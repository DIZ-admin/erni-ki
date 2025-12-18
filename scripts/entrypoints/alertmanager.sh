#!/bin/sh
# =============================================================================
# Alertmanager entrypoint - injects webhook secret into config
# =============================================================================
set -eu

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets.sh
if [ -f /opt/erni/lib/secrets.sh ]; then
  . /opt/erni/lib/secrets.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[alertmanager] $*" >&2; }
  log_error() { echo "[alertmanager] ERROR: $*" >&2; exit 1; }
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

CONFIG_TEMPLATE="/etc/alertmanager/alertmanager.yml"
CONFIG_RUNTIME="/tmp/alertmanager.yml"

# Read webhook secret (required)
WEBHOOK_SECRET=$(require_secret "alertmanager_webhook_secret")

# Replace credentials_file with direct credentials in config
# This is necessary because Alertmanager runs as non-root and can't read secrets
# Escape special characters for sed and YAML:
# 1. Backslashes must be escaped first (\ -> \\)
# 2. Double quotes must be escaped for YAML (" -> \")
# 3. Ampersand and forward slash for sed (& -> \&, / -> \/)
ESCAPED_SECRET=$(printf '%s' "$WEBHOOK_SECRET" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[&/]/\\&/g')
sed "s|credentials_file: /run/secrets/alertmanager_webhook_secret|credentials: \"$ESCAPED_SECRET\"|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_RUNTIME"

exec /bin/alertmanager --config.file="$CONFIG_RUNTIME" "$@"
