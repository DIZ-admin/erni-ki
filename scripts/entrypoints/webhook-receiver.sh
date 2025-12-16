#!/bin/bash
# Entrypoint for webhook-receiver - injects secrets into environment
set -euo pipefail

log() {
  echo "[webhook-entrypoint] $*" >&2
}

# Read ALERTMANAGER_WEBHOOK_SECRET from secret if not already set
if [ -z "${ALERTMANAGER_WEBHOOK_SECRET:-}" ] && [ -f /run/secrets/alertmanager_webhook_secret ]; then
    export ALERTMANAGER_WEBHOOK_SECRET="$(tr -d '\r\n' < /run/secrets/alertmanager_webhook_secret)"
    log "Loaded ALERTMANAGER_WEBHOOK_SECRET from secret"
fi

# Execute the main application using gunicorn (production WSGI server)
exec gunicorn --bind 0.0.0.0:9093 --workers 2 --threads 4 \
    --access-logfile - --error-logfile - \
    "webhook-receiver:app"
