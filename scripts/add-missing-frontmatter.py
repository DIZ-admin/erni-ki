#!/usr/bin/env python3
"""
Add missing frontmatter to documentation files.

This script adds minimal required frontmatter to files that don't have any.

Usage:
    python3 scripts/add-missing-frontmatter.py [--dry-run] [--verbose]
"""

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Add missing frontmatter to docs")
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would be changed without modifying files"
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output")
    parser.add_argument(
        "--path", default="docs", help="Path to documentation directory (default: docs)"
    )
    return parser.parse_args()


def detect_language(filepath: Path) -> str:
    """Detect language from file path."""
    parts = filepath.parts
    if "de" in parts:
        return "de"
    elif "en" in parts:
        return "en"
    return "ru"


def has_frontmatter(content: str) -> bool:
    """Check if content has YAML frontmatter."""
    return bool(re.match(r"^---\s*\n.*?\n---\s*\n", content, re.DOTALL))


def create_frontmatter(filepath: Path) -> str:
    """Create minimal frontmatter for a file."""
    language = detect_language(filepath)
    today = datetime.now().strftime("%Y-%m-%d")

    # Determine translation status
    translation_status = "complete" if language == "ru" else "pending"

    frontmatter = f"""---
language: {language}
translation_status: {translation_status}
doc_version: '2025.11'
last_updated: '{today}'
---

"""
    return frontmatter


def process_file(filepath: Path, dry_run: bool = False, verbose: bool = False) -> bool:
    """
    Process a single markdown file.

    Returns: True if file was modified, False otherwise
    """
    try:
        content = filepath.read_text(encoding="utf-8")

        if has_frontmatter(content):
            if verbose:
                try:
                    rel_path = filepath.relative_to(Path.cwd())
                except ValueError:
                    rel_path = filepath
                print(f"⏭️  {rel_path} - already has frontmatter")
            return False

        # Add frontmatter
        frontmatter = create_frontmatter(filepath)
        new_content = frontmatter + content

        try:
            rel_path = filepath.relative_to(Path.cwd())
        except ValueError:
            rel_path = filepath
        print(f"{'[DRY RUN] ' if dry_run else ''}📝 {rel_path}")
        print(f"  ✓ Adding frontmatter (language: {detect_language(filepath)})")

        if not dry_run:
            filepath.write_text(new_content, encoding="utf-8")

        return True

    except Exception as e:
        print(f"❌ Error processing {filepath}: {e}", file=sys.stderr)
        return False


def main():
    """Main entry point."""
    args = parse_args()

    docs_root = Path(args.path)
    if not docs_root.exists():
        print(f"❌ Documentation directory not found: {docs_root}", file=sys.stderr)
        sys.exit(1)

    print("=" * 70)
    print("📄 Adding missing frontmatter")
    print("=" * 70)
    print(f"Path: {docs_root}")
    print(f"Mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print()

    if args.dry_run:
        print("⚠️  DRY RUN MODE - No files will be modified")
        print()

    # Find all markdown files without frontmatter
    md_files = list(docs_root.rglob("*.md"))

    print(f"Found {len(md_files)} markdown files")
    print()

    # Process files
    modified_count = 0
    for md_file in sorted(md_files):
        if process_file(md_file, args.dry_run, args.verbose):
            modified_count += 1

    # Summary
    print()
    print("=" * 70)
    print(f"{'[DRY RUN] ' if args.dry_run else ''}Summary:")
    print(f"  Files processed: {len(md_files)}")
    print(f"  Files modified: {modified_count}")
    print(f"  Files with existing frontmatter: {len(md_files) - modified_count}")

    if args.dry_run:
        print()
        print("ℹ️  Run without --dry-run to apply changes")
    else:
        print()
        print("✅ Done! Frontmatter has been added.")
        print("   Don't forget to:")
        print("   1. Review changes: git diff")
        print("   2. Update translation_status if needed")
        print("   3. Test: python3 scripts/validate-docs-metadata.py")
        print("   4. Commit: git commit -am 'docs: add missing frontmatter'")

    print("=" * 70)


if __name__ == "__main__":
    main()
# ruff: noqa: N999
