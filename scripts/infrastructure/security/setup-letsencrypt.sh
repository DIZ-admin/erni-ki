#!/bin/bash

# ERNI-KI Let's Encrypt SSL Setup (Cloudflare/Cyon DNS-01)
# Issues certificates for ki.erni-gruppe.ch using acme.sh and Cyon DNS API.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="ki.erni-gruppe.ch"
EMAIL="admin@gmail.com"
ACME_HOME="$HOME/.acme.sh"
SSL_DIR="$(pwd)/conf/nginx/ssl"
BACKUP_DIR="$(pwd)/.config-backup/ssl-letsencrypt-$(date +%Y%m%d-%H%M%S)"
HOOK_SCRIPT="$ACME_HOME/reload-nginx-hook.sh"

log()      { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"; }
success()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"; }
warning()  { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error_out(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; exit 1; }

check_dependencies() {
    log "Checking dependencies..."
    [[ -f "$ACME_HOME/acme.sh" ]] || error_out "acme.sh missing. Install via: curl https://get.acme.sh | sh"
    [[ -d "$SSL_DIR" ]] || error_out "SSL directory not found: $SSL_DIR"
    command -v docker compose >/dev/null 2>&1 || error_out "Docker Compose not installed"
    success "Dependencies satisfied"
}

check_cyon_credentials() {
    log "Validating Cyon DNS credentials..."
    [[ -n "${CY_Username:-}" && -n "${CY_Password:-}" ]] || error_out "Set CY_Username/CY_Password (and optional CY_OTP_Secret)."
    export CY_Username CY_Password
    [[ -n "${CY_OTP_Secret:-}" ]] && export CY_OTP_Secret && log "2FA token detected"
    success "Cyon DNS API credentials exported"
}

create_backup() {
    log "Backing up current certificates..."
    mkdir -p "$BACKUP_DIR"
    if [[ -f "$SSL_DIR/nginx.crt" ]]; then
        cp "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx.key" "$BACKUP_DIR/"
        success "Backup created at $BACKUP_DIR"
    else
        warning "No existing certificates to back up"
    fi
}

issue_certificate() {
    log "Requesting Let's Encrypt certificate for $DOMAIN..."
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt >/dev/null 2>&1
    "$ACME_HOME/acme.sh" --issue --dns dns_cyon -d "$DOMAIN" --email "$EMAIL" --force >/dev/null 2>&1 \
        || error_out "Certificate issuance failed"
    success "Certificate issued"
}

install_certificate() {
    log "Installing certificates..."
    local temp_dir="/tmp/ssl-new-$(date +%s)"
    mkdir -p "$temp_dir"
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$temp_dir/nginx.crt" \
        --key-file "$temp_dir/nginx.key" \
        --fullchain-file "$temp_dir/nginx-fullchain.crt" \
        --ca-file "$temp_dir/nginx-ca.crt" >/dev/null 2>&1 \
        || error_out "acme.sh install-cert failed"

    openssl x509 -in "$temp_dir/nginx.crt" -noout >/dev/null 2>&1 || error_out "Generated certificate invalid"

    cp "$temp_dir"/* "$SSL_DIR"/
    chmod 644 "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx-fullchain.crt" "$SSL_DIR/nginx-ca.crt"
    chmod 600 "$SSL_DIR/nginx.key"
    rm -rf "$temp_dir"
    success "Certificates installed in $SSL_DIR"
}

verify_certificate() {
    log "Verifying certificate..."
    openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | grep -q "Let's Encrypt" \
        || error_out "Certificate issuer is not Let's Encrypt"
    openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates
}

reload_nginx() {
    log "Reloading nginx..."
    if docker compose exec nginx nginx -t >/dev/null 2>&1; then
        docker compose exec nginx nginx -s reload >/dev/null 2>&1 || docker compose restart nginx
        success "nginx reloaded"
    else
        error_out "nginx configuration invalid"
    fi
}

setup_auto_renewal() {
    log "Configuring auto-renewal..."
    if ! crontab -l 2>/dev/null | grep -q "acme.sh"; then
        (crontab -l 2>/dev/null; echo "0 2 * * * $ACME_HOME/acme.sh --cron --home $ACME_HOME >/dev/null 2>&1") | crontab -
        success "Cron job added"
    else
        success "Cron job already present"
    fi

    cat > "$HOOK_SCRIPT" << 'EOF'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )/../../" && pwd)"
cd "$PROJECT_ROOT"
if docker compose exec nginx nginx -s reload >/dev/null 2>&1; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] nginx reloaded after cert renewal"
else
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] reload failed, restarting container"
  docker compose restart nginx
fi
EOF
    chmod +x "$HOOK_SCRIPT"

    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$SSL_DIR/nginx.crt" \
        --key-file "$SSL_DIR/nginx.key" \
        --fullchain-file "$SSL_DIR/nginx-fullchain.crt" \
        --reloadcmd "$HOOK_SCRIPT" >/dev/null 2>&1
    success "Reload hook configured"
}

main() {
    echo -e "${CYAN}=============================================="
    echo "  ERNI-KI Let's Encrypt SSL Setup"
    echo "  Domain: $DOMAIN"
    echo -e "==============================================${NC}"

    [[ -f "compose.yml" || -f "compose.yml.example" ]] || error_out "Run from ERNI-KI repository root"

    check_dependencies
    check_cyon_credentials
    create_backup
    issue_certificate
    install_certificate
    verify_certificate
    reload_nginx
    setup_auto_renewal

    success "Let's Encrypt SSL setup complete!"
    log "Next steps:"
    echo "1. Verify HTTPS: https://$DOMAIN"
    echo "2. Run SSL Labs scan"
    echo "3. Monitor renewal logs"
    log "Backup directory: $BACKUP_DIR"
}

main "$@"
