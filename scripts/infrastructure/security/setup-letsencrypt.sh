#!/bin/bash

# ERNI-KI Let's Encrypt SSL Setup Script
# Setup SSL certificates Let's Encrypt for домена ki.erni-gruppe.ch
# Использует acme.sh с DNS-01 challenge via Cloudflare API

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
EMAIL="admin@gmail.com"
ACME_HOME="$HOME/.acme.sh"
SSL_DIR="$(pwd)/conf/nginx/ssl"
BACKUP_DIR="$(pwd)/.config-backup/ssl-letsencrypt-$(date +%Y%m%d-%H%M%S)"

# Check зависимостей
check_dependencies() {
    log "Check зависимостей..."

    if [ ! -f "$ACME_HOME/acme.sh" ]; then
        error "acme.sh не найден. Установите его сначала: curl https://get.acme.sh | sh"
    fi

    if [ ! -d "$SSL_DIR" ]; then
        error "Directory SSL не найдена: $SSL_DIR"
    fi

    success "Все зависимости найдены"
}

# Check environment variables Cyon
check_cyon_credentials() {
    log "Check Cyon API credentials..."

    if [ -z "${CY_Username:-}" ] || [ -z "${CY_Password:-}" ]; then
        error "Не найдены Cyon API credentials. Установите переменные:
        - CY_Username: Логин от my.cyon.ch (например: kontakt@erni-gruppe.ch)
        - CY_Password: Пароль от my.cyon.ch
        - CY_OTP_Secret: (опционально) OTP token for 2FA"
    fi

    log "Используется Cyon DNS API"
    export CY_Username="$CY_Username"
    export CY_Password="$CY_Password"

    if [ -n "${CY_OTP_Secret:-}" ]; then
        log "2FA включена"
        export CY_OTP_Secret="$CY_OTP_Secret"
    fi

    success "Cyon credentials настроены"
}

# Creating резервной копии
create_backup() {
    log "Creating резервной копии текущих certificates..."

    mkdir -p "$BACKUP_DIR"

    if [ -f "$SSL_DIR/nginx.crt" ]; then
        cp "$SSL_DIR/nginx.crt" "$BACKUP_DIR/"
        cp "$SSL_DIR/nginx.key" "$BACKUP_DIR/"
        log "Backup created в: $BACKUP_DIR"
    else
        warning "Текущие сертификаты не найдены"
    fi
}

# Obtaining certificate Let's Encrypt
obtain_certificate() {
    log "Obtaining Let's Encrypt certificate for домена: $DOMAIN"

    # Installation Let's Encrypt сервера
    "$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt

    # Obtaining certificate via DNS-01 challenge с Cyon API
    if "$ACME_HOME/acme.sh" --issue --dns dns_cyon -d "$DOMAIN" --email "$EMAIL" --force; then
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

    # Копирование certificates из acme.sh
    if "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$TEMP_SSL_DIR/nginx.crt" \
        --key-file "$TEMP_SSL_DIR/nginx.key" \
        --fullchain-file "$TEMP_SSL_DIR/nginx-fullchain.crt" \
        --ca-file "$TEMP_SSL_DIR/nginx-ca.crt"; then

        # Check валидности certificates
        if openssl x509 -in "$TEMP_SSL_DIR/nginx.crt" -noout -text >/dev/null 2>&1; then
            # Замена старых certificates
            cp "$TEMP_SSL_DIR/nginx.crt" "$SSL_DIR/"
            cp "$TEMP_SSL_DIR/nginx.key" "$SSL_DIR/"
            cp "$TEMP_SSL_DIR/nginx-fullchain.crt" "$SSL_DIR/"
            cp "$TEMP_SSL_DIR/nginx-ca.crt" "$SSL_DIR/"

            # Installation correct access permissions
            chmod 644 "$SSL_DIR/nginx.crt" "$SSL_DIR/nginx-fullchain.crt" "$SSL_DIR/nginx-ca.crt"
            chmod 600 "$SSL_DIR/nginx.key"

            success "Certificates installedы в: $SSL_DIR"
        else
            error "Полученный сертификат невалиден"
        fi
    else
        error "Error установки certificate"
    fi

    # Очистка временной директории
    rm -rf "$TEMP_SSL_DIR"
}

# Check certificate
verify_certificate() {
    log "Check installedного certificate..."

    if openssl x509 -in "$SSL_DIR/nginx.crt" -text -noout | grep -q "Let's Encrypt"; then
        success "Certificate Let's Encrypt успешно installed"

        # Показать информацию о сертификате
        echo ""
        log "Info о сертификате:"
        openssl x509 -in "$SSL_DIR/nginx.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before|Not After)"
        echo ""
    else
        error "Certificate не является сертификатом Let's Encrypt"
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
            docker compose restart nginx
        fi
    else
        error "Error в конфигурации nginx"
    fi
}

# Setup автообновления
setup_auto_renewal() {
    log "Setup автообновления certificates..."

    # acme.sh автоматически создает cron job when установке
    # Проверим, что он существует
    if crontab -l 2>/dev/null | grep -q "acme.sh"; then
        success "Auto-renewal уже configured via cron"
    else
        warning "Cron job for автообновления не найден"
        log "Creating cron job for автообновления..."

        # Добавление cron job
        (crontab -l 2>/dev/null; echo "0 2 * * * $ACME_HOME/acme.sh --cron --home $ACME_HOME > /dev/null") | crontab -
        success "Cron job for автообновления создан"
    fi

    # Creating hook script for перезагрузки nginx
    HOOK_SCRIPT="$ACME_HOME/reload-nginx-hook.sh"
    cat > "$HOOK_SCRIPT" << 'EOF'
#!/bin/bash
# Hook script for перезагрузки nginx после обновления certificate

ERNI_KI_DIR="/home/konstantin/Documents/augment-projects/erni-ki"
cd "$ERNI_KI_DIR"

# Reload nginx
if docker compose exec nginx nginx -s reload 2>/dev/null; then
    echo "$(date): Nginx reloaded successfully after certificate renewal"
else
    echo "$(date): Failed to reload nginx, restarting container"
    docker compose restart nginx
fi
EOF

    chmod +x "$HOOK_SCRIPT"

    # Update acme.sh конфигурации for using hook
    "$ACME_HOME/acme.sh" --install-cert -d "$DOMAIN" \
        --cert-file "$SSL_DIR/nginx.crt" \
        --key-file "$SSL_DIR/nginx.key" \
        --fullchain-file "$SSL_DIR/nginx-fullchain.crt" \
        --reloadcmd "$HOOK_SCRIPT"

    success "Hook скрипт for автообновления настроен"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "=============================================="
    echo "  ERNI-KI Let's Encrypt SSL Setup"
    echo "  Domain: $DOMAIN"
    echo "=============================================="
    echo -e "${NC}"

    # Check, что мы в корне проекта
    if [ ! -f "compose.yml" ] && [ ! -f "compose.yml.example" ]; then
        error "Script должен запускаться из корня проекта ERNI-KI"
    fi

    check_dependencies
    check_cyon_credentials
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
}

# Starting script
main "$@"
