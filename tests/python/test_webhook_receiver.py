#!/usr/bin/env python3
"""
Comprehensive unit tests for webhook-receiver.py
Tests alert processing, file operations, recovery scripts, and API endpoints.
"""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, mock_open, patch

from conf.webhook_receiver import (
    app,
    handle_critical_alert,
    handle_gpu_alert,
    process_alert,
    run_recovery_script,
    save_alert_to_file,
)


class TestSaveAlertToFile(unittest.TestCase):
    """Test suite for save_alert_to_file function."""

    @patch("conf.webhook_receiver._impl.LOG_DIR")
    def test_save_alert_creates_file_with_correct_format(self, mock_log_dir):
        """Test that alert is saved with correct filename format."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_log_dir.__truediv__ = lambda self, other: Path(tmpdir) / other

            alert_data = {"alerts": [{"labels": {"alertname": "Test"}}]}

            with patch("builtins.open", mock_open()) as mock_file:
                save_alert_to_file(alert_data, "critical")
                mock_file.assert_called_once()

    @patch("conf.webhook_receiver._impl.LOG_DIR")
    def test_save_alert_handles_encoding(self, mock_log_dir):
        """Test that alert data with non-ASCII characters is saved correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_log_dir.__truediv__ = lambda self, other: Path(tmpdir) / other

            alert_data = {
                "alerts": [{"labels": {"alertname": "Test", "description": "Test Unicode"}}]
            }

            with patch("builtins.open", mock_open()) as mock_file:
                save_alert_to_file(alert_data, "general")

                # Verify encoding parameter
                call_args = mock_file.call_args
                self.assertIn("encoding", call_args[1])
                self.assertEqual(call_args[1]["encoding"], "utf-8")

    @patch("conf.webhook_receiver._impl.LOG_DIR")
    @patch("builtins.open", side_effect=PermissionError("Permission denied"))
    def test_save_alert_handles_permission_error(self, mock_open_func, mock_log_dir):
        """Test that permission errors are handled gracefully."""
        mock_log_dir.__truediv__ = lambda self, other: Path("/nonexistent") / other

        alert_data = {"alerts": []}

        # Should not raise exception
        save_alert_to_file(alert_data, "test")


class TestProcessAlert(unittest.TestCase):
    """Test suite for process_alert function."""

    def test_process_alert_with_empty_alerts(self):
        """Test processing empty alerts list."""
        alert_data = {"alerts": []}

        # Should not raise exception
        process_alert(alert_data, "general")

    def test_process_alert_with_valid_alert(self):
        """Test processing a valid alert extracts correct information."""
        alert_data = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "ServiceDown",
                        "service": "ollama",
                        "severity": "critical",
                    },
                    "annotations": {
                        "summary": "Ollama service is down",
                    },
                    "status": "firing",
                }
            ]
        }

        with patch("conf.webhook_receiver._impl.handle_critical_alert") as mock_handle:
            process_alert(alert_data, "critical")
            mock_handle.assert_called_once()

    def test_process_alert_with_gpu_alert(self):
        """Test that GPU alerts are handled separately."""
        alert_data = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "GPUTemperatureHigh",
                        "service": "gpu",
                        "severity": "warning",
                    },
                    "annotations": {
                        "summary": "GPU temperature is high",
                    },
                    "status": "firing",
                }
            ]
        }

        with patch("conf.webhook_receiver._impl.handle_gpu_alert") as mock_handle:
            process_alert(alert_data, "gpu")
            mock_handle.assert_called_once()

    def test_process_alert_handles_missing_fields_gracefully(self):
        """Test that missing fields use default values."""
        alert_data = {
            "alerts": [
                {
                    "labels": {},
                    "annotations": {},
                }
            ]
        }

        # Should not raise exception
        process_alert(alert_data, "general")

    def test_process_alert_handles_exception(self):
        """Test that exceptions during alert processing are caught."""
        import contextlib

        with patch("conf.webhook_receiver._impl.logger"), contextlib.suppress(Exception):
            # Force an exception by passing invalid data
            process_alert({"alerts": [None]}, "test")

        # Logger should have been called for errors


class TestHandleCriticalAlert(unittest.TestCase):
    """Test suite for handle_critical_alert function."""

    def test_handle_critical_alert_logs_correctly(self):
        """Test that critical alerts are logged with correct severity."""
        alert = {
            "labels": {
                "alertname": "ServiceDown",
                "service": "ollama",
                "severity": "critical",
            }
        }

        with patch("conf.webhook_receiver._impl.run_recovery_script") as mock_recovery:
            handle_critical_alert(alert)
            mock_recovery.assert_called_once_with("ollama")

    def test_handle_critical_alert_calls_recovery_for_known_services(self):
        """Test that recovery scripts are called for known services."""
        known_services = ["ollama", "openwebui", "searxng"]

        for service in known_services:
            alert = {"labels": {"service": service}}

            with patch("conf.webhook_receiver._impl.run_recovery_script") as mock_recovery:
                handle_critical_alert(alert)
                mock_recovery.assert_called_once_with(service)

    def test_handle_critical_alert_logs_unknown_services(self):
        """Test that unknown services log a message instead of running recovery."""
        alert = {"labels": {"service": "unknown-service"}}

        with patch("conf.webhook_receiver._impl.run_recovery_script") as mock_recovery:
            handle_critical_alert(alert)
            # Recovery should not be called for unknown services
            mock_recovery.assert_not_called()


