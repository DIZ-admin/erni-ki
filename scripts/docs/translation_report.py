#!/usr/bin/env python3
"""Generate translation coverage report for docs."""

from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path

import yaml


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Report translation coverage")
    parser.add_argument("--root", default="docs", help="Docs root directory")
    parser.add_argument("--locales", nargs="+", default=["de", "en"], help="Locales to report")
    parser.add_argument(
        "--exclude",
        nargs="+",
        default=["archive"],
        help="Directories (any segment) to exclude from analysis",
    )
    return parser.parse_args()


def parse_frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="ignore")
    if not text.startswith("---"):
        return {}
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}
    try:
        return yaml.safe_load(parts[1]) or {}
    except Exception:
        return {}


def collect_ru_files(root: Path, exclude: set[str]) -> list[Path]:
    ru_files = []
    for p in root.rglob("*.md"):
        parts = set(p.parts)
        if parts & exclude:
            continue
        if "de" in parts or "en" in parts:
            continue
        ru_files.append(p)
    return ru_files


def main() -> None:
    args = parse_args()
    root = Path(args.root)
    exclude = set(args.exclude)

    ru_files = collect_ru_files(root, exclude)
    ru_count = len(ru_files)

    print(f"RU canonical files: {ru_count}")

    for locale in args.locales:
        stats = defaultdict(int)
        missing = []
        for ru in ru_files:
            rel = ru.relative_to(root)
            loc_path = root / locale / rel
            if not loc_path.exists():
                missing.append(rel)
                continue
            fm = parse_frontmatter(loc_path)
            status = fm.get("translation_status", "unknown")
            stats[status] += 1

        total = sum(stats.values())
        complete = stats.get("complete", 0)
        coverage = (complete / ru_count * 100) if ru_count else 0.0

        print(f"\nLocale: {locale}")
        print(f"  Files present: {total} / {ru_count} ({total / ru_count * 100:.1f}%)")
        for k, v in sorted(stats.items()):
            print(f"    {k}: {v}")
        print(f"  Coverage (complete/ru): {coverage:.1f}% ({complete}/{ru_count})")
        print(f"  Missing files: {len(missing)}")
        if missing:
            sample = [str(m) for m in missing[:10]]
            print(f"    Sample: {sample}")


if __name__ == "__main__":
    main()
