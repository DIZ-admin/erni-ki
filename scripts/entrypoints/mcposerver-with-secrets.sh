#!/bin/sh
set -eu

# populate sensitive envs from docker secrets if present (trim CR/LF)
trim() { /opt/erni/bin/busybox tr -d '\r\n' < "$1"; }

if [ -f /run/secrets/postgres_password ]; then
  POSTGRES_PASSWORD="$(trim /run/secrets/postgres_password)"
  [ -z "$POSTGRES_PASSWORD" ] && { echo "mcposerver: postgres_password secret is empty" >&2; exit 1; }
  export POSTGRES_PASSWORD
fi
if [ -f /run/secrets/context7_api_key ]; then
  CONTEXT7_API_KEY="$(trim /run/secrets/context7_api_key)"
  [ -z "$CONTEXT7_API_KEY" ] && { echo "mcposerver: context7_api_key secret is empty" >&2; exit 1; }
  export CONTEXT7_API_KEY
fi
if [ -f /run/secrets/ragflow_api_key ]; then
  RAGFLOW_API_KEY="$(trim /run/secrets/ragflow_api_key)"
  [ -z "$RAGFLOW_API_KEY" ] && { echo "mcposerver: ragflow_api_key secret is empty" >&2; exit 1; }
  export RAGFLOW_API_KEY
fi

# optional debug: dump env and exit
if [ "${ENV_DUMP:-0}" != "0" ]; then
  env
  exit 0
fi

# Run mcpo CLI directly (image Entrypoint defaults to mcpo)
exec mcpo "$@"
