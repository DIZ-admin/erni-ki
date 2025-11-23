#!/bin/bash

# ERNI-KI Backrest Health Monitor
# Automated monitoring of the backup system
# Version: 1.0
# Date: 2025-08-25

set -euo pipefail

# === Configuration ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/backrest-health.log"
ALERT_LOG="$PROJECT_ROOT/logs/backrest-alerts.log"
BACKREST_API="http://localhost:9898"

# Thresholds
MAX_BACKUP_AGE_HOURS=25  # Maximum allowed age of the last backup (hours)
MIN_SNAPSHOTS_COUNT=3    # Minimum required number of snapshots
MAX_REPO_SIZE_GB=5       # Maximum repository size (GB)
CRITICAL_DISK_USAGE=90   # Critical disk usage level (%)

# === Logging helpers ===
log() {
    echo "[$(date -Iseconds)] INFO: $*" | tee -a "$LOG_FILE"
}

warning() {
    echo "[$(date -Iseconds)] WARNING: $*" | tee -a "$LOG_FILE" "$ALERT_LOG"
}

error() {
    echo "[$(date -Iseconds)] ERROR: $*" | tee -a "$LOG_FILE" "$ALERT_LOG"
}

success() {
    echo "[$(date -Iseconds)] SUCCESS: $*" | tee -a "$LOG_FILE"
}

# === Ensure folders exist ===
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$ALERT_LOG")"

# === Backrest availability check ===
check_backrest_availability() {
    log "Checking Backrest API availability..."

    if curl -s -f "$BACKREST_API/" >/dev/null 2>&1; then
        success "Backrest API is reachable"
        return 0
    else
        error "Backrest API is unavailable"
        return 1
    fi
}

# === Container health check ===
check_container_status() {
    log "Checking Docker container status..."

    local container_status
    container_status=$(timeout 10 docker ps --filter "name=backrest" --format "{{.Status}}" 2>/dev/null || echo "not found")

    if [[ "$container_status" == *"healthy"* ]] || [[ "$container_status" == *"Up"* ]]; then
        success "Backrest container is healthy: $container_status"
        return 0
    else
        error "Backrest container issue detected: $container_status"
        return 1
    fi
}

# === Last backup validation ===
check_last_backup() {
    log "Checking time since last backup..."

    local snapshots_count
    snapshots_count=$(timeout 30 docker exec erni-ki-backrest-1 restic -r /backup-sources/.config-backup/repositories/erni-ki-local --password-file /config/repo-password.txt snapshots --json 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")

    if [[ "$snapshots_count" -lt "$MIN_SNAPSHOTS_COUNT" ]]; then
        warning "Insufficient snapshot count: $snapshots_count (required: $MIN_SNAPSHOTS_COUNT)"
        return 1
    fi

    local last_backup_time
    last_backup_time=$(timeout 30 docker exec erni-ki-backrest-1 restic -r /backup-sources/.config-backup/repositories/erni-ki-local --password-file /config/repo-password.txt snapshots --json 2>/dev/null | jq -r '.[-1].time' 2>/dev/null || echo "")

    if [[ -z "$last_backup_time" ]]; then
        error "Unable to determine the last backup timestamp"
        return 1
    fi

    local backup_age_seconds
    backup_age_seconds=$(( $(date +%s) - $(date -d "$last_backup_time" +%s) ))
    local backup_age_hours=$(( backup_age_seconds / 3600 ))

    if [[ "$backup_age_hours" -gt "$MAX_BACKUP_AGE_HOURS" ]]; then
        warning "Last backup is too old: $backup_age_hours hours ago (limit: $MAX_BACKUP_AGE_HOURS)"
        return 1
    else
        success "Last backup age: $backup_age_hours hours (snapshots: $snapshots_count)"
        return 0
    fi
}

# === Repository size check ===
check_repository_size() {
    log "Checking repository size..."

    local repo_size_mb
    repo_size_mb=$(du -sm "$PROJECT_ROOT/.config-backup/repositories/erni-ki-local" 2>/dev/null | cut -f1 || echo "0")
    local repo_size_gb=$(( repo_size_mb / 1024 ))

    if [[ "$repo_size_gb" -gt "$MAX_REPO_SIZE_GB" ]]; then
        warning "Repository size exceeds limit: ${repo_size_gb}GB (max: ${MAX_REPO_SIZE_GB}GB)"
        return 1
    else
        success "Repository size: ${repo_size_mb}MB (${repo_size_gb}GB)"
        return 0
    fi
}

# === Disk usage check ===
check_disk_usage() {
    log "Checking disk usage..."

    local disk_usage
    disk_usage=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')

    if [[ "$disk_usage" -gt "$CRITICAL_DISK_USAGE" ]]; then
        error "Disk usage is critical: ${disk_usage}% (limit: ${CRITICAL_DISK_USAGE}%)"
        return 1
    else
        success "Disk usage: ${disk_usage}%"
        return 0
    fi
}

# === Backrest logs inspection ===
check_backrest_logs() {
    log "Checking Backrest logs for errors..."

    local error_count
    error_count=$(docker logs --since 24h erni-ki-backrest-1 2>&1 | grep -i "error\|failed\|panic" | wc -l || echo "0")

    if [[ "$error_count" -gt 0 ]]; then
        warning "$error_count errors found in logs over the last 24 hours"
        return 1
    else
        success "No errors found in logs"
        return 0
    fi
}

# === Notification helper ===
send_notification() {
    local status="$1"
    local message="$2"

    # Optional webhook notification
    if [[ -x "$PROJECT_ROOT/scripts/backup/backrest-webhook.sh" ]]; then
        "$PROJECT_ROOT/scripts/backup/backrest-webhook.sh" "[$status] $message"
    fi

    # System log entry
    echo "Backrest Health Monitor [$status]: $message" | logger -t "erni-ki-backrest-monitor"
}

# === Monitoring entrypoint ===
main() {
    log "=== Starting Backrest monitoring ==="

    local checks_passed=0
    local checks_total=6
    local critical_issues=0

    # Run all checks
    check_backrest_availability && ((checks_passed++)) || ((critical_issues++))
    check_container_status && ((checks_passed++)) || ((critical_issues++))
    check_last_backup && ((checks_passed++)) || true
    check_repository_size && ((checks_passed++)) || true
    check_disk_usage && ((checks_passed++)) || ((critical_issues++))
    check_backrest_logs && ((checks_passed++)) || true

    # Final summary
    log "=== Monitoring results ==="
    log "Checks passed: $checks_passed/$checks_total"
    log "Critical issues: $critical_issues"

    if [[ "$critical_issues" -eq 0 ]]; then
        if [[ "$checks_passed" -eq "$checks_total" ]]; then
            success "All checks passed successfully"
            send_notification "SUCCESS" "Backrest checks succeeded ($checks_passed/$checks_total)"
            return 0
        else
            warning "Warnings present but no critical issues"
            send_notification "WARNING" "Backrest has warnings ($checks_passed/$checks_total checks passed)"
            return 1
        fi
    else
        error "Critical issues detected"
        send_notification "CRITICAL" "Critical Backrest issues detected ($critical_issues critical, $checks_passed/$checks_total checks passed)"
        return 2
    fi
}

# === Entry point ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
