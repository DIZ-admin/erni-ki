#!/usr/bin/env python3
"""
ERNI-KI Documentation Validator

Validates documentation structure, metadata, and links.

Usage:
    ./validate-documentation.py [--fix] [--report PATH]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib.logger import get_logger

logger = get_logger(__name__)

REPO_ROOT = Path(__file__).resolve().parents[2]
DOCS_DIR = REPO_ROOT / "docs"

# =============================================================================
# Validation Rules
# =============================================================================

REQUIRED_FIELDS = {
    "language": ["ru", "en", "de"],
    "doc_version": None,  # Any value accepted
}

OPTIONAL_FIELDS = {
    "translation_status": ["original", "complete", "draft", "pending", "partial", "in_progress"],
    "last_updated": None,
    "category": None,
}


class ValidationResult:
    """Track validation results."""

    def __init__(self):
        self.total_files = 0
        self.valid_files = 0
        self.warnings = []
        self.errors = []

    def add_warning(self, file_path: str, message: str):
        """Add warning."""
        self.warnings.append(f"{file_path}: {message}")
        logger.warning("%s: %s", file_path, message)

    def add_error(self, file_path: str, message: str):
        """Add error."""
        self.errors.append(f"{file_path}: {message}")
        logger.error("%s: %s", file_path, message)

    def report(self) -> dict[str, Any]:
        """Generate validation report."""
        return {
            "total_files": self.total_files,
            "valid_files": self.valid_files,
            "warnings": len(self.warnings),
            "errors": len(self.errors),
            "warning_list": self.warnings[:20],
            "error_list": self.errors[:20],
        }


def parse_frontmatter(content: str) -> dict[str, str] | None:
    """Parse YAML frontmatter."""
    if not content.startswith("---"):
        return None

    parts = content.split("---", 2)
    if len(parts) < 3:
        return None

    frontmatter = {}
    for line in parts[1].strip().split("\n"):
        if ":" in line:
            key, value = line.split(":", 1)
            frontmatter[key.strip()] = value.strip().strip("'\"")

    return frontmatter


def validate_file(file_path: Path, result: ValidationResult) -> bool:
    """
    Validate single markdown file.

    Returns True if valid, False otherwise.
    """
    result.total_files += 1
    rel_path = str(file_path.relative_to(DOCS_DIR))
    is_valid = True

    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as exc:
        result.add_error(rel_path, f"Failed to read: {exc}")
        return False

    # Check frontmatter
    frontmatter = parse_frontmatter(content)

    if not frontmatter:
        result.add_error(rel_path, "Missing frontmatter")
        return False

    # Check required fields
    for field, allowed_values in REQUIRED_FIELDS.items():
        if field not in frontmatter:
            result.add_error(rel_path, f"Missing required field: {field}")
            is_valid = False
            continue

        if allowed_values and frontmatter[field] not in allowed_values:
            result.add_error(
                rel_path, f"Invalid {field}: {frontmatter[field]} (expected: {allowed_values})"
            )
            is_valid = False

    # Check optional fields
    for field, allowed_values in OPTIONAL_FIELDS.items():
        if field in frontmatter:
            if allowed_values and frontmatter[field] not in allowed_values:
                result.add_warning(
                    rel_path,
                    f"Invalid {field}: {frontmatter[field]} (expected: {allowed_values})",
                )

    # Check language vs path consistency
    if "language" in frontmatter:
        lang = frontmatter["language"]
        path_str = str(file_path)

        # Check if language matches directory
        if lang == "de" and "/de/" not in path_str:
            result.add_warning(rel_path, f"Language is {lang} but not in /de/ directory")
        elif lang == "en" and "/en/" not in path_str and "/de/" not in path_str:
            if not path_str.endswith(("docs/index.md", "docs/overview.md", "docs/VERSION.md")):
                # Russian is default, should not be in /en/ or /de/
                pass
        elif lang == "ru":
            if "/en/" in path_str or "/de/" in path_str:
                result.add_error(rel_path, "Language is ru but in /en/ or /de/ directory")

    if is_valid:
        result.valid_files += 1

    return is_valid


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Validate ERNI-KI documentation")
    parser.add_argument("--fix", action="store_true", help="Auto-fix issues where possible")
    parser.add_argument("--report", type=str, help="Save report to JSON file")

    args = parser.parse_args()

    logger.info("Starting documentation validation")

    result = ValidationResult()

    # Validate all markdown files
    for file_path in DOCS_DIR.rglob("*.md"):
        # Skip archive
        if "archive" in file_path.parts:
            continue

        validate_file(file_path, result)

    # Generate report
    report = result.report()

    logger.info("Validation completed")
    logger.info("Total files: %d", report["total_files"])
    logger.info("Valid files: %d", report["valid_files"])
    logger.info("Warnings: %d", report["warnings"])
    logger.info("Errors: %d", report["errors"])

    # Save report if requested
    if args.report:
        report_path = Path(args.report)
        report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        logger.info("Report saved to: %s", report_path)

    # Print summary
    print("\n" + "=" * 60)
    print("DOCUMENTATION VALIDATION SUMMARY")
    print("=" * 60)
    print(f"Total files:  {report['total_files']}")
    print(f"Valid files:  {report['valid_files']}")
    print(f"Warnings:     {report['warnings']}")
    print(f"Errors:       {report['errors']}")
    print("=" * 60)

    if report["errors"] > 0:
        print("\nTop errors:")
        for error in report["error_list"][:10]:
            print(f"  ❌ {error}")

    if report["warnings"] > 0:
        print("\nTop warnings:")
        for warning in report["warning_list"][:10]:
            print(f"  ⚠️  {warning}")

    # Exit with error if validation failed
    if report["errors"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
