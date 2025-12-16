#!/usr/bin/env bash
# =============================================================================
# Open WebUI entrypoint - loads secrets and configures database/cache URLs
# =============================================================================
set -euo pipefail

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets.sh
if [[ -f /opt/erni/lib/secrets.sh ]]; then
  source /opt/erni/lib/secrets.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[openwebui] $*" >&2; }
  log_warn() { echo "[openwebui] WARNING: $*" >&2; }
  read_secret() {
    local secret_file="/run/secrets/$1"
    [[ -f "$secret_file" ]] && tr -d '\r\n' < "$secret_file" && return 0
    return 1
  }
fi

configure_postgres_urls() {
  local password
  if ! password="$(read_secret "postgres_password")"; then
    log_warn "postgres_password secret is not available; DATABASE_URL will remain unchanged"
    return
  fi

  local db_user="${OPENWEBUI_DB_USER:-postgres}"
  local db_name="${OPENWEBUI_DB_NAME:-openwebui}"
  local db_host="${OPENWEBUI_DB_HOST:-db}"
  local db_port="${OPENWEBUI_DB_PORT:-5432}"

  local url="postgresql://${db_user}:${password}@${db_host}:${db_port}/${db_name}"

  if [[ -z "${DATABASE_URL:-}" ]]; then
    export DATABASE_URL="${url}"
  fi

  if [[ -z "${PGVECTOR_DB_URL:-}" ]]; then
    export PGVECTOR_DB_URL="${url}"
  fi
}

configure_webui_secret() {
  local secret_key
  if secret_key="$(read_secret "openwebui_secret_key")"; then
    export WEBUI_SECRET_KEY="${secret_key}"
  else
    log_warn "openwebui_secret_key secret missing; WEBUI_SECRET_KEY is not set"
  fi
}

configure_openai_keys() {
  local api_key
  if ! api_key="$(read_secret "litellm_api_key")"; then
    log_warn "litellm_api_key secret missing; OpenAI-related keys remain unchanged"
    return
  fi

  export OPENAI_API_KEY="${OPENAI_API_KEY:-$api_key}"
  export LITELLM_API_KEY="${LITELLM_API_KEY:-$api_key}"
  export AUDIO_STT_OPENAI_API_KEY="${AUDIO_STT_OPENAI_API_KEY:-$api_key}"
}

configure_redis_url() {
  local host="${REDIS_HOST:-redis}"
  local port="${REDIS_PORT:-6379}"
  local db="${REDIS_DB:-0}"
  local username="${REDIS_USER:-openwebui}"
  local password

  if password="$(read_secret "redis_password")"; then
    log "redis secret found, applying REDIS_URL with user: ${username}"
    export REDIS_PASSWORD="${REDIS_PASSWORD:-$password}"
    export REDIS_URL="redis://${username}:${password}@${host}:${port}/${db}"
    return
  fi

  log_warn "redis_password secret missing; REDIS_URL may be invalid"
  export REDIS_URL="${REDIS_URL:-redis://${host}:${port}/${db}}"
}

configure_ragflow_key() {
  local api_key
  if api_key="$(read_secret "ragflow_api_key")"; then
    export EXTERNAL_DOCUMENT_LOADER_API_KEY="${api_key}"
    log "ragflow_api_key loaded for EXTERNAL_DOCUMENT_LOADER_API_KEY"
  else
    log_warn "ragflow_api_key secret missing; EXTERNAL_DOCUMENT_LOADER_API_KEY unchanged"
  fi
}

apply_defaults() {
  # Enforce sane JWT expiry while allowing overrides from environment
  export JWT_EXPIRES_IN="${JWT_EXPIRES_IN:-86400}"
  export JWT_EXPIRATION="${JWT_EXPIRATION:-86400}"

  # Force-enable CUDA when GPU runtime is available
  export USE_CUDA_DOCKER="${USE_CUDA_DOCKER:-true}"
}

main() {
  configure_postgres_urls
  configure_webui_secret
  configure_openai_keys
  configure_redis_url
  configure_ragflow_key
  apply_defaults

  if [[ $# -gt 0 ]]; then
    exec "$@"
  fi

  if [[ -x "/app/backend/start.sh" ]]; then
    exec /bin/bash /app/backend/start.sh
  fi

  log "falling back to uvicorn main module"
  exec python3 -m open_webui.main
}

main "$@"
