import contextlib
import logging
import os
import signal
import threading
import time
from typing import Any

import requests
from flask import Flask, Response
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Gauge,
    Histogram,
    generate_latest,
)

# Configuration constants
DEFAULT_RAG_TEST_INTERVAL = 30.0  # seconds
DEFAULT_RAG_TEST_URL = "https://openwebui:8080/health"
DEFAULT_RAG_VERIFY_TLS = "true"
DEFAULT_REQUEST_TIMEOUT = 10  # seconds
DEFAULT_PORT = 9808
FALLBACK_LATENCY = 10.0  # seconds, when RAG check fails
RAG_LATENCY_BUCKETS = (0.25, 0.5, 1, 2, 3, 5, 10)  # seconds

app = Flask(__name__)
logger = logging.getLogger("rag-exporter")
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
registry = CollectorRegistry()

rag_latency = Histogram(
    "erni_ki_rag_response_latency_seconds",
    "RAG end-to-end response latency in seconds",
    buckets=RAG_LATENCY_BUCKETS,
    registry=registry,
)

rag_sources = Gauge(
    "erni_ki_rag_sources_count",
    "Number of sources used in last RAG answer",
    registry=registry,
)

OPENWEBUI_TEST_URL = os.getenv("RAG_TEST_URL", DEFAULT_RAG_TEST_URL)
OPENWEBUI_VERIFY_TLS = os.getenv("RAG_VERIFY_TLS", DEFAULT_RAG_VERIFY_TLS).lower() == "true"
RAG_TEST_INTERVAL = float(os.getenv("RAG_TEST_INTERVAL", str(DEFAULT_RAG_TEST_INTERVAL)))
_shutdown_event = threading.Event()


def probe_loop():
    """Probe RAG endpoint at regular intervals and update metrics."""
    while not _shutdown_event.is_set():
        start = time.time()
        sources_count = None
        try:
            r = requests.get(
                OPENWEBUI_TEST_URL,
                timeout=DEFAULT_REQUEST_TIMEOUT,
                verify=OPENWEBUI_VERIFY_TLS,
            )
            # If an application endpoint returns JSON with sources, extract it here.
            # For now, we default to 0 when not present.
            if r.headers.get("content-type", "").startswith("application/json"):
                with contextlib.suppress(Exception):
                    data = r.json()
                    if (
                        isinstance(data, dict)
                        and "sources" in data
                        and isinstance(data["sources"], list)
                    ):
                        sources_count = len(data["sources"])
            r.raise_for_status()
            elapsed = time.time() - start
            rag_latency.observe(elapsed)
        except requests.RequestException as exc:
            logger.error("RAG health check request failed: %s", exc, exc_info=True)
            rag_latency.observe(FALLBACK_LATENCY)
        finally:
            if sources_count is None:
                sources_count = 0
            rag_sources.set(sources_count)
        _shutdown_event.wait(RAG_TEST_INTERVAL)


@app.route("/metrics")
def metrics():
    return Response(generate_latest(registry), mimetype=CONTENT_TYPE_LATEST)


def main():
    """Start RAG exporter with metrics server."""

    def _handle_signal(signum: int, _frame: Any) -> None:
        logger.info("Received signal %s, shutting down probe loop", signum)
        _shutdown_event.set()

    signal.signal(signal.SIGTERM, _handle_signal)
    signal.signal(signal.SIGINT, _handle_signal)

    t = threading.Thread(target=probe_loop, daemon=True)
    t.start()
    port = int(os.getenv("PORT", str(DEFAULT_PORT)))
    app.run(host="0.0.0.0", port=port)  # noqa: S104 - exporter runs inside container


if __name__ == "__main__":
    main()
