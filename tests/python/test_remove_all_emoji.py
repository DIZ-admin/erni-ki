"""Tests for scripts/remove-all-emoji.py."""

import importlib.util
import sys
from pathlib import Path

# Load remove-all-emoji module from dashed filename
ROOT = Path(__file__).resolve().parents[2]
module_path = ROOT / "scripts" / "remove-all-emoji.py"
spec = importlib.util.spec_from_file_location("remove_all_emoji", module_path)
if spec is None or spec.loader is None:
    raise ImportError(f"Cannot load remove-all-emoji from {module_path}")
remove_all_emoji = importlib.util.module_from_spec(spec)
sys.modules["remove_all_emoji"] = remove_all_emoji
spec.loader.exec_module(remove_all_emoji)


class TestCleanEmojiFromText:
    """Test clean_emoji_from_text function."""

    def test_removes_unicode_emoji(self):
        """Test removal of Unicode emoji."""
        text = "Hello 🌍 World 🚀"
        cleaned, count = remove_all_emoji.clean_emoji_from_text(text)
        assert "🌍" not in cleaned
        assert "🚀" not in cleaned
        assert count == 2
        assert "Hello" in cleaned
        assert "World" in cleaned

    def test_removes_checkmarks(self):
        """Test removal of checkmarks (removed by Unicode pattern first)."""
        text = "✅ Task complete"
        cleaned, count = remove_all_emoji.clean_emoji_from_text(text)
        assert "✅" not in cleaned
        assert count >= 1
        assert "Task complete" in cleaned

    def test_removes_error_marks(self):
        """Test removal of X marks (removed by Unicode pattern first)."""
        text = "❌ Task failed"
        cleaned, count = remove_all_emoji.clean_emoji_from_text(text)
        assert "❌" not in cleaned
        assert count >= 1
        assert "Task failed" in cleaned

    def test_removes_warning_emoji(self):
        """Test removal of warning emoji (removed by Unicode pattern first)."""
        text = "⚠️ Warning message"
        cleaned, count = remove_all_emoji.clean_emoji_from_text(text)
        assert "⚠" not in cleaned
        assert count >= 1
        assert "Warning message" in cleaned

    def test_removes_flags(self):
        """Test removal of country flags (removed by Unicode pattern first)."""
        text = "Languages: 🇬🇧 🇩🇪 🇷🇺"
        cleaned, count = remove_all_emoji.clean_emoji_from_text(text)
        assert "🇬🇧" not in cleaned
        assert "🇩🇪" not in cleaned
        assert "🇷🇺" not in cleaned
        assert count >= 2
        assert "Languages:" in cleaned

    def test_cleans_multiple_spaces(self):
        """Test cleaning of multiple spaces."""
        text = "Too    many     spaces"
        cleaned, _ = remove_all_emoji.clean_emoji_from_text(text)
        assert "    " not in cleaned
        assert "Too many spaces" in cleaned

    def test_cleans_multiple_newlines(self):
        """Test cleaning of multiple consecutive newlines."""
        text = "Line 1\n\n\n\n\nLine 2"
        cleaned, _ = remove_all_emoji.clean_emoji_from_text(text)
        assert "\n\n\n" not in cleaned

    def test_empty_string(self):
        """Test handling of empty string."""
        cleaned, count = remove_all_emoji.clean_emoji_from_text("")
        assert cleaned == ""
        assert count == 0

    def test_text_without_emoji(self):
        """Test text without any emoji."""
        text = "Plain text without emoji"
        cleaned, count = remove_all_emoji.clean_emoji_from_text(text)
        assert cleaned == text
        assert count == 0

    def test_multiple_emoji_types(self):
        """Test text with multiple emoji types."""
        text = "🚀 Deploy ✅ Tests 📊 Metrics 🔍 Search"
        cleaned, count = remove_all_emoji.clean_emoji_from_text(text)
        assert "🚀" not in cleaned
        assert "✅" not in cleaned
        assert "📊" not in cleaned
        assert "🔍" not in cleaned
        assert count >= 4
        assert "Deploy" in cleaned
        assert "Tests" in cleaned
        assert "Metrics" in cleaned


