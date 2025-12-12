#!/usr/bin/env python3
"""Negative tests for webhook_handler signature/validation paths."""

from __future__ import annotations

import hashlib
import hmac
import importlib.util
import os
import sys
from pathlib import Path
from typing import Any

import pytest

try:
    import flask  # noqa: F401
except ImportError:  # pragma: no cover
    pytest.skip("flask not installed", allow_module_level=True)

ROOT = Path(__file__).resolve().parents[2]


def load_webhook_handler():
    os.environ["ALERTMANAGER_WEBHOOK_SECRET"] = "x" * 32  # noqa: S105
    module_path = ROOT / "conf" / "webhook-receiver" / "webhook_handler.py"
    spec = importlib.util.spec_from_file_location("webhook_handler_neg", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook_handler from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["webhook_handler_neg"] = module
    spec.loader.exec_module(module)
    return module


def test_verify_signature_valid():
    wh = load_webhook_handler()
    body = b"{}"
    secret = "test-secret"  # noqa: S105  # pragma: allowlist secret
    os.environ["ALERTMANAGER_WEBHOOK_SECRET"] = secret
    wh.WEBHOOK_SECRET = secret
    sig = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    assert wh.verify_signature(body, sig) is True


def test_verify_signature_invalid():
    wh = load_webhook_handler()
    body = b"{}"
    secret = "another-secret"  # noqa: S105  # pragma: allowlist secret
    os.environ["ALERTMANAGER_WEBHOOK_SECRET"] = secret
    wh.WEBHOOK_SECRET = secret
    assert wh.verify_signature(body, "bad") is False


def test_validate_request_missing_signature(monkeypatch):
    """_validate_request should raise PermissionError when signature missing/invalid."""
    wh = load_webhook_handler()

    class DummyReq:
        def __init__(self):
            self.headers = {}

        def get_data(self) -> bytes:
            return b"{}"

        def get_json(self, force: bool = False) -> dict[str, Any]:
            return {"alerts": []}

    monkeypatch.setattr(wh, "request", DummyReq())
    wh.WEBHOOK_SECRET = "secret"  # noqa: S105  # pragma: allowlist secret
    try:
        wh._validate_request()
        raised = False
    except PermissionError:
        raised = True
    assert raised
