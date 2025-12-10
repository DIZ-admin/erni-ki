#!/bin/bash

# Phase 2A: Migrate to full i18n structure
# This script moves all content files into locale-specific folders

set -e  # Exit on error

DOCS_DIR="/Users/kostas/Documents/Projects/erni-ki-1/docs"
cd "$DOCS_DIR/.."

echo "=== Phase 2A: i18n Migration ==="
echo ""

# Step 1: Find all English files in root
echo "Step 1: Finding English files in root..."
EN_FILES=$(find docs -maxdepth 3 -name "*.md" -not -path "*/ru/*" -not -path "*/de/*" -not -path "*/en/*" -not -path "*/archive/*" -type f -exec grep -l "^language: en" {} \; 2>/dev/null)
EN_COUNT=$(echo "$EN_FILES" | wc -l | tr -d ' ')
echo "Found $EN_COUNT English files to move"
echo ""

# Step 2: Find all Russian files in root
echo "Step 2: Finding Russian files in root..."
RU_FILES=$(find docs -maxdepth 3 -name "*.md" -not -path "*/ru/*" -not -path "*/de/*" -not -path "*/en/*" -not -path "*/archive/*" -type f -exec grep -l "^language: ru" {} \; 2>/dev/null)
RU_COUNT=$(echo "$RU_FILES" | wc -l | tr -d ' ')
echo "Found $RU_COUNT Russian files to move"
echo ""

# Step 3: Create directory structure and move English files
echo "Step 3: Moving English files to docs/en/..."
MOVED_EN=0
while IFS= read -r file; do
    if [ -n "$file" ]; then
        # Calculate target path: docs/something.md -> docs/en/something.md
        # or docs/folder/file.md -> docs/en/folder/file.md
        rel_path=${file#docs/}
        target="docs/en/$rel_path"
        target_dir=$(dirname "$target")

        # Create directory if it doesn't exist
        mkdir -p "$target_dir"

        # Move file using git mv
        if [ -f "$file" ]; then
            echo "  Moving: $file -> $target"
            git mv "$file" "$target"
            MOVED_EN=$((MOVED_EN + 1))
        fi
    fi
done <<< "$EN_FILES"
echo "Moved $MOVED_EN English files"
echo ""

# Step 4: Create directory structure and move Russian files
echo "Step 4: Moving Russian files to docs/ru/..."
MOVED_RU=0
while IFS= read -r file; do
    if [ -n "$file" ]; then
        # Calculate target path
        rel_path=${file#docs/}
        target="docs/ru/$rel_path"
        target_dir=$(dirname "$target")

        # Create directory if it doesn't exist
        mkdir -p "$target_dir"

        # Move file using git mv
        if [ -f "$file" ]; then
            echo "  Moving: $file -> $target"
            git mv "$file" "$target"
            MOVED_RU=$((MOVED_RU + 1))
        fi
    fi
done <<< "$RU_FILES"
echo "Moved $MOVED_RU Russian files"
echo ""

# Step 5: Move archive folder to docs/ru/
echo "Step 5: Moving archive folder to docs/ru/..."
if [ -d "docs/archive" ]; then
    if [ -d "docs/ru/archive" ]; then
        echo "  Warning: docs/ru/archive already exists, merging..."
        # Move contents
        for item in docs/archive/*; do
            if [ -e "$item" ]; then
                basename_item=$(basename "$item")
                if [ ! -e "docs/ru/archive/$basename_item" ]; then
                    git mv "$item" "docs/ru/archive/"
                else
                    echo "  Skipping $item (already exists in target)"
                fi
            fi
        done
        # Remove empty archive dir if possible
        rmdir docs/archive 2>/dev/null || echo "  Note: docs/archive not empty, manual cleanup needed"
    else
        git mv docs/archive docs/ru/archive
        echo "  Moved docs/archive -> docs/ru/archive"
    fi
else
    echo "  No docs/archive folder found"
fi
echo ""

# Step 6: Create new landing page
echo "Step 6: Creating new landing page..."
if [ -f "docs/index.md" ]; then
    # Backup existing index
    echo "  Backing up existing docs/index.md to docs/index.md.backup"
    cp docs/index.md docs/index.md.backup
fi

cat > docs/index.md << 'EOF'
---
language: en
translation_status: original
doc_version: '2025.11'
last_updated: '2025-12-10'
---

# ERNI-KI Documentation

Select your language:

- [Русский (Russian)](ru/index.md) - Canonical source
- [English](en/index.md)
- [Deutsch (German)](de/index.md)

## About

ERNI-KI is a comprehensive knowledge and intelligence platform. This documentation is available in multiple languages. Russian is the canonical source, with English and German translations available.
EOF

echo "  Created new docs/index.md with language selector"
echo ""

# Step 7: Validation
echo "=== Validation ==="
echo ""

echo "Checking for remaining files in root (except index.md)..."
REMAINING=$(find docs -maxdepth 1 -name "*.md" | grep -v index.md | wc -l | tr -d ' ')
if [ "$REMAINING" -eq "0" ]; then
    echo "  ✓ No content files remaining in root"
else
    echo "  ⚠ Found $REMAINING files still in root:"
    find docs -maxdepth 1 -name "*.md" | grep -v index.md
fi
echo ""

echo "Checking for mixed languages in locale folders..."
EN_RU_FILES=$(find docs/en -name "*.md" -exec grep -l "^language: ru" {} \; 2>/dev/null | wc -l | tr -d ' ')
RU_EN_FILES=$(find docs/ru -name "*.md" -exec grep -l "^language: en" {} \; 2>/dev/null | wc -l | tr -d ' ')

if [ "$EN_RU_FILES" -eq "0" ]; then
    echo "  ✓ No Russian files in docs/en/"
else
    echo "  ⚠ Found $EN_RU_FILES Russian files in docs/en/"
fi

if [ "$RU_EN_FILES" -eq "0" ]; then
    echo "  ✓ No English files in docs/ru/"
else
    echo "  ⚠ Found $RU_EN_FILES English files in docs/ru/"
fi
echo ""

echo "=== Migration Summary ==="
echo "English files moved: $MOVED_EN"
echo "Russian files moved: $MOVED_RU"
echo "Archive folder: $([ -d docs/ru/archive ] && echo 'Moved' || echo 'Not found')"
echo "Landing page: Created"
echo ""
echo "=== Next Steps ==="
echo "1. Review git status to verify all moves"
echo "2. Check for broken links (separate task)"
echo "3. Update mkdocs.yml (separate task)"
echo "4. Commit changes when ready"
echo ""
