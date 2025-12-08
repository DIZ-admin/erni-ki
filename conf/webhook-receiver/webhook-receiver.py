#!/usr/bin/env python3
# mypy: ignore-errors
"""ERNI-KI Webhook Receiver (dashed file for container/runtime)."""

from __future__ import annotations

import hashlib
import hmac
import json
import logging
import os
from collections.abc import Callable
from datetime import datetime, timedelta
from pathlib import Path
from subprocess import CalledProcessError, TimeoutExpired, run  # nosec B404
from typing import Any

from flask import Flask, jsonify, request
from pydantic import ValidationError
from werkzeug.exceptions import BadRequest

try:
    from flask_limiter import Limiter
    from flask_limiter.util import get_remote_address
except (ImportError, ModuleNotFoundError):  # pragma: no cover - optional dependency fallback
    Limiter = None
    get_remote_address = None

try:
    from .models import AlertLabels, AlertPayload  # noqa: F401
except ImportError:
    import sys

    _current_dir = str(Path(__file__).parent)
    if _current_dir not in sys.path:
        sys.path.insert(0, _current_dir)
    from models import AlertLabels, AlertPayload  # type: ignore  # noqa: F401

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("webhook-receiver")


class _SimpleLimiter:
    """Minimal in-process limiter for test environments."""

    def __init__(self):
        self._limits: dict[str, tuple[int, datetime]] = {}

    def limit(self, rule: str) -> Callable[[Callable[..., Any]], Callable[..., Any]]:
        parts = rule.split()
        max_calls = int(parts[0])
        key_prefix = f"{max_calls}:{' '.join(parts[1:])}"

        def decorator(fn: Callable[..., Any]) -> Callable[..., Any]:
            counter_key = f"{key_prefix}:{fn.__name__}"

            def wrapper(*args: Any, **kwargs: Any):
                count, start = self._limits.get(counter_key, (0, datetime.now()))
                # Reset counter every minute
                if datetime.now() - start > timedelta(minutes=1):
                    count, start = 0, datetime.now()
                if count >= max_calls:
                    return jsonify({"error": "rate limit exceeded"}), 429
                self._limits[counter_key] = (count + 1, start)
                return fn(*args, **kwargs)

            wrapper.__name__ = fn.__name__
            return wrapper

        return decorator


app = Flask(__name__)
if Limiter and get_remote_address:
    limiter = Limiter(
        app=app,
        key_func=get_remote_address,
        default_limits=["200 per day", "50 per hour"],
    )
else:
    limiter = _SimpleLimiter()

# Configuration
WEBHOOK_PORT = int(os.getenv("WEBHOOK_PORT", "9093"))
WEBHOOK_SECRET = os.getenv("ALERTMANAGER_WEBHOOK_SECRET")


def _ensure_dir(path: Path, fallback: Path) -> Path:
    try:
        path.mkdir(parents=True, exist_ok=True)
        return path
    except OSError:
        fallback.mkdir(parents=True, exist_ok=True)
        logger.warning("Could not create %s, using %s", path, fallback)
        return fallback


LOG_DIR = _ensure_dir(Path(os.getenv("LOG_DIR", "/app/logs")), Path("logs"))
ALERTS_DIR = _ensure_dir(Path(os.getenv("ALERTS_DIR", LOG_DIR)), Path("logs"))

RECOVERY_DIR = Path(os.getenv("RECOVERY_DIR", "/app/scripts/recovery"))
RECOVERY_SCRIPT_TIMEOUT = int(os.getenv("RECOVERY_SCRIPT_TIMEOUT", "30"))
RECOVERY_SCRIPTS = {
    "ollama": "ollama-recovery.sh",
    "openwebui": "openwebui-recovery.sh",
    "searxng": "searxng-recovery.sh",
}
ALLOWED_SERVICES = set(RECOVERY_SCRIPTS.keys())


def _path_within(base: Path, target: Path) -> bool:
    """Return True if target is within base (prevents traversal)."""
    try:
        target_resolved = target.resolve()
        base_resolved = base.resolve()
        return str(target_resolved).startswith(str(base_resolved))
    except (OSError, RuntimeError, ValueError):
        return False


