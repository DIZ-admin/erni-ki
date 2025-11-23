#!/bin/bash

# ERNI-KI SSL Certificate Monitoring Script
# Tracks certificate validity, performs optional renewals, and verifies HTTPS

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
error_msg(){ echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }

DOMAIN="ki.erni-gruppe.ch"
SSL_DIR="$(pwd)/conf/nginx/ssl"
CERT_FILE="$SSL_DIR/nginx.crt"
FULLCHAIN_FILE="$SSL_DIR/nginx-fullchain.crt"
DAYS_WARNING=30
DAYS_CRITICAL=7
LOG_FILE="$(pwd)/logs/ssl-monitor.log"
WEBHOOK_URL="${SSL_WEBHOOK_URL:-}"

mkdir -p "$(dirname "$LOG_FILE")"

send_notification() {
    local message="$1"
    local level="${2:-info}"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"

    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"ERNI-KI SSL Monitor: $message\", \"level\":\"$level\"}" \
            >/dev/null 2>&1 || true
    fi

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "ERNI-KI SSL Monitor" "$message" >/dev/null 2>&1 || true
    fi
}

check_certificate_expiry() {
    log "Checking certificate expiration..."
    local cert_to_check="$CERT_FILE"

    [[ -f "$FULLCHAIN_FILE" ]] && cert_to_check="$FULLCHAIN_FILE"

    if [[ ! -f "$cert_to_check" ]]; then
        error_msg "Certificate not found: $cert_to_check"
        send_notification "SSL certificate missing: $cert_to_check" "error"
        return 1
    fi

    local expiry_date
    if ! expiry_date=$(openssl x509 -in "$cert_to_check" -noout -enddate 2>/dev/null | cut -d= -f2); then
        error_msg "Unable to read expiration date"
        send_notification "Failed to read SSL certificate" "error"
        return 1
    fi

    local expiry_timestamp=$(date -d "$expiry_date" +%s)
    local current_timestamp=$(date +%s)
    local days_left=$(((expiry_timestamp - current_timestamp) / 86400))

    log "Certificate valid until: $expiry_date"
    log "Days left: $days_left"

    if (( days_left < 0 )); then
        error_msg "Certificate expired $((-days_left)) days ago"
        send_notification "SSL certificate expired $((-days_left)) days ago" "critical"
        return 2
    elif (( days_left < DAYS_CRITICAL )); then
        error_msg "CRITICAL: certificate expires in $days_left days"
        send_notification "CRITICAL: SSL certificate expires in $days_left days" "critical"
        return 2
    elif (( days_left < DAYS_WARNING )); then
        warning "Certificate expires in $days_left days"
        send_notification "SSL certificate expires in $days_left days" "warning"
        return 1
    else
        success "Certificate valid for another $days_left days"
        return 0
    fi
}

check_certificate_type() {
    log "Detecting certificate issuer..."
    if [[ ! -f "$CERT_FILE" ]]; then
        warning "Certificate not found"
        return 1
    fi

    local issuer
    issuer=$(openssl x509 -in "$CERT_FILE" -noout -issuer 2>/dev/null | cut -d= -f2-)

    if echo "$issuer" | grep -qi "let's encrypt"; then
        success "Let's Encrypt certificate detected"
    elif echo "$issuer" | grep -qi "erni-ki"; then
        warning "Self-signed ERNI-KI certificate detected"
    else
        log "Issuer: $issuer"
    fi
}

auto_renew_certificate() {
    log "Attempting automatic self-signed renewal..."
    local renewal_script="$(pwd)/scripts/ssl/renew-self-signed.sh"

    if [[ ! -f "$renewal_script" ]]; then
        error_msg "Renewal script not found: $renewal_script"
        send_notification "Self-signed renewal script missing" "error"
        return 1
    fi

    if "$renewal_script"; then
        success "Self-signed certificate renewed"
        send_notification "Self-signed SSL certificate renewed" "success"
    else
        error_msg "Self-signed renewal failed"
        send_notification "Automatic self-signed renewal failed" "error"
        return 1
    fi
}

