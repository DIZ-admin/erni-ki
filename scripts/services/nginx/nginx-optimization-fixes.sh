#!/bin/bash

# ERNI-KI Nginx Optimization Fixes
# Automated application of optimizations from 2025-08-25 audit
# Version: 1.0

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# === Configuration ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NGINX_CONF_DIR="$PROJECT_ROOT/conf/nginx"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/nginx-optimization-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$PROJECT_ROOT/logs/nginx-optimization.log"

# === Logging ===

# === Ensure directories exist ===
mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_DIR"

# === Create backup ===
create_backup() {
    log_info "Creating nginx configuration backup..."

    if cp -r "$NGINX_CONF_DIR" "$BACKUP_DIR/"; then
        log_success "Backup created: $BACKUP_DIR"
        echo "$BACKUP_DIR" > "$PROJECT_ROOT/.config-backup/nginx-last-backup.txt"
    else
        log_error "Failed to create backup"
        exit 1
    fi
}

# === Validate current configuration ===
check_current_config() {
    log_info "Validating current nginx configuration..."

    if docker exec erni-ki-nginx-1 nginx -t >/dev/null 2>&1; then
        log_success "Current configuration is valid"
    else
        log_error "Current configuration has errors"
        docker exec erni-ki-nginx-1 nginx -t
        exit 1
    fi
}

# === Fix 1: Add Gzip compression ===
fix_gzip_compression() {
    log_info "Fix 1: Adding Gzip compression to nginx.conf..."

    local nginx_conf="$NGINX_CONF_DIR/nginx.conf"

    # Skip if gzip already configured
    if grep -q "gzip on" "$nginx_conf"; then
        log_warn "Gzip already configured in nginx.conf"
        return 0
    fi

    # Find insertion line after mime.types
    local insert_line=$(grep -n "include /etc/nginx/mime.types;" "$nginx_conf" | cut -d: -f1)

    if [[ -z "$insert_line" ]]; then
        log_error "Insertion point for gzip settings not found"
        return 1
    fi

    # Temporary gzip settings
    cat > /tmp/gzip_config.txt << 'EOF'

    # Gzip compression for performance
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
EOF

    # Insert gzip settings
    sed -i "${insert_line}r /tmp/gzip_config.txt" "$nginx_conf"
    rm /tmp/gzip_config.txt

    log_success "Gzip compression added to nginx.conf"
}

# === Fix 2: Remove duplicate WebSocket directives ===
fix_websocket_duplication() {
    log_info "Fix 2: Removing duplicate WebSocket directives..."

    local default_conf="$NGINX_CONF_DIR/conf.d/default.conf"

    # Check duplicates
    local websocket_count=$(grep -c "map \$http_upgrade \$connection_upgrade" "$default_conf" || echo "0")

    if [[ "$websocket_count" -eq 0 ]]; then
        log_warn "WebSocket mapping not found in default.conf"
        return 0
    fi

    # Remove duplicate block (lines 74-77)
    sed -i '74,77d' "$default_conf"

    log_success "Duplicate WebSocket directives removed"
}

# === Fix 3: Enforce security headers ===
fix_security_headers() {
    log_info "Fix 3: Enforcing security headers..."

    local default_conf="$NGINX_CONF_DIR/conf.d/default.conf"

    # Find main location / block (around line 804)
    local location_line=$(grep -n "location / {" "$default_conf" | head -1 | cut -d: -f1)

    if [[ -z "$location_line" ]]; then
        log_error "Main location / block not found"
        return 1
    fi

    # Locate proxy_pass within the block
    local proxy_line=$(sed -n "${location_line},/^[[:space:]]*}/p" "$default_conf" | grep -n "proxy_pass" | head -1 | cut -d: -f1)

    if [[ -z "$proxy_line" ]]; then
        log_error "proxy_pass not found in location /"
        return 1
    fi

    # Absolute insertion line
    local insert_line=$((location_line + proxy_line))

    # Temporary file with security headers
    cat > /tmp/security_headers.txt << 'EOF'

        # Enforce security headers
        add_header X-Frame-Options SAMEORIGIN always;
        add_header X-Content-Type-Options nosniff always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
EOF

    # Insert security headers after proxy_pass
    sed -i "${insert_line}r /tmp/security_headers.txt" "$default_conf"
    rm /tmp/security_headers.txt

    log_success "Security headers inserted"
}

