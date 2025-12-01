#!/usr/bin/env python3
"""Tests for docs/examples/webhook-client-python.py."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[2]


def load_module(module_name: str, file_path: Path):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module from {file_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


@patch("requests.post")
def test_send_alert_returns_dict(mock_post: MagicMock):
    """send_alert should return parsed dict when response JSON is dict."""
    webhook_client = load_module(
        "webhook_client_example",
        ROOT / "docs" / "examples" / "webhook-client-python.py",
    )
    WebhookClient = webhook_client.WebhookClient

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {"status": "success", "from": "mock"}
    mock_response.text = "{}"
    mock_post.return_value = mock_response

    test_secret = "test-secret"  # noqa: S105 pragma: allowlist secret
    client = WebhookClient(base_url="http://localhost:9093", webhook_secret=test_secret)
    resp = client.send_alert(
        endpoint="critical",
        alert_name="TestAlert",
        severity="critical",
        summary="Test summary",
        labels={"service": "api"},
    )

    assert resp["status"] == "success"
    mock_post.assert_called_once()
    call_kwargs = mock_post.call_args.kwargs
    assert call_kwargs["headers"]["X-Signature"]
    assert call_kwargs["headers"]["Content-Type"] == "application/json"
    body = call_kwargs["data"]
    assert isinstance(body, (bytes, bytearray))
    assert b" " not in body


@patch("requests.post")
def test_send_alert_handles_non_dict_json(mock_post: MagicMock):
    """send_alert falls back to raw_response when JSON is not a dict."""
    webhook_client = load_module(
        "webhook_client_example",
        ROOT / "docs" / "examples" / "webhook-client-python.py",
    )
    WebhookClient = webhook_client.WebhookClient

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = ["not-a-dict"]
    mock_response.text = '["not-a-dict"]'
    mock_post.return_value = mock_response

    test_secret = "test-secret"  # noqa: S105 pragma: allowlist secret
    client = WebhookClient(base_url="http://localhost:9093", webhook_secret=test_secret)
    resp = client.send_alert(
        endpoint="warning",
        alert_name="Test",
        severity="warning",
        summary="Test summary",
    )

    assert resp["raw_response"] == ["not-a-dict"]


@patch("requests.post")
def test_send_alert_handles_jsondecode_error(mock_post: MagicMock):
    """send_alert returns raw_response when JSON decode fails."""
    from json import JSONDecodeError

    webhook_client = load_module(
        "webhook_client_example",
        ROOT / "docs" / "examples" / "webhook-client-python.py",
    )
    WebhookClient = webhook_client.WebhookClient

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.side_effect = JSONDecodeError("err", "", 0)
    mock_response.text = "not-json"
    mock_post.return_value = mock_response

    test_secret = "test-secret"  # noqa: S105 pragma: allowlist secret
    client = WebhookClient(base_url="http://localhost:9093", webhook_secret=test_secret)
    resp = client.send_alert(endpoint="generic", alert_name="Test", summary="x")

    assert resp["raw_response"] == "not-json"


def test_generate_signature():
    """_generate_signature returns deterministic HMAC."""
    webhook_client = load_module(
        "webhook_client_example",
        ROOT / "docs" / "examples" / "webhook-client-python.py",
    )
    WebhookClient = webhook_client.WebhookClient

    test_secret = "test-secret"  # noqa: S105 pragma: allowlist secret
    client = WebhookClient(base_url="http://localhost:9093", webhook_secret=test_secret)
    body = json.dumps({"a": 1}).encode()
    sig1 = client._generate_signature(body)
    sig2 = client._generate_signature(body)
    assert sig1 == sig2
