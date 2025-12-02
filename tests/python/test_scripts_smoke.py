#!/usr/bin/env python3
"""Smoke tests for maintenance/docs scripts."""

from __future__ import annotations

import subprocess
from pathlib import Path
from unittest.mock import patch


def test_check_duplicate_basenames_smoke(tmp_path: Path):
    """Simulate git ls-files output and ensure script runs without errors."""
    from scripts.maintenance import check_duplicate_basenames as cdb

    # Create fake files
    (tmp_path / "scripts").mkdir()
    (tmp_path / "scripts" / "a.sh").write_text("echo a")
    (tmp_path / "scripts" / "b.sh").write_text("echo b")

    fake_repo_files = [
        "scripts/a.sh",
        "scripts/b.sh",
        "docs/index.md",
    ]

    with patch.object(subprocess, "check_output", return_value="\n".join(fake_repo_files)):
        duplicates = cdb.find_duplicates()
        assert isinstance(duplicates, dict)
        # No duplicates expected in this synthetic list
        assert not duplicates


def test_update_status_snippet_prettier_smoke(tmp_path: Path):
    """Ensure run_prettier/prettier_format handle missing npx gracefully."""
    from scripts.docs import update_status_snippet_v2 as snippet

    # Mock subprocess.run to simulate missing npx
    with patch.object(subprocess, "run", side_effect=FileNotFoundError):
        snippet.run_prettier(["foo.md"])  # should not raise

    sample_md = "# Title\n\nContent"
    repo_tmp = snippet.REPO_ROOT / "tmp_snippet_test"
    repo_tmp.mkdir(exist_ok=True)
    target = repo_tmp / "foo.md"
    with patch.object(subprocess, "run", side_effect=FileNotFoundError):
        result = snippet.prettier_format(sample_md, target)
        assert "Title" in result  # returns original text on failure
