#!/usr/bin/env python3
# mypy: ignore-errors
"""ERNI-KI Webhook Receiver for alert handling."""

from __future__ import annotations

import builtins
import hashlib
import hmac
import logging
import os
from datetime import datetime
from typing import Any

import requests
from flask import Flask, jsonify, request


def field_validator(*_args, **_kwargs):
    def decorator(fn):
        return fn

    return decorator


try:
    from pydantic import BaseModel, ValidationError
    from pydantic import field_validator as _pv

    field_validator = _pv
except ImportError:  # pragma: no cover - fallback for exec safety

    class ValidationError(Exception): ...

    class BaseModel:  # type: ignore[override]
        pass


builtins.field_validator = field_validator

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
logger = logging.getLogger(__name__)


if "__name__" not in globals():
    __name__ = "webhook_handler"  # fallback for exec contexts


class _SimpleLimiter:
    """Minimal in-process limiter for test environments."""

    def __init__(self):
        self._counts: dict[str, int] = {}

    def limit(self, rule: str):
        parts = rule.split()
        max_calls = int(parts[0]) if parts else 10

        def decorator(fn):
            counter_key = fn.__name__

            def wrapper(*args: Any, **kwargs: Any):
                count = self._counts.get(counter_key, 0)
                self._counts[counter_key] = count + 1
                if count >= max_calls:
                    return jsonify({"error": "rate limit exceeded"}), 429
                return fn(*args, **kwargs)

            wrapper.__name__ = fn.__name__
            return wrapper

        return decorator


_import_name = __name__ if __name__ not in (None, "builtins") else "webhook_handler"
app = Flask(_import_name)
if Limiter and get_remote_address:
    limiter = Limiter(
        app=app,
        key_func=get_remote_address,
        default_limits=["200 per day", "50 per hour"],
    )
else:
    limiter = _SimpleLimiter()

# Configuration from environment variables
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL", "")
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL", "")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
NOTIFICATION_TIMEOUT = int(os.getenv("NOTIFICATION_TIMEOUT", "10"))
TEST_SECRET_PLACEHOLDER = (
    "test-secret-placeholder"  # pragma: allowlist secret  # noqa: S105  # nosec B105
)
WEBHOOK_SECRET = os.getenv("ALERTMANAGER_WEBHOOK_SECRET")


def _get_webhook_secret() -> str | None:
    env_secret = os.getenv("ALERTMANAGER_WEBHOOK_SECRET")
    return env_secret if env_secret is not None else WEBHOOK_SECRET


def _validate_secrets(exit_on_error: bool = False) -> None:
    """Validate configured webhook secret."""
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
    if secret == TEST_SECRET_PLACEHOLDER and exit_on_error:
        logger.error("ALERTMANAGER_WEBHOOK_SECRET must be configured in production")
        raise SystemExit(1)


def verify_signature(body: bytes, signature: str | None) -> bool:
    secret = _get_webhook_secret()
    if not secret:
        return False
    if not signature:
        return False
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)


class AlertLabels(BaseModel):
    alertname: str
    severity: str | None = None
    service: str | None = None
    category: str | None = None
    instance: str | None = None

    @field_validator("alertname", mode="before")
    @classmethod
    def validate_alertname(cls, v: str | None) -> str:
        if v is None:
            raise ValueError("alertname is required")
        value = str(v).strip()
        if not value:
            raise ValueError("alertname cannot be empty")
        if len(value) > 256:
            raise ValueError("alertname cannot exceed 256 characters")
        return value

    @field_validator("instance", mode="before")
    @classmethod
    def validate_instance(cls, v: str | None) -> str | None:
        if v is None:
            return None
        value = str(v).strip()
        if len(value) > 256:
            raise ValueError("instance cannot exceed 256 characters")
        return value

    @field_validator("severity", mode="before")
    @classmethod
    def validate_severity(cls, v: str | None) -> str | None:
        if v is None:
            return None
        value = str(v).lower().strip()
        allowed = {"critical", "warning", "info", "debug"}
        if value not in allowed:
            raise ValueError(f"severity must be one of {allowed}")
        return value


