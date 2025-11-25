#!/bin/bash

# ERNI-KI Let's Encrypt SSL Setup (HTTP-01 Challenge)
# Requires Cloudflare proxy to be disabled temporarily.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="ki.erni-gruppe.ch"
EMAIL="admin@erni-ki.local"
ACME_HOME="$HOME/.acme.sh"
SSL_DIR="$(pwd)/conf/nginx/ssl"
WEBROOT_DIR="$(pwd)/data/certbot"
BACKUP_DIR="$(pwd)/.config-backup/ssl-http01-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$(pwd)/logs/ssl-http01-setup.log"

mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_DIR" "$WEBROOT_DIR"

log()      { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"; }
success()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_FILE"; }
warning()  { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"; }
error_out(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

check_prerequisites() {
    log "Checking prerequisites for HTTP-01 challenge..."
    [[ -f "$ACME_HOME/acme.sh" ]] || error_out "acme.sh not installed"
    command -v docker-compose >/dev/null 2>&1 || error_out "docker-compose not found"
    docker-compose ps nginx | grep -q "healthy" || error_out "nginx container is not healthy"

    warning "HTTP-01 challenge requirements:\n  1. Disable Cloudflare proxy (orange cloud → grey).\n  2. Port 80 reachable directly.\n  3. DNS A record points to this server."
    read -r -p "Have you completed these steps? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || error_out "Setup aborted until prerequisites are met."
    success "Prerequisites satisfied"
}

check_domain_accessibility() {
    log "Validating domain $DOMAIN over HTTP..."
    local resolved_ip
    resolved_ip=$(dig +short "$DOMAIN" | head -1)
    log "Domain resolves to: ${resolved_ip:-unknown}"
    curl -I --connect-timeout 10 "http://$DOMAIN/" >/dev/null 2>&1 \
        || error_out "Domain not reachable over HTTP (check DNS/Cloudflare)."
    success "Domain reachable via HTTP"
}

create_backup() {
    log "Backing up current certificates..."
    cp -r "$SSL_DIR" "$BACKUP_DIR/"
    success "Backup stored at $BACKUP_DIR"
}

setup_nginx_webroot() {
    log "Configuring nginx for ACME webroot..."
    local acme_conf="/tmp/acme-challenge.conf"
    cat > "$acme_conf" << 'EOF'
location /.well-known/acme-challenge/ {
    root /var/www/certbot;
    try_files $uri =404;
    access_log off;
    log_not_found off;
    add_header Content-Type "text/plain" always;
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
}
EOF
    local nginx_container=$(docker compose ps --format "{{.Names}}" nginx | head -1)
    docker cp "$acme_conf" "$nginx_container:/etc/nginx/conf.d/acme-challenge.conf"
    docker compose exec nginx mkdir -p /var/www/certbot
    docker cp "$WEBROOT_DIR/." "$nginx_container:/var/www/certbot/" || true
    docker compose exec nginx nginx -t >/dev/null 2>&1 || error_out "nginx config invalid"
    docker compose exec nginx nginx -s reload
    rm -f "$acme_conf"
    success "nginx prepared for HTTP-01"
}

obtain_certificate() {
    log "Requesting Let's Encrypt certificate via HTTP-01..."
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt >/dev/null 2>&1
    "$ACME_HOME/acme.sh" --issue --webroot -w "$WEBROOT_DIR" -d "$DOMAIN" --email "$EMAIL" --force \
        >/dev/null 2>&1 || error_out "Certificate issuance failed"
    success "Certificate issued"
}

install_certificate() {
    log "Installing certificate into nginx..."
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$SSL_DIR/nginx.crt" \
        --key-file "$SSL_DIR/nginx.key" \
        --fullchain-file "$SSL_DIR/nginx-fullchain.crt" \
        --ca-file "$SSL_DIR/nginx-ca.crt" \
        --reloadcmd "docker-compose exec nginx nginx -s reload" \
        >/dev/null 2>&1 || error_out "Certificate install failed"
    chmod 644 "$SSL_DIR"/*.crt
    chmod 600 "$SSL_DIR"/*.key
    success "Certificate installed"
}

cleanup_nginx_config() {
    log "Cleaning temporary nginx configuration..."
    docker compose exec nginx rm -f /etc/nginx/conf.d/acme-challenge.conf >/dev/null 2>&1 || true
    docker compose exec nginx nginx -t >/dev/null 2>&1 && docker compose exec nginx nginx -s reload >/dev/null 2>&1
    success "Temporary config removed"
}

verify_certificate() {
    log "Verifying certificate..."
    [[ -f "$SSL_DIR/nginx.crt" ]] || error_out "nginx.crt missing"
    local issuer=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | sed 's/.*CN=//')
    local expiry=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
    log "Issuer: $issuer"
    log "Expires: $expiry"
}

test_https() {
    log "Testing HTTPS..."
    curl -I "https://$DOMAIN/" --connect-timeout 10 >/dev/null 2>&1 \
        && success "HTTPS reachable" \
        || warning "HTTPS request failed"
}

generate_report() {
    local report_file="$(pwd)/logs/ssl-http01-report-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "ERNI-KI Let's Encrypt HTTP-01 Setup Report"
        echo "Generated: $(date)"
        echo "==========================================="
        echo "Domain: $DOMAIN"
        echo "Webroot: $WEBROOT_DIR"
        echo "SSL dir: $SSL_DIR"
        echo "Backup:  $BACKUP_DIR"
        echo
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Certificate unreadable"
    } > "$report_file"
    success "Report saved: $report_file"
}

main() {
    echo -e "${CYAN}=================================================="
    echo "  ERNI-KI Let's Encrypt HTTP-01 Challenge Setup"
    echo "  IMPORTANT: Disable Cloudflare proxying first"
    echo -e "==================================================${NC}"

    check_prerequisites
    check_domain_accessibility
    create_backup
    setup_nginx_webroot
    obtain_certificate
    install_certificate
    cleanup_nginx_config
    verify_certificate
    test_https
    generate_report

    success "Let's Encrypt HTTP-01 setup completed!"
    log "Next steps:"
    echo "1. Test HTTPS: https://$DOMAIN"
    echo "2. Re-enable Cloudflare proxy if needed"
    echo "3. Configure automatic renewal"
    log "Backup directory: $BACKUP_DIR"
    log "Setup log: $LOG_FILE"
}

main "$@" 2>&1 | tee -a "$LOG_FILE"
