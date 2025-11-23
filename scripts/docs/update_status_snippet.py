#!/usr/bin/env python3
"""
Sync or validate ERNI-KI status snippets across README, docs and locales.

Source of truth: docs/reference/status.yml
Run without arguments to update snippets, or with --check to validate.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
STATUS_YAML = REPO_ROOT / "docs/reference/status.yml"
SNIPPET_MD = REPO_ROOT / "docs/reference/status-snippet.md"
SNIPPET_DE_MD = REPO_ROOT / "docs/de/status-snippet.md"
README_FILE = REPO_ROOT / "README.md"
DOC_INDEX_FILE = REPO_ROOT / "docs/index.md"
DOC_OVERVIEW_FILE = REPO_ROOT / "docs/overview.md"
DE_INDEX_FILE = REPO_ROOT / "docs/de/index.md"
MARKER_START = "<!-- STATUS_SNIPPET_START -->"
MARKER_END = "<!-- STATUS_SNIPPET_END -->"
DE_MARKER_START = "<!-- STATUS_SNIPPET_DE_START -->"
DE_MARKER_END = "<!-- STATUS_SNIPPET_DE_END -->"
LOCALE_STRINGS_FILE = REPO_ROOT / "docs/reference/status-snippet-locales.json"


def load_locale_strings() -> dict[str, dict[str, str]]:
    if not LOCALE_STRINGS_FILE.exists():
        return {}
    try:
        return json.loads(LOCALE_STRINGS_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"[WARN] Failed to parse {LOCALE_STRINGS_FILE}: {exc}")
        return {}


LOCALE_STRINGS = load_locale_strings()


def parse_simple_yaml(path: Path) -> dict[str, str]:
    """Minimal YAML parser for flat key-value files."""
    data: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"').strip("'")
    return data


def render_snippet(data: dict[str, str], locale: str = "ru") -> str:
    """Build the Markdown snippet using locale-specific labels."""
    labels = LOCALE_STRINGS.get(locale, LOCALE_STRINGS.get("ru", {}))
    header_label = labels.get("header", "System Status")
    header = f"> **{header_label} ({data.get('date', 'n/a')}) — {data.get('release', '')}**"
    lines = [
        header,
        ">",
        f"> - {labels.get('containers', 'Containers')}: {data.get('containers', '')}",
        f"> - {labels.get('grafana', 'Grafana')}: {data.get('grafana_dashboards', '')}",
        f"> - {labels.get('alerts', 'Alerts')}: {data.get('prometheus_alerts', '')}",
        f"> - {labels.get('aiGpu', 'AI/GPU')}: {data.get('gpu_stack', '')}",
        f"> - {labels.get('context', 'Context & RAG')}: {data.get('ai_stack', '')}",
        f"> - {labels.get('monitoring', 'Monitoring')}: {data.get('monitoring_stack', '')}",
        f"> - {labels.get('automation', 'Automation')}: {data.get('automation', '')}",
    ]
    note = data.get("notes")
    if note:
        label = labels.get("note", "Note")
        lines.append(f"> - {label}: {note}")
    return "\n".join(lines) + "\n"


def write_snippet(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def run_prettier(paths: list[str]) -> None:
    try:
        subprocess.run(
            ["npx", "prettier", "--write", *paths],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
        )
    except FileNotFoundError:
        print("[WARN] npx not found; skipping prettier formatting.")
    except subprocess.CalledProcessError as exc:
        print("[WARN] prettier failed:", exc.stderr.decode("utf-8"), file=sys.stderr)


def prettier_format(text: str, filepath: Path) -> str:
    rel = filepath.relative_to(REPO_ROOT).as_posix()
    try:
        proc = subprocess.run(
            ["npx", "prettier", "--parser", "markdown", "--stdin-filepath", rel],
            cwd=REPO_ROOT,
            input=text.encode("utf-8"),
            check=True,
            capture_output=True,
        )
        return proc.stdout.decode("utf-8").strip()
    except (FileNotFoundError, subprocess.CalledProcessError):
        return text.strip()


def inject_snippet(
    target: Path, start_marker: str, end_marker: str, content: str, skip_if_missing: bool = False
) -> bool:
    """Inject snippet between markers. Returns True if injection happened, False if skipped."""
    text = target.read_text(encoding="utf-8")
    start = text.find(start_marker)
    end = text.find(end_marker)
    if start == -1 or end == -1:
        if skip_if_missing:
            return False
        raise RuntimeError(f"{target} markers not found.")
    if start > end:
        raise RuntimeError(f"{target} markers are misordered.")
    new_text = text[: start + len(start_marker)].rstrip() + "\n\n" + content + "\n" + text[end:]
    target.write_text(new_text, encoding="utf-8")
    return True


def snippet_present(target: Path, marker_start: str, marker_end: str, content: str) -> bool:
    text = target.read_text(encoding="utf-8")
    start = text.find(marker_start)
    end = text.find(marker_end)
    if start == -1 or end == -1 or start > end:
        return False
    current = text[start + len(marker_start) : end].strip()
    return current == content.strip()


def run_update() -> None:
    data = parse_simple_yaml(STATUS_YAML)
    snippet_ru = render_snippet(data, "ru")
    snippet_de = render_snippet(data, "de")

    write_snippet(SNIPPET_MD, snippet_ru)

    # Create DE directory if it doesn't exist
    SNIPPET_DE_MD.parent.mkdir(parents=True, exist_ok=True)
    write_snippet(SNIPPET_DE_MD, snippet_de)

    inject_snippet(README_FILE, MARKER_START, MARKER_END, snippet_ru)
    if DOC_INDEX_FILE.exists():
        inject_snippet(DOC_INDEX_FILE, MARKER_START, MARKER_END, snippet_ru)
    if DOC_OVERVIEW_FILE.exists():
        inject_snippet(DOC_OVERVIEW_FILE, MARKER_START, MARKER_END, snippet_ru)
    if DE_INDEX_FILE.exists():
        inject_snippet(
            DE_INDEX_FILE, DE_MARKER_START, DE_MARKER_END, snippet_de, skip_if_missing=True
        )
    run_prettier(
        [
            SNIPPET_MD.relative_to(REPO_ROOT).as_posix(),
            SNIPPET_DE_MD.relative_to(REPO_ROOT).as_posix(),
            README_FILE.relative_to(REPO_ROOT).as_posix(),
            DOC_INDEX_FILE.relative_to(REPO_ROOT).as_posix(),
            DOC_OVERVIEW_FILE.relative_to(REPO_ROOT).as_posix(),
            DE_INDEX_FILE.relative_to(REPO_ROOT).as_posix(),
        ]
    )
    print("Status snippets updated from docs/reference/status.yml")


def run_check() -> None:
    data = parse_simple_yaml(STATUS_YAML)
    snippet_ru = prettier_format(render_snippet(data, "ru"), SNIPPET_MD)
    snippet_de = prettier_format(render_snippet(data, "de"), SNIPPET_DE_MD)

    errors = []
    if SNIPPET_MD.read_text(encoding="utf-8").strip() != snippet_ru:
        errors.append("docs/reference/status-snippet.md is out of date.")
    if SNIPPET_DE_MD.exists() and SNIPPET_DE_MD.read_text(encoding="utf-8").strip() != snippet_de:
        errors.append("docs/de/status-snippet.md is out of date.")

    if errors:
        print("Status snippet validation failed:", file=sys.stderr)
        for err in errors:
            print(f"- {err}", file=sys.stderr)
        sys.exit(1)
    print("Status snippets are up to date.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Update or validate ERNI-KI status snippets.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate snippets instead of updating them.",
    )
    args = parser.parse_args()

    if args.check:
        run_check()
    else:
        run_update()


if __name__ == "__main__":
    main()
