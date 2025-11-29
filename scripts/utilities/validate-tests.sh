#!/bin/bash
set -euo pipefail

# Test Validation Script for ERNI-KI
# Validates test structure and coverage

echo "🔍 Validating test infrastructure..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

# Check test directories exist
echo "📁 Checking test directory structure..."
required_dirs=(
    "tests/unit"
    "tests/integration/bats"
    "tests/e2e"
    "tests/python"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $dir exists"
    else
        echo -e "${RED}✗${NC} $dir missing"
        ((errors++))
    fi
done

# Check test files exist
echo -e "\n📝 Checking test files..."

# Python tests
python_tests=(
    "tests/python/test_webhook_handler.py"
    "tests/python/test_webhook_receiver.py"
    "tests/python/test_exporters.py"
    "tests/python/test_docs_scripts.py"
)

for test in "${python_tests[@]}"; do
    if [ -f "$test" ]; then
        echo -e "${GREEN}✓${NC} $test exists"
    else
        echo -e "${YELLOW}⚠${NC} $test missing"
        ((warnings++))
    fi
done

# TypeScript tests
ts_tests=(
    "tests/unit/docker-tags.test.ts"
    "tests/unit/language-check.test.ts"
    "tests/unit/mock-env.test.ts"
    "tests/unit/test-utils.test.ts"
    "tests/unit/test-docker-tags-extended.test.ts"
    "tests/unit/test-language-check-extended.test.ts"
    "tests/unit/test-mock-env-extended.test.ts"
    "tests/unit/test-ci-validation.test.ts"
)

for test in "${ts_tests[@]}"; do
    if [ -f "$test" ]; then
        echo -e "${GREEN}✓${NC} $test exists"
    else
        echo -e "${YELLOW}⚠${NC} $test missing"
        ((warnings++))
    fi
done

# BATS tests
bats_tests=(
    "tests/integration/bats/test_common_lib.bats"
    "tests/integration/bats/test_health_monitor.bats"
    "tests/integration/bats/test_docker_tags_validation.bats"
    "tests/integration/bats/test_nginx_healthcheck.bats"
)

for test in "${bats_tests[@]}"; do
    if [ -f "$test" ]; then
        echo -e "${GREEN}✓${NC} $test exists"
    else
        echo -e "${YELLOW}⚠${NC} $test missing"
        ((warnings++))
    fi
done

# Go tests
if [ -f "auth/main_test.go" ]; then
    test_count=$(grep -c "^func Test" auth/main_test.go || true)
    echo -e "${GREEN}✓${NC} auth/main_test.go exists ($test_count test functions)"
else
    echo -e "${RED}✗${NC} auth/main_test.go missing"
    ((errors++))
fi

# Check test configuration
echo -e "\n⚙️  Checking test configuration..."

if [ -f "vitest.config.ts" ]; then
    echo -e "${GREEN}✓${NC} vitest.config.ts exists"
else
    echo -e "${RED}✗${NC} vitest.config.ts missing"
    ((errors++))
fi

if [ -f "playwright.config.ts" ]; then
    echo -e "${GREEN}✓${NC} playwright.config.ts exists"
else
    echo -e "${RED}✗${NC} playwright.config.ts missing"
    ((errors++))
fi

if [ -f "tests/setup.ts" ]; then
    echo -e "${GREEN}✓${NC} tests/setup.ts exists"
else
    echo -e "${YELLOW}⚠${NC} tests/setup.ts missing"
    ((warnings++))
fi

# Summary
echo -e "\n📊 Validation Summary:"
echo -e "   Errors:   $errors"
echo -e "   Warnings: $warnings"

if [ $errors -eq 0 ]; then
    echo -e "\n${GREEN}✅ Test infrastructure validation passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Test infrastructure validation failed with $errors errors${NC}"
    exit 1
fi