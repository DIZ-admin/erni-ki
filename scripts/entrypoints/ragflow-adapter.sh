#!/usr/bin/env bash
# =============================================================================
# RAGFlow Adapter entrypoint - loads RAGFlow API key
# =============================================================================
set -euo pipefail

# Load shared library (will be mounted by compose)
# shellcheck source=../lib/secrets.sh
if [[ -f /opt/erni/lib/secrets.sh ]]; then
  source /opt/erni/lib/secrets.sh
else
  # Fallback minimal implementation for standalone use
  log() { echo "[ragflow-adapter] $*" >&2; }
  read_secret() {
    local secret_file="/run/secrets/$1"
    [[ -f "$secret_file" ]] && tr -d '\r\n' < "$secret_file" && return 0
    return 1
  }
fi

__SCRIPT_NAME="ragflow-adapter"

# Read RAGFLOW_API_KEY from secret if not already set
if [[ -z "${RAGFLOW_API_KEY:-}" ]]; then
  if api_key=$(read_secret "ragflow_api_key"); then
    export RAGFLOW_API_KEY="$api_key"
    log "Loaded RAGFLOW_API_KEY from secret"
  fi
fi

# Execute the main application
exec uvicorn main:app --host 0.0.0.0 --port 8090
