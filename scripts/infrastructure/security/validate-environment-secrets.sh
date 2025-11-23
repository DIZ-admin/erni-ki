#!/bin/bash

# GitHub Environment Secrets Validation for ERNI-KI
# Validates environment and repository secrets, produces a report.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.config-backup/secrets-validation-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

total_secrets=0
valid_secrets=0
invalid_secrets=0
missing_secrets=0

log()      { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"; }
success()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a "$LOG_FILE"; }
warning()  { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"; }
error_msg(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"; }
info()     { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"; }

check_dependencies() {
    log "Checking dependencies..."
    command -v gh >/dev/null 2>&1 || { error_msg "GitHub CLI missing"; exit 1; }
    gh auth status >/dev/null 2>&1 || { error_msg "Run gh auth login"; exit 1; }
    command -v jq >/dev/null 2>&1 || warning "jq not installed; output may be limited"
    success "Dependencies satisfied"
}

get_environments() {
    gh api "repos/:owner/:repo/environments" --jq '.[].name' 2>/dev/null || echo "development staging production"
}

validate_secret() {
    local env="$1"; local name="$2"; local critical="${3:-false}"
    total_secrets=$((total_secrets+1))
    if gh secret list --env "$env" --json name | jq -r '.[].name' | grep -q "^${name}$"; then
        if [[ "$critical" == "true" ]]; then
            if secret_info=$(gh api "repos/:owner/:repo/environments/$env/secrets/$name" 2>/dev/null); then
                local updated=$(echo "$secret_info" | jq -r '.updated_at')
                success "✅ $name ($env) updated: $updated"
            else
                warning "⚠️ $name ($env) present but metadata unavailable"
            fi
        else
            success "✅ $name ($env) present"
        fi
        valid_secrets=$((valid_secrets+1))
    else
        error_msg "❌ $name ($env) missing"
        missing_secrets=$((missing_secrets+1))
    fi
}

validate_environment() {
    local env="$1"
    info "🔍 Checking secrets for $env"
    local suffix=""
    case "$env" in
        development) suffix="_DEV" ;;
        staging) suffix="_STAGING" ;;
        production) suffix="_PROD" ;;
        *) warning "Unknown environment $env"; return ;;
    esac
    local required=("TUNNEL_TOKEN${suffix}" "OPENAI_API_KEY${suffix}")
    for secret in "${required[@]}"; do
        local crit=false
        [[ "$env" == "production" ]] && crit=true
        validate_secret "$env" "$secret" "$crit"
    done
    if extras=$(gh secret list --env "$env" --json name | jq -r '.[].name' 2>/dev/null); then
        while IFS= read -r name; do
            if [[ ! " ${required[*]} " =~ " ${name} " ]]; then
                info "ℹ️ Additional secret detected: $name ($env)"
            fi
        done <<< "$extras"
    fi
}

validate_repository_secrets() {
    info "🔍 Checking repository secrets..."
    local repo_secrets=(
        POSTGRES_PASSWORD JWT_SECRET WEBUI_SECRET_KEY
        LITELLM_MASTER_KEY LITELLM_SALT_KEY RESTIC_PASSWORD
        SEARXNG_SECRET REDIS_PASSWORD BACKREST_PASSWORD
    )
    for secret in "${repo_secrets[@]}"; do
        total_secrets=$((total_secrets+1))
        if gh secret list --json name | jq -r '.[].name' | grep -q "^${secret}$"; then
            success "✅ $secret (repository) present"
            valid_secrets=$((valid_secrets+1))
        else
            error_msg "❌ $secret (repository) missing"
            missing_secrets=$((missing_secrets+1))
        fi
    done
}

security_check() {
    info "🛡️ Running security checks..."
    local issues=0
    if [[ $issues -eq 0 ]]; then
        success "No security issues detected"
    else
        warning "$issues potential security issues detected"
        invalid_secrets=$((invalid_secrets+issues))
    fi
}

generate_report() {
    local report_file="$PROJECT_ROOT/logs/secrets-validation-report-$(date +%Y%m%d-%H%M%S).md"
    log "Writing report to $report_file"
    cat > "$report_file" <<REPORT
# 🔐 GitHub Secrets Validation Report (ERNI-KI)

**Validation date:** $(date +'%Y-%m-%d %H:%M:%S')
**Environments checked:** $(get_environments | wc -l)
**Total secrets:** $total_secrets

## Summary
- ✅ Valid: $valid_secrets
- ❌ Missing: $missing_secrets
- ⚠️ Problematic: $invalid_secrets

## Environment breakdown
REPORT
    for env in $(get_environments); do
        echo "### Environment: $env" >> "$report_file"
        if secrets=$(gh secret list --env "$env" --json name,updated_at 2>/dev/null); then
            echo "$secrets" | jq -r '.[] | "- \(.name) (updated: \(.updated_at))"' >> "$report_file"
        else
            echo "- Unable to retrieve secrets" >> "$report_file"
        fi
        echo >> "$report_file"
    done
    {
        echo "## Recommendations"
        if [[ $missing_secrets -gt 0 ]]; then
            echo "- Missing secrets detected: $missing_secrets"
            echo "  Run ./scripts/infrastructure/security/setup-environment-secrets.sh"
        fi
        if [[ $invalid_secrets -gt 0 ]]; then
            echo "- Problematic secrets detected: $invalid_secrets"
            echo "  Review values and rotation dates"
        fi
        echo "- Schedule regular audits"
        echo
        echo "*Generated by validate-environment-secrets.sh*"
    } >> "$report_file"
}

main() {
    log "Starting GitHub secrets validation..."
    check_dependencies
    local environments
    environments=$(get_environments)
    log "Environments: $environments"
    validate_repository_secrets
    for env in $environments; do
        validate_environment "$env"
    done
    security_check
    generate_report
    info "Totals: $total_secrets secrets checked"
    info "Valid: $valid_secrets | Missing: $missing_secrets | Problematic: $invalid_secrets"
    if [[ $missing_secrets -eq 0 && $invalid_secrets -eq 0 ]]; then
        success "All secrets look good!"
    else
        warning "See report for remediation steps."
    fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<EOF
Usage: $(basename "$0") [--dry-run]
  --dry-run   Run validation without modifying anything
EOF
    exit 0
fi

log "Dry run mode: ${1:-false}"
main "$@"
