#!/bin/bash

# ERNI-KI Let's Encrypt SSL Setup with Cloudflare DNS Challenge
# Author: Alteon Schultz (Tech Lead)
# Version: 1.0
# Date: 2025-08-11

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# Colors for output



# Configuration
DOMAIN="ki.erni-gruppe.ch"
EMAIL="admin@erni-ki.local"
ACME_HOME="$HOME/.acme.sh"
SSL_DIR="$(pwd)/conf/nginx/ssl"
BACKUP_DIR="$(pwd)/.config-backup/ssl-letsencrypt-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$(pwd)/logs/ssl-setup.log"

# Creating directories for logs
mkdir -p "$(dirname "$LOG_FILE")"

# Dependency check
check_dependencies() {
    log_info "Checking prerequisites..."

    # Check Docker
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose not found. Install Docker Compose."
    fi

    # Check curl
    if ! command -v curl &> /dev/null; then
        log_error "curl not found. Install curl."
    fi

    # Check openssl
    if ! command -v openssl &> /dev/null; then
        log_error "openssl not found. Install openssl."
    fi

    # Ensure SSL directory exists
    if [ ! -d "$SSL_DIR" ]; then
        log_error "SSL directory not found: $SSL_DIR"
    fi

    log_success "All dependencies found"
}

# Validate Cloudflare API token
check_cloudflare_credentials() {
    log_info "Checking Cloudflare API token..."

    if [ -z "${CF_Token:-}" ] && [ -z "${CF_Key:-}" ]; then
        log_error "Cloudflare API token missing. Set CF_Token or CF_Key + CF_Email."
    fi

    if [ -n "${CF_Token:-}" ]; then
        log_info "Using Cloudflare API Token (recommended)"
        if ! curl -s -H "Authorization: Bearer $CF_Token" \
             -H "Content-Type: application/json" \
             "https://api.cloudflare.com/client/v4/user/tokens/verify" | grep -q '"success":true'; then
            log_error "Cloudflare API token invalid"
        fi
    elif [ -n "${CF_Key:-}" ] && [ -n "${CF_Email:-}" ]; then
        log_info "Using Cloudflare Global API Key"
        if ! curl -s -H "X-Auth-Email: $CF_Email" \
             -H "X-Auth-Key: $CF_Key" \
             -H "Content-Type: application/json" \
             "https://api.cloudflare.com/client/v4/user" | grep -q '"success":true'; then
            log_error "Cloudflare Global API Key invalid"
        fi
    else
        log_error "Incomplete Cloudflare credentials. Provide CF_Token or (CF_Key + CF_Email)."
    fi

    log_success "Cloudflare credentials verified"
}

# Install acme.sh if needed
install_acme_sh() {
    log_info "Installing acme.sh..."

    if [ ! -f "$ACME_HOME/acme.sh" ]; then
        log_info "Downloading acme.sh..."
        curl https://get.acme.sh | sh -s email="$EMAIL"

        # Reload environment variables
        source "$HOME/.bashrc" 2>/dev/null || true

        if [ ! -f "$ACME_HOME/acme.sh" ]; then
            log_error "acme.sh installation failed"
        fi
    else
        log_info "acme.sh already installed"
    fi

    # Ensure we're on the latest version
    "$ACME_HOME/acme.sh" --upgrade

    log_success "acme.sh installed and updated"
}

