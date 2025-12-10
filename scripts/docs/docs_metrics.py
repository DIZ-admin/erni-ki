#!/usr/bin/env python3
"""
Collect comprehensive documentation metrics for monitoring and reporting.

This script generates JSON metrics about documentation quality:
- Total documentation files count
- Stale documents (90+ days old based on last_updated)
- Broken links percentage (from lychee output)
- Translation sync status (DE/EN vs RU canonical)
- Frontmatter coverage
- Overall quality score

Usage:
    python scripts/docs/docs_metrics.py                    # Generate metrics JSON
    python scripts/docs/docs_metrics.py --threshold-check  # Exit 1 if thresholds exceeded
    python scripts/docs/docs_metrics.py --output metrics.json  # Save to file
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

import yaml

# Thresholds for alerting
THRESHOLDS = {
    "stale_docs_count": 20,
    "broken_links_percentage": 5.0,
    "frontmatter_coverage": 95.0,
    "quality_score": 80.0,
}

STALE_DAYS = 90
REQUIRED_FIELDS = ["language", "translation_status", "doc_version"]


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Collect documentation metrics")
    parser.add_argument(
        "--threshold-check",
        action="store_true",
        help="Exit with code 1 if thresholds are exceeded",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Save metrics to JSON file (default: stdout)",
    )
    parser.add_argument(
        "--lychee-output",
        type=Path,
        help="Path to lychee output file (optional, for broken links)",
    )
    return parser.parse_args()


def parse_frontmatter(path: Path) -> dict[str, Any]:
    """Extract YAML frontmatter from markdown file."""
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
        if not text.startswith("---"):
            return {}
        parts = text.split("---", 2)
        if len(parts) < 3:
            return {}
        return yaml.safe_load(parts[1]) or {}
    except Exception:
        return {}


def collect_file_metrics(docs_dir: Path) -> dict[str, Any]:
    """Collect metrics about all markdown files."""
    metrics = {
        "total_docs": 0,
        "with_frontmatter": 0,
        "without_frontmatter": 0,
        "stale_docs_count": 0,
        "stale_docs": [],
        "by_language": defaultdict(int),
        "by_translation_status": defaultdict(int),
    }

    cutoff_date = datetime.now() - timedelta(days=STALE_DAYS)

    for md_file in docs_dir.rglob("*.md"):
        # Skip excluded directories
        if any(excl in md_file.parts for excl in [".venv", "node_modules", "site", "archive"]):
            continue

        metrics["total_docs"] += 1

        # Parse frontmatter
        frontmatter = parse_frontmatter(md_file)

        if frontmatter:
            metrics["with_frontmatter"] += 1

            # Track language
            lang = frontmatter.get("language", "unknown")
            metrics["by_language"][lang] += 1

            # Track translation status
            trans_status = frontmatter.get("translation_status", "unknown")
            metrics["by_translation_status"][trans_status] += 1

            # Check if stale
            last_updated = frontmatter.get("last_updated")
            if last_updated:
                try:
                    # Handle both YYYY-MM-DD and datetime formats
                    if isinstance(last_updated, str):
                        updated_date = datetime.strptime(last_updated, "%Y-%m-%d")
                    elif isinstance(last_updated, datetime):
                        updated_date = last_updated
                    else:
                        continue

                    if updated_date < cutoff_date:
                        metrics["stale_docs_count"] += 1
                        metrics["stale_docs"].append(
                            {
                                "path": str(md_file.relative_to(docs_dir)),
                                "last_updated": last_updated  # noqa: E501
                                if isinstance(last_updated, str)
                                else last_updated.strftime("%Y-%m-%d"),
                                "days_old": (datetime.now() - updated_date).days,
                            }
                        )
                except (ValueError, TypeError):
                    # Skip files with invalid date formats
                    pass
        else:
            metrics["without_frontmatter"] += 1

    # Convert defaultdicts to regular dicts for JSON serialization
    metrics["by_language"] = dict(metrics["by_language"])
    metrics["by_translation_status"] = dict(metrics["by_translation_status"])

    return metrics


def collect_ru_canonical_files(docs_dir: Path) -> list[Path]:
    """Collect all RU canonical files (not in de/ or en/ subdirs, not archived)."""
    ru_files = []
    for md_file in docs_dir.rglob("*.md"):
        parts = set(md_file.parts)
        if "archive" in parts:
            continue
        if "de" in parts or "en" in parts:
            continue
        ru_files.append(md_file)
    return ru_files


def collect_translation_metrics(docs_dir: Path) -> dict[str, dict[str, int]]:
    """Collect translation sync status for DE and EN vs RU canonical."""
    ru_files = collect_ru_canonical_files(docs_dir)
    ru_count = len(ru_files)

    translation_sync = {}

    for locale in ["de", "en"]:
        stats = defaultdict(int)
        missing_count = 0

        for ru_file in ru_files:
            rel_path = ru_file.relative_to(docs_dir)
            locale_path = docs_dir / locale / rel_path

            if not locale_path.exists():
                missing_count += 1
                continue

            frontmatter = parse_frontmatter(locale_path)
            trans_status = frontmatter.get("translation_status", "unknown")
            stats[trans_status] += 1

        translation_sync[locale] = {
            "complete": stats.get("complete", 0),
            "partial": stats.get("partial", 0),
            "missing": missing_count,
            "unknown": stats.get("unknown", 0),
            "total_ru_files": ru_count,
        }

    return translation_sync


def parse_lychee_output(lychee_path: Path | None) -> dict[str, Any]:
    """Parse lychee output to get broken links metrics."""
    if not lychee_path or not lychee_path.exists():
        return {"broken_links_count": 0, "total_links_checked": 0, "broken_links_percentage": 0.0}

    try:
        output = lychee_path.read_text(encoding="utf-8")

        # Parse lychee summary format
        # Example: "Total: 1234, OK: 1200, Errors: 34"
        total_match = re.search(r"Total:\s*(\d+)", output)
        errors_match = re.search(r"Errors:\s*(\d+)", output)

        total = int(total_match.group(1)) if total_match else 0
        errors = int(errors_match.group(1)) if errors_match else 0

        percentage = (errors / total * 100) if total > 0 else 0.0

        return {
            "broken_links_count": errors,
            "total_links_checked": total,
            "broken_links_percentage": round(percentage, 2),
        }
    except Exception:
        return {"broken_links_count": 0, "total_links_checked": 0, "broken_links_percentage": 0.0}


def calculate_frontmatter_coverage(file_metrics: dict[str, Any]) -> float:
    """Calculate percentage of files with valid frontmatter."""
    total = file_metrics["total_docs"]
    if total == 0:
        return 100.0
    with_fm = file_metrics["with_frontmatter"]
    return round((with_fm / total) * 100, 2)


def calculate_quality_score(metrics: dict[str, Any]) -> float:
    """
    Calculate overall quality score (0-100).

    Components:
    - Frontmatter coverage: 30 points
    - Stale docs penalty: up to -20 points
    - Broken links penalty: up to -30 points
    - Translation completeness: 40 points (20 per language)
    """
    score = 0.0

    # Frontmatter coverage (30 points)
    fm_coverage = metrics["frontmatter_coverage"]
    score += (fm_coverage / 100) * 30

    # Stale docs penalty (up to -20 points)
    stale_count = metrics["stale_docs_count"]
    stale_penalty = min(20, (stale_count / 50) * 20)  # Max penalty at 50 stale docs
    score -= stale_penalty

    # Broken links penalty (up to -30 points)
    broken_pct = metrics["broken_links_percentage"]
    broken_penalty = min(30, (broken_pct / 10) * 30)  # Max penalty at 10% broken
    score -= broken_penalty

    # Translation completeness (40 points total, 20 per language)
    for locale_data in metrics["translation_sync"].values():
        total_ru = locale_data["total_ru_files"]
        if total_ru > 0:
            complete = locale_data["complete"]
            partial = locale_data["partial"]
            # Complete files: 100%, partial: 50%
            locale_score = ((complete + (partial * 0.5)) / total_ru) * 20
            score += locale_score

    return round(max(0, min(100, score)), 2)


def check_thresholds(metrics: dict[str, Any]) -> list[str]:
    """Check if any thresholds are exceeded and return list of violations."""
    violations = []

    if metrics["stale_docs_count"] > THRESHOLDS["stale_docs_count"]:
        violations.append(
            f"Stale docs count ({metrics['stale_docs_count']}) exceeds threshold ({THRESHOLDS['stale_docs_count']})"  # noqa: E501
        )

    if metrics["broken_links_percentage"] > THRESHOLDS["broken_links_percentage"]:
        violations.append(
            f"Broken links percentage ({metrics['broken_links_percentage']}%) exceeds threshold ({THRESHOLDS['broken_links_percentage']}%)"  # noqa: E501
        )

    if metrics["frontmatter_coverage"] < THRESHOLDS["frontmatter_coverage"]:
        violations.append(
            f"Frontmatter coverage ({metrics['frontmatter_coverage']}%) below threshold ({THRESHOLDS['frontmatter_coverage']}%)"  # noqa: E501
        )

    if metrics["quality_score"] < THRESHOLDS["quality_score"]:
        violations.append(
            f"Quality score ({metrics['quality_score']}) below threshold ({THRESHOLDS['quality_score']})"  # noqa: E501
        )

    return violations


def main() -> int:
    """Main entry point."""
    args = parse_args()
    docs_dir = Path("docs")

    # Collect all metrics
    file_metrics = collect_file_metrics(docs_dir)
    translation_sync = collect_translation_metrics(docs_dir)
    link_metrics = parse_lychee_output(args.lychee_output)

    # Calculate derived metrics
    frontmatter_coverage = calculate_frontmatter_coverage(file_metrics)

    # Assemble full metrics
    metrics = {
        "timestamp": datetime.now().isoformat(),
        "total_docs": file_metrics["total_docs"],
        "stale_docs_count": file_metrics["stale_docs_count"],
        "stale_docs": file_metrics["stale_docs"][:10],  # Include top 10 for reporting
        "broken_links_count": link_metrics["broken_links_count"],
        "total_links_checked": link_metrics["total_links_checked"],
        "broken_links_percentage": link_metrics["broken_links_percentage"],
        "translation_sync": translation_sync,
        "frontmatter_coverage": frontmatter_coverage,
        "with_frontmatter": file_metrics["with_frontmatter"],
        "without_frontmatter": file_metrics["without_frontmatter"],
        "by_language": file_metrics["by_language"],
        "by_translation_status": file_metrics["by_translation_status"],
    }

    # Calculate quality score
    metrics["quality_score"] = calculate_quality_score(metrics)

    # Check thresholds
    violations = check_thresholds(metrics)
    metrics["threshold_violations"] = violations
    metrics["thresholds_exceeded"] = len(violations) > 0

    # Output results
    json_output = json.dumps(metrics, indent=2, ensure_ascii=False)

    if args.output:
        args.output.write_text(json_output, encoding="utf-8")
        print(f"Metrics saved to {args.output}", file=sys.stderr)
    else:
        print(json_output)

    # Return exit code based on threshold check
    if args.threshold_check and violations:
        print("\n❌ Threshold violations detected:", file=sys.stderr)
        for violation in violations:
            print(f"  - {violation}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
# ruff: noqa: N999
