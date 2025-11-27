#!/usr/bin/env python3
"""Comprehensive documentation audit script."""

import re
from collections import defaultdict
from datetime import datetime
from pathlib import Path

import yaml


def extract_frontmatter(content):
    """Extract YAML frontmatter from markdown."""
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if match:
        try:
            return yaml.safe_load(match.group(1))
        except yaml.YAMLError:
            return None
    return None


def check_metadata(file_path):
    """Check metadata compliance."""
    try:
        content = file_path.read_text(encoding="utf-8")
        metadata = extract_frontmatter(content)

        issues = []

        if not metadata:
            return {"has_frontmatter": False, "issues": ["No frontmatter"]}

        # Required fields
        required = ["language", "translation_status", "doc_version"]
        missing = [f for f in required if f not in metadata]
        if missing:
            issues.append(f"Missing required fields: {', '.join(missing)}")

        # Check last_updated (recommended but not required for archive)
        if "archive" not in str(file_path) and "last_updated" not in metadata:
            issues.append("Missing last_updated field")

        return {"has_frontmatter": True, "metadata": metadata, "issues": issues}
    except Exception as e:
        return {"has_frontmatter": False, "issues": [f"Error reading: {str(e)}"]}


def analyze_structure():
    """Analyze documentation structure."""
    docs_dir = Path("docs")

    stats = {
        "total_files": 0,
        "by_language": defaultdict(int),
        "by_category": defaultdict(int),
        "with_frontmatter": 0,
        "without_frontmatter": 0,
        "with_issues": 0,
        "files_with_dates": [],
        "broken_links": [],
        "missing_index": [],
        "emoji_files": [],
    }

    issues_by_file = {}

    # Scan all markdown files
    for md_file in docs_dir.rglob("*.md"):
        if any(excl in md_file.parts for excl in [".venv", "node_modules", "site"]):
            continue

        stats["total_files"] += 1

        # Check category
        rel_path = md_file.relative_to(docs_dir)
        if len(rel_path.parts) > 1:
            category = rel_path.parts[0]
            stats["by_category"][category] += 1

        # Check metadata
        check_result = check_metadata(md_file)

        if check_result["has_frontmatter"]:
            stats["with_frontmatter"] += 1
            metadata = check_result.get("metadata", {})

            # Language stats
            lang = metadata.get("language", "unknown")
            stats["by_language"][lang] += 1
        else:
            stats["without_frontmatter"] += 1

        # Check for issues
        if check_result["issues"]:
            stats["with_issues"] += 1
            issues_by_file[str(md_file)] = check_result["issues"]

        # Check for dates in filename (except archive)
        if "archive" not in str(md_file) and re.search(r"\d{4}-\d{2}-\d{2}", md_file.name):
            stats["files_with_dates"].append(str(md_file))

        # Check for emoji
        try:
            content = md_file.read_text(encoding="utf-8")
            emoji_pattern = re.compile(
                "["
                "\U0001f600-\U0001f64f"
                "\U0001f300-\U0001f5ff"
                "\U0001f680-\U0001f6ff"
                "\U0001f1e0-\U0001f1ff"
                "\U00002702-\U000027b0"
                "\U000024c2-\U0001f251"
                "\U0001f900-\U0001f9ff"
                "\U0001f018-\U0001f270"
                "]+",
                flags=re.UNICODE,
            )
            if emoji_pattern.search(content):
                stats["emoji_files"].append(str(md_file))
        except (FileNotFoundError, PermissionError, UnicodeDecodeError):
            # Skip files that cannot be read
            pass

    # Check for missing index.md files
    for directory in docs_dir.rglob("*"):
        if not directory.is_dir():
            continue
        exclude_dirs = [".venv", "node_modules", "site", "javascripts", "stylesheets"]
        if any(excl in directory.parts for excl in exclude_dirs):
            continue

        index_file = directory / "index.md"
        readme_file = directory / "README.md"

        if not index_file.exists() and not readme_file.exists():
            # Check if directory has any .md files
            md_files = list(directory.glob("*.md"))
            if md_files:
                stats["missing_index"].append(str(directory.relative_to(docs_dir)))

    return stats, issues_by_file


