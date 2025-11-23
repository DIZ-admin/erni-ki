#!/bin/bash

# ERNI-KI SSL Certificate Monitoring Script
# Validity period monitoring SSL certificates и automatic renewal

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions for logging
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

# Configuration
DOMAIN="ki.erni-gruppe.ch"
SSL_DIR="$(pwd)/conf/nginx/ssl"
CERT_FILE="$SSL_DIR/nginx.crt"
FULLCHAIN_FILE="$SSL_DIR/nginx-fullchain.crt"
DAYS_WARNING=30
DAYS_CRITICAL=7
LOG_FILE="$(pwd)/logs/ssl-monitor.log"
WEBHOOK_URL="${SSL_WEBHOOK_URL:-}"

# Creating directories for logs
mkdir -p "$(dirname "$LOG_FILE")"

# Function for отправки уведомлений
send_notification() {
    local message="$1"
    local level="${2:-info}"

    # Logging
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"

    # Webhook уведомление (если настроен)
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"ERNI-KI SSL Monitor: $message\", \"level\":\"$level\"}" \
            >/dev/null 2>&1 || true
    fi

    # Системное уведомление
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "ERNI-KI SSL Monitor" "$message" >/dev/null 2>&1 || true
    fi
}

# Check срока действия certificate
check_certificate_expiry() {
    log "Check срока действия certificate..."

    local cert_to_check="$CERT_FILE"

    # Используем fullchain если доступен (for Let's Encrypt)
    if [ -f "$FULLCHAIN_FILE" ]; then
        cert_to_check="$FULLCHAIN_FILE"
    fi

    if [ ! -f "$cert_to_check" ]; then
        error "Certificate не найден: $cert_to_check"
        send_notification "SSL сертификат не найден: $cert_to_check" "error"
        return 1
    fi

    # Obtaining даты истечения
    local expiry_date
    if ! expiry_date=$(openssl x509 -in "$cert_to_check" -noout -enddate 2>/dev/null | cut -d= -f2); then
        error "Не удалось прочитать дату истечения certificate"
        send_notification "Error чтения SSL certificate" "error"
        return 1
    fi

    # Вычисление days до истечения
    local expiry_timestamp current_timestamp days_left
    expiry_timestamp=$(date -d "$expiry_date" +%s)
    current_timestamp=$(date +%s)
    days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

    log "Certificate действителен до: $expiry_date"
    log "Дней до истечения: $days_left"

    # Check критических сроков
    if [ $days_left -lt 0 ]; then
        error "Certificate истек $((days_left * -1)) days назад!"
        send_notification "SSL сертификат истек $((days_left * -1)) days назад!" "critical"
        return 2
    elif [ $days_left -lt $DAYS_CRITICAL ]; then
        error "КРИТИЧНО: Certificate истекает via $days_left days!"
        send_notification "КРИТИЧНО: SSL сертификат истекает via $days_left days!" "critical"
        return 2
    elif [ $days_left -lt $DAYS_WARNING ]; then
        warning "ATTENTION: Certificate истекает via $days_left days"
        send_notification "ATTENTION: SSL сертификат истекает via $days_left days" "warning"
        return 1
    else
        success "Certificate действителен еще $days_left days"
        return 0
    fi
}

# Check типа certificate
check_certificate_type() {
    log "Check типа certificate..."

    if [ ! -f "$CERT_FILE" ]; then
        warning "Certificate не найден"
        return 1
    fi

    local issuer
    issuer=$(openssl x509 -in "$CERT_FILE" -noout -issuer 2>/dev/null | cut -d= -f2-)

    if echo "$issuer" | grep -qi "let's encrypt"; then
        success "Используется сертификат Let's Encrypt"
        return 0
    elif echo "$issuer" | grep -qi "erni-ki"; then
        warning "Используется самоподписанный сертификат"
        return 1
    else
        log "Используется сертификат от: $issuer"
        return 0
    fi
}

# Автоматическое обновление self-signed certificate
auto_renew_certificate() {
    log "Попытка автоматического обновления self-signed certificate..."

    # Check наличия script обновления
    local renewal_script="$(pwd)/scripts/ssl/renew-self-signed.sh"
    if [ ! -f "$renewal_script" ]; then
        error "Script обновления не найден: $renewal_script"
        send_notification "Script обновления self-signed certificate не найден" "error"
        return 1
    fi

    # Попытка обновления
    log "Starting обновления self-signed certificate..."
    if "$renewal_script"; then
        success "Самоподписанный сертификат успешно обновлен"
        send_notification "Самоподписанный SSL сертификат успешно обновлен" "success"
        return 0
    else
        error "Error обновления self-signed certificate"
        send_notification "Error автоматического обновления self-signed SSL certificate" "error"
        return 1
    fi
}

