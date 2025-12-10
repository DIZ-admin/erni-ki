#!/bin/bash

# Phase 2A: Migrate Russian files (with duplicate handling)

set -e  # Exit on error

DOCS_DIR="/Users/kostas/Documents/Projects/erni-ki-1/docs"
cd "$DOCS_DIR/.."

echo "=== Migrating Russian Files to docs/ru/ ==="
echo ""

# Find all Russian files still in root
RU_FILES=$(find docs -maxdepth 3 -name "*.md" -not -path "*/ru/*" -not -path "*/de/*" -not -path "*/en/*" -not -path "*/archive/*" -type f -exec grep -l "^language: ru" {} \; 2>/dev/null)
RU_COUNT=$(echo "$RU_FILES" | grep -c . || echo 0)

echo "Found $RU_COUNT Russian files to migrate"
echo ""

MOVED=0
SKIPPED=0
CONFLICTS=0

while IFS= read -r file; do
    if [ -n "$file" ] && [ -f "$file" ]; then
        # Calculate target path
        rel_path=${file#docs/}
        target="docs/ru/$rel_path"
        target_dir=$(dirname "$target")

        # Create directory if it doesn't exist
        mkdir -p "$target_dir"

        # Check if target already exists
        if [ -f "$target" ]; then
            # Compare files to see if they're identical
            if diff -q "$file" "$target" > /dev/null 2>&1; then
                echo "  Duplicate (identical): $file -> removing source only"
                git rm "$file"
                SKIPPED=$((SKIPPED + 1))
            else
                echo "  ⚠ CONFLICT: $file differs from $target"
                echo "    Keeping both, manual review needed"
                # Rename source to .conflict for manual review
                git mv "$file" "${file%.md}.conflict.md"
                CONFLICTS=$((CONFLICTS + 1))
            fi
        else
            echo "  Moving: $file -> $target"
            git mv "$file" "$target"
            MOVED=$((MOVED + 1))
        fi
    fi
done <<< "$RU_FILES"

echo ""
echo "=== Summary ==="
echo "Moved: $MOVED files"
echo "Duplicates removed: $SKIPPED files"
echo "Conflicts (needs review): $CONFLICTS files"
echo ""

if [ "$CONFLICTS" -gt 0 ]; then
    echo "⚠ Please review the following conflict files:"
    find docs -name "*.conflict.md" 2>/dev/null || true
    echo ""
fi
