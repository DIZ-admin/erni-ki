#!/bin/bash

# Resolve conflict files by comparing with existing versions

set -e
cd "/Users/kostas/Documents/Projects/erni-ki-1"

echo "=== Resolving Conflict Files ==="
echo ""

# Function to handle a conflict file
handle_conflict() {
    local conflict_file="$1"
    local original_file="${conflict_file%.conflict.md}.md"

    # Determine target location based on language
    local lang=$(head -10 "$conflict_file" | grep "^language:" | head -1 | sed 's/language: //' | tr -d ' ')

    if [ -z "$lang" ]; then
        echo "⚠ Cannot determine language for $conflict_file"
        return
    fi

    # Calculate target path
    local rel_path="${conflict_file#docs/}"
    rel_path="${rel_path%.conflict.md}.md"
    local target="docs/${lang}/${rel_path}"

    # Check if target exists
    if [ -f "$target" ]; then
        # Compare files
        if diff -q "$conflict_file" "$target" > /dev/null 2>&1; then
            echo "✓ Duplicate: $conflict_file (removing)"
            git rm "$conflict_file"
        else
            echo "⚠ Different: $conflict_file vs $target"
            echo "  Conflict file: $(wc -l < "$conflict_file") lines"
            echo "  Target file:   $(wc -l < "$target") lines"
            echo "  Action: Keeping conflict for manual review"
        fi
    else
        # Target doesn't exist, move the conflict file
        local target_dir=$(dirname "$target")
        mkdir -p "$target_dir"
        echo "✓ Moving: $conflict_file -> $target"
        # Rename .conflict.md back to .md and move
        git mv "$conflict_file" "$target"
    fi
}

# Process all conflict files
for conflict in $(find docs -name "*.conflict.md"); do
    handle_conflict "$conflict"
    echo ""
done

echo "=== Remaining Conflicts ==="
REMAINING=$(find docs -name "*.conflict.md" 2>/dev/null | wc -l | tr -d ' ')
echo "Files requiring manual review: $REMAINING"

if [ "$REMAINING" -gt 0 ]; then
    echo ""
    echo "Please manually review and resolve:"
    find docs -name "*.conflict.md"
fi
