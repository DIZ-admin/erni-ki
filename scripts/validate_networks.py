#!/usr/bin/env python3
"""
Network Segmentation Validation Script
Analyzes compose.yml to verify all services have correct network assignments
"""

import sys
from pathlib import Path

import yaml


def main():
    compose_file = Path("/home/konstantin/Documents/augment-projects/erni-ki/compose.yml")

    with open(compose_file) as f:
        config = yaml.safe_load(f)

    services = config.get("services", {})
    networks_def = config.get("networks", {})

    print("=" * 80)
    print("NETWORK SEGMENTATION VALIDATION REPORT")
    print("=" * 80)
    print()

    # Expected network assignments
    expected = {
        # Infrastructure
        "watchtower": {"monitoring"},
        # Data layer
        "db": {"data"},
        "redis": {"data"},
        "backrest": {"data"},
        # Ingress
        "nginx": {"frontend", "backend"},
        "cloudflared": {"frontend", "backend"},
        # Backend + Data
        "openwebui": {"backend", "data"},
        "litellm": {"backend", "data"},
        "auth": {"backend", "data"},
        "searxng": {"backend", "data"},
        "mcposerver": {"backend", "data"},
        "docling": {"backend", "data"},
        # Backend only
        "ollama": {"backend"},
        "edgetts": {"backend"},
        "tika": {"backend"},
        # Monitoring
        "prometheus": {"monitoring"},
        "grafana": {"monitoring"},
        "alertmanager": {"monitoring"},
        "loki": {"monitoring"},
        "fluent-bit": {"monitoring"},
        "uptime-kuma": {"monitoring", "frontend"},
        "webhook-receiver": {"backend", "monitoring"},
        # Exporters
        "node-exporter": {"monitoring"},
        "postgres-exporter": {"monitoring", "data"},
        "postgres-exporter-proxy": set(),  # network_mode: service
        "redis-exporter": {"monitoring", "data"},
        "nvidia-exporter": {"monitoring"},
        "blackbox-exporter": {"monitoring", "frontend"},
        "ollama-exporter": {"monitoring", "backend"},
        "nginx-exporter": {"monitoring", "frontend", "backend"},
        "cadvisor": {"monitoring"},
        "rag-exporter": {"monitoring", "backend"},
    }

    # Check network definitions
    print("1. NETWORK DEFINITIONS")
    print("-" * 80)
    for net_name, net_config in networks_def.items():
        internal = net_config.get("internal", False)
        print(f"  ✓ {net_name:20} (internal={internal})")
    print()

    # Validate service assignments
    print("2. SERVICE NETWORK ASSIGNMENTS")
    print("-" * 80)

    issues = []
    missing_services = []
    extra_services = []

    # Check expected services
    for svc_name, expected_nets in expected.items():
        if svc_name not in services:
            missing_services.append(svc_name)
            continue

        svc_config = services[svc_name]

        # Handle network_mode services
        if "network_mode" in svc_config:
            actual_nets = set()
        else:
            actual_nets = set()
            svc_networks = svc_config.get("networks", {})
            if isinstance(svc_networks, list):
                actual_nets = set(svc_networks)
            elif isinstance(svc_networks, dict):
                actual_nets = set(svc_networks.keys())

        if actual_nets == expected_nets:
            nets_str = ", ".join(sorted(actual_nets)) if actual_nets else "(network_mode)"
            print(f"  ✓ {svc_name:25} {nets_str}")
        else:
            nets_str = ", ".join(sorted(actual_nets)) if actual_nets else "(none)"
            expected_str = ", ".join(sorted(expected_nets)) if expected_nets else "(network_mode)"
            print(f"  ✗ {svc_name:25} {nets_str}")
            print(f"    Expected: {expected_str}")
            issues.append(f"{svc_name}: has {nets_str}, expected {expected_str}")

    # Check for unexpected services
    for svc_name in services:
        if svc_name not in expected:
            svc_config = services[svc_name]
            if "network_mode" in svc_config:
                actual_nets = f"(network_mode: {svc_config['network_mode']})"
            else:
                svc_networks = svc_config.get("networks", {})
                if isinstance(svc_networks, list):
                    actual_nets = ", ".join(sorted(svc_networks))
                elif isinstance(svc_networks, dict):
                    actual_nets = ", ".join(sorted(svc_networks.keys()))
                else:
                    actual_nets = "(none)"
            print(f"  ? {svc_name:25} {actual_nets} (not in expected list)")
            extra_services.append(svc_name)

    print()

    # Port bindings analysis
    print("3. PORT BINDINGS ANALYSIS")
    print("-" * 80)

    removed_ports = {
        "auth": "9092:9090",
        "edgetts": "5050:5050",
        "tika": "9998:9998",
        "mcposerver": "8000:8000",
        "ollama": "11434:11434",
        "backrest": "9898:9898",
    }

    kept_ports = {
        "nginx": ["80:80", "443:443", "8080:8080"],
        "litellm": ["127.0.0.1:4000:4000"],
    }

    # Verify removed ports
    for svc_name, port in removed_ports.items():
        if svc_name in services:
            ports = services[svc_name].get("ports", [])
            if not any(port in str(p) for p in ports):
                print(f"  ✓ {svc_name:25} Port {port} removed")
            else:
                print(f"  ✗ {svc_name:25} Port {port} still present!")
                issues.append(f"{svc_name}: port {port} should be removed")

    # Verify kept ports
    for svc_name, port_list in kept_ports.items():
        if svc_name in services:
            ports = services[svc_name].get("ports", [])
            for port in port_list:
                if any(port in str(p) for p in ports):
                    print(f"  ✓ {svc_name:25} Port {port} retained")
                else:
                    print(f"  ✗ {svc_name:25} Port {port} missing!")
                    issues.append(f"{svc_name}: port {port} should be present")

    print()

    # Summary
    print("4. VALIDATION SUMMARY")
    print("=" * 80)
    print(f"Total services: {len(services)}")
    print(f"Expected services: {len(expected)}")
    print(f"Services with correct networks: {len(expected) - len(issues)}")
    print(f"Issues found: {len(issues)}")

    if missing_services:
        print(f"Missing services: {', '.join(missing_services)}")

    if extra_services:
        print(f"Extra services (not in validation): {', '.join(extra_services)}")

    print()

    if issues:
        print("ISSUES DETECTED:")
        for issue in issues:
            print(f"  - {issue}")
        return 1
    else:
        print("✓ ALL VALIDATIONS PASSED")
        return 0


if __name__ == "__main__":
    sys.exit(main())
