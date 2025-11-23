#!/bin/bash

# Circuit Breaker Monitor for the ERNI-KI logging stack
# Phase 3: Monitoring and alerting to prevent cascading failures
# Version: 1.0 - Production Ready

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLUENT_BIT_URL="http://localhost:2020"
LOKI_URL="http://localhost:3100"
LOKI_TENANT_HEADER="X-Scope-OrgID: erni-ki"
PROMETHEUS_URL="http://localhost:9090"

# Circuit breaker thresholds
ERROR_THRESHOLD=10          # Max errors in a 5-minute window
RETRY_THRESHOLD=50          # Max retries in a 5-minute window
BUFFER_THRESHOLD=80         # Max buffer utilization (%)
RESPONSE_TIME_THRESHOLD=5   # Max response time (seconds)

# ============================================================================
# MONITORING FUNCTIONS
# ============================================================================

check_fluent_bit_health() {
    echo "=== FLUENT BIT HEALTH CHECK ==="

    # Verify API availability
    if ! curl -s --max-time 5 "$FLUENT_BIT_URL/api/v1/health" > /dev/null; then
        echo "❌ Fluent Bit API is unreachable"
        return 1
    fi

    # Retrieve metrics
    local metrics=$(curl -s --max-time 5 "$FLUENT_BIT_URL/api/v1/metrics" 2>/dev/null || echo '{}')

    # Evaluate errors/retries
    local errors=$(echo "$metrics" | jq -r '.output.["loki.0"].errors // 0')
    local retries=$(echo "$metrics" | jq -r '.output.["loki.0"].retries // 0')

    echo "Errors: $errors (threshold: $ERROR_THRESHOLD)"
    echo "Retries: $retries (threshold: $RETRY_THRESHOLD)"

    # Circuit breaker logic
    if [ "$errors" -gt "$ERROR_THRESHOLD" ]; then
        echo "🔴 CIRCUIT BREAKER: Error threshold exceeded ($errors > $ERROR_THRESHOLD)"
        trigger_circuit_breaker "errors" "$errors"
        return 1
    fi

    if [ "$retries" -gt "$RETRY_THRESHOLD" ]; then
        echo "🟡 WARNING: High retry count ($retries > $RETRY_THRESHOLD)"
        trigger_warning "retries" "$retries"
    fi

    echo "✅ Fluent Bit is healthy"
    return 0
}

check_loki_health() {
    echo "=== LOKI HEALTH CHECK ==="

    # Verify Loki readiness
    local start_time=$(date +%s)
    if ! curl -s --max-time "$RESPONSE_TIME_THRESHOLD" -H "$LOKI_TENANT_HEADER" "$LOKI_URL/ready" > /dev/null; then
        echo "❌ Loki is unavailable or slow to respond"
        trigger_circuit_breaker "loki_unavailable" "timeout"
        return 1
    fi
    local end_time=$(date +%s)
    local response_time=$((end_time - start_time))

    echo "Loki response time: ${response_time}s (threshold: ${RESPONSE_TIME_THRESHOLD}s)"

    if [ "$response_time" -gt "$RESPONSE_TIME_THRESHOLD" ]; then
        echo "🟡 WARNING: Slow Loki response (${response_time}s > ${RESPONSE_TIME_THRESHOLD}s)"
        trigger_warning "loki_slow" "$response_time"
    fi

    echo "✅ Loki is healthy"
    return 0
}

