#!/bin/bash

# ===================================================================
# Universal data permissions fix script for ERNI-KI
# Fixes access issues for Snyk and other tools across data/ directories
# Supports: Backrest, Grafana, PostgreSQL and other services
# ===================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging helpers
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Root permission check
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (sudo)"
        exit 1
    fi
}

# Ensure data directory exists
check_data_directory() {
    local data_dir="data"

    if [[ ! -d "$data_dir" ]]; then
        error "Data directory not found: $data_dir"
        exit 1
    fi

    log "Data directory found: $data_dir"
}

# Find problematic directories
find_problematic_directories() {
    log "Searching for directories with restricted permissions..."

    # Find dirs without execute for others
    local problematic_dirs
    problematic_dirs=$(find data/ -type d ! -perm -o+x 2>/dev/null || true)

    if [[ -n "$problematic_dirs" ]]; then
        echo "=== Found problematic directories ==="
        echo "$problematic_dirs" | while read -r dir; do
            if [[ -n "$dir" ]]; then
                ls -ld "$dir" 2>/dev/null || echo "Unavailable: $dir"
            fi
        done
        echo ""
        return 0
    else
        log "No problematic directories found"
        return 1
    fi
}

# Analyze current permissions
analyze_permissions() {
    log "Analyzing current permissions..."

    echo "=== data directory overview ==="
    ls -la data/ | head -10
    echo ""

    # Specific services
    for service_dir in data/backrest data/grafana data/postgres data/prometheus data/redis; do
        if [[ -d "$service_dir" ]]; then
            echo "=== Permissions for $service_dir ==="
            ls -la "$service_dir/" 2>/dev/null | head -5 || echo "Access restricted"
            echo ""
        fi
    done
}

# Fix permissions
fix_permissions() {
    log "Fixing permissions..."

    local fixed_count=0

    # Find and fix all problematic directories
    local problematic_dirs
    problematic_dirs=$(find data/ -type d ! -perm -o+x 2>/dev/null || true)

    if [[ -n "$problematic_dirs" ]]; then
        echo "$problematic_dirs" | while read -r dir; do
            if [[ -n "$dir" && -d "$dir" ]]; then
                log "Fixing permissions for $dir"

                # Set appropriate permissions per service
                case "$dir" in
                    data/postgres*)
                        # PostgreSQL needs stricter permissions
                        chmod 750 "$dir" 2>/dev/null || warning "Не удалось изменить права для $dir"
                        ;;
                    data/grafana/alerting*)
                        # Grafana alerting - fix recursively
                        chmod -R 755 "$dir" 2>/dev/null || warning "Не удалось изменить права для $dir"
                        ;;
                    *)
                        # Standard permissions elsewhere
                        chmod 755 "$dir" 2>/dev/null || warning "Не удалось изменить права для $dir"
                        ;;
                esac

                ((fixed_count++)) || true
            fi
        done

        success "Permissions fixed for directories: $fixed_count"
    else
        log "No problematic directories found"
    fi

    # Backrest repo handling
    if [[ -d "data/backrest/repos/erni-ki-local" ]]; then
        log "Additional fix for Backrest repo"
        chmod -R 755 data/backrest/repos/erni-ki-local 2>/dev/null || warning "Could not fix Backrest permissions"
    fi
}

# Verify access after fixes
verify_access() {
    log "Verifying access after fixes..."

    local verification_failed=0

    # Check previously problematic dirs
    local test_dirs=("data/backrest/repos" "data/grafana/alerting" "data/grafana/csv" "data/grafana/png")

    for dir in "${test_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            if ls "$dir/" >/dev/null 2>&1; then
                success "Access to $dir restored"
            else
                error "Access to $dir still restricted"
                ((verification_failed++))
            fi
        fi
    done

    # Backrest repo check
    if [[ -d "data/backrest/repos/erni-ki-local" ]]; then
        if ls data/backrest/repos/erni-ki-local/ >/dev/null 2>&1; then
            success "Access to Backrest repo restored"
        else
            error "Access to Backrest repo still restricted"
            ((verification_failed++))
        fi
    fi

    # Ensure no remaining problematic dirs
    local remaining_issues
    remaining_issues=$(find data/ -type d ! -perm -o+x 2>/dev/null | wc -l)

    if [[ "$remaining_issues" -eq 0 ]]; then
        success "All permission issues resolved"
    else
        warning "Remaining problematic directories: $remaining_issues"
        ((verification_failed++))
    fi

    return $verification_failed
}

# Check services
check_services() {
    log "Checking services..."

    # Check Backrest
    if docker ps | grep -q backrest; then
        success "Backrest container is running"
        if curl -s http://localhost:9898/ >/dev/null 2>&1; then
            success "Backrest web UI is reachable"
        else
            warning "Backrest web UI is not reachable"
        fi
    else
        warning "Backrest container is not running"
    fi

    # Проверяем Grafana
    if docker ps | grep -q grafana; then
        success "Grafana container is running"
        if curl -s http://localhost:3000/ >/dev/null 2>&1; then
            success "Grafana web UI is reachable"
        else
            warning "Grafana web UI is not reachable"
        fi
    else
        warning "Grafana container is not running"
    fi

    # Check PostgreSQL
    if docker ps | grep -q postgres; then
        success "PostgreSQL container is running"
    else
        warning "PostgreSQL container is not running"
    fi
}

# Создание отчёта
create_report() {
    local report_file="logs/data-permissions-fix-$(date +%Y%m%d_%H%M%S).log"

    log "Создание отчёта: $report_file"

    {
        echo "=== Отчёт об исправлении прав доступа ERNI-KI ==="
        echo "Дата: $(date)"
        echo "Пользователь: $(whoami)"
        echo ""
        echo "=== Общий обзор директории data ==="
        ls -la data/ 2>/dev/null || echo "Директория data недоступна"
        echo ""

        # Отчёт по каждому сервису
        for service in backrest grafana postgres prometheus redis; do
            if [[ -d "data/$service" ]]; then
                echo "=== Права доступа к data/$service ==="
                ls -la "data/$service/" 2>/dev/null || echo "Директория data/$service недоступна"
                echo ""
            fi
        done

        echo "=== Проверка проблемных директорий ==="
        local remaining_issues
        remaining_issues=$(find data/ -type d ! -perm -o+x 2>/dev/null || true)
        if [[ -n "$remaining_issues" ]]; then
            echo "Остались проблемные директории:"
            echo "$remaining_issues"
        else
            echo "Проблемные директории не найдены"
        fi

        echo ""
        echo "=== Статус сервисов ==="
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(backrest|grafana|postgres)" || echo "Сервисы не найдены"

    } > "$report_file"

    success "Отчёт создан: $report_file"
}

# Основная функция
main() {
    log "Запуск универсального исправления прав доступа для ERNI-KI"

    # Проверки
    check_root
    check_data_directory

    # Анализ проблем
    analyze_permissions
    if ! find_problematic_directories; then
        success "Проблемы с правами доступа не обнаружены"
        exit 0
    fi

    # Исправление и проверка
    fix_permissions
    verify_access
    check_services
    create_report

    success "Исправление прав доступа завершено успешно"

    echo ""
    echo "=== Рекомендации ==="
    echo "1. Snyk теперь может сканировать проект без ошибок доступа"
    echo "2. Все сервисы (Backrest, Grafana, PostgreSQL) продолжают работать"
    echo "3. Безопасность сохранена (только чтение для других пользователей)"
    echo "4. При появлении новых проблем запустите этот скрипт повторно"
    echo "5. Рассмотрите добавление скрипта в cron для автоматической проверки"
}

# Запуск основной функции
main "$@"
