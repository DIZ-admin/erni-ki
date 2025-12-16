#!/bin/sh
# Entrypoint for webhook-receiver - injects secrets into environment

# Read ALERTMANAGER_WEBHOOK_SECRET from secret if not already set
if [ -z "$ALERTMANAGER_WEBHOOK_SECRET" ] && [ -f /run/secrets/alertmanager_webhook_secret ]; then
    export ALERTMANAGER_WEBHOOK_SECRET="$(cat /run/secrets/alertmanager_webhook_secret)"
    echo "[webhook-entrypoint] Loaded ALERTMANAGER_WEBHOOK_SECRET from secret"
fi

# Execute the main application using gunicorn (production WSGI server)
exec gunicorn --bind 0.0.0.0:9093 --workers 2 --threads 4 \
    --access-logfile - --error-logfile - \
    "webhook-receiver:app"
