#!/usr/bin/env python3
"""
Validate frontmatter metadata in documentation files.
"""

import sys
from pathlib import Path

import yaml

REQUIRED_FIELDS = ["language", "translation_status", "doc_version"]
ALLOWED_FIELDS = [
    "language",
    "translation_status",
    "doc_version",
    "last_updated",
    "system_version",
    "system_status",
    "title",
    "description",
    "tags",
    "date",
    "page_id",
    "audience",
    "summary",
    "version",
    "status",
    "released",
]
DEPRECATED_FIELDS = [
    "author",
    "contributors",
    "maintainer",
    "created",
    "updated",
    "created_date",
    "last_modified",
    "version",  # use system_version
    "status",  # use system_status or doc_status
]

TARGET_DOC_VERSION = "2025.11"


def validate_file(path: Path):
    errors = []

    # Skip archives
    if "archive" in path.parts:
        return errors

    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return ["No frontmatter found"]

    parts = text.split("---", 2)
    if len(parts) < 3:
        return ["Malformed frontmatter"]

    try:
        metadata = yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as exc:
        return [f"Invalid YAML: {exc}"]

    for field in REQUIRED_FIELDS:
        if field not in metadata:
            errors.append(f"Missing required field: {field}")

    language = metadata.get("language")
    filename = path.name

    for field in DEPRECATED_FIELDS:
        # relax version/status for non-ru docs; allow VERSION.md special fields
        if field in {"version", "status"} and language != "ru":
            continue
        if field in {"released", "status"} and filename == "VERSION.md":
            continue
        if field in metadata:
            errors.append(f"Deprecated field found: {field}")

    for field in metadata:
        if field not in ALLOWED_FIELDS:
            errors.append(f"Unknown field: {field}")

    if metadata.get("doc_version") != TARGET_DOC_VERSION:
        errors.append(f"Incorrect doc_version: {metadata.get('doc_version')}")

    return errors


def main() -> int:
    docs_dir = Path("docs")
    total_files = 0
    total_errors = 0

    for md_file in docs_dir.rglob("*.md"):
        errs = validate_file(md_file)
        if errs:
            print(f"\n{md_file}:")
            for err in errs:
                print(f"  ❌ {err}")
            total_errors += len(errs)
        total_files += 1

    print(f"\nValidated {total_files} files")
    if total_errors:
        print(f"Found {total_errors} metadata issues")
        return 1

    print("Metadata validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
