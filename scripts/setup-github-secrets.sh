#!/bin/bash
# GitHub Secrets Setup Helper for ERNI-KI Project
# Prerequisites: GitHub CLI (gh) installed and authenticated
#
# Usage:
#   1. Install GitHub CLI: https://cli.github.com/
#   2. Authenticate: gh auth login
#   3. Run this script: ./scripts/setup-github-secrets.sh
#
# See docs/guides/github-secrets-setup.md for detailed information

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitHub Secrets Setup for ERNI-KI${NC}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${YELLOW}This script will guide you through setting up GitHub Secrets${NC}"
echo -e "${YELLOW}See docs/guides/github-secrets-setup.md for details${NC}"
echo ""

# Function to set secret with confirmation
set_secret() {
    local name=$1
    local description=$2
    local example=$3
    local required=$4

    echo -e "\n${GREEN}Setting: ${name}${NC}"
    echo "Description: ${description}"
    echo "Example: ${example}"

    if [ "$required" = "required" ]; then
        echo -e "${RED}REQUIRED on main/develop branches${NC}"
    else
        echo -e "${YELLOW}Optional${NC}"
    fi

    read -p "Enter value (or press Enter to skip): " value

    if [ -z "$value" ]; then
        echo -e "${YELLOW}Skipped${NC}"
        return
    fi

    if gh secret set "$name" --body "$value"; then
        echo -e "${GREEN}✓ Successfully set ${name}${NC}"
    else
        echo -e "${RED}✗ Failed to set ${name}${NC}"
    fi
}

# Code Coverage
echo -e "\n${GREEN}=== 1. Code Coverage ===${NC}"
set_secret "CODECOV_TOKEN" \
    "Upload token from codecov.io" \
    "a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
    "optional"

# Contract Testing
echo -e "\n${GREEN}=== 2. Contract Testing ===${NC}"
set_secret "CONTRACT_BASE_URL" \
    "Base URL for contract testing API" \
    "https://api.staging.example.com" \
    "required"

set_secret "CONTRACT_BEARER_TOKEN" \
    "Bearer token for authenticated contract tests" \
    "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
    "required"

# Smoke Testing
echo -e "\n${GREEN}=== 3. Smoke Testing (k6) ===${NC}"
set_secret "SMOKE_BASE_URL" \
    "Base URL for k6 smoke tests" \
    "https://api.staging.example.com" \
    "required"

set_secret "SMOKE_AUTH_TOKEN" \
    "Authentication token for smoke tests" \
    "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
    "optional"

set_secret "SMOKE_AUTH_PATH" \
    "API path for authentication endpoint" \
    "/api/v1/auth/login" \
    "optional"

set_secret "SMOKE_RAG_PATH" \
    "API path for RAG endpoint testing" \
    "/api/v1/rag/query" \
    "optional"

set_secret "SMOKE_VUS" \
    "Number of virtual users for k6" \
    "10" \
    "optional"

set_secret "SMOKE_DURATION" \
    "Duration of k6 smoke test" \
    "1m" \
    "optional"

# Summary
echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "\nConfigured secrets:"
gh secret list

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Verify secrets in GitHub: Settings → Secrets and variables → Actions"
echo "2. Test CI workflows on a feature branch"
echo "3. Review docs/guides/github-secrets-setup.md for detailed information"
echo ""
