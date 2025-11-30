#!/usr/bin/env python3
"""
ERNI-KI Broken Links Fixer

Analyzes and fixes broken internal links in documentation.

Usage:
    ./fix-broken-links.py [--dry-run] [--report PATH]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib.logger import get_logger

logger = get_logger(__name__)

REPO_ROOT = Path(__file__).resolve().parents[2]
DOCS_DIR = REPO_ROOT / "docs"


# =============================================================================
# Link Analysis and Fixing
# =============================================================================


class LinkFixer:
    """Fix broken internal links."""

    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run
        self.fixes_applied = 0
        self.stubs_created = 0
        self.unfixable = []

    def find_broken_links(self, file_path: Path) -> list[tuple[str, str, str]]:
        """
        Find broken internal links in markdown file.

        Returns:
            List of tuples (link_text, link_path, full_match)
        """
        broken = []

        try:
            content = file_path.read_text(encoding="utf-8")
        except Exception:
            return broken

        # Find markdown links [text](path)
        link_pattern = r"\[([^\]]+)\]\(([^)]+)\)"
        for match in re.finditer(link_pattern, content):
            link_text = match.group(1)
            link_path = match.group(2)
            full_match = match.group(0)

            # Skip external links
            if link_path.startswith(("http://", "https://")):
                continue

            # Skip anchors only
            if link_path.startswith("#"):
                continue

            # Skip mailto
            if link_path.startswith("mailto:"):
                continue

            # Remove anchor from path for file existence check
            clean_path = link_path.split("#")[0] if "#" in link_path else link_path

            # Skip empty paths
            if not clean_path:
                continue

            # Resolve relative path
            target = (file_path.parent / clean_path).resolve()

            # Check if target exists
            if not target.exists():
                broken.append((link_text, link_path, full_match))

        return broken

    def find_alternative_target(self, broken_path: str, source_file: Path) -> Path | None:
        """
        Try to find alternative target for broken link.

        Strategies:
        1. Check if Russian version exists (for en/de docs)
        2. Search for file with same name elsewhere
        3. Prefer files in same language directory
        4. Check if it's in archive
        """
        # Get filename from broken path
        filename = Path(broken_path).name.split("#")[0]

        if not filename or filename == "README.md":
            return None

        # Special handling for cross-language links
        # If source is in /en/ or /de/ and target is also /en/ or /de/,
        # check if Russian version exists
        source_rel = str(source_file.relative_to(DOCS_DIR))
        if ("/en/" in source_rel or "/de/" in source_rel) and (
            "../en/" in broken_path or "../de/" in broken_path
        ):
            # Try to find Russian version by replacing /en/ or /de/ with /operations/
            russian_path = broken_path.replace("../en/", "../").replace("../de/", "../")
            russian_target = (source_file.parent / russian_path).resolve()
            if russian_target.exists() and russian_target.is_relative_to(DOCS_DIR):
                logger.debug("Found Russian version for cross-lang link: %s", russian_target)
                return russian_target

        # Search for exact filename match
        matches = list(DOCS_DIR.rglob(filename))

        # Filter out archive files
        matches = [m for m in matches if "archive" not in m.parts]

        if len(matches) == 1:
            logger.debug("Found exact match for %s: %s", filename, matches[0])
            return matches[0]

        # If multiple matches, use sophisticated matching
        if len(matches) > 1:
            # Determine source language
            source_lang = None
            if "/en/" in source_rel:
                source_lang = "en"
            elif "/de/" in source_rel:
                source_lang = "de"

            # Prefer matches in same language directory, then Russian, then others
            scored_matches = []
            for match in matches:
                match_rel = str(match.relative_to(DOCS_DIR))
                score = 0

                # Same language directory gets highest score
                if source_lang and f"/{source_lang}/" in match_rel:
                    score += 100
                # Russian (no language prefix) gets medium score
                elif not any(f"/{lang}/" in match_rel for lang in ["en", "de"]):
                    score += 50

                # Count common path parts
                source_parts = Path(source_rel).parts
                match_parts = Path(match_rel).parts
                for s, m in zip(source_parts, match_parts, strict=False):
                    if s == m:
                        score += 1
                    else:
                        break

                scored_matches.append((score, match))

            # Sort by score (highest first)
            scored_matches.sort(key=lambda x: x[0], reverse=True)
            logger.debug(
                "Found %d matches for %s, using best: %s (score: %d)",
                len(matches),
                filename,
                scored_matches[0][1],
                scored_matches[0][0],
            )
            return scored_matches[0][1]

        return None

    def fix_link(self, source_file: Path, old_link: str, new_target: Path) -> str:
        """
        Generate fixed link from source file to new target.

        Args:
            source_file: Source markdown file
            old_link: Old broken link path
            new_target: New target file path

        Returns:
            New relative link path
        """
        import os

        # Get relative path from source directory to target
        rel_path = os.path.relpath(new_target, source_file.parent)

        # Convert to forward slashes (for URLs)
        rel_path = rel_path.replace(os.sep, "/")

        # Preserve anchor if present
        if "#" in old_link:
            anchor = old_link.split("#", 1)[1]
            return f"{rel_path}#{anchor}"

        return rel_path

    def create_stub_file(self, target_path: Path, title: str) -> None:
        """
        Create stub markdown file with basic frontmatter.

        Args:
            target_path: Path where stub should be created
            title: Title for the stub file
        """
        # Determine language from path
        lang = "ru"
        if "/en/" in str(target_path):
            lang = "en"
        elif "/de/" in str(target_path):
            lang = "de"

        stub_content = f"""---
