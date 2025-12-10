#!/bin/bash

# Migrate remaining files in deep folder structures

set -e
cd "/Users/kostas/Documents/Projects/erni-ki-1"

echo "=== Migrating Deep Folder Files ==="
echo ""

# Find ALL remaining markdown files outside locale folders
ALL_FILES=$(find docs -name "*.md" -not -path "*/ru/*" -not -path "*/de/*" -not -path "*/en/*" -not -name "index.md" -not -path "*/javascripts/*" -not -path "*/stylesheets/*" -type f)

echo "Found remaining files to process..."
echo ""

MOVED_EN=0
MOVED_RU=0
MOVED_DE=0
SKIPPED=0

while IFS= read -r file; do
    if [ -n "$file" ] && [ -f "$file" ]; then
        # Get language from frontmatter
        lang=$(head -10 "$file" | grep "^language:" | head -1 | sed 's/language: //' | tr -d ' ')

        if [ -z "$lang" ]; then
            echo "⚠ No language found: $file"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        # Calculate target path
        rel_path=${file#docs/}
        target="docs/$lang/$rel_path"
        target_dir=$(dirname "$target")

        # Create directory
        mkdir -p "$target_dir"

        # Check if target exists
        if [ -f "$target" ]; then
            if diff -q "$file" "$target" > /dev/null 2>&1; then
                echo "Duplicate: $file (removing)"
                git rm "$file"
                SKIPPED=$((SKIPPED + 1))
            else
                echo "⚠ Conflict: $file differs from $target"
                echo "  Moving with .new suffix"
                git mv "$file" "${target}.new"
            fi
        else
            echo "Moving [$lang]: $file -> $target"
            git mv "$file" "$target"

            case "$lang" in
                en) MOVED_EN=$((MOVED_EN + 1)) ;;
                ru) MOVED_RU=$((MOVED_RU + 1)) ;;
                de) MOVED_DE=$((MOVED_DE + 1)) ;;
            esac
        fi
    fi
done <<< "$ALL_FILES"

echo ""
echo "=== Summary ==="
echo "Moved to docs/en/: $MOVED_EN"
echo "Moved to docs/ru/: $MOVED_RU"
echo "Moved to docs/de/: $MOVED_DE"
echo "Skipped/duplicates: $SKIPPED"
echo ""

# Remove empty directories
echo "Cleaning up empty directories..."
find docs -type d -empty -not -path "*/\.*" -delete 2>/dev/null || true
echo "✓ Done"
