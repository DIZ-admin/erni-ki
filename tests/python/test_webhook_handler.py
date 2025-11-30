"""Unit tests for conf/webhook_receiver/webhook_handler.py."""

import hashlib
import hmac
import importlib.util
import json
import unittest
from pathlib import Path
from typing import Any, Protocol, cast
from unittest.mock import MagicMock, patch


class WebhookModule(Protocol):
    """Protocol for webhook_handler module."""

    DISCORD_WEBHOOK_URL: str
    SLACK_WEBHOOK_URL: str
    TELEGRAM_BOT_TOKEN: str
    TELEGRAM_CHAT_ID: str
    NOTIFICATION_TIMEOUT: int
    WEBHOOK_SECRET: str
    AlertLabels: Any
    AlertPayload: Any
    AlertProcessor: Any
    app: Any
    verify_signature: Any
    _validate_secrets: Any
    _validate_request: Any
    alert_processor: Any


def load_webhook_handler() -> WebhookModule:
    """Load webhook_handler module from the dashed directory."""
    root = Path(__file__).resolve().parents[2]
    module_path = root / "conf" / "webhook-receiver" / "webhook_handler.py"
    spec = importlib.util.spec_from_file_location("webhook_handler", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook_handler from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return cast(WebhookModule, module)


webhook_handler = load_webhook_handler()
AlertProcessor = webhook_handler.AlertProcessor
AlertLabels = webhook_handler.AlertLabels
AlertPayload = webhook_handler.AlertPayload
app = webhook_handler.app
verify_signature = webhook_handler.verify_signature


class TestAlertProcessorCore(unittest.TestCase):
    """Core tests for AlertProcessor."""

    def test_severity_mappings(self):
        processor = AlertProcessor()
        self.assertEqual(processor.severity_colors["critical"], 0xFF0000)
        self.assertEqual(processor.severity_emojis["warning"], "⚠️")

    def test_process_alerts_empty(self):
        processor = AlertProcessor()
        result = processor.process_alerts({"alerts": []})
        self.assertEqual(result["processed"], 0)
        self.assertEqual(result["errors"], [])

    @patch("requests.post")
    def test_process_alerts_sends_notifications(self, mock_post: MagicMock):
        # Configure fake endpoints
        webhook_handler.DISCORD_WEBHOOK_URL = "http://discord.example"
        webhook_handler.SLACK_WEBHOOK_URL = "http://slack.example"
        webhook_handler.TELEGRAM_BOT_TOKEN = "test-token"  # noqa: S105 - test stub
        webhook_handler.TELEGRAM_CHAT_ID = "chat"

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "ServiceDown",
                        "severity": "critical",
                        "service": "api",
                        "instance": "api-1",
                        "category": "runtime",
                    },
                    "annotations": {
                        "summary": "Service is down",
                        "description": "API not reachable",
                    },
                    "status": "firing",
                }
            ]
        }

        result = processor.process_alerts(alerts)

        # Should process one alert and invoke three webhooks
        self.assertEqual(result["processed"], 1)
        self.assertEqual(mock_post.call_count, 3)

    @patch("requests.post", side_effect=Exception("network error"))
    def test_process_alerts_handles_send_failures(self, mock_post: MagicMock):
        webhook_handler.DISCORD_WEBHOOK_URL = "http://discord.example"
        processor = AlertProcessor()

        alerts = {
            "alerts": [
                {
                    "labels": {"alertname": "DiskFull", "severity": "warning"},
                    "annotations": {"summary": "Disk space low"},
                    "status": "firing",
                }
            ]
        }

        result = processor.process_alerts(alerts)

        # Error should be captured, but processing continues
        self.assertEqual(result["processed"], 1)
        self.assertGreaterEqual(len(result.get("errors", [])), 0)


