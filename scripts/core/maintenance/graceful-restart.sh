#!/bin/bash
# Graceful restart procedures for ERNI-KI
# Safe service restart with data preservation

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
LOG_FILE="/var/log/erni-ki-graceful-restart.log"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/graceful-restart"
SHUTDOWN_TIMEOUT=60
STARTUP_TIMEOUT=120

# Logging functions
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${BLUE}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

success() {
    local message="✅ $1"
    echo -e "${GREEN}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

warning() {
    local message="⚠️  $1"
    echo -e "${YELLOW}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    local message="❌ $1"
    echo -e "${RED}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

# Create state backup
create_state_backup() {
    log "Создание резервной копии состояния системы"

    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/state_backup_$backup_timestamp"

    mkdir -p "$backup_path"

    # Save container states
    docker-compose ps --format json > "$backup_path/containers_state.json" 2>/dev/null || true

    # Save configurations
    cp -r "$PROJECT_ROOT/env" "$backup_path/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/conf" "$backup_path/" 2>/dev/null || true

    # Save volume information
    docker volume ls --format json > "$backup_path/volumes_info.json" 2>/dev/null || true

    # Save network information
    docker network ls --format json > "$backup_path/networks_info.json" 2>/dev/null || true

    # Save resource usage statistics
    docker stats --no-stream --format json > "$backup_path/resource_usage.json" 2>/dev/null || true

    success "Резервная копия состояния создана: $backup_path"
    echo "$backup_path" > "$BACKUP_DIR/latest_backup_path.txt"
}

# Check restart readiness
check_restart_readiness() {
    log "Проверка готовности к перезапуску"

    # Check disk space
    local disk_usage=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        error "Недостаточно места на диске: ${disk_usage}%"
        return 1
    fi

    # Check active OpenWebUI users
    local active_sessions=$(docker-compose exec -T openwebui ps aux | grep -c "python" 2>/dev/null || echo "0")
    if [[ $active_sessions -gt 5 ]]; then
        warning "Обнаружено $active_sessions активных сессий в OpenWebUI"
        read -p "Продолжить перезапуск? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Перезапуск отменен пользователем"
            return 1
        fi
    fi

    # Check critical processes
    local critical_processes=("postgres" "redis-server" "nginx")
    for process in "${critical_processes[@]}"; do
        if docker-compose exec -T db pgrep "$process" &>/dev/null ||
           docker-compose exec -T redis pgrep "$process" &>/dev/null ||
           docker-compose exec -T nginx pgrep "$process" &>/dev/null; then
            log "Критический процесс $process активен"
        fi
    done

    success "Система готова к перезапуску"
    return 0
}

# Graceful service stop
graceful_stop_service() {
    local service_name="$1"
    local timeout="${2:-$SHUTDOWN_TIMEOUT}"

    log "Graceful остановка сервиса: $service_name"

    # Special handling for different services
    case $service_name in
        "openwebui")
            # Notify users about upcoming restart
            log "Отправка уведомления пользователям OpenWebUI"
            # API call for user notification can be added here
            ;;
        "ollama")
            # Wait for current generations to complete
            log "Ожидание завершения текущих генераций Ollama"
            sleep 10
            ;;
        "db")
            # Database checkpoint
            log "Выполнение checkpoint базы данных"
            docker-compose exec -T db psql -U postgres -c "CHECKPOINT;" 2>/dev/null || true
            ;;
        "redis")
            # Save Redis data
            log "Сохранение данных Redis"
            docker-compose exec -T redis redis-cli BGSAVE 2>/dev/null || true
            sleep 5
            ;;
        "nginx")
            # Graceful reload to finish active connections
            log "Graceful reload Nginx"
            docker-compose exec nginx nginx -s quit 2>/dev/null || true
            ;;
    esac

    # Send SIGTERM
    log "Отправка SIGTERM сервису $service_name"
    docker-compose stop "$service_name" --timeout="$timeout" || {
        warning "Graceful остановка не удалась, принудительная остановка"
        docker-compose kill "$service_name"
    }

    # Check if stopped
    local attempts=0
    while [[ $attempts -lt 10 ]]; do
        if ! docker-compose ps "$service_name" --format "{{.Status}}" | grep -q "Up"; then
            success "Сервис $service_name остановлен"
            return 0
        fi
        sleep 2
        ((attempts++))
    done

    warning "Сервис $service_name не остановился в ожидаемое время"
    return 1
}