check_system_resources() {
    echo "=== SYSTEM RESOURCE CHECK ==="

    # Check disk usage
    local disk_usage=$(df -h data/logs-optimized 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")
    echo "Log volume disk usage: ${disk_usage}%"

    if [ "$disk_usage" -gt 90 ]; then
        echo "🔴 CIRCUIT BREAKER: Disk usage critical (${disk_usage}% > 90%)"
        trigger_circuit_breaker "disk_full" "$disk_usage"
        return 1
    elif [ "$disk_usage" -gt 80 ]; then
        echo "🟡 WARNING: Elevated disk usage (${disk_usage}% > 80%)"
        trigger_warning "disk_usage" "$disk_usage"
    fi

    # Check logging container memory
    local fluent_memory=$(docker stats --no-stream --format "{{.MemPerc}}" erni-ki-fluent-bit 2>/dev/null | sed 's/%//' || echo "0")
    echo "Fluent Bit memory usage: ${fluent_memory}%"

    if [ "${fluent_memory%.*}" -gt 80 ]; then
        echo "🟡 WARNING: Fluent Bit memory usage high (${fluent_memory}% > 80%)"
        trigger_warning "memory_usage" "$fluent_memory"
    fi

    echo "✅ System resources are within limits"
    return 0
}

# ============================================================================
# CIRCUIT BREAKER ACTIONS
# ============================================================================

trigger_circuit_breaker() {
    local reason="$1"
    local value="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "🔴 CIRCUIT BREAKER TRIGGERED: $reason = $value"

    # Log the event
    echo "[$timestamp] CIRCUIT_BREAKER_TRIGGERED: reason=$reason value=$value" >> "$PROJECT_ROOT/.config-backup/logs/circuit-breaker.log"

    # Notify via webhook (if configured)
    if command -v curl > /dev/null; then
        curl -s -X POST "http://localhost:9095/webhook/circuit-breaker" \
            -H "Content-Type: application/json" \
            -d "{\"reason\":\"$reason\",\"value\":\"$value\",\"timestamp\":\"$timestamp\",\"severity\":\"critical\"}" \
            > /dev/null 2>&1 || true
    fi

    # Apply mitigation steps
    case "$reason" in
        "errors"|"loki_unavailable")
            echo "Applying mitigation: enabling local log fallback"
            enable_local_fallback
            ;;
        "disk_full")
            echo "Applying mitigation: emergency log cleanup"
            emergency_log_cleanup
            ;;
    esac
}

trigger_warning() {
    local reason="$1"
    local value="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "🟡 WARNING: $reason = $value"

    # Log warning
    echo "[$timestamp] WARNING: reason=$reason value=$value" >> "$PROJECT_ROOT/.config-backup/logs/circuit-breaker.log"

    # Send webhook notification
    if command -v curl > /dev/null; then
        curl -s -X POST "http://localhost:9095/webhook/warning" \
            -H "Content-Type: application/json" \
            -d "{\"reason\":\"$reason\",\"value\":\"$value\",\"timestamp\":\"$timestamp\",\"severity\":\"warning\"}" \
            > /dev/null 2>&1 || true
    fi
}

enable_local_fallback() {
    echo "Enabling local log fallback mode..."

    # Create temporary configuration with local output
    local fallback_config="$PROJECT_ROOT/conf/fluent-bit/fluent-bit-fallback.conf"

    # Copy base configuration and adjust
    cp "$PROJECT_ROOT/conf/fluent-bit/fluent-bit.conf" "$fallback_config"

    # Append local output
    cat >> "$fallback_config" << EOF

# EMERGENCY FALLBACK OUTPUT - Circuit Breaker activated
[OUTPUT]
    Name        file
    Match       *
    Path        /var/log/emergency
    File        emergency-logs.txt
    Format      json_lines

EOF

    echo "✅ Local fallback mode configured"
}

emergency_log_cleanup() {
    echo "Executing emergency log cleanup..."

    # Archive/remove older logs
    find "$PROJECT_ROOT/data/logs-optimized" -name "*.log" -mtime +7 -exec gzip {} \; 2>/dev/null || true
    find "$PROJECT_ROOT/data/logs-optimized" -name "*.gz" -mtime +30 -delete 2>/dev/null || true

    # Clean Docker logs
    docker system prune -f --volumes > /dev/null 2>&1 || true

    echo "✅ Emergency log cleanup finished"
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

main() {
    echo "🔍 Starting Circuit Breaker Monitor for ERNI-KI logging"
    echo "Timestamp: $(date)"
    echo ""

    local overall_status=0

    # Ensure log directory exists
    mkdir -p "$PROJECT_ROOT/.config-backup/logs"

    # Check all components
    check_fluent_bit_health || overall_status=1
    echo ""

    check_loki_health || overall_status=1
    echo ""

    check_system_resources || overall_status=1
    echo ""

    if [ $overall_status -eq 0 ]; then
        echo "🎉 Logging systems are operating normally"
    else
        echo "⚠️  Logging issues detected — mitigation steps applied"
    fi

    return $overall_status
}

# Kick off monitor
main "$@"
