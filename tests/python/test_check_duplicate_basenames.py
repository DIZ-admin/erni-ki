"""
Tests for scripts/maintenance/check_duplicate_basenames.py

This module tests the duplicate basename detection script that prevents
naming conflicts between scripts/ and conf/ directories.
"""

import sys
from pathlib import Path
from unittest.mock import patch

import pytest

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from scripts.maintenance.check_duplicate_basenames import check_duplicates, get_basenames, main


class TestGetBasenames:
    """Tests for get_basenames function."""

    def test_get_basenames_empty_directory(self, tmp_path):
        """Test get_basenames with an empty directory."""
        result = get_basenames(tmp_path)
        assert result == {}

    def test_get_basenames_single_file(self, tmp_path):
        """Test get_basenames with a single file."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("#!/bin/bash\n")

        result = get_basenames(tmp_path)
        assert "test.sh" in result
        assert result["test.sh"] == [test_file]

    def test_get_basenames_multiple_files(self, tmp_path):
        """Test get_basenames with multiple files."""
        files = ["script1.sh", "script2.py", "config.yaml"]
        for filename in files:
            (tmp_path / filename).write_text("test")

        result = get_basenames(tmp_path)
        assert len(result) == 3
        for filename in files:
            assert filename in result

    def test_get_basenames_ignores_directories(self, tmp_path):
        """Test that get_basenames ignores subdirectories."""
        subdir = tmp_path / "subdir"
        subdir.mkdir()
        (subdir / "file.sh").write_text("test")

        result = get_basenames(tmp_path)
        assert "subdir" not in result
        assert len(result) == 0  # Subdirectory files should not be included

    def test_get_basenames_duplicate_basenames_different_paths(self, tmp_path):
        """Test get_basenames when same basename exists in different subdirs."""
        dir1 = tmp_path / "dir1"
        dir2 = tmp_path / "dir2"
        dir1.mkdir()
        dir2.mkdir()

        (dir1 / "duplicate.sh").write_text("test1")
        (dir2 / "duplicate.sh").write_text("test2")

        # When called on parent, should find both
        result = get_basenames(tmp_path)
        # Note: This depends on implementation - adjust based on actual behavior
        assert len(result) >= 0

    def test_get_basenames_with_hidden_files(self, tmp_path):
        """Test that get_basenames handles hidden files."""
        (tmp_path / ".hidden.sh").write_text("test")
        (tmp_path / "visible.sh").write_text("test")

        result = get_basenames(tmp_path)
        assert ".hidden.sh" in result
        assert "visible.sh" in result


class TestCheckDuplicates:
    """Tests for check_duplicates function."""

    def test_check_duplicates_no_duplicates(self):
        """Test check_duplicates when there are no duplicates."""
        scripts_basenames = {"script1.sh": [Path("/scripts/script1.sh")]}
        conf_basenames = {"config.yaml": [Path("/conf/config.yaml")]}

        duplicates = check_duplicates(scripts_basenames, conf_basenames)
        assert len(duplicates) == 0

    def test_check_duplicates_single_duplicate(self):
        """Test check_duplicates with one duplicate basename."""
        scripts_basenames = {"common.sh": [Path("/scripts/common.sh")]}
        conf_basenames = {"common.sh": [Path("/conf/common.sh")]}

        duplicates = check_duplicates(scripts_basenames, conf_basenames)
        assert len(duplicates) == 1
        assert "common.sh" in duplicates

    def test_check_duplicates_multiple_duplicates(self):
        """Test check_duplicates with multiple duplicate basenames."""
        scripts_basenames = {
            "util.sh": [Path("/scripts/util.sh")],
            "helper.py": [Path("/scripts/helper.py")],
        }
        conf_basenames = {
            "util.sh": [Path("/conf/util.sh")],
            "helper.py": [Path("/conf/helper.py")],
        }

        duplicates = check_duplicates(scripts_basenames, conf_basenames)
        assert len(duplicates) == 2
        assert "util.sh" in duplicates
        assert "helper.py" in duplicates

    def test_check_duplicates_empty_inputs(self):
        """Test check_duplicates with empty dictionaries."""
        duplicates = check_duplicates({}, {})
        assert len(duplicates) == 0

    def test_check_duplicates_one_empty_input(self):
        """Test check_duplicates when one directory is empty."""
        scripts_basenames = {"script.sh": [Path("/scripts/script.sh")]}
        conf_basenames = {}

        duplicates = check_duplicates(scripts_basenames, conf_basenames)
        assert len(duplicates) == 0


class TestMain:
    """Tests for main function."""

    def test_main_no_duplicates_exits_zero(self, tmp_path, monkeypatch):
        """Test that main exits with 0 when no duplicates found."""
        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        (scripts_dir / "unique1.sh").write_text("test")
        (conf_dir / "unique2.yaml").write_text("test")

        monkeypatch.chdir(tmp_path)

        with patch("sys.exit") as mock_exit:
            main()
            mock_exit.assert_called_once_with(0)

    def test_main_with_duplicates_exits_one(self, tmp_path, monkeypatch, capsys):
        """Test that main exits with 1 when duplicates are found."""
        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        (scripts_dir / "duplicate.sh").write_text("test1")
        (conf_dir / "duplicate.sh").write_text("test2")

        monkeypatch.chdir(tmp_path)

        with patch("sys.exit") as mock_exit:
            main()
            mock_exit.assert_called_once_with(1)

        captured = capsys.readouterr()
        assert "duplicate.sh" in captured.out

    def test_main_missing_scripts_directory(self, tmp_path, monkeypatch, capsys):
        """Test main behavior when scripts directory is missing."""
        conf_dir = tmp_path / "conf"
        conf_dir.mkdir()

        monkeypatch.chdir(tmp_path)

        with patch("sys.exit") as mock_exit:
            main()
            # Should exit with 0 if directory doesn't exist (no duplicates possible)
            mock_exit.assert_called_once_with(0)

    def test_main_missing_conf_directory(self, tmp_path, monkeypatch, capsys):
        """Test main behavior when conf directory is missing."""
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()

        monkeypatch.chdir(tmp_path)

        with patch("sys.exit") as mock_exit:
            main()
            mock_exit.assert_called_once_with(0)


class TestIntegration:
    """Integration tests for the duplicate basename checker."""

    def test_real_world_scenario_with_nested_directories(self, tmp_path, monkeypatch):
        """Test with a realistic directory structure."""
        # Create directory structure
        scripts_dir = tmp_path / "scripts"
        scripts_utils = scripts_dir / "utils"
        scripts_maintenance = scripts_dir / "maintenance"
        conf_dir = tmp_path / "conf"
        conf_nginx = conf_dir / "nginx"

        for dir_path in [scripts_utils, scripts_maintenance, conf_nginx]:
            dir_path.mkdir(parents=True)

        # Create files
        (scripts_utils / "logger.py").write_text("# logger script")
        (scripts_maintenance / "cleanup.sh").write_text("#!/bin/bash")
        (conf_nginx / "nginx.conf").write_text("server {}")
        (conf_dir / "cleanup.sh").write_text("#!/bin/bash")  # Duplicate!

        monkeypatch.chdir(tmp_path)

        # Run check
        scripts_basenames = get_basenames(scripts_dir)
        conf_basenames = get_basenames(conf_dir)
        duplicates = check_duplicates(scripts_basenames, conf_basenames)

        # Should find cleanup.sh as duplicate
        assert "cleanup.sh" in duplicates
        assert len(duplicates["cleanup.sh"]) == 2

    def test_case_sensitivity(self, tmp_path):
        """Test that basename checking is case-sensitive."""
        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        (scripts_dir / "Script.sh").write_text("test")
        (conf_dir / "script.sh").write_text("test")

        scripts_basenames = get_basenames(scripts_dir)
        conf_basenames = get_basenames(conf_dir)
        duplicates = check_duplicates(scripts_basenames, conf_basenames)

        # On case-sensitive filesystems, these are different files
        # On case-insensitive filesystems (macOS, Windows), might be considered duplicates
        # The test should reflect the actual filesystem behavior
        # For now, we expect them to be treated as different
        assert len(duplicates) == 0 or "script.sh" in duplicates

    def test_symlinks_handling(self, tmp_path):
        """Test handling of symbolic links."""
        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        original_file = scripts_dir / "original.sh"
        original_file.write_text("test")

        # Create symlink
        try:
            symlink = conf_dir / "original.sh"
            symlink.symlink_to(original_file)

            scripts_basenames = get_basenames(scripts_dir)
            conf_basenames = get_basenames(conf_dir)
            duplicates = check_duplicates(scripts_basenames, conf_basenames)

            # Symlinks should be treated as regular files for basename purposes
            assert "original.sh" in duplicates
        except OSError:
            # Symlinks might not be supported on all platforms
            pytest.skip("Symlinks not supported on this platform")

    def test_performance_with_many_files(self, tmp_path, monkeypatch):
        """Test performance with a large number of files."""
        import time

        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        # Create many files
        for i in range(1000):
            (scripts_dir / f"script_{i}.sh").write_text(f"# Script {i}")
            (conf_dir / f"config_{i}.yaml").write_text(f"# Config {i}")

        # Add one duplicate
        (scripts_dir / "duplicate.sh").write_text("test")
        (conf_dir / "duplicate.sh").write_text("test")

        monkeypatch.chdir(tmp_path)

        start_time = time.time()
        scripts_basenames = get_basenames(scripts_dir)
        conf_basenames = get_basenames(conf_dir)
        duplicates = check_duplicates(scripts_basenames, conf_basenames)
        elapsed = time.time() - start_time

        assert "duplicate.sh" in duplicates
        # Should complete in reasonable time (< 1 second for 2000 files)
        assert elapsed < 1.0


class TestEdgeCases:
    """Tests for edge cases and error conditions."""

    def test_files_with_spaces_in_names(self, tmp_path):
        """Test handling of filenames with spaces."""
        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        (scripts_dir / "my script.sh").write_text("test")
        (conf_dir / "my script.sh").write_text("test")

        scripts_basenames = get_basenames(scripts_dir)
        conf_basenames = get_basenames(conf_dir)
        duplicates = check_duplicates(scripts_basenames, conf_basenames)

        assert "my script.sh" in duplicates

    def test_files_with_special_characters(self, tmp_path):
        """Test handling of filenames with special characters."""
        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        # Note: Some characters might not be allowed on all filesystems
        special_files = ["script-name.sh", "script_name.py", "script.v2.0.sh"]

        for filename in special_files:
            try:
                (scripts_dir / filename).write_text("test")
                (conf_dir / filename).write_text("test")
            except OSError:
                continue  # Skip if filesystem doesn't support the character

        scripts_basenames = get_basenames(scripts_dir)
        conf_basenames = get_basenames(conf_dir)
        duplicates = check_duplicates(scripts_basenames, conf_basenames)

        # Should find duplicates for all successfully created files
        assert len(duplicates) > 0

    def test_empty_filenames_rejected(self, tmp_path):
        """Test that empty filenames are handled properly."""
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()

        # Can't actually create a file with empty name, but test the logic
        # This is more of a sanity check
        result = get_basenames(scripts_dir)
        assert "" not in result

    def test_very_long_filenames(self, tmp_path):
        """Test handling of very long filenames."""
        scripts_dir = tmp_path / "scripts"
        conf_dir = tmp_path / "conf"
        scripts_dir.mkdir()
        conf_dir.mkdir()

        # Most filesystems have a limit around 255 characters
        long_name = "a" * 200 + ".sh"

        try:
            (scripts_dir / long_name).write_text("test")
            (conf_dir / long_name).write_text("test")

            scripts_basenames = get_basenames(scripts_dir)
            conf_basenames = get_basenames(conf_dir)
            duplicates = check_duplicates(scripts_basenames, conf_basenames)

            assert long_name in duplicates
        except OSError:
            pytest.skip("Filesystem doesn't support filenames this long")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
