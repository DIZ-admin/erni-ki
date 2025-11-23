#!/bin/bash

# ============================================================================
# ERNI-KI LOG MONITORING SCRIPT
# Automated log size and performance monitoring
# Created: 2025-09-18 as part of logging improvements
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
ALERT_THRESHOLD_GB=1
CRITICAL_THRESHOLD_GB=5
WEBHOOK_URL="${LOG_MONITORING_WEBHOOK_URL:-}"
COMPOSE_FILE="$PROJECT_ROOT/compose.yml"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Webhook sender
send_webhook() {
    local message="$1"
    local severity="${2:-info}"

    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"🔍 ERNI-KI Log Monitor: $message\", \"severity\":\"$severity\"}" \
            >/dev/null 2>&1 || warn "Failed to send webhook notification"
    fi
}

# Docker log size check
check_docker_logs() {
    log "Checking Docker container log sizes..."

    local total_size=0
    local alerts=()

    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            local log_file="/var/lib/docker/containers/$container/$container-json.log"
            if [[ -f "$log_file" ]]; then
                local size_bytes=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
                local size_mb=$((size_bytes / 1024 / 1024))
                total_size=$((total_size + size_mb))

                if [[ $size_mb -gt 100 ]]; then
                    local container_name=$(docker inspect --format='{{.Name}}' "$container" 2>/dev/null | sed 's/^\/*//' || echo "unknown")
                    alerts+=("$container_name: ${size_mb}MB")
                fi
            fi
        fi
    done < <(docker ps -q)

    local total_gb=$((total_size / 1024))

    echo "📊 Total Docker log size: ${total_gb}GB (${total_size}MB)"

    if [[ $total_gb -gt $CRITICAL_THRESHOLD_GB ]]; then
        error "CRITICAL log usage: ${total_gb}GB > ${CRITICAL_THRESHOLD_GB}GB"
        send_webhook "🚨 Critical log usage: ${total_gb}GB" "critical"
        return 2
    elif [[ $total_gb -gt $ALERT_THRESHOLD_GB ]]; then
        warn "Warning threshold exceeded: ${total_gb}GB > ${ALERT_THRESHOLD_GB}GB"
        send_webhook "⚠️ Log warning threshold exceeded: ${total_gb}GB" "warning"
        return 1
    else
        success "Log size is within limits: ${total_gb}GB"
        return 0
    fi
}

# Fluent Bit performance check
check_fluent_bit_performance() {
    log "Checking Fluent Bit performance..."

    local container_name="erni-ki-fluent-bit"

    # Check CPU and memory
    local stats=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" "$container_name" 2>/dev/null || echo "N/A	N/A")
    local cpu_percent=$(echo "$stats" | tail -n1 | awk '{print $1}' | sed 's/%//')
    local mem_usage=$(echo "$stats" | tail -n1 | awk '{print $2}')

    echo "📈 Fluent Bit performance:"
    echo "   CPU: ${cpu_percent}%"
    echo "   Memory: $mem_usage"

    # Metrics via API
    local metrics_response=$(curl -s "http://localhost:2020/api/v1/metrics" 2>/dev/null || echo "{}")
    local input_records=$(echo "$metrics_response" | jq -r '.input.forward.records // 0' 2>/dev/null || echo "0")
    local output_records=$(echo "$metrics_response" | jq -r '.output.loki.proc_records // 0' 2>/dev/null || echo "0")

    echo "   Input records: $input_records"
    echo "   Output records: $output_records"

    # Errors in the last hour
    local error_count=$(docker logs "$container_name" --since 1h 2>/dev/null | grep -c -E "(ERROR|error)" || echo "0")
    echo "   Errors (1h): $error_count"

    if [[ "$error_count" -gt 50 ]]; then
        warn "High error count in Fluent Bit: $error_count in the last hour"
        send_webhook "⚠️ Fluent Bit errors: $error_count/hour" "warning"
        return 1
    else
        success "Fluent Bit is stable"
        return 0
    fi
}

