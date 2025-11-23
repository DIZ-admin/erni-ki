#!/bin/bash

# ============================================================================
# SETUP LOG MONITORING CRON JOB
# Automatic log monitoring for ERNI-KI
# Created: 2025-09-18
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_MONITORING_SCRIPT="$SCRIPT_DIR/log-monitoring.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Configure cron
setup_cron() {
    log "Configuring cron job for log monitoring..."

    # Build temporary cron file
    local temp_cron=$(mktemp)

    # Current cron jobs (excluding this monitoring)
    crontab -l 2>/dev/null | grep -v "log-monitoring.sh" > "$temp_cron" || true

    # Add new jobs (every 30 minutes + daily cleanup)
    cat >> "$temp_cron" << EOF

# ERNI-KI Log Monitoring (added $(date '+%Y-%m-%d'))
# Every 30 minutes: monitor log sizes
*/30 * * * * cd "$PROJECT_ROOT" && "$LOG_MONITORING_SCRIPT" >> "$PROJECT_ROOT/logs/log-monitoring-cron.log" 2>&1

# ERNI-KI Log Monitoring - daily cleanup at 03:00
0 3 * * * cd "$PROJECT_ROOT" && "$LOG_MONITORING_SCRIPT" --cleanup >> "$PROJECT_ROOT/logs/log-monitoring-cron.log" 2>&1
EOF

    # Install new crontab
    crontab "$temp_cron"
    rm -f "$temp_cron"

    success "Cron jobs configured:"
    echo "  - Monitoring every 30 minutes"
    echo "  - Daily cleanup at 03:00"
}

# Check cron
check_cron() {
    log "Checking current cron jobs..."

    local cron_jobs=$(crontab -l 2>/dev/null | grep -c "log-monitoring.sh" || echo "0")

    if [[ "$cron_jobs" -gt 0 ]]; then
        success "Found $cron_jobs cron jobs for log monitoring"
        echo
        echo "Current jobs:"
        crontab -l | grep "log-monitoring.sh" || true
    else
        warn "No cron jobs found for log monitoring"
        return 1
    fi
}

# Remove cron jobs
remove_cron() {
    log "Removing log monitoring cron jobs..."

    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "log-monitoring.sh" > "$temp_cron" || true
    crontab "$temp_cron"
    rm -f "$temp_cron"

    success "Cron jobs removed"
}

# Create systemd timer (alternative to cron)
setup_systemd_timer() {
    log "Configuring systemd timer for log monitoring..."

    # Create service file
    sudo tee /etc/systemd/system/erni-ki-log-monitoring.service > /dev/null << EOF
[Unit]
Description=ERNI-KI Log Monitoring
After=docker.service

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$PROJECT_ROOT
ExecStart=$LOG_MONITORING_SCRIPT
StandardOutput=append:$PROJECT_ROOT/logs/log-monitoring-systemd.log
StandardError=append:$PROJECT_ROOT/logs/log-monitoring-systemd.log
EOF

    # Create timer file
    sudo tee /etc/systemd/system/erni-ki-log-monitoring.timer > /dev/null << EOF
[Unit]
Description=Run ERNI-KI Log Monitoring every 30 minutes
Requires=erni-ki-log-monitoring.service

[Timer]
OnCalendar=*:0/30
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Reload systemd and start timer
    sudo systemctl daemon-reload
    sudo systemctl enable erni-ki-log-monitoring.timer
    sudo systemctl start erni-ki-log-monitoring.timer

    success "Systemd timer configured and started"
}

# Main
main() {
    echo "============================================================================"
    echo "🔧 ERNI-KI LOG MONITORING CRON SETUP"
    echo "============================================================================"

    case "${1:-setup}" in
        "setup"|"install")
            setup_cron
            ;;
        "check"|"status")
            check_cron
            ;;
        "remove"|"uninstall")
            remove_cron
            ;;
        "systemd")
            setup_systemd_timer
            ;;
        *)
            echo "Usage: $0 [setup|check|remove|systemd]"
            echo
            echo "Commands:"
            echo "  setup    - Configure cron jobs (default)"
            echo "  check    - Check current cron jobs"
            echo "  remove   - Remove cron jobs"
            echo "  systemd  - Configure systemd timer (alternative to cron)"
            exit 1
            ;;
    esac

    echo "============================================================================"
}

# Запуск скрипта
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
