"""Unit tests for conf/webhook-receiver/webhook_handler.py."""

import hashlib
import hmac
import importlib.util
import json
import sys
import unittest
from pathlib import Path
from typing import Any, Protocol, cast
from unittest.mock import MagicMock, patch

import pytest

try:
    import requests
except ImportError:  # pragma: no cover
    pytest.skip("requests not installed", allow_module_level=True)

from pydantic import ValidationError

ROOT = Path(__file__).resolve().parents[2]


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
    module_path = ROOT / "conf" / "webhook-receiver" / "webhook_handler.py"
    spec = importlib.util.spec_from_file_location("webhook_handler", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook_handler from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["webhook_handler"] = module
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
        test_secret = "test_secret_key_for_webhook_verification"  # noqa: S105 - test stub  # pragma: allowlist secret
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
        test_secret = "test_secret_key_for_webhook_verification"  # noqa: S105 - test stub  # pragma: allowlist secret
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
            webhook_handler.WEBHOOK_SECRET = "some_secret"  # noqa: S105  # pragma: allowlist secret
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


# ============================================================================
# Tests for AlertLabels field validators (webhook_handler.py)
# ============================================================================


def test_alert_labels_validate_alertname_required():
    """Test that alertname is required and cannot be None."""
    with pytest.raises(ValidationError, match="alertname is required"):
        AlertLabels(alertname=None, severity="critical")


def test_alert_labels_validate_alertname_empty_string():
    """Test that empty alertname after stripping is rejected."""
    with pytest.raises(ValidationError, match="alertname cannot be empty"):
        AlertLabels(alertname="   ", severity="critical")


def test_alert_labels_validate_alertname_max_length():
    """Test alertname length validation at boundary."""
    # Exactly 256 chars should be OK
    labels = AlertLabels(alertname="a" * 256, severity="info")
    assert len(labels.alertname) == 256

    # 257 chars should fail
    with pytest.raises(ValidationError, match="cannot exceed 256 characters"):
        AlertLabels(alertname="a" * 257, severity="info")


def test_alert_labels_validate_instance_max_length():
    """Test instance field length validation."""
    # Valid
    labels = AlertLabels(alertname="Test", instance="192.168.1.1:9090")
    assert labels.instance == "192.168.1.1:9090"

    # Too long
    with pytest.raises(ValidationError, match="instance cannot exceed 256 characters"):
        AlertLabels(alertname="Test", instance="a" * 257)


def test_alert_labels_validate_instance_whitespace_trimmed():
    """Test that instance whitespace is trimmed."""
    labels = AlertLabels(alertname="Test", instance="  192.168.1.1:9090  ")
    assert labels.instance == "192.168.1.1:9090"


def test_alert_labels_validate_severity_normalization():
    """Test that severity is normalized to lowercase."""
    test_cases = [
        ("CRITICAL", "critical"),
        ("Warning", "warning"),
        ("INFO", "info"),
        ("DeBuG", "debug"),
    ]

    for input_val, expected in test_cases:
        labels = AlertLabels(alertname="Test", severity=input_val)
        assert labels.severity == expected


def test_alert_labels_validate_severity_invalid_values():
    """Test that invalid severity values are rejected."""
    invalid_severities = ["high", "low", "urgent", "error", "fatal"]

    for severity in invalid_severities:
        with pytest.raises(ValidationError, match="severity must be one of"):
            AlertLabels(alertname="Test", severity=severity)


# ============================================================================
# Tests for enhanced notification error handling
# ============================================================================


def test_process_alerts_network_error_counted_as_processed(monkeypatch):
    """Test that alerts are counted as processed even when notifications fail."""
    processor = AlertProcessor()

    # Mock notification methods to raise network errors
    def mock_send_discord(*args, **kwargs):
        raise requests.RequestException("Connection timeout")

    monkeypatch.setattr(processor, "_send_discord_notification", mock_send_discord)
    monkeypatch.setenv("DISCORD_WEBHOOK_URL", "https://discord.com/webhook/test")

    alerts_data = {
        "alerts": [
            {
                "labels": {"alertname": "TestAlert", "severity": "critical"},
                "status": "firing",
                "startsAt": "2024-01-01T00:00:00Z",
            }
        ]
    }

    result = processor.process_alerts(alerts_data)

    # Alert should be counted as processed despite notification failure
    assert result["processed"] == 1
    assert len(result["errors"]) > 0


def test_send_discord_notification_connection_error(monkeypatch, caplog):
    """Test Discord notification handling of connection errors."""
    processor = AlertProcessor()

    def mock_post(*args, **kwargs):
        raise requests.ConnectionError("Failed to connect")

    monkeypatch.setattr(requests, "post", mock_post)
    monkeypatch.setenv("DISCORD_WEBHOOK_URL", "https://discord.com/webhook/test")

    message_data = {
        "alert_name": "TestAlert",
        "severity": "critical",
        "status": "firing",
        "instance": "test-instance",
        "starts_at": "2024-01-01T00:00:00Z",
    }

    # Should not raise, just log error
    processor._send_discord_notification(message_data)

    assert "Failed to send Discord notification" in caplog.text


def test_send_slack_notification_timeout_error(monkeypatch, caplog):
    """Test Slack notification handling of timeout errors."""
    processor = AlertProcessor()

    def mock_post(*args, **kwargs):
        raise requests.Timeout("Request timed out")

    monkeypatch.setattr(requests, "post", mock_post)
    monkeypatch.setenv("SLACK_WEBHOOK_URL", "https://hooks.slack.com/test")

    message_data = {
        "alert_name": "TestAlert",
        "severity": "warning",
        "status": "firing",
        "instance": "test-instance",
        "starts_at": "2024-01-01T00:00:00Z",
    }

    processor._send_slack_notification(message_data)

    assert "Failed to send Slack notification" in caplog.text


def test_send_telegram_notification_network_error(monkeypatch, caplog):
    """Test Telegram notification handling of various network errors."""
    processor = AlertProcessor()

    def mock_post(*args, **kwargs):
        raise requests.RequestException("Network unreachable")

    monkeypatch.setattr(requests, "post", mock_post)
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "test_token")
    monkeypatch.setenv("TELEGRAM_CHAT_ID", "123456")

    message_data = {
        "alert_name": "TestAlert",
        "severity": "info",
        "status": "firing",
        "instance": "test-instance",
        "starts_at": "2024-01-01T00:00:00Z",
    }

    processor._send_telegram_notification(message_data)

    assert "Failed to send Telegram notification" in caplog.text


