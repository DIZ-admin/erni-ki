#!/usr/bin/env bash
#
# Cleanup and archive Alertmanager webhook logs

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

WEBHOOK_DIR="${PROJECT_DIR}/data/webhook-logs"
ARCHIVE_DIR="${WEBHOOK_DIR}/archive"
RETENTION_DAYS="${WEBHOOK_LOG_RETENTION_DAYS:-7}"
ARCHIVE_RETENTION_DAYS="${WEBHOOK_LOG_ARCHIVE_RETENTION_DAYS:-30}"

mkdir -p "$ARCHIVE_DIR"

if [[ ! -d "$WEBHOOK_DIR" ]]; then
  log_info "Directory $WEBHOOK_DIR not found"
  exit 0
fi

cutoff_epochs=$(date -d "-${RETENTION_DAYS} days" +%s)

# Group files by date from filename (alert_<severity>_YYYYMMDD_HHMMSS.json)
find "$WEBHOOK_DIR" -maxdepth 1 -type f -name 'alert_*.json' -print0 | while IFS= read -r -d '' file; do
  base="$(basename "$file")"
  IFS='_' read -r prefix severity date_part time_part rest <<<"$base"
  [[ -z "${date_part:-}" || "${#date_part}" -ne 8 ]] && continue
  if ! file_epoch=$(date -d "$date_part" +%s 2>/dev/null); then
    continue
  fi
  if (( file_epoch > cutoff_epochs )); then
    continue
  fi
  bucket="${ARCHIVE_DIR}/${date_part}"
  mkdir -p "$bucket"
  mv "$file" "$bucket/" 2>/dev/null || true
done

# Tar per-day buckets and remove originals
shopt -s nullglob
for day_dir in "${ARCHIVE_DIR}"/*; do
  [[ -d "$day_dir" ]] || continue
  day="$(basename "$day_dir")"
  archive_file="${ARCHIVE_DIR}/alert-${day}.tar.gz"
  if [[ -n "$(ls -A "$day_dir")" ]]; then
    tar -czf "$archive_file" -C "$day_dir" . && rm -rf "$day_dir"
    log_info "Archived webhooks for ${day} → $(basename "$archive_file")"
  else
    rmdir "$day_dir"
  fi
done
shopt -u nullglob

# Remove old archives
find "$ARCHIVE_DIR" -maxdepth 1 -type f -name 'alert-*.tar.gz' -mtime +"$ARCHIVE_RETENTION_DAYS" -print -delete

log_info "Cleanup complete"
