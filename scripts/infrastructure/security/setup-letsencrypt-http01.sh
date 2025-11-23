#!/bin/bash

# ERNI-KI Let's Encrypt SSL Setup с HTTP-01 Challenge
# Author: Alteon Schultz (Tech Lead)
# Version: 1.0
# Date: 2025-08-11
# ATTENTION: Требует отключения Cloudflare проксирования!

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
WEBROOT_DIR="$(pwd)/data/certbot"
BACKUP_DIR="$(pwd)/.config-backup/ssl-http01-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$(pwd)/logs/ssl-http01-setup.log"

# Creating директорий
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"
mkdir -p "$WEBROOT_DIR"

# Check предварительных условий
check_prerequisites() {
    log "Check предварительных условий for HTTP-01 Challenge..."

    # Check acme.sh
    if [ ! -f "$ACME_HOME/acme.sh" ]; then
        error "acme.sh не найден. Установите его сначала."
    fi

    # Check Docker
    if ! command -v docker-compose &> /dev/null; then
        error "docker-compose не найден."
    fi

    # Check nginx контейнера
    if ! docker-compose ps nginx | grep -q "healthy"; then
        error "Nginx контейнер не запущен или не здоров."
    fi

    # IMPORTANT ПРЕДУПРЕЖДЕНИЕ
    warning "ATTENTION: HTTP-01 Challenge требует:"
    echo "1. Отключения Cloudflare проксирования (оранжевое облако → серое)"
    echo "2. Прямого доступа к серверу via порт 80"
    echo "3. A-записи домена должна указывать на реальный IP сервера"
    echo ""
    echo -n "Вы подтверждаете, что выполнили эти требования? (y/N): "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        error "Setup отменена. Выполните требования и запустите скрипт снова."
    fi

    success "Предварительные условия проверены"
}

# Check доступности домена
check_domain_accessibility() {
    log "Check доступности домена $DOMAIN..."

    # Check DNS резолюции
    local resolved_ip=$(nslookup "$DOMAIN" | grep -A1 "Non-authoritative answer:" | grep "Address:" | awk '{print $2}' | head -1)
    log "Domain резолвится в: $resolved_ip"

    # Check доступности порта 80
    if curl -I --connect-timeout 10 "http://$DOMAIN/" >/dev/null 2>&1; then
        success "Domain доступен via HTTP"
    else
        error "Domain недоступен via HTTP. Проверьте DNS и Cloudflare настройки."
    fi
}

# Creating резервной копии
create_backup() {
    log "Creating резервной копии..."

    cp -r "$SSL_DIR" "$BACKUP_DIR/"
    success "Backup created: $BACKUP_DIR"
}

# Setup nginx for webroot
setup_nginx_webroot() {
    log "Setup nginx for webroot challenge..."

    # Creating временной конфигурации for ACME challenge
    local acme_conf="/tmp/acme-challenge.conf"
    cat > "$acme_conf" << EOF
# Временная конфигурация for Let's Encrypt HTTP-01 Challenge
location /.well-known/acme-challenge/ {
    root /var/www/certbot;
    try_files \$uri =404;
    access_log off;
    log_not_found off;

    # Заголовки for ACME challenge
    add_header Content-Type "text/plain" always;
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
}
EOF

    # Копирование конфигурации в nginx контейнер
    docker cp "$acme_conf" erni-ki-nginx-1:/etc/nginx/conf.d/acme-challenge.conf

    # Добавление volume mount for webroot (если не существует)
    if ! docker-compose config | grep -q "/var/www/certbot"; then
        warning "Webroot volume не настроен в docker-compose.yml"
        log "Creating временного bind mount..."

        # Creating временного контейнера с webroot
        docker-compose exec nginx mkdir -p /var/www/certbot
        docker cp "$WEBROOT_DIR/." erni-ki-nginx-1:/var/www/certbot/
    fi

    # Reload nginx
    if docker-compose exec nginx nginx -t; then
        docker-compose exec nginx nginx -s reload
        success "Nginx настроен for webroot challenge"
    else
        error "Error в конфигурации nginx"
    fi

    # Очистка временного файла
    rm -f "$acme_conf"
}

# Obtaining certificate Let's Encrypt
obtain_certificate() {
    log "Obtaining Let's Encrypt certificate via HTTP-01 Challenge..."

    # Installation Let's Encrypt сервера
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt

    # Obtaining certificate via webroot
    if "$ACME_HOME/acme.sh" --issue --webroot -w "$WEBROOT_DIR" -d "$DOMAIN" --email "$EMAIL" --force; then
        success "Certificate successfully obtained"
    else
        error "Error получения certificate"
    fi
}

