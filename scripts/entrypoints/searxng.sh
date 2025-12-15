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
    valkey_url="redis://${username}:${password}@${host}:${port}/${db}" # pragma: allowlist secret
    # Only export SEARXNG_VALKEY_URL to avoid deprecation warning
    # (SearXNG warns if SEARXNG_REDIS_URL is set)
    export SEARXNG_VALKEY_URL="${valkey_url}"
    log "Valkey URL configured for user ${username} on ${host}:${port}/${db} (value not logged)"
    return
  fi

  log "warning: redis_password secret missing; using host=${host} port=${port} db=${db} (URL value not logged; will fail if requirepass is enabled)"
  # Only export SEARXNG_VALKEY_URL to avoid deprecation warning
  export SEARXNG_VALKEY_URL="${SEARXNG_VALKEY_URL:-redis://${host}:${port}/${db}}" # pragma: allowlist secret
}

configure_searxng_secret() {
  if secret="$(read_secret "searxng_secret_key")"; then
    export SEARXNG_SECRET="${secret}"
    log "Applied SEARXNG_SECRET from docker secret (value not logged)"
  else
    log "warning: searxng_secret_key secret missing; SEARXNG_SECRET not set"
  fi
}

main() {
  log "Main function started with $# arguments"
  configure_searxng_secret
  configure_redis_url

  log "Configured SEARXNG_VALKEY_URL environment variable (value not logged)"

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
