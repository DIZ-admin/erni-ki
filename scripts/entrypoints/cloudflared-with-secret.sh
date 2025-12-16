#!/bin/sh
# =============================================================================
# Cloudflared entrypoint - loads tunnel token from Docker secret
# =============================================================================
set -eu

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets-sh.sh
if [ -f /opt/erni/lib/secrets-sh.sh ]; then
  . /opt/erni/lib/secrets-sh.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[cloudflared] $*" >&2; }
  log_error() { echo "[cloudflared] ERROR: $*" >&2; exit 1; }
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

# Load tunnel token
TUNNEL_TOKEN=$(require_secret "cloudflared_tunnel_token")
export TUNNEL_TOKEN

# Debug mode
if [ "${ENV_DUMP:-0}" != "0" ]; then
  env
  exit 0
fi

exec cloudflared "$@"
