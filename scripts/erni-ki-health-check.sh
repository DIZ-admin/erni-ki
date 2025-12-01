#!/usr/bin/env bash

# Historical entry point kept for compatibility. Generates a markdown report.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

TARGET="$SCRIPT_DIR/health-monitor-v2.sh"

REPORT_FILE="diagnostic-report-$(date '+%Y-%m-%d_%H-%M-%S').md"
REPORT_DIR="$SCRIPT_DIR/../.config-backup/monitoring"
REPORT_PATH="$REPORT_DIR/$REPORT_FILE"

mkdir -p "$REPORT_DIR"

if [[ ! -x "$TARGET" ]]; then
  echo "❌ scripts/health-monitor-v2.sh not found" >&2
  exit 1
fi

exec "$TARGET" --report "$REPORT_PATH" "$@"
