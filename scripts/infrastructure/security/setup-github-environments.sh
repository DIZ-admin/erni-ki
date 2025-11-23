#!/bin/bash

# GitHub Environments Setup for ERNI-KI
# Create and configure development, staging, production environments
# Author: Alteon Schultz (Tech Lead)
# Date: 2025-09-19

set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.config-backup/github-environments-setup-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === LOGGING HELPERS ===
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# === DEPENDENCY CHECK ===
check_dependencies() {
    log "Checking prerequisites..."

    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI not installed. Install from https://cli.github.com/"
    fi

    # Validate authentication
    if ! gh auth status &> /dev/null; then
        error "GitHub CLI not authenticated. Run: gh auth login"
    fi

    # Ensure we can access the repo
    local repo_info
    if ! repo_info=$(gh repo view --json owner,name 2>/dev/null); then
        error "Cannot access repository (run from repo root with appropriate rights)"
    fi

    local owner=$(echo "$repo_info" | jq -r '.owner.login')
    local repo=$(echo "$repo_info" | jq -r '.name')

    log "Repository: $owner/$repo"

    # Verify permissions
    if ! gh api "repos/$owner/$repo" --jq '.permissions.admin' | grep -q true; then
        warning "Admin permissions may be required to create environments."
    fi

    success "Dependency check complete"
}

# === ENVIRONMENT CREATION ===
create_environment() {
    local env_name="$1"
    local description="$2"

    log "Creating environment: $env_name"

    if gh api "repos/:owner/:repo/environments/$env_name" -X PUT \
        --field "wait_timer=0" \
        --field "prevent_self_review=false" \
        --field "reviewers=[]" \
        --field "deployment_branch_policy=null" > /dev/null 2>&1; then
        success "Environment $env_name created"
    else
        warning "Environment $env_name already exists or request failed"
    fi
}

# === PROTECTION RULES ===
setup_development_protection() {
    log "Setup protection rules for development..."

    # Development: no restrictions
    gh api "repos/:owner/:repo/environments/development" -X PUT \
        --field "wait_timer=0" \
        --field "prevent_self_review=false" \
        --field "reviewers=[]" \
        --field "deployment_branch_policy=null" > /dev/null

    success "Development protection configured (no restrictions)"
}

setup_staging_protection() {
    log "Setup protection rules for staging..."

    # Staging: require one reviewer
    gh api "repos/:owner/:repo/environments/staging" -X PUT \
        --field "wait_timer=0" \
        --field "prevent_self_review=true" \
        --field "reviewers=[{\"type\":\"Team\",\"id\":null}]" \
        --field "deployment_branch_policy=null" > /dev/null

    success "Staging protection configured (review required)"
}

setup_production_protection() {
    log "Setup protection rules for production..."

    # Production: require reviews and restrict to protected branches
    gh api "repos/:owner/:repo/environments/production" -X PUT \
        --field "wait_timer=0" \
        --field "prevent_self_review=true" \
        --field "reviewers=[{\"type\":\"Team\",\"id\":null}]" \
        --field "deployment_branch_policy={\"protected_branches\":true,\"custom_branch_policies\":false}" > /dev/null

    success "Production protection configured (review + main branch only)"
}

# === MAIN FLOW ===
main() {
    log "Starting GitHub environment configuration for ERNI-KI..."

    mkdir -p "$PROJECT_ROOT/.config-backup"

    check_dependencies

    create_environment "development" "Development environment for ERNI-KI"
    create_environment "staging" "Staging environment for ERNI-KI pre-production testing"
    create_environment "production" "Production environment for ERNI-KI live deployment"

    setup_development_protection
    setup_staging_protection
    setup_production_protection

    success "✅ GitHub environments configured!"

    echo ""
    log "Next steps:"
    echo "1. Add environment-specific secrets"
    echo "2. Update GitHub Actions workflows to reference environments"
    echo "3. Test deployments for each environment"
    echo ""
    log "Logs stored at: $LOG_FILE"
}

# Starting script
main "$@"
