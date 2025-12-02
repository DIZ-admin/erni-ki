#!/bin/sh
set -eu

log() {
  echo "[openwebui-entrypoint] $*" >&2
}

read_secret() {
  secret_name="$1"
  secret_file="/run/secrets/${secret_name}"

  if [ -f "${secret_file}" ]; then
    # Strip trailing newline without using subshells repeatedly
    tr -d '\r' <"${secret_file}" | tr -d '\n'
    return 0
  fi

  return 1
}

configure_postgres_urls() {
  password=""
  if ! password="$(read_secret "postgres_password")"; then
    log "warning: postgres_password secret is not available; DATABASE_URL will remain unchanged"
    return
  fi

  db_user="${OPENWEBUI_DB_USER:-postgres}"
  db_name="${OPENWEBUI_DB_NAME:-openwebui}"
  db_host="${OPENWEBUI_DB_HOST:-db}"
  db_port="${OPENWEBUI_DB_PORT:-5432}"

  url="postgresql://${db_user}:${password}@${db_host}:${db_port}/${db_name}"

  if [ -z "${DATABASE_URL:-}" ]; then
    export DATABASE_URL="${url}"
  fi

  if [ -z "${PGVECTOR_DB_URL:-}" ]; then
    export PGVECTOR_DB_URL="${url}"
  fi
}

configure_webui_secret() {
  secret_key=""
  if secret_key="$(read_secret "openwebui_secret_key")"; then
    export WEBUI_SECRET_KEY="${secret_key}"
  else
    log "warning: openwebui_secret_key secret missing; WEBUI_SECRET_KEY is not set"
  fi
}

configure_openai_keys() {
  api_key=""
  if ! api_key="$(read_secret "litellm_api_key")"; then
    log "warning: litellm_api_key secret missing; OpenAI-related keys remain unchanged"
    return
  fi

  export OPENAI_API_KEY="${OPENAI_API_KEY:-$api_key}"
  export LITELLM_API_KEY="${LITELLM_API_KEY:-$api_key}"
  export AUDIO_STT_OPENAI_API_KEY="${AUDIO_STT_OPENAI_API_KEY:-$api_key}"
}

configure_redis_url() {
  host="${REDIS_HOST:-redis}"
  port="${REDIS_PORT:-6379}"
  db="${REDIS_DB:-0}"
  username="${REDIS_USER:-openwebui}"
  password=""

  if password="$(read_secret "redis_password")"; then
    log "redis secret found, applying REDIS_URL with user: ${username}"
    export REDIS_PASSWORD="${REDIS_PASSWORD:-$password}"
  # NOTE 2025-12-02: Added username for Redis ACL
    export REDIS_URL="redis://${username}:${password}@${host}:${port}/${db}"
    return
  fi

  log "warning: redis_password secret missing; REDIS_URL may be invalid"
  # Fallback: no secret provided, keep existing REDIS_URL (may fail if requirepass is enabled)
  export REDIS_URL="${REDIS_URL:-redis://${host}:${port}/${db}}"
}

apply_defaults() {
  # Enforce sane JWT expiry (override any stale defaults)
  export JWT_EXPIRES_IN=86400
  export JWT_EXPIRATION=86400

  # Force-enable CUDA when GPU runtime is available
  export USE_CUDA_DOCKER=true
}

main() {
  configure_postgres_urls
  configure_webui_secret
  configure_openai_keys
  configure_redis_url
  apply_defaults

  if [ $# -gt 0 ]; then
    exec "$@"
  fi

  if [ -x "/app/backend/start.sh" ]; then
    exec /bin/bash /app/backend/start.sh
  fi

  log "falling back to uvicorn main module"
  exec python3 -m open_webui.main
}

main "$@"
