#!/usr/bin/env sh
set -eu

# Load HTTP API token from Docker secret and execute Watchtower with the
# original arguments passed via compose `command`.
BUSYBOX=${BUSYBOX:-/opt/erni/bin/busybox}

if [ -f /run/secrets/watchtower_api_token ]; then
  token="$($BUSYBOX tr -d '\r\n' < /run/secrets/watchtower_api_token)"
  WATCHTOWER_HTTP_API_TOKEN="$token"
  export WATCHTOWER_HTTP_API_TOKEN
fi

exec /watchtower "$@"
