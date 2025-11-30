#!/usr/bin/env bash
set -euo pipefail

# Source environment validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
if [[ -f "$SCRIPT_DIR/functions/env-validator.sh" ]]; then
  source "$SCRIPT_DIR/functions/env-validator.sh"
fi

log() {
  echo "[searxng-entrypoint] $*" >&2
}

read_secret() {
  local secret_name="$1"
  local secret_file="/run/secrets/${secret_name}"

  if [[ -f "${secret_file}" ]]; then
    tr -d '\r' <"${secret_file}" | tr -d '\n'
    return 0
  fi

  return 1
}

configure_redis_url() {
  local host="${SEARXNG_REDIS_HOST:-redis}"
  local port="${SEARXNG_REDIS_PORT:-6379}"
  local db="${SEARXNG_REDIS_DB:-1}"
  local password

  if password="$(read_secret "redis_password")"; then
    export SEARXNG_REDIS_URL="redis://:${password}@${host}:${port}/${db}"
    return
  fi

  log "warning: redis_password secret missing; using SEARXNG_REDIS_URL=${SEARXNG_REDIS_URL:-redis://${host}:${port}/${db}} (will fail if requirepass is enabled)"
  export SEARXNG_REDIS_URL="${SEARXNG_REDIS_URL:-redis://${host}:${port}/${db}}"
}

validate_searxng_config() {
  log "Validating SearXNG configuration..."

  local errors=0

  # Check required URLs are set after configuration
  if [[ -z "${SEARXNG_REDIS_URL:-}" ]]; then
    log "ERROR: SEARXNG_REDIS_URL not set after configuration"
    ((errors++))
  fi

  # Validate Redis is reachable (warning only)
  if command -v validate_url &> /dev/null; then
    log "Checking service connectivity..."
    validate_url "http://redis:6379" "Redis" || true
  fi

  if [[ $errors -gt 0 ]]; then
    log "ERROR: Configuration validation failed with $errors error(s)"
    return 1
  fi

  log "✓ SearXNG configuration is valid"
  return 0
}

main() {
  configure_redis_url

  # Validate configuration
  if ! validate_searxng_config; then
    log "FATAL: Configuration validation failed"
    exit 1
  fi

  if [[ $# -gt 0 ]]; then
    exec "$@"
  fi

  if [[ -x "/usr/local/bin/docker-entrypoint.sh" ]]; then
    exec /usr/local/bin/docker-entrypoint.sh "$@"
  fi

  exec uwsgi --ini /etc/searxng/uwsgi.ini
}

main "$@"