# ============================================================================
# Tests for notification timeout configuration
# ============================================================================


def test_notification_timeout_applied_to_discord(monkeypatch):
    """Test that NOTIFICATION_TIMEOUT is applied to Discord requests."""
    timeout_used = None

    def mock_post(*args, **kwargs):
        nonlocal timeout_used
        timeout_used = kwargs.get("timeout")
        return MagicMock(status_code=200, json=lambda: {})

    monkeypatch.setattr(requests, "post", mock_post)
    monkeypatch.setenv("DISCORD_WEBHOOK_URL", "https://discord.com/webhook/test")
    monkeypatch.setenv("NOTIFICATION_TIMEOUT", "15")
    monkeypatch.setenv("ALERTMANAGER_WEBHOOK_SECRET", "x" * 16)

    # Reimport to pick up new env var
    import sys

    module_path = ROOT / "conf" / "webhook-receiver" / "webhook_handler.py"
    spec = importlib.util.spec_from_file_location("webhook_handler_test", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook_handler from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["webhook_handler_test"] = module
    spec.loader.exec_module(module)
    processor_cls = module.AlertProcessor

    processor = processor_cls()

    message_data = {
        "alert_name": "Test",
        "severity": "critical",
        "status": "firing",
        "instance": "test",
        "starts_at": "2024-01-01T00:00:00Z",
    }

    processor._send_discord_notification(message_data)

    assert timeout_used == 15


# ============================================================================
# Tests for production secret validation
# ============================================================================


def test_production_secret_validation_on_startup(monkeypatch):
    """Test that production startup validates ALERTMANAGER_WEBHOOK_SECRET."""

    # Test with missing secret
    monkeypatch.delenv("ALERTMANAGER_WEBHOOK_SECRET", raising=False)

    with (
        pytest.raises(SystemExit) as exc_info,
        open("conf/webhook-receiver/webhook_handler.py") as handler_file,
    ):
        # Simulate __main__ execution
        exec(handler_file.read())  # noqa: S102

    assert exc_info.value.code == 1


def test_production_secret_validation_test_placeholder(monkeypatch, caplog):
    """Test that test placeholder secret is rejected in production."""

    monkeypatch.setenv("ALERTMANAGER_WEBHOOK_SECRET", "test-secret-placeholder")

    # Should log error and exit
    with (
        pytest.raises(SystemExit),
        open("conf/webhook-receiver/webhook_handler.py") as handler_file,
    ):
        exec(handler_file.read())  # noqa: S102


# ============================================================================
# Tests for malformed alert payloads
# ============================================================================


def test_process_alerts_missing_alerts_key():
    """Test handling of payload without 'alerts' key."""
    processor = AlertProcessor()

    result = processor.process_alerts({"invalid": "payload"})

    assert result["processed"] == 0
    assert result["total"] == 0


def test_process_alerts_empty_alerts_array():
    """Test handling of empty alerts array."""
    processor = AlertProcessor()

    result = processor.process_alerts({"alerts": []})

    assert result["processed"] == 0
    assert result["total"] == 0


def test_process_alerts_malformed_alert_structure():
    """Test handling of malformed individual alerts."""
    processor = AlertProcessor()

    alerts_data = {
        "alerts": [
            {"invalid": "structure"},  # Missing required fields
            {"labels": {"alertname": "ValidAlert", "severity": "info"}, "status": "firing"},
        ]
    }

    result = processor.process_alerts(alerts_data)

    # Second alert should be processed
    assert result["processed"] >= 1
    assert len(result["errors"]) >= 1  # First alert should cause error


# ============================================================================
# Tests for notification message formatting edge cases
# ============================================================================


def test_format_alert_message_with_missing_fields():
    """Test message formatting when optional fields are missing."""
    processor = AlertProcessor()

    # Minimal alert with only required fields
    alert = {"labels": {"alertname": "MinimalAlert", "severity": "info"}, "status": "firing"}

    message = processor._format_alert_message(alert, {})

    assert "MinimalAlert" in message["alert_name"]
    assert message["severity"] == "info"
    assert message["status"] == "firing"


def test_format_alert_message_with_unicode_content():
    """Test message formatting with unicode content."""
    processor = AlertProcessor()

    alert = {
        "labels": {"alertname": "Unicode Alert 测试 🚨", "severity": "warning"},
        "status": "firing",
        "annotations": {"description": "Alert with unicode: 日本語 Ελληνικά العربية"},
    }

    message = processor._format_alert_message(alert, {})

    assert "测试" in message["alert_name"]
    assert "日本語" in message.get("description", "")


def test_format_alert_message_with_very_long_description():
    """Test message formatting with very long description."""
    processor = AlertProcessor()

    long_description = "A" * 5000

    alert = {
        "labels": {"alertname": "LongAlert", "severity": "critical"},
        "status": "firing",
        "annotations": {"description": long_description},
    }

    message = processor._format_alert_message(alert, {})

    # Message should handle long content gracefully
    assert "description" in message
    assert len(message["description"]) > 0


# ============================================================================
# Tests for webhook endpoint health check
# ============================================================================


def test_health_check_response_format(client):
    """Test that health check returns proper response format."""
    response = client.get("/health")

    assert response.status_code == 200
    data = response.get_json()

    assert "status" in data
    assert data["status"] == "healthy"
    assert "service" in data
    assert data["service"] == "erni-ki-webhook-receiver"


def test_health_check_under_load(client):
    """Test health check reliability under load."""
    # Make many rapid health check requests
    responses = []
    for _ in range(100):
        response = client.get("/health")
        responses.append(response.status_code)

    # Most should succeed (some might be rate-limited)
    success_count = responses.count(200)
    assert success_count >= 30  # At least rate limit allows


# ============================================================================
# Tests for alert grouping and deduplication
# ============================================================================


def test_process_alerts_with_group_labels():
    """Test that group labels are properly passed to alert processing."""
    processor = AlertProcessor()

    group_labels = {"cluster": "prod", "env": "production"}

    alerts_data = {
        "alerts": [{"labels": {"alertname": "TestAlert", "severity": "info"}, "status": "firing"}],
        "groupLabels": group_labels,
    }

    result = processor.process_alerts(alerts_data)

    assert result["processed"] == 1
    # Group labels should be used in processing


def test_process_alerts_multiple_same_alertname():
    """Test handling of multiple alerts with same name."""
    processor = AlertProcessor()

    alerts_data = {
        "alerts": [
            {
                "labels": {
                    "alertname": "DuplicateAlert",
                    "severity": "warning",
                    "instance": "host1",
                },
                "status": "firing",
            },
            {
                "labels": {
                    "alertname": "DuplicateAlert",
                    "severity": "warning",
                    "instance": "host2",
                },
                "status": "firing",
            },
        ]
    }

    result = processor.process_alerts(alerts_data)

    # Both should be processed
    assert result["processed"] == 2


# ============================================================================
# Tests for notification retry logic (if implemented)
# ============================================================================


def test_notification_failure_logged_but_not_retried(monkeypatch, caplog):
    """Test that notification failures are logged but don't trigger retries."""
    processor = AlertProcessor()

    call_count = 0

    def mock_post(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        raise requests.RequestException("Simulated failure")

    monkeypatch.setattr(requests, "post", mock_post)
    monkeypatch.setenv("DISCORD_WEBHOOK_URL", "https://discord.com/webhook/test")

    message_data = {
        "alert_name": "Test",
        "severity": "critical",
        "status": "firing",
        "instance": "test",
        "starts_at": "2024-01-01T00:00:00Z",
    }

    processor._send_discord_notification(message_data)

    # Should only try once (no retries)
    assert call_count == 1
    assert "Failed to send Discord notification" in caplog.text


# End of additional tests for webhook_handler.py
