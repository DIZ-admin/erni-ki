#!/bin/bash

# ERNI-KI Let's Encrypt staging test (Cloudflare DNS-01)
# Requests a certificate from Let's Encrypt staging to verify DNS automation.

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
STAGING_DIR="$(pwd)/conf/nginx/ssl-staging"
LOG_FILE="$(pwd)/logs/ssl-staging-test.log"

mkdir -p "$(dirname "$LOG_FILE")" "$STAGING_DIR"

log()      { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"; }
success()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_FILE"; }
warning()  { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"; }
error_out(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

check_cloudflare_credentials() {
    log "Checking Cloudflare credentials..."
    if [[ -z "${CF_Token:-}" && -z "${CF_Key:-}" ]]; then
        error_out "Provide CF_Token or CF_Key + CF_Email for Cloudflare"
    fi

    if [[ -n "${CF_Token:-}" ]]; then
        curl -s -H "Authorization: Bearer $CF_Token" -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/user/tokens/verify" | grep -q '"success":true' \
            || error_out "Cloudflare API token invalid"
        success "Cloudflare API token verified"
    else
        curl -s -H "X-Auth-Email: $CF_Email" -H "X-Auth-Key: $CF_Key" -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/user" | grep -q '"success":true' \
            || error_out "Cloudflare Global API key invalid"
        success "Cloudflare Global API key verified"
    fi
}

issue_staging_certificate() {
    log "Requesting staging certificate..."
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt_test >/dev/null 2>&1
    "$ACME_HOME/acme.sh" --issue --dns dns_cf -d "$DOMAIN" --email "$EMAIL" --staging --force \
        >/dev/null 2>&1 || error_out "Failed to issue staging certificate"
    success "Staging certificate issued"
}

install_staging_certificate() {
    log "Installing staging certificate into $STAGING_DIR..."
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$STAGING_DIR/nginx.crt" \
        --key-file "$STAGING_DIR/nginx.key" \
        --fullchain-file "$STAGING_DIR/nginx-fullchain.crt" \
        --ca-file "$STAGING_DIR/nginx-ca.crt" >/dev/null 2>&1 \
        || error_out "Failed to install staging certificate"
    chmod 644 "$STAGING_DIR"/*.crt
    chmod 600 "$STAGING_DIR"/*.key
    success "Staging certificate installed"
}

verify_staging_certificate() {
    log "Validating staging certificate..."
    [[ -f "$STAGING_DIR/nginx.crt" ]] || error_out "Staging cert missing"
    local expiry=$(openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
    local subject=$(openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -subject | sed 's/.*CN=//')
    local issuer=$(openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -issuer | sed 's/.*CN=//')
    log "Subject: $subject"
    log "Issuer: $issuer"
    log "Valid until: $expiry"
}

cleanup_staging() {
    log "Cleaning staging artifacts..."
    "$ACME_HOME/acme.sh" --remove -d "$DOMAIN" >/dev/null 2>&1 || true
    rm -rf "$STAGING_DIR"
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt >/dev/null 2>&1 || true
    success "Cleanup complete"
}

generate_report() {
    local report_file="$(pwd)/logs/ssl-staging-test-report-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "ERNI-KI Let's Encrypt Staging Test Report"
        echo "Generated: $(date)"
        echo "=========================================="
        echo "Domain: $DOMAIN"
        echo "Email:  $EMAIL"
        echo "Challenge: DNS-01 via Cloudflare"
        openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Certificate data unavailable"
    } > "$report_file"
    success "Report saved: $report_file"
}

main() {
    echo -e "${CYAN}=============================================="
    echo "  ERNI-KI Let's Encrypt Staging Test"
    echo -e "==============================================${NC}"

    check_cloudflare_credentials
    issue_staging_certificate
    install_staging_certificate
    verify_staging_certificate
    generate_report
    cleanup_staging

    success "Staging certificate workflow completed"
}

main "$@"
