from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.docs import visuals_and_links_check as vac


def _setup_temp_docs(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> tuple[Path, Path]:
    root = tmp_path / "repo"
    docs_dir = root / "docs"
    docs_dir.mkdir(parents=True)

    targets_file = docs_dir / "visuals_targets.json"

    monkeypatch.setattr(vac, "ROOT", root)
    monkeypatch.setattr(vac, "TARGETS", targets_file)
    return root, targets_file


def test_validate_file_success(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    root, targets_file = _setup_temp_docs(tmp_path, monkeypatch)
    (root / "docs").mkdir(exist_ok=True)

    content = """\
# Title
## Section A
Some intro
```mermaid
graph TD;
```
## Section B
See [details](details.md)
"""
    target_md = root / "docs" / "sample.md"
    target_md.write_text(content, encoding="utf-8")
    (root / "docs" / "details.md").write_text("# details", encoding="utf-8")

    targets_file.write_text(json.dumps([{"path": "docs/sample.md"}]), encoding="utf-8")

    problems = vac.validate_file("docs/sample.md")
    assert problems == []

    vac.main()  # Should not raise for valid config


def test_validate_file_reports_missing_link(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    root, targets_file = _setup_temp_docs(tmp_path, monkeypatch)
    md_path = root / "docs" / "broken.md"
    md_path.write_text("## A\n\nno visuals\n\n[broken](missing.md)", encoding="utf-8")
    targets_file.write_text(json.dumps([{"path": "docs/broken.md"}]), encoding="utf-8")

    problems = vac.validate_file("docs/broken.md")
    assert any("missing link target" in issue for issue in problems)

    with pytest.raises(SystemExit):
        vac.main()
