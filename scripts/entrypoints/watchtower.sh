#!/usr/bin/env sh
set -eu

# Load HTTP API token from Docker secret and execute Watchtower with the
# original arguments passed via compose `command`.
BUSYBOX=${BUSYBOX:-/opt/erni/bin/busybox}

if [ -f /run/secrets/watchtower_api_token ]; then
  token="$($BUSYBOX tr -d '\r\n' < /run/secrets/watchtower_api_token)"
  if [ -z "$token" ]; then
    echo "watchtower: watchtower_api_token secret is empty" >&2
    exit 1
  fi
  export WATCHTOWER_HTTP_API_TOKEN="$token"
else
  echo "watchtower: watchtower_api_token secret missing" >&2
  exit 1
fi

exec /watchtower "$@"
