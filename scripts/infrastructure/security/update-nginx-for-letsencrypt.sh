#!/bin/bash

# ERNI-KI Nginx Configuration Update for Let's Encrypt
# Author: Alteon Schultz (Tech Lead)
# Version: 1.0
# Date: 2025-08-11
# Purpose: Update configuration nginx for using Let's Encrypt certificates

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
PROJECT_ROOT="$(pwd)"
NGINX_CONF_DIR="$PROJECT_ROOT/conf/nginx"
NGINX_DEFAULT_CONF="$NGINX_CONF_DIR/conf.d/default.conf"
SSL_DIR="$NGINX_CONF_DIR/ssl"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/nginx-letsencrypt-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$PROJECT_ROOT/logs/nginx-letsencrypt-update.log"

# Creating директорий
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

# Check текущей конфигурации
check_current_config() {
    log "Check текущей конфигурации nginx..."

    if [ ! -f "$NGINX_DEFAULT_CONF" ]; then
        error "File конфигурации nginx не найден: $NGINX_DEFAULT_CONF"
    fi

    # Check SSL настроек
    if grep -q "ssl_certificate.*nginx-fullchain.crt" "$NGINX_DEFAULT_CONF"; then
        success "Configuration уже настроена for Let's Encrypt (fullchain)"
    elif grep -q "ssl_certificate.*nginx.crt" "$NGINX_DEFAULT_CONF"; then
        warning "Configuration использует простой сертификат, требуется обновление"
        return 1
    else
        error "SSL конфигурация не найдена в nginx"
    fi

    # Check OCSP stapling
    if grep -q "ssl_stapling on" "$NGINX_DEFAULT_CONF"; then
        success "OCSP stapling включен"
    else
        warning "OCSP stapling не настроен"
    fi

    return 0
}

# Creating резервной копии
create_backup() {
    log "Creating резервной копии конфигурации nginx..."

    cp -r "$NGINX_CONF_DIR" "$BACKUP_DIR/"
    success "Backup created: $BACKUP_DIR"
}

# Check Let's Encrypt certificates
check_letsencrypt_certificates() {
    log "Check Let's Encrypt certificates..."

    local required_files=(
        "$SSL_DIR/nginx.crt"
        "$SSL_DIR/nginx.key"
        "$SSL_DIR/nginx-fullchain.crt"
        "$SSL_DIR/nginx-ca.crt"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            success "Найден: $(basename "$file")"
        else
            error "Отсутствует: $file"
        fi
    done

    # Check, что сертификат от Let's Encrypt
    if openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer | grep -q "Let's Encrypt"; then
        success "Certificate выдан Let's Encrypt"
    else
        local issuer=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -issuer 2>/dev/null || echo "Unknown")
        warning "Certificate не от Let's Encrypt. Издатель: $issuer"
    fi

    # Check срока действия
    local expiry_date=$(openssl x509 -in "$SSL_DIR/nginx.crt" -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local current_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))

    if [ $days_left -gt 0 ]; then
        success "Certificate действителен еще $days_left days"
    else
        error "Certificate истек $((days_left * -1)) days назад"
    fi
}

# Update configuration nginx
update_nginx_config() {
    log "Update configuration nginx for Let's Encrypt..."

    # Check, нужно ли обновление
    if check_current_config; then
        log "Configuration уже оптимизирована for Let's Encrypt"
        return 0
    fi

    # Update путей к certificateм
    log "Update путей к certificateм..."

    # Замена ssl_certificate на fullchain версию
    sed -i 's|ssl_certificate /etc/nginx/ssl/nginx\.crt;|ssl_certificate /etc/nginx/ssl/nginx-fullchain.crt;|g' "$NGINX_DEFAULT_CONF"

    # Добавление OCSP stapling если отсутствует
    if ! grep -q "ssl_stapling on" "$NGINX_DEFAULT_CONF"; then
        log "Добавление OCSP stapling конфигурации..."

        # Найти строку с ssl_session_tickets и добавить после неё OCSP настройки
        sed -i '/ssl_session_tickets off;/a\\n  # OCSP Stapling for быстрой проверки certificates\n  ssl_stapling on;\n  ssl_stapling_verify on;\n  ssl_trusted_certificate /etc/nginx/ssl/nginx-ca.crt;\n  resolver 1.1.1.1 1.0.0.1 valid=300s;\n  resolver_timeout 5s;' "$NGINX_DEFAULT_CONF"
    fi

    success "Configuration nginx обновлена for Let's Encrypt"
}

# Check конфигурации nginx
test_nginx_config() {
    log "Check конфигурации nginx..."

    if docker-compose exec -T nginx nginx -t; then
        success "Configuration nginx корректна"
        return 0
    else
        error "Error в конфигурации nginx"
        return 1
    fi
}

