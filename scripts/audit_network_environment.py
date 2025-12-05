#!/usr/bin/env python3
"""
Network Environment Audit Script
Analyzes the current running state of Docker networks and containers
"""

import json
import subprocess  # nosec B404
from collections import defaultdict


def run_cmd(cmd):
    """Run command (list of args) and return stdout; capture stderr for diagnostics."""
    try:
        result = subprocess.run(  # nosec B603 - fixed argv list, no untrusted shell
            cmd,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return f"Error: {e.stderr.strip()}"


def main():
    print("=" * 80)
    print("ERNI-KI NETWORK ENVIRONMENT AUDIT")
    print("=" * 80)
    print()

    # 1. Container Status
    print("1. CONTAINER STATUS")
    print("-" * 80)

    containers = []
    healthy = []
    actual = set()

    ps_output = run_cmd(["docker", "compose", "ps", "--format", "json"])
    if ps_output and not ps_output.startswith("Error"):
        containers = [json.loads(line) for line in ps_output.strip().split("\n") if line]

        running = [c for c in containers if c.get("State") == "running"]
        healthy = [c for c in containers if c.get("Health") == "healthy"]

        print(f"Total services: {len(containers)}")
        print(f"Running: {len(running)}")
        print(f"Healthy: {len(healthy)}")
        print()

        # Group by status
        status_groups = defaultdict(list)
        for c in containers:
            state = c.get("State", "unknown")
            health = c.get("Health", "n/a")
            status = f"{state} ({health})" if health != "n/a" else state
            status_groups[status].append(c.get("Service", c.get("Name", "unknown")))

        for status, services in sorted(status_groups.items()):
            print(f"  {status}: {len(services)} services")
            for svc in sorted(services)[:5]:
                print(f"    - {svc}")
            if len(services) > 5:
                print(f"    ... and {len(services) - 5} more")
    else:
        print("  No containers found or error querying")

    print()

    # 2. Network Configuration
    print("2. ACTIVE DOCKER NETWORKS")
    print("-" * 80)

    networks_output = run_cmd(
        ["docker", "network", "ls", "--filter", "name=erni-ki", "--format", "json"]
    )
    if networks_output and not networks_output.startswith("Error"):
        networks = [json.loads(line) for line in networks_output.strip().split("\n") if line]

        for net in networks:
            name = net.get("Name", "unknown")
            driver = net.get("Driver", "unknown")
            scope = net.get("Scope", "unknown")
            print(f"  {name:30} (driver={driver}, scope={scope})")

            # Get network details
            inspect_cmd = ["docker", "network", "inspect", name, "--format", "{{.Internal}}"]
            internal = run_cmd(inspect_cmd)
            if internal == "true":
                print("    Internal: YES (isolated from external network)")
            else:
                print("    Internal: NO (can access external network)")

            # Count containers
            containers_cmd = [
                "docker",
                "network",
                "inspect",
                name,
                "--format",
                "{{len .Containers}}",
            ]
            container_count = run_cmd(containers_cmd)
            print(f"    Connected containers: {container_count}")

        print()

        # Check for expected networks
        expected = {"erni-ki_frontend", "erni-ki_backend", "erni-ki_data", "erni-ki_monitoring"}
        actual = {net.get("Name") for net in networks}

        if expected.issubset(actual):
            print("  ✓ All expected segmented networks are present")
        else:
            missing = expected - actual
            print(f"  ✗ Missing expected networks: {missing}")
            print(f"  ℹ Current network: {actual}")
            print("  ℹ This indicates the new network configuration has NOT been deployed yet")
    else:
        print("  No networks found or error querying")

    print()

    # 3. Container Network Attachments
    print("3. CONTAINER NETWORK ATTACHMENTS (Sample)")
    print("-" * 80)

    # Sample a few key services
    key_services = ["nginx", "db", "openwebui", "prometheus", "ollama"]

    for svc in key_services:
        container_name = f"erni-ki-{svc}-1"
        inspect_cmd = [
            "docker",
            "inspect",
            container_name,
            "--format",
            "{{json .NetworkSettings.Networks}}",
        ]
        networks_json = run_cmd(inspect_cmd)

        if networks_json and not networks_json.startswith("Error"):
            try:
                nets = json.loads(networks_json)
                net_names = list(nets.keys())
                if net_names:
                    print(f"  {svc:20} → {', '.join(net_names)}")
                else:
                    print(f"  {svc:20} → (no networks)")
            except json.JSONDecodeError:
                print(f"  {svc:20} → (error parsing)")
        else:
            print(f"  {svc:20} → (not running or not found)")

    print()

    # 4. Port Exposure Analysis
    print("4. PORT EXPOSURE ANALYSIS")
    print("-" * 80)

    ports_output = run_cmd(
        ["docker", "ps", "--filter", "name=erni-ki", "--format", "{{.Names}}\t{{.Ports}}"]
    )
    if ports_output and not ports_output.startswith("Error"):
        lines = ports_output.strip().split("\n")

        public_ports = []
        localhost_ports = []
        internal_only = []

        for line in lines:
            if not line:
                continue
            parts = line.split("\t", 1)
            name = parts[0] if parts else "unknown"
            ports = parts[1] if len(parts) > 1 else ""

            if "0.0.0.0:" in ports or "[::]" in ports:
                public_ports.append((name, ports))
            elif "127.0.0.1:" in ports:
                localhost_ports.append((name, ports))
            else:
                internal_only.append(name)

        print(f"  Public ports (0.0.0.0): {len(public_ports)}")
        for name, ports in public_ports[:3]:
            print(f"    - {name}: {ports}")

        print()
        print(f"  Localhost-only ports (127.0.0.1): {len(localhost_ports)}")
        for name, ports in localhost_ports[:5]:
            print(f"    - {name.replace('erni-ki-', '')}: {ports[:50]}...")

        print()
        print(f"  Internal-only (no port bindings): {len(internal_only)}")
        for name in internal_only[:5]:
            print(f"    - {name.replace('erni-ki-', '')}")
        if len(internal_only) > 5:
            print(f"    ... and {len(internal_only) - 5} more")

    print()

    # 5. Service Connectivity Test
    print("5. SERVICE CONNECTIVITY TEST (Sample)")
    print("-" * 80)

    # Test a few key connections
    tests = [
        (
            "openwebui",
            "db",
            (
                'psql -h db -U postgres -c "SELECT 1" 2>&1 '
                '| grep -q "FATAL\\|ERROR" && echo FAIL || echo OK'
            ),
        ),
        (
            "openwebui",
            "redis",
            "redis-cli -h redis ping 2>&1 | grep -q PONG && echo OK || echo FAIL",
        ),
        (
            "nginx",
            "openwebui",
            (
                "curl -f http://openwebui:8080/health 2>&1 "
                '| grep -q "200\\|OK" && echo OK || echo FAIL'
            ),
        ),
    ]

    for src, dst, test_cmd in tests:
        src_container = f"erni-ki-{src}-1"
        result = run_cmd(["docker", "exec", src_container, "sh", "-c", test_cmd])
        status = "✓" if "OK" in result else "✗"
        print(f"  {status} {src:15} → {dst:15} : {result}")

    print()

    # 6. Summary
    print("6. AUDIT SUMMARY")
    print("=" * 80)

    if "erni-ki_default" in actual:
        print("⚠️  WARNING: System is using legacy flat network architecture")
        print("   Current: single 'erni-ki_default' network")
        print("   Expected: segmented networks (frontend/backend/data/monitoring)")
        print()
        print("   RECOMMENDATION: Deploy the new network configuration with:")
        print("   $ docker compose up -d --force-recreate")
        print()
    else:
        print("✓ System is using segmented network architecture")

    print(f"   Active containers: {len(containers)} / {len(containers)}")
    print(f"   Healthy containers: {len(healthy)} / {len(containers)}")

    if len(healthy) == len(containers):
        print("   ✓ All services are healthy")
    else:
        print(f"   ⚠️  {len(containers) - len(healthy)} services are not healthy")


if __name__ == "__main__":
    main()
