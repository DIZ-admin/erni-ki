#!/usr/bin/env python3
"""Validate that archive/data README files list all documents."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE_CHECKS = {
    ROOT / "docs/en/archive/audits": ROOT / "docs/en/archive/audits/README.md",
    ROOT / "docs/en/archive/diagnostics": ROOT / "docs/en/archive/diagnostics/README.md",
    ROOT / "docs/en/archive/incidents": ROOT / "docs/en/archive/incidents/README.md",
}
DATA_DIR = ROOT / "docs/en/data"
DATA_README = DATA_DIR / "README.md"


def missing_entries(directory: Path, readme: Path, include_suffix: str = ".md") -> list[str]:
    text = readme.read_text(encoding="utf-8")
    missing: list[str] = []
    for md_file in sorted(directory.glob(f"*{include_suffix}")):
        if md_file.name.lower() == "readme.md":
            continue
        if md_file.name not in text:
            missing.append(md_file.name)
    return missing


def check_archive_readmes() -> list[str]:
    errors: list[str] = []
    for folder, readme in ARCHIVE_CHECKS.items():
        if not readme.exists():
            errors.append(f"{readme} is missing.")
            continue
        missing = missing_entries(folder, readme)
        if missing:
            errors.append(f"{readme} does not contain references to: {', '.join(missing)}")
    return errors


def check_data_readme() -> list[str]:
    if not DATA_README.exists():
        return [f"{DATA_README} is missing."]
    text = DATA_README.read_text(encoding="utf-8")

    # Check table structure first (header, separator, at least one data row)
    table_rows = [line for line in text.splitlines() if line.strip().startswith("| ")]
    # Need at least: header row, separator row, and one data row = 3 rows minimum
    if len(table_rows) < 3:
        return [f"{DATA_README} state table looks incomplete (found {len(table_rows)} rows)."]

    # Then check for missing entries
    missing = missing_entries(DATA_DIR, DATA_README)
    if missing:
        return [f"{DATA_README} does not contain entries for: {', '.join(missing)}"]

    return []


def main() -> None:
    errors = check_archive_readmes()
    errors.extend(check_data_readme())
    if errors:
        print("Archive/data README check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        sys.exit(1)
    print("Archive/data READMEs cover all documents.")


if __name__ == "__main__":
    main()