# === Fix 4: Comment unused upstream blocks ===
fix_unused_upstreams() {
    log_info "Fix 4: Commenting unused upstream blocks..."

    local default_conf="$NGINX_CONF_DIR/conf.d/default.conf"

    # Comment redisUpstream (when unused)
    if grep -q "upstream redisUpstream" "$default_conf" && ! grep -q "proxy_pass.*redisUpstream" "$default_conf"; then
        sed -i '/upstream redisUpstream/,/^}/s/^/# /' "$default_conf"
        log_success "redisUpstream commented"
    fi

    # Comment authUpstream (when unused)
    if grep -q "upstream authUpstream" "$default_conf" && ! grep -q "proxy_pass.*authUpstream" "$default_conf"; then
        sed -i '/upstream authUpstream/,/^}/s/^/# /' "$default_conf"
        log_success "authUpstream commented"
    fi
}

# === Validate new configuration ===
test_new_config() {
    log_info "Validating new nginx configuration..."

    if docker exec erni-ki-nginx-1 nginx -t >/dev/null 2>&1; then
        log_success "New configuration is valid"
        return 0
    else
        log_error "New configuration has errors:"
        docker exec erni-ki-nginx-1 nginx -t
        return 1
    fi
}

# === Apply changes ===
apply_changes() {
    log_info "Applying changes without downtime..."

    if docker exec erni-ki-nginx-1 nginx -s reload; then
        log_success "Nginx reloaded successfully"
    else
        log_error "Failed to reload nginx"
        return 1
    fi
}

# === Verify fixes ===
verify_fixes() {
    log_info "Verifying optimization results..."

    # Gzip check
    if curl -s -H "Accept-Encoding: gzip" -I http://localhost:8080/ | grep -q "Content-Encoding: gzip"; then
        log_success "Gzip compression works"
    else
        log_warn "Gzip compression not detected"
    fi

    # Security headers check
    local headers_count=$(curl -s -I https://localhost:443/ -k | grep -E "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Strict-Transport-Security)" | wc -l)

    if [[ "$headers_count" -ge 3 ]]; then
        log_success "Security headers present ($headers_count of 4)"
    else
        log_warn "Security headers incomplete ($headers_count of 4)"
    fi

    # General availability
    if curl -s -o /dev/null -w "%{http_code}" https://localhost:443/ -k | grep -q "200"; then
        log_success "Main site reachable"
    else
        log_error "Main site unreachable"
    fi
}

# === Rollback changes ===
rollback_changes() {
    log_info "Rolling back to previous configuration..."

    local last_backup
    if [[ -f "$PROJECT_ROOT/.config-backup/nginx-last-backup.txt" ]]; then
        last_backup=$(cat "$PROJECT_ROOT/.config-backup/nginx-last-backup.txt")
    else
        log_error "Path to last backup not found"
        return 1
    fi

    if [[ -d "$last_backup" ]]; then
        cp -r "$last_backup/nginx/"* "$NGINX_CONF_DIR/"
        docker exec erni-ki-nginx-1 nginx -s reload
        log_success "Rollback completed successfully"
    else
        log_error "Backup directory not found: $last_backup"
        return 1
    fi
}

# === Main function ===
main() {
    log_info "=== Starting ERNI-KI Nginx optimization ==="

    # Environment checks
    if ! docker ps | grep -q "erni-ki-nginx-1"; then
        log_error "Container erni-ki-nginx-1 not found"
        exit 1
    fi

    # Apply fixes
    create_backup
    check_current_config

    log_info "Applying fixes..."
    fix_gzip_compression
    fix_websocket_duplication
    fix_security_headers
    fix_unused_upstreams

    # Validate and apply
    if test_new_config; then
        apply_changes
        verify_fixes

        log_info "=== Optimization completed successfully ==="
        log_info "Backup saved to: $BACKUP_DIR"
        log_info "For rollback use: $0 --rollback"
    else
        log_error "Configuration has errors, rolling back..."
        rollback_changes
        exit 1
    fi
}

# === Argument handling ===
case "${1:-}" in
    --rollback)
        rollback_changes
        ;;
    --help)
        echo "Usage: $0 [--rollback|--help]"
        echo "  --rollback  Roll back to previous configuration"
        echo "  --help      Show this help"
        ;;
    *)
        main "$@"
        ;;
esac