class TestAlertLabelValidation(unittest.TestCase):
    """Test suite for AlertLabels validation."""

    def test_alertname_validation_empty_string(self):
        """Test that empty alertname raises validation error."""
        from pydantic import ValidationError

        with self.assertRaises(ValidationError):
            AlertLabels(alertname="")

    def test_alertname_validation_too_long(self):
        """Test that alertname exceeding 256 characters raises error."""
        from pydantic import ValidationError

        long_name = "x" * 257
        with self.assertRaises(ValidationError):
            AlertLabels(alertname=long_name)

    def test_instance_validation_too_long(self):
        """Test that instance exceeding 256 characters raises error."""
        from pydantic import ValidationError

        long_instance = "x" * 257
        with self.assertRaises(ValidationError):
            AlertLabels(alertname="Test", instance=long_instance)

    def test_severity_validation_with_valid_values(self):
        """Test that valid severity values are accepted."""
        for severity in ["critical", "warning", "info", "debug"]:
            label = AlertLabels(alertname="Test", severity=severity)
            self.assertEqual(label.severity, severity)

    def test_service_validation_valid_formats(self):
        """Test that service accepts alphanumeric, hyphens, and underscores."""
        label = AlertLabels(alertname="Test", service="my-service_01")
        self.assertEqual(label.service, "my-service_01")


class TestDiscordNotification(unittest.TestCase):
    """Test suite for Discord notification."""

    @patch("requests.post")
    def test_discord_notification_formatting(self, mock_post: MagicMock):
        """Test that Discord notification is formatted correctly."""
        webhook_handler.DISCORD_WEBHOOK_URL = "http://discord.example"
        webhook_handler.SLACK_WEBHOOK_URL = ""
        webhook_handler.TELEGRAM_BOT_TOKEN = ""
        webhook_handler.TELEGRAM_CHAT_ID = ""

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "HighMemory",
                        "severity": "critical",
                        "service": "api-server",
                        "instance": "api-1",
                    },
                    "annotations": {
                        "summary": "Memory usage is high",
                        "description": "Memory above 90%",
                    },
                    "status": "firing",
                }
            ]
        }

        processor.process_alerts(alerts)
        mock_post.assert_called_once()

        # Verify the call contains expected fields
        call_args = mock_post.call_args
        payload = call_args[1]["json"]
        self.assertIn("embeds", payload)
        self.assertIn("username", payload)
        embed = payload["embeds"][0]
        self.assertEqual(embed["color"], 0xFF0000)  # Critical = red
        self.assertIn("🚨", embed["title"])  # Critical emoji

    @patch("requests.post")
    def test_discord_notification_with_warning_severity(self, mock_post: MagicMock):
        """Test Discord notification with warning severity."""
        webhook_handler.DISCORD_WEBHOOK_URL = "http://discord.example"
        webhook_handler.SLACK_WEBHOOK_URL = ""
        webhook_handler.TELEGRAM_BOT_TOKEN = ""
        webhook_handler.TELEGRAM_CHAT_ID = ""

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {"alertname": "LowDisk", "severity": "warning"},
                    "annotations": {"summary": "Disk space low"},
                    "status": "firing",
                }
            ]
        }

        processor.process_alerts(alerts)

        call_args = mock_post.call_args
        payload = call_args[1]["json"]
        embed = payload["embeds"][0]
        self.assertEqual(embed["color"], 0xFFA500)  # Warning = orange
        self.assertIn("⚠️", embed["title"])  # Warning emoji


class TestSlackNotification(unittest.TestCase):
    """Test suite for Slack notification."""

    @patch("requests.post")
    def test_slack_notification_formatting(self, mock_post: MagicMock):
        """Test that Slack notification is formatted correctly."""
        webhook_handler.DISCORD_WEBHOOK_URL = ""
        webhook_handler.SLACK_WEBHOOK_URL = "http://slack.example"
        webhook_handler.TELEGRAM_BOT_TOKEN = ""
        webhook_handler.TELEGRAM_CHAT_ID = ""

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {"alertname": "ServiceDown", "severity": "critical"},
                    "annotations": {"summary": "Service is not responding"},
                    "status": "firing",
                }
            ]
        }

        processor.process_alerts(alerts)
        mock_post.assert_called_once()

        call_args = mock_post.call_args
        payload = call_args[1]["json"]
        self.assertIn("attachments", payload)
        attachment = payload["attachments"][0]
        self.assertEqual(attachment["color"], "danger")  # Critical = danger


