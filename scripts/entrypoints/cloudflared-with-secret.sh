#!/bin/sh
set -eu
if [ -f /run/secrets/cloudflared_tunnel_token ]; then
  export TUNNEL_TOKEN="$(/opt/erni/bin/busybox cat /run/secrets/cloudflared_tunnel_token)"
fi

# optional debug: dump env and exit
if [ "${ENV_DUMP:-0}" != "0" ]; then
  /opt/erni/bin/busybox env
  exit 0
fi

exec cloudflared "$@"
