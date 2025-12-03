#!/usr/bin/env bash

# LEGACY: deprecated, use scripts/health-monitor-v2.sh instead
# Unified ERNI-KI health monitor (original implementation)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_PATH=""
REPORT_FORMAT="markdown"

HEALTH_MONITOR_ENV_FILE="${HEALTH_MONITOR_ENV_FILE:-$PROJECT_DIR/env/health-monitor.env}"
if [[ -f "$HEALTH_MONITOR_ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$HEALTH_MONITOR_ENV_FILE"
  set +a
fi

LOG_IGNORE_REGEX="${HEALTH_MONITOR_LOG_IGNORE_REGEX:-litellm\.proxy\.proxy_server\.user_api_key_auth|node-exporter.*(broken pipe|connection reset by peer)|cloudflared.*context canceled|redis-exporter.*Errorstats|redis-exporter.*unexpected_error_replies|redis-exporter.*total_error_replies}"
LOG_WINDOW="${HEALTH_MONITOR_LOG_WINDOW:-5m}"

IFS=' ' read -r -a COMPOSE_CMD <<< "${HEALTH_MONITOR_COMPOSE_BIN:-docker compose}"
COMPOSE_CMD=("${COMPOSE_CMD[@]}")

RESULTS=()
FAILED=0
WARNINGS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -r, --report PATH     Save report to PATH (default markdown)
  -f, --format FORMAT   Report format: markdown | text (default markdown)
  -h, --help            Show help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--report)
        REPORT_PATH="$2"
        shift 2
        ;;
      -f|--format)
        REPORT_FORMAT="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

log() {
  printf "${BLUE}[%s]${NC} %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

record_result() {
  local status="$1"
  local summary="$2"
  local details="$3"

  RESULTS+=("$status|$summary|$details")

  case "$status" in
    FAIL) FAILED=$((FAILED + 1)) ;;
    WARN) WARNINGS=$((WARNINGS + 1)) ;;
  esac

  local icon output
  case "$status" in
    PASS)
      icon="✅"
      output="${GREEN}${icon} $summary${NC} - $details"
      ;;
    WARN)
      icon="⚠️ "
      output="${YELLOW}${icon} $summary${NC} - $details"
      ;;
    FAIL)
      icon="❌"
      output="${RED}${icon} $summary${NC} - $details"
      ;;
    *)
      icon="ℹ️ "
      output="${icon} $summary - $details"
      ;;
  esac

  echo -e "$output"
}

compose() {
  (cd "$PROJECT_DIR" && "${COMPOSE_CMD[@]}" "$@")
}

load_env_value() {
  local file="$PROJECT_DIR/env/$1"
  local key="$2"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local line
  line="$(grep -E "^${key}=" "$file" | tail -n 1 || true)"
  [[ -z "$line" ]] && return 1

  local value="${line#*=}"
  value="${value%\"}"
  value="${value#\"}"
  printf '%s' "$value"
}

check_compose_services() {
  log "Checking container status..."

  local compose_json compose_err tmp_err
  tmp_err=$(mktemp)
  if ! compose_json="$(compose ps --format json 2>"$tmp_err")"; then
    compose_err="$(cat "$tmp_err")"
    rm -f "$tmp_err"
    record_result "FAIL" "Containers" "Failed to run docker compose ps (${compose_err:-unknown error})"
    return
  fi
  compose_err="$(cat "$tmp_err")"
  rm -f "$tmp_err"

  local parsed
  if ! parsed="$(
    COMPOSE_JSON_PAYLOAD="$compose_json" python3 <<'PY'
from __future__ import annotations
import json
import os
import sys

payload = os.environ.get("COMPOSE_JSON_PAYLOAD", "")
lines = [line.strip() for line in payload.splitlines() if line.strip()]
records = []
for line in lines:
    try:
        records.append(json.loads(line))
    except json.JSONDecodeError:
        continue

if not records:
    sys.exit(2)

total = len(records)
healthy = sum(1 for svc in records if svc.get("Health") == "healthy")
running = sum(1 for svc in records if svc.get("State") == "running")
unhealthy = [svc.get("Service") for svc in records if svc.get("Health") not in (None, "healthy")]
detail = " ".join(unhealthy) if unhealthy else "none"
print(f"{healthy}/{total} healthy, {running}/{total} running|{detail}")
PY
  )"; then
    record_result "FAIL" "Containers" "Failed to parse docker compose ps output"
    return
  fi

  local summary="${parsed%%|*}"
  local detail="${parsed#*|}"

  if [[ "$detail" == "none" ]]; then
    record_result "PASS" "Containers" "$summary"
  else
    record_result "WARN" "Containers" "$summary (issues: $detail)"
  fi
}

check_http_endpoint() {
  local name="$1"
  local url="$2"
  local expected="$3"

  local response
  if ! response=$(curl -fsS --max-time 8 "$url" 2>/dev/null); then
    record_result "FAIL" "$name" "Endpoint unavailable: $url"
    return
  fi

  if [[ -n "$expected" && "$response" != *"$expected"* ]]; then
    record_result "WARN" "$name" "Response missing expected value ($expected)"
    return
  fi

  record_result "PASS" "$name" "$url"
}

