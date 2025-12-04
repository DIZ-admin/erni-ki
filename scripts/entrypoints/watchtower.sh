#!/usr/bin/env sh
set -euo pipefail

# Load HTTP API token from Docker secret and execute Watchtower with the
# original arguments passed via compose `command`.
if [ -f /run/secrets/watchtower_api_token ]; then
  WATCHTOWER_HTTP_API_TOKEN="$(tr -d '\r\n' </run/secrets/watchtower_api_token)"
  export WATCHTOWER_HTTP_API_TOKEN
fi

exec /watchtower "$@"