language: {lang}
doc_version: 1.0.0
translation_status: pending
---

# {title}

> **⚠️ This is a placeholder document.**
>
> This file was automatically generated to fix broken links.
> Please update with actual content.

## Overview

Add content here  # pragma: allowlist todo

## Related Documentation

Add links to related documentation  # pragma: allowlist todo
"""

        if not self.dry_run:
            target_path.parent.mkdir(parents=True, exist_ok=True)
            target_path.write_text(stub_content, encoding="utf-8")
            logger.info("Created stub file: %s", target_path.relative_to(DOCS_DIR))
        else:
            logger.info("[DRY RUN] Would create stub: %s", target_path.relative_to(DOCS_DIR))

        self.stubs_created += 1

    def process_file(self, file_path: Path) -> None:
        """
        Process single file and fix broken links.

        Args:
            file_path: Path to markdown file
        """
        broken_links = self.find_broken_links(file_path)

        if not broken_links:
            return

        rel_path = file_path.relative_to(DOCS_DIR)
        logger.info("Processing %s (%d broken links)", rel_path, len(broken_links))

        content = file_path.read_text(encoding="utf-8")
        original_content = content

        for link_text, link_path, full_match in broken_links:
            # Try to find alternative target
            alt_target = self.find_alternative_target(link_path, file_path)

            if alt_target:
                # Fix link to point to alternative target
                new_link = self.fix_link(file_path, link_path, alt_target)
                new_full_match = full_match.replace(link_path, new_link)
                content = content.replace(full_match, new_full_match)
                logger.info("  Fixed: %s → %s", link_path, new_link)
                self.fixes_applied += 1

            else:
                # Check if we should create stub
                clean_path = link_path.split("#")[0]
                target = (file_path.parent / clean_path).resolve()

                # Only create stubs for .md files in docs directory
                if target.suffix == ".md" and DOCS_DIR in target.parents:
                    self.create_stub_file(target, link_text)
                    logger.info("  Created stub for: %s", link_path)
                    self.fixes_applied += 1
                else:
                    # Cannot fix - add to unfixable list
                    self.unfixable.append((str(rel_path), link_text, link_path))
                    logger.warning("  Cannot fix: %s (%s)", link_path, link_text)

        # Write updated content
        if content != original_content:
            if not self.dry_run:
                file_path.write_text(content, encoding="utf-8")
                logger.info("Updated file: %s", rel_path)
            else:
                logger.info("[DRY RUN] Would update: %s", rel_path)

    def run(self) -> dict[str, Any]:
        """
        Run link fixing on all markdown files.

        Returns:
            Report dictionary
        """
        logger.info("Starting broken link fixing")

        for file_path in DOCS_DIR.rglob("*.md"):
            # Skip archive
            if "archive" in file_path.parts:
                continue

            self.process_file(file_path)

        return {
            "fixes_applied": self.fixes_applied,
            "stubs_created": self.stubs_created,
            "unfixable_count": len(self.unfixable),
            "unfixable_links": self.unfixable[:20],  # Limit to 20 for report
        }


# =============================================================================
# Main
# =============================================================================


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Fix broken links in ERNI-KI documentation")
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would be done without making changes"
    )
    parser.add_argument("--report", type=str, help="Save report to file")

    args = parser.parse_args()

    # Log mode
    mode = "DRY RUN" if args.dry_run else "LIVE"
    logger.info("Starting broken link fixing [%s]", mode)

    if args.dry_run:
        logger.warning("DRY RUN MODE: No changes will be made")

    # Run fixer
    fixer = LinkFixer(dry_run=args.dry_run)
    report = fixer.run()

    # Print summary
    print("\n" + "=" * 60)
    print("BROKEN LINK FIXING SUMMARY")
    print("=" * 60)
    print(f"Fixes Applied:    {report['fixes_applied']}")
    print(f"Stubs Created:    {report['stubs_created']}")
    print(f"Unfixable Links:  {report['unfixable_count']}")
    print("=" * 60)

    if report["unfixable_count"] > 0:
        print("\nUnfixable links (manual review needed):")
        for file, text, path in report["unfixable_links"]:
            print(f"  - {file}: [{text}]({path})")

    # Save report if requested
    if args.report:
        import json

        report_path = Path(args.report)
        report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        logger.info("Report saved to: %s", report_path)

    logger.info("Broken link fixing completed")


if __name__ == "__main__":
    main()
