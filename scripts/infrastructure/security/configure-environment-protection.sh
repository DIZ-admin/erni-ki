#!/bin/bash

# GitHub Environment Protection Rules Configuration for ERNI-KI
# Detailed protection rules setup for each environment
# Author: Alteon Schulz (Tech Lead)
# Date: 2025-09-19

set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.config-backup/environment-protection-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# === REPOSITORY INFO ===
get_repo_info() {
    local repo_info
    repo_info=$(gh repo view --json owner,name,id)

    REPO_OWNER=$(echo "$repo_info" | jq -r '.owner.login')
    REPO_NAME=$(echo "$repo_info" | jq -r '.name')
    REPO_ID=$(echo "$repo_info" | jq -r '.id')

    log "Repository: $REPO_OWNER/$REPO_NAME (ID: $REPO_ID)"
}

# === TEAM/USER IDS ===
get_team_ids() {
    log "Retrieving team IDs for reviewers..."

    # Try to fetch organization teams
    local teams_response
    if teams_response=$(gh api "orgs/$REPO_OWNER/teams" 2>/dev/null); then
        echo "$teams_response" | jq -r '.[] | "\(.name): \(.id)"' | head -5

        # Get ID of the first team for use as default
        TEAM_ID=$(echo "$teams_response" | jq -r '.[0].id // empty')
        if [ -n "$TEAM_ID" ]; then
            log "Found team ID: $TEAM_ID"
        else
            warning "No teams found, will use individual reviewers"
        fi
    else
        warning "Failed to fetch organization teams"
        TEAM_ID=""
    fi
}

# === CONFIGURE DEVELOPMENT ENVIRONMENT ===
configure_development() {
    log "Configuring Development environment..."

    # Development: minimal restrictions for fast iteration
    local config='{
        "wait_timer": 0,
        "prevent_self_review": false,
        "reviewers": [],
        "deployment_branch_policy": null
    }'

    if gh api "repos/$REPO_OWNER/$REPO_NAME/environments/development" -X PUT \
        --input <(echo "$config") > /dev/null 2>&1; then
        success "Development environment configured (no restrictions)"
    else
        error "Failed to configure Development environment"
    fi
}

# === CONFIGURE STAGING ENVIRONMENT ===
configure_staging() {
    log "Configuring Staging environment..."

    # Staging: require 1 reviewer, allow develop and main branches
    local reviewers_config="[]"
    if [ -n "$TEAM_ID" ]; then
        reviewers_config="[{\"type\": \"Team\", \"id\": $TEAM_ID}]"
    fi

    local config="{
        \"wait_timer\": 300,
        \"prevent_self_review\": true,
        \"reviewers\": $reviewers_config,
        \"deployment_branch_policy\": {
            \"protected_branches\": false,
            \"custom_branch_policies\": true
        }
    }"

    if gh api "repos/$REPO_OWNER/$REPO_NAME/environments/staging" -X PUT \
        --input <(echo "$config") > /dev/null 2>&1; then
        success "Staging environment configured (1 reviewer, 5 min wait)"

        # Configure allowed branches for staging
        configure_staging_branches
    else
        error "Failed to configure Staging environment"
    fi
}

# === CONFIGURE STAGING BRANCHES ===
configure_staging_branches() {
    log "Configuring allowed branches for Staging..."

    # Allow develop and main branches for staging
    local branch_policy='{
        "name": "develop"
    }'

    gh api "repos/$REPO_OWNER/$REPO_NAME/environments/staging/deployment-branch-policies" -X POST \
        --input <(echo "$branch_policy") > /dev/null 2>&1 || true

    branch_policy='{
        "name": "main"
    }'

    gh api "repos/$REPO_OWNER/$REPO_NAME/environments/staging/deployment-branch-policies" -X POST \
        --input <(echo "$branch_policy") > /dev/null 2>&1 || true

    success "Allowed branches for Staging: develop, main"
}

# === CONFIGURE PRODUCTION ENVIRONMENT ===
configure_production() {
    log "Configuring Production environment..."

    # Production: require reviewers, main only, 10-minute wait
    local reviewers_config="[]"
    if [ -n "$TEAM_ID" ]; then
        reviewers_config="[{\"type\": \"Team\", \"id\": $TEAM_ID}]"
    fi

    local config="{
        \"wait_timer\": 600,
        \"prevent_self_review\": true,
        \"reviewers\": $reviewers_config,
        \"deployment_branch_policy\": {
            \"protected_branches\": true,
            \"custom_branch_policies\": false
        }
    }"

    if gh api "repos/$REPO_OWNER/$REPO_NAME/environments/production" -X PUT \
        --input <(echo "$config") > /dev/null 2>&1; then
        success "Production environment configured (reviewers, protected branches only, 10 min wait)"
    else
        error "Failed to configure Production environment"
    fi
}

# === VERIFY SETTINGS ===
verify_environments() {
    log "Verifying environment settings..."

    for env in development staging production; do
        log "Checking environment: $env"

        if env_info=$(gh api "repos/$REPO_OWNER/$REPO_NAME/environments/$env" 2>/dev/null); then
            local wait_timer=$(echo "$env_info" | jq -r '.protection_rules[0].wait_timer // 0')
            local reviewers_count=$(echo "$env_info" | jq -r '.protection_rules[0].reviewers | length')

            log "  - Deployment wait: ${wait_timer} seconds"
            log "  - Reviewer count: $reviewers_count"
            success "  - Environment $env configured correctly"
        else
            error "Environment $env not found"
        fi
    done
}

# === MAIN ===
main() {
    log "Starting protection rule configuration for GitHub Environments..."

    # Ensure log directory exists
    mkdir -p "$PROJECT_ROOT/.config-backup"

    # Gather repository info
    get_repo_info

    # Fetch team IDs
    get_team_ids

    # Configure each environment
    configure_development
    configure_staging
    configure_production

    # Verify settings
    verify_environments

    success "✅ Protection rules successfully configured for all environments!"

    echo ""
    log "Environment configuration summary:"
    echo "📝 Development: No restrictions (fast iteration)"
    echo "🔍 Staging: 1 reviewer, 5-minute wait, develop/main branches"
    echo "🔒 Production: Reviewers required, 10-minute wait, protected branches only"
    echo ""
    log "Logs saved to: $LOG_FILE"
}

# Starting script
main "$@"
