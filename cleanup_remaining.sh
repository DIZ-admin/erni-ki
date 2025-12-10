#!/bin/bash

# Clean up remaining archive files and create landing page

set -e
cd "/Users/kostas/Documents/Projects/erni-ki-1"

echo "=== Cleaning up remaining files ==="
echo ""

# Remove duplicate audit file
if [ -f "docs/archive/audits/comprehensive-investor-audit-2025-12-03.md" ]; then
    echo "Removing duplicate audit file..."
    git rm docs/archive/audits/comprehensive-investor-audit-2025-12-03.md
fi

# Move .txt files to en/archive/reports (they're English summaries)
echo "Moving .txt files to en/archive/reports..."
mkdir -p docs/en/archive/reports
for txtfile in docs/archive/reports/*.txt; do
    if [ -f "$txtfile" ]; then
        echo "  Moving: $txtfile"
        git mv "$txtfile" docs/en/archive/reports/
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
        rm -rf docs/archive
        echo "✓ Removed empty docs/archive directory"
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
    cp docs/index.md docs/index.md.backup
fi

# Create new landing page
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
