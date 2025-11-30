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


def main() -> int:
    by_name: dict[str, list[Path]] = defaultdict(list)

    try:
        files = subprocess.check_output(["git", "ls-files"], text=True).strip().splitlines()
    except subprocess.CalledProcessError as exc:
        print(f"Failed to list files: {exc}", file=sys.stderr)
        return 1

    for file_path in files:
        path = Path(file_path)
        if not any(
            str(path).startswith(prefix + "/") or str(path) == prefix for prefix in TARGET_DIRS
        ):
            continue
        if path.name in ALLOWLIST or path.name == ".gitkeep":
            continue
        by_name[path.name].append(path)

    duplicates = {name: paths for name, paths in by_name.items() if len(paths) > 1}

    if not duplicates:
        return 0

    print("Duplicate basenames detected in scripts/ or conf/:", file=sys.stderr)
    for name, paths in sorted(duplicates.items()):
        print(f"- {name}", file=sys.stderr)
        for p in paths:
            print(f"    {p}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
