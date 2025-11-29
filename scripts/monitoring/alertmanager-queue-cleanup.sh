#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$PROJECT_DIR/.config-backup/logs/alertmanager-queue.log"
PROM_URL="${PROMETHEUS_URL:-http://localhost:9091}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://localhost:9093}"
THRESHOLD="${ALERTMANAGER_QUEUE_WARN:-100}"
HARD_LIMIT="${ALERTMANAGER_QUEUE_HARD_LIMIT:-500}"
SILENCE_TAG="${ALERTMANAGER_AUTO_SILENCE_TAG:-[auto-cleanup]}"
COMPOSE_CMD="${COMPOSE_CMD:-docker compose}"
RESTART_AM="${ALERTMANAGER_RESTART_ON_OVERFLOW:-1}"

mkdir -p "$(dirname "$LOG_FILE")"

get_queue_value() {
  local query='alertmanager_cluster_messages_queued'
  local response
  if ! response=$(curl -fsS "$PROM_URL/api/v1/query" --data-urlencode "query=$query"); then
    log_info "queue-cleanup: failed to get response from $PROM_URL"
    echo 0
    return
  fi

  python3 - "$response" <<'PY'
import json, sys
payload = json.loads(sys.argv[1])
try:
    result = payload['data']['result'][0]
    print(float(result['value'][1]))
except (KeyError, IndexError, ValueError):
    print(0)
PY
}

queue_value=$(get_queue_value)
log_info "queue-cleanup: current queue value ${queue_value} (threshold=${THRESHOLD}, hard_limit=${HARD_LIMIT})"

awk "BEGIN {exit !(${queue_value} > ${HARD_LIMIT})}" || exit 0

log_info "queue-cleanup: hard limit exceeded, expiring auto-silences (tag ${SILENCE_TAG})"

silence_list=$($COMPOSE_CMD exec alertmanager amtool --alertmanager.url="$ALERTMANAGER_URL" \
  silence query --format '{{ .ID }}|{{ .Comment }}')

target_ids=$(python3 - <<'PY'
import os, sys
payload = sys.stdin.read().strip().splitlines()
tag = os.environ.get('SILENCE_TAG', '[auto-cleanup]')
for line in payload:
    if not line:
        continue
    silence_id, _, comment = line.partition('|')
    if tag in comment:
        print(silence_id)
PY <<<"$silence_list")

if [[ -z "$target_ids" ]]; then
  log_info "queue-cleanup: no silences found with tag ${SILENCE_TAG}"
else
  while read -r silence_id; do
    [[ -z "$silence_id" ]] && continue
    log_info "queue-cleanup: expire silence ${silence_id}"
    $COMPOSE_CMD exec alertmanager amtool --alertmanager.url="$ALERTMANAGER_URL" silence expire "$silence_id" || \
      log_info "queue-cleanup: failed to expire silence ${silence_id}"
  done <<<"$target_ids"
fi

if [[ "$RESTART_AM" == "1" ]]; then
  log_info "queue-cleanup: restarting alertmanager"
  $COMPOSE_CMD restart alertmanager >/dev/null
fi

log_info "queue-cleanup: done"
