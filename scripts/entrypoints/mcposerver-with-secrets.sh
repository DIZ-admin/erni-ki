#!/bin/sh
# =============================================================================
# MCPOServer entrypoint - loads secrets from Docker secrets
# =============================================================================
set -eu

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets-sh.sh
if [ -f /opt/erni/lib/secrets-sh.sh ]; then
  . /opt/erni/lib/secrets-sh.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[mcposerver] $*" >&2; }
  log_error() { echo "[mcposerver] ERROR: $*" >&2; exit 1; }
  read_secret() {
    secret_file="/run/secrets/$1"
    [ -f "$secret_file" ] && tr -d '\r\n' < "$secret_file" && return 0
    return 1
  }
  require_secret() {
    value=$(read_secret "$1") || log_error "Required secret not found: $1"
    [ -z "$value" ] && log_error "Required secret is empty: $1"
    echo "$value"
  }
fi

__SCRIPT_NAME="mcposerver"

# Load required secrets
if value=$(read_secret "postgres_password"); then
  [ -z "$value" ] && log_error "postgres_password secret is empty"
  export POSTGRES_PASSWORD="$value"
fi

if value=$(read_secret "context7_api_key"); then
  [ -z "$value" ] && log_error "context7_api_key secret is empty"
  export CONTEXT7_API_KEY="$value"
fi

if value=$(read_secret "ragflow_api_key"); then
  [ -z "$value" ] && log_error "ragflow_api_key secret is empty"
  export RAGFLOW_API_KEY="$value"
fi

# Debug mode
if [ "${ENV_DUMP:-0}" != "0" ]; then
  env
  exit 0
fi

exec mcpo "$@"