# Reload nginx
reload_nginx() {
    log "Reload nginx после обновления certificate..."

    # Check конфигурации nginx
    if docker compose exec nginx nginx -t 2>/dev/null; then
        # Reload nginx
        if docker compose exec nginx nginx -s reload 2>/dev/null; then
            success "Nginx успешно перезагружен"
            send_notification "Nginx перезагружен после обновления SSL certificate" "info"
        else
            warning "Error перезагрузки nginx, пробуем restart контейнера"
            if docker compose restart nginx; then
                success "Nginx контейнер перезапущен"
                send_notification "Nginx контейнер перезапущен после обновления SSL" "info"
            else
                error "Error перезапуска nginx контейнера"
                send_notification "Error перезапуска nginx после обновления SSL" "error"
                return 1
            fi
        fi
    else
        error "Error в конфигурации nginx"
        send_notification "Error в конфигурации nginx после обновления SSL" "error"
        return 1
    fi
}

# Check доступности HTTPS
test_https_connectivity() {
    log "Check HTTPS доступности..."

    # Check локального доступа
    if curl -k -I "https://localhost:443/" --connect-timeout 5 >/dev/null 2>&1; then
        success "Локальный HTTPS доступен"
    else
        warning "Локальный HTTPS недоступен"
        send_notification "Локальный HTTPS недоступен" "warning"
        attempt_nginx_recovery "local"
    fi

    # Check доступа via домен
    if curl -k -I "https://$DOMAIN/health" --resolve "$DOMAIN:443:127.0.0.1" --connect-timeout 5 >/dev/null 2>&1 \
       || curl -k -I "https://$DOMAIN/" --connect-timeout 8 >/dev/null 2>&1; then
        success "HTTPS via домен доступен"
    else
        warning "HTTPS via домен недоступен"
        send_notification "HTTPS via домен $DOMAIN недоступен" "warning"
        attempt_nginx_recovery "domain"
    fi
}

attempt_nginx_recovery() {
    local scope="${1:-local}"
    if ! command -v docker >/dev/null 2>&1; then
        warning "Docker не доступен, пропускаю восстановление Nginx ($scope)"
        return
    fi

    log "Попытка восстановить Nginx (${scope} scope)..."
    if docker compose ps nginx >/dev/null 2>&1; then
        if docker compose exec -T nginx nginx -t >/dev/null 2>&1; then
            docker compose exec -T nginx nginx -s reload >/dev/null 2>&1 \
              && success "Nginx перезагружен после ошибки HTTPS (${scope})" \
              || docker compose restart nginx >/dev/null 2>&1
        else
            warning "nginx -t вернул ошибку, выполняю docker compose restart nginx"
            docker compose restart nginx >/dev/null 2>&1 || warning "Не удалось перезапустить nginx автоматически"
        fi
    else
        warning "Container nginx не найден (docker compose ps nginx)"
    fi
}

# Generation отчета
generate_report() {
    local report_file="$(pwd)/logs/ssl-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "ERNI-KI SSL Certificate Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""

        echo "Certificate Information:"
        if [ -f "$CERT_FILE" ]; then
            openssl x509 -in "$CERT_FILE" -noout -subject -issuer -dates 2>/dev/null || echo "Error reading certificate"
        else
            echo "Certificate not found: $CERT_FILE"
        fi
        echo ""

        echo "HTTPS Connectivity:"
        if curl -k -I "https://$DOMAIN/" --connect-timeout 5 >/dev/null 2>&1; then
            echo "✓ HTTPS accessible"
        else
            echo "✗ HTTPS not accessible"
        fi
        echo ""

        echo "SSL Configuration:"
        if echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" >/dev/null 2>&1; then
            echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | grep -E "(Protocol|Cipher|Verify)" || echo "SSL connection failed"
        else
            echo "✗ SSL connection failed"
        fi

    } > "$report_file"

    log "Report сохранен: $report_file"
}

# Main function
main() {
    local action="${1:-check}"

    echo -e "${CYAN}"
    echo "=============================================="
    echo "  ERNI-KI SSL Certificate Monitor"
    echo "  Domain: $DOMAIN"
    echo "  Action: $action"
    echo "=============================================="
    echo -e "${NC}"

    # Check, что мы в корне проекта
    if [ ! -f "compose.yml" ] && [ ! -f "compose.yml.example" ]; then
        error "Script должен запускаться из корня проекта ERNI-KI"
        exit 1
    fi

    case "$action" in
        "check")
            check_certificate_type
            local cert_status
            check_certificate_expiry
            cert_status=$?
            test_https_connectivity

            if [ $cert_status -eq 2 ]; then
                # Критическое состояние - попытка автообновления
                auto_renew_certificate
            fi
            ;;
        "renew")
            auto_renew_certificate
            ;;
        "report")
            generate_report
            ;;
        "test")
            test_https_connectivity
            ;;
        *)
            echo "Usage: $0 [check|renew|report|test]"
            echo "  check  - Check срока действия certificate (по умолчанию)"
            echo "  renew  - Принудительное обновление certificate"
            echo "  report - Generation подробного отчета"
            echo "  test   - Тестирование HTTPS доступности"
            exit 1
            ;;
    esac

    success "Monitoring завершен"
}

# Starting script
main "$@"
