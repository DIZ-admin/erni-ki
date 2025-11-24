#!/usr/bin/env python3
"""
Fix deprecated metadata fields in documentation files.

This script replaces deprecated fields according to metadata-standards.md:
- 'status' → 'system_status'
- 'version' → 'system_version'

Usage:
    python3 scripts/fix-deprecated-metadata.py [--dry-run] [--verbose]
"""

import argparse
import re
import sys
from pathlib import Path


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Fix deprecated metadata in docs")
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would be changed without modifying files"
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output")
    parser.add_argument(
        "--path", default="docs", help="Path to documentation directory (default: docs)"
    )
    return parser.parse_args()


def fix_frontmatter(content: str, filepath: str, verbose: bool = False) -> tuple[str, list[str]]:
    """
    Fix deprecated fields in YAML frontmatter.

    Returns: (updated_content, list_of_changes)
    """
    changes = []

    # Match YAML frontmatter
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not match:
        return content, changes

    frontmatter = match.group(1)
    new_frontmatter = frontmatter

    # Replace 'status:' with 'system_status:'
    # Only replace if it's not 'translation_status'
    status_pattern = r"^(\s*)(?<!translation_)status:\s*(.+)$"
    if re.search(status_pattern, frontmatter, re.MULTILINE):
        new_frontmatter = re.sub(
            status_pattern, r"\1system_status: \2", new_frontmatter, flags=re.MULTILINE
        )
        changes.append("status → system_status")

    # Replace 'version:' with 'system_version:'
    # Only replace if it's not 'doc_version'
    version_pattern = r"^(\s*)(?<!doc_)version:\s*(.+)$"
    if re.search(version_pattern, frontmatter, re.MULTILINE):
        new_frontmatter = re.sub(
            version_pattern, r"\1system_version: \2", new_frontmatter, flags=re.MULTILINE
        )
        changes.append("version → system_version")

    if changes:
        # Reconstruct content with updated frontmatter
        body = content[match.end() :]
        new_content = f"---\n{new_frontmatter}\n---\n{body}"
        return new_content, changes

    return content, changes


def process_file(filepath: Path, dry_run: bool = False, verbose: bool = False) -> bool:
    """
    Process a single markdown file.

    Returns: True if file was modified, False otherwise
    """
    try:
        content = filepath.read_text(encoding="utf-8")
        new_content, changes = fix_frontmatter(content, str(filepath), verbose)

        if changes:
            try:
                rel_path = filepath.relative_to(Path.cwd())
            except ValueError:
                rel_path = filepath
            print(f"{'[DRY RUN] ' if dry_run else ''}📝 {rel_path}")
            for change in changes:
                print(f"  ✓ {change}")

            if not dry_run:
                filepath.write_text(new_content, encoding="utf-8")

            return True
        elif verbose:
            try:
                rel_path = filepath.relative_to(Path.cwd())
            except ValueError:
                rel_path = filepath
            print(f"⏭️  {rel_path} - no deprecated fields")

        return False

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
    print("🔧 Fixing deprecated metadata fields")
    print("=" * 70)
    print(f"Path: {docs_root}")
    print(f"Mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print()

    if args.dry_run:
        print("⚠️  DRY RUN MODE - No files will be modified")
        print()

    # Find all markdown files (excluding archive)
    md_files = []
    for md_file in docs_root.rglob("*.md"):
        # Skip archive directory in dry run check
        if "archive" not in md_file.parts or not args.dry_run:
            md_files.append(md_file)

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
    print(f"  Files unchanged: {len(md_files) - modified_count}")

    if args.dry_run:
        print()
        print("ℹ️  Run without --dry-run to apply changes")
    else:
        print()
        print("✅ Done! Files have been updated.")
        print("   Don't forget to:")
        print("   1. Review changes: git diff")
        print("   2. Test: python3 scripts/validate-docs-metadata.py")
        print("   3. Commit: git commit -am 'docs: fix deprecated metadata fields'")

    print("=" * 70)


if __name__ == "__main__":
    main()
