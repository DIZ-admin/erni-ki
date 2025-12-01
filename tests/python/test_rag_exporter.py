#!/usr/bin/env python3
"""Tests for conf/rag_exporter.py."""

from __future__ import annotations

from unittest.mock import MagicMock, patch


@patch("conf.rag_exporter.requests.get")
def test_probe_success_sets_metrics(mock_get):
    from conf import rag_exporter

    mock_resp = MagicMock()
    mock_resp.headers = {"content-type": "application/json"}
    mock_resp.json.return_value = {"sources": ["a", "b"]}
    mock_resp.raise_for_status = MagicMock()
    mock_get.return_value = mock_resp

    # run single iteration of probe loop body
    rag_exporter.rag_sources.set(0)
    rag_exporter.rag_latency.observe(0.0)
    with patch.object(rag_exporter, "_shutdown_event") as evt:
        evt.is_set.return_value = True
        rag_exporter.probe_loop()

    # After successful probe, sources gauge should be set to len(sources)
    assert rag_exporter.rag_sources._value.get() == 2  # type: ignore[attr-defined]


def test_metrics_endpoint_returns_content():
    from conf import rag_exporter

    client = rag_exporter.app.test_client()
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert resp.data  # non-empty metrics payload
