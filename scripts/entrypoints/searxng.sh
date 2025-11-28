#!/usr/bin/env bash
set -euo pipefail

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

main() {
  configure_redis_url

  if [[ $# -gt 0 ]]; then
    exec "$@"
  fi

  if [[ -x "/usr/local/bin/docker-entrypoint.sh" ]]; then
    exec /usr/local/bin/docker-entrypoint.sh "$@"
  fi

  exec uwsgi --ini /etc/searxng/uwsgi.ini
}

main "$@"