check_rag_latency() {
  log "Checking RAG web search..."
  local warn_threshold="${RAG_LATENCY_WARN_SECONDS:-5.0}"
  local result
  result=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" "http://localhost:8080/api/searxng/search?q=health-check&format=json" --max-time 10 || echo "000|10")
  local code="${result%%|*}"
  local duration="${result#*|}"

  if [[ "$code" != "200" ]]; then
    record_result "FAIL" "RAG web search" "HTTP $code via /api/searxng/"
    return
  fi

  if (( $(echo "$duration > $warn_threshold" | bc -l) )); then
    record_result "WARN" "RAG web search" "Response ${duration}s (threshold ${warn_threshold}s)"
  else
    record_result "PASS" "RAG web search" "${duration}s"
  fi
}

check_postgres() {
  log "Checking PostgreSQL..."
  if compose exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    record_result "PASS" "PostgreSQL" "pg_isready ok"
  else
    record_result "FAIL" "PostgreSQL" "pg_isready returned error"
  fi
}

check_redis() {
  log "Checking Redis..."
  local redis_pass
  redis_pass="$(load_env_value redis.env REDIS_PASSWORD || true)"

  local cmd="redis-cli ping"
  if [[ -n "$redis_pass" ]]; then
    cmd="redis-cli -a '$redis_pass' ping"
  fi

  if compose exec -T redis sh -c "$cmd" 2>/dev/null | grep -q "PONG"; then
    record_result "PASS" "Redis" "ping OK"
  else
    record_result "FAIL" "Redis" "Redis did not reply PONG"
  fi
}

check_disk_usage() {
  log "Checking disk space..."
  local usageLine
  usageLine=$(df -h "$PROJECT_DIR" | tail -1)
  local percent
  percent=$(echo "$usageLine" | awk '{print $5}' | tr -d '%')
  local detail=$(echo "$usageLine" | awk '{print $3 "/" $2 " used"}')

  if [[ -z "$percent" ]]; then
    record_result "WARN" "Disk" "Unable to determine usage"
    return
  fi

  if (( percent >= 90 )); then
    record_result "FAIL" "Disk" "$percent% - $detail"
  elif (( percent >= 80 )); then
    record_result "WARN" "Disk" "$percent% - $detail"
  else
    record_result "PASS" "Disk" "$percent% - $detail"
  fi
}

check_logs() {
  log "Analyzing logs for the last 30 minutes..."
  local count
  local stream
  stream="$(compose logs --since "$LOG_WINDOW" 2>/dev/null | grep -i -E "(ERROR|FATAL|CRITICAL)" || true)"

  if [[ -n "$LOG_IGNORE_REGEX" ]]; then
    stream="$(echo "$stream" | grep -Ev "$LOG_IGNORE_REGEX" || true)"
  fi

  count="$(echo "$stream" | sed '/^[[:space:]]*$/d' | wc -l || echo "0")"

  if [[ "$count" -eq 0 ]]; then
    record_result "PASS" "Logs" "No critical errors found"
  elif [[ "$count" -le 10 ]]; then
    record_result "WARN" "Logs" "$count critical records in 30 minutes"
  else
    record_result "FAIL" "Logs" "$count critical records in 30 minutes"
  fi
}

write_report() {
  [[ -z "$REPORT_PATH" ]] && return

  mkdir -p "$(dirname "$REPORT_PATH")"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  if [[ "$REPORT_FORMAT" == "text" ]]; then
    {
      echo "ERNI-KI Health Report - $ts"
      echo "========================================"
      for row in "${RESULTS[@]}"; do
        IFS='|' read -r status summary detail <<< "$row"
        echo "[$status] $summary - $detail"
      done
      echo ""
      echo "Failures: $FAILED, Warnings: $WARNINGS"
    } > "$REPORT_PATH"
    return
  fi

  {
    echo "# ERNI-KI Health Report"
    echo "_${ts}_"
    echo ""
    echo "| Status | Check | Details |"
    echo "|--------|----------|--------|"
    for row in "${RESULTS[@]}"; do
      IFS='|' read -r status summary detail <<< "$row"
      echo "| $status | $summary | $detail |"
    done
    echo ""
    echo "**Failures:** $FAILED &nbsp;&nbsp; **Warnings:** $WARNINGS"
  } > "$REPORT_PATH"
}

main() {
  parse_args "$@"

  log "=== ERNI-KI Health Monitor ==="
  check_compose_services

  check_http_endpoint "OpenWebUI" "http://localhost:8080/health" ""
  check_http_endpoint "LiteLLM" "http://localhost:4000/health/liveliness" "alive"
  check_http_endpoint "Ollama API" "http://localhost:11434/api/tags" "models"
  check_http_endpoint "Nginx proxy" "http://localhost/health" ""

  check_rag_latency
  check_postgres
  check_redis
  check_disk_usage
  check_logs

  write_report

  if [[ $FAILED -gt 0 ]]; then
    exit 1
  fi

  exit 0
}

main "$@"
