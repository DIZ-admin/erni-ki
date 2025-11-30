#!/bin/bash

# ERNI-KI Rate Limiting Monitoring Setup
# Automated rate limiting monitoring configuration
# Author: Alteon Schultz (Tech Lead)

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# === Logging functions ===

# === Create cron job ===
setup_cron_monitoring() {
    log_info "Setting up cron monitoring..."

    local cron_entry="*/1 * * * * cd $PROJECT_ROOT && ./scripts/monitor-rate-limiting.sh monitor >/dev/null 2>&1"

    # Check existing cron job
    if crontab -l 2>/dev/null | grep -q "monitor-rate-limiting.sh"; then
        log_info "Cron job already exists"
    else
        # Add new cron job
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        log_success "Cron job added: monitoring every minute"
    fi
}

# === Create systemd service ===
setup_systemd_service() {
    log_info "Creating systemd service..."

    local service_file="/etc/systemd/system/erni-ki-rate-monitor.service"
    local timer_file="/etc/systemd/system/erni-ki-rate-monitor.timer"

    # Create service
    sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=ERNI-KI Rate Limiting Monitor
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$PROJECT_ROOT
ExecStart=$PROJECT_ROOT/scripts/monitor-rate-limiting.sh monitor
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Create timer
    sudo tee "$timer_file" > /dev/null <<EOF
[Unit]
Description=Run ERNI-KI Rate Limiting Monitor every minute
Requires=erni-ki-rate-monitor.service

[Timer]
OnCalendar=*:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Reload systemd and start
    sudo systemctl daemon-reload
    sudo systemctl enable erni-ki-rate-monitor.timer
    sudo systemctl start erni-ki-rate-monitor.timer

    log_success "Systemd service configured and started"
}

# === Setup log rotation ===
setup_log_rotation() {
    log_info "Setting up log rotation..."

    local logrotate_config="/etc/logrotate.d/erni-ki-rate-limiting"

    sudo tee "$logrotate_config" > /dev/null <<EOF
$PROJECT_ROOT/logs/rate-limiting-*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 $USER $USER
    postrotate
        # Send signal to update logs (if needed)
    endscript
}
EOF

    log_success "Log rotation configured"
}

# === Create dashboard script ===
create_dashboard() {
    log_info "Creating dashboard script..."

    cat > "$PROJECT_ROOT/scripts/rate-limiting-dashboard.sh" <<'EOF'
#!/bin/bash

# ERNI-KI Rate Limiting Dashboard
# Simple dashboard for rate limiting monitoring

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="$PROJECT_ROOT/logs/rate-limiting-state.json"

clear
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                        ERNI-KI Rate Limiting Dashboard                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo

# Current status
echo "📊 Current status:"
if [[ -f "$STATE_FILE" ]]; then
    echo "   Last update: $(jq -r '.timestamp' "$STATE_FILE" 2>/dev/null || echo 'N/A')"
    echo "   Blocks per minute: $(jq -r '.total_blocks' "$STATE_FILE" 2>/dev/null || echo 'N/A')"
    echo "   Maximum excess: $(jq -r '.max_excess' "$STATE_FILE" 2>/dev/null || echo 'N/A')"
else
    echo "   ⚠️  No monitoring data"
fi

echo

# Zone statistics
echo "🎯 Zone statistics:"
if [[ -f "$STATE_FILE" ]] && jq -e '.zones | length > 0' "$STATE_FILE" >/dev/null 2>&1; then
    jq -r '.zones[] | "   \(.zone): \(.count) blocks"' "$STATE_FILE" 2>/dev/null
    jq -r '.zones[] | "   \(.zone): \(.count) blocks"' "$STATE_FILE" 2>/dev/null
else
    echo "   ✅ No blocks"
fi

echo

# Top IP addresses
echo "🌐 Top IP Addresses:"
if [[ -f "$STATE_FILE" ]] && jq -e '.top_ips | length > 0' "$STATE_FILE" >/dev/null 2>&1; then
    jq -r '.top_ips[] | "   \(.ip): \(.count) blocks"' "$STATE_FILE" 2>/dev/null | head -5
else
    echo "   ✅ No problematic IPs"
fi

echo

# Latest alerts
echo "🚨 Latest Alerts:"
local alert_file="$PROJECT_ROOT/logs/rate-limiting-alerts.log"
if [[ -f "$alert_file" ]]; then
    tail -5 "$alert_file" | grep -E "^\[.*\] \[.*\]" | while read -r line; do
        echo "   $line"
    done
else
    echo "   ✅ No alerts"
fi

echo
echo "Updated: $(date)"
echo "Press Ctrl+C to exit"
EOF

    chmod +x "$PROJECT_ROOT/scripts/rate-limiting-dashboard.sh"
    log_success "Dashboard created: scripts/rate-limiting-dashboard.sh"
}

# === Setup notifications ===
setup_notifications() {
    log_info "Setting up notification integration..."

    # Create configuration file for notifications
    cat > "$PROJECT_ROOT/conf/rate-limiting-notifications.conf" <<EOF
# ERNI-KI Rate Limiting Notifications Configuration

# Alert thresholds
ALERT_THRESHOLD=10
WARNING_THRESHOLD=5

# Email notifications (if sendmail is configured)
EMAIL_ENABLED=false
EMAIL_TO="admin@example.com"

# Slack notifications (if webhook is configured)
SLACK_ENABLED=false
SLACK_WEBHOOK_URL=""

# Discord notifications (if webhook is configured)
DISCORD_ENABLED=false
DISCORD_WEBHOOK_URL=""

# Telegram notifications (if bot is configured)
TELEGRAM_ENABLED=false
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Backrest integration
BACKREST_ENABLED=true
BACKREST_URL="http://localhost:9898"
EOF

    log_success "Notification configuration created"
}

# === Test system ===
test_monitoring() {
    log_info "Testing monitoring system..."

    # Run a test check
    if "$PROJECT_ROOT/scripts/monitor-rate-limiting.sh" monitor; then
        log_success "Monitoring works correctly"
    else
        log_error "Monitoring error"
        return 1
    fi

    # Check file creation
    if [[ -f "$PROJECT_ROOT/logs/rate-limiting-monitor.log" ]]; then
        log_success "Log file created"
    else
        log_error "Log file not created"
    fi

    return 0
}

# === Main function ===
main() {
    log_info "Setting up ERNI-KI rate limiting monitoring system"

    # Create directories
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/conf"

    # Choose monitoring method
    case "${1:-cron}" in
        "cron")
            setup_cron_monitoring
            ;;
        "systemd")
            setup_systemd_service
            ;;
        "both")
            setup_cron_monitoring
            setup_systemd_service
            ;;
        *)
            log_error "Unknown method: $1"
            echo "Available methods: cron, systemd, both"
            exit 1
            ;;
    esac

    # General settings
    setup_log_rotation
    create_dashboard
    setup_notifications

    # Testing
    if test_monitoring; then
        echo "  ./scripts/monitor-rate-limiting.sh stats    # Show statistics"
        echo "  ./scripts/rate-limiting-dashboard.sh        # Start dashboard"
        echo "  tail -f logs/rate-limiting-monitor.log      # View logs"

    else
        log_error "Error setting up monitoring system"
        exit 1
    fi
}

# Run script
main "$@"
