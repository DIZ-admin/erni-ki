#!/bin/bash

# ERNI-KI Self-Signed Certificate Renewal Script
# Update self-signed SSL certificate for ki.erni-gruppe.ch

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
    exit 1
}

# Configuration
DOMAIN="ki.erni-gruppe.ch"
SSL_DIR="$(pwd)/conf/nginx/ssl"
BACKUP_DIR="$(pwd)/.config-backup/ssl-renewal-$(date +%Y%m%d-%H%M%S)"
CERT_VALIDITY_DAYS=730  # 2 years
KEY_SIZE=4096

# Check окружения
check_environment() {
    log "Check окружения..."

    # Check, что мы в корне проекта
    if [ ! -f "compose.yml" ] && [ ! -f "compose.yml.example" ]; then
        error "Script должен запускаться из корня проекта ERNI-KI"
    fi

    # Check директории SSL
    if [ ! -d "$SSL_DIR" ]; then
        error "Directory SSL не найдена: $SSL_DIR"
    fi

    # Check наличия openssl
    if ! command -v openssl >/dev/null 2>&1; then
        error "OpenSSL не найден. Установите openssl"
    fi

    success "Окружение проверено"
}

# Creating резервной копии
create_backup() {
    log "Creating резервной копии текущих certificates..."

    mkdir -p "$BACKUP_DIR"

    if [ -f "$SSL_DIR/nginx.crt" ]; then
        cp "$SSL_DIR/nginx.crt" "$BACKUP_DIR/"
        cp "$SSL_DIR/nginx.key" "$BACKUP_DIR/"

        # Копирование дополнительных файлов если есть
        [ -f "$SSL_DIR/nginx-fullchain.crt" ] && cp "$SSL_DIR/nginx-fullchain.crt" "$BACKUP_DIR/"
        [ -f "$SSL_DIR/nginx-ca.crt" ] && cp "$SSL_DIR/nginx-ca.crt" "$BACKUP_DIR/"

        log "Backup created в: $BACKUP_DIR"

        # Показать информацию о старом сертификате
        echo ""
        log "Info о текущем сертификате:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates
        echo ""
    else
        warning "Текущие сертификаты не найдены"
    fi
}

# Generation нового certificate
generate_certificate() {
    log "Generation нового self-signed certificate..."

    # Creating временной директории
    TEMP_DIR="/tmp/ssl-gen-$$"
    mkdir -p "$TEMP_DIR"

    # Creating конфигурационного файла for расширений
    cat > "$TEMP_DIR/cert.conf" << EOF
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

    # Generation приватного ключа
    log "Generation приватного ключа ($KEY_SIZE бит)..."
    openssl genrsa -out "$TEMP_DIR/nginx.key" $KEY_SIZE

    # Generation certificate
    log "Generation certificate (действителен $CERT_VALIDITY_DAYS days)..."
    openssl req -new -x509 -key "$TEMP_DIR/nginx.key" \
        -out "$TEMP_DIR/nginx.crt" \
        -days $CERT_VALIDITY_DAYS \
        -config "$TEMP_DIR/cert.conf" \
        -extensions v3_req

    # Check сгенерированного certificate
    if openssl x509 -in "$TEMP_DIR/nginx.crt" -noout -text >/dev/null 2>&1; then
        success "Certificate успешно сгенерирован"
    else
        error "Error генерации certificate"
    fi

    # Installation certificates
    log "Installation новых certificates..."
    cp "$TEMP_DIR/nginx.crt" "$SSL_DIR/"
    cp "$TEMP_DIR/nginx.key" "$SSL_DIR/"

    # Creating fullchain (for совместимости)
    cp "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx-fullchain.crt"
    cp "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx-ca.crt"

    # Installation correct access permissions
    chmod 644 "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx-fullchain.crt" "$SSL_DIR/nginx-ca.crt"
    chmod 600 "$SSL_DIR/nginx.key"

    # Очистка временной директории
    rm -rf "$TEMP_DIR"

    success "Новые сертификаты installedы"
}

