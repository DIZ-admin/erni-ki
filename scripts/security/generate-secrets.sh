#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# Generate secure random secrets for ERNI-KI
# Part of ERNI-KI security hardening
# Reference: docs/security/secrets-audit-2025-11-27.md

generate_secret() {
  local name=$1
  local length=${2:-32}
  local file="secrets/${name}.txt"

  if [[ -f "$file" ]]; then
    read -rp "⚠️  $file already exists. Overwrite? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      log_info "Skipped: $name"
      return
    fi
  fi

  # Generate cryptographically secure random bytes
  openssl rand -base64 "$length" | tr -d '\n' > "$file"
  chmod 600 "$file"

  log_info "✅ Generated: $file (${length} bytes)"
}

main() {
  log_info "ERNI-KI Secret Generation Tool"
  log_info "================================"
  log_info ""

  if [[ ! -d "secrets" ]]; then
    log_info "Error: secrets/ directory not found"
    log_info "Run this script from project root"
    exit 1
  fi

  log_info "Generating secrets..."
  log_info ""

  # Database secrets
  generate_secret "postgres_password" 32
  generate_secret "litellm_db_password" 32
  generate_secret "redis_password" 32

  # API keys
  generate_secret "litellm_master_key" 48
  generate_secret "litellm_salt_key" 48
  generate_secret "litellm_api_key" 64

  # Service secrets
  generate_secret "grafana_admin_password" 32
  generate_secret "openwebui_secret_key" 64
  generate_secret "context7_api_key" 32
  generate_secret "watchtower_api_token" 32

  log_info ""
  log_info "✅ Secret generation complete"
  log_info ""
  log_info "Next steps:"
  log_info "1. Update services with new secrets"
  log_info "2. Restart affected services"
  log_info "3. Verify functionality"
  log_info "4. Document rotation in secrets-rotation-log.txt"
}

main "$@"
