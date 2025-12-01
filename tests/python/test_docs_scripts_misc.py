#!/usr/bin/env python3
"""Lightweight smoke tests for documentation maintenance scripts."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_module(rel_path: list[str], name: str):
    module_path = ROOT.joinpath(*rel_path)
    spec = importlib.util.spec_from_file_location(name, module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


fix_meta = load_module(["scripts", "fix-deprecated-metadata.py"], "fix_meta")
remove_emoji = load_module(["scripts", "remove-all-emoji.py"], "remove_emoji")
validate_emoji = load_module(["scripts", "validate-no-emoji.py"], "validate_emoji")


def test_fix_frontmatter_replaces_fields():
    content = """---
status: draft
version: v1
translation_status: keep
doc_version: keep
---
Body
"""
    new_content, changes = fix_meta.fix_frontmatter(content, "dummy.md")
    assert "system_status" in new_content
    assert "system_version" in new_content
    assert "status → system_status" in changes
    assert "version → system_version" in changes


def test_clean_emoji_from_text_counts_and_replaces():
    text = "Hello ✅🚀"
    cleaned, count = remove_emoji.clean_emoji_from_text(text)
    assert "[OK]" in cleaned or "Hello " in cleaned
    assert count >= 1


def test_validate_no_emoji_detects_and_lists(tmp_path: Path):
    sample = tmp_path / "file.txt"
    sample.write_text("Warning ⚠️ here", encoding="utf-8")

    has_emoji, emoji_list = validate_emoji.check_file_for_emoji(str(sample))
    assert has_emoji is True
    assert "⚠️" in emoji_list
