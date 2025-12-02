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

    rag_sources_mock = MagicMock()
    rag_latency_mock = MagicMock()
    with (
        patch.object(rag_exporter, "rag_sources", rag_sources_mock),
        patch.object(rag_exporter, "rag_latency", rag_latency_mock),
        patch.object(rag_exporter, "_shutdown_event") as evt,
    ):
        evt.is_set.side_effect = [False, True]
        evt.wait.return_value = None
        rag_exporter.probe_loop()

    rag_sources_mock.set.assert_called_with(2)
    rag_latency_mock.observe.assert_called()  # observed latency


def test_metrics_endpoint_returns_content():
    from conf import rag_exporter

    with patch("conf.rag_exporter.generate_latest", return_value=b"metrics"):  # type: ignore[attr-defined]
        client = rag_exporter.app.test_client()
        resp = client.get("/metrics")
        assert resp.status_code == 200
        assert resp.data == b"metrics"


@patch("conf.rag_exporter._shutdown_event")
def test_main_graceful_shutdown(mock_evt):
    """main should start thread and honor shutdown event immediately."""
    mock_evt.is_set.return_value = True
    with (
        patch("conf.rag_exporter.threading.Thread") as mock_thread,
        patch("conf.rag_exporter.app.run") as mock_run,
    ):
        from conf import rag_exporter

        rag_exporter.main()
        mock_thread.assert_called_once()
        mock_run.assert_called_once()