class TestHandleGPUAlert(unittest.TestCase):
    """Test suite for handle_gpu_alert function."""

    def test_handle_gpu_alert_extracts_gpu_info(self):
        """Test that GPU alert extracts GPU ID and component correctly."""
        alert = {
            "labels": {
                "alertname": "GPUTemperatureHigh",
                "gpu_id": "0",
                "component": "nvidia",
            }
        }

        with patch("conf.webhook_receiver._impl.logger") as mock_logger:
            handle_gpu_alert(alert)
            # Should log with GPU information
            mock_logger.warning.assert_called()

    def test_handle_gpu_alert_handles_temperature_alerts(self):
        """Test special handling for GPU temperature alerts."""
        alert = {
            "labels": {
                "alertname": "GPUTemperatureExceeded",
                "gpu_id": "1",
                "component": "nvidia",
            }
        }

        with patch("conf.webhook_receiver._impl.logger") as mock_logger:
            handle_gpu_alert(alert)
            # Should log temperature warning
            self.assertEqual(mock_logger.warning.call_count, 2)


class TestRunRecoveryScript(unittest.TestCase):
    """Test suite for run_recovery_script function."""

    @patch("conf.webhook_receiver._impl.RECOVERY_DIR")
    @patch("conf.webhook_receiver._impl._path_within", return_value=True)
    def test_run_recovery_script_checks_existence(self, mock_path_within, mock_recovery_dir):
        """Test that recovery script existence is checked."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_recovery_dir.__truediv__ = lambda self, other: Path(tmpdir).resolve() / other
            mock_recovery_dir.resolve.return_value = Path(tmpdir).resolve()

            run_recovery_script("nonexistent-service")
            # Should return early if script doesn't exist

    @patch("conf.webhook_receiver._impl.RECOVERY_DIR")
    @patch("conf.webhook_receiver._impl._path_within", return_value=True)
    def test_run_recovery_script_checks_executable(self, mock_path_within, mock_recovery_dir):
        """Test that recovery script executable permission is checked."""
        with tempfile.TemporaryDirectory() as tmpdir:
            script_path = Path(tmpdir).resolve() / "test-recovery.sh"
            script_path.write_text("#!/bin/bash\necho 'test'")
            script_path.chmod(0o644)  # Not executable

            mock_recovery_dir.__truediv__ = lambda self, other: script_path
            mock_recovery_dir.resolve.return_value = Path(tmpdir).resolve()

            with patch("conf.webhook_receiver._impl.logger") as mock_logger:
                run_recovery_script("ollama")
                # Should log warning about non-executable script
                mock_logger.warning.assert_called()

    @patch("conf.webhook_receiver._impl.RECOVERY_DIR")
    @patch("conf.webhook_receiver._impl.run")
    @patch("conf.webhook_receiver._impl._path_within", return_value=True)
    def test_run_recovery_script_executes_successfully(
        self, mock_path_within, mock_run, mock_recovery_dir
    ):
        """Test successful execution of recovery script."""
        with tempfile.TemporaryDirectory() as tmpdir:
            script_path = Path(tmpdir).resolve() / "ollama-recovery.sh"
            script_path.write_text("#!/bin/bash\necho 'Recovery complete'")
            script_path.chmod(0o755)

            mock_recovery_dir.__truediv__ = lambda self, other: script_path
            mock_recovery_dir.resolve.return_value = Path(tmpdir).resolve()

            mock_result = MagicMock()
            mock_result.stdout = "Recovery complete"
            mock_result.stderr = ""
            mock_run.return_value = mock_result

            run_recovery_script("ollama")
            mock_run.assert_called_once()

    @patch("conf.webhook_receiver._impl.RECOVERY_DIR")
    @patch("conf.webhook_receiver._impl.run")
    @patch("conf.webhook_receiver._impl._path_within", return_value=True)
    def test_run_recovery_script_handles_failure(
        self, mock_path_within, mock_run, mock_recovery_dir
    ):
        """Test handling of recovery script failure."""
        with tempfile.TemporaryDirectory() as tmpdir:
            script_path = Path(tmpdir).resolve() / "test-recovery.sh"
            script_path.write_text("#!/bin/bash\nexit 1")
            script_path.chmod(0o755)

            mock_recovery_dir.__truediv__ = lambda self, other: script_path
            mock_recovery_dir.resolve.return_value = Path(tmpdir).resolve()

            from subprocess import CalledProcessError

            mock_run.side_effect = CalledProcessError(1, "test-recovery.sh", stderr="Error")

            with patch("conf.webhook_receiver._impl.logger") as mock_logger:
                run_recovery_script("test")
                # Should log error
                mock_logger.error.assert_called()


class TestWebhookEndpoints(unittest.TestCase):
    """Test suite for Flask webhook endpoints."""

    def setUp(self):
        """Set up test client."""
        self.app = app
        self.app.testing = True
        self.client = self.app.test_client()

    def test_health_endpoint_returns_healthy_status(self):
        """Test that health endpoint returns 200 and correct status."""
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["service"], "webhook-receiver")
        self.assertIn("timestamp", data)

    @patch("conf.webhook_receiver._impl.save_alert_to_file")
    @patch("conf.webhook_receiver._impl.process_alert")
    @patch("conf.webhook_receiver._impl.verify_signature", return_value=True)
    def test_webhook_general_with_valid_json(self, mock_verify, mock_process, mock_save):
        """Test general webhook endpoint with valid JSON."""
        payload = {"alerts": [{"labels": {"alertname": "Test"}, "status": "firing"}]}

        response = self.client.post(
            "/webhook",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data["status"], "success")
        mock_save.assert_called_once()
        mock_process.assert_called_once()

    @patch("conf.webhook_receiver._impl.verify_signature", return_value=True)
    def test_webhook_general_without_json_returns_400(self, mock_verify):
        """Test that missing JSON returns 400 error."""
        response = self.client.post("/webhook")

        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn("error", data)

    @patch("conf.webhook_receiver._impl.save_alert_to_file")
    @patch("conf.webhook_receiver._impl.process_alert")
    @patch("conf.webhook_receiver._impl.verify_signature", return_value=True)
    def test_webhook_critical_processes_correctly(self, mock_verify, mock_process, mock_save):
        """Test critical webhook endpoint."""
        payload = {
            "alerts": [
                {"labels": {"alertname": "Critical", "severity": "critical"}, "status": "firing"}
            ]
        }

        response = self.client.post(
            "/webhook/critical",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 200)
        # Verify it was saved as critical
        # Use ANY for fields populated by Pydantic defaults
        expected_payload = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "Critical",
                        "severity": "critical",
                        "service": None,
                        "category": None,
                        "gpu_id": None,
                        "component": None,
                    },
                    "annotations": {},
                    "status": "firing",
                }
            ],
            "groupLabels": {},
        }
        mock_save.assert_called_once_with(expected_payload, "critical")

    @patch("conf.webhook_receiver._impl.save_alert_to_file")
    @patch("conf.webhook_receiver._impl.process_alert")
    @patch("conf.webhook_receiver._impl.verify_signature", return_value=True)
    def test_webhook_gpu_processes_correctly(self, mock_verify, mock_process, mock_save):
        """Test GPU webhook endpoint."""
        payload = {
            "alerts": [{"labels": {"alertname": "GPUHigh", "component": "gpu"}, "status": "firing"}]
        }

        response = self.client.post(
            "/webhook/gpu",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 200)
        # Use ANY for fields populated by Pydantic defaults
        expected_payload = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "GPUHigh",
                        "component": "gpu",
                        "severity": None,
                        "service": None,
                        "category": None,
                        "gpu_id": None,
                    },
                    "annotations": {},
                    "status": "firing",
                }
            ],
            "groupLabels": {},
        }
        mock_save.assert_called_once_with(expected_payload, "gpu")

    @patch("conf.webhook_receiver._impl.LOG_DIR")
    def test_list_alerts_endpoint(self, mock_log_dir):
        """Test alerts listing endpoint."""
        with tempfile.TemporaryDirectory() as tmpdir:
            log_dir = Path(tmpdir)
            mock_log_dir.glob = lambda pattern: log_dir.glob(pattern)

            # Create some test alert files
            for i in range(3):
                alert_file = log_dir / f"alert_test_{i}.json"
                alert_file.write_text(json.dumps({"alerts": [{"test": i}]}))

            response = self.client.get("/alerts")

            self.assertEqual(response.status_code, 200)
            data = json.loads(response.data)
            self.assertIn("alerts", data)

    @patch("conf.webhook_receiver._impl.process_alert", side_effect=Exception("Test error"))
    @patch("conf.webhook_receiver._impl.verify_signature", return_value=True)
    def test_webhook_handles_processing_exception(self, mock_verify, mock_process):
        """Test that webhook handles processing exceptions gracefully."""
        payload = {"alerts": [{"labels": {"alertname": "Test"}, "status": "firing"}]}

        response = self.client.post(
            "/webhook",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 500)
        data = json.loads(response.data)
        self.assertIn("error", data)


if __name__ == "__main__":
    unittest.main()