reload_nginx() {
    log "Reloading nginx after certificate update..."

    if docker compose exec nginx nginx -t >/dev/null 2>&1; then
        if docker compose exec nginx nginx -s reload >/dev/null 2>&1; then
            success "nginx reloaded"
            send_notification "nginx reloaded after SSL update" "info"
        else
            warning "nginx reload failed, restarting container"
            if docker compose restart nginx >/dev/null 2>&1; then
                success "nginx container restarted"
                send_notification "nginx container restarted after SSL update" "info"
            else
                error_msg "Unable to restart nginx container"
                send_notification "Failed to restart nginx after SSL update" "error"
                return 1
            fi
        fi
    else
        error_msg "nginx configuration check failed"
        send_notification "nginx configuration invalid after SSL update" "error"
        return 1
    fi
}

test_https_connectivity() {
    log "Validating HTTPS endpoints..."

    if curl -k -I "https://localhost:443/" --connect-timeout 5 >/dev/null 2>&1; then
        success "HTTPS reachable locally"
    else
        warning "Local HTTPS unavailable"
        send_notification "Local HTTPS unavailable" "warning"
        attempt_nginx_recovery "local"
    fi

    if curl -k -I "https://$DOMAIN/health" --resolve "$DOMAIN:443:127.0.0.1" --connect-timeout 5 >/dev/null 2>&1 \
        || curl -k -I "https://$DOMAIN/" --connect-timeout 8 >/dev/null 2>&1; then
        success "HTTPS reachable via domain"
    else
        warning "HTTPS unreachable via $DOMAIN"
        send_notification "Domain HTTPS check failed for $DOMAIN" "warning"
        attempt_nginx_recovery "domain"
    fi
}

attempt_nginx_recovery() {
    local scope="${1:-local}"
    if ! command -v docker >/dev/null 2>&1; then
        warning "Docker unavailable, skipping nginx recovery (${scope})"
        return
    fi

    log "Attempting nginx recovery (${scope})..."
    if docker compose ps nginx >/dev/null 2>&1; then
        if docker compose exec -T nginx nginx -t >/dev/null 2>&1; then
            docker compose exec -T nginx nginx -s reload >/dev/null 2>&1 \
                && success "nginx reloaded (${scope})" \
                || docker compose restart nginx >/dev/null 2>&1
        else
            warning "nginx -t failed, restarting container"
            docker compose restart nginx >/dev/null 2>&1 || warning "Unable to restart nginx automatically"
        fi
    else
        warning "nginx container not found"
    fi
}

generate_report() {
    local report_file="$(pwd)/logs/ssl-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "ERNI-KI SSL Certificate Report"
        echo "Generated: $(date)"
        echo "================================"
        echo

        echo "Certificate Information:"
        if [[ -f "$CERT_FILE" ]]; then
            openssl x509 -in "$CERT_FILE" -noout -subject -issuer -dates 2>/dev/null || echo "Unable to read certificate"
        else
            echo "Certificate not found: $CERT_FILE"
        fi
        echo

        echo "HTTPS Connectivity:"
        if curl -k -I "https://$DOMAIN/" --connect-timeout 5 >/dev/null 2>&1; then
            echo "✓ HTTPS accessible"
        else
            echo "✗ HTTPS not accessible"
        fi
        echo

        echo "SSL Configuration:"
        if echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" >/dev/null 2>&1; then
            echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null |
                grep -E "(Protocol|Cipher|Verify)" || echo "SSL connection failed"
        else
            echo "✗ SSL connection failed"
        fi

    } > "$report_file"

    log "Report saved to $report_file"
}

main() {
    local action="${1:-check}"

    echo -e "${CYAN}=============================================="
    echo "  ERNI-KI SSL Certificate Monitor"
    echo "  Domain: $DOMAIN"
    echo "  Action: $action"
    echo "==============================================${NC}"

    if [[ ! -f "compose.yml" && ! -f "compose.yml.example" ]]; then
        error_msg "Run this script from the ERNI-KI repository root"
        exit 1
    fi

    case "$action" in
        check)
            check_certificate_type
            local cert_status=0
            check_certificate_expiry || cert_status=$?
            test_https_connectivity
            if [[ $cert_status -eq 2 ]]; then
                auto_renew_certificate
            fi
            ;;
        renew)
            auto_renew_certificate
            ;;
        report)
            generate_report
            ;;
        test)
            test_https_connectivity
            ;;
        *)
            echo "Usage: $0 [check|renew|report|test]"
            echo "  check  - Default mode: validate certificates and endpoints"
            echo "  renew  - Force self-signed renewal"
            echo "  report - Generate SSL status report"
            echo "  test   - Run HTTPS health checks"
            exit 1
            ;;
    esac

    success "Monitoring completed"
}

main "$@"
