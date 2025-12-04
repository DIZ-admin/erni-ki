#!/usr/bin/env sh
set -euo pipefail

# Inject WEBUI_SECRET_KEY from Docker secret for the auth service.
if [ -z "${WEBUI_SECRET_KEY:-}" ] && [ -f /run/secrets/openwebui_secret_key ]; then
  WEBUI_SECRET_KEY="$(tr -d '\r\n' </run/secrets/openwebui_secret_key)"
  export WEBUI_SECRET_KEY
fi

exec /app/main "$@"
