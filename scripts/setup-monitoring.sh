#!/bin/bash

# 📊 ERNI-KI Monitoring Setup Script
# Monitoring and logging setup
# Author: Alteon Schulz, Tech Lead

set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CRON_FILE="/tmp/erni-ki-monitoring-cron"

# === COLORS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === FUNCTIONS ===
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# === DIRECTORY SETUP ===
setup_directories() {
    log_info "Creating monitoring directories..."

    mkdir -p "$PROJECT_DIR/.config-backup/monitoring"
    mkdir -p "$PROJECT_DIR/.config-backup/logs"
    mkdir -p "$PROJECT_DIR/scripts"

    log_success "Directories created"
}

# === CRON JOBS ===
setup_cron() {
    log_info "Configuring cron jobs for automated monitoring..."

    # Create cron file
    cat > "$CRON_FILE" << EOF
# ERNI-KI System Monitoring
# Automated system monitoring

# Hourly check
0 * * * * cd $PROJECT_DIR && ./scripts/health-monitor-v2.sh >> .config-backup/monitoring/cron.log 2>&1

# Daily cleanup of old logs (older than 7 days)
0 2 * * * find $PROJECT_DIR/.config-backup/monitoring -name "health-report-*.md" -mtime +7 -delete

# Weekly full report (Sunday 03:00)
0 3 * * 0 cd $PROJECT_DIR && ./scripts/health-monitor-v2.sh > .config-backup/monitoring/weekly-report-\$(date +\%Y\%m\%d).md 2>&1
EOF

    # Install cron jobs
    if crontab -l > /dev/null 2>&1; then
        # Append to existing crontab
        (crontab -l; cat "$CRON_FILE") | crontab -
    else
        # Create new crontab
        crontab "$CRON_FILE"
    fi

    rm -f "$CRON_FILE"

    log_success "Cron jobs configured:"
    log_info "  - Hourly system check"
    log_info "  - Daily log cleanup"
    log_info "  - Weekly full report"
}

# === LOGGING LEVELS ===
setup_logging_levels() {
    log_info "Configuring optimal logging levels..."

    cd "$PROJECT_DIR"

    # Create configuration backup
    local backup_dir
    backup_dir=".config-backup/logging-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup key configs
    if [[ -f "env/openwebui.env" ]]; then
        cp "env/openwebui.env" "$backup_dir/"
    fi

    if [[ -f "env/ollama.env" ]]; then
        cp "env/ollama.env" "$backup_dir/"
    fi

    log_success "Backups created in $backup_dir"

    # OpenWebUI logging (reduce noise)
    if grep -q "LOG_LEVEL" env/openwebui.env; then
        log_info "LOG_LEVEL already set in OpenWebUI"
    else
        echo "" >> env/openwebui.env
        echo "# === LOGGING SETTINGS ===" >> env/openwebui.env
        echo "# Logging level (INFO for prod, DEBUG for troubleshooting)" >> env/openwebui.env
        echo "LOG_LEVEL=INFO" >> env/openwebui.env
        log_success "Added LOG_LEVEL=INFO to OpenWebUI"
    fi

    # Ollama logging
    if grep -q "OLLAMA_LOG_LEVEL" env/ollama.env; then
        log_info "OLLAMA_LOG_LEVEL already set"
    else
        echo "" >> env/ollama.env
        echo "# === LOGGING SETTINGS ===" >> env/ollama.env
        echo "# Ollama log level (INFO for production)" >> env/ollama.env
        echo "OLLAMA_LOG_LEVEL=INFO" >> env/ollama.env
        log_success "Added OLLAMA_LOG_LEVEL=INFO to Ollama"
    fi
}

# === ALERTS SETUP ===
setup_alerts() {
    log_info "Creating alert system..."

    # Create critical alert script
    cat > "$PROJECT_DIR/scripts/critical-alert.sh" << 'EOF'
#!/bin/bash
# Critical alert sender
set -euo pipefail

ALERT_TYPE="$1"
MESSAGE="$2"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log alert
echo "[$TIMESTAMP] CRITICAL ALERT: $ALERT_TYPE - $MESSAGE" >> .config-backup/monitoring/critical-alerts.log

# Add notification transport here if needed:
# - Email / Slack / Discord webhook / Telegram / SMS

echo "CRITICAL ALERT: $ALERT_TYPE"
echo "Message: $MESSAGE"
echo "Time: $TIMESTAMP"
EOF

    chmod +x "$PROJECT_DIR/scripts/critical-alert.sh"

    log_success "Alert script created"
}

# === MONITORING TEST ===
test_monitoring() {
    log_info "Testing monitoring system..."

    cd "$PROJECT_DIR"

    # Run test check
    if ./scripts/health-monitor-v2.sh; then
        log_success "Monitoring test passed"
    else
        log_warning "Monitoring test reported issues (expected on first run)"
    fi

    # Verify report creation
    local latest_report
    latest_report=$(find .config-backup/monitoring -name "health-report-*.md" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2- || echo "")

    if [[ -n "$latest_report" && -f "$latest_report" ]]; then
        log_success "Report created: $latest_report"
        log_info "Report size: $(wc -l < "$latest_report") lines"
    else
        log_error "Report not created"
        return 1
    fi
}

# === MAIN ===
main() {
    log_info "🔧 Setting up ERNI-KI monitoring"
    echo ""

    setup_directories
    setup_logging_levels
    setup_cron
    setup_alerts
    test_monitoring

    echo ""
    log_success "🎉 Monitoring setup completed!"
    echo ""
    log_info "📋 Configured:"
    log_info "  ✅ Hourly checks"
    log_info "  ✅ Weekly reports"
    log_info "  ✅ Automatic log cleanup"
    log_info "  ✅ Alerting script"
    log_info "  ✅ Optimized logging levels"
    echo ""
    log_info "📁 Monitoring files:"
    log_info "  - Reports: .config-backup/monitoring/"
    log_info "  - Scripts: scripts/"
    log_info "  - Alerts: .config-backup/monitoring/critical-alerts.log"
    echo ""
    log_info "🔧 Operations:"
    log_info "  - Manual check: ./scripts/health-monitor-v2.sh"
    log_info "  - View cron: crontab -l | grep erni-ki"
    log_info "  - Cron logs: .config-backup/monitoring/cron.log"
    echo ""
    log_success "System ready for automated monitoring!"
}

# === ENTRYPOINT ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