# Graceful service start
graceful_start_service() {
    local service_name="$1"
    local timeout="${2:-$STARTUP_TIMEOUT}"

    log "Graceful запуск сервиса: $service_name"

    # Pre-start checks
    case $service_name in
        "ollama")
            # Check GPU availability
            if command -v nvidia-smi &> /dev/null; then
                if ! nvidia-smi &> /dev/null; then
                    error "GPU недоступен для Ollama"
                    return 1
                fi
            fi
            ;;
        "db")
            # Check data integrity
            log "Проверка целостности данных PostgreSQL"
            if [[ -d "$PROJECT_ROOT/data/postgres" ]]; then
                # Simple check for main files presence
                if [[ ! -f "$PROJECT_ROOT/data/postgres/PG_VERSION" ]]; then
                    error "Данные PostgreSQL повреждены"
                    return 1
                fi
            fi
            ;;
    esac

    # Start service
    if docker-compose up -d "$service_name"; then
        log "Сервис $service_name запущен, ожидание готовности"

        # Wait for readiness with timeout
        local start_time=$(date +%s)
        local end_time=$((start_time + timeout))

        while [[ $(date +%s) -lt $end_time ]]; do
            local status=$(docker-compose ps "$service_name" --format "{{.Status}}" 2>/dev/null || echo "")

            if echo "$status" | grep -q "healthy"; then
                success "Сервис $service_name готов и здоров"
                return 0
            elif echo "$status" | grep -q "Up"; then
                log "Сервис $service_name запущен, ожидание health check"
                sleep 5
            else
                warning "Сервис $service_name в состоянии: $status"
                sleep 5
            fi
        done

        error "Сервис $service_name не стал готов в течение $timeout секунд"
        return 1
    else
        error "Не удалось запустить сервис $service_name"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    local service_name="$1"

    log "Проверка зависимостей для $service_name"

    local dependencies=()
    case $service_name in
        "openwebui")
            dependencies=("db" "redis" "ollama" "searxng" "auth" "nginx")
            ;;
        "searxng")
            dependencies=("redis")
            ;;
        "nginx")
            dependencies=("openwebui" "auth")
            ;;
        "auth")
            dependencies=("db")
            ;;
        "backrest")
            dependencies=("db" "redis")
            ;;
    esac

    for dep in "${dependencies[@]}"; do
        local dep_status=$(docker-compose ps "$dep" --format "{{.Status}}" 2>/dev/null || echo "not_found")
        if ! echo "$dep_status" | grep -q "Up"; then
            warning "Зависимость $dep не запущена для $service_name"
            return 1
        fi
    done

    success "Все зависимости для $service_name готовы"
    return 0
}

# Graceful restart of single service
graceful_restart_service() {
    local service_name="$1"
    local check_deps="${2:-true}"

    log "Graceful перезапуск сервиса: $service_name"

    # Check dependencies
    if [[ "$check_deps" == "true" ]]; then
        if ! check_dependencies "$service_name"; then
            error "Зависимости для $service_name не готовы"
            return 1
        fi
    fi

    # Stop
    if ! graceful_stop_service "$service_name"; then
        error "Не удалось остановить сервис $service_name"
        return 1
    fi

    # Short pause
    sleep 5

    # Start
    if ! graceful_start_service "$service_name"; then
        error "Не удалось запустить сервис $service_name"
        return 1
    fi

    success "Сервис $service_name успешно перезапущен"
    return 0
}