# Reload nginx
reload_nginx() {
    log "Reload nginx..."

    if docker-compose exec -T nginx nginx -s reload; then
        success "Nginx успешно перезагружен"
    else
        warning "Error перезагрузки nginx, перезапуск контейнера..."
        docker-compose restart nginx

        # Check статуса после перезапуска
        sleep 5
        if docker-compose ps nginx | grep -q "healthy"; then
            success "Nginx контейнер перезапущен и здоров"
        else
            error "Nginx контейнер не запустился корректно"
        fi
    fi
}

# Тестирование HTTPS
test_https_access() {
    log "Тестирование HTTPS доступа..."

    local domain="ki.erni-gruppe.ch"

    # Test локального доступа
    if curl -k -I "https://localhost/" --connect-timeout 5 >/dev/null 2>&1; then
        success "Локальный HTTPS доступ работает"
    else
        warning "Локальный HTTPS доступ недоступен"
    fi

    # Test доступа по домену
    if curl -I "https://$domain/" --connect-timeout 5 >/dev/null 2>&1; then
        success "HTTPS доступ по домену работает"
    else
        warning "HTTPS доступ по домену недоступен (возможно, проблемы с DNS или сертификатом)"
    fi

    # Test SSL соединения
    if echo | openssl s_client -connect "$domain:443" -servername "$domain" >/dev/null 2>&1; then
        success "SSL соединение installedо успешно"
    else
        warning "Проблемы с SSL соединением"
    fi
}

# Check SSL рейтинга
check_ssl_rating() {
    log "Check SSL конфигурации..."

    local domain="ki.erni-gruppe.ch"

    # Check поддерживаемых протоколов
    log "Check поддерживаемых SSL протоколов..."

    if echo | openssl s_client -connect "$domain:443" -tls1_2 >/dev/null 2>&1; then
        success "TLS 1.2 поддерживается"
    else
        warning "TLS 1.2 не поддерживается"
    fi

    if echo | openssl s_client -connect "$domain:443" -tls1_3 >/dev/null 2>&1; then
        success "TLS 1.3 поддерживается"
    else
        warning "TLS 1.3 не поддерживается"
    fi

    # Check HSTS заголовка
    if curl -k -I "https://$domain/" 2>/dev/null | grep -q "Strict-Transport-Security"; then
        success "HSTS заголовок настроен"
    else
        warning "HSTS заголовок отсутствует"
    fi
}

# Generation отчета
generate_report() {
    log "Generation отчета обновления nginx..."

    local report_file="$PROJECT_ROOT/logs/nginx-letsencrypt-update-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "ERNI-KI Nginx Let's Encrypt Update Report"
        echo "Generated: $(date)"
        echo "=========================================="
        echo ""

        echo "Configuration Files:"
        echo "- Nginx config: $NGINX_DEFAULT_CONF"
        echo "- SSL directory: $SSL_DIR"
        echo "- Backup: $BACKUP_DIR"
        echo ""

        echo "Certificate Information:"
        if [ -f "$SSL_DIR/nginx.crt" ]; then
            openssl x509 -in "$SSL_DIR/nginx.crt" -noout -subject -issuer -dates 2>/dev/null || echo "Error reading certificate"
        else
            echo "Certificate not found"
        fi
        echo ""

        echo "Nginx Configuration Check:"
        docker-compose exec -T nginx nginx -t 2>&1 || echo "Configuration test failed"
        echo ""

        echo "Container Status:"
        docker-compose ps nginx || echo "Container status check failed"
        echo ""

        echo "Next Steps:"
        echo "1. Test HTTPS access: https://ki.erni-gruppe.ch/"
        echo "2. Check SSL rating: https://www.ssllabs.com/ssltest/"
        echo "3. Monitor certificate expiry"
        echo ""

    } > "$report_file"

    success "Report сохранен: $report_file"
    cat "$report_file"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  ERNI-KI Nginx Let's Encrypt Configuration"
    echo "  Update for валидных SSL certificates"
    echo "=================================================="
    echo -e "${NC}"

    create_backup
    check_letsencrypt_certificates
    update_nginx_config

    if test_nginx_config; then
        reload_nginx
        test_https_access
        check_ssl_rating
        generate_report

        echo ""
        success "🎉 Nginx успешно настроен for Let's Encrypt!"
        echo ""
        log "Следующие шаги:"
        echo "1. Проверьте HTTPS доступ: https://ki.erni-gruppe.ch/"
        echo "2. Проверьте SSL рейтинг: https://www.ssllabs.com/ssltest/"
        echo "3. Настройте мониторинг certificates"
        echo ""
        log "Резервная копия: $BACKUP_DIR"
    else
        error "Error в конфигурации nginx. Check logs и восстановите из резервной копии when необходимости."
    fi
}

# Starting script
main "$@" 2>&1 | tee -a "$LOG_FILE"
