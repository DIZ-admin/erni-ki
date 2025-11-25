#!/usr/bin/env python3
"""
ERNI-KI Webhook Receiver
Simple webhook receiver for Alertmanager alerts
"""

import json
import logging
import os
from datetime import datetime
from pathlib import Path
from subprocess import CalledProcessError, run

from flask import Flask, jsonify, request

# Logging configuration
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("webhook-receiver")

app = Flask(__name__)

# Configuration
WEBHOOK_PORT = int(os.getenv("WEBHOOK_PORT", 9093))
LOG_DIR = Path("/app/logs")
LOG_DIR.mkdir(exist_ok=True)
RECOVERY_DIR = Path(os.getenv("RECOVERY_DIR", "/app/scripts/recovery"))


def save_alert_to_file(alert_data, alert_type="general"):
    """Save alert to file for further processing"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = LOG_DIR / f"alert_{alert_type}_{timestamp}.json"

    try:
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(alert_data, f, indent=2, ensure_ascii=False)
        logger.info(f"Alert saved to {filename}")
    except Exception as e:
        logger.error(f"Failed to save alert to file: {e}")


def process_alert(alert_data, alert_type="general"):
    """Process alert and execute necessary actions"""
    try:
        alerts = alert_data.get("alerts", [])

        for alert in alerts:
            labels = alert.get("labels", {})
            annotations = alert.get("annotations", {})
            status = alert.get("status", "unknown")

            # Alert logging
            logger.info(f"Processing {alert_type} alert:")
            logger.info(f"  Status: {status}")
            logger.info(f"  Alert: {labels.get('alertname', 'Unknown')}")
            logger.info(f"  Service: {labels.get('service', 'Unknown')}")
            logger.info(f"  Severity: {labels.get('severity', 'Unknown')}")
            logger.info(f"  Summary: {annotations.get('summary', 'No summary')}")

            # Special handling for critical alerts
            if alert_type == "critical" or labels.get("severity") == "critical":
                handle_critical_alert(alert)

            # Special handling for GPU alerts
            if alert_type == "gpu" or labels.get("service") == "gpu":
                handle_gpu_alert(alert)

    except Exception as e:
        logger.error(f"Error processing alert: {e}")


def handle_critical_alert(alert):
    """Critical alert handling"""
    labels = alert.get("labels", {})
    service = labels.get("service", "unknown")

    logger.critical(f"🚨 CRITICAL ALERT for service: {service}")

    # Automatic actions can be added here:
    # - Send SMS/email
    # - Notifications to Slack/Teams
    # - Recovery scripts per service

    if service in ["ollama", "openwebui", "searxng"]:
        run_recovery_script(service)
    else:
        logger.info(
            "Service %s has no recovery script configured; manual intervention may be required",
            service,
        )


def handle_gpu_alert(alert):
    """GPU alert handling"""
    labels = alert.get("labels", {})
    gpu_id = labels.get("gpu_id", "unknown")
    component = labels.get("component", "unknown")

    logger.warning(f"🎮 GPU Alert - GPU {gpu_id}, Component: {component}")

    # Special handling for GPU temperature
    if component == "nvidia" and "temperature" in labels.get("alertname", "").lower():
        logger.warning("GPU temperature alert - consider reducing workload")


def run_recovery_script(service: str) -> None:
    """Execute recovery script for a critical service if available."""
    script_path = RECOVERY_DIR / f"{service}-recovery.sh"

    if not script_path.exists():
        logger.warning(f"No recovery script found for {service} at {script_path}")
        return

    if not os.access(script_path, os.X_OK):
        logger.warning(f"Recovery script for {service} is not executable: {script_path}")
        return

    try:
        logger.info(f"Running recovery script for {service}: {script_path}")
        result = run([str(script_path)], check=True, capture_output=True, text=True)
        logger.info("Recovery script output:\n%s", result.stdout)
        if result.stderr:
            logger.warning("Recovery script stderr:\n%s", result.stderr)
    except CalledProcessError as exc:
        logger.error(
            "Recovery script failed for %s (exit %s): %s", service, exc.returncode, exc.stderr
        )
    except Exception as exc:
        logger.error("Unexpected error executing recovery script for %s: %s", service, exc)


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    return jsonify(
        {
            "status": "healthy",
            "service": "webhook-receiver",
            "timestamp": datetime.now().isoformat(),
        }
    )


@app.route("/webhook", methods=["POST"])
def webhook_general():
    """General webhook endpoint"""
    try:
        alert_data = request.get_json()
        if not alert_data:
            return jsonify({"error": "No JSON data received"}), 400

        save_alert_to_file(alert_data, "general")
        process_alert(alert_data, "general")

        return jsonify({"status": "success", "message": "Alert processed"})

    except Exception as e:
        logger.error(f"Error in general webhook: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/critical", methods=["POST"])
def webhook_critical():
    """Critical alerts"""
    try:
        alert_data = request.get_json()
        if not alert_data:
            return jsonify({"error": "No JSON data received"}), 400

        save_alert_to_file(alert_data, "critical")
        process_alert(alert_data, "critical")

        return jsonify({"status": "success", "message": "Critical alert processed"})

    except Exception as e:
        logger.error(f"Error in critical webhook: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/warning", methods=["POST"])
def webhook_warning():
    """Warnings"""
    try:
        alert_data = request.get_json()
        if not alert_data:
            return jsonify({"error": "No JSON data received"}), 400

        save_alert_to_file(alert_data, "warning")
        process_alert(alert_data, "warning")

        return jsonify({"status": "success", "message": "Warning alert processed"})

    except Exception as e:
        logger.error(f"Error in warning webhook: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/gpu", methods=["POST"])
def webhook_gpu():
    """GPU alerts"""
    try:
        alert_data = request.get_json()
        if not alert_data:
            return jsonify({"error": "No JSON data received"}), 400

        save_alert_to_file(alert_data, "gpu")
        process_alert(alert_data, "gpu")

        return jsonify({"status": "success", "message": "GPU alert processed"})

    except Exception as e:
        logger.error(f"Error in GPU webhook: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/ai", methods=["POST"])
def webhook_ai():
    """AI services alerts"""
    try:
        alert_data = request.get_json()
        if not alert_data:
            return jsonify({"error": "No JSON data received"}), 400

        save_alert_to_file(alert_data, "ai")
        process_alert(alert_data, "ai")

        return jsonify({"status": "success", "message": "AI alert processed"})

    except Exception as e:
        logger.error(f"Error in AI webhook: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/webhook/database", methods=["POST"])
def webhook_database():
    """Database alerts"""
    try:
        alert_data = request.get_json()
        if not alert_data:
            return jsonify({"error": "No JSON data received"}), 400

        save_alert_to_file(alert_data, "database")
        process_alert(alert_data, "database")

        return jsonify({"status": "success", "message": "Database alert processed"})

    except Exception as e:
        logger.error(f"Error in database webhook: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/alerts", methods=["GET"])
def list_alerts():
    """List of recent alerts"""
    try:
        alert_files = sorted(LOG_DIR.glob("alert_*.json"), reverse=True)[:20]
        alerts = []

        for alert_file in alert_files:
            try:
                with open(alert_file, encoding="utf-8") as f:
                    alert_data = json.load(f)
                    alerts.append(
                        {
                            "filename": alert_file.name,
                            "timestamp": alert_file.stat().st_mtime,
                            "alerts_count": len(alert_data.get("alerts", [])),
                        }
                    )
            except Exception as e:
                logger.error(f"Error reading alert file {alert_file}: {e}")

        return jsonify({"alerts": alerts})

    except Exception as e:
        logger.error(f"Error listing alerts: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    logger.info(f"Starting ERNI-KI Webhook Receiver on port {WEBHOOK_PORT}")
    app.run(host="0.0.0.0", port=WEBHOOK_PORT, debug=False)  # noqa: S104 - runs inside container
