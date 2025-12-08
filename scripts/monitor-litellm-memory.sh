#!/bin/bash

# LiteLLM Memory Monitoring Script for ERNI-KI
# Automatic memory check every 5 minutes (intended for cron)
# Created: 2025-09-09 to address critical memory issue

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
CONTAINER_NAME="erni-ki-litellm"
MEMORY_THRESHOLD=90  # Memory usage percent threshold for alert
LOG_FILE="/var/log/litellm-memory-monitor.log"
WEBHOOK_URL=""  # Optional: webhook URL for notifications

# Logging helper

# Send notification
send_alert() {
    local message="$1"
    local memory_usage="$2"

    log_info "ALERT: $message (Memory: $memory_usage%)"

    # Send to webhook (if configured)
    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"🚨 ERNI-KI LiteLLM Memory Alert: $message (Memory: $memory_usage%)\",\"channel\":\"#alerts\"}" \
            || log_info "Failed to send webhook notification"
    fi

    # Send to system log
    logger -t "litellm-monitor" "CRITICAL: $message (Memory: $memory_usage%)"
}

# Memory check
check_memory() {
    # Get container stats
    local stats
    if ! stats=$(docker stats --no-stream --format "{{.MemPerc}}" "$CONTAINER_NAME" 2>/dev/null); then
        log_info "ERROR: Cannot get stats for container $CONTAINER_NAME"
        return 1
    fi

    # Extract memory percent
    local memory_percent
    memory_percent="${stats//%/}"

    # Validate numeric
    if ! [[ "$memory_percent" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        log_info "ERROR: Invalid memory percentage: $memory_percent"
        return 1
    fi

    # Detailed usage
    local memory_usage
    memory_usage=$(docker stats --no-stream --format "{{.MemUsage}}" "$CONTAINER_NAME" 2>/dev/null)

    log_info "Memory usage: $memory_percent% ($memory_usage)"

    # Threshold check
    if (( $(echo "$memory_percent > $MEMORY_THRESHOLD" | bc) )); then
        send_alert "LiteLLM memory usage exceeded threshold ($MEMORY_THRESHOLD%)" "$memory_percent"

        # Extra diagnostics
        log_info "Container details:"
        docker inspect "$CONTAINER_NAME" --format '{{.HostConfig.Memory}}' | tee -a "$LOG_FILE"

        # Top processes in container
        log_info "Top processes in container:"
        docker exec "$CONTAINER_NAME" ps aux 2>/dev/null | head -10 | tee -a "$LOG_FILE" || true

        return 2  # Return code for threshold breach
    fi

    return 0
}

# Container health check
check_health() {
    local health_status
    health_status=$(docker inspect "$CONTAINER_NAME" --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")

    if [[ "$health_status" != "healthy" ]]; then
        log_info "WARNING: Container health status is '$health_status'"
        return 1
    fi

    return 0
}

# Main
main() {
    log_info "Starting LiteLLM memory monitoring check"

    # Ensure container exists
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "ERROR: Container $CONTAINER_NAME is not running"
        exit 1
    fi

    # Check memory
    local memory_check_result=0
    check_memory || memory_check_result=$?

    # Check health
    local health_check_result=0
    check_health || health_check_result=$?

    # Final status
    if [[ $memory_check_result -eq 2 ]]; then
        log_info "CRITICAL: Memory threshold exceeded"
        exit 2
    elif [[ $memory_check_result -ne 0 || $health_check_result -ne 0 ]]; then
        log_info "WARNING: Some checks failed"
        exit 1
    else
        log_info "OK: All checks passed"
        exit 0
    fi
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Run
main "$@"
