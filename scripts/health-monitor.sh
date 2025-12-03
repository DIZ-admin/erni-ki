#!/usr/bin/env bash

# Redirects callers to the refactored health monitor.
# Keeps historical entrypoints working while we transition to v2.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/health-monitor-v2.sh"

if [[ ! -x "$TARGET" ]]; then
  echo "❌ scripts/health-monitor-v2.sh not found; please reinstall scripts" >&2
  exit 1
fi

if [[ -z "${SUPPRESS_HEALTH_MONITOR_LEGACY_NOTICE:-}" ]]; then
  echo "DEPRECATED: use scripts/health-monitor-v2.sh directly (scripts/health-monitor.sh kept as wrapper)." >&2
fi

exec "$TARGET" "$@"
