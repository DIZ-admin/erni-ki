"""
Alert processing and recovery script execution services.
"""

import logging
import os
from pathlib import Path
from subprocess import CalledProcessError, TimeoutExpired, run
from typing import Any

logger = logging.getLogger("webhook-receiver")

# Recovery script configuration
RECOVERY_DIR = Path(os.getenv("RECOVERY_DIR", "/app/scripts/recovery"))
RECOVERY_SCRIPT_TIMEOUT = int(os.getenv("RECOVERY_SCRIPT_TIMEOUT", "30"))

# Explicit mapping of services to recovery script filenames
# This prevents any path traversal attempts through service names
RECOVERY_SCRIPTS = {
    "ollama": "ollama-recovery.sh",
    "openwebui": "openwebui-recovery.sh",
    "searxng": "searxng-recovery.sh",
}

ALLOWED_SERVICES = set(RECOVERY_SCRIPTS.keys())


def _path_within(base: Path, target: Path) -> bool:
    """Check if target path is within base path (security check)."""
    try:
        target_resolved = target.resolve()
        base_resolved = base.resolve()
        return str(target_resolved).startswith(str(base_resolved))
    except (OSError, ValueError):
        # Path resolution can fail on invalid paths
        return False


def process_alert(alert_data: dict[str, Any], alert_type: str = "general") -> None:
    """Process alert and execute necessary actions."""
    try:
        alerts = alert_data.get("alerts", [])

        for alert in alerts:
            labels = alert.get("labels", {})
            annotations = alert.get("annotations", {})
            status = alert.get("status", "unknown")

            # Alert logging
            logger.info("Processing %s alert:", alert_type)
            logger.info("  Status: %s", status)
            logger.info("  Alert: %s", labels.get("alertname", "Unknown"))
            logger.info("  Service: %s", labels.get("service", "Unknown"))
            logger.info("  Severity: %s", labels.get("severity", "Unknown"))
            logger.info("  Summary: %s", annotations.get("summary", "No summary"))

            # Special handling for critical alerts
            if alert_type == "critical" or labels.get("severity") == "critical":
                handle_critical_alert(alert)

            # Special handling for GPU alerts
            if alert_type == "gpu" or labels.get("service") == "gpu":
                handle_gpu_alert(alert)

    except (KeyError, TypeError) as e:
        logger.error("Invalid alert data structure: %s", e)
    except Exception as e:
        logger.exception("Unexpected error processing alert: %s", e)


def handle_critical_alert(alert: dict[str, Any]) -> None:
    """Critical alert handling."""
    labels = alert.get("labels", {})
    service = labels.get("service", "unknown")

    logger.critical("🚨 CRITICAL ALERT for service: %s", service)

    if service in ALLOWED_SERVICES:
        run_recovery_script(service)
    else:
        logger.info(
            "Service %s has no recovery script configured; manual intervention may be required",
            service,
        )


def handle_gpu_alert(alert: dict[str, Any]) -> None:
    """GPU alert handling."""
    labels = alert.get("labels", {})
    gpu_id = labels.get("gpu_id", "unknown")
    component = labels.get("component", "unknown")

    logger.warning("🎮 GPU Alert - GPU %s, Component: %s", gpu_id, component)

    # Special handling for GPU temperature
    if component == "nvidia" and "temperature" in labels.get("alertname", "").lower():
        logger.warning("GPU temperature alert - consider reducing workload")


def run_recovery_script(service: str) -> None:
    """Execute recovery script for a critical service if available."""
    # Use explicit mapping to prevent path traversal attacks
    if service not in RECOVERY_SCRIPTS:
        logger.error("Invalid service: %s", service)
        return

    script_filename = RECOVERY_SCRIPTS[service]
    script_path = RECOVERY_DIR / script_filename

    # Double-check path is within recovery directory
    if not _path_within(RECOVERY_DIR, script_path):
        logger.error("Path traversal attempt detected for %s", script_path)
        return

    if not script_path.exists():
        logger.warning("No recovery script found for %s at %s", service, script_path)
        return

    if not os.access(script_path, os.X_OK):
        logger.warning("Recovery script for %s is not executable: %s", service, script_path)
        return

    try:
        logger.info("Running recovery script for %s: %s", service, script_path)
        result = run(
            [str(script_path)],
            check=True,
            capture_output=True,
            text=True,
            timeout=RECOVERY_SCRIPT_TIMEOUT,
        )
        logger.info("Recovery script output:\n%s", result.stdout)
        if result.stderr:
            logger.warning("Recovery script stderr:\n%s", result.stderr)
    except TimeoutExpired:
        logger.error(
            "Recovery script timeout for %s after %d seconds", service, RECOVERY_SCRIPT_TIMEOUT
        )
    except CalledProcessError as exc:
        logger.error(
            "Recovery script failed for %s (exit %s): %s", service, exc.returncode, exc.stderr
        )
    except (OSError, FileNotFoundError) as exc:
        logger.error("Failed to execute recovery script for %s: %s", service, exc)
