#!/usr/bin/env python3
"""
ERNI-KI Webhook Receiver
Simple webhook receiver for Alertmanager alerts
"""

import hashlib
import hmac
import json
import logging
import os
from datetime import datetime
from pathlib import Path
from subprocess import CalledProcessError, TimeoutExpired, run
from typing import Any

from flask import Flask, jsonify, request
from pydantic import BaseModel, ValidationError, field_validator
from werkzeug.exceptions import BadRequest

try:
    from flask_limiter import Limiter
    from flask_limiter.util import get_remote_address
except Exception:  # pragma: no cover - optional dependency fallback
    Limiter = None
    get_remote_address = None

# Logging configuration
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("webhook-receiver")

app = Flask(__name__)
if Limiter and get_remote_address:
    limiter = Limiter(
        app=app,
        key_func=get_remote_address,
        default_limits=["200 per day", "50 per hour"],
    )
else:

    class _NoopLimiter:
        def limit(self, *_args: Any, **_kwargs: Any):  # pragma: no cover - fallback
            def decorator(fn):
                return fn

            return decorator

    limiter = _NoopLimiter()

# Configuration
WEBHOOK_PORT = int(os.getenv("WEBHOOK_PORT", 9093))
LOG_DIR = Path(os.getenv("LOG_DIR", "/app/logs"))
try:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
except OSError:
    # Fallback for local development/testing if /app/logs is not writable
    if not os.getenv("LOG_DIR"):
        LOG_DIR = Path("logs")
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        logger.warning(f"Could not create /app/logs, falling back to {LOG_DIR}")
    else:
        raise
RECOVERY_DIR = Path(os.getenv("RECOVERY_DIR", "/app/scripts/recovery"))
WEBHOOK_SECRET = os.getenv("ALERTMANAGER_WEBHOOK_SECRET", "")
ALLOWED_SERVICES = {"ollama", "openwebui", "searxng"}

# Explicit mapping of services to recovery script filenames
# This prevents any path traversal attempts through service names
RECOVERY_SCRIPTS = {
    "ollama": "ollama-recovery.sh",
    "openwebui": "openwebui-recovery.sh",
    "searxng": "searxng-recovery.sh",
}


def _validate_secrets() -> None:
    """Validate required secrets are configured on startup."""
    if not WEBHOOK_SECRET:
        logger.error(
            "CRITICAL: ALERTMANAGER_WEBHOOK_SECRET environment variable not set. "
            "Webhook receiver cannot start without it."
        )
        raise RuntimeError(
            "Missing required ALERTMANAGER_WEBHOOK_SECRET environment variable"
        )
    if len(WEBHOOK_SECRET) < 16:
        logger.error(
            "CRITICAL: ALERTMANAGER_WEBHOOK_SECRET is too short. "
            "Minimum 16 characters required for security."
        )
        raise RuntimeError(
            "ALERTMANAGER_WEBHOOK_SECRET must be at least 16 characters long"
        )


def _path_within(base: Path, target: Path) -> bool:
    try:
        target_resolved = target.resolve()
        base_resolved = base.resolve()
        return str(target_resolved).startswith(str(base_resolved))
    except Exception:
        return False


class AlertLabels(BaseModel):
    alertname: str
    severity: str | None = None
    service: str | None = None
    category: str | None = None
    gpu_id: str | None = None
    component: str | None = None

    @field_validator("alertname", mode="before")
    @classmethod
    def validate_alertname(cls, v: str) -> str:
        """Validate alert name length and content."""
        if not v:
            raise ValueError("alertname cannot be empty")
        if len(v) > 256:
            raise ValueError("alertname cannot exceed 256 characters")
        return v.strip()

    @field_validator("severity", mode="before")
    @classmethod
    def validate_severity(cls, v: str | None) -> str | None:
        """Validate severity is one of allowed values."""
        if v is None:
            return v
        allowed = {"critical", "warning", "info", "debug"}
        v_lower = str(v).lower().strip()
        if v_lower not in allowed:
            raise ValueError(f"severity must be one of {allowed}, got {v_lower}")
        return v_lower

    @field_validator("service", mode="before")
    @classmethod
    def validate_service(cls, v: str | None) -> str | None:
        """Validate service name."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 128:
            raise ValueError("service cannot exceed 128 characters")
        if not v.replace("-", "").replace("_", "").isalnum():
            raise ValueError("service must contain only alphanumeric characters, hyphens, or underscores")
        return v

    @field_validator("category", mode="before")
    @classmethod
    def validate_category(cls, v: str | None) -> str | None:
        """Validate alert category."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 128:
            raise ValueError("category cannot exceed 128 characters")
        return v

    @field_validator("gpu_id", mode="before")
    @classmethod
    def validate_gpu_id(cls, v: str | None) -> str | None:
        """Validate GPU ID format."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 32:
            raise ValueError("gpu_id cannot exceed 32 characters")
        if not v.replace("-", "").isalnum():
            raise ValueError("gpu_id must be alphanumeric with optional hyphens")
        return v

    @field_validator("component", mode="before")
    @classmethod
    def validate_component(cls, v: str | None) -> str | None:
        """Validate component name."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 128:
            raise ValueError("component cannot exceed 128 characters")
        return v


