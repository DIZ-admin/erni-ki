#!/bin/bash

# Nginx configuration test for ERNI-KI
# Validates syntax and SSL settings

set -euo pipefail

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging helpers
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Check nginx config syntax
test_nginx_syntax() {
    log "Checking nginx configuration syntax..."

    # Check via Docker if nginx is running
    if docker compose ps nginx 2>/dev/null | grep -q "Up"; then
        if docker compose exec nginx nginx -t 2>/dev/null; then
            success "Nginx configuration syntax is valid"
            return 0
        else
            error "Nginx configuration syntax error"
            docker compose exec nginx nginx -t
            return 1
        fi
    else
        warning "Nginx not running, syntax check skipped"
        return 0
    fi
}

# Check SSL certificates
test_ssl_certificates() {
    log "Checking SSL certificates..."

    local ssl_dir="conf/nginx/ssl"
    local cert_file="$ssl_dir/nginx.crt"
    local key_file="$ssl_dir/nginx.key"
    local fullchain_file="$ssl_dir/nginx-fullchain.crt"

    # Check main certificate
    if [ -f "$cert_file" ]; then
        if openssl x509 -in "$cert_file" -noout -text >/dev/null 2>&1; then
            success "Primary certificate is valid"

            # Show certificate info
            echo ""
            log "Certificate info:"
            openssl x509 -in "$cert_file" -noout -subject -issuer -dates
            echo ""
        else
            error "Primary certificate is corrupted"
            return 1
        fi
    else
        warning "Primary certificate not found: $cert_file"
    fi

    # Check private key
    if [ -f "$key_file" ]; then
        if openssl rsa -in "$key_file" -check -noout >/dev/null 2>&1; then
            success "Private key is valid"
        else
            error "Private key is corrupted"
            return 1
        fi
    else
        warning "Private key not found: $key_file"
    fi

    # Check fullchain certificate (for Let's Encrypt)
    if [ -f "$fullchain_file" ]; then
        if openssl x509 -in "$fullchain_file" -noout -text >/dev/null 2>&1; then
            success "Fullchain certificate is valid"
        else
            warning "Fullchain certificate is corrupted"
        fi
    else
        log "Fullchain certificate not found (created when obtaining Let's Encrypt)"
    fi

    # Verify key matches certificate
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        local cert_modulus=$(openssl x509 -noout -modulus -in "$cert_file" 2>/dev/null | openssl md5)
        local key_modulus=$(openssl rsa -noout -modulus -in "$key_file" 2>/dev/null | openssl md5)

        if [ "$cert_modulus" = "$key_modulus" ]; then
            success "Certificate and key match"
        else
            error "Certificate and key do not match"
            return 1
        fi
    fi
}

# Check HTTPS availability
test_https_access() {
    log "Checking HTTPS availability..."

    local domain="ki.erni-gruppe.ch"

    # Local HTTPS
    if curl -k -I "https://localhost:443/" --connect-timeout 5 >/dev/null 2>&1; then
        success "Local HTTPS reachable"
    else
        warning "Local HTTPS unreachable"
    fi

    # HTTPS via domain
    if curl -k -I "https://$domain/" --connect-timeout 5 >/dev/null 2>&1; then
        success "HTTPS via domain reachable"

        # Show response headers
        echo ""
        log "HTTP response headers:"
        curl -k -I "https://$domain/" --connect-timeout 5 2>/dev/null | head -10
        echo ""
    else
        warning "HTTPS via domain unreachable"
    fi
}

# Check SSL configuration
test_ssl_configuration() {
    log "Checking SSL configuration..."

    local domain="ki.erni-gruppe.ch"

    # SSL handshake
    if echo | openssl s_client -connect "$domain:443" -servername "$domain" >/dev/null 2>&1; then
        success "SSL connection established"

        # Show SSL details
        echo ""
        log "SSL connection details:"
        echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | grep -E "(Protocol|Cipher|Verify)"
        echo ""
    else
        warning "Failed to establish SSL connection"
    fi
}

# Check security headers
test_security_headers() {
    log "Checking security headers..."

    local domain="ki.erni-gruppe.ch"

    if curl -k -I "https://$domain/" --connect-timeout 5 >/dev/null 2>&1; then
        local headers=$(curl -k -I "https://$domain/" --connect-timeout 5 2>/dev/null)

        # HSTS
        if echo "$headers" | grep -qi "strict-transport-security"; then
            success "HSTS header present"
        else
            warning "HSTS header missing"
        fi

        # X-Frame-Options
        if echo "$headers" | grep -qi "x-frame-options"; then
            success "X-Frame-Options header present"
        else
            warning "X-Frame-Options header missing"
        fi

        # X-Content-Type-Options
        if echo "$headers" | grep -qi "x-content-type-options"; then
            success "X-Content-Type-Options header present"
        else
            warning "X-Content-Type-Options header missing"
        fi

        # CSP
        if echo "$headers" | grep -qi "content-security-policy"; then
            success "Content-Security-Policy header present"
        else
            warning "Content-Security-Policy header missing"
        fi
    else
        warning "Unable to retrieve headers for security checks"
    fi
}

# Report generation
generate_report() {
    echo ""
    log "=== NGINX SSL CONFIGURATION TEST REPORT ==="
    echo ""

    log "Recommendations:"
    echo "1. After obtaining Let's Encrypt certificate, restart nginx"
    echo "2. Check SSL rating at https://www.ssllabs.com/ssltest/"
    echo "3. Ensure all services are reachable via HTTPS"
    echo "4. Monitor certificate expiration"
    echo ""

    log "Useful commands:"
    echo "- Check certificate: openssl x509 -in conf/nginx/ssl/nginx.crt -text -noout"
    echo "- Reload nginx: docker compose restart nginx"
    echo "- Check logs: docker compose logs nginx"
    echo "- SSL test: echo | openssl s_client -connect ki.erni-gruppe.ch:443"
}

# Main
main() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "  ERNI-KI Nginx SSL Configuration Test"
    echo "=============================================="
    echo -e "${NC}"

    # Ensure we are in project root
    if [ ! -f "compose.yml" ] && [ ! -f "compose.yml.example" ]; then
        error "Script must be run from ERNI-KI project root"
        exit 1
    fi

    test_nginx_syntax
    test_ssl_certificates
    test_https_access
    test_ssl_configuration
    test_security_headers
    generate_report

    success "Testing completed!"
}

# Script entry
main "$@"
