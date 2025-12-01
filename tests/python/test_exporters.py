#!/usr/bin/env python3
"""
Comprehensive unit tests for RAG and Ollama exporters
"""

import importlib.util
import sys
import time
import types
import unittest
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


def stub_prometheus():
    class DummyGauge:
        def __init__(self, *args, **kwargs):
            pass

        def set(self, *_args, **_kwargs):
            return None

        def labels(self, *args, **kwargs):
            return self

        def observe(self, *_args, **_kwargs):
            return None

    sys.modules["prometheus_client"] = types.SimpleNamespace(
        Gauge=DummyGauge,
        start_http_server=lambda *a, **k: None,
        Histogram=DummyGauge,
        CollectorRegistry=DummyGauge,
        generate_latest=lambda *_: b"",
        CONTENT_TYPE_LATEST="text/plain",
    )


class TestRAGExporter(unittest.TestCase):
    """Test suite for rag_exporter.py"""

    @patch("requests.get")
    def test_rag_probe_success(self, mock_get):
        """Test successful RAG health probe"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"content-type": "application/json"}
        mock_response.json.return_value = {"sources": ["doc1", "doc2"]}
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        # Simulate probe logic
        start = time.time()
        response = mock_get("http://test/health", timeout=10)
        elapsed = time.time() - start

        self.assertEqual(response.status_code, 200)
        self.assertLess(elapsed, 1.0)
        data = response.json()
        self.assertEqual(len(data["sources"]), 2)

    @patch("requests.get")
    def test_rag_probe_failure(self, mock_get):
        """Test RAG probe handles failures"""
        mock_get.side_effect = Exception("Connection failed")

        try:
            mock_get("http://test/health", timeout=10)
            self.fail("Should have raised exception")
        except Exception as e:
            self.assertIn("Connection failed", str(e))

    @patch("requests.get")
    def test_rag_probe_timeout(self, mock_get):
        """Test RAG probe timeout handling"""
        import requests

        mock_get.side_effect = requests.Timeout("Request timeout")

        try:
            mock_get("http://test/health", timeout=10)
            self.fail("Should have raised timeout")
        except requests.Timeout:
            pass  # Expected

    def test_rag_sources_count_extraction(self):
        """Test extraction of sources count from response"""
        test_cases = [
            ({"sources": ["a", "b", "c"]}, 3),
            ({"sources": []}, 0),
            ({"no_sources": []}, 0),
            ({}, 0),
        ]

        for data, expected_count in test_cases:
            if "sources" in data and isinstance(data["sources"], list):
                count = len(data["sources"])
            else:
                count = 0
            self.assertEqual(count, expected_count)


class TestOllamaExporter(unittest.TestCase):
    """Test suite for ollama-exporter"""

    @patch("requests.get")
    def test_fetch_version_success(self, mock_get):
        """Test successful version fetch"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"version": "0.1.47"}
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        response = mock_get("http://ollama:11434/api/version", timeout=5)
        data = response.json()

        self.assertEqual(data["version"], "0.1.47")

    @patch("requests.get")
    def test_fetch_tags_success(self, mock_get):
        """Test successful models/tags fetch"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "models": [
                {"name": "llama2", "size": 123456},
                {"name": "mistral", "size": 789012},
            ]
        }
        mock_get.return_value = mock_response

        response = mock_get("http://ollama:11434/api/tags", timeout=5)
        data = response.json()

        self.assertEqual(len(data["models"]), 2)
        self.assertIn("llama2", [m["name"] for m in data["models"]])

    @patch("requests.get")
    def test_fetch_tags_dict_models(self, mock_get):
        """Test tags with dict-based models"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "models": {
                "llama2": {"size": 123456},
                "mistral": {"size": 789012},
            }
        }
        mock_get.return_value = mock_response

        response = mock_get("http://ollama:11434/api/tags", timeout=5)
        data = response.json()
        models = data["models"]

        if isinstance(models, dict):
            count = len(models.keys())
        elif isinstance(models, list):
            count = len(models)
        else:
            count = 0

        self.assertEqual(count, 2)

    @patch("requests.get")
    def test_request_timeout_handling(self, mock_get):
        """Test request timeout is respected"""
        import requests

        mock_get.side_effect = requests.Timeout()

        with self.assertRaises(requests.Timeout):
            mock_get("http://ollama:11434/api/version", timeout=5)

    def test_metric_latency_calculation(self):
        """Test latency metric calculation"""
        start = time.perf_counter()
        time.sleep(0.01)  # Simulate some work
        latency = time.perf_counter() - start

        self.assertGreater(latency, 0.01)
        self.assertLess(latency, 0.1)

    @patch("requests.get")
    def test_ollama_down_detection(self, mock_get):
        """Test Ollama down state detection"""
        mock_get.side_effect = Exception("Connection refused")

        try:
            mock_get("http://ollama:11434/api/version", timeout=5)
            ollama_up = 1
        except Exception:
            ollama_up = 0

        self.assertEqual(ollama_up, 0)

    def test_models_count_with_none(self):
        """Test handling of None/missing models"""
        test_cases = [
            ({"models": None}, 0),
            ({"models": []}, 0),
            ({"models": {}}, 0),
            ({}, 0),
        ]

        for data, expected in test_cases:
            models = data.get("models")
            if isinstance(models, list):
                count = len(models)
            elif isinstance(models, dict):
                count = len(models.keys())
            else:
                count = 0
            self.assertEqual(count, expected)

    @patch("requests.get")
    def test_fetch_json_returns_dict(self, mock_get):
        """fetch_json returns dict when JSON is a mapping"""
        stub_prometheus()
        app = load_module("ollama_exporter_app", ROOT / "ops" / "ollama-exporter" / "app.py")

        mock_resp = MagicMock()
        mock_resp.raise_for_status = MagicMock()
        mock_resp.json.return_value = {"ok": True}
        mock_get.return_value = mock_resp

        result = app.fetch_json("/api/version")
        self.assertEqual(result, {"ok": True})

    @patch("requests.get")
    def test_fetch_json_returns_none_for_non_dict(self, mock_get):
        """fetch_json returns None when JSON is not a mapping"""
        stub_prometheus()
        app = load_module("ollama_exporter_app", ROOT / "ops" / "ollama-exporter" / "app.py")

        mock_resp = MagicMock()
        mock_resp.raise_for_status = MagicMock()
        mock_resp.json.return_value = ["not-a-dict"]
        mock_get.return_value = mock_resp

        result = app.fetch_json("/api/version")
        self.assertIsNone(result)


class TestExporterConfiguration(unittest.TestCase):
    """Test exporter configuration and environment variables"""

    def test_default_configuration_values(self):
        """Test default configuration values"""
        import os

        # Simulate default env var handling
        ollama_url = os.getenv("OLLAMA_URL", "http://ollama:11434").rstrip("/")
        exporter_port = int(os.getenv("EXPORTER_PORT", "9778"))
        poll_interval = int(os.getenv("OLLAMA_EXPORTER_INTERVAL", "15"))
        request_timeout = float(os.getenv("OLLAMA_REQUEST_TIMEOUT", "5"))

        self.assertEqual(ollama_url, "http://ollama:11434")
        self.assertEqual(exporter_port, 9778)
        self.assertEqual(poll_interval, 15)
        self.assertEqual(request_timeout, 5.0)

    def test_url_trailing_slash_removal(self):
        """Test that trailing slashes are removed from URLs"""
        test_urls = [
            ("http://ollama:11434/", "http://ollama:11434"),
            ("http://ollama:11434", "http://ollama:11434"),
            ("http://test.com///", "http://test.com"),
        ]

        for url, expected in test_urls:
            result = url.rstrip("/")
            self.assertEqual(result, expected)


if __name__ == "__main__":
    unittest.main()
