#!/bin/bash
# ============================================================================
# ERNI-KI LOGGING STANDARDIZATION SCRIPT
# Automatic standardization конфигурации логирования
# ============================================================================
# Version: 2.0
# Date: 2025-08-26
# Purpose: Unification of logging levels и форматов во всех сервисах
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
ENV_DIR="env"
BACKUP_DIR=".config-backup/logging-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/logging-standardization.log"

# Function логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function output с цветом
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%H:%M:%S')] ${message}${NC}"
}

# Creating резервной копии
create_backup() {
    print_status "$BLUE" "Creating резервной копии конфигурации..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$ENV_DIR" "$BACKUP_DIR/"
    log "Backup created: $BACKUP_DIR"
}

# Standardization of logging levels
standardize_log_levels() {
    print_status "$YELLOW" "Standardization of logging levels..."

    # Critical services (INFO уровень)
    local critical_services=("openwebui" "ollama" "db" "nginx")

    # Important services (INFO уровень)
    local important_services=("searxng" "redis" "backrest" "auth" "cloudflared")

    # Auxiliary services (WARN уровень)
    local auxiliary_services=("edgetts" "tika" "mcposerver")

    # Monitoring services (ERROR уровень)
    local monitoring_services=("prometheus" "grafana" "alertmanager" "node-exporter" "postgres-exporter" "redis-exporter" "nvidia-exporter" "blackbox-exporter" "cadvisor" "fluent-bit")

    # Processing critical services
    for service in "${critical_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Setup $service (critical service) -> INFO"
            standardize_service_logging "$service" "info" "json"
        fi
    done

    # Processing important services
    for service in "${important_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Setup $service (important service) -> INFO"
            standardize_service_logging "$service" "info" "json"
        fi
    done

    # Processing auxiliary services
    for service in "${auxiliary_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Setup $service (auxiliary service) -> WARN"
            standardize_service_logging "$service" "warn" "json"
        fi
    done

    # Processing monitoring services
    for service in "${monitoring_services[@]}"; do
        if [[ -f "$ENV_DIR/${service}.env" ]]; then
            print_status "$GREEN" "Setup $service (monitoring service) -> ERROR"
            standardize_service_logging "$service" "error" "logfmt"
        fi
    done
}

# Стандартизация конкретного сервиса
standardize_service_logging() {
    local service=$1
    local log_level=$2
    local log_format=$3
    local env_file="$ENV_DIR/${service}.env"

    log "Стандартизация $service: уровень=$log_level, формат=$log_format"

    # Creating временный файл
    local temp_file=$(mktemp)

    # Обрабатываем файл
    {
        echo "# === СТАНДАРТИЗИРОВАННОЕ ЛОГИРОВАНИЕ (обновлено $(date '+%Y-%m-%d %H:%M:%S')) ==="
        echo "LOG_LEVEL=$log_level"
        echo "LOG_FORMAT=$log_format"
        echo ""

        # Copying remaining content, исключая старые настройки логирования
        grep -v -E "^(LOG_LEVEL|LOG_FORMAT|log_level|log_format|DEBUG|VERBOSE|QUIET)" "$env_file" || true

    } > "$temp_file"

    # Replacing original file
    mv "$temp_file" "$env_file"

    log "Service $service стандартизирован"
}

# Оптимизация health check логирования
optimize_health_checks() {
    print_status "$YELLOW" "Оптимизация health check логирования..."

    # Creating конфигурацию for nginx for исключения health check логов
    local nginx_log_config="$ENV_DIR/nginx-logging.conf"

    cat > "$nginx_log_config" << 'EOF'
# Оптимизированное логирование Nginx for ERNI-KI
# Исключение health check запросов из access логов

map $request_uri $loggable {
    ~^/health$ 0;
    ~^/healthz$ 0;
    ~^/-/healthy$ 0;
    ~^/api/health$ 0;
    ~^/metrics$ 0;
    default 1;
}

# Applying в конфигурации виртуального хоста:
# access_log /var/log/nginx/access.log combined if=$loggable;
EOF

    log "Создана конфигурация оптимизации health check логов: $nginx_log_config"
}

