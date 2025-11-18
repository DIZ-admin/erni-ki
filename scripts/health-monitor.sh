#!/usr/bin/env bash

# Unified ERNI-KI health monitor

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_PATH=""
REPORT_FORMAT="markdown"

HEALTH_MONITOR_ENV_FILE="${HEALTH_MONITOR_ENV_FILE:-$PROJECT_DIR/env/health-monitor.env}"
if [[ -f "$HEALTH_MONITOR_ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$HEALTH_MONITOR_ENV_FILE"
  set +a
fi

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
  -r, --report PATH     Сохранить отчёт в указанный файл (Markdown по умолчанию)
  -f, --format FORMAT   Формат отчёта: markdown | text (по умолчанию markdown)
  -h, --help            Показать справку
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
        echo "Неизвестный аргумент: $1" >&2
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
  log "Проверка статуса контейнеров..."

  local compose_json compose_err tmp_err
  tmp_err=$(mktemp)
  if ! compose_json="$(compose ps --format json 2>"$tmp_err")"; then
    compose_err="$(cat "$tmp_err")"
    rm -f "$tmp_err"
    record_result "FAIL" "Контейнеры" "Не удалось получить docker compose ps (${compose_err:-unknown error})"
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
    record_result "FAIL" "Контейнеры" "Не удалось разобрать вывод docker compose ps"
    return
  fi

  local summary="${parsed%%|*}"
  local detail="${parsed#*|}"

  if [[ "$detail" == "none" ]]; then
    record_result "PASS" "Контейнеры" "$summary"
  else
    record_result "WARN" "Контейнеры" "$summary (проблемы: $detail)"
  fi
}

check_http_endpoint() {
  local name="$1"
  local url="$2"
  local expected="$3"

  local response
  if ! response=$(curl -fsS --max-time 8 "$url" 2>/dev/null); then
    record_result "FAIL" "$name" "Endpoint недоступен: $url"
    return
  fi

  if [[ -n "$expected" && "$response" != *"$expected"* ]]; then
    record_result "WARN" "$name" "Ответ не содержит ожидаемое значение ($expected)"
    return
  fi

  record_result "PASS" "$name" "$url"
}

check_rag_latency() {
  log "Проверка RAG веб-поиска..."
  local warn_threshold="${RAG_LATENCY_WARN_SECONDS:-5.0}"
  local result
  result=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" "http://localhost:8080/api/searxng/search?q=health-check&format=json" --max-time 10 || echo "000|10")
  local code="${result%%|*}"
  local duration="${result#*|}"

  if [[ "$code" != "200" ]]; then
    record_result "FAIL" "RAG web search" "HTTP $code через /api/searxng/"
    return
  fi

  if (( $(echo "$duration > $warn_threshold" | bc -l) )); then
    record_result "WARN" "RAG web search" "Ответ ${duration}s (порог ${warn_threshold}s)"
  else
    record_result "PASS" "RAG web search" "${duration}s"
  fi
}

check_postgres() {
  log "Проверка PostgreSQL..."
  if compose exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    record_result "PASS" "PostgreSQL" "pg_isready ok"
  else
    record_result "FAIL" "PostgreSQL" "pg_isready вернул ошибку"
  fi
}

check_redis() {
  log "Проверка Redis..."
  local redis_pass
  redis_pass="$(load_env_value redis.env REDIS_PASSWORD || true)"

  local cmd="redis-cli ping"
  if [[ -n "$redis_pass" ]]; then
    cmd="redis-cli -a '$redis_pass' ping"
  fi

  if compose exec -T redis sh -c "$cmd" 2>/dev/null | grep -q "PONG"; then
    record_result "PASS" "Redis" "ping OK"
  else
    record_result "FAIL" "Redis" "Redis не ответил PONG"
  fi
}

check_disk_usage() {
  log "Проверка дискового пространства..."
  local usageLine
  usageLine=$(df -h "$PROJECT_DIR" | tail -1)
  local percent
  percent=$(echo "$usageLine" | awk '{print $5}' | tr -d '%')
  local detail=$(echo "$usageLine" | awk '{print $3 "/" $2 " используется"}')

  if [[ -z "$percent" ]]; then
    record_result "WARN" "Диск" "Не удалось определить использование"
    return
  fi

  if (( percent >= 90 )); then
    record_result "FAIL" "Диск" "$percent% - $detail"
  elif (( percent >= 80 )); then
    record_result "WARN" "Диск" "$percent% - $detail"
  else
    record_result "PASS" "Диск" "$percent% - $detail"
  fi
}

check_logs() {
  log "Анализ логов за последние 30 минут..."
  local count
  count=$(compose logs --since 30m 2>/dev/null | grep -i -E "(ERROR|FATAL|CRITICAL)" | wc -l || echo "0")

  if [[ "$count" -eq 0 ]]; then
    record_result "PASS" "Логи" "Критические ошибки не найдены"
  elif [[ "$count" -le 10 ]]; then
    record_result "WARN" "Логи" "$count критических записей за 30 мин"
  else
    record_result "FAIL" "Логи" "$count критических записей за 30 мин"
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
    echo "| Статус | Проверка | Детали |"
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
