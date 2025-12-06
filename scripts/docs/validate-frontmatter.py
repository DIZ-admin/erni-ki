#!/usr/bin/env python3
"""
Validate frontmatter in Markdown documentation files.

This script checks that all .md files have proper YAML frontmatter with required fields.
"""

import json
import re
import sys
from pathlib import Path

import yaml

# Required frontmatter fields
REQUIRED_FIELDS = ["title", "language", "page_id", "doc_version", "translation_status"]

# Valid values for specific fields
VALID_LANGUAGES = ["ru", "de", "en"]
VALID_TRANSLATION_STATUS = ["original", "translated", "outdated", "in_progress"]

# Directories to exclude
EXCLUDE_DIRS = ["node_modules", ".venv", "venv", "site", ".git"]


class FrontmatterValidator:
    """Validates frontmatter in Markdown files."""

    def __init__(self, docs_dir: Path, output_file: Path | None = None):
        """Initialize validator with docs directory and optional output file."""
        self.docs_dir = docs_dir
        self.output_file = output_file
        self.results = {
            "total_files": 0,
            "files_with_frontmatter": 0,
            "files_without_frontmatter": 0,
            "valid_files": 0,
            "invalid_files": 0,
            "errors": [],
            "warnings": [],
        }

    def extract_frontmatter(self, content: str) -> dict | None:
        """Extract YAML frontmatter from markdown content."""
        # Match frontmatter between --- delimiters
        pattern = r"^---\s*\n(.*?)\n---\s*\n"
        match = re.match(pattern, content, re.DOTALL)

        if not match:
            return None

        try:
            frontmatter = yaml.safe_load(match.group(1))
            return frontmatter if isinstance(frontmatter, dict) else None
        except yaml.YAMLError:
            return None

    def validate_frontmatter(self, frontmatter: dict, file_path: Path) -> list:
        """Validate frontmatter fields and return list of errors."""
        errors = []

        # Check required fields
        for field in REQUIRED_FIELDS:
            if field not in frontmatter:
                errors.append(f"Missing required field: {field}")

        # Validate language
        if "language" in frontmatter:
            lang = frontmatter["language"]
            if lang not in VALID_LANGUAGES:
                errors.append(f"Invalid language '{lang}', must be one of {VALID_LANGUAGES}")

        # Validate translation_status
        if "translation_status" in frontmatter:
            status = frontmatter["translation_status"]
            if status not in VALID_TRANSLATION_STATUS:
                errors.append(
                    f"Invalid translation_status '{status}', "
                    f"must be one of {VALID_TRANSLATION_STATUS}"
                )

        # Validate doc_version format (should be 'YYYY.MM')
        if "doc_version" in frontmatter:
            version = str(frontmatter["doc_version"])
            if not re.match(r"^\d{4}\.\d{2}$", version):
                errors.append(f"Invalid doc_version '{version}', should be 'YYYY.MM' format")

        # Validate page_id format (should be kebab-case)
        if "page_id" in frontmatter:
            page_id = frontmatter["page_id"]
            if not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", page_id):
                errors.append(
                    f"Invalid page_id '{page_id}', should be kebab-case (lowercase, hyphens only)"
                )

        return errors

    def validate_file(self, file_path: Path) -> None:
        """Validate a single markdown file."""
        self.results["total_files"] += 1
        relative_path = file_path.relative_to(self.docs_dir)

        try:
            content = file_path.read_text(encoding="utf-8")
        except Exception as e:
            self.results["errors"].append(
                {"file": str(relative_path), "error": f"Failed to read file: {e}"}
            )
            self.results["invalid_files"] += 1
            return

        frontmatter = self.extract_frontmatter(content)

        if frontmatter is None:
            self.results["files_without_frontmatter"] += 1
            self.results["warnings"].append(
                {"file": str(relative_path), "warning": "No frontmatter found"}
            )
            self.results["invalid_files"] += 1
            return

        self.results["files_with_frontmatter"] += 1

        # Validate frontmatter
        errors = self.validate_frontmatter(frontmatter, file_path)

        if errors:
            self.results["invalid_files"] += 1
            self.results["errors"].append({"file": str(relative_path), "errors": errors})
        else:
            self.results["valid_files"] += 1

    def should_exclude(self, path: Path) -> bool:
        """Check if path should be excluded from validation."""
        parts = path.parts
        return any(excluded in parts for excluded in EXCLUDE_DIRS)

    def validate_all(self) -> None:
        """Validate all markdown files in docs directory."""
        for md_file in self.docs_dir.rglob("*.md"):
            if not self.should_exclude(md_file):
                self.validate_file(md_file)

    def print_summary(self) -> None:
        """Print validation summary to console."""
        print("\n" + "=" * 80)
        print("FRONTMATTER VALIDATION SUMMARY")
        print("=" * 80)
        print(f"\nTotal files: {self.results['total_files']}")
        total = max(1, self.results['total_files'])
        with_fm = self.results['files_with_frontmatter']
        percent = (with_fm / total) * 100
        print(f"Files with frontmatter: {with_fm} ({percent:.1f}%)")
        print(f"Files without frontmatter: {self.results['files_without_frontmatter']}")
        print(f"Valid files: {self.results['valid_files']}")
        print(f"Invalid files: {self.results['invalid_files']}")

        if self.results["warnings"]:
            print(f"\n⚠️  Warnings: {len(self.results['warnings'])}")
            for warning in self.results["warnings"][:10]:  # Show first 10
                print(f"  - {warning['file']}: {warning['warning']}")
            if len(self.results["warnings"]) > 10:
                print(f"  ... and {len(self.results['warnings']) - 10} more")

        if self.results["errors"]:
            print(f"\n❌ Errors: {len(self.results['errors'])}")
            for error in self.results["errors"][:10]:  # Show first 10
                print(f"  - {error['file']}:")
                if "error" in error:
                    print(f"    {error['error']}")
                else:
                    for err in error.get("errors", []):
                        print(f"    • {err}")
            if len(self.results["errors"]) > 10:
                print(f"  ... and {len(self.results['errors']) - 10} more")

        print("\n" + "=" * 80)

        # Exit code
        if self.results["invalid_files"] > 0:
            print("\n❌ Validation FAILED")
            return 1
        else:
            print("\n✅ Validation PASSED")
            return 0

    def save_results(self) -> None:
        """Save results to JSON file if output_file is specified."""
        if self.output_file:
            self.output_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.output_file, "w", encoding="utf-8") as f:
                json.dump(self.results, f, indent=2, ensure_ascii=False)
            print(f"\n📄 Results saved to: {self.output_file}")


def main() -> int:
    """Main function."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate frontmatter in Markdown documentation files"
    )
    parser.add_argument(
        "--docs-dir",
        type=Path,
        default=Path("docs"),
        help="Documentation directory to validate (default: docs)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Output JSON file for results (optional)",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail on warnings (files without frontmatter)",
    )

    args = parser.parse_args()

    if not args.docs_dir.exists():
        print(f"❌ Error: Documentation directory not found: {args.docs_dir}")
        return 1

    validator = FrontmatterValidator(args.docs_dir, args.output)
    validator.validate_all()

    if args.output:
        validator.save_results()

    exit_code = validator.print_summary()

    # In strict mode, also fail on warnings
    if args.strict and validator.results["warnings"]:
        return 1

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