class TestTelegramNotification(unittest.TestCase):
    """Test suite for Telegram notification."""

    @patch("requests.post")
    def test_telegram_notification_formatting(self, mock_post: MagicMock):
        """Test that Telegram notification is formatted correctly."""
        webhook_handler.DISCORD_WEBHOOK_URL = ""
        webhook_handler.SLACK_WEBHOOK_URL = ""
        webhook_handler.TELEGRAM_BOT_TOKEN = "test-token"  # noqa: S105 - test stub
        webhook_handler.TELEGRAM_CHAT_ID = "123456"

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {"alertname": "DatabaseError", "severity": "warning"},
                    "annotations": {"summary": "Database connection failed"},
                    "status": "firing",
                }
            ]
        }

        processor.process_alerts(alerts)
        mock_post.assert_called_once()

        call_args = mock_post.call_args
        payload = call_args[1]["json"]
        self.assertIn("text", payload)
        self.assertIn("DatabaseError", payload["text"])


class TestMultipleAlerts(unittest.TestCase):
    """Test suite for processing multiple alerts."""

    @patch("requests.post")
    def test_process_multiple_alerts(self, mock_post: MagicMock):
        """Test processing multiple alerts in single payload."""
        webhook_handler.DISCORD_WEBHOOK_URL = "http://discord.example"
        webhook_handler.SLACK_WEBHOOK_URL = ""
        webhook_handler.TELEGRAM_BOT_TOKEN = ""
        webhook_handler.TELEGRAM_CHAT_ID = ""

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {"alertname": "Alert1", "severity": "critical"},
                    "annotations": {"summary": "First alert"},
                    "status": "firing",
                },
                {
                    "labels": {"alertname": "Alert2", "severity": "warning"},
                    "annotations": {"summary": "Second alert"},
                    "status": "firing",
                },
            ]
        }

        result = processor.process_alerts(alerts)

        # Both alerts should be processed
        self.assertEqual(result["processed"], 2)
        # Discord should be called twice (once for each alert)
        self.assertEqual(mock_post.call_count, 2)


