#!/usr/bin/env bash

# Measure pre-commit hook durations and store in .cache/pre-commit/perf.log
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

METRICS_DIR=".cache/pre-commit"
METRICS_FILE="$METRICS_DIR/perf.log"
mkdir -p "$METRICS_DIR"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

echo "[$(timestamp)] Running pre-commit with timing..."
# --time prints per-hook durations; --verbose for visibility
PRE_COMMIT_COLOR=never pre-commit run --config .pre-commit-config.yaml --all-files --verbose --time 2>&1 | tee "$METRICS_DIR/run.log"

# Extract timing lines: "hook-name........Passed (1.23s)"
grep -E "Passed \\([0-9.]+s\\)" "$METRICS_DIR/run.log" | while IFS= read -r line; do
  if [[ "$line" =~ ^([[:alnum:][:punct:]-]+).*\(([0-9.]+)s\) ]]; then
    hook="${BASH_REMATCH[1]}"
    secs="${BASH_REMATCH[2]}"
    echo "$(timestamp),${hook},${secs}" >> "$METRICS_FILE"
  fi
done

echo "Performance data appended to $METRICS_FILE"
