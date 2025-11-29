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
from pydantic import BaseModel, ValidationError

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
LOG_DIR = Path("/app/logs")
LOG_DIR.mkdir(exist_ok=True)
RECOVERY_DIR = Path(os.getenv("RECOVERY_DIR", "/app/scripts/recovery"))
WEBHOOK_SECRET = os.getenv("ALERTMANAGER_WEBHOOK_SECRET", "")
ALLOWED_SERVICES = {"ollama", "openwebui", "searxng"}


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
    if service not in ALLOWED_SERVICES:
        logger.error("Invalid service: %s", service)
        return

    script_path = RECOVERY_DIR / f"{service}-recovery.sh"

    if not _path_within(RECOVERY_DIR, script_path):
        logger.error("Path traversal attempt for %s", script_path)
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
def health_check():
    """Health check endpoint"""
    return jsonify(
        {
            "status": "healthy",
            "service": "webhook-receiver",
            "timestamp": datetime.now().isoformat(),
        }
    )


@app.route("/webhook", methods=["POST"])
@limiter.limit("10 per minute")
def webhook_general():
    """General webhook endpoint"""
    try:
        signature = request.headers.get("X-Signature")
        if not verify_signature(request.get_data(), signature):
            return jsonify({"error": "Unauthorized"}), 401

        payload = AlertPayload(**request.get_json(force=True))

        save_alert_to_file(payload.model_dump(), "general")
        process_alert(payload.model_dump(), "general")

        return jsonify({"status": "success", "message": "Alert processed"})

    except ValidationError as e:
        logger.error("Payload validation failed: %s", e)
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in general webhook: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/critical", methods=["POST"])
@limiter.limit("10 per minute")
def webhook_critical():
    """Critical alerts"""
    try:
        signature = request.headers.get("X-Signature")
        if not verify_signature(request.get_data(), signature):
            return jsonify({"error": "Unauthorized"}), 401

        payload = AlertPayload(**request.get_json(force=True))

        save_alert_to_file(payload.model_dump(), "critical")
        process_alert(payload.model_dump(), "critical")

        return jsonify({"status": "success", "message": "Critical alert processed"})

    except ValidationError as e:
        logger.error("Payload validation failed: %s", e)
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in critical webhook: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/warning", methods=["POST"])
@limiter.limit("10 per minute")
def webhook_warning():
    """Warnings"""
    try:
        signature = request.headers.get("X-Signature")
        if not verify_signature(request.get_data(), signature):
            return jsonify({"error": "Unauthorized"}), 401

        payload = AlertPayload(**request.get_json(force=True))

        save_alert_to_file(payload.model_dump(), "warning")
        process_alert(payload.model_dump(), "warning")

        return jsonify({"status": "success", "message": "Warning alert processed"})

    except ValidationError as e:
        logger.error("Payload validation failed: %s", e)
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in warning webhook: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/gpu", methods=["POST"])
@limiter.limit("10 per minute")
def webhook_gpu():
    """GPU alerts"""
    try:
        signature = request.headers.get("X-Signature")
        if not verify_signature(request.get_data(), signature):
            return jsonify({"error": "Unauthorized"}), 401

        payload = AlertPayload(**request.get_json(force=True))

        save_alert_to_file(payload.model_dump(), "gpu")
        process_alert(payload.model_dump(), "gpu")

        return jsonify({"status": "success", "message": "GPU alert processed"})

    except ValidationError as e:
        logger.error("Payload validation failed: %s", e)
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in GPU webhook: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/ai", methods=["POST"])
@limiter.limit("10 per minute")
def webhook_ai():
    """AI services alerts"""
    try:
        signature = request.headers.get("X-Signature")
        if not verify_signature(request.get_data(), signature):
            return jsonify({"error": "Unauthorized"}), 401

        payload = AlertPayload(**request.get_json(force=True))

        save_alert_to_file(payload.model_dump(), "ai")
        process_alert(payload.model_dump(), "ai")

        return jsonify({"status": "success", "message": "AI alert processed"})

    except ValidationError as e:
        logger.error("Payload validation failed: %s", e)
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in AI webhook: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/database", methods=["POST"])
@limiter.limit("10 per minute")
def webhook_database():
    """Database alerts"""
    try:
        signature = request.headers.get("X-Signature")
        if not verify_signature(request.get_data(), signature):
            return jsonify({"error": "Unauthorized"}), 401

        payload = AlertPayload(**request.get_json(force=True))

        save_alert_to_file(payload.model_dump(), "database")
        process_alert(payload.model_dump(), "database")

        return jsonify({"status": "success", "message": "Database alert processed"})

    except ValidationError as e:
        logger.error("Payload validation failed: %s", e)
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in database webhook: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


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
    logger.info(f"Starting ERNI-KI Webhook Receiver on port {WEBHOOK_PORT}")
    app.run(host="0.0.0.0", port=WEBHOOK_PORT, debug=False)  # noqa: S104 - runs inside container