# Check нового certificate
verify_certificate() {
    log "Check нового certificate..."

    if openssl x509 -in "$SSL_DIR/nginx.crt" -noout -text >/dev/null 2>&1; then
        success "Новый сертификат валиден"

        # Показать информацию о новом сертификате
        echo ""
        log "Info о новом сертификате:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates
        echo ""

        # Check SAN (Subject Alternative Names)
        log "Subject Alternative Names:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -text | grep -A 3 "Subject Alternative Name" || echo "SAN не найдены"
        echo ""
    else
        error "Новый сертификат невалиден"
    fi
}

# Reload nginx
reload_nginx() {
    log "Reload nginx..."

    # Check конфигурации nginx
    if docker compose exec nginx nginx -t 2>/dev/null; then
        # Reload nginx
        if docker compose exec nginx nginx -s reload 2>/dev/null; then
            success "Nginx успешно перезагружен"
        else
            warning "Error перезагрузки nginx, пробуем restart контейнера"
            if docker compose restart nginx; then
                success "Nginx контейнер перезапущен"
            else
                error "Error перезапуска nginx контейнера"
            fi
        fi
    else
        error "Error в конфигурации nginx"
    fi
}

# Тестирование HTTPS
test_https() {
    log "Тестирование HTTPS доступности..."

    # Ожидание запуска nginx
    sleep 5

    # Test локального доступа
    if curl -k -I "https://localhost:443/" --connect-timeout 10 >/dev/null 2>&1; then
        success "Локальный HTTPS доступен"
    else
        warning "Локальный HTTPS недоступен"
    fi

    # Test доступа via домен
    if curl -k -I "https://$DOMAIN/" --connect-timeout 10 >/dev/null 2>&1; then
        success "HTTPS via домен доступен"

        # Показать заголовки ответа
        echo ""
        log "HTTP заголовки ответа:"
        curl -k -I "https://$DOMAIN/" --connect-timeout 10 2>/dev/null | head -5
        echo ""
    else
        warning "HTTPS via домен недоступен"
    fi
}

# Update мониторинга
update_monitoring() {
    log "Update configuration мониторинга..."

    # Update configuration мониторинга
    if [ -f "conf/ssl/monitoring.conf" ]; then
        # Добавление записи о обновлении
        echo "# Certificate обновлен: $(date)" >> conf/ssl/monitoring.conf
        log "Configuration мониторинга обновлена"
    fi

    # Starting проверки мониторинга
    if [ -x "scripts/ssl/monitor-certificates.sh" ]; then
        log "Starting проверки мониторинга..."
        ./scripts/ssl/monitor-certificates.sh check || warning "Error проверки мониторинга"
    fi
}

# Generation отчета
generate_report() {
    local report_file="logs/ssl-renewal-report-$(date +%Y%m%d-%H%M%S).txt"
    mkdir -p "$(dirname "$report_file")"

    {
        echo "ERNI-KI SSL Certificate Renewal Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""

        echo "Certificate Information:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Error reading certificate"
        echo ""

        echo "Backup Location:"
        echo "$BACKUP_DIR"
        echo ""

        echo "HTTPS Test Results:"
        if curl -k -I "https://$DOMAIN/" --connect-timeout 5 >/dev/null 2>&1; then
            echo "✓ HTTPS accessible"
        else
            echo "✗ HTTPS not accessible"
        fi
        echo ""

        echo "Next Renewal Date:"
        echo "$(date -d "+$((CERT_VALIDITY_DAYS - 30)) days" '+%Y-%m-%d') (30 days before expiration)"

    } > "$report_file"

    log "Report сохранен: $report_file"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "=============================================="
    echo "  ERNI-KI Self-Signed Certificate Renewal"
    echo "  Domain: $DOMAIN"
    echo "  Validity: $CERT_VALIDITY_DAYS days"
    echo "=============================================="
    echo -e "${NC}"

    check_environment
    create_backup
    generate_certificate
    verify_certificate
    reload_nginx
    test_https
    update_monitoring
    generate_report

    echo ""
    success "🎉 SSL сертификат успешно обновлен!"
    echo ""
    log "Следующие шаги:"
    echo "1. Проверьте HTTPS доступ: https://$DOMAIN"
    echo "2. Добавьте исключение в браузере for self-signed certificate"
    echo "3. Следующее обновление рекомендуется via $((CERT_VALIDITY_DAYS - 30)) days"
    echo ""
    log "Резервная копия старых certificates: $BACKUP_DIR"
}

# Starting script
main "$@"
