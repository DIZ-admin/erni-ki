#!/usr/bin/env python3
"""Remove all emoji from project files."""

import re
import sys
from pathlib import Path

# Comprehensive emoji regex pattern
EMOJI_PATTERN = re.compile(
    "["
    "\U0001f600-\U0001f64f"  # emoticons
    "\U0001f300-\U0001f5ff"  # symbols & pictographs
    "\U0001f680-\U0001f6ff"  # transport & map symbols
    "\U0001f1e0-\U0001f1ff"  # flags (iOS)
    "\U00002702-\U000027b0"  # dingbats
    "\U000024c2-\U0001f251"
    "\U0001f900-\U0001f9ff"  # supplemental symbols
    "\U0001f018-\U0001f270"
    "]+",
    flags=re.UNICODE,
)

# Common text emoji and their replacements
TEXT_EMOJI_REPLACEMENTS = [
    (r"⭐+", ""),  # Stars
    (r"✅", "[OK]"),  # Checkmarks
    (r"❌", "[ERROR]"),  # X marks
    (r"⚠️", "[WARNING]"),  # Warning
    (r"🔴", "[CRITICAL]"),  # Red circle
    (r"🟡", "[WARNING]"),  # Yellow circle
    (r"🟢", "[OK]"),  # Green circle
    (r"ℹ️", "[INFO]"),  # Info
    (r"💡", "[TIP]"),  # Lightbulb
    (r"🚨", "[ALERT]"),  # Alert
    (r"📋", ""),  # Clipboard
    (r"🔧", ""),  # Wrench
    (r"🛠️", ""),  # Tools
    (r"🎯", ""),  # Target
    (r"📊", ""),  # Chart
    (r"📈", ""),  # Graph
    (r"🏗️", ""),  # Building
    (r"🗄️", ""),  # File cabinet
    (r"💾", ""),  # Floppy disk
    (r"📚", ""),  # Books
    (r"📝", ""),  # Memo
    (r"🔍", ""),  # Magnifying glass
    (r"🌐", ""),  # Globe
    (r"🔐", ""),  # Lock with key
    (r"🚪", ""),  # Door
    (r"🇬🇧", "EN"),  # UK flag
    (r"🇩🇪", "DE"),  # German flag
    (r"🇷🇺", "RU"),  # Russian flag
    (r"👉", ""),  # Pointing finger
    (r"💪", ""),  # Flexed biceps
    (r"🎉", ""),  # Party popper
    (r"🚀", ""),  # Rocket
    (r"⚡", ""),  # Lightning
    (r"🔥", ""),  # Fire
    (r"💰", ""),  # Money bag
    (r"📦", ""),  # Package
    (r"🐳", ""),  # Whale (docker)
    (r"🐍", ""),  # Snake (python)
]

EXCLUDE_DIRS = {".git", "node_modules", ".venv", "site", "coverage", "__pycache__", "dist", "build"}


def clean_emoji_from_text(text: str) -> tuple[str, int]:
    """Remove all emoji from text and return cleaned text + count."""
    emoji_count = 0

    # Remove Unicode emoji and count substitutions in a single pass
    cleaned, unicode_count = EMOJI_PATTERN.subn("", text)
    emoji_count += unicode_count

    # Replace text emoji - use subn() for efficiency (single pass per pattern)
    for pattern, replacement in TEXT_EMOJI_REPLACEMENTS:
        cleaned, count = re.subn(pattern, replacement, cleaned)
        emoji_count += count

    # Clean up multiple spaces and empty lines
    cleaned = re.sub(r" +", " ", cleaned)
    cleaned = re.sub(r"\n\n\n+", "\n\n", cleaned)

    return cleaned, emoji_count


def process_file(file_path: Path, dry_run: bool = False) -> tuple[bool, int]:
    """Process a single file and remove emoji."""
    try:
        content = file_path.read_text(encoding="utf-8")
        cleaned_content, emoji_count = clean_emoji_from_text(content)

        if emoji_count > 0 and not dry_run:
            file_path.write_text(cleaned_content, encoding="utf-8")
            return True, emoji_count

        return emoji_count > 0, emoji_count
    except Exception as e:
        print(f"Error processing {file_path}: {e}", file=sys.stderr)
        return False, 0


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("DRY RUN MODE - No files will be modified\n")

    # Find all markdown files
    files_to_process = []
    for path in Path(".").rglob("*.md"):
        if any(excl in path.parts for excl in EXCLUDE_DIRS):
            continue
        files_to_process.append(path)

    print(f"Found {len(files_to_process)} markdown files to scan\n")

    # Process files
    total_emoji_removed = 0
    files_modified = []

    for file_path in files_to_process:
        modified, emoji_count = process_file(file_path, dry_run)
        if modified:
            files_modified.append((str(file_path), emoji_count))
            total_emoji_removed += emoji_count

    # Report results
    print("\n" + "=" * 70)
    print("EMOJI REMOVAL REPORT")
    print("=" * 70)
    print(f"\nTotal files scanned:     {len(files_to_process)}")
    print(f"Files with emoji:        {len(files_modified)}")
    print(f"Total emoji removed:     {total_emoji_removed}")

    if files_modified:
        print(f"\nFiles modified ({len(files_modified)}):")
        for file_path, count in sorted(files_modified, key=lambda x: x[1], reverse=True)[:50]:
            print(f"  {count:4d} emoji - {file_path}")

        if len(files_modified) > 50:
            print(f"  ... and {len(files_modified) - 50} more files")

    if dry_run:
        print("\nDRY RUN COMPLETE - No files were modified")
        print("Run without --dry-run to apply changes")
    else:
        print("\nEmoji removal complete!")

    return 0 if not dry_run else (1 if files_modified else 0)


if __name__ == "__main__":
    sys.exit(main())
# ruff: noqa: N999
