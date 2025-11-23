#!/bin/bash

# Setup automatic SSL certificate monitoring for ERNI-KI
# Creates systemd timer or cron job for regular checks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions for logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Configuration
PROJECT_DIR="$(pwd)"
MONITOR_SCRIPT="$PROJECT_DIR/scripts/infrastructure/security/monitor-certificates.sh"
SERVICE_NAME="erni-ki-ssl-monitor"
TIMER_NAME="erni-ki-ssl-monitor"

# Check access permissions
check_permissions() {
    log "Checking access permissions..."

    if [ "$EUID" -eq 0 ]; then
        log "Starting as root, creating system timer"
        SYSTEMD_DIR="/etc/systemd/system"
    else
        log "Starting as user, creating user timer"
        SYSTEMD_DIR="$HOME/.config/systemd/user"
        mkdir -p "$SYSTEMD_DIR"
    fi
}

# Creating systemd service
create_systemd_service() {
    log "Creating systemd service..."

    local service_file="$SYSTEMD_DIR/$SERVICE_NAME.service"

    if [ "$EUID" -eq 0 ]; then
        # System service with Docker dependency
        cat > "$service_file" << EOF
[Unit]
Description=ERNI-KI SSL Certificate Monitor
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
User=$(whoami)
Group=$(id -gn)
WorkingDirectory=$PROJECT_DIR
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=HOME=$HOME
ExecStart=$MONITOR_SCRIPT check
StandardOutput=journal
StandardError=journal
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF
    else
        # User service without Docker dependency
        cat > "$service_file" << EOF
[Unit]
Description=ERNI-KI SSL Certificate Monitor
After=network.target

[Service]
Type=oneshot
WorkingDirectory=$PROJECT_DIR
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=HOME=$HOME
ExecStart=$MONITOR_SCRIPT check
StandardOutput=journal
StandardError=journal
TimeoutSec=300

[Install]
WantedBy=default.target
EOF
    fi

    success "Systemd service created: $service_file"
}

# Creating systemd timer
create_systemd_timer() {
    log "Creating systemd timer..."

    local timer_file="$SYSTEMD_DIR/$TIMER_NAME.timer"

    cat > "$timer_file" << EOF
[Unit]
Description=ERNI-KI SSL Certificate Monitor Timer
Requires=$SERVICE_NAME.service

[Timer]
# Starting daily at 02:00
OnCalendar=daily
# Starting 5 minutes after system boot
OnBootSec=5min
# Random delay up to 30 minutes for load distribution
RandomizedDelaySec=30min
# Persistent timer
Persistent=true

[Install]
WantedBy=timers.target
EOF

    success "Systemd timer created: $timer_file"
}

# Setup systemd monitoring
setup_systemd_monitoring() {
    log "Setting up systemd monitoring..."

    check_permissions
    create_systemd_service
    create_systemd_timer

    # Reload systemd
    if [ "$EUID" -eq 0 ]; then
        systemctl daemon-reload
        systemctl enable "$TIMER_NAME.timer"
        systemctl start "$TIMER_NAME.timer"

        log "Checking timer status:"
        systemctl status "$TIMER_NAME.timer" --no-pager || true
    else
        systemctl --user daemon-reload
        systemctl --user enable "$TIMER_NAME.timer"
        systemctl --user start "$TIMER_NAME.timer"

        log "Checking timer status:"
        systemctl --user status "$TIMER_NAME.timer" --no-pager || true
    fi

    success "Systemd monitoring configured"
}

# Creating cron job (alternative)
setup_cron_monitoring() {
    log "Setting up cron monitoring..."

    # Check existing cron jobs
    if crontab -l 2>/dev/null | grep -q "monitor-certificates.sh"; then
        warning "Cron job already exists"
        return 0
    fi

    # Creating new cron job
    local cron_entry="0 2 * * * cd $PROJECT_DIR && $MONITOR_SCRIPT check >/dev/null 2>&1"

    # Adding to existing crontab
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

    success "Cron job created: $cron_entry"

    # Show current crontab
    log "Current cron jobs:"
    crontab -l | grep -E "(monitor-certificates|acme)" || echo "No related cron jobs found"
}

# Creating script for manual execution
create_manual_script() {
    log "Creating script for manual execution..."

    local manual_script="$PROJECT_DIR/scripts/ssl/check-ssl-now.sh"

    cat > "$manual_script" << 'EOF'
#!/bin/bash
# Manual SSL certificate check for ERNI-KI

cd "$(dirname "$0")/../.."
./scripts/infrastructure/security/monitor-certificates.sh check
EOF

    chmod +x "$manual_script"
    success "Script for manual execution created: $manual_script"
}

