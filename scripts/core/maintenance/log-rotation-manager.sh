#!/bin/bash
# ERNI-KI log rotation management script
# Automatic log archiving and cleanup with storage in .config-backup/logs/

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/logs"
DOCKER_LOGS_DIR="/var/lib/docker/containers"
NGINX_LOGS_DIR="/var/log/nginx"
RETENTION_DAYS=7
ARCHIVE_RETENTION_WEEKS=4
MAX_LOG_SIZE="100M"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Create directory structure for archiving
create_backup_structure() {
    log "Creating directory structure for log archiving..."

    local dirs=(
        "$BACKUP_DIR"
        "$BACKUP_DIR/daily"
        "$BACKUP_DIR/weekly"
        "$BACKUP_DIR/critical"
        "$BACKUP_DIR/services"
        "$BACKUP_DIR/nginx"
        "$BACKUP_DIR/docker"
        "$BACKUP_DIR/system"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            success "Created directory: $dir"
        fi
    done
}

# Rotate Docker container logs
rotate_docker_logs() {
    log "Rotating Docker container logs..."

    local date_suffix=$(date +%Y%m%d_%H%M%S)
    local services=("auth" "db" "redis" "ollama" "nginx" "openwebui" "searxng" "edgetts" "tika" "mcposerver" "cloudflared" "watchtower" "backrest")

    for service in "${services[@]}"; do
        log "Processing logs for service: $service"

        # Get container ID
        local container_id=$(docker-compose ps -q "$service" 2>/dev/null || echo "")

        if [[ -n "$container_id" ]]; then
            # Export container logs
            local log_file="$BACKUP_DIR/services/${service}_${date_suffix}.log"

            if docker logs "$container_id" --since="24h" > "$log_file" 2>&1; then
                # Compress log
                gzip "$log_file"
                success "Archived log for service $service: ${log_file}.gz"

                # Clean old container logs (keep last 100MB)
                docker logs "$container_id" --tail=1000 > /tmp/temp_log_$service 2>&1 || true

            else
                warning "Failed to export logs for service $service"
            fi
        else
            warning "Container $service not found or not running"
        fi
    done
}

# Rotate Nginx logs
rotate_nginx_logs() {
    log "Rotating Nginx logs..."

    local date_suffix=$(date +%Y%m%d_%H%M%S)

    # Archive access.log
    if [[ -f "$NGINX_LOGS_DIR/access.log" ]]; then
        local access_backup="$BACKUP_DIR/nginx/access_${date_suffix}.log"
        cp "$NGINX_LOGS_DIR/access.log" "$access_backup"
        gzip "$access_backup"

        # Clear current log
        > "$NGINX_LOGS_DIR/access.log"
        success "Archived Nginx access.log"
    fi

    # Archive error.log
    if [[ -f "$NGINX_LOGS_DIR/error.log" ]]; then
        local error_backup="$BACKUP_DIR/nginx/error_${date_suffix}.log"
        cp "$NGINX_LOGS_DIR/error.log" "$error_backup"
        gzip "$error_backup"

        # Clear current log
        > "$NGINX_LOGS_DIR/error.log"
        success "Archived Nginx error.log"
    fi

    # Reload Nginx to apply changes
    if docker-compose exec nginx nginx -s reload 2>/dev/null; then
        success "Nginx reloaded to apply log rotation"
    else
        warning "Failed to reload Nginx"
    fi
}

# Archive critical logs
archive_critical_logs() {
    log "Archiving critical logs..."

    local date_suffix=$(date +%Y%m%d_%H%M%S)
    local critical_log="$BACKUP_DIR/critical/critical_errors_${date_suffix}.log"

    # Search for critical errors in all service logs
    {
        echo "=== ERNI-KI CRITICAL ERRORS ==="
        echo "Archive Date: $(date)"
        echo "Period: last 24 hours"
        echo ""

        # Search in Docker logs
        docker-compose logs --since=24h 2>/dev/null | grep -i -E "(error|fatal|critical|exception|panic|segfault)" | head -1000

        echo ""
        echo "=== NGINX ERRORS ==="
        if [[ -f "$NGINX_LOGS_DIR/error.log" ]]; then
            tail -1000 "$NGINX_LOGS_DIR/error.log" | grep -i -E "(error|crit|alert|emerg)"
        fi

    } > "$critical_log"

    # Compress critical logs
    gzip "$critical_log"
    success "Archived critical logs: ${critical_log}.gz"
}

# Create daily archive
create_daily_archive() {
    log "Creating daily log archive..."

    local date_suffix=$(date +%Y%m%d)
    local daily_archive="$BACKUP_DIR/daily/erni-ki-logs-${date_suffix}.tar.gz"

    # Create archive of all logs for the day
    tar -czf "$daily_archive" \
        -C "$BACKUP_DIR" \
        --exclude="daily" \
        --exclude="weekly" \
        services/ nginx/ critical/ docker/ system/ 2>/dev/null || true

    if [[ -f "$daily_archive" ]]; then
        local archive_size=$(du -h "$daily_archive" | cut -f1)
        success "Created daily archive: $daily_archive ($archive_size)"
    else
        error "Failed to create daily archive"
    fi
}

# Create weekly archive
create_weekly_archive() {
    log "Creating weekly log archive..."

    # Check if today is Sunday (day of week 0)
    if [[ $(date +%w) -eq 0 ]]; then
        local week_suffix=$(date +%Y_week_%U)
        local weekly_archive="$BACKUP_DIR/weekly/erni-ki-logs-${week_suffix}.tar.gz"

        # Create archive of all daily archives for the week
        tar -czf "$weekly_archive" \
            -C "$BACKUP_DIR/daily" \
            . 2>/dev/null || true

        if [[ -f "$weekly_archive" ]]; then
            local archive_size=$(du -h "$weekly_archive" | cut -f1)
            success "Created weekly archive: $weekly_archive ($archive_size)"
        else
            warning "Failed to create weekly archive"
        fi
    else
        log "Weekly archive is created only on Sundays"
    fi
}

# Clean up old archives
cleanup_old_archives() {
    log "Cleaning up old archives..."

    # Delete daily archives older than RETENTION_DAYS days
    find "$BACKUP_DIR/daily" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Delete weekly archives older than ARCHIVE_RETENTION_WEEKS weeks
    local weeks_in_days=$((ARCHIVE_RETENTION_WEEKS * 7))
    find "$BACKUP_DIR/weekly" -name "*.tar.gz" -mtime +$weeks_in_days -delete 2>/dev/null || true

    # Delete old service logs
    find "$BACKUP_DIR/services" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_DIR/nginx" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_DIR/critical" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    success "Old archives cleanup completed"
}

# Monitor log sizes
monitor_log_sizes() {
    log "Monitoring log sizes..."

    # Check log directory size
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
    log "Total log archive size: $total_size"

    # Check Docker logs size
    local docker_logs_size=$(du -sh /var/lib/docker/containers 2>/dev/null | cut -f1 || echo "0")
    log "Docker logs size: $docker_logs_size"

    # Warning about large logs
    local large_logs=$(find /var/lib/docker/containers -name "*.log" -size +$MAX_LOG_SIZE 2>/dev/null || true)
    if [[ -n "$large_logs" ]]; then
        warning "Large Docker log files found:"
        echo "$large_logs" | while read -r log_file; do
            local size=$(du -h "$log_file" | cut -f1)
            warning "  $log_file ($size)"
        done
    fi
}

# Generate rotation report
generate_rotation_report() {
    log "Generating log rotation report..."

    local report_file="$BACKUP_DIR/rotation_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=== ERNI-KI LOG ROTATION REPORT ==="
        echo "Date: $(date)"
        echo "Host: $(hostname)"
        echo ""

        echo "=== ARCHIVE STATISTICS ==="
        echo "Total archive size: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")"
        echo "Daily archives count: $(find "$BACKUP_DIR/daily" -name "*.tar.gz" 2>/dev/null | wc -l)"
        echo "Weekly archives count: $(find "$BACKUP_DIR/weekly" -name "*.tar.gz" 2>/dev/null | wc -l)"
        echo ""

        echo "=== LATEST ARCHIVES ==="
        echo "Daily archives:"
        ls -lah "$BACKUP_DIR/daily" 2>/dev/null | tail -5 || echo "No archives"
        echo ""
        echo "Weekly archives:"
        ls -lah "$BACKUP_DIR/weekly" 2>/dev/null | tail -3 || echo "No archives"
        echo ""

        echo "=== SERVICE STATUS ==="
        docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" 2>/dev/null || echo "Docker Compose not available"

    } > "$report_file"

    success "Report saved: $report_file"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ERNI-KI Log Rotation                     ║"
    echo "║                  Log Rotation Management                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Check access permissions
    if [[ $EUID -ne 0 ]] && [[ ! -w "$NGINX_LOGS_DIR" ]]; then
        warning "Root privileges required for full log rotation"
        warning "Some operations may be unavailable"
    fi

    # Execute rotation
    create_backup_structure
    echo ""

    rotate_docker_logs
    echo ""

    if [[ -w "$NGINX_LOGS_DIR" ]]; then
        rotate_nginx_logs
    else
        warning "No access to Nginx logs, skipping rotation"
    fi
    echo ""

    archive_critical_logs
    echo ""

    create_daily_archive
    echo ""

    create_weekly_archive
    echo ""

    cleanup_old_archives
    echo ""

    monitor_log_sizes
    echo ""

    generate_rotation_report
    echo ""

    success "Log rotation completed successfully!"
}

# Command line argument handling
case "${1:-}" in
    --daily)
        log "Starting daily log rotation"
        main
        ;;
    --weekly)
        log "Starting weekly log rotation"
        create_backup_structure
        create_weekly_archive
        cleanup_old_archives
        ;;
    --cleanup)
        log "Starting old archives cleanup"
        cleanup_old_archives
        ;;
    --report)
        log "Generating log report"
        generate_rotation_report
        ;;
    --monitor)
        log "Monitoring log sizes"
        monitor_log_sizes
        ;;
    *)
        main
        ;;
esac