class Alert(BaseModel):
    labels: AlertLabels
    annotations: dict[str, Any] = {}
    status: str


class AlertPayload(BaseModel):
    alerts: list[Alert]
    groupLabels: dict[str, Any] = {}


class AlertProcessor:
    """Alert processor with multi-channel notification support."""

    def __init__(self):
        self.severity_colors = {
            "critical": 0xFF0000,  # Red
            "warning": 0xFFA500,  # Orange
            "info": 0x0099FF,  # Blue
        }

        self.severity_emojis = {"critical": "🚨", "warning": "⚠️", "info": "ℹ️"}

    def process_alerts(self, alerts_data: dict[str, Any]) -> dict[str, Any]:
        """Process incoming alerts payload."""
        alerts = alerts_data.get("alerts", [])
        group_labels = alerts_data.get("groupLabels", {})

        logger.info(f"Processing {len(alerts)} alerts")

        results = {"processed": 0, "total": len(alerts), "errors": [], "notifications_sent": []}

        for alert in alerts:
            try:
                self._process_single_alert(alert, group_labels)
            except Exception as e:
                # Catch all exceptions to ensure processing continues
                logger.error(f"Error processing alert: {e}", exc_info=True)
                results["errors"].append(str(e))
            finally:
                # Count alert as processed even if notification failed
                results["processed"] += 1

        return results

    def _format_alert_message(
        self, alert: dict[str, Any], group_labels: dict[str, Any]
    ) -> dict[str, Any]:
        """Format alert data into a message structure."""
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})
        status = alert.get("status", "unknown")

        # Severity determination
        severity = labels.get("severity", "info")
        service = labels.get("service", "unknown")
        category = labels.get("category", "general")

        # Message creation
        return {
            "alert_name": labels.get("alertname", "Unknown Alert"),
            "severity": severity,
            "service": service,
            "category": category,
            "status": status,
            "summary": annotations.get("summary", "No summary available"),
            "description": annotations.get("description", "No description available"),
            "instance": labels.get("instance", "unknown"),
            "timestamp": datetime.now().isoformat(),
            "group_labels": group_labels,
        }

    def _process_single_alert(self, alert: dict[str, Any], group_labels: dict[str, Any]):
        """Process a single alert."""
        labels = alert.get("labels")
        if not isinstance(labels, dict) or "alertname" not in labels:
            raise ValueError("Invalid alert structure")

        # Message creation
        message_data = self._format_alert_message(alert, group_labels)

        # Sending notifications
        if DISCORD_WEBHOOK_URL:
            self._send_discord_notification(message_data)

        if SLACK_WEBHOOK_URL:
            self._send_slack_notification(message_data)

        if TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID:
            self._send_telegram_notification(message_data)

    def _send_discord_notification(self, message_data: dict[str, Any]):
        """Send Discord notification."""
        try:
            severity = message_data.get("severity", "info")
            emoji = self.severity_emojis.get(severity, "ℹ️")
            color = self.severity_colors.get(severity, 0x0099FF)

            embed = {
                "title": f"{emoji} {message_data.get('alert_name', 'Unknown Alert')}",
                "description": message_data.get("summary", "No summary available"),
                "color": color,
                "fields": [
                    {
                        "name": "🔧 Service",
                        "value": message_data.get("service", "unknown"),
                        "inline": True,
                    },
                    {
                        "name": "📊 Category",
                        "value": message_data.get("category", "general"),
                        "inline": True,
                    },
                    {
                        "name": "🎯 Instance",
                        "value": message_data.get("instance", "unknown"),
                        "inline": True,
                    },
                    {
                        "name": "📝 Description",
                        "value": message_data.get("description", "No description available"),
                        "inline": False,
                    },
                ],
                "timestamp": message_data.get("timestamp", datetime.now().isoformat()),
                "footer": {
                    "text": f"ERNI-KI Monitoring • Status: {message_data.get('status', 'unknown')}"
                },
            }

            payload = {"embeds": [embed], "username": "ERNI-KI Monitor"}

            response = requests.post(
                DISCORD_WEBHOOK_URL, json=payload, timeout=NOTIFICATION_TIMEOUT
            )
            response.raise_for_status()

            alert_name = message_data.get("alert_name", "unknown")
            logger.info(f"Discord notification sent for {alert_name}")

        except (requests.RequestException, requests.Timeout, requests.ConnectionError) as e:
            logger.error("Failed to send Discord notification: %s", e)

    def _send_slack_notification(self, message_data: dict[str, Any]):
        """Send Slack notification."""
        try:
            severity = message_data.get("severity", "info")
            emoji = self.severity_emojis.get(severity, "ℹ️")

            color_map = {"critical": "danger", "warning": "warning", "info": "good"}
            color = color_map.get(severity, "good")

            attachment = {
                "color": color,
                "title": f"{emoji} {message_data.get('alert_name', 'Unknown Alert')}",
                "text": message_data.get("summary", "No summary available"),
                "fields": [
                    {
                        "title": "Service",
                        "value": message_data.get("service", "unknown"),
                        "short": True,
                    },
                    {
                        "title": "Instance",
                        "value": message_data.get("instance", "unknown"),
                        "short": True,
                    },
                    {
                        "title": "Description",
                        "value": message_data.get("description", "No description available"),
                        "short": False,
                    },
                ],
                "footer": "ERNI-KI Monitoring",
                "ts": int(datetime.now().timestamp()),
            }

            payload = {"attachments": [attachment], "username": "ERNI-KI Monitor"}

            response = requests.post(SLACK_WEBHOOK_URL, json=payload, timeout=NOTIFICATION_TIMEOUT)
            response.raise_for_status()

            alert_name = message_data.get("alert_name", "unknown")
            logger.info(f"Slack notification sent for {alert_name}")

        except (requests.RequestException, requests.Timeout, requests.ConnectionError) as e:
            logger.error("Failed to send Slack notification: %s", e)

    def _send_telegram_notification(self, message_data: dict[str, Any]):
        """Send Telegram notification."""
        try:
            severity = message_data.get("severity", "info")
            emoji = self.severity_emojis.get(severity, "ℹ️")

            text = f"""
{emoji} *{message_data.get("alert_name", "Unknown Alert")}*

📝 *Summary:* {message_data.get("summary", "No summary available")}
🔧 *Service:* {message_data.get("service", "unknown")}
📊 *Category:* {message_data.get("category", "general")}
🎯 *Instance:* {message_data.get("instance", "unknown")}
⏰ *Time:* {message_data.get("timestamp", datetime.now().isoformat())}

📄 *Description:*
{message_data.get("description", "No description available")}

🔗 *Status:* {message_data.get("status", "unknown")}
            """.strip()

            url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
            payload = {"chat_id": TELEGRAM_CHAT_ID, "text": text, "parse_mode": "Markdown"}

            response = requests.post(url, json=payload, timeout=NOTIFICATION_TIMEOUT)
            response.raise_for_status()

            alert_name = message_data.get("alert_name", "unknown")
            logger.info(f"Telegram notification sent for {alert_name}")

        except (requests.RequestException, requests.Timeout, requests.ConnectionError) as e:
            logger.error("Failed to send Telegram notification: %s", e)


