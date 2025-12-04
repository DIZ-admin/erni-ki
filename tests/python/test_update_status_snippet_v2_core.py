from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.docs import update_status_snippet_v2 as uss


def _configure_paths(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    repo_root = tmp_path / "repo"
    repo_root.mkdir()

    status_dir = repo_root / "docs" / "reference"
    status_dir.mkdir(parents=True)
    locale_file = repo_root / "docs" / "reference" / "status-snippet-locales.json"
    locale_file.write_text(
        json.dumps(
            {
                "ru": {
                    "header": "System Status",
                    "containers": "Containers",
                    "grafana": "Grafana",
                    "alerts": "Alerts",
                    "aiGpu": "AI/GPU",
                    "context": "Context & RAG",
                    "monitoring": "Monitoring",
                    "automation": "Automation",
                    "note": "Note",
                }
            }
        ),
        encoding="utf-8",
    )

    monkeypatch.setattr(uss, "REPO_ROOT", repo_root)
    monkeypatch.setattr(uss, "STATUS_YAML", status_dir / "status.yml")
    monkeypatch.setattr(uss, "SNIPPET_MD", status_dir / "status-snippet.md")
    monkeypatch.setattr(uss, "SNIPPET_DE_MD", status_dir / "status-snippet.de.md")
    monkeypatch.setattr(uss, "README_FILE", repo_root / "README.md")
    monkeypatch.setattr(uss, "DOC_INDEX_FILE", repo_root / "docs" / "index.md")
    monkeypatch.setattr(uss, "DOC_OVERVIEW_FILE", repo_root / "docs" / "overview.md")
    monkeypatch.setattr(uss, "DE_INDEX_FILE", repo_root / "docs" / "de" / "index.md")
    monkeypatch.setattr(uss, "LOCALE_STRINGS_FILE", locale_file)

    return repo_root


def test_parse_simple_yaml(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    repo_root = _configure_paths(tmp_path, monkeypatch)
    status_yaml = repo_root / "docs" / "reference" / "status.yml"
    status_yaml.write_text(
        "# comment\ndate: 2025-12-04\nrelease: v0.6.1\ncontainers: 10/10\nnote: All good\n",
        encoding="utf-8",
    )

    parsed = uss.parse_simple_yaml(status_yaml)
    assert parsed["date"] == "2025-12-04"
    assert parsed["release"] == "v0.6.1"
    assert parsed["containers"] == "10/10"


def test_render_and_write_snippet(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    _configure_paths(tmp_path, monkeypatch)
    data = {
        "date": "2025-12-04",
        "release": "v0.6.1",
        "containers": "34/34 services healthy",
        "grafana_dashboards": "5/5 Grafana dashboards (provisioned)",
        "prometheus_alerts": "20 Prometheus alert rules active",
        "gpu_stack": "Ollama + OpenWebUI (GPU)",
        "ai_stack": "LiteLLM + Context7",
        "monitoring_stack": "Prometheus/Loki/Grafana",
        "automation": "Scheduled backups",
        "notes": "Stable",
    }

    snippet = uss.render_snippet(data, locale="ru")
    assert "System Status" in snippet
    assert "34/34 services healthy" in snippet

    target = uss.SNIPPET_MD
    uss.write_snippet(target, snippet, data, locale="ru")

    written = target.read_text(encoding="utf-8")
    assert written.startswith("---\nlanguage: ru")
    assert "System Status" in written
    assert "34/34 services healthy" in written


def test_parse_simple_yaml_missing(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    _configure_paths(tmp_path, monkeypatch)
    missing = tmp_path / "repo" / "docs" / "reference" / "absent.yml"
    with pytest.raises(FileNotFoundError):
        uss.parse_simple_yaml(missing)


def test_build_frontmatter_defaults(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    _configure_paths(tmp_path, monkeypatch)
    fm = uss.build_frontmatter("de", {"date": "2025-12-04"})
    assert "language: de" in fm
    assert "doc_version: '2025.12'" in fm
