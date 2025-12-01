#!/usr/bin/env python3
"""
ERNI-KI Webhook Client - Python Example

Demonstrates how to send properly signed webhook requests to ERNI-KI webhook endpoints.
Works with all webhook endpoints:
  - POST /webhook (generic)
  - POST /webhook/critical (critical alerts)
  - POST /webhook/warning (warning alerts)
  - POST /webhook/gpu (GPU alerts)
  - POST /webhook/ai (AI/model alerts)
  - POST /webhook/database (database alerts)

Usage:
    # Send critical alert
    python webhook-client-python.py --endpoint critical \
      --alert-name "OllamaDown" \
      --severity critical \
      --summary "Ollama service is down"

    # Send warning alert with custom labels
    python webhook-client-python.py --endpoint warning \
      --alert-name "HighMemory" \
      --severity warning \
      --summary "Memory usage above 80%" \
      --label "instance=gpu-server" \
      --label "component=memory"
"""

import argparse
import hashlib
import hmac
import json
import sys
from datetime import datetime
from json import JSONDecodeError
from typing import Any, cast

import requests


class WebhookClient:
    """Client for sending signed webhook requests to ERNI-KI."""

    def __init__(
        self,
        base_url: str,
        webhook_secret: str,
        timeout: float = 10.0,
    ):
        """
        Initialize webhook client.

        Args:
            base_url: Base URL of webhook receiver (e.g., http://localhost:5001)
            webhook_secret: Secret key for HMAC signature
            timeout: Request timeout in seconds
        """
        self.base_url = base_url.rstrip("/")
        self.webhook_secret = webhook_secret
        self.timeout = timeout

    def _generate_signature(self, body: bytes) -> str:
        """Generate HMAC-SHA256 signature for request body."""
        return hmac.new(
            self.webhook_secret.encode("utf-8"),
            body,
            hashlib.sha256,
        ).hexdigest()

    def _build_alert_payload(
        self,
        alert_name: str,
        status: str = "firing",
        severity: str = "warning",
        summary: str = "",
        description: str = "",
        labels: dict[str, str] | None = None,
        annotations: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        """Build a standard Alertmanager alert payload."""
        if labels is None:
            labels = {}
        if annotations is None:
            annotations = {}

        # Add required labels
        labels.setdefault("alertname", alert_name)
        labels.setdefault("severity", severity)

        # Add annotations
        annotations.setdefault("summary", summary or alert_name)
        if description:
            annotations["description"] = description

        alert = {
            "status": status,
            "labels": labels,
            "annotations": annotations,
            "startsAt": datetime.utcnow().isoformat() + "Z",
            "endsAt": "0001-01-01T00:00:00Z",
        }

        return {
            "alerts": [alert],
            "groupLabels": {"alertname": alert_name},
            "commonLabels": labels,
            "commonAnnotations": annotations,
            "externalURL": "http://alertmanager:9093",
            "version": "4",
            "groupKey": f'{{}}:{{alertname="{alert_name}"}}',
        }

    def send_alert(
        self,
        endpoint: str,
        alert_name: str,
        status: str = "firing",
        severity: str = "warning",
        summary: str = "",
        description: str = "",
        labels: dict[str, str] | None = None,
        annotations: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        """
        Send an alert to the specified webhook endpoint.

        Args:
            endpoint: Webhook endpoint (generic, critical, warning, gpu, ai, database)
            alert_name: Name of the alert
            status: Alert status (firing or resolved)
            severity: Alert severity (info, warning, critical)
            summary: Alert summary
            description: Detailed description
            labels: Additional labels (dict)
            annotations: Additional annotations (dict)

        Returns:
            Response from webhook endpoint
        """
        payload = self._build_alert_payload(
            alert_name=alert_name,
            status=status,
            severity=severity,
            summary=summary,
            description=description,
            labels=labels or {},
            annotations=annotations or {},
        )

        # Serialize to compact JSON (no spaces)
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")

        # Generate signature
        signature = self._generate_signature(body)

        # Build URL
        url = f"{self.base_url}/webhook"
        if endpoint != "generic":
            url += f"/{endpoint}"

        # Send request
        headers = {
            "Content-Type": "application/json",
            "X-Signature": signature,
        }

        try:
            response = requests.post(
                url,
                data=body,
                headers=headers,
                timeout=self.timeout,
            )
            response.raise_for_status()
            try:
                data = response.json()
                if isinstance(data, dict):
                    return cast(dict[str, Any], data)
                return {"status": "success", "raw_response": data}
            except JSONDecodeError:
                return {
                    "status": "success",
                    "raw_response": response.text[:200],
                }

        except requests.exceptions.Timeout:
            return {
                "error": "Request timeout",
                "status": "failed",
                "url": url,
            }
        except requests.exceptions.RequestException as e:
            return {
                "error": str(e),
                "status": "failed",
                "url": url,
                "status_code": getattr(e.response, "status_code", None),
            }

    def send_critical_alert(
        self,
        alert_name: str,
        summary: str = "",
        service: str | None = None,
        recovery_enabled: bool = False,
    ) -> dict[str, Any]:
        """
        Send a critical alert (with optional auto-recovery).

        Args:
            alert_name: Name of the alert
            summary: Alert summary
            service: Service name (ollama, openwebui, searxng)
            recovery_enabled: Enable automatic recovery attempt

        Returns:
            Response from critical endpoint
        """
        annotations = {"summary": summary or alert_name}
        if recovery_enabled and service:
            annotations["recovery"] = "auto"

        labels = {"severity": "critical"}
        if service:
            labels["service"] = service

        return self.send_alert(
            endpoint="critical",
            alert_name=alert_name,
            severity="critical",
            summary=summary or alert_name,
            labels=labels,
            annotations=annotations,
        )

    def send_gpu_alert(
        self,
        alert_name: str,
        gpu_id: str,
        component: str,
        summary: str = "",
    ) -> dict[str, Any]:
        """
        Send a GPU-specific alert.

        Args:
            alert_name: Name of the alert
            gpu_id: GPU device ID
            component: GPU component (memory, cuda, temperature)
            summary: Alert summary

        Returns:
            Response from GPU endpoint
        """
        labels = {
            "severity": "warning",
            "gpu_id": gpu_id,
            "component": component,
        }

        return self.send_alert(
            endpoint="gpu",
            alert_name=alert_name,
            severity="warning",
            summary=summary or alert_name,
            labels=labels,
        )

    def send_database_alert(
        self,
        alert_name: str,
        database: str,
        summary: str = "",
    ) -> dict[str, Any]:
        """
        Send a database-specific alert.

        Args:
            alert_name: Name of the alert
            database: Database name
            summary: Alert summary

        Returns:
            Response from database endpoint
        """
        labels = {
            "severity": "warning",
            "database": database,
        }

        return self.send_alert(
            endpoint="database",
            alert_name=alert_name,
            severity="warning",
            summary=summary or alert_name,
            labels=labels,
        )


def main():
    """CLI interface for webhook client."""
    parser = argparse.ArgumentParser(description="Send signed webhook alerts to ERNI-KI")
    parser.add_argument(
        "--url",
        default="http://localhost:5001",
        help="Webhook base URL (default: http://localhost:5001)",
    )
    parser.add_argument(
        "--secret",
        required=True,
        help="Webhook secret for HMAC signature",
    )
    parser.add_argument(
        "--endpoint",
        choices=["generic", "critical", "warning", "gpu", "ai", "database"],
        default="generic",
        help="Webhook endpoint to send to",
    )
    parser.add_argument(
        "--alert-name",
        required=True,
        help="Alert name",
    )
    parser.add_argument(
        "--severity",
        choices=["info", "warning", "critical"],
        default="warning",
        help="Alert severity",
    )
    parser.add_argument(
        "--status",
        choices=["firing", "resolved"],
        default="firing",
        help="Alert status",
    )
    parser.add_argument(
        "--summary",
        default="",
        help="Alert summary",
    )
    parser.add_argument(
        "--description",
        default="",
        help="Alert description",
    )
    parser.add_argument(
        "--label",
        action="append",
        default=[],
        help="Additional label in key=value format (can be used multiple times)",
    )
    parser.add_argument(
        "--annotation",
        action="append",
        default=[],
        help="Additional annotation in key=value format (can be used multiple times)",
    )
    parser.add_argument(
        "--service",
        help="Service name for critical alerts",
    )
    parser.add_argument(
        "--auto-recovery",
        action="store_true",
        help="Enable auto-recovery for critical alerts",
    )
    parser.add_argument(
        "--gpu-id",
        help="GPU device ID for GPU alerts",
    )
    parser.add_argument(
        "--gpu-component",
        default="memory",
        help="GPU component for GPU alerts (memory, cuda, temperature)",
    )
    parser.add_argument(
        "--database",
        help="Database name for database alerts",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=10.0,
        help="Request timeout in seconds",
    )
    parser.add_argument(
        "--json-output",
        action="store_true",
        help="Output response as JSON",
    )

    args = parser.parse_args()

    # Parse labels and annotations
    labels = {}
    for label in args.label:
        key, value = label.split("=", 1)
        labels[key] = value

    annotations = {}
    for annotation in args.annotation:
        key, value = annotation.split("=", 1)
        annotations[key] = value

    # Create client
    client = WebhookClient(args.url, args.secret, timeout=args.timeout)

    # Send alert
    if args.endpoint == "critical":
        response = client.send_critical_alert(
            alert_name=args.alert_name,
            summary=args.summary,
            service=args.service,
            recovery_enabled=args.auto_recovery,
        )
    elif args.endpoint == "gpu":
        if not args.gpu_id:
            print("Error: --gpu-id required for GPU alerts", file=sys.stderr)
            sys.exit(1)
        response = client.send_gpu_alert(
            alert_name=args.alert_name,
            gpu_id=args.gpu_id,
            component=args.gpu_component,
            summary=args.summary,
        )
    elif args.endpoint == "database":
        if not args.database:
            print("Error: --database required for database alerts", file=sys.stderr)
            sys.exit(1)
        response = client.send_database_alert(
            alert_name=args.alert_name,
            database=args.database,
            summary=args.summary,
        )
    else:
        response = client.send_alert(
            endpoint=args.endpoint,
            alert_name=args.alert_name,
            status=args.status,
            severity=args.severity,
            summary=args.summary,
            description=args.description,
            labels=labels,
            annotations=annotations,
        )

    # Output response
    if args.json_output:
        print(json.dumps(response, indent=2))
    else:
        if "error" in response:
            print(f"✗ Error: {response.get('error')}", file=sys.stderr)
            if "status_code" in response:
                print(f"  HTTP Status: {response['status_code']}", file=sys.stderr)
            sys.exit(1)
        else:
            print("✓ Alert sent successfully")
            print(f"  Status: {response.get('status')}")
            if "processed" in response:
                print(f"  Processed: {response['processed']} alert(s)")
            if "recovery" in response:
                recovery = response["recovery"]
                print(f"  Recovery: {recovery.get('success', False)}")
                print(f"    Service: {recovery.get('service')}")
                print(f"    Time: {recovery.get('execution_time_seconds')}s")


if __name__ == "__main__":
    main()
