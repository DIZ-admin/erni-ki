#!/bin/sh
set -eu
PW_FILE=/run/secrets/redis_password
if [ -f "$PW_FILE" ]; then
  PW=$(/opt/erni/bin/busybox tr -d '\r\n' < "$PW_FILE")
  # Use explicit flags to avoid redis:// scheme parsing issues inside exporter
  exec /redis_exporter --redis.addr=redis:6379 --redis.user=exporter --redis.password="$PW" "$@"
fi
export FROM_SECRET_INIT=1

if [ "${ENV_DUMP:-0}" != "0" ]; then
  /opt/erni/bin/busybox env
  exit 0
fi
exec /redis_exporter "$@"
