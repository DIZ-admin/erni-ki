#!/usr/bin/env python3
"""Tests for conf/webhook-receiver/services.py."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


def load_services():
    module_path = ROOT / "conf" / "webhook-receiver" / "services.py"
    spec = importlib.util.spec_from_file_location("services_module", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load services from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["services_module"] = module
    spec.loader.exec_module(module)
    return module


def test_run_recovery_script_success(tmp_path, caplog, monkeypatch):
    """Happy path: executable script runs and logs output."""
    services = load_services()
    caplog.set_level("INFO")

    script_path = tmp_path / "svc.sh"
    script_path.write_text("#!/bin/bash\necho ok")
    script_path.chmod(0o755)

    monkeypatch.setattr(services, "RECOVERY_DIR", tmp_path)
    monkeypatch.setattr(services, "RECOVERY_SCRIPTS", {"svc": script_path.name})
    monkeypatch.setattr(services, "ALLOWED_SERVICES", {"svc"})

    services.run_recovery_script("svc")
    # Should log invocation without error
    assert "svc" in caplog.text


def test_run_recovery_script_handles_timeout(monkeypatch, caplog, tmp_path):
    """Timeouts are logged and do not raise."""
    services = load_services()
    caplog.set_level("INFO")

    script_path = tmp_path / "svc.sh"
    script_path.write_text("#!/bin/bash\necho slow")
    script_path.chmod(0o755)

    monkeypatch.setattr(services, "RECOVERY_DIR", tmp_path)
    monkeypatch.setattr(services, "RECOVERY_SCRIPTS", {"svc": script_path.name})
    monkeypatch.setattr(services, "ALLOWED_SERVICES", {"svc"})

    with patch.object(services, "run", side_effect=subprocess.TimeoutExpired(cmd="svc", timeout=1)):
        services.run_recovery_script("svc")

    assert "timeout" in caplog.text.lower()


def test_run_recovery_script_rejects_traversal(monkeypatch, caplog, tmp_path):
    """Mapping with path traversal component is rejected by _path_within."""
    services = load_services()

    monkeypatch.setattr(services, "RECOVERY_DIR", tmp_path)
    monkeypatch.setattr(services, "RECOVERY_SCRIPTS", {"svc": "../bad.sh"})
    monkeypatch.setattr(services, "ALLOWED_SERVICES", {"svc"})

    services.run_recovery_script("svc")

    assert "Path traversal" in caplog.text


def test_process_alert_handles_invalid_payload(caplog):
    """Invalid structures should be logged without raising."""
    services = load_services()

    services.process_alert({"alerts": "invalid"})

    assert "Invalid alert data structure" in caplog.text or "Unexpected error" in caplog.text