def generate_report(stats, issues_by_file):
    """Generate audit report."""
    report = []
    report.append("=" * 80)
    report.append("COMPREHENSIVE DOCUMENTATION AUDIT")
    report.append(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("=" * 80)
    report.append("")

    # Overall stats
    report.append("## OVERALL STATISTICS")
    report.append("")
    report.append(f"Total markdown files: {stats['total_files']}")

    with_fm = stats["with_frontmatter"]
    total = stats["total_files"]
    fm_percent = (with_fm / total * 100) if total > 0 else 0
    report.append(f"Files with frontmatter: {with_fm} ({fm_percent:.1f}%)")

    without_fm = stats["without_frontmatter"]
    without_fm_percent = (without_fm / total * 100) if total > 0 else 0
    report.append(f"Files without frontmatter: {without_fm} ({without_fm_percent:.1f}%)")

    report.append(f"Files with metadata issues: {stats['with_issues']}")
    report.append("")

    # Language distribution
    report.append("## LANGUAGE DISTRIBUTION")
    report.append("")
    for lang, count in sorted(stats["by_language"].items(), key=lambda x: x[1], reverse=True):
        percentage = count / stats["total_files"] * 100
        report.append(f"  {lang.upper():4s}: {count:3d} files ({percentage:5.1f}%)")
    report.append("")

    # Category distribution
    report.append("## CATEGORY DISTRIBUTION")
    report.append("")
    for cat, count in sorted(stats["by_category"].items(), key=lambda x: x[1], reverse=True):
        report.append(f"  {cat:30s}: {count:3d} files")
    report.append("")

    # Issues
    if issues_by_file:
        report.append("## METADATA ISSUES")
        report.append("")
        report.append(f"Found {len(issues_by_file)} files with metadata issues:")
        report.append("")
        for file_path, file_issues in sorted(issues_by_file.items())[:20]:
            report.append(f"  {file_path}")
            for issue in file_issues:
                report.append(f"    - {issue}")
        if len(issues_by_file) > 20:
            report.append(f"  ... and {len(issues_by_file) - 20} more files")
        report.append("")

    # Files with dates
    if stats["files_with_dates"]:
        report.append("## FILES WITH DATES IN NAME (outside archive/)")
        report.append("")
        report.append(f"Found {len(stats['files_with_dates'])} files:")
        for file_path in stats["files_with_dates"][:10]:
            report.append(f"  - {file_path}")
        if len(stats["files_with_dates"]) > 10:
            report.append(f"  ... and {len(stats['files_with_dates']) - 10} more")
        report.append("")

    # Missing index files
    if stats["missing_index"]:
        report.append("## DIRECTORIES WITHOUT index.md OR README.md")
        report.append("")
        report.append(f"Found {len(stats['missing_index'])} directories:")
        for dir_path in sorted(stats["missing_index"])[:15]:
            report.append(f"  - {dir_path}/")
        if len(stats["missing_index"]) > 15:
            report.append(f"  ... and {len(stats['missing_index']) - 15} more")
        report.append("")

    # Emoji check
    if stats["emoji_files"]:
        report.append("## FILES WITH EMOJI (Policy Violation)")
        report.append("")
        report.append(f"[WARNING] Found {len(stats['emoji_files'])} files with emoji:")
        for file_path in stats["emoji_files"][:10]:
            report.append(f"  - {file_path}")
        if len(stats["emoji_files"]) > 10:
            report.append(f"  ... and {len(stats['emoji_files']) - 10} more")
        report.append("")

    # Overall score
    report.append("## OVERALL ASSESSMENT")
    report.append("")

    # Calculate score
    score = 10.0

    # Penalties
    if stats["without_frontmatter"] > 0:
        penalty = (stats["without_frontmatter"] / stats["total_files"]) * 2
        score -= penalty
        report.append(f"  - Frontmatter coverage: -{penalty:.1f} points")

    if stats["with_issues"] > 10:
        penalty = min(1.0, (stats["with_issues"] - 10) / 20)
        score -= penalty
        report.append(f"  - Metadata issues: -{penalty:.1f} points")

    if stats["files_with_dates"]:
        penalty = min(0.5, len(stats["files_with_dates"]) / 10 * 0.5)
        score -= penalty
        report.append(f"  - Files with dates: -{penalty:.1f} points")

    if stats["emoji_files"]:
        penalty = min(1.0, len(stats["emoji_files"]) / 10)
        score -= penalty
        report.append(f"  - Emoji policy violations: -{penalty:.1f} points")

    if stats["missing_index"]:
        penalty = min(0.5, len(stats["missing_index"]) / 20 * 0.5)
        score -= penalty
        report.append(f"  - Missing index files: -{penalty:.1f} points")

    report.append("")
    report.append(f"FINAL SCORE: {max(0, score):.1f}/10.0")
    report.append("")

    report.append("=" * 80)

    return "\n".join(report)


def main():
    """Main audit function."""
    print("Starting documentation audit...")
    print()

    stats, issues_by_file = analyze_structure()
    report = generate_report(stats, issues_by_file)

    print(report)

    # Save report
    report_dir = Path("docs/reports")
    report_dir.mkdir(parents=True, exist_ok=True)

    report_file = report_dir / f"audit-report-{datetime.now().strftime('%Y-%m-%d')}.txt"
    report_file.write_text(report, encoding="utf-8")

    print()
    print(f"Report saved to: {report_file}")

    return 0 if stats["with_issues"] == 0 else 1


if __name__ == "__main__":
    exit(main())
