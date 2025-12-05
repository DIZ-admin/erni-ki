#!/usr/bin/env bash
set -euo pipefail

# Load HTTP API token from Docker secret and execute Watchtower with the
# original arguments passed via compose `command`.
BUSYBOX=${BUSYBOX:-/opt/erni/bin/busybox}

if [ -f /run/secrets/watchtower_api_token ]; then
  token="$($BUSYBOX cat /run/secrets/watchtower_api_token)"
  token=${token%$'\n'}
  token=${token%$'\r'}
  WATCHTOWER_HTTP_API_TOKEN="$token"
  export WATCHTOWER_HTTP_API_TOKEN
fi

exec /watchtower "$@"
