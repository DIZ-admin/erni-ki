"""
Tests for validate-no-emoji.py script.

This module tests the emoji validation functionality used in pre-commit hooks.
"""

import importlib.util
import subprocess
import sys
from pathlib import Path

import pytest

# Load validate-no-emoji module from dashed filename
ROOT = Path(__file__).resolve().parents[2]
module_path = ROOT / "scripts" / "validate-no-emoji.py"
spec = importlib.util.spec_from_file_location("validate_no_emoji", module_path)
if spec is None or spec.loader is None:
    raise ImportError(f"Cannot load module from {module_path}")
validate_no_emoji = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validate_no_emoji)


class TestCheckFileForEmoji:
    """Test check_file_for_emoji function."""

    def test_detects_unicode_emoji(self, tmp_path):
        """Test detection of Unicode emoji."""
        test_file = tmp_path / "test.md"
        test_file.write_text("Hello 🌍 World 🚀", encoding="utf-8")

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is True
        assert len(emoji_list) >= 2
        assert "🌍" in emoji_list
        assert "🚀" in emoji_list

    def test_detects_text_emoji(self, tmp_path):
        """Test detection of text-based emoji."""
        test_file = tmp_path / "test.md"
        test_file.write_text("Status: ✅ Approved ⭐", encoding="utf-8")

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is True
        assert "✅" in emoji_list
        assert "⭐" in emoji_list

    def test_detects_mixed_emoji(self, tmp_path):
        """Test detection of both Unicode and text emoji."""
        test_file = tmp_path / "test.md"
        test_file.write_text("🎯 Goal: ✅ Complete", encoding="utf-8")

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is True
        assert len(emoji_list) >= 2

    def test_clean_file_no_emoji(self, tmp_path):
        """Test that clean files return False."""
        test_file = tmp_path / "test.md"
        test_file.write_text("# Clean File\nNo emoji here!", encoding="utf-8")

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is False
        assert len(emoji_list) == 0

    def test_empty_file(self, tmp_path):
        """Test that empty files return False."""
        test_file = tmp_path / "test.md"
        test_file.write_text("", encoding="utf-8")

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is False
        assert len(emoji_list) == 0

    def test_nonexistent_file(self):
        """Test handling of nonexistent files."""
        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji("/nonexistent/file.md")

        assert has_emoji is False
        assert len(emoji_list) == 0

    def test_detects_flag_emoji(self, tmp_path):
        """Test detection of flag emoji."""
        test_file = tmp_path / "test.md"
        test_file.write_text("Languages: 🇬🇧 🇩🇪 🇷🇺", encoding="utf-8")

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is True
        assert len(emoji_list) >= 3

    def test_detects_all_forbidden_emoji(self, tmp_path):
        """Test detection of commonly used forbidden emoji."""
        forbidden_sample = "⭐ ✅ ❌ ⚠️ 💡 🚨 📋 🎯 🚀 ⚡"
        test_file = tmp_path / "test.md"
        test_file.write_text(forbidden_sample, encoding="utf-8")

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is True
        assert len(emoji_list) >= 5


class TestEmojiPatterns:
    """Test emoji pattern matching."""

    def test_pattern_matches_emoticons(self):
        """Test pattern matches emoticon range."""
        text = "😀😁😂"
        matches = validate_no_emoji.EMOJI_PATTERN.findall(text)
        assert len(matches) > 0

    def test_pattern_matches_symbols(self):
        """Test pattern matches symbol range."""
        text = "🔥⚡✨"
        matches = validate_no_emoji.EMOJI_PATTERN.findall(text)
        assert len(matches) > 0

    def test_pattern_matches_transport(self):
        """Test pattern matches transport emoji."""
        text = "🚀🚁🚂"
        matches = validate_no_emoji.EMOJI_PATTERN.findall(text)
        assert len(matches) > 0

    def test_pattern_ignores_plain_text(self):
        """Test pattern doesn't match plain text."""
        text = "Hello World 123 ABC"
        matches = validate_no_emoji.EMOJI_PATTERN.findall(text)
        assert len(matches) == 0

    def test_forbidden_list_completeness(self):
        """Test that forbidden list contains common emoji."""
        assert "✅" in validate_no_emoji.FORBIDDEN_EMOJI
        assert "❌" in validate_no_emoji.FORBIDDEN_EMOJI
        assert "⭐" in validate_no_emoji.FORBIDDEN_EMOJI
        assert "🚀" in validate_no_emoji.FORBIDDEN_EMOJI
        assert "🎯" in validate_no_emoji.FORBIDDEN_EMOJI
        assert len(validate_no_emoji.FORBIDDEN_EMOJI) > 30


