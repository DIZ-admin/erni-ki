#!/bin/sh
set -euo pipefail

# Minimal POSIX entrypoint: read DSN from secret or mounted file and start exporter.

DSN_SOURCE=""
for p in /run/secrets/postgres_exporter_dsn /etc/postgres_exporter_dsn.txt; do
  if [ -f "$p" ]; then
    DSN_SOURCE="$p"
    break
  fi
done

if [ -z "$DSN_SOURCE" ]; then
  echo "postgres-exporter entrypoint: DSN file not found" >&2
  exit 1
fi

DATA_SOURCE_NAME=$(tr -d '\r' < "$DSN_SOURCE")
export DATA_SOURCE_NAME

exec /bin/postgres_exporter "$@"
