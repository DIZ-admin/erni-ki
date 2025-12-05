#!/bin/sh
set -eu

TOKEN_PATH="/run/secrets/cloudflared_tunnel_token"

if [ -f "$TOKEN_PATH" ]; then
  if ! token="$(/opt/erni/bin/busybox cat "$TOKEN_PATH" 2>/dev/null)"; then
    echo "cloudflared: unable to read tunnel token from $TOKEN_PATH" >&2
    exit 1
  fi
  TUNNEL_TOKEN="$token"
  export TUNNEL_TOKEN
fi

# optional debug: dump env and exit
if [ "${ENV_DUMP:-0}" != "0" ]; then
  /opt/erni/bin/busybox env
  exit 0
fi

exec cloudflared "$@"
