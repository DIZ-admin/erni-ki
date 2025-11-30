#!/usr/bin/env python3
"""
ERNI-KI Webhook Receiver for alert handling.
Processes Alertmanager notifications and forwards them to various channels.
"""

import hashlib
import hmac
import logging
import os
import sys
from datetime import datetime
from typing import Any

import requests
from flask import Flask, jsonify, request
from pydantic import BaseModel, ValidationError, field_validator

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

# Configuration from environment variables
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL", "")
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL", "")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
NOTIFICATION_TIMEOUT = int(os.getenv("NOTIFICATION_TIMEOUT", "10"))
TEST_SECRET_PLACEHOLDER = "test-secret-placeholder"  # pragma: allowlist secret  # noqa: S105
WEBHOOK_SECRET = os.getenv("ALERTMANAGER_WEBHOOK_SECRET", "")


def verify_signature(body: bytes, signature: str | None) -> bool:
    if not WEBHOOK_SECRET:
        logger.error("WEBHOOK_SECRET not configured; rejecting request")
        return False
    if not signature:
        return False
    expected = hmac.new(WEBHOOK_SECRET.encode(), body, hashlib.sha256).hexdigest()
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
        try:
            alerts = alerts_data.get("alerts", [])
            group_labels = alerts_data.get("groupLabels", {})

            logger.info(f"Processing {len(alerts)} alerts")

            results = {"processed": 0, "total": len(alerts), "errors": [], "notifications_sent": []}

            for alert in alerts:
                try:
                    self._process_single_alert(alert, group_labels)
                except (KeyError, TypeError, ValueError) as e:
                    logger.error(f"Error processing alert data: {e}", exc_info=True)
                    results["errors"].append(str(e))
                finally:
                    # Count alert as processed even if notification failed, to reflect attempt.
                    results["processed"] += 1

            return results

        except (KeyError, TypeError) as e:
            logger.error(f"Invalid alerts data structure: {e}")
            return {"error": "Invalid alerts data structure"}
        except Exception as e:
            logger.exception(f"Unexpected error processing alerts: {e}")
            return {"error": "Internal server error"}

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
    signature = request.headers.get("X-Signature")
    if not verify_signature(request.get_data(), signature):
        raise PermissionError("Unauthorized")
    return AlertPayload(**request.get_json(force=True))


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

    except ValidationError as e:
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

    except ValidationError as e:
        return jsonify({"error": str(e)}), 400
    except PermissionError:
        return jsonify({"error": "Unauthorized"}), 401
    except (KeyError, TypeError) as e:
        logger.error(f"Invalid payload structure: {e}", exc_info=True)
        return jsonify({"error": "Invalid payload"}), 400
    except Exception as e:
        logger.exception(f"Unexpected error handling warning webhook: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route("/health", methods=["GET"])
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
    if not WEBHOOK_SECRET or WEBHOOK_SECRET == TEST_SECRET_PLACEHOLDER:
        logger.error("ALERTMANAGER_WEBHOOK_SECRET must be configured in production")
        sys.exit(1)
    logger.info("Starting ERNI-KI Webhook Receiver")
    app.run(host="0.0.0.0", port=9093, debug=False)  # noqa: S104 - runs inside container
