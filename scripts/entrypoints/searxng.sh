#!/usr/bin/env bash
# =============================================================================
# SearXNG entrypoint - loads secrets and configures Redis/Valkey URL
# =============================================================================
set -euo pipefail

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets.sh
if [[ -f /opt/erni/lib/secrets.sh ]]; then
  source /opt/erni/lib/secrets.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[searxng] $*" >&2; }
  log_warn() { echo "[searxng] WARNING: $*" >&2; }
  read_secret() {
    local secret_file="/run/secrets/$1"
    [[ -f "$secret_file" ]] && tr -d '\r\n' < "$secret_file" && return 0
    return 1
  }
fi

__SCRIPT_NAME="searxng"

configure_redis_url() {
  local host="${SEARXNG_REDIS_HOST:-redis}"
  local port="${SEARXNG_REDIS_PORT:-6379}"
  # Redis Database Allocation (2025-12-02):
  # DB 0: SearXNG (cache, limiter, bot detection)
  # DB 1: Reserved for future use
  # DB 2: LiteLLM (model caching - when enabled)
  # DB 3-15: Available
  local db="${SEARXNG_REDIS_DB:-0}"
  local username="${SEARXNG_REDIS_USER:-searxng}"
  local password

  if password="$(read_secret "redis_password")"; then
    # URL format with username for ACL: redis://username:password@host:port/db  # pragma: allowlist secret
    local valkey_url="redis://${username}:${password}@${host}:${port}/${db}"  # pragma: allowlist secret
    # Only export SEARXNG_VALKEY_URL to avoid deprecation warning
    # (SearXNG warns if SEARXNG_REDIS_URL is set)
    export SEARXNG_VALKEY_URL="${valkey_url}"
    log "Valkey URL configured for user ${username} on ${host}:${port}/${db}"
    return
  fi

  log_warn "redis_password secret missing; using host=${host} port=${port} db=${db} (will fail if requirepass is enabled)"
  export SEARXNG_VALKEY_URL="${SEARXNG_VALKEY_URL:-redis://${host}:${port}/${db}}"  # pragma: allowlist secret
}

configure_searxng_secret() {
  local secret
  if secret="$(read_secret "searxng_secret_key")"; then
    export SEARXNG_SECRET="${secret}"
    log "Applied SEARXNG_SECRET from docker secret"
  else
    log_warn "searxng_secret_key secret missing; SEARXNG_SECRET not set"
  fi
}

main() {
  configure_searxng_secret
  configure_redis_url

  if [[ $# -gt 0 ]]; then
    log "Executing: $*"
    exec "$@"
  fi

  if [[ -x "/usr/local/searxng/entrypoint.sh" ]]; then
    log "Calling original SearXNG entrypoint"
    exec /usr/local/searxng/entrypoint.sh "$@"
  fi

  log "Falling back to uwsgi"
  exec uwsgi --ini /etc/searxng/uwsgi.ini
}

main "$@"
