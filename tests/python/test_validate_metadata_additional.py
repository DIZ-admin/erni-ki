from __future__ import annotations

from pathlib import Path

import pytest

from scripts.docs import validate_metadata as vm


def test_validate_metadata_happy_path(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    monkeypatch.chdir(tmp_path)
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    md = docs_dir / "good.md"
    md.write_text(
        "---\n"
        "language: ru\n"
        "translation_status: complete\n"
        "doc_version: '2025.11'\n"
        "last_updated: '2025-12-04'\n"
        "---\n\n"
        "Content\n",
        encoding="utf-8",
    )

    errors, metadata, info = vm.validate_file(md)
    assert errors == []
    assert metadata is not None
    assert info["doc_version_ok"] is True
    assert info["language"] == "ru"


def test_validate_metadata_doc_version_mismatch(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    monkeypatch.chdir(tmp_path)
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    md = docs_dir / "mismatch.md"
    md.write_text(
        "---\n"
        "language: en\n"
        "translation_status: in-progress\n"
        "doc_version: '2024.09'\n"
        "---\n\n"
        "Content\n",
        encoding="utf-8",
    )

    errors, _metadata, info = vm.validate_file(md)
    assert any("Incorrect doc_version" in err for err in errors)
    assert info["doc_version_ok"] is False


def test_validate_metadata_missing_frontmatter(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    monkeypatch.chdir(tmp_path)
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    md = docs_dir / "broken.md"
    md.write_text("no frontmatter here", encoding="utf-8")

    errors, metadata, _info = vm.validate_file(md)
    assert "No frontmatter found" in errors
    assert metadata is None
