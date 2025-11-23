#!/bin/bash

# ERNI-KI Let's Encrypt SSL Setup with Cloudflare DNS Challenge
# Author: Alteon Schultz (Tech Lead)
# Version: 1.0
# Date: 2025-08-11

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
BACKUP_DIR="$(pwd)/.config-backup/ssl-letsencrypt-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$(pwd)/logs/ssl-setup.log"

# Creating directories for logs
mkdir -p "$(dirname "$LOG_FILE")"

# Check зависимостей
check_dependencies() {
    log "Check зависимостей..."

    # Check Docker
    if ! command -v docker-compose &> /dev/null; then
        error "docker-compose не найден. Установите Docker Compose."
    fi

    # Check curl
    if ! command -v curl &> /dev/null; then
        error "curl не найден. Установите curl."
    fi

    # Check openssl
    if ! command -v openssl &> /dev/null; then
        error "openssl не найден. Установите openssl."
    fi

    # Check директории SSL
    if [ ! -d "$SSL_DIR" ]; then
        error "Directory SSL не найдена: $SSL_DIR"
    fi

    success "Все зависимости найдены"
}

# Check Cloudflare API tokenа
check_cloudflare_credentials() {
    log "Check Cloudflare API tokenа..."

    if [ -z "${CF_Token:-}" ] && [ -z "${CF_Key:-}" ]; then
        error "Cloudflare API token не найден. Установите переменную CF_Token или CF_Key и CF_Email"
    fi

    if [ -n "${CF_Token:-}" ]; then
        log "Используется Cloudflare API Token (рекомендуется)"
        # Test API tokenа
        if ! curl -s -H "Authorization: Bearer $CF_Token" \
             -H "Content-Type: application/json" \
             "https://api.cloudflare.com/client/v4/user/tokens/verify" | grep -q '"success":true'; then
            error "Cloudflare API token недействителен"
        fi
    elif [ -n "${CF_Key:-}" ] && [ -n "${CF_Email:-}" ]; then
        log "Используется Cloudflare Global API Key"
        # Test Global API Key
        if ! curl -s -H "X-Auth-Email: $CF_Email" \
             -H "X-Auth-Key: $CF_Key" \
             -H "Content-Type: application/json" \
             "https://api.cloudflare.com/client/v4/user" | grep -q '"success":true'; then
            error "Cloudflare Global API Key недействителен"
        fi
    else
        error "Неполные данные Cloudflare API. Требуется CF_Token или (CF_Key + CF_Email)"
    fi

    success "Cloudflare API token действителен"
}

# Installation acme.sh
install_acme_sh() {
    log "Installation acme.sh..."

    if [ ! -f "$ACME_HOME/acme.sh" ]; then
        log "Loading и installation acme.sh..."
        curl https://get.acme.sh | sh -s email="$EMAIL"

        # Reload environment variables
        source "$HOME/.bashrc" 2>/dev/null || true

        if [ ! -f "$ACME_HOME/acme.sh" ]; then
            error "Error установки acme.sh"
        fi
    else
        log "acme.sh already installed"
    fi

    # Update acme.sh до послеdays версии
    "$ACME_HOME/acme.sh" --upgrade

    success "acme.sh installed и обновлен"
}

