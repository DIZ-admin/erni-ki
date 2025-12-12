#!/usr/bin/env python3
"""
Validate frontmatter metadata in documentation files.
Outputs per-file errors and a short summary (locales, missing/unknown/deprecated fields).
"""

import sys
from collections import Counter
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
    "doc_status",
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
    # Audit/report specific fields
    "audit_type",
    "audit_scope",
    "auditor",
    # Academy KI specific fields
    "category",
    "difficulty",
    "duration",
    "roles",
    "industry",
    "company",
    "level",
    "prerequisites",
    "document_type",
    "phase",
    "session",
    "report_type",
    "scope",
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
    """
    Return (errors, metadata, info) where:
    - errors: list[str]
    - metadata: dict | None
    - info: dict with keys
      (missing, deprecated, unknown, doc_version_ok, language, translation_status)
    """
    errors: list[str] = []
    info = {
        "missing": [],
        "deprecated": [],
        "unknown": [],
        "doc_version_ok": True,
        "language": None,
        "translation_status": None,
    }

    # Skip snippet templates that intentionally lack frontmatter
    if path.name == "status-snippet.md":
        return errors, None, info

    # Skip archives
    if "archive" in path.parts:
        return errors, None, info

    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        errors.append("No frontmatter found")
        return errors, None, info

    parts = text.split("---", 2)
    if len(parts) < 3:
        errors.append("Malformed frontmatter")
        return errors, None, info

    try:
        metadata = yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as exc:
        errors.append(f"Invalid YAML: {exc}")
        return errors, None, info

    info["language"] = metadata.get("language")
    info["translation_status"] = metadata.get("translation_status")

    for field in REQUIRED_FIELDS:
        if field not in metadata:
            errors.append(f"Missing required field: {field}")
            info["missing"].append(field)

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
            info["deprecated"].append(field)

    for field in metadata:
        if field not in ALLOWED_FIELDS:
            errors.append(f"Unknown field: {field}")
            info["unknown"].append(field)

    if metadata.get("doc_version") != TARGET_DOC_VERSION:
        errors.append(f"Incorrect doc_version: {metadata.get('doc_version')}")
        info["doc_version_ok"] = False

    return errors, metadata, info


def main() -> int:
    docs_dir = Path("docs")
    total_files = 0
    total_errors = 0
    files_with_errors = 0
    locale_counts: Counter[str] = Counter()
    translation_counts: Counter[str] = Counter()
    missing_counts: Counter[str] = Counter()
    deprecated_counts: Counter[str] = Counter()
    unknown_counts: Counter[str] = Counter()
    doc_version_mismatch = 0

    for md_file in docs_dir.rglob("*.md"):
        errs, metadata, info = validate_file(md_file)
        if errs:
            print(f"\n{md_file}:")
            for err in errs:
                print(f"  ❌ {err}")
            total_errors += len(errs)
            files_with_errors += 1
        if metadata:
            lang = info["language"] or "unknown"
            locale_counts[lang] += 1
            translation = info["translation_status"] or "unknown"
            translation_counts[translation] += 1
            for field in info["missing"]:
                missing_counts[field] += 1
            for field in info["deprecated"]:
                deprecated_counts[field] += 1
            for field in info["unknown"]:
                unknown_counts[field] += 1
            if not info["doc_version_ok"]:
                doc_version_mismatch += 1
        total_files += 1

    print(f"\nValidated {total_files} files")
    print(f"Files with errors: {files_with_errors} (issues: {total_errors})")
    if locale_counts:
        locales = ", ".join(f"{k}={v}" for k, v in sorted(locale_counts.items()))
        print(f"Locales: {locales}")
    if translation_counts:
        translations = ", ".join(f"{k}={v}" for k, v in sorted(translation_counts.items()))
        print(f"Translation statuses: {translations}")
    if missing_counts:
        missing = ", ".join(f"{k}={v}" for k, v in sorted(missing_counts.items()))
        print(f"Missing required fields: {missing}")
    if deprecated_counts:
        deprecated = ", ".join(f"{k}={v}" for k, v in sorted(deprecated_counts.items()))
        print(f"Deprecated fields found: {deprecated}")
    if unknown_counts:
        unknown = ", ".join(f"{k}={v}" for k, v in sorted(unknown_counts.items()))
        print(f"Unknown fields found: {unknown}")
    if doc_version_mismatch:
        print(f"doc_version mismatches: {doc_version_mismatch}")

    if total_errors:
        print("Metadata validation failed")
        return 1

    print("Metadata validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
