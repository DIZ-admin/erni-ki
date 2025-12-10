#!/bin/bash

# Clean up remaining archive files and create landing page
# Usage: ./cleanup_remaining.sh [--dry-run]

set -e

# Get script directory and change to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Parse arguments
DRY_RUN=false
if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
    DRY_RUN=true
    echo "=== DRY RUN MODE (no changes will be made) ==="
    echo ""
fi

# Helper function for git commands
git_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] git $*"
    else
        git "$@"
    fi
}

echo "=== Cleaning up remaining files ==="
echo ""

# Remove duplicate audit file
if [ -f "docs/archive/audits/comprehensive-investor-audit-2025-12-03.md" ]; then
    echo "Removing duplicate audit file..."
    git_cmd rm docs/archive/audits/comprehensive-investor-audit-2025-12-03.md
fi

# Move .txt files to en/archive/reports (they're English summaries)
echo "Moving .txt files to en/archive/reports..."
if [ "$DRY_RUN" = false ]; then
    mkdir -p docs/en/archive/reports
fi
for txtfile in docs/archive/reports/*.txt; do
    if [ -f "$txtfile" ]; then
        echo "  Moving: $txtfile"
        git_cmd mv "$txtfile" docs/en/archive/reports/
    fi
done

# The .conflict.md files will be handled manually later
echo ""
echo "Conflict files remaining for manual review:"
find docs -name "*.conflict.md" 2>/dev/null || echo "  None"

# Try to remove archive directory if empty
echo ""
if [ -d "docs/archive" ]; then
    REMAINING=$(find docs/archive -type f | wc -l | tr -d ' ')
    echo "Remaining files in archive: $REMAINING"
    if [ "$REMAINING" -eq 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would remove empty docs/archive directory"
        else
            rm -rf docs/archive
            echo "✓ Removed empty docs/archive directory"
        fi
    else
        echo "⚠ Archive still contains files (likely conflicts)"
        find docs/archive -type f
    fi
fi

echo ""
echo "=== Creating new landing page ==="

# Backup existing index if it exists
if [ -f "docs/index.md" ]; then
    echo "Backing up existing index.md..."
    if [ "$DRY_RUN" = false ]; then
        cp docs/index.md docs/index.md.backup
    else
        echo "[DRY-RUN] Would backup docs/index.md"
    fi
fi

# Create new landing page
if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would create new docs/index.md with language selector"
else
    cat > docs/index.md << 'EOF'
---
language: en
translation_status: original
doc_version: '2025.11'
last_updated: '2025-12-10'
---

# ERNI-KI Documentation

Welcome to the ERNI-KI documentation. Please select your language:

## Language Selection

- [Русский (Russian)](ru/index.md) - Canonical source, most complete
- [English](en/index.md) - English translation
- [Deutsch (German)](de/index.md) - German translation

## About ERNI-KI

ERNI-KI is a comprehensive knowledge and intelligence platform designed for efficient information management and AI-powered assistance.

This documentation is maintained in multiple languages, with Russian as the canonical source. English and German translations are provided for broader accessibility.

## Quick Links

- [Getting Started](en/getting-started/index.md)
- [Architecture Overview](en/architecture/index.md)
- [Operations Handbook](en/operations/core/operations-handbook.md)
- [Academy & Training](en/academy/index.md)

## System Status

For real-time system status, visit the [Status Page](en/system/status.md).

## Contributing

For information on contributing to this documentation, see the [Development Guide](en/development/index.md).
EOF
    echo "✓ Created new docs/index.md with language selector"
fi
echo ""

echo "=== Final Status ==="
echo ""
echo "Directory structure:"
echo "  docs/en/     - English content ($(find docs/en -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files)"
echo "  docs/ru/     - Russian content ($(find docs/ru -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files)"
echo "  docs/de/     - German content ($(find docs/de -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files)"
echo "  docs/index.md - Language selector"
echo ""
echo "Remaining items for manual review:"
find docs -maxdepth 3 -name "*.conflict.md" 2>/dev/null | wc -l | tr -d ' ' | xargs echo "  Conflict files:"
echo ""
echo "✓ Migration complete!"
echo ""
echo "Next steps:"
echo "1. Review conflict files and resolve manually"
echo "2. Run validation checks"
echo "3. Update mkdocs.yml (separate task)"
echo "4. Check for broken links"