# Creating configuration file
create_config_file() {
    log "Creating configuration file..."

    local config_file="$PROJECT_DIR/conf/ssl/monitoring.conf"
    mkdir -p "$(dirname "$config_file")"

    cat > "$config_file" << EOF
# ERNI-KI SSL Monitoring Configuration
# SSL certificate monitoring configuration

# Domain for monitoring
DOMAIN=ki.erni-gruppe.ch

# Warning thresholds (days)
DAYS_WARNING=30
DAYS_CRITICAL=7

# Webhook URL for notifications (optional)
# SSL_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Email for notifications (optional)
# SSL_NOTIFICATION_EMAIL=admin@erni-ki.local

# Logging
LOG_LEVEL=INFO
LOG_RETENTION_DAYS=30

# Automatic renewal
AUTO_RENEW_ENABLED=true
AUTO_RENEW_DAYS_BEFORE=7

# Cloudflare API (for automatic renewal)
# CF_Token=your_cloudflare_api_token_here
# CF_Email=your_cloudflare_email@example.com
# CF_Key=your_cloudflare_global_api_key_here
EOF

    success "Configuration file created: $config_file"
}

# Testing monitoring
test_monitoring() {
    log "Testing monitoring..."

    if [ -x "$MONITOR_SCRIPT" ]; then
        log "Starting test check..."
        "$MONITOR_SCRIPT" check
        success "Test check completed"
    else
        error "Monitoring script not found or not executable: $MONITOR_SCRIPT"
    fi
}

# Show usage instructions
show_usage_instructions() {
    echo ""
    log "=== USAGE INSTRUCTIONS ==="
    echo ""

    log "Commands for managing monitoring:"
    echo "• Manual check: ./scripts/infrastructure/security/monitor-certificates.sh check"
    echo "• Forced renewal: ./scripts/infrastructure/security/monitor-certificates.sh renew"
    echo "• Generate report: ./scripts/infrastructure/security/monitor-certificates.sh report"
    echo "• Test HTTPS: ./scripts/infrastructure/security/monitor-certificates.sh test"
    echo ""

    if command -v systemctl >/dev/null 2>&1; then
        log "Systemd commands:"
        if [ "$EUID" -eq 0 ]; then
            echo "• Timer status: systemctl status $TIMER_NAME.timer"
            echo "• Stop timer: systemctl stop $TIMER_NAME.timer"
            echo "• Start timer: systemctl start $TIMER_NAME.timer"
            echo "• Logs: journalctl -u $SERVICE_NAME.service"
        else
            echo "• Timer status: systemctl --user status $TIMER_NAME.timer"
            echo "• Stop timer: systemctl --user stop $TIMER_NAME.timer"
            echo "• Start timer: systemctl --user start $TIMER_NAME.timer"
            echo "• Logs: journalctl --user -u $SERVICE_NAME.service"
        fi
    fi
    echo ""

    log "Configuration files:"
    echo "• Monitoring configuration: conf/ssl/monitoring.conf"
    echo "• Monitoring logs: logs/ssl-monitor.log"
    echo "• Reports: logs/ssl-report-*.txt"
    echo ""

    log "Setup notifications:"
    echo "• Edit conf/ssl/monitoring.conf"
    echo "• Add SSL_WEBHOOK_URL for Slack/Discord notifications"
    echo "• Configure CF_Token for automatic renewal"
}

# Main function
main() {
    local method="${1:-systemd}"

    echo -e "${BLUE}"
    echo "=============================================="
    echo "  ERNI-KI SSL Monitoring Setup"
    echo "  Method: $method"
    echo "=============================================="
    echo -e "${NC}"

    # Ensure script runs from project root
    if [ ! -f "compose.yml" ] && [ ! -f "compose.yml.example" ]; then
        error "Run this script from the ERNI-KI repository root"
    fi

    # Ensure monitoring script exists
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        error "Monitoring script not found: $MONITOR_SCRIPT"
    fi

    case "$method" in
        "systemd")
            if command -v systemctl >/dev/null 2>&1; then
                setup_systemd_monitoring
            else
                warning "systemd not available, falling back to cron"
                setup_cron_monitoring
            fi
            ;;
        "cron")
            setup_cron_monitoring
            ;;
        "manual")
            log "Manual-only monitoring selected"
            ;;
        *)
            echo "Usage: $0 [systemd|cron|manual]"
            echo "  systemd - Use systemd timer (recommended)"
            echo "  cron    - Use cron job"
            echo "  manual  - Manual execution only"
            exit 1
            ;;
    esac

    create_manual_script
    create_config_file
    test_monitoring
    show_usage_instructions

    success "SSL monitoring setup finished!"
}

# Starting script
main "$@"