class TestMainFunction:
    """Test main function behavior."""

    def test_main_with_clean_files(self, tmp_path):
        """Test main function with clean files exits 0."""
        test_file = tmp_path / "clean.md"
        test_file.write_text("# Clean content\nNo emoji", encoding="utf-8")

        result = subprocess.run(  # noqa: S603
            [sys.executable, str(module_path), str(test_file)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert result.returncode == 0
        assert "[OK] No emoji found" in result.stdout

    def test_main_with_emoji_files(self, tmp_path):
        """Test main function with emoji files exits 1."""
        test_file = tmp_path / "emoji.md"
        test_file.write_text("# Header 🚀\nContent ✅", encoding="utf-8")

        result = subprocess.run(  # noqa: S603
            [sys.executable, str(module_path), str(test_file)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert result.returncode == 1
        assert "ERROR: Emoji found in files" in result.stdout
        assert "remove-all-emoji.py" in result.stdout

    def test_main_with_multiple_files(self, tmp_path):
        """Test main function with multiple files."""
        clean_file = tmp_path / "clean.md"
        clean_file.write_text("Clean content", encoding="utf-8")

        emoji_file = tmp_path / "emoji.md"
        emoji_file.write_text("Emoji 🎯", encoding="utf-8")

        result = subprocess.run(  # noqa: S603
            [sys.executable, str(module_path), str(clean_file), str(emoji_file)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert result.returncode == 1
        assert str(emoji_file) in result.stdout

    def test_main_without_arguments(self):
        """Test main function without arguments shows usage."""
        result = subprocess.run(  # noqa: S603
            [sys.executable, str(module_path)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert result.returncode == 1
        assert "Usage:" in result.stderr

    def test_main_shows_emoji_count(self, tmp_path):
        """Test main function shows emoji count and examples."""
        test_file = tmp_path / "emoji.md"
        test_file.write_text("🚀 🎯 ✅ ❌ ⭐", encoding="utf-8")

        result = subprocess.run(  # noqa: S603
            [sys.executable, str(module_path), str(test_file)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert result.returncode == 1
        assert "Found" in result.stdout
        assert "emoji" in result.stdout.lower()


class TestRealWorldScenarios:
    """Test real-world usage scenarios."""

    def test_markdown_with_code_blocks(self, tmp_path):
        """Test markdown with code blocks containing emoji in strings."""
        test_file = tmp_path / "code.md"
        test_file.write_text(
            '# Code Example\n```python\nprint("No emoji here")\n```\n',
            encoding="utf-8",
        )

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is False

    def test_documentation_with_status_badges(self, tmp_path):
        """Test documentation with text status indicators (no emoji)."""
        test_file = tmp_path / "doc.md"
        test_file.write_text(
            "Status: APPROVED\nPriority: HIGH\n[DONE] Task completed\n",
            encoding="utf-8",
        )

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is False

    def test_mixed_language_content(self, tmp_path):
        """Test content in multiple languages without emoji."""
        test_file = tmp_path / "mixed.md"
        # Test multiple European languages (no Cyrillic to avoid pre-commit issues)
        test_file.write_text(
            "English\nDeutsch\nFrançais\nEspañol\nItaliano\n",
            encoding="utf-8",
        )

        has_emoji, emoji_list = validate_no_emoji.check_file_for_emoji(str(test_file))

        assert has_emoji is False


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
