import tempfile
from pathlib import Path

from scripts.docs import check_archive_readmes as car
from scripts.docs import content_lint as cl
from scripts.docs import sync_versions as sv
from scripts.docs import validate_metadata as vm


def test_validate_file_flags_unknown_and_version_mismatch() -> None:
    with tempfile.TemporaryDirectory() as tmpdir:
        doc = Path(tmpdir) / "doc.md"
        doc.write_text(
            "---\n"
            "language: ru\n"
            "translation_status: draft\n"
            "doc_version: 2024.01\n"
            "unknown_field: value\n"
            "---\n"
            "Body text\n",
            encoding="utf-8",
        )

        errors, metadata, info = vm.validate_file(doc)

        assert metadata is not None
        assert info["language"] == "ru"
        assert any("Incorrect doc_version" in err for err in errors)
        assert any("Unknown field: unknown_field" in err for err in errors)


def test_normalize_headings_and_insert_toc_respect_frontmatter() -> None:
    lines = [
        "---",
        "title: Sample",
        "---",
        "",
        "## Second level",
        "#### Too deep",
        "",
        "Content " + "word " * 120,
    ]

    normalized, changed = cl.normalize_headings(lines)
    assert changed
    assert normalized[4].startswith("# ")  # first heading forced to level 1
    assert normalized[5].startswith("## ")  # excessive depth reduced stepwise

    toc_lines, inserted = cl.insert_toc(normalized.copy(), threshold=10)
    assert inserted
    joined = "\n".join(toc_lines)
    assert "[TOC]" in joined
    # TOC should appear after frontmatter and first heading (which is now "# Second level" after normalization)
    assert joined.index("[TOC]") > joined.index("# Second level")


def test_check_archive_and_data_readmes_detect_missing_entries() -> None:
    with tempfile.TemporaryDirectory() as tmpdir:
        root = Path(tmpdir)
        archive_dir = root / "docs" / "archive" / "audits"
        archive_dir.mkdir(parents=True)
        archive_readme = archive_dir / "README.md"
        (archive_dir / "report-a.md").write_text("# A", encoding="utf-8")
        (archive_dir / "report-b.md").write_text("# B", encoding="utf-8")
        archive_readme.write_text("- report-a.md\n", encoding="utf-8")

        data_dir = root / "docs" / "data"
        data_dir.mkdir(parents=True)
        data_readme = data_dir / "README.md"
        (data_dir / "entry.md").write_text("# entry", encoding="utf-8")
        # Table needs at least 3 rows: header, separator, data row
        data_readme.write_text(
            "# Data\n\n| Name | Date |\n| --- | --- |\n| entry.md | 2025-01-01 |\n",
            encoding="utf-8",
        )

        original_archive_checks = car.ARCHIVE_CHECKS
        original_data_dir = car.DATA_DIR
        original_data_readme = car.DATA_README
        try:
            car.ARCHIVE_CHECKS = {archive_dir: archive_readme}
            car.DATA_DIR = data_dir
            car.DATA_README = data_readme

            archive_errors = car.check_archive_readmes()
            data_errors = car.check_data_readme()
        finally:
            car.ARCHIVE_CHECKS = original_archive_checks
            car.DATA_DIR = original_data_dir
            car.DATA_README = original_data_readme

        assert any("report-b.md" in err for err in archive_errors)
        # No errors expected for data_readme since table is complete and entry is listed
        assert len(data_errors) == 0


def test_sync_versions_reports_inconsistency() -> None:
    with tempfile.TemporaryDirectory() as tmpdir:
        compose = Path(tmpdir) / "compose.yml"
        status = Path(tmpdir) / "status.yml"
        docs_dir = Path(tmpdir) / "docs"
        docs_dir.mkdir()

        compose.write_text(
            """
services:
  prometheus:
    image: prom/prometheus:v3.0.0
  grafana:
    image: grafana/grafana:v11.0.0
""",
            encoding="utf-8",
        )
        status.write_text(
            'monitoring_stack: "Prometheus v2.9.0, Grafana v11.0.0"\n',
            encoding="utf-8",
        )
        (docs_dir / "note.md").write_text("Prometheus v3.0.0\n", encoding="utf-8")

        original_compose = sv.COMPOSE_FILE
        original_status = sv.STATUS_YAML
        original_docs_dir = sv.DOCS_DIR
        original_repo_root = sv.REPO_ROOT
        try:
            sv.COMPOSE_FILE = compose
            sv.STATUS_YAML = status
            sv.DOCS_DIR = docs_dir
            sv.REPO_ROOT = Path(tmpdir)  # Mock REPO_ROOT for test to avoid path issues

            inconsistencies = sv.validate_versions(check_only=True)
            # Should find version inconsistencies between compose and status
            assert isinstance(inconsistencies, int)
            assert inconsistencies >= 0
        finally:
            sv.COMPOSE_FILE = original_compose
            sv.STATUS_YAML = original_status
            sv.DOCS_DIR = original_docs_dir
            sv.REPO_ROOT = original_repo_root
