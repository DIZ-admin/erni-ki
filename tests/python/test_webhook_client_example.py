#!/usr/bin/env python3
"""Tests for docs/examples/webhook-client-python.py."""

from __future__ import annotations

import hashlib
import hmac
import importlib.util
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[2]


def load_client():
    module_path = ROOT / "docs" / "examples" / "webhook-client-python.py"
    spec = importlib.util.spec_from_file_location("webhook_client_example", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["webhook_client_example"] = module
    spec.loader.exec_module(module)
    return module


def test_generate_signature_and_payload():
    client = load_client()

    test_secret = "secret"  # noqa: S105  # pragma: allowlist secret
    cli = client.WebhookClient(base_url="http://localhost:9093", webhook_secret=test_secret)
    body = b"{}"
    sig = cli._generate_signature(body)
    assert sig == hmac.new(b"secret", body, hashlib.sha256).hexdigest()

    payload = cli._build_alert_payload(alert_name="Test", severity="critical", summary="s")
    assert payload["alerts"][0]["labels"]["severity"] == "critical"
    assert payload["alerts"][0]["annotations"]["summary"] == "s"


def test_send_alert_timeout_returns_error():
    client = load_client()

    test_secret = "secret"  # noqa: S105  # pragma: allowlist secret
    cli = client.WebhookClient(base_url="http://localhost:9093", webhook_secret=test_secret)

    with patch.object(client.requests, "post", side_effect=client.requests.Timeout):
        result = cli.send_alert(endpoint="generic", alert_name="Test")
        assert result["status"] == "failed"
        assert "timeout" in result["error"].lower()


def test_send_alert_success_parses_dict():
    client = load_client()

    test_secret = "secret"  # noqa: S105  # pragma: allowlist secret
    cli = client.WebhookClient(base_url="http://localhost:9093", webhook_secret=test_secret)
    fake_resp = MagicMock()
    fake_resp.raise_for_status = MagicMock()
    fake_resp.json.return_value = {"status": "ok"}
    fake_resp.text = "{}"

    with patch.object(client.requests, "post", return_value=fake_resp):
        result = cli.send_alert(endpoint="critical", alert_name="X", severity="critical")
        assert result["status"] == "ok"
