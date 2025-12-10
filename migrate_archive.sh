#!/bin/bash

# Migrate archive files by language

set -e

cd "/Users/kostas/Documents/Projects/erni-ki-1"

echo "=== Migrating Archive Files ==="
echo ""

# Find English files in archive
EN_ARCHIVE=$(find docs/archive -name "*.md" -exec grep -l "^language: en" {} \; 2>/dev/null)
EN_COUNT=$(echo "$EN_ARCHIVE" | grep -c . || echo 0)

echo "Found $EN_COUNT English files in archive"

# Find Russian files in archive
RU_ARCHIVE=$(find docs/archive -name "*.md" -exec grep -l "^language: ru" {} \; 2>/dev/null)
RU_COUNT=$(echo "$RU_ARCHIVE" | grep -c . || echo 0)

echo "Found $RU_COUNT Russian files in archive"
echo ""

# Move English archive files to docs/en/archive/
echo "Moving English archive files to docs/en/archive/..."
MOVED_EN=0
while IFS= read -r file; do
    if [ -n "$file" ] && [ -f "$file" ]; then
        rel_path=${file#docs/archive/}
        target="docs/en/archive/$rel_path"
        target_dir=$(dirname "$target")

        mkdir -p "$target_dir"

        if [ -f "$target" ]; then
            if diff -q "$file" "$target" > /dev/null 2>&1; then
                echo "  Duplicate: $file (removing)"
                git rm "$file"
            else
                echo "  Conflict: $file vs $target"
                git mv "$file" "${file%.md}.conflict.md"
            fi
        else
            echo "  Moving: $file -> $target"
            git mv "$file" "$target"
            MOVED_EN=$((MOVED_EN + 1))
        fi
    fi
done <<< "$EN_ARCHIVE"

echo "Moved $MOVED_EN English archive files"
echo ""

# Move Russian archive files to docs/ru/archive/
echo "Moving Russian archive files to docs/ru/archive/..."
MOVED_RU=0
SKIPPED_RU=0
while IFS= read -r file; do
    if [ -n "$file" ] && [ -f "$file" ]; then
        rel_path=${file#docs/archive/}
        target="docs/ru/archive/$rel_path"
        target_dir=$(dirname "$target")

        mkdir -p "$target_dir"

        if [ -f "$target" ]; then
            if diff -q "$file" "$target" > /dev/null 2>&1; then
                echo "  Duplicate: $file (removing)"
                git rm "$file"
                SKIPPED_RU=$((SKIPPED_RU + 1))
            else
                echo "  Conflict: $file vs $target"
                git mv "$file" "${file%.md}.conflict.md"
            fi
        else
            echo "  Moving: $file -> $target"
            git mv "$file" "$target"
            MOVED_RU=$((MOVED_RU + 1))
        fi
    fi
done <<< "$RU_ARCHIVE"

echo "Moved $MOVED_RU Russian archive files"
echo "Skipped $SKIPPED_RU duplicates"
echo ""

# Check if archive directory is now empty
if [ -d "docs/archive" ]; then
    REMAINING=$(find docs/archive -type f | wc -l | tr -d ' ')
    if [ "$REMAINING" -eq 0 ]; then
        echo "Archive directory is empty, removing..."
        rm -rf docs/archive
        echo "Removed docs/archive"
    else
        echo "⚠ Archive directory still has $REMAINING files"
    fi
fi

echo ""
echo "=== Archive Migration Complete ==="
