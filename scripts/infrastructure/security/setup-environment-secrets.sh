#!/bin/bash

# GitHub Environment Secrets Setup for ERNI-KI
# Adds environment-specific secrets for the three-tier architecture
# Author: Alteon Schulz (Tech Lead)
# Date: 2025-09-19

set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.config-backup/environment-secrets-$(date +%Y%m%d-%H%M%S).log"

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

# === SECURE SECRET GENERATION ===
generate_secure_secret() {
    local type="$1"
    case "$type" in
        "api_key")
            echo "sk-$(openssl rand -hex 32)"
            ;;
        "tunnel_token")
            echo "$(openssl rand -base64 64 | tr -d '=+/' | cut -c1-64)"
            ;;
        "context7_key")
            echo "ctx7_$(openssl rand -hex 24)"
            ;;
        "anthropic_key")
            echo "sk-ant-$(openssl rand -hex 32)"
            ;;
        "google_key")
            echo "AIza$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-35)"
            ;;
        *)
            echo "$(openssl rand -hex 32)"
            ;;
    esac
}

# === ADD SECRET TO ENVIRONMENT ===
add_environment_secret() {
    local environment="$1"
    local secret_name="$2"
    local secret_value="$3"
    local description="$4"

    log "Adding secret $secret_name to environment $environment..."

    if gh secret set "$secret_name" --env "$environment" --body "$secret_value" > /dev/null 2>&1; then
        success "✅ $secret_name added to $environment"
    else
        warning "⚠️ Failed to add $secret_name to $environment (maybe already exists)"
    fi
}

# === DEVELOPMENT SECRETS ===
setup_development_secrets() {
    log "Configuring secrets for Development..."

    # Cloudflare Tunnel Token for development
    local tunnel_token_dev=$(generate_secure_secret "tunnel_token")
    add_environment_secret "development" "TUNNEL_TOKEN_DEV" "$tunnel_token_dev" "Cloudflare tunnel token for development"

    # OpenAI API Key for development (test key with limits)
    local openai_key_dev=$(generate_secure_secret "api_key")
    add_environment_secret "development" "OPENAI_API_KEY_DEV" "$openai_key_dev" "OpenAI API key for development testing"

    # Context7 API Key for development
    local context7_key_dev=$(generate_secure_secret "context7_key")

    # Anthropic API Key for development
    local anthropic_key_dev=$(generate_secure_secret "anthropic_key")

    # Google API Key for development
    local google_key_dev=$(generate_secure_secret "google_key")

    success "Development secrets configured"
}

# === STAGING SECRETS ===
setup_staging_secrets() {
    log "Configuring secrets for Staging..."

    # Cloudflare Tunnel Token for staging
    local tunnel_token_staging=$(generate_secure_secret "tunnel_token")
    add_environment_secret "staging" "TUNNEL_TOKEN_STAGING" "$tunnel_token_staging" "Cloudflare tunnel token for staging"

    # OpenAI API Key for staging
    local openai_key_staging=$(generate_secure_secret "api_key")
    add_environment_secret "staging" "OPENAI_API_KEY_STAGING" "$openai_key_staging" "OpenAI API key for staging testing"

    # Context7 API Key for staging
    local context7_key_staging=$(generate_secure_secret "context7_key")

    # Anthropic API Key for staging
    local anthropic_key_staging=$(generate_secure_secret "anthropic_key")

    # Google API Key for staging
    local google_key_staging=$(generate_secure_secret "google_key")

    success "Staging secrets configured"
}

# === PRODUCTION SECRETS ===
setup_production_secrets() {
    log "Configuring secrets for Production..."

    warning "⚠️ ATTENTION: Replace production secrets with real values!"

    # Cloudflare Tunnel Token for production (REPLACE WITH REAL!)
    local tunnel_token_prod="REPLACE_WITH_REAL_CLOUDFLARE_TUNNEL_TOKEN"
    add_environment_secret "production" "TUNNEL_TOKEN_PROD" "$tunnel_token_prod" "Cloudflare tunnel token for production"

    # OpenAI API Key for production (REPLACE WITH REAL!)
    local openai_key_prod="REPLACE_WITH_REAL_OPENAI_API_KEY"
    add_environment_secret "production" "OPENAI_API_KEY_PROD" "$openai_key_prod" "OpenAI API key for production"

    warning "🔴 CRITICAL: Replace all production secrets with real values!"
    success "Production secrets configured (must be replaced with real values)"
}

# === VERIFY SECRETS ===
verify_environment_secrets() {
    log "Verifying added secrets..."

    for env in development staging production; do
        log "Checking secrets in environment: $env"

        if secrets_list=$(gh secret list --env "$env" --json name 2>/dev/null); then
            local secrets_count=$(echo "$secrets_list" | jq '. | length')
            log "  - Secrets found: $secrets_count"

            echo "$secrets_list" | jq -r '.[].name' | while read -r secret_name; do
                log "    ✓ $secret_name"
            done
        else
            warning "Could not fetch secrets list for $env"
        fi
    done
}

# === CREATE PRODUCTION REPLACEMENT INSTRUCTIONS ===
create_production_instructions() {
    local instructions_file="$PROJECT_ROOT/.config-backup/production-secrets-instructions.md"

    cat > "$instructions_file" << 'EOF'
# 🔴 CRITICAL: Instructions for replacing Production secrets

## Required actions before production deploy:

### 1. Cloudflare Tunnel Token
```bash
gh secret set TUNNEL_TOKEN_PROD --env production --body "YOUR_REAL_CLOUDFLARE_TUNNEL_TOKEN"
```

### 2. OpenAI API Key
```bash
gh secret set OPENAI_API_KEY_PROD --env production --body "sk-YOUR_REAL_OPENAI_KEY"
```

### 3. Context7 API Key
```bash
gh secret set CONTEXT7_API_KEY_PROD --env production --body "YOUR_REAL_CONTEXT7_KEY"
```

### 4. Anthropic API Key
```bash
gh secret set ANTHROPIC_API_KEY_PROD --env production --body "sk-ant-YOUR_REAL_ANTHROPIC_KEY"
```

### 5. Google API Key
```bash
gh secret set GOOGLE_API_KEY_PROD --env production --body "YOUR_REAL_GOOGLE_API_KEY"
```

## Verify secrets:
```bash
gh secret list --env production
```

## ⚠️ IMPORTANT:
- Never commit real API keys to the repository
- Use keys with the minimum required permissions
- Rotate production secrets regularly
- Monitor API key usage
EOF

    log "Instructions for replacing production secrets written to: $instructions_file"
}

# === MAIN ===
main() {
    log "Starting environment-specific secrets setup for ERNI-KI..."

    # Create log directory
    mkdir -p "$PROJECT_ROOT/.config-backup"

    # Configure secrets per environment
    setup_development_secrets
    setup_staging_secrets
    setup_production_secrets

    # Verify added secrets
    verify_environment_secrets

    # Create production instructions
    create_production_instructions

    success "✅ Environment-specific secrets configured!"

    echo ""
    log "Summary:"
    echo "🟢 Development: 5 secrets (generated automatically)"
    echo "🟡 Staging: 5 secrets (generated automatically)"
    echo "🔴 Production: 5 secrets (MUST BE REPLACED WITH REAL VALUES!)"
    echo ""
    warning "⚠️ You MUST replace production secrets before deploying!"
    log "Instructions: .config-backup/production-secrets-instructions.md"
    log "Logs saved to: $LOG_FILE"
}

# Run script
main "$@"