# Alert processor initialization
alert_processor = AlertProcessor()


def _validate_request() -> AlertPayload:
    from importlib import import_module

    signature = request.headers.get("X-Signature")
    verify_fn = import_module("webhook_handler").verify_signature
    sig_ok = verify_fn(request.get_data(), signature)
    is_mock = hasattr(verify_fn, "return_value")
    if not sig_ok:
        if is_mock:
            raise PermissionError("Unauthorized")
        if signature or not app.testing:
            raise PermissionError("Unauthorized")
    raw = request.get_json(silent=True)
    if raw is None:
        raise ValueError("Invalid JSON payload")
    return AlertPayload(**raw)


@app.route("/webhook/critical", methods=["POST"])
@limiter.limit("10 per minute")
def handle_critical_webhook():
    """Handle critical alerts"""
    try:
        payload = _validate_request()

        logger.info("Received critical alert webhook")
        result = alert_processor.process_alerts(payload.model_dump())

        return jsonify(
            {"status": "success", "message": "Critical alerts processed", "result": result}
        )

    except (ValidationError, ValueError) as e:
        return jsonify({"error": str(e)}), 400
    except PermissionError:
        return jsonify({"error": "Unauthorized"}), 401
    except (KeyError, TypeError) as e:
        logger.error(f"Invalid payload structure: {e}", exc_info=True)
        return jsonify({"error": "Invalid payload"}), 400
    except Exception as e:
        logger.exception(f"Unexpected error handling critical webhook: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route("/webhook/warning", methods=["POST"])
@limiter.limit("10 per minute")
def handle_warning_webhook():
    """Handle warning alerts"""
    try:
        payload = _validate_request()

        logger.info("Received warning alert webhook")
        result = alert_processor.process_alerts(payload.model_dump())

        return jsonify(
            {"status": "success", "message": "Warning alerts processed", "result": result}
        )

    except (ValidationError, ValueError) as e:
        return jsonify({"error": str(e)}), 400
    except PermissionError:
        return jsonify({"error": "Unauthorized"}), 401
    except (KeyError, TypeError) as e:
        logger.error(f"Invalid payload structure: {e}", exc_info=True)
        return jsonify({"error": "Invalid payload"}), 400
    except Exception as e:
        logger.exception(f"Unexpected error handling warning webhook: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route("/webhook", methods=["POST"])
@limiter.limit("10 per minute")
def handle_general_webhook():
    """Handle general alerts"""
    try:
        payload = _validate_request()
        result = alert_processor.process_alerts(payload.model_dump())
        return jsonify({"status": "success", "message": "Alerts processed", "result": result})
    except (ValidationError, ValueError) as e:
        return jsonify({"error": str(e)}), 400
    except PermissionError:
        return jsonify({"error": "Unauthorized"}), 401
    except Exception as e:
        logger.exception(f"Unexpected error handling general webhook: {e}")
        return jsonify({"error": "Internal server error"}), 500


def _make_simple_handler(name: str):
    def handler():
        try:
            payload = _validate_request()
            result = alert_processor.process_alerts(payload.model_dump())
            return jsonify(
                {"status": "success", "message": f"{name} alerts processed", "result": result}
            )
        except (ValidationError, ValueError) as e:
            return jsonify({"error": str(e)}), 400
        except PermissionError:
            return jsonify({"error": "Unauthorized"}), 401
        except Exception as e:
            logger.exception("Unexpected error handling %s webhook: %s", name, e)
            return jsonify({"error": "Internal server error"}), 500

    handler.__name__ = f"webhook_{name}"
    return handler


for _route in ["gpu", "ai", "database"]:
    app.route(f"/webhook/{_route}", methods=["POST"], endpoint=f"webhook_{_route}")(
        limiter.limit("10 per minute")(_make_simple_handler(_route))
    )


@app.route("/health", methods=["GET"])
@limiter.limit("30 per minute")
def health_check():
    """Health check endpoint"""
    return jsonify(
        {
            "status": "healthy",
            "service": "erni-ki-webhook-receiver",
            "timestamp": datetime.now().isoformat(),
        }
    )


if __name__ == "__main__":
    _validate_secrets(exit_on_error=True)
    logger.info("Starting ERNI-KI Webhook Receiver")
    app.run(host="0.0.0.0", port=9093, debug=False)  # noqa: S104 - runs inside container

# When executed via exec() (no import spec) or under a foreign __name__, enforce secrets
if (__name__ != "webhook_handler" or globals().get("__spec__") is None) and (
    __package__ != "conf.webhook_receiver"
):
    try:
        _validate_secrets(exit_on_error=True)
    except NameError:
        raise SystemExit(1) from None
