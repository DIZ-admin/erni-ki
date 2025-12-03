#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT="${SCRIPT_DIR%/scripts}"

export MOCK_OPENWEBUI_PORT=${MOCK_OPENWEBUI_PORT:-4173}
export MOCK_OPENWEBUI_HOST=${MOCK_OPENWEBUI_HOST:-127.0.0.1}
export E2E_MOCK_MODE=${E2E_MOCK_MODE:-true}
export PW_BASE_URL=${PW_BASE_URL:-"http://${MOCK_OPENWEBUI_HOST}:${MOCK_OPENWEBUI_PORT}"}

echo "🚀 Starting mock OpenWebUI on ${PW_BASE_URL}"
bun run "${REPO_ROOT}/tests/mocks/mock-openwebui-server.mjs" &
MOCK_PID=$!

cleanup() {
  if kill -0 "$MOCK_PID" >/dev/null 2>&1; then
    kill "$MOCK_PID"
    wait "$MOCK_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

echo "🧪 Running Playwright against mock server..."
bunx playwright test "$@"
