#!/bin/bash

# ERNI-KI Let's Encrypt SSL Test с Staging сервером
# Author: Alteon Schultz (Tech Lead)
# Version: 1.0
# Date: 2025-08-11
# Purpose: Тестирование получения certificate с staging сервера Let's Encrypt

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

# Configuration
DOMAIN="ki.erni-gruppe.ch"
EMAIL="admin@erni-ki.local"
ACME_HOME="$HOME/.acme.sh"
SSL_DIR="$(pwd)/conf/nginx/ssl"
STAGING_DIR="$(pwd)/conf/nginx/ssl-staging"
LOG_FILE="$(pwd)/logs/ssl-staging-test.log"

# Creating директорий
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$STAGING_DIR"

# Check Cloudflare API tokenа
check_cloudflare_credentials() {
    log "Check Cloudflare API tokenа..."

    if [ -z "${CF_Token:-}" ] && [ -z "${CF_Key:-}" ]; then
        error "Cloudflare API token не найден. Установите переменную CF_Token или CF_Key и CF_Email"
    fi

    if [ -n "${CF_Token:-}" ]; then
        log "Используется Cloudflare API Token"
        # Test API tokenа
        if curl -s -H "Authorization: Bearer $CF_Token" \
             -H "Content-Type: application/json" \
             "https://api.cloudflare.com/client/v4/user/tokens/verify" | grep -q '"success":true'; then
            success "Cloudflare API token действителен"
        else
            error "Cloudflare API token недействителен"
        fi
    elif [ -n "${CF_Key:-}" ] && [ -n "${CF_Email:-}" ]; then
        log "Используется Cloudflare Global API Key"
        # Test Global API Key
        if curl -s -H "X-Auth-Email: $CF_Email" \
             -H "X-Auth-Key: $CF_Key" \
             -H "Content-Type: application/json" \
             "https://api.cloudflare.com/client/v4/user" | grep -q '"success":true'; then
            success "Cloudflare Global API Key действителен"
        else
            error "Cloudflare Global API Key недействителен"
        fi
    else
        error "Неполные данные Cloudflare API. Требуется CF_Token или (CF_Key + CF_Email)"
    fi
}

# Obtaining тестового certificate
obtain_staging_certificate() {
    log "Obtaining тестового certificate с Let's Encrypt Staging сервера..."

    # Installation staging сервера
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt_test

    # Obtaining certificate via DNS-01 challenge with Cloudflare API
    if "$ACME_HOME/acme.sh" --issue --dns dns_cf -d "$DOMAIN" --email "$EMAIL" --staging --force; then
        success "Тестовый сертификат successfully obtained"
        return 0
    else
        error "Error получения тестового certificate"
        return 1
    fi
}

# Installation тестового certificate
install_staging_certificate() {
    log "Installation тестового certificate..."

    # Installation certificate в staging директорию
    if "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$STAGING_DIR/nginx.crt" \
        --key-file "$STAGING_DIR/nginx.key" \
        --fullchain-file "$STAGING_DIR/nginx-fullchain.crt" \
        --ca-file "$STAGING_DIR/nginx-ca.crt"; then

        # Installation correct access permissions
        chmod 644 "$STAGING_DIR"/*.crt
        chmod 600 "$STAGING_DIR"/*.key

        success "Тестовый сертификат installed"
    else
        error "Error установки тестового certificate"
    fi
}

# Check тестового certificate
verify_staging_certificate() {
    log "Check тестового certificate..."

    if [ -f "$STAGING_DIR/nginx.crt" ]; then
        # Check срока действия
        local expiry_date=$(openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
        log "Тестовый сертификат действителен до: $expiry_date"

        # Check домена
        local cert_domain=$(openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -subject | grep -o "CN=[^,]*" | cut -d= -f2)
        if [ "$cert_domain" = "$DOMAIN" ]; then
            success "Тестовый сертификат выдан for правильного домена: $cert_domain"
        else
            warning "Domain в сертификате ($cert_domain) не соответствует ожидаемому ($DOMAIN)"
        fi

        # Check издателя (должен быть Fake LE)
        local issuer=$(openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -issuer)
        log "Издатель тестового certificate: $issuer"

        if echo "$issuer" | grep -q "Fake LE"; then
            success "Certificate получен с правильного staging сервера"
        else
            warning "Certificate может быть получен не с staging сервера"
        fi

    else
        error "File тестового certificate не найден: $STAGING_DIR/nginx.crt"
    fi
}

# Очистка тестовых данных
cleanup_staging() {
    log "Очистка тестовых данных..."

    # Deletion staging certificate из acme.sh
    "$ACME_HOME/acme.sh" --remove -d "$DOMAIN" || true

    # Очистка staging директории
    rm -rf "$STAGING_DIR"

    # Возврат к production серверу
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt

    success "Тестовые данные очищены"
}

# Generation отчета
generate_test_report() {
    log "Generation отчета тестирования..."

    local report_file="$(pwd)/logs/ssl-staging-test-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "ERNI-KI Let's Encrypt Staging Test Report"
        echo "Generated: $(date)"
        echo "=========================================="
        echo ""

        echo "Test Configuration:"
        echo "- Domain: $DOMAIN"
        echo "- Email: $EMAIL"
        echo "- Staging Server: Let's Encrypt Staging"
        echo "- Challenge Type: DNS-01 (Cloudflare)"
        echo ""

        echo "API Credentials Test:"
        if [ -n "${CF_Token:-}" ]; then
            echo "- Type: Cloudflare API Token"
            echo "- Status: Configured"
        elif [ -n "${CF_Key:-}" ] && [ -n "${CF_Email:-}" ]; then
            echo "- Type: Cloudflare Global API Key"
            echo "- Status: Configured"
        else
            echo "- Status: NOT CONFIGURED"
        fi
        echo ""

        echo "Certificate Information:"
        if [ -f "$STAGING_DIR/nginx.crt" ]; then
            openssl x509 -in "$STAGING_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Error reading certificate"
        else
            echo "No staging certificate found"
        fi
        echo ""

        echo "Next Steps:"
        echo "1. If test successful, run production script:"
        echo "   ./scripts/ssl/setup-letsencrypt-cloudflare.sh"
        echo "2. Monitor certificate installation"
        echo "3. Test HTTPS access to $DOMAIN"
        echo ""

    } > "$report_file"

    success "Report сохранен: $report_file"
    cat "$report_file"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  ERNI-KI Let's Encrypt Staging Test"
    echo "  Тестирование с безопасным staging сервером"
    echo "=================================================="
    echo -e "${NC}"

    # Check аргументов
    local action="${1:-test}"

    case "$action" in
        "test")
            check_cloudflare_credentials
            obtain_staging_certificate
            install_staging_certificate
            verify_staging_certificate
            generate_test_report
            cleanup_staging
            ;;
        "cleanup")
            cleanup_staging
            ;;
        *)
            echo "Usage: $0 [test|cleanup]"
            echo "  test    - Полное тестирование (по умолчанию)"
            echo "  cleanup - Очистка тестовых данных"
            exit 1
            ;;
    esac

    echo ""
    success "🧪 Тестирование Let's Encrypt завершено!"
    echo ""
    log "Если тест прошел успешно, запустите production скрипт:"
    echo "  ./scripts/ssl/setup-letsencrypt-cloudflare.sh"
    echo ""
    log "Логи тестирования: $LOG_FILE"
}

# Starting script
main "$@" 2>&1 | tee -a "$LOG_FILE"
