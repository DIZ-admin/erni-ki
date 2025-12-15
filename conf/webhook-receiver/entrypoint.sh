#!/bin/sh
set -eu

# Read webhook secret from Docker secret file
if [ -f /run/secrets/alertmanager_webhook_secret ]; then
    export ALERTMANAGER_WEBHOOK_SECRET=$(cat /run/secrets/alertmanager_webhook_secret | tr -d '\r\n')
fi

# Validate secret is set
if [ -z "${ALERTMANAGER_WEBHOOK_SECRET:-}" ]; then
    echo "ERROR: ALERTMANAGER_WEBHOOK_SECRET not configured"
    exit 1
fi

# Execute the main command
exec "$@"