# Creating резервной копии
create_backup() {
    log "Creating резервной копии текущих certificates..."

    mkdir -p "$BACKUP_DIR"

    if [ -f "$SSL_DIR/nginx.crt" ]; then
        cp "$SSL_DIR"/*.crt "$BACKUP_DIR/" 2>/dev/null || true
        cp "$SSL_DIR"/*.key "$BACKUP_DIR/" 2>/dev/null || true
        cp "$SSL_DIR"/*.pem "$BACKUP_DIR/" 2>/dev/null || true
        success "Backup created: $BACKUP_DIR"
    else
        warning "Существующие сертификаты не найдены"
    fi
}

# Obtaining certificate Let's Encrypt
obtain_certificate() {
    log "Obtaining Let's Encrypt certificate for домена: $DOMAIN"

    # Installation Let's Encrypt сервера
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt

    # Obtaining certificate via DNS-01 challenge with Cloudflare API
    if "$ACME_HOME/acme.sh" --issue --dns dns_cf -d "$DOMAIN" --email "$EMAIL" --force; then
        success "Certificate successfully obtained"
    else
        error "Error получения certificate"
    fi
}

# Installation certificate
install_certificate() {
    log "Installation certificate в nginx..."

    # Creating временной директории for новых certificates
    TEMP_SSL_DIR="/tmp/ssl-new-$(date +%s)"
    mkdir -p "$TEMP_SSL_DIR"

    # Installation certificate с правильными путями
    if "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$TEMP_SSL_DIR/nginx.crt" \
        --key-file "$TEMP_SSL_DIR/nginx.key" \
        --fullchain-file "$TEMP_SSL_DIR/nginx-fullchain.crt" \
        --ca-file "$TEMP_SSL_DIR/nginx-ca.crt"; then

        # Копирование certificates в рабочую директорию
        cp "$TEMP_SSL_DIR"/* "$SSL_DIR/"

        # Installation correct access permissions
        chmod 644 "$SSL_DIR"/*.crt
        chmod 600 "$SSL_DIR"/*.key

        # Очистка временной директории
        rm -rf "$TEMP_SSL_DIR"

        success "Certificate installed в nginx"
    else
        rm -rf "$TEMP_SSL_DIR"
        error "Error установки certificate"
    fi
}

# Check certificate
verify_certificate() {
    log "Check installedного certificate..."

    if [ -f "$SSL_DIR/nginx.crt" ]; then
        # Check срока действия
        local expiry_date=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
        log "Certificate действителен до: $expiry_date"

        # Check домена
        local cert_domain=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject | grep -o "CN=[^,]*" | cut -d= -f2)
        if [ "$cert_domain" = "$DOMAIN" ]; then
            success "Certificate выдан for правильного домена: $cert_domain"
        else
            warning "Domain в сертификате ($cert_domain) не соответствует ожидаемому ($DOMAIN)"
        fi

        # Check издателя
        local issuer=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | grep -o "CN=[^,]*" | cut -d= -f2)
        log "Издатель certificate: $issuer"

    else
        error "File certificate не найден: $SSL_DIR/nginx.crt"
    fi
}

# Reload nginx
reload_nginx() {
    log "Reload nginx..."

    # Check конфигурации nginx
    if docker-compose exec -T nginx nginx -t; then
        # Reload nginx
        if docker-compose exec -T nginx nginx -s reload; then
            success "Nginx успешно перезагружен"
        else
            warning "Error перезагрузки nginx, перезапуск контейнера..."
            docker-compose restart nginx
        fi
    else
        error "Error в конфигурации nginx"
    fi
}

# Setup автоматического обновления
setup_auto_renewal() {
    log "Setup автоматического обновления certificates..."

    # Creating hook script for перезагрузки nginx
    local hook_script="$ACME_HOME/nginx-reload-hook.sh"

    cat > "$hook_script" << 'EOF'
#!/bin/bash
# Hook скрипт for перезагрузки nginx после обновления certificate

cd "$(dirname "$0")/../.."

# Logging
echo "$(date): Certificate renewal hook executed" >> logs/ssl-renewal.log

# Reload nginx
if docker-compose exec -T nginx nginx -s reload 2>/dev/null; then
    echo "$(date): Nginx reloaded successfully after certificate renewal" >> logs/ssl-renewal.log
else
    echo "$(date): Failed to reload nginx, restarting container" >> logs/ssl-renewal.log
    docker-compose restart nginx
fi
EOF

    chmod +x "$hook_script"

    # Update acme.sh конфигурации for using hook
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$SSL_DIR/nginx.crt" \
        --key-file "$SSL_DIR/nginx.key" \
        --fullchain-file "$SSL_DIR/nginx-fullchain.crt" \
        --ca-file "$SSL_DIR/nginx-ca.crt" \
        --reloadcmd "$hook_script"

    success "Hook скрипт for автообновления настроен"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  ERNI-KI Let's Encrypt SSL Setup"
    echo "  Cloudflare DNS Challenge"
    echo "=================================================="
    echo -e "${NC}"

    check_dependencies
    check_cloudflare_credentials
    install_acme_sh
    create_backup
    obtain_certificate
    install_certificate
    verify_certificate
    reload_nginx
    setup_auto_renewal

    echo ""
    success "🎉 Let's Encrypt SSL сертификат успешно настроен!"
    echo ""
    log "Следующие шаги:"
    echo "1. Проверьте HTTPS доступ: https://$DOMAIN"
    echo "2. Проверьте SSL рейтинг: https://www.ssllabs.com/ssltest/"
    echo "3. Certificate будет автоматически обновляться каждые 60 days"
    echo ""
    log "Резервная копия старых certificates: $BACKUP_DIR"
    log "Логи установки: $LOG_FILE"
}

# Starting script
main "$@" 2>&1 | tee -a "$LOG_FILE"
