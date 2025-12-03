#!/usr/bin/env python3
"""Tests for ops/ollama-exporter/app.py."""

from __future__ import annotations

import importlib.util
import sys
import types
from pathlib import Path
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[2]


def load_app():
    if "ollama_exporter_app" in sys.modules:
        return sys.modules["ollama_exporter_app"]
    module_path = ROOT / "ops" / "ollama-exporter" / "app.py"
    spec = importlib.util.spec_from_file_location("ollama_exporter_app", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["ollama_exporter_app"] = module
    spec.loader.exec_module(module)
    return module


def test_fetch_json_success_sets_latency(monkeypatch):
    app = load_app()

    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json.return_value = {"version": "1.0.0"}
    lat_mock = MagicMock()
    monkeypatch.setattr(app, "OLLAMA_REQUEST_LATENCY", lat_mock)

    with patch.object(app.requests, "get", return_value=resp):
        data = app.fetch_json("/api/version")

    assert data == {"version": "1.0.0"}
    lat_mock.set.assert_called()


def test_fetch_json_timeout_returns_none(monkeypatch):
    app = load_app()

    monkeypatch.setattr(app, "OLLAMA_REQUEST_LATENCY", MagicMock())
    with patch.object(app.requests, "get", side_effect=app.requests.Timeout):
        assert app.fetch_json("/api/version") is None


def test_poll_forever_updates_metrics(monkeypatch):
    app = load_app()

    fake_event = types.SimpleNamespace()
    fake_event.is_set = MagicMock(side_effect=[False, True])
    fake_event.wait = MagicMock()

    monkeypatch.setattr(app, "_STOP_EVENT", fake_event)
    monkeypatch.setattr(
        app,
        "fetch_json",
        MagicMock(side_effect=[{"version": "1.2.3"}, {"models": ["a", "b"]}]),
    )

    gauge_mock = MagicMock()
    monkeypatch.setattr(app, "OLLAMA_UP", gauge_mock)
    monkeypatch.setattr(
        app,
        "OLLAMA_VERSION_INFO",
        MagicMock(labels=MagicMock(return_value=MagicMock(set=MagicMock()))),
    )
    monkeypatch.setattr(app, "OLLAMA_INSTALLED_MODELS", MagicMock(set=MagicMock()))

    app.poll_forever()

    gauge_mock.set.assert_called()
