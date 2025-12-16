#!/bin/sh
# Entrypoint for ragflow-adapter - injects secrets into environment
set -euo pipefail

log() {
  echo "[ragflow-adapter] $*" >&2
}

# Read RAGFLOW_API_KEY from secret if not already set
if [ -z "${RAGFLOW_API_KEY:-}" ] && [ -f /run/secrets/ragflow_api_key ]; then
    export RAGFLOW_API_KEY="$(tr -d '\r\n' < /run/secrets/ragflow_api_key)"
    log "Loaded RAGFLOW_API_KEY from secret"
fi

# Execute the main application
exec uvicorn main:app --host 0.0.0.0 --port 8090
