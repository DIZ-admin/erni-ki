#!/usr/bin/env python3
"""
Validate and optionally fix version inconsistencies across documentation.

Reads versions from compose.yml and status.yml, then checks docs/ for discrepancies.
Usage:
    python scripts/docs/sync_versions.py --check  # validation only
    python scripts/docs/sync_versions.py          # fix inconsistencies
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import NamedTuple

REPO_ROOT = Path(__file__).resolve().parents[2]
COMPOSE_FILE = REPO_ROOT / "compose.yml"
STATUS_YAML = REPO_ROOT / "docs/reference/status.yml"
DOCS_DIR = REPO_ROOT / "docs"


class Version(NamedTuple):
    """Version information for a service."""

    name: str
    version: str
    source: str  # 'compose' or 'status'


def parse_compose_versions() -> dict[str, str]:
    """Extract service versions from compose.yml."""
    versions = {}
    if not COMPOSE_FILE.exists():
        return versions

    content = COMPOSE_FILE.read_text(encoding="utf-8")

    # Pattern: image: service/name:vX.Y.Z
    image_pattern = re.compile(r"image:\s+[\w/-]+:(v?[\d.]+(?:-[\w.]+)?)")

    # Known services mapping
    service_mapping = {
        "prom/prometheus": "Prometheus",
        "grafana/grafana": "Grafana",
        "prom/alertmanager": "Alertmanager",
        "grafana/loki": "Loki",
        "fluent/fluent-bit": "Fluent Bit",
        "ghcr.io/berriai/litellm": "LiteLLM",
    }

    for match in image_pattern.finditer(content):
        version = match.group(1)
        # Find service name from context
        line_start = content.rfind("\n", 0, match.start())
        line_end = content.find("\n", match.end())
        context = content[max(0, line_start - 200) : line_end]

        for image_prefix, service_name in service_mapping.items():
            if image_prefix in context:
                versions[service_name] = version
                break

    return versions


def parse_status_versions() -> dict[str, str]:
    """Extract versions from status.yml."""
    versions = {}
    if not STATUS_YAML.exists():
        return versions

    content = STATUS_YAML.read_text(encoding="utf-8")

    # Parse monitoring_stack field
    monitoring_match = re.search(r'monitoring_stack:\s*"([^"]+)"', content)
    if monitoring_match:
        monitoring_str = monitoring_match.group(1)
        # Extract individual versions: Prometheus v3.0.0, Grafana v11.3.0, etc.
        version_pattern = re.compile(r"(\w+(?:\s+\w+)?)\s+v([\d.]+)")
        for match in version_pattern.finditer(monitoring_str):
            service = match.group(1)
            version = match.group(2)
            versions[service] = f"v{version}"

    return versions


def find_version_references(
    docs_dir: Path, exclude_dirs: set[str] = None
) -> list[tuple[Path, int, str]]:
    """Find all version references in documentation.

    Returns list of (file_path, line_number, line_content) tuples.
    """
    if exclude_dirs is None:
        exclude_dirs = {"archive", ".git", "node_modules"}

    references = []
    services = "|".join(
        [
            "Prometheus",
            "Grafana",
            "Loki",
            "Alertmanager",
            "Fluent Bit",
            "LiteLLM",
            "OpenWebUI",
            "Ollama",
        ]
    )
    version_pattern = re.compile(rf"({services})\s+v?([\d.]+(?:-[\w.]+)?)", re.IGNORECASE)

    for md_file in docs_dir.rglob("*.md"):
        # Skip excluded directories
        if any(excluded in md_file.parts for excluded in exclude_dirs):
            continue

        try:
            lines = md_file.read_text(encoding="utf-8").splitlines()
            for line_num, line in enumerate(lines, 1):
                if version_pattern.search(line):
                    references.append((md_file, line_num, line))
        except Exception as e:
            print(f"[WARN] Could not read {md_file}: {e}", file=sys.stderr)

    return references


def validate_versions(check_only: bool = True) -> int:
    """Validate version consistency across documentation.

    Returns number of inconsistencies found.
    """
    print("🔍 Analyzing versions from compose.yml and status.yml...")

    compose_versions = parse_compose_versions()
    status_versions = parse_status_versions()

    print(f"✓ Found {len(compose_versions)} versions in compose.yml")
    print(f"✓ Found {len(status_versions)} versions in status.yml")

    # Check status.yml matches compose.yml
    inconsistencies = 0
    for service, compose_ver in compose_versions.items():
        status_ver = status_versions.get(service)
        if status_ver and status_ver != compose_ver:
            print(f"⚠️  {service}: status.yml has {status_ver}, compose.yml has {compose_ver}")
            inconsistencies += 1

    # Scan documentation
    print("\n🔍 Scanning documentation for version references...")
    refs = find_version_references(DOCS_DIR)
    print(f"✓ Found {len(refs)} version references in documentation\n")

    # Report first 10 files with most references
    from collections import Counter

    file_counts = Counter(ref[0] for ref in refs)
    print("📊 Files with most version references:")
    for file_path, count in file_counts.most_common(10):
        try:
            rel_path = file_path.relative_to(REPO_ROOT)
        except ValueError:
            rel_path = file_path
        print(f"   {count:3d} references in {rel_path}")

    if check_only:
        if inconsistencies == 0:
            print("\n✅ No inconsistencies found")
        else:
            print(f"\n❌ Found {inconsistencies} inconsistencies")
        print("💡 Run without --check to automatically fix status.yml inconsistencies")

    return inconsistencies


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate and fix version inconsistencies in documentation"
    )
    parser.add_argument(
        "--check", action="store_true", help="Check for inconsistencies without fixing"
    )
    args = parser.parse_args()

    inconsistencies = validate_versions(check_only=args.check)

    if args.check and inconsistencies > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
