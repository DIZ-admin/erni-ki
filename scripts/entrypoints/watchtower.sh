#!/bin/sh
# =============================================================================
# Watchtower entrypoint - loads HTTP API token from Docker secret
# =============================================================================
set -eu

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets-sh.sh
if [ -f /opt/erni/lib/secrets-sh.sh ]; then
  . /opt/erni/lib/secrets-sh.sh
else
  # Fallback minimal implementation for standalone use
  BUSYBOX="${BUSYBOX:-/opt/erni/bin/busybox}"
  log() { echo "[watchtower] $*" >&2; }
  log_error() { echo "[watchtower] ERROR: $*" >&2; exit 1; }
  read_secret() {
    secret_file="/run/secrets/$1"
    [ -f "$secret_file" ] && $BUSYBOX tr -d '\r\n' < "$secret_file" && return 0
    return 1
  }
  require_secret() {
    value=$(read_secret "$1") || log_error "Required secret not found: $1"
    [ -z "$value" ] && log_error "Required secret is empty: $1"
    echo "$value"
  }
fi

# Load HTTP API token (required)
WATCHTOWER_HTTP_API_TOKEN=$(require_secret "watchtower_api_token")
export WATCHTOWER_HTTP_API_TOKEN

exec /watchtower "$@"