class Alert(BaseModel):
    labels: AlertLabels
    annotations: dict[str, Any] = {}
    status: str


class AlertPayload(BaseModel):
    alerts: list[Alert]
    groupLabels: dict[str, Any] = {}


def verify_signature(body: bytes, signature: str | None) -> bool:
    if not WEBHOOK_SECRET:
        logger.error("WEBHOOK_SECRET not configured; rejecting request")
        return False
    if not signature:
        return False
    expected = hmac.new(WEBHOOK_SECRET.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)


def save_alert_to_file(alert_data, alert_type="general"):
    """Save alert to file for further processing"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = LOG_DIR / f"alert_{alert_type}_{timestamp}.json"

    try:
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(alert_data, f, indent=2, ensure_ascii=False)
        logger.info(f"Alert saved to {filename}")
    except Exception as e:
        logger.error(f"Failed to save alert to file: {e}")


def process_alert(alert_data, alert_type="general"):
    """Process alert and execute necessary actions"""
    try:
        alerts = alert_data.get("alerts", [])

        for alert in alerts:
            labels = alert.get("labels", {})
            annotations = alert.get("annotations", {})
            status = alert.get("status", "unknown")

            # Alert logging
            logger.info(f"Processing {alert_type} alert:")
            logger.info(f"  Status: {status}")
            logger.info(f"  Alert: {labels.get('alertname', 'Unknown')}")
            logger.info(f"  Service: {labels.get('service', 'Unknown')}")
            logger.info(f"  Severity: {labels.get('severity', 'Unknown')}")
            logger.info(f"  Summary: {annotations.get('summary', 'No summary')}")

            # Special handling for critical alerts
            if alert_type == "critical" or labels.get("severity") == "critical":
                handle_critical_alert(alert)

            # Special handling for GPU alerts
            if alert_type == "gpu" or labels.get("service") == "gpu":
                handle_gpu_alert(alert)

    except Exception as e:
        logger.error(f"Error processing alert: {e}")


def handle_critical_alert(alert):
    """Critical alert handling"""
    labels = alert.get("labels", {})
    service = labels.get("service", "unknown")

    logger.critical(f"🚨 CRITICAL ALERT for service: {service}")

    # Automatic actions can be added here:
    # - Send SMS/email
    # - Notifications to Slack/Teams
    # - Recovery scripts per service

    if service in ALLOWED_SERVICES:
        run_recovery_script(service)
    else:
        logger.info(
            "Service %s has no recovery script configured; manual intervention may be required",
            service,
        )


def handle_gpu_alert(alert):
    """GPU alert handling"""
    labels = alert.get("labels", {})
    gpu_id = labels.get("gpu_id", "unknown")
    component = labels.get("component", "unknown")

    logger.warning(f"🎮 GPU Alert - GPU {gpu_id}, Component: {component}")

    # Special handling for GPU temperature
    if component == "nvidia" and "temperature" in labels.get("alertname", "").lower():
        logger.warning("GPU temperature alert - consider reducing workload")


def run_recovery_script(service: str) -> None:
    """Execute recovery script for a critical service if available."""
    # Use explicit mapping to prevent path traversal attacks
    if service not in RECOVERY_SCRIPTS:
        logger.error("Invalid service: %s", service)
        return

    script_filename = RECOVERY_SCRIPTS[service]
    script_path = RECOVERY_DIR / script_filename

    # Double-check path is within recovery directory
    if not _path_within(RECOVERY_DIR, script_path):
        logger.error("Path traversal attempt detected for %s", script_path)
        return

    if not script_path.exists():
        logger.warning(f"No recovery script found for {service} at {script_path}")
        return

    if not os.access(script_path, os.X_OK):
        logger.warning(f"Recovery script for {service} is not executable: {script_path}")
        return

    try:
        logger.info(f"Running recovery script for {service}: {script_path}")
        result = run([str(script_path)], check=True, capture_output=True, text=True, timeout=30)
        logger.info("Recovery script output:\n%s", result.stdout)
        if result.stderr:
            logger.warning("Recovery script stderr:\n%s", result.stderr)
    except TimeoutExpired:
        logger.error("Recovery script timeout for %s", service)
    except CalledProcessError as exc:
        logger.error(
            "Recovery script failed for %s (exit %s): %s", service, exc.returncode, exc.stderr
        )
    except Exception as exc:
        logger.error("Unexpected error executing recovery script for %s: %s", service, exc)


@app.route("/health", methods=["GET"])
@limiter.limit("30 per minute")  # Rate limit health checks to prevent DDoS
def health_check():
    """Health check endpoint"""
    return jsonify(
        {
            "status": "healthy",
            "service": "webhook-receiver",
            "timestamp": datetime.now().isoformat(),
        }
    )


def _create_webhook_handler(alert_type: str, description: str):
    """Factory function to create webhook handlers, reducing code duplication.

    Args:
        alert_type: Type of alert (general, critical, warning, gpu, ai, database)
        description: Human-readable description for response messages

    Returns:
        A Flask route handler function
    """

    def handler():
        try:
            signature = request.headers.get("X-Signature")
            if not verify_signature(request.get_data(), signature):
                return jsonify({"error": "Unauthorized"}), 401

            payload = AlertPayload(**request.get_json(force=True))

            save_alert_to_file(payload.model_dump(), alert_type)
            process_alert(payload.model_dump(), alert_type)

            return jsonify({"status": "success", "message": f"{description} processed"})

        except (ValidationError, BadRequest) as e:
            logger.error("Payload validation failed: %s", e)
            return jsonify({"error": str(e)}), 400
        except Exception as e:
            logger.error(f"Error in {alert_type} webhook: {e}", exc_info=True)
            return jsonify({"error": str(e)}), 500

    handler.__doc__ = f"{description} webhook handler"
    return handler


# Register webhook handlers using factory pattern
# This consolidates 6 nearly identical functions into 1 factory + configuration
WEBHOOK_ROUTES = [
    ("", "general", "Alert"),
    ("/critical", "critical", "Critical alert"),
    ("/warning", "warning", "Warning alert"),
    ("/gpu", "gpu", "GPU alert"),
    ("/ai", "ai", "AI alert"),
    ("/database", "database", "Database alert"),
]

for route_suffix, alert_type, description in WEBHOOK_ROUTES:
    route_path = f"/webhook{route_suffix}"
    handler = _create_webhook_handler(alert_type, description)
    handler_name = f"webhook_{alert_type}"

    # Register the route with rate limiting
    app.route(route_path, methods=["POST"])(limiter.limit("10 per minute")(handler))

    # Register handler for debugging
    app.view_functions[handler_name] = handler


@app.route("/alerts", methods=["GET"])
def list_alerts():
    """List of recent alerts"""
    try:
        alert_files = sorted(LOG_DIR.glob("alert_*.json"), reverse=True)[:20]
        alerts = []

        for alert_file in alert_files:
            try:
                with open(alert_file, encoding="utf-8") as f:
                    alert_data = json.load(f)
                    alerts.append(
                        {
                            "filename": alert_file.name,
                            "timestamp": alert_file.stat().st_mtime,
                            "alerts_count": len(alert_data.get("alerts", [])),
                        }
                    )
            except Exception as e:
                logger.error(f"Error reading alert file {alert_file}: {e}")

        return jsonify({"alerts": alerts})

    except Exception as e:
        logger.error(f"Error listing alerts: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    _validate_secrets()
    logger.info(f"Starting ERNI-KI Webhook Receiver on port {WEBHOOK_PORT}")
    app.run(host="0.0.0.0", port=WEBHOOK_PORT, debug=False)  # noqa: S104 - runs inside container
