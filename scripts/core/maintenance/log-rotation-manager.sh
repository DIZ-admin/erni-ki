#!/bin/bash
# ERNI-KI log rotation management script
# Automatic log archiving and cleanup with storage in .config-backup/logs/

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/logs"
DOCKER_LOGS_DIR="/var/lib/docker/containers"
NGINX_LOGS_DIR="/var/log/nginx"
RETENTION_DAYS=7
ARCHIVE_RETENTION_WEEKS=4
MAX_LOG_SIZE="100M"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Create directory structure for archiving
create_backup_structure() {
    log "Создание структуры директорий для архивации логов..."

    local dirs=(
        "$BACKUP_DIR"
        "$BACKUP_DIR/daily"
        "$BACKUP_DIR/weekly"
        "$BACKUP_DIR/critical"
        "$BACKUP_DIR/services"
        "$BACKUP_DIR/nginx"
        "$BACKUP_DIR/docker"
        "$BACKUP_DIR/system"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            success "Создана директория: $dir"
        fi
    done
}

# Rotate Docker container logs
rotate_docker_logs() {
    log "Ротация логов Docker контейнеров..."

    local date_suffix=$(date +%Y%m%d_%H%M%S)
    local services=("auth" "db" "redis" "ollama" "nginx" "openwebui" "searxng" "edgetts" "tika" "mcposerver" "cloudflared" "watchtower" "backrest")

    for service in "${services[@]}"; do
        log "Обработка логов сервиса: $service"

        # Get container ID
        local container_id=$(docker-compose ps -q "$service" 2>/dev/null || echo "")

        if [[ -n "$container_id" ]]; then
            # Export container logs
            local log_file="$BACKUP_DIR/services/${service}_${date_suffix}.log"

            if docker logs "$container_id" --since="24h" > "$log_file" 2>&1; then
                # Compress log
                gzip "$log_file"
                success "Архивирован лог сервиса $service: ${log_file}.gz"

                # Clean old container logs (keep last 100MB)
                docker logs "$container_id" --tail=1000 > /tmp/temp_log_$service 2>&1 || true

            else
                warning "Не удалось экспортировать логи сервиса $service"
            fi
        else
            warning "Контейнер $service не найден или не запущен"
        fi
    done
}

# Rotate Nginx logs
rotate_nginx_logs() {
    log "Ротация логов Nginx..."

    local date_suffix=$(date +%Y%m%d_%H%M%S)

    # Archive access.log
    if [[ -f "$NGINX_LOGS_DIR/access.log" ]]; then
        local access_backup="$BACKUP_DIR/nginx/access_${date_suffix}.log"
        cp "$NGINX_LOGS_DIR/access.log" "$access_backup"
        gzip "$access_backup"

        # Clear current log
        > "$NGINX_LOGS_DIR/access.log"
        success "Архивирован Nginx access.log"
    fi

    # Archive error.log
    if [[ -f "$NGINX_LOGS_DIR/error.log" ]]; then
        local error_backup="$BACKUP_DIR/nginx/error_${date_suffix}.log"
        cp "$NGINX_LOGS_DIR/error.log" "$error_backup"
        gzip "$error_backup"

        # Clear current log
        > "$NGINX_LOGS_DIR/error.log"
        success "Архивирован Nginx error.log"
    fi

    # Reload Nginx to apply changes
    if docker-compose exec nginx nginx -s reload 2>/dev/null; then
        success "Nginx перезагружен для применения ротации логов"
    else
        warning "Не удалось перезагрузить Nginx"
    fi
}

# Archive critical logs
archive_critical_logs() {
    log "Архивация критических логов..."

    local date_suffix=$(date +%Y%m%d_%H%M%S)
    local critical_log="$BACKUP_DIR/critical/critical_errors_${date_suffix}.log"

    # Search for critical errors in all service logs
    {
        echo "=== КРИТИЧЕСКИЕ ОШИБКИ ERNI-KI ==="
        echo "Дата архивации: $(date)"
        echo "Период: последние 24 часа"
        echo ""

        # Search in Docker logs
        docker-compose logs --since=24h 2>/dev/null | grep -i -E "(error|fatal|critical|exception|panic|segfault)" | head -1000

        echo ""
        echo "=== NGINX ОШИБКИ ==="
        if [[ -f "$NGINX_LOGS_DIR/error.log" ]]; then
            tail -1000 "$NGINX_LOGS_DIR/error.log" | grep -i -E "(error|crit|alert|emerg)"
        fi

    } > "$critical_log"

    # Compress critical logs
    gzip "$critical_log"
    success "Архивированы критические логи: ${critical_log}.gz"
}

# Create daily archive
create_daily_archive() {
    log "Создание ежедневного архива логов..."

    local date_suffix=$(date +%Y%m%d)
    local daily_archive="$BACKUP_DIR/daily/erni-ki-logs-${date_suffix}.tar.gz"

    # Create archive of all logs for the day
    tar -czf "$daily_archive" \
        -C "$BACKUP_DIR" \
        --exclude="daily" \
        --exclude="weekly" \
        services/ nginx/ critical/ docker/ system/ 2>/dev/null || true

    if [[ -f "$daily_archive" ]]; then
        local archive_size=$(du -h "$daily_archive" | cut -f1)
        success "Создан ежедневный архив: $daily_archive ($archive_size)"
    else
        error "Не удалось создать ежедневный архив"
    fi
}

# Create weekly archive
create_weekly_archive() {
    log "Создание еженедельного архива логов..."

    # Check if today is Sunday (day of week 0)
    if [[ $(date +%w) -eq 0 ]]; then
        local week_suffix=$(date +%Y_week_%U)
        local weekly_archive="$BACKUP_DIR/weekly/erni-ki-logs-${week_suffix}.tar.gz"

        # Create archive of all daily archives for the week
        tar -czf "$weekly_archive" \
            -C "$BACKUP_DIR/daily" \
            . 2>/dev/null || true

        if [[ -f "$weekly_archive" ]]; then
            local archive_size=$(du -h "$weekly_archive" | cut -f1)
            success "Создан еженедельный архив: $weekly_archive ($archive_size)"
        else
            warning "Не удалось создать еженедельный архив"
        fi
    else
        log "Еженедельный архив создается только по воскресеньям"
    fi
}

# Clean up old archives
cleanup_old_archives() {
    log "Очистка старых архивов..."

    # Delete daily archives older than RETENTION_DAYS days
    find "$BACKUP_DIR/daily" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Delete weekly archives older than ARCHIVE_RETENTION_WEEKS weeks
    local weeks_in_days=$((ARCHIVE_RETENTION_WEEKS * 7))
    find "$BACKUP_DIR/weekly" -name "*.tar.gz" -mtime +$weeks_in_days -delete 2>/dev/null || true

    # Delete old service logs
    find "$BACKUP_DIR/services" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_DIR/nginx" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_DIR/critical" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    success "Очистка старых архивов завершена"
}

# Monitor log sizes
monitor_log_sizes() {
    log "Мониторинг размера логов..."

    # Check log directory size
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
    log "Общий размер архивов логов: $total_size"

    # Check Docker logs size
    local docker_logs_size=$(du -sh /var/lib/docker/containers 2>/dev/null | cut -f1 || echo "0")
    log "Размер логов Docker: $docker_logs_size"

    # Warning about large logs
    local large_logs=$(find /var/lib/docker/containers -name "*.log" -size +$MAX_LOG_SIZE 2>/dev/null || true)
    if [[ -n "$large_logs" ]]; then
        warning "Обнаружены большие лог-файлы Docker:"
        echo "$large_logs" | while read -r log_file; do
            local size=$(du -h "$log_file" | cut -f1)
            warning "  $log_file ($size)"
        done
    fi
}

# Generate rotation report
generate_rotation_report() {
    log "Генерация отчета о ротации логов..."

    local report_file="$BACKUP_DIR/rotation_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=== ОТЧЕТ О РОТАЦИИ ЛОГОВ ERNI-KI ==="
        echo "Дата: $(date)"
        echo "Хост: $(hostname)"
        echo ""

        echo "=== СТАТИСТИКА АРХИВОВ ==="
        echo "Общий размер архивов: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")"
        echo "Количество ежедневных архивов: $(find "$BACKUP_DIR/daily" -name "*.tar.gz" 2>/dev/null | wc -l)"
        echo "Количество еженедельных архивов: $(find "$BACKUP_DIR/weekly" -name "*.tar.gz" 2>/dev/null | wc -l)"
        echo ""

        echo "=== ПОСЛЕДНИЕ АРХИВЫ ==="
        echo "Ежедневные архивы:"
        ls -lah "$BACKUP_DIR/daily" 2>/dev/null | tail -5 || echo "Нет архивов"
        echo ""
        echo "Еженедельные архивы:"
        ls -lah "$BACKUP_DIR/weekly" 2>/dev/null | tail -3 || echo "Нет архивов"
        echo ""

        echo "=== СТАТУС СЕРВИСОВ ==="
        docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" 2>/dev/null || echo "Docker Compose недоступен"

    } > "$report_file"

    success "Отчет сохранен: $report_file"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ERNI-KI Log Rotation                     ║"
    echo "║                  Управление ротацией логов                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Check access permissions
    if [[ $EUID -ne 0 ]] && [[ ! -w "$NGINX_LOGS_DIR" ]]; then
        warning "Для полной ротации логов требуются права root"
        warning "Некоторые операции могут быть недоступны"
    fi

    # Execute rotation
    create_backup_structure
    echo ""

    rotate_docker_logs
    echo ""

    if [[ -w "$NGINX_LOGS_DIR" ]]; then
        rotate_nginx_logs
    else
        warning "Нет доступа к логам Nginx, пропускаем ротацию"
    fi
    echo ""

    archive_critical_logs
    echo ""

    create_daily_archive
    echo ""

    create_weekly_archive
    echo ""

    cleanup_old_archives
    echo ""

    monitor_log_sizes
    echo ""

    generate_rotation_report
    echo ""

    success "Ротация логов завершена успешно!"
}

# Command line argument handling
case "${1:-}" in
    --daily)
        log "Запуск ежедневной ротации логов"
        main
        ;;
    --weekly)
        log "Запуск еженедельной ротации логов"
        create_backup_structure
        create_weekly_archive
        cleanup_old_archives
        ;;
    --cleanup)
        log "Запуск очистки старых архивов"
        cleanup_old_archives
        ;;
    --report)
        log "Генерация отчета о логах"
        generate_rotation_report
        ;;
    --monitor)
        log "Мониторинг размера логов"
        monitor_log_sizes
        ;;
    *)
        main
        ;;
esac
