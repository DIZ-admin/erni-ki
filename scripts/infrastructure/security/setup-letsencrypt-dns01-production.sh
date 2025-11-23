#!/bin/bash

# =========================================================================
# ERNI-KI Production Let's Encrypt Setup (Cloudflare DNS-01 Challenge)
# =========================================================================
# Issues a certificate for ki.erni-gruppe.ch/www.ki.erni-gruppe.ch via Cloudflare.
# Creates backups, validates dependencies, and configures auto-renewal hooks.
# =========================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SSL_DIR="$PROJECT_ROOT/conf/nginx/ssl"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/ssl-letsencrypt-dns01-$(date +%Y%m%d-%H%M%S)"
ACME_HOME="$HOME/.acme.sh"
LOG_FILE="$PROJECT_ROOT/logs/ssl-letsencrypt-dns01-setup-$(date +%Y%m%d-%H%M%S).log"

DOMAIN="ki.erni-gruppe.ch"
DOMAIN_WWW="www.ki.erni-gruppe.ch"
EMAIL="diginnz1@gmail.com"
CERT_KEYLENGTH=2048

mkdir -p "$(dirname "$LOG_FILE")"

log()      { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"; }
success()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a "$LOG_FILE"; }
warning()  { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"; }
error_out(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"; exit 1; }

print_header() {
    echo -e "${CYAN}============================================================================"
    echo "  ERNI-KI Production Let's Encrypt SSL Setup"
    echo "  Method: Cloudflare DNS-01 Challenge"
    echo "  Domains: $DOMAIN, $DOMAIN_WWW"
    echo "============================================================================${NC}"
}

check_dependencies() {
    log "Checking dependencies..."
    local deps=(docker curl openssl dig)
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || error_out "$dep not installed"
    done
    [[ -d "$SSL_DIR" ]] || error_out "SSL directory not found: $SSL_DIR"
    success "Dependencies satisfied"
}

check_docker_compose() {
    log "Checking Docker Compose..."
    (cd "$PROJECT_ROOT" && docker compose version >/dev/null 2>&1) || error_out "Docker Compose unavailable"
    success "Docker Compose OK"
}

request_cloudflare_token() {
    log "Requesting Cloudflare API token..."
    echo -e "${YELLOW}Follow https://dash.cloudflare.com/profile/api-tokens → Create Token → Edit zone DNS.${NC}"
    echo -e "${GREEN}Paste Cloudflare API Token (input hidden):${NC}"
    read -s CF_Token
    echo
    [[ -n "$CF_Token" ]] || error_out "API token cannot be empty"
    export CF_Token CF_Account_ID=""
    success "Cloudflare token captured"
}

verify_cloudflare_token() {
    log "Validating Cloudflare token..."
    local response
    response=$(curl -s -H "Authorization: Bearer $CF_Token" -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/user/tokens/verify")
    echo "$response" | grep -q '"success":true' || error_out "Cloudflare token invalid"
    success "Cloudflare token verified"
}

create_backrest_backup() {
    log "Creating backrest backup..."
    local backup_tag="ssl-letsencrypt-dns01-$(date +%Y%m%d-%H%M%S)"
    if (cd "$PROJECT_ROOT" && docker compose exec -T backrest backrest backup --tag "$backup_tag" >>"$LOG_FILE" 2>&1); then
        success "Backrest backup created (tag: $backup_tag)"
    else
        warning "Backrest unavailable, falling back to local backup"
        create_local_backup
    fi
}

create_local_backup() {
    log "Creating local backup..."
    mkdir -p "$BACKUP_DIR"
    if ls "$SSL_DIR"/nginx.crt >/dev/null 2>&1; then
        cp "$SSL_DIR"/*.crt "$BACKUP_DIR"/ 2>/dev/null || true
        cp "$SSL_DIR"/*.key "$BACKUP_DIR"/ 2>/dev/null || true
        success "Local backup stored at $BACKUP_DIR"
    else
        warning "No existing certificates to back up"
    fi
}

install_acme_sh() {
    log "Installing/Updating acme.sh..."
    if [[ ! -f "$ACME_HOME/acme.sh" ]]; then
        curl -s https://get.acme.sh | sh -s email="$EMAIL" >>"$LOG_FILE" 2>&1 || error_out "acme.sh install failed"
    fi
    "$ACME_HOME/acme.sh" --upgrade >>"$LOG_FILE" 2>&1 || true
    success "acme.sh ready"
}

issue_certificate() {
    log "Requesting certificate via DNS-01..."
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt >>"$LOG_FILE" 2>&1
    "$ACME_HOME/acme.sh" --issue --dns dns_cf -d "$DOMAIN" -d "$DOMAIN_WWW" \
        --email "$EMAIL" --keylength "$CERT_KEYLENGTH" --force >>"$LOG_FILE" 2>&1 \
        || error_out "Certificate issuance failed"
    success "Certificate issued"
}

install_certificate() {
    log "Installing certificate into $SSL_DIR..."
    local temp_dir="/tmp/ssl-install-$(date +%s)"
    mkdir -p "$temp_dir"
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --key-file "$temp_dir/nginx.key" \
        --fullchain-file "$temp_dir/nginx-fullchain.crt" \
        --cert-file "$temp_dir/nginx.crt" \
        --ca-file "$temp_dir/nginx-ca.crt" >>"$LOG_FILE" 2>&1 \
        || error_out "acme.sh install-cert failed"
    cp "$temp_dir"/* "$SSL_DIR"/
    chmod 600 "$SSL_DIR"/*.key
    chmod 644 "$SSL_DIR"/*.crt
    rm -rf "$temp_dir"
    success "Certificate installed"
}

verify_certificate() {
    log "Validating deployed certificate..."
    [[ -f "$SSL_DIR/nginx.crt" ]] || error_out "nginx.crt missing"
    local expiry=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
    local subject=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject | sed 's/.*CN=//')
    local issuer=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | sed 's/.*CN=//')
    log "Expires: $expiry"
    log "Subject: $subject"
    log "Issuer: $issuer"
}

reload_nginx() {
    log "Reloading nginx..."
    (cd "$PROJECT_ROOT" && docker compose exec -T nginx nginx -t) || error_out "nginx config invalid"
    if (cd "$PROJECT_ROOT" && docker compose exec -T nginx nginx -s reload); then
        success "nginx reloaded"
    else
        warning "Reload failed, restarting container"
        (cd "$PROJECT_ROOT" && docker compose restart nginx) || error_out "Unable to restart nginx"
    fi
}

configure_renewal_hook() {
    log "Configuring renewal hook..."
    local hook_script="$ACME_HOME/nginx-reload-hook.sh"
    cat > "$hook_script" << 'EOF'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )/../../" && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/ssl-renew-hook.log"
{
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Renewal hook triggered"
  cd "$PROJECT_ROOT" && docker compose exec -T nginx nginx -s reload \
    && echo "[$(date +'%Y-%m-%d %H:%M:%S')] nginx reloaded" \
    || docker compose restart nginx
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Hook completed"
} >> "$LOG_FILE" 2>&1
EOF
    chmod +x "$hook_script"
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --key-file "$SSL_DIR/nginx.key" \
        --fullchain-file "$SSL_DIR/nginx-fullchain.crt" \
        --cert-file "$SSL_DIR/nginx.crt" \
        --ca-file "$SSL_DIR/nginx-ca.crt" \
        --reloadcmd "$hook_script" >>"$LOG_FILE" 2>&1
    success "Renewal hook configured"
}

main() {
    print_header
    check_dependencies
    check_docker_compose
    request_cloudflare_token
    verify_cloudflare_token
    create_backrest_backup
    install_acme_sh
    issue_certificate
    install_certificate
    verify_certificate
    reload_nginx
    configure_renewal_hook

    success "Let's Encrypt DNS-01 setup completed!"
    echo "Next steps:"
    echo "  1. Test HTTPS access: https://$DOMAIN"
    echo "  2. Run SSL Labs scan: https://www.ssllabs.com/ssltest/"
    echo "  3. Certificates auto-renew via acme.sh + Cloudflare"
    log "Backup directory: $BACKUP_DIR"
    log "Full log: $LOG_FILE"
}

main "$@"
