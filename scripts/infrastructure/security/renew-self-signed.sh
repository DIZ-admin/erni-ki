#!/bin/bash

# ERNI-KI Self-Signed Certificate Renewal Script
# Generates a new self-signed certificate for ki.erni-gruppe.ch

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()      { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"; }
success()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"; }
warning()  { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error_out(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; exit 1; }

DOMAIN="ki.erni-gruppe.ch"
SSL_DIR="$(pwd)/conf/nginx/ssl"
BACKUP_DIR="$(pwd)/.config-backup/ssl-renewal-$(date +%Y%m%d-%H%M%S)"
CERT_VALIDITY_DAYS=730
KEY_SIZE=4096

check_environment() {
    log "Validating environment..."

    if [[ ! -f "compose.yml" && ! -f "compose.yml.example" ]]; then
        error_out "Run this script from the ERNI-KI repository root"
    fi

    [[ -d "$SSL_DIR" ]] || error_out "SSL directory not found: $SSL_DIR"
    command -v openssl >/dev/null 2>&1 || error_out "OpenSSL not installed"

    success "Environment looks good"
}

create_backup() {
    log "Backing up existing certificates..."
    mkdir -p "$BACKUP_DIR"

    if [[ -f "$SSL_DIR/nginx.crt" ]]; then
        cp "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx.key" "$BACKUP_DIR/"
        [[ -f "$SSL_DIR/nginx-fullchain.crt" ]] && cp "$SSL_DIR/nginx-fullchain.crt" "$BACKUP_DIR/"
        [[ -f "$SSL_DIR/nginx-ca.crt" ]] && cp "$SSL_DIR/nginx-ca.crt" "$BACKUP_DIR/"

        log "Backup stored in: $BACKUP_DIR"
        log "Current certificate details:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates
    else
        warning "No existing certificates found"
    fi
}

generate_certificate() {
    log "Generating new self-signed certificate..."

    local temp_dir="/tmp/ssl-gen-$$"
    mkdir -p "$temp_dir"

    cat > "$temp_dir/cert.conf" << EOF
[req]
default_bits = $KEY_SIZE
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=CH
ST=Zurich
L=Zurich
O=ERNI-KI
OU=IT Department
CN=$DOMAIN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = 192.168.62.140
EOF

    log "Generating ${KEY_SIZE}-bit private key..."
    openssl genrsa -out "$temp_dir/nginx.key" $KEY_SIZE

    log "Generating certificate (valid for $CERT_VALIDITY_DAYS days)..."
    openssl req -new -x509 -key "$temp_dir/nginx.key" \
        -out "$temp_dir/nginx.crt" \
        -days $CERT_VALIDITY_DAYS \
        -config "$temp_dir/cert.conf" \
        -extensions v3_req

    openssl x509 -in "$temp_dir/nginx.crt" -noout -text >/dev/null 2>&1 \
        || error_out "Generated certificate is invalid"

    log "Installing new certificates..."
    cp "$temp_dir/nginx.crt" "$SSL_DIR/"
    cp "$temp_dir/nginx.key" "$SSL_DIR/"
    cp "$temp_dir/nginx.crt" "$SSL_DIR/nginx-fullchain.crt"
    cp "$temp_dir/nginx.crt" "$SSL_DIR/nginx-ca.crt"

    chmod 644 "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx-fullchain.crt" "$SSL_DIR/nginx-ca.crt"
    chmod 600 "$SSL_DIR/nginx.key"

    rm -rf "$temp_dir"
    success "Self-signed certificate installed"
}

verify_certificate() {
    log "Verifying new certificate..."

    if openssl x509 -in "$SSL_DIR/nginx.crt" -noout -text >/dev/null 2>&1; then
        success "Certificate validation succeeded"
        log "New certificate details:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates
        log "Subject Alternative Names:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -text | grep -A 3 "Subject Alternative Name" || echo "No SAN entries"
    else
        error_out "New certificate is invalid"
    fi
}

reload_nginx() {
    log "Reloading nginx..."

    if docker compose exec nginx nginx -t >/dev/null 2>&1; then
        if docker compose exec nginx nginx -s reload >/dev/null 2>&1; then
            success "nginx reloaded"
        else
            warning "nginx reload failed, restarting container"
            docker compose restart nginx >/dev/null 2>&1 || error_out "Unable to restart nginx"
        fi
    else
        error_out "nginx configuration check failed"
    fi
}

test_https() {
    log "Testing HTTPS endpoints..."
    sleep 5

    if curl -k -I "https://localhost:443/" --connect-timeout 10 >/dev/null 2>&1; then
        success "Local HTTPS reachable"
    else
        warning "Local HTTPS unavailable"
    fi

    if curl -k -I "https://$DOMAIN/" --connect-timeout 10 >/dev/null 2>&1; then
        success "HTTPS reachable via domain"
        log "Response headers:"
        curl -k -I "https://$DOMAIN/" --connect-timeout 10 2>/dev/null | head -5
    else
        warning "HTTPS unavailable via $DOMAIN"
    fi
}

update_monitoring() {
    log "Updating monitoring metadata..."

    if [[ -f "conf/ssl/monitoring.conf" ]]; then
        echo "# Certificate renewed: $(date)" >> conf/ssl/monitoring.conf
        log "Monitoring configuration updated"
    fi

    if [[ -x "scripts/ssl/monitor-certificates.sh" ]]; then
        log "Triggering ssl monitoring check..."
        ./scripts/ssl/monitor-certificates.sh check || warning "Monitoring check reported an issue"
    fi
}

generate_report() {
    local report_file="logs/ssl-renewal-report-$(date +%Y%m%d-%H%M%S).txt"
    mkdir -p "$(dirname "$report_file")"

    {
        echo "ERNI-KI SSL Certificate Renewal Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo

        echo "Certificate Information:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Unable to read certificate"
        echo

        echo "Backup Location:"
        echo "$BACKUP_DIR"
        echo

        echo "HTTPS Test:"
        if curl -k -I "https://$DOMAIN/" --connect-timeout 5 >/dev/null 2>&1; then
            echo "✓ HTTPS accessible"
        else
            echo "✗ HTTPS not accessible"
        fi
        echo

        echo "Next Renewal Reminder:"
        echo "$(date -d "+$((CERT_VALIDITY_DAYS - 30)) days" '+%Y-%m-%d') (30 days before expiration)"
    } > "$report_file"

    log "Report saved to $report_file"
}

main() {
    echo -e "${CYAN}=============================================="
    echo "  ERNI-KI Self-Signed Certificate Renewal"
    echo "  Domain: $DOMAIN"
    echo "  Validity: $CERT_VALIDITY_DAYS days"
    echo "==============================================${NC}"

    check_environment
    create_backup
    generate_certificate
    verify_certificate
    reload_nginx
    test_https
    update_monitoring
    generate_report

    success "Self-signed certificate renewed successfully!"
    log "Next steps:"
    echo "1. Validate HTTPS: https://$DOMAIN"
    echo "2. Accept the self-signed certificate in browsers if prompted"
    echo "3. Plan the next renewal ~$((CERT_VALIDITY_DAYS - 30)) days from now"
    log "Backup directory: $BACKUP_DIR"
}

main "$@"
