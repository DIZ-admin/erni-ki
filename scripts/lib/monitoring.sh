#!/usr/bin/env bash
# Common monitoring functions for ERNI-KI
# Provides shared utilities for health checks and system monitoring

set -euo pipefail

# Source project common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

# Send alert to webhook and log file
# Arguments: severity, message, webhook_url (optional)
# Example: send_alert "critical" "Service down" "https://webhook.url"
send_alert() {
    local severity="$1"
    local message="$2"
    local webhook_url="${3:-${ALERT_WEBHOOK:-}}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Log alert locally if LOG_DIR is set
    if [[ -n "${LOG_DIR:-}" ]]; then
        local alert_json
        alert_json=$(printf '{"timestamp":"%s","severity":"%s","message":"%s","service":"erni-ki"}\n' \
            "$timestamp" "$severity" "$message")
        echo "$alert_json" >> "$LOG_DIR/alerts.json"
    fi

    # Send webhook if configured
    if [[ -n "$webhook_url" ]]; then
        curl -s -X POST "$webhook_url" \
            -H "Content-Type: application/json" \
            -d "{\"timestamp\":\"$timestamp\",\"severity\":\"$severity\",\"message\":\"$message\",\"service\":\"erni-ki\"}" \
            || log_warn "Failed to send webhook alert"
    fi
}

# Check system resources (CPU, memory, disk, GPU)
# Arguments: metrics_dir (optional)
# Example: check_system_resources "/path/to/metrics"
check_system_resources() {
    local metrics_dir="${1:-${METRICS_DIR:-}}"

    log_info "Checking system resource usage..."

    # CPU usage (Linux-specific)
    local cpu_usage=0
    if command -v top >/dev/null 2>&1; then
        cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "0")
        cpu_usage=${cpu_usage%.*}  # Remove decimals
    fi

    # Memory usage
    local memory_usage=0
    if command -v free >/dev/null 2>&1; then
        local memory_info
        memory_info=$(free 2>/dev/null | grep Mem || echo "")
        if [[ -n "$memory_info" ]]; then
            local total_mem used_mem
            total_mem=$(echo "$memory_info" | awk '{print $2}')
            used_mem=$(echo "$memory_info" | awk '{print $3}')
            if [[ -n "$total_mem" && "$total_mem" -gt 0 ]]; then
                memory_usage=$((used_mem * 100 / total_mem))
            fi
        fi
    fi

    # Disk usage
    local disk_usage
    disk_usage=$(df / 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")

    # GPU metrics (if available)
    local gpu_usage="N/A"
    local gpu_memory="N/A"
    local gpu_temp="N/A"

    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "N/A")
        gpu_memory=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "N/A")
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "N/A")
    fi

    # Log resource snapshot
    log_info "CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Disk: ${disk_usage}%"
    if [[ "$gpu_usage" != "N/A" ]]; then
        log_info "GPU: ${gpu_usage}%, GPU Memory: ${gpu_memory}, GPU Temperature: ${gpu_temp}°C"
    fi

    # Save metrics if directory provided
    if [[ -n "$metrics_dir" ]]; then
        mkdir -p "$metrics_dir"
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local metrics_json
        metrics_json=$(printf '{"timestamp":"%s","cpu_usage":%s,"memory_usage":%s,"disk_usage":%s,"gpu_usage":"%s","gpu_memory":"%s","gpu_temperature":"%s"}\n' \
            "$timestamp" "$cpu_usage" "$memory_usage" "$disk_usage" "$gpu_usage" "$gpu_memory" "$gpu_temp")
        echo "$metrics_json" >> "$metrics_dir/system-resources.json"
    fi

    # Resource alerts
    if [[ "$cpu_usage" -gt 85 ]]; then
        send_alert "warning" "High CPU usage: ${cpu_usage}%"
    fi

    if [[ "$memory_usage" -gt 90 ]]; then
        send_alert "critical" "Critically high memory usage: ${memory_usage}%"
    elif [[ "$memory_usage" -gt 80 ]]; then
        send_alert "warning" "High memory usage: ${memory_usage}%"
    fi

    if [[ "$disk_usage" -gt 90 ]]; then
        send_alert "critical" "Critically low disk space: ${disk_usage}%"
    elif [[ "$disk_usage" -gt 80 ]]; then
        send_alert "warning" "Low disk space: ${disk_usage}%"
    fi
}
