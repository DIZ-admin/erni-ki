#!/usr/bin/env bash
set -euo pipefail

readonly ARTEFACT_DIRS=(
  "compose/data"
  "docs/ru/archive/reports"
)

warn_if_tracked() {
  local dir="$1"
  local tracked
  tracked=$(git ls-files "$dir" 2>/dev/null | wc -l | tr -d '[:space:]')
  tracked=${tracked:-0}
  if [[ "$tracked" -gt 0 ]]; then
    echo "[WARN] $dir is tracked with $tracked entries — consider moving the data to an artifact store and keeping only metadata in Git."
  fi
}

summary=0
for dir in "${ARTEFACT_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    continue
  fi

  du -sh "$dir" 2>/dev/null || true
  warn_if_tracked "$dir"
  summary=1

done

if [[ "$summary" -eq 0 ]]; then
  echo "No known generated artefact directories exist in the workspace."
else
  echo "Use git rm --cached <files> and upload the directories to S3/GCS/artifact storage before committing."
fi