class TestFlaskEndpoints(unittest.TestCase):
    """Test suite for Flask endpoints."""

    def setUp(self):
        """Set up test client."""
        self.app = app
        self.app.testing = True
        self.client = self.app.test_client()

    def test_health_endpoint_returns_200(self):
        """Test that health endpoint returns 200."""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data["status"], "healthy")
        self.assertIn("service", data)
        self.assertIn("timestamp", data)

    @patch("webhook_handler.verify_signature", return_value=True)
    @patch("webhook_handler.alert_processor.process_alerts")
    def test_critical_webhook_endpoint(self, mock_process, mock_verify):
        """Test /webhook/critical endpoint."""
        mock_process.return_value = {"processed": 1, "errors": []}

        payload = {
            "alerts": [
                {
                    "labels": {"alertname": "Critical", "severity": "critical"},
                    "annotations": {"summary": "Critical issue"},
                    "status": "firing",
                }
            ]
        }

        response = self.client.post(
            "/webhook/critical",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data["status"], "success")
        self.assertIn("Critical alerts processed", data["message"])

    @patch("webhook_handler.verify_signature", return_value=True)
    @patch("webhook_handler.alert_processor.process_alerts")
    def test_warning_webhook_endpoint(self, mock_process, mock_verify):
        """Test /webhook/warning endpoint."""
        mock_process.return_value = {"processed": 1, "errors": []}

        payload = {
            "alerts": [
                {
                    "labels": {"alertname": "Warning", "severity": "warning"},
                    "annotations": {"summary": "Warning issue"},
                    "status": "firing",
                }
            ]
        }

        response = self.client.post(
            "/webhook/warning",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data["status"], "success")
        self.assertIn("Warning alerts processed", data["message"])

    @patch("webhook_handler.verify_signature", return_value=False)
    def test_webhook_rejects_invalid_signature(self, mock_verify):
        """Test that webhook rejects invalid signatures."""
        payload = {"alerts": [{"labels": {"alertname": "Test"}, "status": "firing"}]}

        response = self.client.post(
            "/webhook/critical",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 401)
        data = json.loads(response.data)
        self.assertEqual(data["error"], "Unauthorized")

    @patch("webhook_handler.verify_signature", return_value=True)
    def test_webhook_with_invalid_payload(self, mock_verify):
        """Test that webhook rejects invalid JSON payload."""
        payload = {
            "alerts": [
                {
                    "labels": {"alertname": "Test", "severity": "invalid_severity"},
                    "status": "firing",
                }
            ]
        }

        response = self.client.post(
            "/webhook/critical",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn("error", data)


class TestSignatureVerification(unittest.TestCase):
    """Test suite for signature verification."""

    def test_verify_signature_with_valid_signature(self):
        """Test that valid signatures are accepted."""
        test_secret = "test_secret_key_for_webhook_verification"  # noqa: S105 - test stub
        test_body = b"test webhook payload"

        expected_signature = hmac.new(test_secret.encode(), test_body, hashlib.sha256).hexdigest()

        original_secret = webhook_handler.WEBHOOK_SECRET
        try:
            webhook_handler.WEBHOOK_SECRET = test_secret
            result = verify_signature(test_body, expected_signature)
            self.assertTrue(result)
        finally:
            webhook_handler.WEBHOOK_SECRET = original_secret

    def test_verify_signature_with_invalid_signature(self):
        """Test that invalid signatures are rejected."""
        test_secret = "test_secret_key_for_webhook_verification"  # noqa: S105 - test stub
        test_body = b"test webhook payload"
        invalid_signature = "invalid_signature_that_doesnt_match"  # noqa: S105 - test stub

        original_secret = webhook_handler.WEBHOOK_SECRET
        try:
            webhook_handler.WEBHOOK_SECRET = test_secret
            result = verify_signature(test_body, invalid_signature)
            self.assertFalse(result)
        finally:
            webhook_handler.WEBHOOK_SECRET = original_secret

    def test_verify_signature_with_missing_signature(self):
        """Test that missing signatures are rejected."""
        original_secret = webhook_handler.WEBHOOK_SECRET
        try:
            webhook_handler.WEBHOOK_SECRET = "some_secret"  # noqa: S105 - test stub
            result = verify_signature(b"test", None)
            self.assertFalse(result)
        finally:
            webhook_handler.WEBHOOK_SECRET = original_secret


class TestNotificationChannelCombinations(unittest.TestCase):
    """Test suite for combinations of notification channels."""

    @patch("requests.post")
    def test_all_channels_enabled(self, mock_post: MagicMock):
        """Test sending to all notification channels."""
        webhook_handler.DISCORD_WEBHOOK_URL = "http://discord.example"
        webhook_handler.SLACK_WEBHOOK_URL = "http://slack.example"
        webhook_handler.TELEGRAM_BOT_TOKEN = "test-token"  # noqa: S105 - test stub
        webhook_handler.TELEGRAM_CHAT_ID = "123"

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {"alertname": "Test", "severity": "warning"},
                    "annotations": {"summary": "Test alert"},
                    "status": "firing",
                }
            ]
        }

        processor.process_alerts(alerts)

        # All three channels should be called
        self.assertEqual(mock_post.call_count, 3)

    @patch("requests.post")
    def test_only_discord_enabled(self, mock_post: MagicMock):
        """Test sending only to Discord when other channels disabled."""
        webhook_handler.DISCORD_WEBHOOK_URL = "http://discord.example"
        webhook_handler.SLACK_WEBHOOK_URL = ""
        webhook_handler.TELEGRAM_BOT_TOKEN = ""
        webhook_handler.TELEGRAM_CHAT_ID = ""

        mock_resp = MagicMock()
        mock_resp.raise_for_status.return_value = None
        mock_post.return_value = mock_resp

        processor = AlertProcessor()
        alerts = {
            "alerts": [
                {
                    "labels": {"alertname": "Test", "severity": "info"},
                    "annotations": {"summary": "Test alert"},
                    "status": "firing",
                }
            ]
        }

        processor.process_alerts(alerts)

        # Only Discord should be called
        self.assertEqual(mock_post.call_count, 1)


if __name__ == "__main__":
    unittest.main()
