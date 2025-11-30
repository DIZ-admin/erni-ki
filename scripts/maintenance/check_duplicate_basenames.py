#!/usr/bin/env python3
"""Fail if duplicate basenames exist in scripts/ or conf/."""

from __future__ import annotations

import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGET_DIRS = ("scripts", "conf")
ALLOWLIST = {"README.md", "__init__.py", "config.example"}


def get_basenames(search_path: Path | None = None) -> dict[str, list[Path]]:
    """Get mapping of basenames to file paths.

    Args:
            search_path: Optional path to search (for testing). Defaults to TARGET_DIRS.

    Returns:
            Dictionary mapping basenames to list of paths.
    """
    by_name: dict[str, list[Path]] = defaultdict(list)

    if search_path:
        # For testing: scan local directory
        for path in search_path.rglob("*"):
            if path.is_file() and path.name not in ALLOWLIST and path.name != ".gitkeep":
                by_name[path.name].append(path)
        return by_name

    try:
        files = subprocess.check_output(["git", "ls-files"], text=True).strip().splitlines()
    except subprocess.CalledProcessError as exc:
        print(f"Failed to list files: {exc}", file=sys.stderr)
        return by_name

    for file_path in files:
        path = Path(file_path)
        if not any(
            str(path).startswith(prefix + "/") or str(path) == prefix for prefix in TARGET_DIRS
        ):
            continue
        if path.name in ALLOWLIST or path.name == ".gitkeep":
            continue
        by_name[path.name].append(path)

    return by_name


def check_duplicates(by_name: dict[str, list[Path]] | None = None) -> int:
    """Check for duplicate basenames and report them.

    Args:
            by_name: Optional dict of basenames to paths. If None, will call get_basenames().

    Returns:
            0 if no duplicates, 1 if duplicates found.
    """
    if by_name is None:
        by_name = get_basenames()

    duplicates = {name: paths for name, paths in by_name.items() if len(paths) > 1}

    if not duplicates:
        return 0

    print("Duplicate basenames detected in scripts/ or conf/:", file=sys.stderr)
    for name, paths in sorted(duplicates.items()):
        print(f"- {name}", file=sys.stderr)
        for p in paths:
            print(f"    {p}", file=sys.stderr)
    return 1


def main() -> int:
    """Main entry point."""
    by_name = get_basenames()
    return check_duplicates(by_name)


if __name__ == "__main__":
    raise SystemExit(main())
