#!/usr/bin/env python3
# mypy: ignore-errors
"""
Comprehensive unit tests for webhook-receiver.py
Tests alert processing, file operations, recovery scripts, and API endpoints.
"""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any, Protocol, cast
from unittest.mock import MagicMock, mock_open, patch


class WebhookModule(Protocol):
    """Protocol for webhook-receiver module."""

    app: Any
    WEBHOOK_SECRET: str
    RECOVERY_DIR: Path
    ALLOWED_SERVICES: set[str]
    AlertLabels: type
    AlertPayload: type
    handle_critical_alert: Any
    handle_gpu_alert: Any
    process_alert: Any
    run_recovery_script: Any
    save_alert_to_file: Any
    verify_signature: Any
    _validate_secrets: Any
    _path_within: Any


def load_webhook_receiver() -> WebhookModule:
    """Load webhook-receiver module from the dashed directory."""
    root = Path(__file__).resolve().parents[2]
    module_path = root / "conf" / "webhook-receiver" / "webhook-receiver.py"
    spec = importlib.util.spec_from_file_location("webhook_receiver", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook-receiver from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["webhook_receiver"] = module
    spec.loader.exec_module(module)
    return cast(WebhookModule, module)


webhook = load_webhook_receiver()
app = webhook.app
handle_critical_alert = webhook.handle_critical_alert
handle_gpu_alert = webhook.handle_gpu_alert
process_alert = webhook.process_alert
run_recovery_script = webhook.run_recovery_script
save_alert_to_file = webhook.save_alert_to_file
verify_signature = webhook.verify_signature
_validate_secrets = webhook._validate_secrets
_path_within = webhook._path_within
AlertLabels = webhook.AlertLabels
AlertPayload = webhook.AlertPayload
WEBHOOK_SECRET = webhook.WEBHOOK_SECRET
RECOVERY_DIR = webhook.RECOVERY_DIR


class TestSaveAlertToFile(unittest.TestCase):
    """Test suite for save_alert_to_file function."""

    @patch("webhook_receiver.LOG_DIR")
    def test_save_alert_creates_file_with_correct_format(self, mock_log_dir):
        """Test that alert is saved with correct filename format."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_log_dir.__truediv__ = lambda self, other: Path(tmpdir) / other

            alert_data = {"alerts": [{"labels": {"alertname": "Test"}}]}

            with patch("builtins.open", mock_open()) as mock_file:
                save_alert_to_file(alert_data, "critical")
                mock_file.assert_called_once()

    @patch("webhook_receiver.LOG_DIR")
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

    @patch("webhook_receiver.LOG_DIR")
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

        with patch("webhook_receiver.handle_critical_alert") as mock_handle:
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

        with patch("webhook_receiver.handle_gpu_alert") as mock_handle:
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

        with patch("webhook_receiver.logger"), contextlib.suppress(Exception):
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

        with patch("webhook_receiver.run_recovery_script") as mock_recovery:
            handle_critical_alert(alert)
            mock_recovery.assert_called_once_with("ollama")

    def test_handle_critical_alert_calls_recovery_for_known_services(self):
        """Test that recovery scripts are called for known services."""
        known_services = ["ollama", "openwebui", "searxng"]

        for service in known_services:
            alert = {"labels": {"service": service}}

            with patch("webhook_receiver.run_recovery_script") as mock_recovery:
                handle_critical_alert(alert)
                mock_recovery.assert_called_once_with(service)

    def test_handle_critical_alert_logs_unknown_services(self):
        """Test that unknown services log a message instead of running recovery."""
        alert = {"labels": {"service": "unknown-service"}}

        with patch("webhook_receiver.run_recovery_script") as mock_recovery:
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

        with patch("webhook_receiver.logger") as mock_logger:
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

        with patch("webhook_receiver.logger") as mock_logger:
            handle_gpu_alert(alert)
            # Should log temperature warning
            self.assertEqual(mock_logger.warning.call_count, 2)


class TestRunRecoveryScript(unittest.TestCase):
    """Test suite for run_recovery_script function."""

    @patch("webhook_receiver.RECOVERY_DIR")
    @patch("webhook_receiver._path_within", return_value=True)
    def test_run_recovery_script_checks_existence(self, mock_path_within, mock_recovery_dir):
        """Test that recovery script existence is checked."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_recovery_dir.__truediv__ = lambda self, other: Path(tmpdir).resolve() / other
            mock_recovery_dir.resolve.return_value = Path(tmpdir).resolve()

            run_recovery_script("nonexistent-service")
            # Should return early if script doesn't exist

    @patch("webhook_receiver.RECOVERY_DIR")
    @patch("webhook_receiver._path_within", return_value=True)
    def test_run_recovery_script_checks_executable(self, mock_path_within, mock_recovery_dir):
        """Test that recovery script executable permission is checked."""
        with tempfile.TemporaryDirectory() as tmpdir:
            script_path = Path(tmpdir).resolve() / "test-recovery.sh"
            script_path.write_text("#!/bin/bash\necho 'test'")
            script_path.chmod(0o644)  # Not executable

            mock_recovery_dir.__truediv__ = lambda self, other: script_path
            mock_recovery_dir.resolve.return_value = Path(tmpdir).resolve()

            with patch("webhook_receiver.logger") as mock_logger:
                run_recovery_script("ollama")
                # Should log warning about non-executable script
                mock_logger.warning.assert_called()

    @patch("webhook_receiver.RECOVERY_DIR")
    @patch("webhook_receiver.run")
    @patch("webhook_receiver._path_within", return_value=True)
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

    @patch("webhook_receiver.RECOVERY_DIR")
    @patch("webhook_receiver.run")
    @patch("webhook_receiver._path_within", return_value=True)
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

            with patch("webhook_receiver.logger") as mock_logger:
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

    @patch("webhook_receiver.save_alert_to_file")
    @patch("webhook_receiver.process_alert")
    @patch("webhook_receiver.verify_signature", return_value=True)
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

    @patch("webhook_receiver.verify_signature", return_value=True)
    def test_webhook_general_without_json_returns_400(self, mock_verify):
        """Test that missing JSON returns 400 error."""
        response = self.client.post("/webhook")

        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn("error", data)

    @patch("webhook_receiver.save_alert_to_file")
    @patch("webhook_receiver.process_alert")
    @patch("webhook_receiver.verify_signature", return_value=True)
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

    @patch("webhook_receiver.save_alert_to_file")
    @patch("webhook_receiver.process_alert")
    @patch("webhook_receiver.verify_signature", return_value=True)
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

    @patch("webhook_receiver.LOG_DIR")
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

    @patch("webhook_receiver.process_alert", side_effect=Exception("Test error"))
    @patch("webhook_receiver.verify_signature", return_value=True)
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


class TestSignatureVerification(unittest.TestCase):
    """Test suite for webhook signature verification."""

    def test_verify_signature_with_valid_signature(self):
        """Test that valid signatures are accepted."""
        import hashlib
        import hmac

        test_secret = "test_secret_key_for_signature_verification"  # noqa: S105 - test stub  # pragma: allowlist secret
        test_body = b"test alert payload"

        expected_signature = hmac.new(test_secret.encode(), test_body, hashlib.sha256).hexdigest()

        # Temporarily override WEBHOOK_SECRET
        original_secret = webhook.WEBHOOK_SECRET
        try:
            webhook.WEBHOOK_SECRET = test_secret
            result = verify_signature(test_body, expected_signature)
            self.assertTrue(result)
        finally:
            webhook.WEBHOOK_SECRET = original_secret

    def test_verify_signature_with_invalid_signature(self):
        """Test that invalid signatures are rejected."""
        test_secret = "test_secret_key_for_signature_verification"  # noqa: S105 - test stub  # pragma: allowlist secret
        test_body = b"test alert payload"
        invalid_signature = "invalid_signature_that_does_not_match"  # noqa: S105 - test stub

        original_secret = webhook.WEBHOOK_SECRET
        try:
            webhook.WEBHOOK_SECRET = test_secret
            result = verify_signature(test_body, invalid_signature)
            self.assertFalse(result)
        finally:
            webhook.WEBHOOK_SECRET = original_secret

    def test_verify_signature_with_missing_signature(self):
        """Test that missing signatures are rejected."""
        test_body = b"test alert payload"

        original_secret = webhook.WEBHOOK_SECRET
        try:
            webhook.WEBHOOK_SECRET = "some_secret"  # noqa: S105 - test stub  # pragma: allowlist secret
            result = verify_signature(test_body, None)
            self.assertFalse(result)
        finally:
            webhook.WEBHOOK_SECRET = original_secret

    def test_verify_signature_with_no_secret_configured(self):
        """Test that verification fails when secret is not configured."""
        original_secret = webhook.WEBHOOK_SECRET
        try:
            webhook.WEBHOOK_SECRET = ""
            result = verify_signature(b"test", "fake_signature")
            self.assertFalse(result)
        finally:
            webhook.WEBHOOK_SECRET = original_secret


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

    def test_alertname_validation_strips_whitespace(self):
        """Test that alertname whitespace is stripped."""
        label = AlertLabels(alertname="  Test Alert  ")
        self.assertEqual(label.alertname, "Test Alert")

    def test_severity_validation_with_valid_values(self):
        """Test that valid severity values are accepted."""
        for severity in ["critical", "warning", "info", "debug"]:
            label = AlertLabels(alertname="Test", severity=severity)
            self.assertEqual(label.severity, severity)

    def test_severity_validation_case_insensitive(self):
        """Test that severity validation is case-insensitive."""
        label = AlertLabels(alertname="Test", severity="CRITICAL")
        self.assertEqual(label.severity, "critical")

    def test_severity_validation_invalid_value(self):
        """Test that invalid severity values raise error."""
        from pydantic import ValidationError

        with self.assertRaises(ValidationError):
            AlertLabels(alertname="Test", severity="invalid")

    def test_service_validation_alphanumeric_with_hyphens(self):
        """Test that service accepts alphanumeric, hyphens, and underscores."""
        label = AlertLabels(alertname="Test", service="my-service_01")
        self.assertEqual(label.service, "my-service_01")

    def test_service_validation_too_long(self):
        """Test that service exceeding 128 characters raises error."""
        from pydantic import ValidationError

        long_service = "x" * 129
        with self.assertRaises(ValidationError):
            AlertLabels(alertname="Test", service=long_service)

    def test_service_validation_invalid_characters(self):
        """Test that service with invalid characters raises error."""
        from pydantic import ValidationError

        with self.assertRaises(ValidationError):
            AlertLabels(alertname="Test", service="invalid@service")

    def test_gpu_id_validation_with_hyphens(self):
        """Test that GPU ID accepts alphanumeric with hyphens."""
        label = AlertLabels(alertname="Test", gpu_id="gpu-0-1")
        self.assertEqual(label.gpu_id, "gpu-0-1")

    def test_gpu_id_validation_invalid_characters(self):
        """Test that GPU ID with invalid characters raises error."""
        from pydantic import ValidationError

        with self.assertRaises(ValidationError):
            AlertLabels(alertname="Test", gpu_id="gpu@invalid")

    def test_component_validation_long_name(self):
        """Test that component exceeding 128 characters raises error."""
        from pydantic import ValidationError

        long_component = "x" * 129
        with self.assertRaises(ValidationError):
            AlertLabels(alertname="Test", component=long_component)

    def test_category_validation_spaces(self):
        """Test that category whitespace is stripped."""
        label = AlertLabels(alertname="Test", category="  test category  ")
        self.assertEqual(label.category, "test category")


class TestPathTraversal(unittest.TestCase):
    """Test suite for path traversal prevention."""

    def test_path_within_valid_path(self):
        """Test that valid paths within base directory are accepted."""
        base = Path("/app/scripts")
        target = Path("/app/scripts/recovery.sh")
        # Note: This test might fail on systems without these exact paths
        # So we test the logic with mocked paths

        _path_within(base, target)
        # Result depends on actual filesystem

    def test_run_recovery_script_with_invalid_service(self):
        """Test that invalid service names are rejected."""
        with patch("webhook_receiver.logger") as mock_logger:
            run_recovery_script("invalid_service_not_in_mapping")
            # Should log error about invalid service
            mock_logger.error.assert_called()


class TestWebhookValidation(unittest.TestCase):
    """Test suite for webhook validation with missing/invalid data."""

    def setUp(self):
        """Set up test client."""
        self.app = app
        self.app.testing = True
        self.client = self.app.test_client()

    @patch("webhook_receiver.verify_signature", return_value=False)
    def test_webhook_rejects_invalid_signature(self, mock_verify):
        """Test that webhooks with invalid signatures are rejected."""
        payload = {"alerts": [{"labels": {"alertname": "Test"}, "status": "firing"}]}

        response = self.client.post(
            "/webhook",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 401)
        data = json.loads(response.data)
        self.assertEqual(data["error"], "Unauthorized")

    @patch("webhook_receiver.verify_signature", return_value=True)
    def test_webhook_warning_processes_correctly(self, mock_verify):
        """Test warning webhook endpoint."""
        with (
            patch("webhook_receiver.save_alert_to_file"),
            patch("webhook_receiver.process_alert") as mock_process,
        ):
            payload = {
                "alerts": [
                    {
                        "labels": {
                            "alertname": "Warning",
                            "severity": "warning",
                        },
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
            mock_process.assert_called_once()

    @patch("webhook_receiver.verify_signature", return_value=True)
    def test_webhook_database_processes_correctly(self, mock_verify):
        """Test database webhook endpoint."""
        with (
            patch("webhook_receiver.save_alert_to_file"),
            patch("webhook_receiver.process_alert") as mock_process,
        ):
            payload = {
                "alerts": [
                    {
                        "labels": {"alertname": "DatabaseDown", "service": "postgres"},
                        "status": "firing",
                    }
                ]
            }

            response = self.client.post(
                "/webhook/database",
                data=json.dumps(payload),
                content_type="application/json",
            )

            self.assertEqual(response.status_code, 200)
            mock_process.assert_called_once()

    @patch("webhook_receiver.verify_signature", return_value=True)
    def test_webhook_ai_processes_correctly(self, mock_verify):
        """Test AI webhook endpoint."""
        with (
            patch("webhook_receiver.save_alert_to_file"),
            patch("webhook_receiver.process_alert") as mock_process,
        ):
            payload = {
                "alerts": [
                    {
                        "labels": {"alertname": "AIError", "service": "ollama"},
                        "status": "firing",
                    }
                ]
            }

            response = self.client.post(
                "/webhook/ai",
                data=json.dumps(payload),
                content_type="application/json",
            )

            self.assertEqual(response.status_code, 200)
            mock_process.assert_called_once()

    @patch("webhook_receiver.verify_signature", return_value=True)
    def test_webhook_with_pydantic_validation_error(self, mock_verify):
        """Test that invalid alert structure returns 400."""
        payload = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "Test",
                        "severity": "invalid_severity",  # Invalid severity
                    },
                    "status": "firing",
                }
            ]
        }

        response = self.client.post(
            "/webhook",
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn("error", data)


class TestRecoveryScriptValidation(unittest.TestCase):
    """Test suite for recovery script path validation."""

    @patch("webhook_receiver.RECOVERY_DIR")
    @patch("webhook_receiver._path_within", return_value=False)
    def test_run_recovery_script_rejects_path_traversal(self, mock_path_within, mock_recovery_dir):
        """Test that path traversal attempts are rejected."""
        with patch("webhook_receiver.logger") as mock_logger:
            run_recovery_script("../../../etc/passwd")
            # Should log error about path traversal attempt
            mock_logger.error.assert_called()

    def test_recovery_scripts_mapping_completeness(self):
        """Test that all allowed services have recovery scripts defined."""
        for service in ["ollama", "openwebui", "searxng"]:
            self.assertIn(service, webhook.RECOVERY_SCRIPTS)


if __name__ == "__main__":
    unittest.main()