# Loki API availability check
check_loki_api() {
    log "Checking Loki API availability..."

    # Local API check
    local local_status=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Scope-OrgID: erni-ki" "http://localhost:3100/ready" 2>/dev/null || echo "000")

    # API check through nginx
    local nginx_status=$(curl -k -s -o /dev/null -w "%{http_code}" -H "X-Scope-OrgID: erni-ki" "https://localhost/loki/api/v1/labels" 2>/dev/null || echo "000")

    echo "🔗 Loki API status:"
    echo "   Local API: $local_status"
    echo "   Nginx proxy: $nginx_status"

    if [[ "$local_status" == "200" && "$nginx_status" == "200" ]]; then
        success "Loki API is fully available"
        return 0
    else
        error "Loki API availability issues"
        send_webhook "🚨 Loki API unavailable (local: $local_status, nginx: $nginx_status)" "critical"
        return 1
    fi
}

# Remove old logs when thresholds are breached
cleanup_old_logs() {
    log "Cleaning up old logs..."

    local cleaned_files=0

    # Remove log files older than 7 days from logs/
    if [[ -d "$LOG_DIR" ]]; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            ((cleaned_files++))
        done < <(find "$LOG_DIR" -name "*.log" -type f -mtime +7 -print0 2>/dev/null)
    fi

    # Rotate Docker logs if usage is critical
    local total_size_gb=$(check_docker_logs | grep "Total Docker log size" | awk '{print $5}' | sed 's/GB.*//' || echo "0")

    if [[ "${total_size_gb:-0}" -gt $CRITICAL_THRESHOLD_GB ]]; then
        log "Force rotating Docker logs..."
        docker system prune -f --volumes >/dev/null 2>&1 || warn "Failed to run docker system prune"
    fi

    success "Cleaned files: $cleaned_files"
}

# Report generation
generate_report() {
    local timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local report_file="$LOG_DIR/log-monitoring-report-$timestamp.json"

    log "Generating report: $report_file"

    # Ensure log directory exists
    mkdir -p "$LOG_DIR"

    # Collect check outputs
    local docker_log_check=$(check_docker_logs 2>&1)
    local fluent_bit_check=$(check_fluent_bit_performance 2>&1)
    local loki_api_check=$(check_loki_api 2>&1)

    # Build JSON report
    cat > "$report_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "version": "1.0",
  "system": "ERNI-KI",
  "checks": {
    "docker_logs": {
      "output": $(echo "$docker_log_check" | jq -Rs .)
    },
    "fluent_bit": {
      "output": $(echo "$fluent_bit_check" | jq -Rs .)
    },
    "loki_api": {
      "output": $(echo "$loki_api_check" | jq -Rs .)
    }
  },
  "thresholds": {
    "alert_gb": $ALERT_THRESHOLD_GB,
    "critical_gb": $CRITICAL_THRESHOLD_GB
  }
}
EOF

    success "Report saved: $report_file"
}

# Main entrypoint
main() {
    echo "============================================================================"
    echo "🔍 ERNI-KI LOG MONITORING - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================================================"

    local exit_code=0

    # Docker logs
    check_docker_logs || exit_code=$?
    echo

    # Fluent Bit
    check_fluent_bit_performance || exit_code=$?
    echo

    # Loki API
    check_loki_api || exit_code=$?
    echo

    # Cleanup if needed
    if [[ $exit_code -gt 1 ]]; then
        cleanup_old_logs
        echo
    fi

    # Report
    generate_report
    echo

    # Final status
    case $exit_code in
        0)
            success "✅ All checks passed"
            send_webhook "✅ Log monitoring: all systems healthy" "info"
            ;;
        1)
            warn "⚠️ Warnings detected"
            ;;
        2)
            error "🚨 Critical issues detected"
            ;;
    esac

    echo "============================================================================"
    exit $exit_code
}

# Script entry
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
