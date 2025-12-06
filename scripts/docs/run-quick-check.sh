#!/bin/bash
# Quick documentation checks (faster subset for pre-commit)

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================================================================================"
echo "🚀 QUICK DOCUMENTATION CHECK"
echo "======================================================================================================"
echo ""

FAILED=0

# 1. Check modified files for frontmatter
echo "▶ Checking frontmatter in modified files..."
MODIFIED_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep '\.md$' || true)
if [ -n "$MODIFIED_FILES" ]; then
    for file in $MODIFIED_FILES; do
        if [ -f "$file" ]; then
            if ! head -1 "$file" | grep -q "^---$"; then
                echo -e "${RED}❌ Missing frontmatter: $file${NC}"
                FAILED=1
            fi
        fi
    done
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ Frontmatter check passed${NC}"
    fi
else
    echo "No markdown files modified"
fi

# 2. Quick markdown lint on modified files
if [ -n "$MODIFIED_FILES" ]; then
    echo ""
    echo "▶ Linting modified markdown files..."
    if markdownlint --config .markdownlint.json $MODIFIED_FILES 2>/dev/null; then
        echo -e "${GREEN}✅ Markdown lint passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Markdown lint found issues (can be auto-fixed with --fix)${NC}"
    fi
fi

# 3. Check for common mistakes
echo ""
echo "▶ Checking for common mistakes..."
MISTAKES=0

# Check for hardcoded localhost URLs
if echo "$MODIFIED_FILES" | xargs grep -n "http://localhost" 2>/dev/null | grep -v -e "example" -e "code" -e "\`\`\`"; then
    echo -e "${YELLOW}⚠️  Found hardcoded localhost URLs${NC}"
    ((MISTAKES++))
fi

# Check for TODO/FIXME without pragma
if echo "$MODIFIED_FILES" | xargs grep -n "TODO\|FIXME" 2>/dev/null | grep -v -e "pragma" -e "example" -e "\`\`\`"; then
    echo -e "${YELLOW}⚠️  Found TODO/FIXME without pragma${NC}"
    ((MISTAKES++))
fi

if [ $MISTAKES -eq 0 ]; then
    echo -e "${GREEN}✅ No common mistakes found${NC}"
fi

echo ""
echo "======================================================================================================"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Quick check FAILED${NC}"
    echo "Fix the issues above before committing."
    exit 1
else
    echo -e "${GREEN}✅ Quick check PASSED${NC}"
    echo "Run 'bash scripts/docs/run-local-audit.sh' for full validation."
    exit 0
fi
