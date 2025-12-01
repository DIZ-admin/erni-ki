#!/usr/bin/env python3
"""Tests for webhook-receiver.py signature/health paths."""

from __future__ import annotations

import hashlib
import hmac
import importlib.util
import sys
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


def load_webhook_receiver():
    module_path = ROOT / "conf" / "webhook-receiver" / "webhook-receiver.py"
    spec = importlib.util.spec_from_file_location("webhook_receiver_neg", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook-receiver from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["webhook_receiver_neg"] = module
    spec.loader.exec_module(module)
    return module


def test_verify_signature_valid():
    wh = load_webhook_receiver()
    body = b"{}"
    secret = "secret"  # noqa: S105
    wh.WEBHOOK_SECRET = secret
    sig = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    assert wh.verify_signature(body, sig) is True


def test_verify_signature_invalid():
    wh = load_webhook_receiver()
    body = b"{}"
    wh.WEBHOOK_SECRET = "secret"  # noqa: S105
    assert wh.verify_signature(body, "bad") is False


def test_webhook_missing_signature():
    wh = load_webhook_receiver()
    client = wh.app.test_client()
    resp = client.post("/webhook", json={"alerts": []})
    assert resp.status_code == 401


def test_webhook_health():
    wh = load_webhook_receiver()
    client = wh.app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["status"] == "healthy"


def test_webhook_critical_with_valid_signature():
    wh = load_webhook_receiver()
    client = wh.app.test_client()
    body = {"alerts": [{"labels": {"alertname": "X"}, "status": "firing"}]}
    raw = wh.json.dumps(body).encode()
    secret = "secret"  # noqa: S105
    wh.WEBHOOK_SECRET = secret
    sig = hmac.new(secret.encode(), raw, hashlib.sha256).hexdigest()
    with (
        patch.object(wh, "save_alert_to_file") as mock_save,
        patch.object(wh, "process_alert") as mock_process,
    ):
        resp = client.post(
            "/webhook/critical",
            data=raw,
            headers={"Content-Type": "application/json", "X-Signature": sig},
        )
    assert resp.status_code == 200
    mock_save.assert_called_once()
    mock_process.assert_called_once()
