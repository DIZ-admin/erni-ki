#!/bin/sh
set -eu

CONFIG_TEMPLATE="/etc/alertmanager/alertmanager.yml"
CONFIG_RUNTIME="/tmp/alertmanager.yml"

# Read webhook secret
if [ -f /run/secrets/alertmanager_webhook_secret ]; then
    WEBHOOK_SECRET=$(cat /run/secrets/alertmanager_webhook_secret | tr -d '\r\n')
else
    echo "ERROR: alertmanager_webhook_secret not found"
    exit 1
fi

# Replace credentials_file with direct credentials in config
# This is necessary because Alertmanager runs as non-root and can't read secrets
sed "s|credentials_file: /run/secrets/alertmanager_webhook_secret|credentials: \"$WEBHOOK_SECRET\"|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_RUNTIME"

# Execute alertmanager with runtime config
exec /bin/alertmanager --config.file="$CONFIG_RUNTIME" "$@"
