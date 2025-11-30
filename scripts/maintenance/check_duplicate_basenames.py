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
        if not search_path.exists():
            return by_name
        # Only recurse for expected top-level targets; otherwise scan shallowly
        iterator = (
            search_path.rglob("*") if search_path.name in TARGET_DIRS else search_path.glob("*")
        )
        for path in iterator:
            if path.is_dir() and path.name == "__pycache__":
                continue
            if path.suffix == ".pyc":
                continue
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
        if "__pycache__" in path.parts or path.suffix == ".pyc":
            continue
        if not any(
            str(path).startswith(prefix + "/") or str(path) == prefix for prefix in TARGET_DIRS
        ):
            continue
        if path.name in ALLOWLIST or path.name == ".gitkeep":
            continue
        by_name[path.name].append(path)

    return by_name


def check_duplicates(
    scripts_basenames: dict[str, list[Path]], conf_basenames: dict[str, list[Path]]
) -> dict[str, list[Path]]:
    """Check for duplicate basenames between scripts/ and conf/ directories.

    Args:
            scripts_basenames: Mapping of basenames to paths in scripts/ directory.
            conf_basenames: Mapping of basenames to paths in conf/ directory.

    Returns:
            Dictionary of basenames that appear in both directories, mapped to list of paths.
    """
    duplicates: dict[str, list[Path]] = {}

    # Find basenames that exist in both directories
    for name in scripts_basenames:
        if name in conf_basenames:
            duplicates[name] = scripts_basenames[name] + conf_basenames[name]

    return duplicates


def main() -> None:
    """Main entry point."""
    scripts_basenames = get_basenames(Path.cwd() / "scripts")
    conf_basenames = get_basenames(Path.cwd() / "conf")
    duplicates = check_duplicates(scripts_basenames, conf_basenames)

    exit_code = 1 if duplicates else 0
    if duplicates:
        print("Duplicate basenames detected in scripts/ or conf/:")
        for name, paths in sorted(duplicates.items()):
            print(f"- {name}")
            for p in paths:
                print(f"    {p}")
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
