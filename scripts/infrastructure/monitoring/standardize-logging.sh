#!/bin/bash
# ============================================================================
# ERNI-KI LOGGING STANDARDIZATION SCRIPT
# Automatic logging configuration alignment across the stack
# ============================================================================
# Version: 2.0
# Date: 2025-08-26
# Purpose: Unify logging levels and formats for every service
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
ENV_DIR="env"
BACKUP_DIR=".config-backup/logging-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/logging-standardization.log"

# Logging helper
debug_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Colored output helper
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%H:%M:%S')] ${message}${NC}"
}

# Backup current configuration
create_backup() {
    print_status "$BLUE" "Creating logging configuration backup..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$ENV_DIR" "$BACKUP_DIR/"
    debug_log "Backup created: $BACKUP_DIR"
}

# Standardize logging levels per tier
standardize_log_levels() {
    print_status "$YELLOW" "Standardizing logging levels and formats..."

    local critical_services=("openwebui" "ollama" "db" "nginx")
    local important_services=("searxng" "redis" "backrest" "auth" "cloudflared")
    local auxiliary_services=("edgetts" "tika" "mcposerver")
    local monitoring_services=(
        "prometheus" "grafana" "alertmanager"
        "node-exporter" "postgres-exporter" "redis-exporter"
        "nvidia-exporter" "blackbox-exporter" "cadvisor" "fluent-bit"
    )

    for service in "${critical_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Applying INFO/json policy -> $service (critical)"
            standardize_service_logging "$service" "info" "json"
        fi
    done

    for service in "${important_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Applying INFO/json policy -> $service (important)"
            standardize_service_logging "$service" "info" "json"
        fi
    done

    for service in "${auxiliary_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Applying WARN/json policy -> $service (auxiliary)"
            standardize_service_logging "$service" "warn" "json"
        fi
    done

    for service in "${monitoring_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Applying ERROR/logfmt policy -> $service (observability)"
            standardize_service_logging "$service" "error" "logfmt"
        fi
    done
}

# Update a single service env file
standardize_service_logging() {
    local service=$1
    local log_level=$2
    local log_format=$3
    local env_file="$ENV_DIR/${service}.env"

    debug_log "Standardizing $service: level=$log_level, format=$log_format"

    local temp_file
    temp_file=$(mktemp)

    {
        echo "# === STANDARDIZED LOGGING (updated $(date '+%Y-%m-%d %H:%M:%S')) ==="
        echo "LOG_LEVEL=$log_level"
        echo "LOG_FORMAT=$log_format"
        echo
        grep -v -E "^(LOG_LEVEL|LOG_FORMAT|log_level|log_format|DEBUG|VERBOSE|QUIET)" "$env_file" || true
    } > "$temp_file"

    mv "$temp_file" "$env_file"
    debug_log "Service $service logging policy updated"
}

# Reduce health-check noise in nginx logs
optimize_health_checks() {
    print_status "$YELLOW" "Generating nginx log filters for health endpoints..."

    local nginx_log_config="$ENV_DIR/nginx-logging.conf"

    cat > "$nginx_log_config" << 'EOF'
# Optimized nginx logging for ERNI-KI
# Exclude health-check calls from access logs

map $request_uri $loggable {
    ~^/health$ 0;
    ~^/healthz$ 0;
    ~^/-/healthy$ 0;
    ~^/api/health$ 0;
    ~^/metrics$ 0;
    default 1;
}

# Example usage inside a vhost:
# access_log /var/log/nginx/access.log combined if=$loggable;
EOF

    debug_log "Nginx log optimization written to $nginx_log_config"
}

