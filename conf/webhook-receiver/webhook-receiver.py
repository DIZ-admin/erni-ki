#!/usr/bin/env python3
"""
ERNI-KI Webhook Receiver
Simple webhook receiver for Alertmanager alerts.

Refactored with modular components:
- models.py: Pydantic validation models
- services.py: Alert processing and recovery execution
- This file: Flask routes and HTTP handling
"""

import hashlib
import hmac
import json
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Any

from flask import Flask, jsonify, request
from pydantic import ValidationError
from werkzeug.exceptions import BadRequest

try:
    # Try relative imports first (normal package use)
    from .models import AlertPayload
    from .services import process_alert
except ImportError:
    # Fall back to absolute imports (for testing with importlib)
    from models import AlertPayload  # type: ignore
    from services import process_alert  # type: ignore

try:
    from flask_limiter import Limiter
    from flask_limiter.util import get_remote_address
except (ImportError, ModuleNotFoundError):  # pragma: no cover - optional dependency fallback
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


def _get_log_dir() -> Path:
    """Get log directory with fallback for development."""
    default = Path(os.getenv("LOG_DIR", "/app/logs"))
    try:
        default.mkdir(parents=True, exist_ok=True)
        return default
    except OSError:
        if not os.getenv("LOG_DIR"):
            fallback = Path("logs")
            fallback.mkdir(parents=True, exist_ok=True)
            logger.warning("Could not create %s, falling back to %s", default, fallback)
            return fallback
        raise


LOG_DIR = _get_log_dir()
WEBHOOK_SECRET = os.getenv("ALERTMANAGER_WEBHOOK_SECRET", "test-secret-placeholder")


def _validate_secrets() -> None:
    """Validate required secrets are configured on startup."""
    if not WEBHOOK_SECRET:
        logger.error(
            "CRITICAL: ALERTMANAGER_WEBHOOK_SECRET environment variable not set. "
            "Webhook receiver cannot start without it."
        )
        raise RuntimeError("Missing required ALERTMANAGER_WEBHOOK_SECRET environment variable")
    if len(WEBHOOK_SECRET) < 16:
        logger.error(
            "CRITICAL: ALERTMANAGER_WEBHOOK_SECRET is too short. "
            "Minimum 16 characters required for security."
        )
        raise RuntimeError("ALERTMANAGER_WEBHOOK_SECRET must be at least 16 characters long")


def verify_signature(body: bytes, signature: str | None) -> bool:
    """Verify webhook signature using HMAC."""
    if not WEBHOOK_SECRET:
        logger.error("WEBHOOK_SECRET not configured; rejecting request")
        return False
    if not signature:
        return False
    expected = hmac.new(WEBHOOK_SECRET.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)


def save_alert_to_file(alert_data: dict[str, Any], alert_type: str = "general") -> None:
    """Save alert to file for further processing."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = LOG_DIR / f"alert_{alert_type}_{timestamp}.json"

    try:
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(alert_data, f, indent=2, ensure_ascii=False)
        logger.info("Alert saved to %s", filename)
    except OSError as e:
        logger.error("Failed to save alert to file at %s: %s", filename, e)
    except (ValueError, TypeError) as e:
        logger.error("Failed to serialize alert data: %s", e)


@app.route("/health", methods=["GET"])
@limiter.limit("30 per minute")  # Rate limit health checks to prevent DDoS
def health_check():
    """Health check endpoint."""
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
        except OSError as e:
            logger.error("File operation error in %s webhook: %s", alert_type, e)
            return jsonify({"error": "Internal server error"}), 500
        except Exception as e:
            logger.exception("Unexpected error in %s webhook: %s", alert_type, e)
            return jsonify({"error": "Internal server error"}), 500

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

    # Register the route with rate limiting and a unique endpoint name
    app.route(route_path, methods=["POST"], endpoint=handler_name)(
        limiter.limit("10 per minute")(handler)
    )


@app.route("/alerts", methods=["GET"])
def list_alerts():
    """List of recent alerts."""
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
            except OSError as e:
                logger.error("Failed to read alert file %s: %s", alert_file, e)
            except json.JSONDecodeError as e:
                logger.error("Invalid JSON in alert file %s: %s", alert_file, e)

        return jsonify({"alerts": alerts})

    except (OSError, ValueError) as e:
        logger.error("Error listing alerts: %s", e)
        return jsonify({"error": "Failed to list alerts"}), 500


if __name__ == "__main__":
    _validate_secrets()
    logger.info("Starting ERNI-KI Webhook Receiver on port %s", WEBHOOK_PORT)
    app.run(host="0.0.0.0", port=WEBHOOK_PORT, debug=False)  # noqa: S104 - runs inside container
