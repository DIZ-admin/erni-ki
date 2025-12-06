#!/bin/bash
# Check for stale documentation files (not modified in 90+ days)

set -euo pipefail

# Configuration
DOCS_DIR="${1:-docs}"
STALE_DAYS="${2:-90}"
EXCLUDE_PATTERNS=("archive" "node_modules" ".venv" "site")

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "======================================================================================================"
echo "STALE DOCUMENTATION CHECK"
echo "======================================================================================================"
echo ""
echo "Configuration:"
echo "  Documentation directory: $DOCS_DIR"
echo "  Stale threshold: $STALE_DAYS days"
echo "  Excluded patterns: ${EXCLUDE_PATTERNS[*]}"
echo ""

# Check if docs directory exists
if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}❌ Error: Documentation directory not found: $DOCS_DIR${NC}"
    exit 1
fi

# Build exclude pattern for find command
EXCLUDE_ARGS=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_ARGS+=(-not -path "*/$pattern/*")
done

# Find stale files
echo "Searching for stale documentation files..."
echo ""

STALE_FILES=$(find "$DOCS_DIR" -name "*.md" -type f "${EXCLUDE_ARGS[@]}" -mtime +"$STALE_DAYS" 2>/dev/null | sort || echo "")
TOTAL_FILES=$(find "$DOCS_DIR" -name "*.md" -type f "${EXCLUDE_ARGS[@]}" 2>/dev/null | wc -l | tr -d ' ')
if [ -z "$STALE_FILES" ]; then
    STALE_COUNT=0
else
    STALE_COUNT=$(echo "$STALE_FILES" | grep -c '^' || echo "0")
fi

# Calculate percentage
if [ "$TOTAL_FILES" -gt 0 ]; then
    STALE_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($STALE_COUNT / $TOTAL_FILES) * 100}")
else
    STALE_PERCENT="0.0"
fi

echo "======================================================================================================"
echo "SUMMARY"
echo "======================================================================================================"
echo ""
echo "Total documentation files: $TOTAL_FILES"
echo -e "Stale files (>$STALE_DAYS days): ${YELLOW}$STALE_COUNT${NC} (${STALE_PERCENT}%)"
echo ""

if [ "$STALE_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  STALE FILES FOUND${NC}"
    echo ""
    echo "The following files have not been modified in more than $STALE_DAYS days:"
    echo ""

    # Group by directory
    current_dir=""
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            dir=$(dirname "$file")
            if [ "$dir" != "$current_dir" ]; then
                echo ""
                echo "📁 $dir/"
                current_dir="$dir"
            fi

            # Get last modification date
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                mod_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$file")
                days_ago=$(( ($(date +%s) - $(stat -f "%m" "$file")) / 86400 ))
            else
                # Linux
                mod_date=$(stat -c "%y" "$file" | cut -d' ' -f1)
                days_ago=$(( ($(date +%s) - $(stat -c "%Y" "$file")) / 86400 ))
            fi

            filename=$(basename "$file")
            echo "  • $filename (last modified: $mod_date, $days_ago days ago)"
        fi
    done <<< "$STALE_FILES"

    echo ""
    echo "======================================================================================================"
    echo ""
    echo -e "${YELLOW}Recommendation:${NC}"
    echo "  Review these files for accuracy and update if necessary."
    echo "  Consider archiving files that are no longer relevant."
    echo ""

    # Set exit code based on percentage
    if (( $(echo "$STALE_PERCENT > 5.0" | bc -l) )); then
        echo -e "${RED}❌ FAILED: More than 5% of files are stale (${STALE_PERCENT}%)${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ WARNING: ${STALE_PERCENT}% of files are stale (threshold: 5%)${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✅ No stale files found!${NC}"
    echo ""
    echo "All documentation has been updated within the last $STALE_DAYS days."
    echo ""
    echo "======================================================================================================"
    exit 0
fi
