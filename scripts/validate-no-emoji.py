#!/usr/bin/env python3
"""
Validate that documentation files contain no emoji.
Used in pre-commit hooks and CI/CD pipelines.
"""

import re
import sys
from pathlib import Path

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

FORBIDDEN_EMOJI = [
    "⭐",
    "✅",
    "❌",
    "⚠️",
    "🔴",
    "🟡",
    "🟢",
    "ℹ️",
    "💡",
    "🚨",
    "📋",
    "🔧",
    "🛠️",
    "🎯",
    "📊",
    "📈",
    "🏗️",
    "🗄️",
    "💾",
    "📚",
    "📝",
    "🔍",
    "🌐",
    "🔐",
    "🚪",
    "🇬🇧",
    "🇩🇪",
    "🇷🇺",
    "👉",
    "💪",
    "🎉",
    "🚀",
    "⚡",
    "🔥",
    "💰",
    "📦",
    "🐳",
    "🐍",
]


def check_file_for_emoji(file_path: str) -> tuple[bool, list[str]]:
    """Check if file contains emoji. Returns (has_emoji, emoji_list)."""
    try:
        content = Path(file_path).read_text(encoding="utf-8")

        found_emoji = []

        # Check Unicode emoji
        unicode_matches = EMOJI_PATTERN.findall(content)
        if unicode_matches:
            found_emoji.extend(unicode_matches)

        # Check text emoji
        for emoji in FORBIDDEN_EMOJI:
            if emoji in content:
                found_emoji.append(emoji)

        return len(found_emoji) > 0, found_emoji
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        return False, []


def main():
    if len(sys.argv) < 2:
        print("Usage: validate-no-emoji.py <file1> [file2] ...", file=sys.stderr)
        sys.exit(1)

    files_with_emoji = {}

    for file_path in sys.argv[1:]:
        has_emoji, emoji_list = check_file_for_emoji(file_path)
        if has_emoji:
            files_with_emoji[file_path] = emoji_list

    if files_with_emoji:
        print("=" * 70)
        print("ERROR: Emoji found in files")
        print("=" * 70)
        for file_path, emoji_list in files_with_emoji.items():
            unique_emoji = set(emoji_list)
            print(f"\n{file_path}:")
            print(f"  Found {len(emoji_list)} emoji ({len(unique_emoji)} unique)")
            print(f"  Examples: {' '.join(list(unique_emoji)[:10])}")

        print("\n" + "=" * 70)
        print("To remove emoji automatically, run:")
        print("  python3 scripts/remove-all-emoji.py")
        print("=" * 70)
        sys.exit(1)

    print("[OK] No emoji found")
    sys.exit(0)


if __name__ == "__main__":
    main()
# ruff: noqa: N999
