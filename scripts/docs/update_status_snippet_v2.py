#!/usr/bin/env python3
"""
ERNI-KI Status Snippet Updater (Refactored)

Sync or validate ERNI-KI status snippets across README, docs and locales.
Source of truth: docs/reference/status.yml

Usage:
    ./update_status_snippet_v2.py           # Update snippets
    ./update_status_snippet_v2.py --check   # Validate only
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

# Import logging library
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib.logger import get_logger

logger = get_logger(__name__)

# =============================================================================
# Constants
# =============================================================================

REPO_ROOT = Path(__file__).resolve().parents[2]
STATUS_YAML = REPO_ROOT / "docs/reference/status.yml"
SNIPPET_MD = REPO_ROOT / "docs/reference/status-snippet.md"
SNIPPET_DE_MD = REPO_ROOT / "docs/de/reference/status-snippet.md"
README_FILE = REPO_ROOT / "README.md"
DOC_INDEX_FILE = REPO_ROOT / "docs/index.md"
DOC_OVERVIEW_FILE = REPO_ROOT / "docs/overview.md"
DE_INDEX_FILE = REPO_ROOT / "docs/de/index.md"

MARKER_START = "<!-- STATUS_SNIPPET_START -->"
MARKER_END = "<!-- STATUS_SNIPPET_END -->"
DE_MARKER_START = "<!-- STATUS_SNIPPET_DE_START -->"
DE_MARKER_END = "<!-- STATUS_SNIPPET_DE_END -->"

LOCALE_STRINGS_FILE = REPO_ROOT / "docs/reference/status-snippet-locales.json"

# =============================================================================
# Helper Functions
# =============================================================================


def load_locale_strings() -> dict[str, dict[str, str]]:
    """Load locale strings from JSON file."""
    if not LOCALE_STRINGS_FILE.exists():
        logger.warning("Locale strings file not found: %s", LOCALE_STRINGS_FILE)
        return {}

    try:
        content = LOCALE_STRINGS_FILE.read_text(encoding="utf-8")
        return json.loads(content)
    except json.JSONDecodeError as exc:
        logger.error("Failed to parse locale strings: %s", exc)
        return {}


def parse_simple_yaml(path: Path) -> dict[str, str]:
    """
    Parse simple flat YAML file (key: value format).

    Args:
        path: Path to YAML file

    Returns:
        Dictionary of key-value pairs
    """
    if not path.exists():
        logger.error("YAML file not found: %s", path)
        raise FileNotFoundError(f"YAML file not found: {path}")

    data: dict[str, str] = {}

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()

        # Skip empty lines and comments
        if not line or line.startswith("#"):
            continue

        # Skip lines without colon
        if ":" not in line:
            logger.debug("Skipping invalid line: %s", line)
            continue

        # Split on first colon
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"').strip("'")

    logger.debug("Parsed %d keys from %s", len(data), path.name)
    return data


def render_snippet(data: dict[str, str], locale: str = "ru") -> str:
    """
    Build Markdown snippet using locale-specific labels.

    Args:
        data: Status data dictionary
        locale: Locale code (ru, de, en)

    Returns:
        Formatted Markdown snippet
    """
    locale_strings = load_locale_strings()
    labels = locale_strings.get(locale, locale_strings.get("ru", {}))

    # Build header
    header_label = labels.get("header", "System Status")
    date = data.get("date", "n/a")
    release = data.get("release", "")
    header = f"> **{header_label} ({date}) — {release}**"

    # Build lines
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

    # Add notes if present
    note = data.get("notes")
    if note:
        note_label = labels.get("note", "Note")
        lines.append(f"> - {note_label}: {note}")

    snippet = "\n".join(lines) + "\n"
    logger.debug("Generated snippet for locale '%s': %d lines", locale, len(lines))
    return snippet


def write_snippet(path: Path, content: str) -> None:
    """Write snippet to file."""
    logger.info("Writing snippet to: %s", path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def run_prettier(paths: list[str]) -> None:
    """
    Run prettier on specified paths.

    Args:
        paths: List of file paths to format
    """
    try:
        logger.info("Running prettier on %d files", len(paths))
        subprocess.run(
            ["npx", "prettier", "--write", *paths],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
            timeout=30,
        )
        logger.info("Prettier formatting completed")
    except FileNotFoundError:
        logger.warning("npx not found; skipping prettier formatting")
    except subprocess.TimeoutExpired:
        logger.error("Prettier timed out after 30 seconds")
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.decode("utf-8") if exc.stderr else "unknown error"
        logger.error("Prettier failed: %s", stderr)


def prettier_format(text: str, filepath: Path) -> str:
    """
    Format text using prettier.

    Args:
        text: Text to format
        filepath: Original file path (for parser detection)

    Returns:
        Formatted text
    """
    rel_path = filepath.relative_to(REPO_ROOT).as_posix()

    try:
        proc = subprocess.run(
            ["npx", "prettier", "--parser", "markdown", "--stdin-filepath", rel_path],
            cwd=REPO_ROOT,
            input=text.encode("utf-8"),
            check=True,
            capture_output=True,
            timeout=10,
        )
        return proc.stdout.decode("utf-8").strip()
    except (FileNotFoundError, subprocess.TimeoutExpired, subprocess.CalledProcessError):
        logger.debug("Prettier formatting failed, returning original text")
        return text.strip()


def inject_snippet(
    target: Path,
    start_marker: str,
    end_marker: str,
    content: str,
    skip_if_missing: bool = False,
) -> bool:
    """
    Inject snippet between markers in target file.

    Args:
        target: Target file path
        start_marker: Start marker string
        end_marker: End marker string
        content: Content to inject
        skip_if_missing: Skip if markers not found (don't raise error)

    Returns:
        True if injection happened, False if skipped

    Raises:
        RuntimeError: If markers not found or misordered (and not skipping)
    """
    if not target.exists():
        if skip_if_missing:
            logger.debug("Target file does not exist, skipping: %s", target)
            return False
        raise FileNotFoundError(f"Target file not found: {target}")

    text = target.read_text(encoding="utf-8")
    start_pos = text.find(start_marker)
    end_pos = text.find(end_marker)

    if start_pos == -1 or end_pos == -1:
        if skip_if_missing:
            logger.debug("Markers not found in %s, skipping", target)
            return False
        raise RuntimeError(f"Markers not found in {target}")

    if start_pos > end_pos:
        raise RuntimeError(f"Markers are misordered in {target}")

    # Inject content
    new_text = (
        text[: start_pos + len(start_marker)].rstrip() + "\n\n" + content + "\n" + text[end_pos:]
    )

    target.write_text(new_text, encoding="utf-8")
    logger.info("Injected snippet into: %s", target)
    return True


def snippet_present(target: Path, marker_start: str, marker_end: str, content: str) -> bool:
    """
    Check if snippet is already present and correct in target file.

    Args:
        target: Target file path
        marker_start: Start marker
        marker_end: End marker
        content: Expected content

    Returns:
        True if snippet matches, False otherwise
    """
    if not target.exists():
        return False

    text = target.read_text(encoding="utf-8")
    start_pos = text.find(marker_start)
    end_pos = text.find(marker_end)

    if start_pos == -1 or end_pos == -1 or start_pos > end_pos:
        return False

    current = text[start_pos + len(marker_start) : end_pos].strip()
    return current == content.strip()


# =============================================================================
# Main Operations
# =============================================================================


def run_update() -> None:
    """Update all status snippets from source YAML."""
    logger.info("Starting status snippet update")

    # Parse source data
    data = parse_simple_yaml(STATUS_YAML)
    logger.info("Loaded status data: date=%s, release=%s", data.get("date"), data.get("release"))

    # Render snippets for different locales
    snippet_ru = render_snippet(data, "ru")
    snippet_de = render_snippet(data, "de")

    # Write snippet files
    write_snippet(SNIPPET_MD, snippet_ru)
    SNIPPET_DE_MD.parent.mkdir(parents=True, exist_ok=True)
    write_snippet(SNIPPET_DE_MD, snippet_de)

    # Inject into documentation files
    files_updated = 0

    if inject_snippet(README_FILE, MARKER_START, MARKER_END, snippet_ru):
        files_updated += 1

    if DOC_INDEX_FILE.exists() and inject_snippet(
        DOC_INDEX_FILE, MARKER_START, MARKER_END, snippet_ru
    ):
        files_updated += 1

    if DOC_OVERVIEW_FILE.exists() and inject_snippet(
        DOC_OVERVIEW_FILE, MARKER_START, MARKER_END, snippet_ru
    ):
        files_updated += 1

    if DE_INDEX_FILE.exists() and inject_snippet(
        DE_INDEX_FILE, DE_MARKER_START, DE_MARKER_END, snippet_de, skip_if_missing=True
    ):
        files_updated += 1

    logger.info("Updated %d documentation files", files_updated)

    # Run prettier
    files_to_format = [
        SNIPPET_MD.relative_to(REPO_ROOT).as_posix(),
        SNIPPET_DE_MD.relative_to(REPO_ROOT).as_posix(),
        README_FILE.relative_to(REPO_ROOT).as_posix(),
    ]

    if DOC_INDEX_FILE.exists():
        files_to_format.append(DOC_INDEX_FILE.relative_to(REPO_ROOT).as_posix())
    if DOC_OVERVIEW_FILE.exists():
        files_to_format.append(DOC_OVERVIEW_FILE.relative_to(REPO_ROOT).as_posix())
    if DE_INDEX_FILE.exists():
        files_to_format.append(DE_INDEX_FILE.relative_to(REPO_ROOT).as_posix())

    run_prettier(files_to_format)

    logger.info("Status snippet update completed successfully")


def run_check() -> None:
    """Validate that snippets are up to date."""
    logger.info("Starting status snippet validation")

    # Parse source data
    data = parse_simple_yaml(STATUS_YAML)

    # Render expected snippets
    snippet_ru = prettier_format(render_snippet(data, "ru"), SNIPPET_MD)
    snippet_de = prettier_format(render_snippet(data, "de"), SNIPPET_DE_MD)

    # Check snippet files
    errors = []

    if SNIPPET_MD.read_text(encoding="utf-8").strip() != snippet_ru:
        errors.append("docs/reference/status-snippet.md is out of date")
        logger.error(errors[-1])

    if SNIPPET_DE_MD.exists() and SNIPPET_DE_MD.read_text(encoding="utf-8").strip() != snippet_de:
        errors.append("docs/de/reference/status-snippet.md is out of date")
        logger.error(errors[-1])

    if errors:
        logger.error("Validation failed: %d errors found", len(errors))
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        sys.exit(1)

    logger.info("Status snippets are up to date")


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Update or validate ERNI-KI status snippets.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate snippets instead of updating them",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging",
    )

    args = parser.parse_args()

    # Set debug mode
    if args.debug:
        logger.setLevel("DEBUG")

    try:
        if args.check:
            run_check()
        else:
            run_update()
    except Exception:
        logger.exception("Fatal error occurred")
        sys.exit(1)


if __name__ == "__main__":
    main()
