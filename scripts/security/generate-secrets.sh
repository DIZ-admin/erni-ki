#!/usr/bin/env bash
set -euo pipefail

# Generate secure random secrets for ERNI-KI
# Part of ERNI-KI security hardening
# Reference: docs/security/secrets-audit-2025-11-27.md

log() {
  echo "[generate-secrets] $*" >&2
}

generate_secret() {
  local name=$1
  local length=${2:-32}
  local file="secrets/${name}.txt"

  if [[ -f "$file" ]]; then
    read -rp "⚠️  $file already exists. Overwrite? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      log "Skipped: $name"
      return
    fi
  fi

  # Generate cryptographically secure random bytes
  openssl rand -base64 "$length" | tr -d '\n' > "$file"
  chmod 600 "$file"

  log "✅ Generated: $file (${length} bytes)"
}

main() {
  log "ERNI-KI Secret Generation Tool"
  log "================================"
  log ""

  if [[ ! -d "secrets" ]]; then
    log "Error: secrets/ directory not found"
    log "Run this script from project root"
    exit 1
  fi

  log "Generating secrets..."
  log ""

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

  log ""
  log "✅ Secret generation complete"
  log ""
  log "Next steps:"
  log "1. Update services with new secrets"
  log "2. Restart affected services"
  log "3. Verify functionality"
  log "4. Document rotation in secrets-rotation-log.txt"
}

main "$@"
