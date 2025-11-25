#!/bin/bash

# ERNI-KI Rate Limiting Monitor
# Monitoring and analysis of nginx rate limiting events
# Author: Alteon Schultz (Tech Lead)

set -euo pipefail

# === Configuration ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/rate-limiting-monitor.log"
STATE_FILE="$PROJECT_ROOT/logs/rate-limiting-state.json"
ALERT_THRESHOLD=10  # Alert when >10 blocks per minute
WARNING_THRESHOLD=5 # Warning when >5 blocks per minute
CHECK_INTERVAL=60   # Check interval in seconds
NGINX_ACCESS_LOG="${NGINX_ACCESS_LOG:-$PROJECT_ROOT/data/nginx/logs/access.log}"
COMPOSE_BIN="${DOCKER_COMPOSE_BIN:-docker compose}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# === Logging helpers ===
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $*" | tee -a "$LOG_FILE"
}

warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" | tee -a "$LOG_FILE"
}

# === Rate limiting analysis ===
analyze_rate_limiting() {
    local time_window="${1:-1m}"  # Default: last minute

    log "Analyzing rate limiting for the last $time_window"

    # Get nginx logs for the requested window
    local nginx_logs=""
    nginx_logs=$($COMPOSE_BIN -f "$PROJECT_ROOT/compose.yml" logs nginx --since "$time_window" 2>/dev/null || echo "")

    if [[ -z "$nginx_logs" && -f "$NGINX_ACCESS_LOG" ]]; then
        local since_epoch
        local minutes_window="$time_window"
        if [[ "$minutes_window" == *m ]]; then
            minutes_window="${minutes_window%m}"
        fi
        since_epoch=$(date -u -d "${minutes_window:-1} minutes ago" +%s)
        nginx_logs=$(python3 - "$NGINX_ACCESS_LOG" "$since_epoch" <<'PY'
import collections
import datetime as dt
import sys

if len(sys.argv) < 3:
    sys.exit(0)

path = sys.argv[1]
since = int(sys.argv[2])

buffer = collections.deque(maxlen=5000)

try:
    with open(path, "r", encoding="utf-8", errors="ignore") as log_file:
        for line in log_file:
            buffer.append(line)
except FileNotFoundError:
    sys.exit(0)

for line in buffer:
    try:
        ts = line.split('[', 1)[1].split(']', 1)[0]
        parsed = dt.datetime.strptime(ts, "%d/%b/%Y:%H:%M:%S %z")
    except (IndexError, ValueError):
        continue

    if int(parsed.timestamp()) >= since:
        sys.stdout.write(line)
PY
        )
    fi

    if [[ -z "$nginx_logs" ]]; then
        log "No nginx logs for the selected window; assuming zero blocks"
    fi

    # Count rate limiting errors
    local total_blocks
    total_blocks=$(printf '%s\n' "$nginx_logs" | grep -c "limiting requests" || true)

    # Zone stats
    local zones_stats
    zones_stats=$(printf '%s\n' "$nginx_logs" | grep "limiting requests" | grep -o 'zone "[^"]*"' | sort | uniq -c || echo "")

    # IP stats
    local ip_stats
    ip_stats=$(printf '%s\n' "$nginx_logs" | grep "limiting requests" | grep -o 'client: [^,]*' | sort | uniq -c | head -10 || echo "")

    # Max excess
    local max_excess
    max_excess=$(printf '%s\n' "$nginx_logs" | grep "limiting requests" | grep -o 'excess: [0-9.]*' | sort -n | tail -1 | tr -d '\n' || echo "0")

    # Build JSON report
    local report
    report=$(cat <<EOF
{
    "timestamp": "$(date -Iseconds)",
    "time_window": "$time_window",
    "total_blocks": $total_blocks,
    "max_excess": "${max_excess#excess: }",
    "zones": $(echo "$zones_stats" | awk '{print "{\"zone\":\""$2"\",\"count\":"$1"}"}' | jq -s '.' 2>/dev/null || echo "[]"),
    "top_ips": $(echo "$ip_stats" | awk '{print "{\"ip\":\""$3"\",\"count\":"$1"}"}' | jq -s '.' 2>/dev/null || echo "[]")
}
EOF
    )

    # Persist state
    echo "$report" > "$STATE_FILE"

    # Log results
    log "Rate limiting stats:"
    log "  - Total blocks: $total_blocks"
    log "  - Max excess: ${max_excess#excess: }"

    if [[ -n "$zones_stats" ]]; then
        log "  - By zones:"
        echo "$zones_stats" | while read -r count zone; do
            log "    $zone: $count blocks"
        done
    fi

    # Threshold checks + alerts
    check_thresholds "$total_blocks" "$report"

    return 0
}

