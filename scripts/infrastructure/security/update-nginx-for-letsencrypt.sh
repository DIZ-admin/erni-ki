#!/bin/bash

# ERNI-KI Nginx Configuration Update for Let's Encrypt certificates

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(pwd)"
NGINX_CONF_DIR="$PROJECT_ROOT/conf/nginx"
NGINX_DEFAULT_CONF="$NGINX_CONF_DIR/conf.d/default.conf"
SSL_DIR="$NGINX_CONF_DIR/ssl"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/nginx-letsencrypt-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$PROJECT_ROOT/logs/nginx-letsencrypt-update.log"
DOMAIN="ki.erni-gruppe.ch"

mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_DIR"

log()      { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"; }
success()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_FILE"; }
warning()  { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"; }
error_out(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

check_current_config() {
    log "Inspecting existing nginx configuration..."
    [[ -f "$NGINX_DEFAULT_CONF" ]] || error_out "nginx config not found: $NGINX_DEFAULT_CONF"

    if grep -q "ssl_certificate .*nginx-fullchain.crt" "$NGINX_DEFAULT_CONF"; then
        success "Configuration already references nginx-fullchain.crt"
    elif grep -q "ssl_certificate .*nginx.crt" "$NGINX_DEFAULT_CONF"; then
        warning "Configuration still references nginx.crt"
        return 1
    else
        error_out "SSL configuration missing in nginx default config"
    fi

    if grep -q "ssl_stapling on" "$NGINX_DEFAULT_CONF"; then
        success "OCSP stapling enabled"
    else
        warning "OCSP stapling not configured"
    fi
}

create_backup() {
    log "Backing up nginx configuration..."
    cp -r "$NGINX_CONF_DIR" "$BACKUP_DIR/"
    success "Backup created at $BACKUP_DIR"
}

check_certificates() {
    log "Validating certificate files..."
    local files=("$SSL_DIR/nginx.crt" "$SSL_DIR/nginx.key" "$SSL_DIR/nginx-fullchain.crt" "$SSL_DIR/nginx-ca.crt")
    for file in "${files[@]}"; do
        [[ -f "$file" ]] || error_out "Missing $file"
    done
    if openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | grep -q "Let's Encrypt"; then
        success "Certificate issued by Let's Encrypt"
    else
        warning "Certificate issuer is not Let's Encrypt"
    fi
    local expiry=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
    log "Certificate valid until: $expiry"
}

update_nginx_config() {
    log "Updating nginx configuration for fullchain certificates..."
    if check_current_config >/dev/null 2>&1; then
        log "Configuration already optimized"
        return
    fi
    sed -i 's|ssl_certificate /etc/nginx/ssl/nginx\.crt;|ssl_certificate /etc/nginx/ssl/nginx-fullchain.crt;|g' "$NGINX_DEFAULT_CONF"
    if ! grep -q "ssl_stapling on" "$NGINX_DEFAULT_CONF"; then
        sed -i '/ssl_session_tickets off;/a\\n  # OCSP stapling\n  ssl_stapling on;\n  ssl_stapling_verify on;\n  ssl_trusted_certificate /etc/nginx/ssl/nginx-ca.crt;\n  resolver 1.1.1.1 1.0.0.1 valid=300s;\n  resolver_timeout 5s;' "$NGINX_DEFAULT_CONF"
    fi
    success "nginx configuration updated"
}

test_nginx_config() {
    log "Validating nginx syntax..."
    docker-compose exec -T nginx nginx -t >>"$LOG_FILE" 2>&1 || return 1
    success "nginx configuration is valid"
}

reload_nginx() {
    log "Reloading nginx..."
    if docker-compose exec -T nginx nginx -s reload >>"$LOG_FILE" 2>&1; then
        success "nginx reloaded"
    else
        warning "Reload failed, restarting container"
        docker-compose restart nginx >>"$LOG_FILE" 2>&1 || error_out "Unable to restart nginx"
        sleep 5
        docker-compose ps nginx | grep -q "healthy" || error_out "nginx container unhealthy after restart"
        success "nginx container restarted"
    fi
}

test_https_access() {
    log "Testing HTTPS endpoints..."
    curl -k -I "https://localhost/" --connect-timeout 5 >/dev/null 2>&1 && success "Local HTTPS OK" || warning "Local HTTPS unreachable"
    curl -I "https://$DOMAIN/" --connect-timeout 5 >/dev/null 2>&1 && success "Domain HTTPS OK" || warning "Domain HTTPS unreachable"
    if echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" >/dev/null 2>&1; then
        success "TLS handshake completed"
    else
        warning "TLS handshake failed"
    fi
}

check_ssl_rating() {
    log "Checking TLS capabilities..."
    echo | openssl s_client -connect "$DOMAIN:443" -tls1_2 >/dev/null 2>&1 && success "TLS 1.2 supported" || warning "TLS 1.2 not supported"
    echo | openssl s_client -connect "$DOMAIN:443" -tls1_3 >/dev/null 2>&1 && success "TLS 1.3 supported" || warning "TLS 1.3 not supported"
    if curl -I "https://$DOMAIN/" 2>/dev/null | grep -qi "Strict-Transport-Security"; then
        success "HSTS header present"
    else
        warning "HSTS header missing"
    fi
}

generate_report() {
    local report_file="$PROJECT_ROOT/logs/nginx-letsencrypt-update-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "ERNI-KI Nginx Let's Encrypt Update Report"
        echo "Generated: $(date)"
        echo "Config file: $NGINX_DEFAULT_CONF"
        echo "SSL dir: $SSL_DIR"
        echo "Backup: $BACKUP_DIR"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Certificate read error"
        docker-compose exec -T nginx nginx -t 2>&1 || echo "nginx -t failed"
    } > "$report_file"
    success "Report saved: $report_file"
}

main() {
    echo -e "${CYAN}=================================================="
    echo "  ERNI-KI Nginx Let's Encrypt Configuration"
    echo -e "==================================================${NC}"

    create_backup
    check_certificates
    update_nginx_config
    if test_nginx_config; then
        reload_nginx
        test_https_access
        check_ssl_rating
        generate_report
        success "Nginx configured for Let's Encrypt"
        log "Backup directory: $BACKUP_DIR"
    else
        error_out "nginx configuration test failed"
    fi
}

main "$@"
