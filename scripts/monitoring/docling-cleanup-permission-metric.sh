#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="${DOCLING_CLEANUP_LOG:-$PROJECT_DIR/logs/docling-shared-cleanup.log}"
TEXTFILE_DIR="${TEXTFILE_DIR:-$PROJECT_DIR/data/node-exporter-textfile}"
METRIC_FILE="$TEXTFILE_DIR/docling_cleanup_perm_denied.prom"
mkdir -p "$TEXTFILE_DIR"

metric_value=0
if [[ -f "$LOG_FILE" ]]; then
  if tail -n 200 "$LOG_FILE" | grep -qi "Permission denied"; then
    metric_value=1
  fi
fi

cat >"$METRIC_FILE" <<EOF
# HELP erni_docling_cleanup_permission_denied Permission errors detected in the latest docling cleanup execution (1=yes).
# TYPE erni_docling_cleanup_permission_denied gauge
erni_docling_cleanup_permission_denied ${metric_value}
EOF
