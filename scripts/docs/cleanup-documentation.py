#!/usr/bin/env python3
"""
ERNI-KI Documentation Cleanup and Reorganization

Cleans up documentation by:
- Removing empty/duplicate directories
- Archiving backup files
- Validating frontmatter
- Removing broken links
- Standardizing structure

Usage:
    ./cleanup-documentation.py [--dry-run] [--verbose]
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path
from typing import Any

# Import logging
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib.logger import get_logger

logger = get_logger(__name__)

# =============================================================================
# Constants
# =============================================================================

REPO_ROOT = Path(__file__).resolve().parents[2]
DOCS_DIR = REPO_ROOT / "docs"
ARCHIVE_DIR = DOCS_DIR / "archive" / "cleanup"

# Patterns to detect
DUPLICATE_DIR_PATTERNS = [
    r" 2$",  # Directory ending with " 2"
    r" copy$",
    r"_old$",
    r"_backup$",
]

BACKUP_FILE_PATTERNS = [
    r".*-backup\.md$",
    r".*-copy\.md$",
    r".*-old\.md$",
    r".*\.bak\.md$",
    r".*2\.md$",  # filename2.md
]

REQUIRED_FRONTMATTER_FIELDS = ["language", "doc_version"]

# =============================================================================
# Statistics
# =============================================================================


class CleanupStats:
    """Track cleanup statistics."""

    def __init__(self):
        self.empty_dirs_removed = 0
        self.duplicate_dirs_removed = 0
        self.backup_files_archived = 0
        self.invalid_frontmatter = 0
        self.broken_links = 0
        self.total_files = 0
        self.total_dirs = 0

    def report(self) -> str:
        """Generate cleanup report."""
        lines = [
            "# Documentation Cleanup Report",
            "",
            f"**Total Files Scanned:** {self.total_files}",
            f"**Total Directories Scanned:** {self.total_dirs}",
            "",
            "## Actions Taken:",
            "",
            f"- Empty Directories Removed: {self.empty_dirs_removed}",
            f"- Duplicate Directories Removed: {self.duplicate_dirs_removed}",
            f"- Backup Files Archived: {self.backup_files_archived}",
            f"- Invalid Frontmatter Issues: {self.invalid_frontmatter}",
            f"- Broken Links Found: {self.broken_links}",
        ]
        return "\n".join(lines)


stats = CleanupStats()

# =============================================================================
# Helper Functions
# =============================================================================


def is_empty_directory(path: Path) -> bool:
    """Check if directory is empty or contains only hidden files."""
    if not path.is_dir():
        return False

    # List all items
    items = list(path.iterdir())

    # Empty if no items
    if not items:
        return True

    # Check if only hidden files
    visible_items = [item for item in items if not item.name.startswith(".")]
    return len(visible_items) == 0


def is_duplicate_directory(path: Path) -> bool:
    """Check if directory name matches duplicate patterns."""
    name = path.name
    return any(re.search(pattern, name) for pattern in DUPLICATE_DIR_PATTERNS)


def is_backup_file(path: Path) -> bool:
    """Check if file matches backup patterns."""
    name = path.name
    return any(re.search(pattern, name) for pattern in BACKUP_FILE_PATTERNS)


def parse_frontmatter(content: str) -> dict[str, Any] | None:
    """Parse YAML frontmatter from markdown content."""
    if not content.startswith("---"):
        return None

    parts = content.split("---", 2)
    if len(parts) < 3:
        return None

    frontmatter = {}
    for line in parts[1].strip().split("\n"):
        if ":" in line:
            key, value = line.split(":", 1)
            frontmatter[key.strip()] = value.strip().strip("'\"")

    return frontmatter


def validate_frontmatter(file_path: Path) -> list[str]:
    """
    Validate frontmatter in markdown file.

    Returns list of issues found.
    """
    issues = []

    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as exc:
        issues.append(f"Failed to read file: {exc}")
        return issues

    frontmatter = parse_frontmatter(content)

    if frontmatter is None:
        issues.append("Missing frontmatter")
        return issues

    # Check required fields
    for field in REQUIRED_FRONTMATTER_FIELDS:
        if field not in frontmatter:
            issues.append(f"Missing required field: {field}")

    # Validate language field
    if "language" in frontmatter:
        lang = frontmatter["language"]
        if lang not in ["ru", "en", "de"]:
            issues.append(f"Invalid language: {lang}")

    return issues


def find_broken_links(file_path: Path) -> list[str]:
    """
    Find broken internal links in markdown file.

    Returns list of broken links.
    """
    broken = []

    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception:
        return broken

    # Find markdown links [text](path)
    link_pattern = r"\[([^\]]+)\]\(([^)]+)\)"
    for match in re.finditer(link_pattern, content):
        link_text = match.group(1)
        link_path = match.group(2)

        # Skip external links
        if link_path.startswith("http://") or link_path.startswith("https://"):
            continue

        # Skip anchors only
        if link_path.startswith("#"):
            continue

        # Skip mailto links
        if link_path.startswith("mailto:"):
            continue

        # Remove anchor from path for file existence check
        clean_path = link_path.split("#")[0] if "#" in link_path else link_path

        # Skip empty paths
        if not clean_path:
            continue

        # Resolve relative path
        target = (file_path.parent / clean_path).resolve()

        # Check if target exists
        if not target.exists():
            broken.append(f"{link_text} -> {link_path}")

    return broken


# =============================================================================
# Cleanup Operations
# =============================================================================


def remove_empty_directories(dry_run: bool = False) -> None:
    """Remove empty directories."""
    logger.info("Scanning for empty directories...")

    empty_dirs = []

    for dirpath in DOCS_DIR.rglob("*"):
        if dirpath.is_dir() and is_empty_directory(dirpath):
            # Skip archive directory itself
            if dirpath == ARCHIVE_DIR or ARCHIVE_DIR in dirpath.parents:
                continue

            empty_dirs.append(dirpath)
            stats.empty_dirs_removed += 1

    if empty_dirs:
        logger.info("Found %d empty directories", len(empty_dirs))

        for directory in empty_dirs:
            rel_path = directory.relative_to(DOCS_DIR)
            logger.info("Removing empty directory: %s", rel_path)

            if not dry_run:
                shutil.rmtree(directory)
    else:
        logger.info("No empty directories found")


def remove_duplicate_directories(dry_run: bool = False) -> None:
    """Remove duplicate directories (e.g., 'name 2', 'name copy')."""
    logger.info("Scanning for duplicate directories...")

    duplicate_dirs = []

    for dirpath in DOCS_DIR.rglob("*"):
        if dirpath.is_dir() and is_duplicate_directory(dirpath):
            # Skip archive
            if dirpath == ARCHIVE_DIR or ARCHIVE_DIR in dirpath.parents:
                continue

            duplicate_dirs.append(dirpath)
            stats.duplicate_dirs_removed += 1

    if duplicate_dirs:
        logger.info("Found %d duplicate directories", len(duplicate_dirs))

        for directory in duplicate_dirs:
            rel_path = directory.relative_to(DOCS_DIR)
            logger.warning("Removing duplicate directory: %s", rel_path)

            if not dry_run:
                # Move to archive instead of deleting
                archive_path = ARCHIVE_DIR / rel_path
                archive_path.parent.mkdir(parents=True, exist_ok=True)

                shutil.move(str(directory), str(archive_path))
                logger.info("Archived to: %s", archive_path.relative_to(DOCS_DIR))
    else:
        logger.info("No duplicate directories found")


def archive_backup_files(dry_run: bool = False) -> None:
    """Archive backup files."""
    logger.info("Scanning for backup files...")

    backup_files = []

    for filepath in DOCS_DIR.rglob("*.md"):
        if is_backup_file(filepath):
            # Skip if already in archive
            if ARCHIVE_DIR in filepath.parents:
                continue

            backup_files.append(filepath)
            stats.backup_files_archived += 1

    if backup_files:
        logger.info("Found %d backup files", len(backup_files))

        for file_path in backup_files:
            rel_path = file_path.relative_to(DOCS_DIR)
            logger.warning("Archiving backup file: %s", rel_path)

            if not dry_run:
                archive_path = ARCHIVE_DIR / rel_path
                archive_path.parent.mkdir(parents=True, exist_ok=True)

                shutil.move(str(file_path), str(archive_path))
                logger.info("Archived to: %s", archive_path.relative_to(DOCS_DIR))
    else:
        logger.info("No backup files found")


def validate_all_frontmatter(dry_run: bool = False) -> None:
    """Validate frontmatter in all markdown files."""
    logger.info("Validating frontmatter...")

    issues_found = {}

    for filepath in DOCS_DIR.rglob("*.md"):
        stats.total_files += 1

        # Skip archive
        if ARCHIVE_DIR in filepath.parents:
            continue

        issues = validate_frontmatter(filepath)

        if issues:
            rel_path = filepath.relative_to(DOCS_DIR)
            issues_found[str(rel_path)] = issues
            stats.invalid_frontmatter += 1

    if issues_found:
        logger.warning("Found %d files with frontmatter issues", len(issues_found))

        for file_path, issues in list(issues_found.items())[:10]:
            logger.warning("  %s:", file_path)
            for issue in issues:
                logger.warning("    - %s", issue)

        if len(issues_found) > 10:
            logger.warning("  ... and %d more files", len(issues_found) - 10)
    else:
        logger.info("All frontmatter valid")


def check_broken_links(dry_run: bool = False) -> None:
    """Check for broken internal links."""
    logger.info("Checking for broken links...")

    broken_links_found = {}

    for filepath in DOCS_DIR.rglob("*.md"):
        # Skip archive
        if ARCHIVE_DIR in filepath.parents:
            continue

        broken = find_broken_links(filepath)

        if broken:
            rel_path = filepath.relative_to(DOCS_DIR)
            broken_links_found[str(rel_path)] = broken
            stats.broken_links += len(broken)

    if broken_links_found:
        logger.warning("Found broken links in %d files", len(broken_links_found))

        for file_path, links in list(broken_links_found.items())[:5]:
            logger.warning("  %s:", file_path)
            for link in links[:3]:
                logger.warning("    - %s", link)

        if len(broken_links_found) > 5:
            logger.warning("  ... and %d more files", len(broken_links_found) - 5)
    else:
        logger.info("No broken links found")


def count_directories() -> None:
    """Count total directories."""
    for dirpath in DOCS_DIR.rglob("*"):
        if dirpath.is_dir():
            stats.total_dirs += 1


# =============================================================================
# Main
# =============================================================================


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Clean up ERNI-KI documentation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )

    args = parser.parse_args()

    # Configure logging
    if args.verbose:
        logger.setLevel("DEBUG")

    # Log mode
    mode = "DRY RUN" if args.dry_run else "LIVE"
    logger.info("Starting documentation cleanup [%s]", mode)

    if args.dry_run:
        logger.warning("DRY RUN MODE: No changes will be made")

    # Create archive directory
    if not args.dry_run:
        ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

    # Run cleanup operations
    try:
        count_directories()
        remove_empty_directories(dry_run=args.dry_run)
        remove_duplicate_directories(dry_run=args.dry_run)
        archive_backup_files(dry_run=args.dry_run)
        validate_all_frontmatter(dry_run=args.dry_run)
        check_broken_links(dry_run=args.dry_run)

        # Generate report
        logger.info("Cleanup completed")
        print("\n" + "=" * 60)
        print(stats.report())
        print("=" * 60)

        if args.dry_run:
            logger.info("Run without --dry-run to apply changes")

    except Exception as exc:
        logger.exception("Fatal error occurred: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
# ruff: noqa: N999