# Backup existing certificates
create_backup() {
    log_info "Backing up current certificates..."

    mkdir -p "$BACKUP_DIR"

    if [ -f "$SSL_DIR/nginx.crt" ]; then
        cp "$SSL_DIR"/*.crt "$BACKUP_DIR/" 2>/dev/null || true
        cp "$SSL_DIR"/*.key "$BACKUP_DIR/" 2>/dev/null || true
        cp "$SSL_DIR"/*.pem "$BACKUP_DIR/" 2>/dev/null || true
        log_success "Backup created: $BACKUP_DIR"
    else
        log_warn "No existing certificates found"
    fi
}

# Obtaining certificate Let's Encrypt
obtain_certificate() {
    log_info "Requesting Let's Encrypt certificate for domain: $DOMAIN"

    # Use Let's Encrypt CA
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt

    # Issue certificate via DNS-01 challenge with Cloudflare
    if "$ACME_HOME/acme.sh" --issue --dns dns_cf -d "$DOMAIN" --email "$EMAIL" --force; then
        log_success "Certificate successfully obtained"
    else
        log_error "Certificate issuance failed"
    fi
}

# Installation certificate
install_certificate() {
    log_info "Installing certificate into nginx..."

    # Temporary directory for fresh files
    TEMP_SSL_DIR="/tmp/ssl-new-$(date +%s)"
    mkdir -p "$TEMP_SSL_DIR"

    # Install certificate into the temp directory
    if "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$TEMP_SSL_DIR/nginx.crt" \
        --key-file "$TEMP_SSL_DIR/nginx.key" \
        --fullchain-file "$TEMP_SSL_DIR/nginx-fullchain.crt" \
        --ca-file "$TEMP_SSL_DIR/nginx-ca.crt"; then

        # Copy certificates into SSL directory
        cp "$TEMP_SSL_DIR"/* "$SSL_DIR/"

        # Fix permissions
        chmod 644 "$SSL_DIR"/*.crt
        chmod 600 "$SSL_DIR"/*.key

        # Cleanup temp files
        rm -rf "$TEMP_SSL_DIR"

        log_success "Certificate installed in nginx"
    else
        rm -rf "$TEMP_SSL_DIR"
        log_error "Certificate installation failed"
    fi
}

# Check certificate
verify_certificate() {
    log_info "Checking installed certificate..."

    if [ -f "$SSL_DIR/nginx.crt" ]; then
        # Expiration
        local expiry_date=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
        log_info "Certificate valid until: $expiry_date"

        # Domain name
        local cert_domain=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject | grep -o "CN=[^,]*" | cut -d= -f2)
        if [[ "$cert_domain" == "$DOMAIN" ]]; then
            log_success "Certificate issued for expected domain: $cert_domain"
        else
            log_warn "Certificate domain ($cert_domain) does not match ($DOMAIN)"
        fi

        # Issuer
        local issuer=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | grep -o "CN=[^,]*" | cut -d= -f2)
        log_info "Issuer: $issuer"

    else
        log_error "Certificate file not found: $SSL_DIR/nginx.crt"
    fi
}

# Reload nginx
reload_nginx() {
    log_info "Reloading nginx..."

    if docker-compose exec -T nginx nginx -t; then
        if docker-compose exec -T nginx nginx -s reload; then
            log_success "Nginx reloaded successfully"
        else
            log_warn "Nginx reload failed, restarting container..."
            docker-compose restart nginx
        fi
    else
        log_error "Nginx configuration test failed"
    fi
}

# Configure automatic renewal
setup_auto_renewal() {
    log_info "Configuring automatic renewal..."

    # Hook script to reload nginx
    local hook_script="$ACME_HOME/nginx-reload-hook.sh"

    cat > "$hook_script" << 'EOF'
#!/bin/bash
# Hook script that reloads nginx after certificate renewal

cd "$(dirname "$0")/../.."

# Logging
echo "$(date): Certificate renewal hook executed" >> logs/ssl-renewal.log

# Reload nginx
if docker-compose exec -T nginx nginx -s reload 2>/dev/null; then
    echo "$(date): Nginx reloaded successfully after certificate renewal" >> logs/ssl-renewal.log
else
    echo "$(date): Failed to reload nginx, restarting container" >> logs/ssl-renewal.log
    docker-compose restart nginx
fi
EOF

    chmod +x "$hook_script"

    # Update acme.sh configuration to use the hook
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$SSL_DIR/nginx.crt" \
        --key-file "$SSL_DIR/nginx.key" \
        --fullchain-file "$SSL_DIR/nginx-fullchain.crt" \
        --ca-file "$SSL_DIR/nginx-ca.crt" \
        --reloadcmd "$hook_script"

    log_success "Renewal hook configured"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  ERNI-KI Let's Encrypt SSL Setup"
    echo "  Cloudflare DNS Challenge"
    echo "=================================================="
    echo -e "${NC}"

    check_dependencies
    check_cloudflare_credentials
    install_acme_sh
    create_backup
    obtain_certificate
    install_certificate
    verify_certificate
    reload_nginx
    setup_auto_renewal

    echo ""
    log_success "🎉 Let's Encrypt SSL certificate configured!"
    echo ""
    log_info "Next steps:"
    echo "1. Verify HTTPS access: https://$DOMAIN"
    echo "2. Check SSL rating: https://www.ssllabs.com/ssltest/"
    echo "3. Certificates auto-renew every ~60 days"
    echo ""
    log_info "Backup directory: $BACKUP_DIR"
    log_info "Setup log: $LOG_FILE"
}

# Starting script
main "$@" 2>&1 | tee -a "$LOG_FILE"