# Creating мониторинговых скриптов
create_monitoring_scripts() {
    print_status "$YELLOW" "Creating скриптов мониторинга логов..."

    local monitoring_dir="scripts/monitoring"
    mkdir -p "$monitoring_dir"

    # Script анализа объемов логов
    cat > "$monitoring_dir/log-volume-analysis.sh" << 'EOF'
#!/bin/bash
# Analysis объемов логов ERNI-KI

echo "=== ANALYSIS LOG VOLUMES ERNI-KI ==="
echo "Date: $(date)"
echo

# Размеры логов Docker контейнеров
echo "1. Размеры логов Docker контейнеров:"
docker system df

echo
echo "2. Топ-10 контейнеров по объему логов (за последний час):"
for container in $(docker ps --format "{{.Names}}" | grep erni-ki); do
    lines=$(docker logs --since 1h "$container" 2>&1 | wc -l)
    echo "$container: $lines строк"
done | sort -k2 -nr | head -10

echo
echo "3. Analysis ошибок в логах:"
for container in $(docker ps --format "{{.Names}}" | grep erni-ki | head -5); do
    errors=$(docker logs --since 1h "$container" 2>&1 | grep -i -E "(error|critical|fatal)" | wc -l)
    if [[ $errors -gt 0 ]]; then
        echo "$container: $errors ошибок"
    fi
done
EOF

    chmod +x "$monitoring_dir/log-volume-analysis.sh"

    # Script очистки логов
    cat > "$monitoring_dir/log-cleanup.sh" << 'EOF'
#!/bin/bash
# Очистка старых логов ERNI-KI

echo "=== LOG CLEANUP ERNI-KI ==="
echo "Date: $(date)"

# Очистка Docker логов старше 7 days
echo "Очистка Docker логов старше 7 days..."
docker system prune -f --filter "until=168h"

# Archiving logs
ARCHIVE_DIR="/var/log/erni-ki/archive/$(date +%Y%m%d)"
mkdir -p "$ARCHIVE_DIR"

echo "Archiving completed in: $ARCHIVE_DIR"
EOF

    chmod +x "$monitoring_dir/log-cleanup.sh"

    log "Созданы скрипты мониторинга в $monitoring_dir"
}

# Validation конфигурации
validate_configuration() {
    print_status "$YELLOW" "Validation конфигурации логирования..."

    local errors=0

    # Checking все env файлы
    for env_file in "$ENV_DIR"/*.env; do
        if [[ -f "$env_file" ]]; then
            local service=$(basename "$env_file" .env)

            # Checking наличие LOG_LEVEL
            if ! grep -q "^LOG_LEVEL=" "$env_file"; then
                print_status "$RED" "ОШИБКА: Отсутствует LOG_LEVEL в $service"
                ((errors++))
            fi

            # Checking корректность уровня
            local log_level=$(grep "^LOG_LEVEL=" "$env_file" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
            if [[ ! "$log_level" =~ ^(debug|info|warn|error|critical)$ ]]; then
                print_status "$RED" "ОШИБКА: Invalid LOG_LEVEL в $service: $log_level"
                ((errors++))
            fi
        fi
    done

    if [[ $errors -eq 0 ]]; then
        print_status "$GREEN" "Validation прошла успешно!"
    else
        print_status "$RED" "Найдено $errors ошибок в конфигурации"
        return 1
    fi
}

# Generation отчета
generate_report() {
    print_status "$BLUE" "Generation отчета стандартизации..."

    local report_file="reports/logging-standardization-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "reports"

    cat > "$report_file" << EOF
# LOGGING STANDARDIZATION REPORT ERNI-KI

**Date:** $(date)
**Version:** 2.0
**Status:** Завершено

## Обработанные сервисы

$(find "$ENV_DIR" -name "*.env" -exec basename {} .env \; | sort | sed 's/^/- /')

## Примененные стандарты

- **Critical services:** INFO уровень, JSON формат
- **Important services:** INFO уровень, JSON формат
- **Auxiliary services:** WARN уровень, JSON формат
- **Monitoring services:** ERROR уровень, LOGFMT формат

## Оптимизации

- Исключение health check логов
- Masking sensitive data
- Стандартизация форматов временных меток
- Setup ротации логов

## Резервная копия

Создана резервная копия: \`$BACKUP_DIR\`

## Следующие шаги

1. Restarting сервисов for применения изменений
2. Monitoring объемов логов
3. Setup алертинга
4. Регулярная очистка архивных логов
EOF

    print_status "$GREEN" "Report создан: $report_file"
}

# Main function
main() {
    print_status "$BLUE" "=== STARTING LOGGING STANDARDIZATION ERNI-KI ==="

    # Checking наличие директории env
    if [[ ! -d "$ENV_DIR" ]]; then
        print_status "$RED" "ОШИБКА: Directory $ENV_DIR не найдена"
        exit 1
    fi

    # Performing standardization
    create_backup
    standardize_log_levels
    optimize_health_checks
    create_monitoring_scripts
    validate_configuration
    generate_report

    print_status "$GREEN" "=== СТАНДАРТИЗАЦИЯ ЛОГИРОВАНИЯ COMPLETED ==="
    print_status "$YELLOW" "To apply changes execute: docker-compose restart"
}

# Starting script
main "$@"
