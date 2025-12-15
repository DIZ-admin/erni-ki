#!/bin/sh
# Redis Exporter entrypoint with secret loading
# Reads Redis password from Docker secret file

set -e

# Load Redis password from secret file using busybox
if [ -f /run/secrets/redis_password ]; then
    REDIS_PASSWORD=$(/opt/erni/bin/busybox cat /run/secrets/redis_password)
    export REDIS_PASSWORD
fi

# Build Redis URL with authentication
# Use REDIS_USER env var if set, otherwise default to 'exporter'
REDIS_USER="${REDIS_USER:-exporter}"
if [ -n "$REDIS_PASSWORD" ]; then
    export REDIS_ADDR="redis://${REDIS_USER}:${REDIS_PASSWORD}@redis:6379"
fi

# Execute redis_exporter
exec /redis_exporter "$@"
