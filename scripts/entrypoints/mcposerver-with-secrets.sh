#!/bin/sh
set -eu
# populate sensitive envs from docker secrets if present
[ -f /run/secrets/postgres_password ] && export POSTGRES_PASSWORD="$(cat /run/secrets/postgres_password)"
[ -f /run/secrets/context7_api_key ] && export CONTEXT7_API_KEY="$(cat /run/secrets/context7_api_key)"
[ -f /run/secrets/ragflow_api_key ] && export RAGFLOW_API_KEY="$(cat /run/secrets/ragflow_api_key)"

# optional debug: dump env and exit
if [ "${ENV_DUMP:-0}" != "0" ]; then
  env
  exit 0
fi

# fall back to default entrypoint if available, else run module
if [ -x /docker-entrypoint.sh ]; then
  exec /docker-entrypoint.sh "$@"
fi
exec python -m mcpo "$@"
