"""Validate visuals presence, basic TOC structure, and relative links.

Checks are scoped to files listed in docs/visuals_targets.json to avoid
false positives. The script is intentionally lightweight and dependency-free.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

RE_VISUAL = re.compile(r"```mermaid|!\[.*?\]\(", re.IGNORECASE)
RE_HEADINGS = re.compile(r"^#{2,6}\s+", re.MULTILINE)
RE_REL_LINK = re.compile(r"\[[^\]]+\]\((?!https?://)(?!mailto:)(?!#)([^)]+)\)")

ROOT = Path(__file__).resolve().parents[2]
TARGETS = ROOT / "docs" / "visuals_targets.json"


def load_targets() -> list[dict]:
    if not TARGETS.exists():
        raise SystemExit(f"Missing config file: {TARGETS}")
    with TARGETS.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, list) else []


def has_visual(text: str) -> bool:
    return bool(RE_VISUAL.search(text))


def has_basic_toc(text: str) -> bool:
    return len(RE_HEADINGS.findall(text)) >= 2


def check_links(path: Path, text: str) -> list[str]:
    issues: list[str] = []
    for target in RE_REL_LINK.findall(text):
        target = target.split("#", 1)[0].strip()
        if not target:
            continue
        candidate = (path.parent / target).resolve()
        if not candidate.exists():
            rel = candidate.relative_to(ROOT, walk_up=True)
            issues.append(f"missing link target: {rel}")
    return issues


def validate_file(rel_path: str) -> list[str]:
    path = ROOT / rel_path
    if not path.exists():
        return ["file not found"]
    text = path.read_text(encoding="utf-8")
    problems: list[str] = []
    if not has_visual(text):
        problems.append("no visual (mermaid/image) detected")
    if not has_basic_toc(text):
        problems.append("no headings found for basic TOC")
    problems.extend(check_links(path, text))
    return problems


def main() -> None:
    targets = load_targets()
    errors: list[str] = []
    for item in targets:
        rel_path = item.get("path")
        if not rel_path:
            continue
        problems = validate_file(rel_path)
        if problems:
            joined = "; ".join(problems)
            errors.append(f"{rel_path}: {joined}")

    if errors:
        print("Visual/TOC/link check failed:")
        for err in errors:
            print(f" - {err}")
        raise SystemExit(1)

    print("Visual/TOC/link check passed for targets.")


if __name__ == "__main__":
    main()