def _validate_secrets(exit_on_error: bool = False) -> None:
    """Validate required secrets, optionally exiting for production runs."""
    secret = _get_webhook_secret()
    if not secret:
        msg = "Missing required ALERTMANAGER_WEBHOOK_SECRET"
        if exit_on_error:
            logger.error(msg)
            raise SystemExit(1)
        raise RuntimeError(msg)
    if len(secret) < 16:
        msg = "ALERTMANAGER_WEBHOOK_SECRET must be at least 16 characters long"
        if exit_on_error:
            logger.error(msg)
            raise SystemExit(1)
        raise RuntimeError(msg)


def _get_webhook_secret() -> str | None:
    env_secret = os.getenv("ALERTMANAGER_WEBHOOK_SECRET")
    return env_secret if env_secret is not None else WEBHOOK_SECRET


def verify_signature(body: bytes, signature: str | None) -> bool:
    """Verify webhook signature using HMAC."""
    secret = _get_webhook_secret()
    if not secret:
        logger.error("WEBHOOK_SECRET not configured; rejecting request")
        return False
    if not signature:
        return False
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)


def save_alert_to_file(alert_data: dict[str, Any], alert_type: str = "general") -> None:
    """Persist alert payload to ALERTS_DIR."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S%f")
    filename = ALERTS_DIR / f"{alert_type}_{timestamp}.json"
    try:
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(alert_data, f, indent=2, ensure_ascii=False)
    except OSError as exc:
        logger.error("Failed to save alert to file at %s: %s", filename, exc)
    except (TypeError, ValueError) as exc:
        logger.error("Failed to serialize alert data: %s", exc)


def run_recovery_script(service: str) -> None:
    """Execute mapped recovery script if allowed."""
    if service not in RECOVERY_SCRIPTS:
        logger.error("Invalid service: %s", service)
        return

    script_path = RECOVERY_DIR / RECOVERY_SCRIPTS[service]
    if not _path_within(RECOVERY_DIR, script_path):
        logger.error("Path traversal attempt detected for %s", script_path)
        return
    if not script_path.exists():
        logger.warning("No recovery script found for %s at %s", service, script_path)
        return
    if not os.access(script_path, os.X_OK):
        logger.warning(
            "Recovery script for %s is not executable (permission denied): %s",
            service,
            script_path,
        )
        return

    try:
        result = run(  # nosec B603
            [str(script_path)],
            check=True,
            capture_output=True,
            text=True,
            timeout=RECOVERY_SCRIPT_TIMEOUT,
        )
        if result.stdout:
            logger.info("Recovery script output:\n%s", result.stdout)
        if result.stderr:
            logger.warning("Recovery script stderr:\n%s", result.stderr)
    except TimeoutExpired:
        logger.error("Recovery script timed out for %s", service)
    except CalledProcessError as exc:
        logger.error(
            "Recovery script failed for %s (exit %s): %s", service, exc.returncode, exc.stderr
        )
    except (OSError, FileNotFoundError) as exc:
        logger.error("Failed to execute recovery script for %s: %s", service, exc)


def handle_critical_alert(alert: dict[str, Any]) -> None:
    labels = alert.get("labels", {})
    service = labels.get("service", "unknown")
    logger.critical("🚨 CRITICAL ALERT for service: %s", service)
    if service in ALLOWED_SERVICES:
        run_recovery_script(service)
    else:
        logger.info(
            "Service %s has no recovery script configured; manual intervention may be required",
            service,
        )


def handle_gpu_alert(alert: dict[str, Any]) -> None:
    labels = alert.get("labels", {})
    gpu_id = labels.get("gpu_id", "unknown")
    component = labels.get("component", "unknown")
    logger.warning("🎮 GPU Alert - GPU %s, Component: %s", gpu_id, component)
    alert_name = labels.get("alertname", "") or ""
    if "temperature" in str(alert_name).lower():
        logger.warning("GPU temperature alert - consider reducing workload")


def process_alert(alert_data: dict[str, Any], alert_type: str = "general") -> None:
    """Process alerts: basic logging, routing, and persistence."""
    try:
        alerts = alert_data.get("alerts", [])
    except AttributeError:
        logger.error("Invalid alert data structure: %s", alert_data)
        return

    for alert in alerts:
        try:
            labels = alert.get("labels", {})
            if not isinstance(labels, dict) or "alertname" not in labels:
                raise ValueError("alert missing required labels")
            status = alert.get("status", "unknown")
            logger.info("Processing %s alert: %s (%s)", alert_type, labels.get("alertname"), status)
            if alert_type == "critical" or labels.get("severity") == "critical":
                handle_critical_alert(alert)
            if alert_type == "gpu" or labels.get("service") == "gpu":
                handle_gpu_alert(alert)
            # Persist each alert instance
            save_alert_to_file({"alerts": [alert]}, alert_type)
        except Exception as exc:  # noqa: BLE001 - want resilience here
            logger.error("Unexpected error processing alert: %s", exc)


@app.route("/health", methods=["GET"])
@limiter.limit("30 per minute")
def health_check():
    return jsonify(
        {
            "status": "healthy",
            "service": "webhook-receiver",
            "timestamp": datetime.now().isoformat(),
        }
    )


def _create_webhook_handler(alert_type: str, description: str):
    def handler():
        try:
            signature = request.headers.get("X-Signature")
            if not verify_signature(request.get_data(), signature):
                return jsonify({"error": "Unauthorized"}), 401
            try:
                raw_json = request.get_json(force=True)
            except BadRequest:
                return jsonify({"error": "Invalid JSON payload"}), 400
            payload = AlertPayload(**raw_json)
            model = payload.model_dump()
            save_alert_to_file(model, alert_type)
            process_alert(model, alert_type)
            return jsonify({"status": "success", "message": f"{description} processed"})
        except ValidationError as exc:
            logger.warning(
                "Payload validation failed for %s webhook at locations: %s",
                alert_type,
                [err.get("loc") for err in exc.errors()],
            )
            return jsonify({"error": "Invalid request payload"}), 400
        except Exception as exc:  # noqa: BLE001
            logger.exception("Unexpected error in %s webhook: %s", alert_type, exc)
            return jsonify({"error": "Internal server error"}), 500

    handler.__name__ = f"webhook_{alert_type}"
    return handler


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
    app.route(route_path, methods=["POST"], endpoint=f"webhook_{alert_type}")(
        limiter.limit("10 per minute")(_create_webhook_handler(alert_type, description))
    )


@app.route("/alerts", methods=["GET"])
@limiter.limit("10 per minute")
def list_alerts():
    """List recent alert files."""
    try:
        alert_files = sorted(LOG_DIR.glob("alert_*.json"), reverse=True)[:20]
        alerts: list[dict[str, Any]] = []
        for alert_file in alert_files:
            try:
                with open(alert_file, encoding="utf-8") as fh:
                    data = json.load(fh)
                alerts.append(
                    {
                        "filename": alert_file.name,
                        "timestamp": alert_file.stat().st_mtime,
                        "alerts_count": len(data.get("alerts", [])),
                    }
                )
            except (OSError, ValueError, json.JSONDecodeError) as exc:
                logger.error("Failed to read alert file %s: %s", alert_file, exc)
        return jsonify({"alerts": alerts})
    except Exception as exc:  # noqa: BLE001
        logger.error("Error listing alerts: %s", exc)
        return jsonify({"error": "Failed to list alerts"}), 500


if __spec__ is None or __name__ == "__main__":  # Executed via `python` or `exec`
    _validate_secrets(exit_on_error=True)
    if __name__ == "__main__":
        logger.info("Starting ERNI-KI Webhook Receiver on port %s", WEBHOOK_PORT)
        app.run(host="0.0.0.0", port=WEBHOOK_PORT, debug=False)  # noqa: S104  # nosec B104
# ruff: noqa: N999
