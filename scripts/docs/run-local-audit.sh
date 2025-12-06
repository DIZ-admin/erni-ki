#!/bin/bash
# Run local documentation audit with same settings as CI
# This ensures local checks match GitHub Actions workflows

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="${1:-docs}"
OUTPUT_DIR="docs/reports/audit-2025-12"

echo "======================================================================================================"
echo "📚 LOCAL DOCUMENTATION AUDIT"
echo "======================================================================================================"
echo ""
echo "This script runs the same checks as GitHub Actions workflows:"
echo "  - .github/workflows/docs-quality.yml"
echo "  - .github/workflows/nightly-audit.yml"
echo ""
echo "Configuration:"
echo "  Documentation directory: $DOCS_DIR"
echo "  Output directory: $OUTPUT_DIR"
echo ""
echo "======================================================================================================"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Track results
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

run_check() {
    local name="$1"
    local command="$2"
    local allow_failure="${3:-false}"

    echo ""
    echo "======================================================================================================"
    echo -e "${BLUE}▶ Running: $name${NC}"
    echo "======================================================================================================"
    echo ""

    ((CHECKS_TOTAL++))

    if eval "$command"; then
        echo -e "${GREEN}✅ PASSED: $name${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        if [ "$allow_failure" = "true" ]; then
            echo -e "${YELLOW}⚠️  WARNING: $name (allowed to fail)${NC}"
            ((CHECKS_WARNED++))
            return 0
        else
            echo -e "${RED}❌ FAILED: $name${NC}"
            ((CHECKS_FAILED++))
            return 1
        fi
    fi
}

# 1. Frontmatter Validation
run_check \
    "Frontmatter Validation" \
    "python3 scripts/docs/validate-frontmatter.py --docs-dir $DOCS_DIR --output $OUTPUT_DIR/frontmatter.json" \
    "true"

# 2. Markdown Linting
run_check \
    "Markdown Linting" \
    "markdownlint 'docs/**/*.md' --config .markdownlint.json --ignore 'docs/node_modules/**' --ignore 'docs/site/**' --ignore 'docs/.venv/**'" \
    "true"

# 3. YAML Frontmatter Linting
run_check \
    "YAML Frontmatter Linting" \
    "python3 -m yamllint $DOCS_DIR -f parsable -c .yamllint.yml" \
    "true"

# 4. Broken Links Check
run_check \
    "Broken Links Check" \
    "lychee --verbose --no-progress --max-redirects 5 --exclude-link-local --exclude 'localhost' --exclude '127\\.0\\.0\\.1' --exclude 'example\\.com' --exclude 'www\\.conventionalcommits\\.org' --exclude 'docs\\.pact\\.io' 'docs/**/*.md'" \
    "true"

# 5. Stale Documents Check
run_check \
    "Stale Documents Check (>90 days)" \
    "bash scripts/docs/check-stale-docs.sh $DOCS_DIR 90" \
    "true"

# 6. Translation Sync Check
run_check \
    "Translation Synchronization Check" \
    "bash scripts/docs/translation-sync-check.sh $DOCS_DIR" \
    "true"

# 7. MkDocs Build
run_check \
    "MkDocs Build" \
    "mkdocs build --site-dir site" \
    "false"

# Summary
echo ""
echo "======================================================================================================"
echo "📊 AUDIT SUMMARY"
echo "======================================================================================================"
echo ""
echo "Total checks: $CHECKS_TOTAL"
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNED${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -gt 0 ]; then
    echo -e "${RED}❌ AUDIT FAILED${NC}"
    echo ""
    echo "Some checks failed. Please review the output above and fix the issues."
    echo ""
    echo "Common fixes:"
    echo "  - Frontmatter: Add missing required fields (title, language, page_id, doc_version, translation_status)"
    echo "  - Markdown: Run 'markdownlint --fix docs/**/*.md' for auto-fixes"
    echo "  - Links: Update or remove broken links"
    echo "  - Stale docs: Review and update documentation older than 90 days"
    echo ""
    exit 1
elif [ $CHECKS_WARNED -gt 0 ]; then
    echo -e "${YELLOW}⚠️  AUDIT COMPLETED WITH WARNINGS${NC}"
    echo ""
    echo "All critical checks passed, but some warnings were found."
    echo "Review the warnings above and consider addressing them."
    echo ""
    exit 0
else
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo ""
    echo "Your documentation is in great shape!"
    echo ""
    exit 0
fi