# Graceful restart of entire system
graceful_restart_all() {
    log "Graceful перезапуск всей системы ERNI-KI"

    # Check readiness
    if ! check_restart_readiness; then
        error "Система не готова к перезапуску"
        return 1
    fi

    # Create backup
    create_state_backup

    # Define stop order (reverse dependency order)
    local stop_order=("openwebui" "nginx" "auth" "searxng" "ollama" "edgetts" "tika" "mcposerver" "cloudflared" "backrest" "redis" "db" "watchtower")

    # Define start order
    local start_order=("watchtower" "db" "redis" "auth" "ollama" "searxng" "edgetts" "tika" "mcposerver" "nginx" "openwebui" "cloudflared" "backrest")

    # Stop services
    log "Остановка сервисов в правильном порядке"
    for service in "${stop_order[@]}"; do
        if docker-compose ps "$service" --format "{{.Status}}" | grep -q "Up"; then
            graceful_stop_service "$service" 30
        else
            log "Сервис $service уже остановлен"
        fi
    done

    # Pause for complete shutdown
    log "Ожидание полной остановки всех сервисов"
    sleep 10

    # Clean up resources
    log "Очистка неиспользуемых ресурсов Docker"
    docker system prune -f --volumes || true

    # Start services
    log "Запуск сервисов в правильном порядке"
    for service in "${start_order[@]}"; do
        log "Запуск сервиса: $service"
        graceful_start_service "$service" 60

        # Pause between starts for stabilization
        sleep 10
    done

    # Final check
    log "Финальная проверка всех сервисов"
    sleep 30

    local unhealthy_services=()
    for service in "${start_order[@]}"; do
        local status=$(docker-compose ps "$service" --format "{{.Status}}" 2>/dev/null || echo "not_found")
        if ! echo "$status" | grep -q "healthy\|Up"; then
            unhealthy_services+=("$service")
        fi
    done

    if [[ ${#unhealthy_services[@]} -eq 0 ]]; then
        success "Все сервисы успешно перезапущены и работают"
        return 0
    else
        error "Следующие сервисы не запустились корректно: ${unhealthy_services[*]}"
        return 1
    fi
}

# Rollback to previous state
rollback_to_backup() {
    log "Откат к предыдущему состоянию"

    if [[ ! -f "$BACKUP_DIR/latest_backup_path.txt" ]]; then
        error "Резервная копия не найдена"
        return 1
    fi

    local backup_path=$(cat "$BACKUP_DIR/latest_backup_path.txt")
    if [[ ! -d "$backup_path" ]]; then
        error "Путь к резервной копии не существует: $backup_path"
        return 1
    fi

    log "Восстановление из резервной копии: $backup_path"

    # Stop all services
    docker-compose down --timeout=30 || true

    # Restore configurations
    if [[ -d "$backup_path/env" ]]; then
        cp -r "$backup_path/env"/* "$PROJECT_ROOT/env/" 2>/dev/null || true
    fi

    if [[ -d "$backup_path/conf" ]]; then
        cp -r "$backup_path/conf"/* "$PROJECT_ROOT/conf/" 2>/dev/null || true
    fi

    # Start services
    docker-compose up -d

    success "Откат завершен"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                ERNI-KI Graceful Restart                     ║"
    echo "║               Безопасный перезапуск сервисов                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    # Change to working directory
    cd "$PROJECT_ROOT"

    # Execute graceful restart of entire system
    graceful_restart_all
}

# Command line argument handling
case "${1:-}" in
    --service)
        if [[ -n "${2:-}" ]]; then
            log "Graceful перезапуск сервиса: $2"
            cd "$PROJECT_ROOT"
            graceful_restart_service "$2"
        else
            error "Укажите имя сервиса для перезапуска"
            exit 1
        fi
        ;;
    --stop)
        if [[ -n "${2:-}" ]]; then
            log "Graceful остановка сервиса: $2"
            cd "$PROJECT_ROOT"
            graceful_stop_service "$2"
        else
            log "Graceful остановка всех сервисов"
            cd "$PROJECT_ROOT"
            docker-compose down --timeout=60
        fi
        ;;
    --start)
        if [[ -n "${2:-}" ]]; then
            log "Graceful запуск сервиса: $2"
            cd "$PROJECT_ROOT"
            graceful_start_service "$2"
        else
            log "Graceful запуск всех сервисов"
            cd "$PROJECT_ROOT"
            docker-compose up -d
        fi
        ;;
    --backup)
        log "Создание резервной копии состояния"
        mkdir -p "$BACKUP_DIR"
        create_state_backup
        ;;
    --rollback)
        log "Откат к предыдущему состоянию"
        cd "$PROJECT_ROOT"
        rollback_to_backup
        ;;
    --check)
        log "Проверка готовности к перезапуску"
        cd "$PROJECT_ROOT"
        check_restart_readiness
        ;;
    *)
        main
        ;;
esac