# Installation certificate
install_certificate() {
    log "Installation certificate в nginx..."

    # Installation certificate с правильными путями
    if "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$SSL_DIR/nginx.crt" \
        --key-file "$SSL_DIR/nginx.key" \
        --fullchain-file "$SSL_DIR/nginx-fullchain.crt" \
        --ca-file "$SSL_DIR/nginx-ca.crt" \
        --reloadcmd "docker-compose exec nginx nginx -s reload"; then

        # Installation correct access permissions
        chmod 644 "$SSL_DIR"/*.crt
        chmod 600 "$SSL_DIR"/*.key

        success "Certificate installed в nginx"
    else
        error "Error установки certificate"
    fi
}

# Очистка временной конфигурации
cleanup_nginx_config() {
    log "Очистка временной конфигурации nginx..."

    # Deletion временной конфигурации ACME
    docker-compose exec nginx rm -f /etc/nginx/conf.d/acme-challenge.conf

    # Reload nginx
    if docker-compose exec nginx nginx -t; then
        docker-compose exec nginx nginx -s reload
        success "Временная конфигурация очищена"
    else
        warning "Error when очистке конфигурации nginx"
    fi
}

# Check certificate
verify_certificate() {
    log "Check installedного certificate..."

    if [ -f "$SSL_DIR/nginx.crt" ]; then
        # Check издателя
        local issuer=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | grep -o "CN=[^,]*" | cut -d= -f2)
        log "Издатель certificate: $issuer"

        if echo "$issuer" | grep -q "Let's Encrypt"; then
            success "Certificate выдан Let's Encrypt"
        else
            warning "Certificate не от Let's Encrypt: $issuer"
        fi

        # Check срока действия
        local expiry_date=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
        log "Certificate действителен до: $expiry_date"

    else
        error "File certificate не найден: $SSL_DIR/nginx.crt"
    fi
}

# Тестирование HTTPS
test_https() {
    log "Тестирование HTTPS доступа..."

    if curl -I "https://$DOMAIN/" --connect-timeout 10 >/dev/null 2>&1; then
        success "HTTPS доступ работает"
    else
        warning "HTTPS доступ недоступен"
    fi
}

# Generation отчета
generate_report() {
    log "Generation отчета..."

    local report_file="$(pwd)/logs/ssl-http01-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "ERNI-KI Let's Encrypt HTTP-01 Setup Report"
        echo "Generated: $(date)"
        echo "==========================================="
        echo ""

        echo "Configuration:"
        echo "- Domain: $DOMAIN"
        echo "- Method: HTTP-01 Challenge"
        echo "- Webroot: $WEBROOT_DIR"
        echo "- SSL Directory: $SSL_DIR"
        echo "- Backup: $BACKUP_DIR"
        echo ""

        echo "Certificate Information:"
        if [ -f "$SSL_DIR/nginx.crt" ]; then
            openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Error reading certificate"
        else
            echo "Certificate not found"
        fi
        echo ""

        echo "HTTPS Test:"
        if curl -I "https://$DOMAIN/" --connect-timeout 5 >/dev/null 2>&1; then
            echo "✓ HTTPS accessible"
        else
            echo "✗ HTTPS not accessible"
        fi
        echo ""

        echo "Important Notes:"
        echo "- Remember to re-enable Cloudflare proxying if needed"
        echo "- Monitor certificate expiry (90 days)"
        echo "- Set up automatic renewal"
        echo ""

    } > "$report_file"

    success "Report сохранен: $report_file"
    cat "$report_file"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  ERNI-KI Let's Encrypt HTTP-01 Challenge Setup"
    echo "  ATTENTION: Требует отключения Cloudflare проксирования!"
    echo "=================================================="
    echo -e "${NC}"

    check_prerequisites
    check_domain_accessibility
    create_backup
    setup_nginx_webroot
    obtain_certificate
    install_certificate
    cleanup_nginx_config
    verify_certificate
    test_https
    generate_report

    echo ""
    success "🎉 Let's Encrypt SSL сертификат (HTTP-01) успешно настроен!"
    echo ""
    log "Следующие шаги:"
    echo "1. Проверьте HTTPS доступ: https://$DOMAIN"
    echo "2. При необходимости включите обратно Cloudflare проксирование"
    echo "3. Настройте automatic renewal"
    echo ""
    log "Резервная копия: $BACKUP_DIR"
    log "Логи установки: $LOG_FILE"
}

# Starting script
main "$@" 2>&1 | tee -a "$LOG_FILE"
