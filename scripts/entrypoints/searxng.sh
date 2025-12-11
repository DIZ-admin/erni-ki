#!/bin/sh
set -euo pipefail

# Debug: write to a file to verify script runs
echo "Script started at $(date)" > /tmp/searxng-entrypoint.log

log() {
  echo "[searxng-entrypoint] $*" >&2
  echo "[searxng-entrypoint] $*" >> /tmp/searxng-entrypoint.log
}

read_secret() {
  secret_name="$1"
  secret_file="/run/secrets/${secret_name}"

  if [ -f "${secret_file}" ]; then
    tr -d '\r' <"${secret_file}" | tr -d '\n'
    return 0
  fi

  return 1
}

configure_redis_url() {
  log "Configuring Redis URL..."
  host="${SEARXNG_REDIS_HOST:-redis}"
  port="${SEARXNG_REDIS_PORT:-6379}"
  # Redis Database Allocation (2025-12-02):
  # DB 0: SearXNG (cache, limiter, bot detection)
  # DB 1: Reserved for future use
  # DB 2: LiteLLM (model caching - when enabled)
  # DB 3-15: Available
  db="${SEARXNG_REDIS_DB:-0}"
  username="${SEARXNG_REDIS_USER:-searxng}"
  password=""

  log "Reading redis_password secret..."
  if password="$(read_secret "redis_password")"; then
    # URL format with username for ACL: redis://username:password@host:port/db  # pragma: allowlist secret
    redis_url="redis://${username}:${password}@${host}:${port}/${db}" # pragma: allowlist secret
    export SEARXNG_REDIS_URL="${redis_url}"
    export SEARXNG_VALKEY_URL="${redis_url}"
    log "Redis URL configured for user ${username} on ${host}:${port}/${db} (value not logged)"
    # Note: settings.yml already has correct URL with username
    return
  fi

  log "warning: redis_password secret missing; using host=${host} port=${port} db=${db} (URL value not logged; will fail if requirepass is enabled)"
  export SEARXNG_REDIS_URL="${SEARXNG_REDIS_URL:-redis://${host}:${port}/${db}}" # pragma: allowlist secret
  export SEARXNG_VALKEY_URL="${SEARXNG_VALKEY_URL:-redis://${host}:${port}/${db}}" # pragma: allowlist secret
}

validate_secret() {
  secret="$1"
  name="$2"

  # Check for empty or whitespace-only
  trimmed=$(printf '%s' "$secret" | tr -d '[:space:]')
  if [ -z "$trimmed" ]; then
    log "CRITICAL: ${name} is empty or contains only whitespace"
    return 1
  fi

  # Check minimum length (32 characters for cryptographic operations)
  if [ ${#trimmed} -lt 32 ]; then
    log "CRITICAL: ${name} is too short (${#trimmed} chars, minimum 32 required)"
    return 1
  fi

  # Check for common placeholder values
  case "$secret" in
    "CHANGE_BEFORE_GOING_LIVE"|"changeme"|"placeholder"|"your-"*|"example"*|"test"*|"secret"*|"password"*)
      log "CRITICAL: ${name} appears to be a placeholder value - please set a real secret"
      return 1
      ;;
  esac

  return 0
}

configure_searxng_secret() {
  # pragma: allowlist secret
  if secret="$(read_secret "searxng_secret_key")"; then
    if validate_secret "$secret" "SEARXNG_SECRET"; then  # pragma: allowlist secret
      export SEARXNG_SECRET="${secret}"
      log "Applied SEARXNG_SECRET from docker secret (value not logged)"
    else
      log "CRITICAL: Invalid SEARXNG_SECRET - container will exit"
      exit 1
    fi
  else
    log "warning: searxng_secret_key secret missing; SEARXNG_SECRET not set"
  fi
}

main() {
  log "Main function started with $# arguments"
  configure_searxng_secret
  configure_redis_url

  log "Configured SEARXNG_REDIS_URL and SEARXNG_VALKEY_URL environment variables (values not logged)"

  if [ $# -gt 0 ]; then
    log "Executing: $*"
    exec "$@"
  fi

  if [ -x "/usr/local/searxng/entrypoint.sh" ]; then
    log "Calling original SearXNG entrypoint"
    exec /usr/local/searxng/entrypoint.sh "$@"
  fi

  log "Falling back to uwsgi"
  exec uwsgi --ini /etc/searxng/uwsgi.ini
}

main "$@"
