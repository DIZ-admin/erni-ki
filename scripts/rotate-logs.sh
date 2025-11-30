#!/bin/bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET="$PROJECT_ROOT/scripts/infrastructure/security/rotate-logs.sh"

if [[ ! -x "$TARGET" ]]; then
  echo "❌ Target rotate-logs script not found: $TARGET"
  exit 1
fi

exec "$TARGET" "$@"
