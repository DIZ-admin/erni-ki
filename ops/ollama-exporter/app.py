import logging
import os
import signal
import sys
import threading
import time
from typing import Any

import requests
from prometheus_client import Gauge, start_http_server

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434").rstrip("/")
EXPORTER_PORT = int(os.getenv("EXPORTER_PORT", "9778"))
POLL_INTERVAL = int(os.getenv("OLLAMA_EXPORTER_INTERVAL", "15"))
REQUEST_TIMEOUT = float(os.getenv("OLLAMA_REQUEST_TIMEOUT", "5"))

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s | %(levelname)s | %(message)s",
)
LOGGER = logging.getLogger("ollama_exporter")

OLLAMA_UP = Gauge("ollama_up", "Ollama health status (1=up, 0=down)")
OLLAMA_VERSION_INFO = Gauge("ollama_version_info", "Current Ollama version", ["version"])
OLLAMA_INSTALLED_MODELS = Gauge("ollama_installed_models", "Number of installed Ollama models")
OLLAMA_REQUEST_LATENCY = Gauge(
    "ollama_request_latency_seconds", "Latency for Ollama version endpoint"
)

_STOP_EVENT = threading.Event()


def fetch_json(path: str) -> dict[str, Any] | None:
    """
    Retrieve and parse JSON from the Ollama API at the given path.

    Parameters:
        path (str): API path appended to OLLAMA_URL (e.g., "/api/version").

    Returns:
        dict[str, Any] | None: Parsed JSON object from the response, or `None` if the
        request failed (timeout, connection error, HTTP error, or other request
        exceptions). Records request latency to OLLAMA_REQUEST_LATENCY on successful
        responses.
    """
    url = f"{OLLAMA_URL}{path}"
    try:
        start = time.perf_counter()
        response = requests.get(url, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        OLLAMA_REQUEST_LATENCY.set(time.perf_counter() - start)
        return response.json()
    except requests.Timeout:
        LOGGER.warning("Request timeout for %s", url)
        return None
    except requests.ConnectionError as exc:
        LOGGER.warning("Connection error for %s: %s", url, exc)
        return None
    except requests.HTTPError as exc:
        LOGGER.warning("HTTP error for %s: %s", url, exc)
        return None
    except requests.RequestException as exc:
        LOGGER.warning("Request failed for %s: %s", url, exc)
        return None


def poll_forever() -> None:
    """
    Continuously polls the Ollama API and updates Prometheus metrics until stopped.

    Polls the version and tags endpoints at regular intervals and updates the following metrics:
    - OLLAMA_UP: set to 1 when version data is retrieved, 0 otherwise.
    - OLLAMA_VERSION_INFO (labeled by version): sets the gauge for the reported version.
    - OLLAMA_INSTALLED_MODELS: set to the number of installed models when present in tags.

    The loop runs until the module-level _STOP_EVENT is set, and waits
    interruptibly between polls.
    """
    LOGGER.info(
        "Starting poller (url=%s, interval=%ss, timeout=%ss)",
        OLLAMA_URL,
        POLL_INTERVAL,
        REQUEST_TIMEOUT,
    )
    while not _STOP_EVENT.is_set():
        version = fetch_json("/api/version")
        if version:
            OLLAMA_UP.set(1)
            version_str = version.get("version") or "unknown"
            OLLAMA_VERSION_INFO.labels(version=version_str).set(1)
        else:
            OLLAMA_UP.set(0)

        tags = fetch_json("/api/tags") or {}
        models = tags.get("models")
        if isinstance(models, list):
            OLLAMA_INSTALLED_MODELS.set(len(models))
        elif isinstance(models, dict):
            OLLAMA_INSTALLED_MODELS.set(len(models.keys()))

        _STOP_EVENT.wait(POLL_INTERVAL)


def shutdown(signum: int, frame: Any) -> None:  # pylint: disable=unused-argument
    """Signal handler for graceful shutdown"""
    LOGGER.info("Received signal %s, stopping exporter", signum)
    _STOP_EVENT.set()


def main() -> None:
    """
    Start the Prometheus metrics server, register shutdown handlers, and run the
    background poller until termination.

    Registers SIGTERM and SIGINT to initiate a graceful shutdown, starts the HTTP
    metrics server on EXPORTER_PORT, launches the daemon poller thread, blocks
    until shutdown is signaled, and joins the poller before exiting.
    """
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    start_http_server(EXPORTER_PORT)
    poller = threading.Thread(target=poll_forever, name="ollama-exporter", daemon=True)
    poller.start()

    while not _STOP_EVENT.is_set():
        time.sleep(1)

    poller.join(timeout=2)
    LOGGER.info("Exporter stopped")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        shutdown(signal.SIGINT, None)
        sys.exit(0)