# === Threshold checks ===
check_thresholds() {
    local total_blocks="$1"
    local report="$2"

    if [[ $total_blocks -ge $ALERT_THRESHOLD ]]; then
        send_alert "CRITICAL" "Rate limiting exceeded critical threshold: $total_blocks blocks per minute (threshold: $ALERT_THRESHOLD)" "$report"
    elif [[ $total_blocks -ge $WARNING_THRESHOLD ]]; then
        send_alert "WARNING" "Rate limiting exceeded warning threshold: $total_blocks blocks per minute (threshold: $WARNING_THRESHOLD)" "$report"
    fi
}

# === Alert sending ===
send_alert() {
    local level="$1"
    local message="$2"
    local report="$3"

    log "[$level] $message"

    # Send to system journal
    logger -t "erni-ki-rate-limiting" "[$level] $message"

    # Store alert to file
    local alert_file="$PROJECT_ROOT/logs/rate-limiting-alerts.log"
    echo "[$(date -Iseconds)] [$level] $message" >> "$alert_file"
    echo "$report" >> "$alert_file"
    echo "---" >> "$alert_file"

    # Backrest integration (if available)
    if command -v curl >/dev/null 2>&1; then
        send_backrest_notification "$level" "$message" || true
    fi
}

# === Send notification via Backrest ===
send_backrest_notification() {
    local level="$1"
    local message="$2"

    # Attempt Backrest webhook (if configured)
    local backrest_url="http://localhost:9898/api/v1/notifications"

    local payload
    payload=$(cat <<EOF
{
    "title": "ERNI-KI Rate Limiting Alert",
    "message": "$message",
    "level": "$level",
    "timestamp": "$(date -Iseconds)",
    "source": "nginx-rate-limiting-monitor"
}
EOF
    )

    if curl -s -f -X POST "$backrest_url" \
        -H "Content-Type: application/json" \
        -d "$payload" >/dev/null 2>&1; then
        log "Notification delivered via Backrest"
    else
        log "Failed to send notification via Backrest"
    fi
}

# === Get statistics ===
get_statistics() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{"error": "No statistics available"}'
    fi
}

# === Nginx health check ===
check_nginx_health() {
    log "Checking nginx health..."

    if $COMPOSE_BIN -f "$PROJECT_ROOT/compose.yml" exec -T nginx nginx -t >/dev/null 2>&1; then
        success "nginx configuration is valid"
    else
        error "nginx configuration errors detected"
        return 1
    fi

    # Availability check
    if curl -s -f http://localhost/ >/dev/null 2>&1; then
        success "nginx responds to requests"
    else
        error "nginx does not respond to requests"
        return 1
    fi

    return 0
}

# === Main ===
main() {
    case "${1:-monitor}" in
        "monitor")
            log "Starting rate limiting monitor"
            analyze_rate_limiting "1m"
            ;;
        "stats")
            get_statistics
            ;;
        "health")
            check_nginx_health
            ;;
        "daemon")
            log "Starting monitoring daemon (interval: ${CHECK_INTERVAL}s)"
            while true; do
                analyze_rate_limiting "1m"
                sleep "$CHECK_INTERVAL"
            done
            ;;
        "help"|"-h"|"--help")
            cat <<EOF
ERNI-KI Rate Limiting Monitor

Usage:
  $0 [command]

Commands:
  monitor    Single rate-limiting check (default)
  stats      Show last statistics
  health     Check nginx health
  daemon     Run in daemon mode
  help       Show this help

Examples:
  $0                    # Single check
  $0 daemon             # Run as daemon
  $0 stats | jq         # Show statistics as JSON
EOF
            ;;
        *)
            error "Unknown command: $1"
            echo "Use '$0 help' for usage"
            exit 1
            ;;
    esac
}

# Entrypoint
main "$@"
