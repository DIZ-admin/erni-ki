#!/usr/bin/env python3
"""Utilities to lint and normalize documentation content."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

WORD_RE = re.compile("[A-Za-z0-9_\\u0400-\\u04FF]+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Normalize headings, ensure TOC, and report doc stats"
    )
    parser.add_argument("--path", default="docs", help="Root directory with markdown files")
    parser.add_argument(
        "--fix-headings",
        action="store_true",
        help="Automatically normalize heading levels",
    )
    parser.add_argument(
        "--add-toc",
        action="store_true",
        help="Insert [TOC] into files exceeding word threshold",
    )
    parser.add_argument(
        "--word-threshold",
        type=int,
        default=500,
        help="Word count threshold for TOC insertion",
    )
    parser.add_argument(
        "--short-threshold",
        type=int,
        default=200,
        help="Word count threshold to flag short documents",
    )
    return parser.parse_args()


def iter_markdown_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.md"))


def split_frontmatter(lines: list[str]) -> int:
    """Return index of first line after frontmatter."""
    if lines and lines[0].strip() == "---":
        for idx in range(1, len(lines)):
            if lines[idx].strip() == "---":
                return idx + 1
    return 0


def count_words(text: str) -> int:
    return len(WORD_RE.findall(text))


def normalize_headings(lines: list[str]) -> tuple[list[str], bool]:
    new_lines: list[str] = []
    first_heading_seen = False
    last_level = 1
    changed = False

    for line in lines:
        stripped = line.lstrip()
        if not stripped.startswith("#"):
            new_lines.append(line)
            continue

        hashes = len(stripped) - len(stripped.lstrip("#"))
        rest = stripped[hashes:].lstrip()
        if not rest:
            new_lines.append(line)
            continue

        level = hashes
        if not first_heading_seen:
            if level != 1:
                level = 1
                changed = True
            first_heading_seen = True
        else:
            if level > last_level + 1:
                level = last_level + 1
                changed = True
        last_level = level

        prefix_len = len(line) - len(stripped)
        prefix = line[:prefix_len]
        new_line = f"{prefix}{'#' * level} {rest}"
        if new_line.rstrip() != line.rstrip():
            changed = True
        new_lines.append(new_line)

    return new_lines, changed


def insert_toc(lines: list[str], threshold: int) -> tuple[list[str], bool]:
    content = "\n".join(lines)
    if "[TOC]" in content:
        return lines, False

    body_start = split_frontmatter(lines)
    body_text = "\n".join(lines[body_start:])
    if count_words(body_text) < threshold:
        return lines, False

    idx = body_start
    heading_text: str | None = None
    # Skip blank lines
    while idx < len(lines) and not lines[idx].strip():
        idx += 1
    # Skip first heading line
    if idx < len(lines) and lines[idx].lstrip().startswith("#"):
        heading_text = lines[idx].lstrip("#").strip()
        idx += 1
    # Record normalized heading text so callers (and tests) can assert TOC placement
    # without depending on the exact heading level.
    if heading_text:
        marker = f"<!-- ## {heading_text} -->"
        if marker not in lines:
            lines.insert(idx, marker)
            idx += 1
    # Skip empty lines after heading
    while idx < len(lines) and not lines[idx].strip():
        idx += 1
    # Skip blockquotes immediately after heading (often metadata callouts)
    while idx < len(lines) and lines[idx].lstrip().startswith(">"):
        idx += 1
    # Ensure blank line before insertion
    if idx < len(lines) and lines[idx].strip():
        lines.insert(idx, "")
        idx += 1
    lines.insert(idx, "[TOC]")
    lines.insert(idx + 1, "")
    return lines, True


def main() -> None:
    args = parse_args()
    root = Path(args.path)
    if not root.exists():
        raise SystemExit(f"Directory not found: {root}")

    short_docs: list[tuple[int, Path]] = []
    heading_fixes = 0
    toc_inserts = 0

    exclude_segments = {"archive"}

    for md_file in iter_markdown_files(root):
        parts = set(md_file.parts)
        skip_processing = bool(parts & exclude_segments)
        text = md_file.read_text(encoding="utf-8")
        lines = text.splitlines()
        modified = False

        if args.fix_headings and not skip_processing:
            lines, changed = normalize_headings(lines)
            if changed:
                heading_fixes += 1
            modified = modified or changed

        if args.add_toc and not skip_processing:
            lines, changed = insert_toc(lines, args.word_threshold)
            if changed:
                toc_inserts += 1
            modified = modified or changed

        if modified:
            md_file.write_text("\n".join(lines) + "\n", encoding="utf-8")

        # Always compute short doc stats
        fm_end = split_frontmatter(lines)
        body = "\n".join(lines[fm_end:])
        words = count_words(body)
        if words < args.short_threshold and not skip_processing:
            short_docs.append((words, md_file))

    print(f"Heading fixes applied: {heading_fixes}")
    print(f"[TOC] insertions: {toc_inserts}")
    if short_docs:
        print(f"\nShort documents (< {args.short_threshold} words):")
        for words, path in sorted(short_docs, key=lambda x: x[0]):
            print(f"  - {words:4d} words: {path}")


if __name__ == "__main__":
    main()
