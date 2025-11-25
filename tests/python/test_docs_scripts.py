import tempfile
import unittest
from pathlib import Path

from scripts.docs.translation_report import collect_ru_files, parse_frontmatter
from scripts.docs.visuals_and_links_check import check_links, has_basic_toc, has_visual


class TestTranslationReport(unittest.TestCase):
    def test_parse_frontmatter_returns_dict(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "sample.md"
            path.write_text("---\nkey: value\nflag: true\n---\ncontent", encoding="utf-8")
            data = parse_frontmatter(path)
            self.assertEqual(data.get("key"), "value")
            self.assertEqual(data.get("flag"), True)

    def test_collect_ru_files_excludes_locales(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            (root / "docs").mkdir()
            ru_file = root / "docs" / "file.md"
            de_file = root / "de" / "file.md"
            en_file = root / "en" / "file.md"
            for p in (ru_file, de_file, en_file):
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text("content", encoding="utf-8")

            ru_list = collect_ru_files(root, exclude=set())
            self.assertIn(ru_file, ru_list)
            self.assertNotIn(de_file, ru_list)
            self.assertNotIn(en_file, ru_list)


class TestVisualsAndLinks(unittest.TestCase):
    def test_has_visual_and_toc(self) -> None:
        text = "# Title\n\n## Section\nContent\n\n## Second\n```mermaid\nflowchart LR\nA-->B\n```\n"
        self.assertTrue(has_visual(text))
        self.assertTrue(has_basic_toc(text))

    def test_check_links_reports_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            file_path = base / "doc.md"
            file_path.write_text("[link](missing.md)", encoding="utf-8")
            issues = check_links(file_path, file_path.read_text(encoding="utf-8"))
            self.assertTrue(any("missing link target" in issue for issue in issues))


if __name__ == "__main__":
    unittest.main()
