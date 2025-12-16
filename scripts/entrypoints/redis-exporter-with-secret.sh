#!/bin/sh
# =============================================================================
# Redis Exporter entrypoint - loads Redis password from Docker secret
# =============================================================================
set -eu

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets-sh.sh
if [ -f /opt/erni/lib/secrets-sh.sh ]; then
  . /opt/erni/lib/secrets-sh.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[redis-exporter] $*" >&2; }
  read_secret() {
    secret_file="/run/secrets/$1"
    [ -f "$secret_file" ] && tr -d '\r\n' < "$secret_file" && return 0
    return 1
  }
fi

__SCRIPT_NAME="redis-exporter"

# Load Redis password
if REDIS_PASSWORD=$(read_secret "redis_password"); then
  export REDIS_PASSWORD
  # Build Redis URL with authentication
  REDIS_USER="${REDIS_USER:-exporter}"
  export REDIS_ADDR="redis://${REDIS_USER}:${REDIS_PASSWORD}@redis:6379"
fi

exec /redis_exporter "$@"
