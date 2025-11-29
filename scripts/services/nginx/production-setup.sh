#!/bin/bash

# ERNI-KI NGINX Production Setup Script
# Production setup for nginx with security and performance optimizations

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# Output colors

# Configuration
NGINX_SSL_DIR="conf/nginx/ssl"
NGINX_CONF_DIR="conf/nginx"
BACKUP_DIR=".config-backup/nginx-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}🚀 ERNI-KI NGINX Production Setup${NC}"
echo "=================================================="

# Logging helpers


warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}



# Create backup
create_backup() {
    log_info "Creating backup of current configuration..."
    mkdir -p "$BACKUP_DIR"

    if [ -d "$NGINX_CONF_DIR" ]; then
        cp -r "$NGINX_CONF_DIR" "$BACKUP_DIR/"
        log_info "Backup created: $BACKUP_DIR"
    else
        warn "Nginx configuration directory not found"
    fi
}

# Generate DH params for better security
generate_dhparam() {
    log_info "Checking DH params..."

    if [ ! -f "$NGINX_SSL_DIR/dhparam.pem" ]; then
        log_info "Generating DH params (this may take a few minutes)..."
        mkdir -p "$NGINX_SSL_DIR"
        openssl dhparam -out "$NGINX_SSL_DIR/dhparam.pem" 2048
        log_info "DH parameters generated: $NGINX_SSL_DIR/dhparam.pem"
    else
        log_info "DH params already exist"
    fi
}

# Check SSL certificates
check_ssl_certificates() {
    log_info "Checking SSL certificates..."

    if [ -f "$NGINX_SSL_DIR/nginx.crt" ] && [ -f "$NGINX_SSL_DIR/nginx.key" ]; then
        # Validate certificate
        if openssl x509 -in "$NGINX_SSL_DIR/nginx.crt" -text -noout > /dev/null 2>&1; then
            local expiry=$(openssl x509 -in "$NGINX_SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
            log_info "SSL certificate valid until: $expiry"
        else
            log_error "SSL certificate is corrupted"
            return 1
        fi
    else
        warn "SSL certificates not found in $NGINX_SSL_DIR"
        warn "Ensure nginx.crt and nginx.key exist"
    fi
}

# Test nginx configuration
test_nginx_config() {
    log_info "Testing nginx configuration..."

    if docker exec erni-ki-nginx-1 nginx -t 2>/dev/null; then
        log_info "Nginx configuration is valid"
        return 0
    else
        log_error "Nginx configuration error"
        docker exec erni-ki-nginx-1 nginx -t
        return 1
    fi
}

# Apply production configuration
apply_production_config() {
    log_info "Applying production configuration..."

    # Backup current config
    if [ -f "$NGINX_CONF_DIR/nginx.conf" ]; then
        cp "$NGINX_CONF_DIR/nginx.conf" "$BACKUP_DIR/nginx.conf.backup"
    fi

    # Copy new config
    if [ -f "$NGINX_CONF_DIR/nginx-production.conf" ]; then
        cp "$NGINX_CONF_DIR/nginx-production.conf" "$NGINX_CONF_DIR/nginx.conf"
        log_info "Production nginx configuration applied"
    else
        log_error "nginx-production.conf not found"
        return 1
    fi
}

# Reload nginx
reload_nginx() {
    log_info "Reloading nginx..."

    if docker exec erni-ki-nginx-1 nginx -s reload 2>/dev/null; then
        log_info "Nginx reloaded successfully"
    else
        warn "Reload failed, attempting container restart..."
        docker-compose restart nginx
        sleep 5

        if docker ps --filter "name=nginx" --format "{{.Status}}" | grep -q "Up"; then
            log_info "Nginx container restarted successfully"
        else
            log_error "Failed to restart nginx"
            return 1
        fi
    fi
}

# Performance tests
performance_test() {
    log_info "Running performance checks..."

    echo "HTTP test:"
    time curl -s -o /dev/null -w "HTTP %{http_code} - %{time_total}s\n" http://localhost:8080/health

    echo "HTTPS test:"
    time curl -s -o /dev/null -w "HTTP %{http_code} - %{time_total}s\n" -k https://localhost:443/health

    echo "SSL handshake test:"
    echo | openssl s_client -connect localhost:443 -servername localhost 2>/dev/null | grep -E "(Protocol|Cipher)"
}

# Security headers check
check_security_headers() {
    log_info "Checking security headers..."

    echo "HTTPS security headers:"
    curl -s -I -k https://localhost:443/health | grep -E "(Strict-Transport|X-Frame|X-Content|X-XSS|Referrer-Policy|Content-Security-Policy)"

    echo -e "\nHTTP security headers:"
    curl -s -I http://localhost:8080/health | grep -E "(X-Frame|X-Content|X-XSS|Referrer-Policy)"
}

# Main function
main() {
    log_info "Starting nginx production setup"

    # Ensure we are in project root
    if [ ! -f "compose.production.yml" ]; then
        log_error "Script must be run from ERNI-KI project root"
        exit 1
    fi

    # Setup steps
    create_backup
    generate_dhparam
    check_ssl_certificates

    # Ask for confirmation
    echo -e "\n${YELLOW}Apply production nginx configuration? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        apply_production_config

        if test_nginx_config; then
            reload_nginx
            sleep 3
            performance_test
            echo ""
            check_security_headers

            log_info "✅ Nginx production setup completed successfully!"
            log_info "📊 Backup saved to: $BACKUP_DIR"
            log_info "🔒 DH params: $NGINX_SSL_DIR/dhparam.pem"
            log_info "⚡ Performance and security optimized"
        else
            log_error "Configuration error, rolling back..."
            cp "$BACKUP_DIR/nginx.conf.backup" "$NGINX_CONF_DIR/nginx.conf" 2>/dev/null || true
            docker exec erni-ki-nginx-1 nginx -s reload 2>/dev/null || docker-compose restart nginx
        fi
    else
        log_info "Configuration application cancelled by user"
        log_info "Manual apply: cp $NGINX_CONF_DIR/nginx-production.conf $NGINX_CONF_DIR/nginx.conf"
    fi
}

# Entry point
main "$@"