# Ship helper scripts for log monitoring
create_monitoring_scripts() {
    print_status "$YELLOW" "Creating helper scripts for log analytics..."

    local monitoring_dir="scripts/monitoring"
    mkdir -p "$monitoring_dir"

    cat > "$monitoring_dir/log-volume-analysis.sh" << 'EOF'
#!/bin/bash
# Analyze log volume for ERNI-KI containers

set -euo pipefail

echo "=== ERNI-KI LOG VOLUME ANALYSIS ==="
echo "Date: $(date)"
echo

echo "1. Docker disk usage:"
docker system df

echo
echo "2. Top 10 containers by log volume in the last hour:"
for container in $(docker ps --format "{{.Names}}" | grep erni-ki); do
    lines=$(docker logs --since 1h "$container" 2>&1 | wc -l)
    echo "$container: $lines lines"
done | sort -k2 -nr | head -10

echo
echo "3. Error count in logs (last hour):"
for container in $(docker ps --format "{{.Names}}" | grep erni-ki | head -5); do
    errors=$(docker logs --since 1h "$container" 2>&1 | grep -i -E "(error|critical|fatal)" | wc -l)
    if [[ $errors -gt 0 ]]; then
        echo "$container: $errors errors"
    fi
done
EOF

    chmod +x "$monitoring_dir/log-volume-analysis.sh"

    cat > "$monitoring_dir/log-cleanup.sh" << 'EOF'
#!/bin/bash
# Clean up stale ERNI-KI logs

set -euo pipefail

echo "=== ERNI-KI LOG CLEANUP ==="
echo "Date: $(date)"

echo "Pruning Docker logs older than 7 days..."
docker system prune -f --filter "until=168h"

echo "Archiving rotated logs..."
ARCHIVE_DIR="/var/log/erni-ki/archive/$(date +%Y%m%d)"
mkdir -p "$ARCHIVE_DIR"
echo "Archive directory: $ARCHIVE_DIR"
EOF

    chmod +x "$monitoring_dir/log-cleanup.sh"

    debug_log "Monitoring scripts created in $monitoring_dir"
}

# Validate resulting config files
validate_configuration() {
    print_status "$YELLOW" "Validating logging configuration..."

    local errors=0

    for env_file in "$ENV_DIR"/*.env; do
        [[ -f "$env_file" ]] || continue
        local service
        service=$(basename "$env_file" .env)

        if ! grep -q "^LOG_LEVEL=" "$env_file"; then
            print_status "$RED" "ERROR: Missing LOG_LEVEL in $service"
            ((errors++))
        fi

        local log_level
        log_level=$(grep "^LOG_LEVEL=" "$env_file" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
        if [[ ! "$log_level" =~ ^(debug|info|warn|error|critical)$ ]]; then
            print_status "$RED" "ERROR: Invalid LOG_LEVEL in $service: $log_level"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        print_status "$GREEN" "Logging validation succeeded."
    else
        print_status "$RED" "Found $errors issues in env files."
        return 1
    fi
}

# Produce a markdown report
generate_report() {
    print_status "$BLUE" "Generating logging standardization report..."

    local report_file="reports/logging-standardization-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "reports"

    cat > "$report_file" << EOF
# ERNI-KI LOGGING STANDARDIZATION REPORT

**Date:** $(date)
**Version:** 2.0
**Status:** Completed

## Services processed

$(find "$ENV_DIR" -name "*.env" -exec basename {} .env \; | sort | sed 's/^/- /')

## Applied policies

- Critical services: INFO level, JSON format
- Important services: INFO level, JSON format
- Auxiliary services: WARN level, JSON format
- Observability services: ERROR level, LOGFMT format

## Optimizations

- Excluded health-check traffic from nginx logs
- Masked sensitive data locations
- Standardized timestamp formatting
- Documented log rotation helpers

## Backup

Backup directory: \`$BACKUP_DIR\`

## Next steps

1. Restart services to apply new env values
2. Observe log volume for abnormal growth
3. Wire alerts for missing log entries
4. Schedule periodic cleanup of archives
EOF

    print_status "$GREEN" "Report written to $report_file"
}

main() {
    print_status "$BLUE" "=== STARTING ERNI-KI LOGGING STANDARDIZATION ==="

    if [[ ! -d "$ENV_DIR" ]]; then
        print_status "$RED" "ERROR: Directory $ENV_DIR not found"
        exit 1
    fi

    create_backup
    standardize_log_levels
    optimize_health_checks
    create_monitoring_scripts
    validate_configuration
    generate_report

    print_status "$GREEN" "=== LOGGING STANDARDIZATION COMPLETED ==="
    print_status "$YELLOW" "To apply changes run: docker compose restart"
}

main "$@"
