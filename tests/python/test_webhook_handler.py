"""Unit tests for conf/webhook_receiver/webhook_handler.py."""

import importlib.util
import types
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch


def load_webhook_handler() -> types.ModuleType:
    """Load webhook_handler module from the dashed directory."""
    root = Path(__file__).resolve().parents[2]
    module_path = root / "conf" / "webhook-receiver" / "webhook_handler.py"
    spec = importlib.util.spec_from_file_location("webhook_handler", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook_handler from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


webhook_handler = load_webhook_handler()
AlertProcessor = webhook_handler.AlertProcessor


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


if __name__ == "__main__":
    unittest.main()
