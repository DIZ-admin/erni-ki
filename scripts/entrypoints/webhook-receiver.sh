#!/usr/bin/env bash
# =============================================================================
# Webhook Receiver entrypoint - loads webhook secret
# =============================================================================
set -euo pipefail

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets.sh
if [[ -f /opt/erni/lib/secrets.sh ]]; then
  source /opt/erni/lib/secrets.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[webhook-receiver] $*" >&2; }
  read_secret() {
    local secret_file="/run/secrets/$1"
    [[ -f "$secret_file" ]] && tr -d '\r\n' < "$secret_file" && return 0
    return 1
  }
fi

# Read ALERTMANAGER_WEBHOOK_SECRET from secret if not already set
if [[ -z "${ALERTMANAGER_WEBHOOK_SECRET:-}" ]]; then
  if secret=$(read_secret "alertmanager_webhook_secret"); then
    export ALERTMANAGER_WEBHOOK_SECRET="$secret"
    log "Loaded ALERTMANAGER_WEBHOOK_SECRET from secret"
  fi
fi

# Execute the main application using gunicorn (production WSGI server)
exec gunicorn --bind 0.0.0.0:9093 --workers 2 --threads 4 \
    --access-logfile - --error-logfile - \
    "webhook_receiver:app"