class TestProcessFile:
    """Test process_file function."""

    def test_process_file_with_emoji(self, tmp_path):
        """Test processing a file with emoji."""
        file_path = tmp_path / "test.md"
        file_path.write_text("Hello 🌍 World", encoding="utf-8")

        modified, count = remove_all_emoji.process_file(file_path, dry_run=False)

        assert modified is True
        assert count > 0
        content = file_path.read_text(encoding="utf-8")
        assert "🌍" not in content
        assert "Hello" in content

    def test_process_file_without_emoji(self, tmp_path):
        """Test processing a file without emoji."""
        file_path = tmp_path / "test.md"
        file_path.write_text("Plain text", encoding="utf-8")

        modified, count = remove_all_emoji.process_file(file_path, dry_run=False)

        assert modified is False
        assert count == 0

    def test_process_file_dry_run(self, tmp_path):
        """Test processing a file in dry run mode."""
        file_path = tmp_path / "test.md"
        original_content = "Hello 🌍 World"
        file_path.write_text(original_content, encoding="utf-8")

        modified, count = remove_all_emoji.process_file(file_path, dry_run=True)

        assert modified is True
        assert count > 0
        # File should not be modified in dry run
        content = file_path.read_text(encoding="utf-8")
        assert content == original_content

    def test_process_file_encoding_error(self, tmp_path):
        """Test handling of encoding errors."""
        file_path = tmp_path / "test.bin"
        file_path.write_bytes(b"\x00\x01\x02\x03")

        modified, count = remove_all_emoji.process_file(file_path, dry_run=False)

        # Should handle error gracefully
        assert modified is False
        assert count == 0


class TestEmojiPattern:
    """Test emoji pattern regex."""

    def test_emoji_pattern_matches_emoticons(self):
        """Test that pattern matches emoticons."""
        text = "😀 😃 😄 😁"
        matches = remove_all_emoji.EMOJI_PATTERN.findall(text)
        assert len(matches) > 0

    def test_emoji_pattern_matches_symbols(self):
        """Test that pattern matches symbols."""
        text = "🔥 ⚡ 🌟"
        matches = remove_all_emoji.EMOJI_PATTERN.findall(text)
        assert len(matches) > 0

    def test_emoji_pattern_no_match_text(self):
        """Test that pattern doesn't match plain text."""
        text = "Plain text without any emoji"
        matches = remove_all_emoji.EMOJI_PATTERN.findall(text)
        assert len(matches) == 0


class TestTextEmojiReplacements:
    """Test text emoji replacements."""

    def test_has_common_emoji(self):
        """Test that common emoji are in replacements."""
        patterns = [pattern for pattern, _ in remove_all_emoji.TEXT_EMOJI_REPLACEMENTS]

        # Check for common emoji
        assert any("✅" in p for p in patterns)
        assert any("❌" in p for p in patterns)
        assert any("⚠" in p for p in patterns)

    def test_replacements_format(self):
        """Test that replacements have correct format."""
        for pattern, replacement in remove_all_emoji.TEXT_EMOJI_REPLACEMENTS:
            assert isinstance(pattern, str)
            assert isinstance(replacement, str)
            assert len(pattern) > 0

    def test_flag_replacements(self):
        """Test that country flags have proper replacements."""
        replacements = dict(remove_all_emoji.TEXT_EMOJI_REPLACEMENTS)

        # Flags should map to country codes
        if "🇬🇧" in replacements:
            assert replacements["🇬🇧"] == "EN"
        if "🇩🇪" in replacements:
            assert replacements["🇩🇪"] == "DE"
        if "🇷🇺" in replacements:
            assert replacements["🇷🇺"] == "RU"


class TestExcludeDirs:
    """Test exclude directories configuration."""

    def test_exclude_dirs_exists(self):
        """Test that exclude dirs set exists."""
        assert hasattr(remove_all_emoji, "EXCLUDE_DIRS")
        assert isinstance(remove_all_emoji.EXCLUDE_DIRS, set)

    def test_exclude_dirs_contains_common(self):
        """Test that common directories are excluded."""
        exclude_dirs = remove_all_emoji.EXCLUDE_DIRS

        assert ".git" in exclude_dirs
        assert "node_modules" in exclude_dirs
        assert ".venv" in exclude_dirs
        assert "__pycache__" in exclude_dirs

    def test_exclude_dirs_not_empty(self):
        """Test that exclude dirs is not empty."""
        assert len(remove_all_emoji.EXCLUDE_DIRS) > 0
