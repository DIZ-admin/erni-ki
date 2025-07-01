#!/bin/bash
# Комплексный предпродакшн аудит системы ERNI-KI
# Проводит полную проверку безопасности, производительности, надежности и конфигурации

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции логирования
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

critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

# Глобальные переменные для отчета
AUDIT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
AUDIT_REPORT_FILE="audit-report-$(date +%Y%m%d_%H%M%S).md"
SECURITY_ISSUES=()
PERFORMANCE_ISSUES=()
RELIABILITY_ISSUES=()
CONFIG_ISSUES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

# Функция добавления проблемы в отчет
add_issue() {
    local category="$1"
    local severity="$2"
    local title="$3"
    local description="$4"
    local recommendation="$5"

    case $severity in
        "CRITICAL") ((CRITICAL_COUNT++)) ;;
        "HIGH") ((HIGH_COUNT++)) ;;
        "MEDIUM") ((MEDIUM_COUNT++)) ;;
        "LOW") ((LOW_COUNT++)) ;;
    esac

    local issue="**[$severity]** $title|$description|$recommendation"

    case $category in
        "SECURITY") SECURITY_ISSUES+=("$issue") ;;
        "PERFORMANCE") PERFORMANCE_ISSUES+=("$issue") ;;
        "RELIABILITY") RELIABILITY_ISSUES+=("$issue") ;;
        "CONFIG") CONFIG_ISSUES+=("$issue") ;;
    esac
}

# Проверка предварительных условий
check_prerequisites() {
    section "Проверка предварительных условий"

    # Проверка Docker
    if ! command -v docker &> /dev/null; then
        critical "Docker не установлен"
        add_issue "CONFIG" "CRITICAL" "Docker не найден" "Docker не установлен в системе" "Установите Docker"
        return 1
    fi

    # Проверка Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        critical "Docker Compose не найден"
        add_issue "CONFIG" "CRITICAL" "Docker Compose не найден" "Docker Compose не установлен" "Установите Docker Compose"
        return 1
    fi

    # Проверка файлов проекта
    if [ ! -f "compose.yml" ]; then
        critical "Файл compose.yml не найден"
        add_issue "CONFIG" "CRITICAL" "Отсутствует compose.yml" "Основной файл конфигурации не найден" "Создайте compose.yml из compose.yml.example"
        return 1
    fi

    success "Предварительные условия выполнены"
    return 0
}

# Аудит безопасности
audit_security() {
    section "АУДИТ БЕЗОПАСНОСТИ"

    # Проверка файлов с секретами
    log "Проверка управления секретами..."

    # Проверка .env файлов
    if find env/ -name "*.env" -exec grep -l "password\|secret\|key" {} \; 2>/dev/null | grep -q .; then
        warning "Найдены секреты в .env файлах"

        # Проверка на дефолтные пароли (исключая example файлы)
        if grep -r "CHANGE_BEFORE_GOING_LIVE\|password123\|admin123" env/ --exclude="*.example" 2>/dev/null; then
            critical "Найдены дефолтные пароли"
            add_issue "SECURITY" "CRITICAL" "Дефолтные пароли" "Обнаружены незамененные дефолтные пароли в production файлах" "Замените все дефолтные пароли на безопасные"
        fi

        # Проверка прав доступа к файлам с секретами (исключая example файлы)
        if find env/ -name "*.env" -not -name "*.example" -not -perm 600 2>/dev/null | grep -q .; then
            error "Небезопасные права доступа к .env файлам"
            add_issue "SECURITY" "HIGH" "Небезопасные права доступа" "Файлы с секретами имеют слишком открытые права" "Установите права 600 для всех .env файлов"
        fi
    fi

    # Проверка Docker конфигурации безопасности
    log "Проверка конфигурации Docker..."

    # Проверка на privileged контейнеры
    if grep -q "privileged.*true" compose.yml 2>/dev/null; then
        error "Найдены privileged контейнеры"
        add_issue "SECURITY" "HIGH" "Privileged контейнеры" "Контейнеры запущены с привилегированными правами" "Удалите privileged: true или обоснуйте необходимость"
    fi

    # Проверка монтирования Docker socket
    if grep -q "/var/run/docker.sock" compose.yml 2>/dev/null; then
        warning "Docker socket монтируется в контейнеры"
        add_issue "SECURITY" "MEDIUM" "Docker socket доступ" "Контейнеры имеют доступ к Docker socket" "Ограничьте доступ только необходимым сервисам"
    fi

    # Проверка сетевой конфигурации
    log "Проверка сетевой безопасности..."

    # Проверка открытых портов
    if grep -E "ports:" compose.yml | grep -E "0\.0\.0\.0|::" 2>/dev/null; then
        warning "Порты открыты для всех интерфейсов"
        add_issue "SECURITY" "MEDIUM" "Открытые порты" "Сервисы доступны на всех сетевых интерфейсах" "Ограничьте доступ к портам только необходимыми интерфейсами"
    fi

    # Проверка SSL/TLS конфигурации
    if ! grep -q "ssl\|tls\|https" conf/nginx/ 2>/dev/null; then
        error "SSL/TLS не настроен"
        add_issue "SECURITY" "HIGH" "Отсутствует SSL/TLS" "Веб-трафик не зашифрован" "Настройте SSL/TLS сертификаты"
    fi

    success "Аудит безопасности завершен"
}

# Аудит производительности
audit_performance() {
    section "АУДИТ ПРОИЗВОДИТЕЛЬНОСТИ"

    # Проверка ресурсов системы
    log "Анализ системных ресурсов..."

    # Проверка использования CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
    if [ "$CPU_USAGE" -gt 80 ] 2>/dev/null; then
        warning "Высокое использование CPU: ${CPU_USAGE}%"
        add_issue "PERFORMANCE" "MEDIUM" "Высокая нагрузка CPU" "CPU загружен на ${CPU_USAGE}%" "Оптимизируйте процессы или увеличьте ресурсы"
    fi

    # Проверка использования памяти
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$MEMORY_USAGE" -gt 85 ] 2>/dev/null; then
        warning "Высокое использование памяти: ${MEMORY_USAGE}%"
        add_issue "PERFORMANCE" "MEDIUM" "Высокое использование памяти" "ОЗУ загружено на ${MEMORY_USAGE}%" "Оптимизируйте использование памяти или увеличьте ОЗУ"
    fi

    # Проверка дискового пространства
    DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    if [ "$DISK_USAGE" -gt 85 ]; then
        error "Критически мало дискового пространства: ${DISK_USAGE}%"
        add_issue "PERFORMANCE" "HIGH" "Недостаток дискового пространства" "Диск заполнен на ${DISK_USAGE}%" "Очистите диск или увеличьте объем хранилища"
    fi

    # Проверка конфигурации Docker ресурсов
    log "Проверка ресурсных ограничений контейнеров..."

    if ! grep -q "mem_limit\|cpus\|memory" compose.yml 2>/dev/null; then
        warning "Не настроены ограничения ресурсов для контейнеров"
        add_issue "PERFORMANCE" "MEDIUM" "Отсутствуют ограничения ресурсов" "Контейнеры могут потреблять неограниченные ресурсы" "Настройте mem_limit и cpus для всех сервисов"
    fi

    # Проверка конфигурации базы данных
    log "Проверка конфигурации PostgreSQL..."

    if [ -f "conf/postgres/postgresql.conf" ]; then
        # Проверка shared_buffers
        if ! grep -q "shared_buffers" conf/postgres/postgresql.conf 2>/dev/null; then
            warning "shared_buffers не настроен"
            add_issue "PERFORMANCE" "MEDIUM" "PostgreSQL не оптимизирован" "shared_buffers не настроен" "Настройте shared_buffers = 25% от ОЗУ"
        fi
    fi

    success "Аудит производительности завершен"
}

# Аудит надежности
audit_reliability() {
    section "АУДИТ НАДЕЖНОСТИ"

    # Проверка health checks
    log "Проверка health checks..."

    SERVICES_WITHOUT_HEALTHCHECK=()
    while IFS= read -r service; do
        if ! grep -A 10 "^  $service:" compose.yml | grep -q "healthcheck:" 2>/dev/null; then
            SERVICES_WITHOUT_HEALTHCHECK+=("$service")
        fi
    done < <(grep -E "^  [a-zA-Z].*:" compose.yml | sed 's/://g' | awk '{print $1}')

    if [ ${#SERVICES_WITHOUT_HEALTHCHECK[@]} -gt 0 ]; then
        warning "Сервисы без health checks: ${SERVICES_WITHOUT_HEALTHCHECK[*]}"
        add_issue "RELIABILITY" "MEDIUM" "Отсутствуют health checks" "Сервисы ${SERVICES_WITHOUT_HEALTHCHECK[*]} не имеют проверок здоровья" "Добавьте healthcheck для всех критических сервисов"
    fi

    # Проверка restart policies
    log "Проверка политик перезапуска..."

    if grep -c "restart:" compose.yml | grep -q "0"; then
        warning "Не все сервисы имеют политику перезапуска"
        add_issue "RELIABILITY" "MEDIUM" "Отсутствуют restart policies" "Некоторые сервисы не перезапустятся автоматически" "Добавьте restart: unless-stopped для всех сервисов"
    fi

    # Проверка резервного копирования
    log "Проверка системы резервного копирования..."

    if [ ! -d ".config-backup" ] || [ ! "$(ls -A .config-backup 2>/dev/null)" ]; then
        error "Система резервного копирования не настроена"
        add_issue "RELIABILITY" "HIGH" "Отсутствует резервное копирование" "Backrest не настроен или не содержит данных" "Настройте и протестируйте систему резервного копирования"
    fi

    # Проверка логирования
    log "Проверка системы логирования..."

    if ! grep -q "logging:" compose.yml 2>/dev/null; then
        warning "Не настроено централизованное логирование"
        add_issue "RELIABILITY" "LOW" "Отсутствует централизованное логирование" "Логи контейнеров не централизованы" "Настройте logging driver для всех сервисов"
    fi

    success "Аудит надежности завершен"
}

# Аудит конфигурации
audit_configuration() {
    section "АУДИТ КОНФИГУРАЦИИ"

    # Проверка Docker Compose версии
    log "Проверка версии Docker Compose файла..."

    COMPOSE_VERSION=$(grep "version:" compose.yml | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'")
    if [ -z "$COMPOSE_VERSION" ]; then
        warning "Версия Docker Compose не указана"
        add_issue "CONFIG" "LOW" "Отсутствует версия Compose" "Версия Docker Compose файла не указана" "Добавьте version: '3.8' в начало файла"
    elif [[ "$COMPOSE_VERSION" < "3.7" ]]; then
        warning "Устаревшая версия Docker Compose: $COMPOSE_VERSION"
        add_issue "CONFIG" "MEDIUM" "Устаревшая версия Compose" "Используется версия $COMPOSE_VERSION" "Обновите до версии 3.8 или выше"
    fi

    # Проверка переменных окружения
    log "Проверка переменных окружения..."

    # Проверка наличия example файлов
    for env_file in env/*.env; do
        if [ -f "$env_file" ]; then
            example_file="${env_file}.example"
            if [ ! -f "$example_file" ]; then
                warning "Отсутствует example файл для $env_file"
                add_issue "CONFIG" "LOW" "Отсутствует example файл" "Нет $example_file" "Создайте example файл с безопасными значениями по умолчанию"
            fi
        fi
    done

    # Проверка volumes
    log "Проверка конфигурации volumes..."

    # Проверка на использование bind mounts в production
    if grep -E "^\s*-\s*\./.*:" compose.yml | grep -v ":ro" 2>/dev/null; then
        warning "Используются bind mounts без read-only"
        add_issue "CONFIG" "MEDIUM" "Небезопасные bind mounts" "Bind mounts без :ro могут быть изменены контейнерами" "Добавьте :ro для read-only bind mounts где возможно"
    fi

    # Проверка networks
    log "Проверка сетевой конфигурации..."

    if ! grep -q "networks:" compose.yml 2>/dev/null; then
        warning "Не настроены пользовательские сети"
        add_issue "CONFIG" "LOW" "Отсутствуют пользовательские сети" "Все сервисы в default сети" "Создайте изолированные сети для разных групп сервисов"
    fi

    success "Аудит конфигурации завершен"
}

# Основная функция аудита
main() {
    log "Запуск комплексного предпродакшн аудита ERNI-KI..."
    echo "Дата аудита: $AUDIT_DATE"
    echo "Отчет будет сохранен в: $AUDIT_REPORT_FILE"
    echo ""

    # Проверка предварительных условий
    if ! check_prerequisites; then
        error "Не удалось выполнить предварительные проверки"
        exit 1
    fi

    # Выполнение аудитов
    audit_security
    echo ""
    audit_performance
    echo ""
    audit_reliability
    echo ""
    audit_configuration

    echo ""
    section "ГЕНЕРАЦИЯ ОТЧЕТА"
    generate_report

    echo ""
    success "Комплексный аудит завершен!"
    echo "Отчет сохранен в: $AUDIT_REPORT_FILE"
    echo ""
    echo "Сводка проблем:"
    echo "  🔴 Критические: $CRITICAL_COUNT"
    echo "  🟠 Высокие: $HIGH_COUNT"
    echo "  🟡 Средние: $MEDIUM_COUNT"
    echo "  🟢 Низкие: $LOW_COUNT"
}

# Генерация отчета
generate_report() {
    log "Создание детального отчета..."

    cat > "$AUDIT_REPORT_FILE" << EOF
# 🔍 Комплексный предпродакшн аудит ERNI-KI

**Дата аудита**: $AUDIT_DATE
**Система**: $(hostname)
**Пользователь**: $(whoami)
**Версия Docker**: $(docker --version 2>/dev/null || echo "Не установлен")
**Версия Docker Compose**: $(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "Не установлен")

## 📊 Сводка результатов

| Категория | Критические | Высокие | Средние | Низкие | Всего |
|-----------|-------------|---------|---------|--------|-------|
| 🔒 Безопасность | $(echo "${SECURITY_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#SECURITY_ISSUES[@]} |
| ⚡ Производительность | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#PERFORMANCE_ISSUES[@]} |
| 🛡️ Надежность | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#RELIABILITY_ISSUES[@]} |
| ⚙️ Конфигурация | $(echo "${CONFIG_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#CONFIG_ISSUES[@]} |
| **ИТОГО** | **$CRITICAL_COUNT** | **$HIGH_COUNT** | **$MEDIUM_COUNT** | **$LOW_COUNT** | **$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))** |

## 🎯 Оценка готовности к продакшну

EOF

    # Определение общей готовности
    if [ $CRITICAL_COUNT -eq 0 ] && [ $HIGH_COUNT -eq 0 ]; then
        echo "✅ **ГОТОВ К ПРОДАКШНУ** - Критические и высокие проблемы отсутствуют" >> "$AUDIT_REPORT_FILE"
    elif [ $CRITICAL_COUNT -eq 0 ] && [ $HIGH_COUNT -le 2 ]; then
        echo "⚠️ **УСЛОВНО ГОТОВ** - Необходимо устранить высокие проблемы" >> "$AUDIT_REPORT_FILE"
    else
        echo "❌ **НЕ ГОТОВ К ПРОДАКШНУ** - Требуется устранение критических проблем" >> "$AUDIT_REPORT_FILE"
    fi

    # Добавление детальных разделов
    add_security_section
    add_performance_section
    add_reliability_section
    add_configuration_section
    add_recommendations_section
    add_action_plan_section

    success "Отчет создан: $AUDIT_REPORT_FILE"
}

# Добавление разделов отчета
add_security_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 🔒 Аудит безопасности

EOF

    if [ ${#SECURITY_ISSUES[@]} -eq 0 ]; then
        echo "✅ Проблемы безопасности не обнаружены" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Обнаруженные проблемы:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${SECURITY_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Описание**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Рекомендация**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_performance_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## ⚡ Аудит производительности

### Системные ресурсы
- **CPU**: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% загружен
- **Память**: $(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')% использовано
- **Диск**: $(df -h . | awk 'NR==2 {print $5}') заполнен

EOF

    if [ ${#PERFORMANCE_ISSUES[@]} -eq 0 ]; then
        echo "✅ Проблемы производительности не обнаружены" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Обнаруженные проблемы:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${PERFORMANCE_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Описание**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Рекомендация**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_reliability_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 🛡️ Аудит надежности

EOF

    if [ ${#RELIABILITY_ISSUES[@]} -eq 0 ]; then
        echo "✅ Проблемы надежности не обнаружены" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Обнаруженные проблемы:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${RELIABILITY_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Описание**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Рекомендация**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_configuration_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## ⚙️ Аудит конфигурации

EOF

    if [ ${#CONFIG_ISSUES[@]} -eq 0 ]; then
        echo "✅ Проблемы конфигурации не обнаружены" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Обнаруженные проблемы:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${CONFIG_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Описание**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Рекомендация**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_recommendations_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 💡 Общие рекомендации

### Приоритет 1 (Критический)
- Замените все дефолтные пароли на безопасные
- Настройте SSL/TLS шифрование
- Исправьте критические уязвимости безопасности

### Приоритет 2 (Высокий)
- Настройте ограничения ресурсов для контейнеров
- Добавьте health checks для всех сервисов
- Настройте систему резервного копирования

### Приоритет 3 (Средний)
- Оптимизируйте конфигурацию базы данных
- Настройте мониторинг и алертинг
- Добавьте централизованное логирование

### Приоритет 4 (Низкий)
- Обновите версии Docker Compose
- Создайте пользовательские сети
- Добавьте example файлы для конфигураций

EOF
}

add_action_plan_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 📅 План действий

### Неделя 1 (Критические проблемы)
- [ ] Замена дефолтных паролей
- [ ] Настройка SSL/TLS
- [ ] Исправление критических уязвимостей
- [ ] Тестирование безопасности

### Неделя 2 (Высокие проблемы)
- [ ] Настройка ограничений ресурсов
- [ ] Добавление health checks
- [ ] Настройка резервного копирования
- [ ] Тестирование надежности

### Неделя 3 (Средние проблемы)
- [ ] Оптимизация производительности
- [ ] Настройка мониторинга
- [ ] Централизованное логирование
- [ ] Нагрузочное тестирование

### Неделя 4 (Низкие проблемы и финализация)
- [ ] Обновление конфигураций
- [ ] Создание документации
- [ ] Финальное тестирование
- [ ] Подготовка к продакшну

## 📋 Чек-лист готовности к продакшну

### Безопасность
- [ ] Все дефолтные пароли заменены
- [ ] SSL/TLS настроен и работает
- [ ] Права доступа к файлам корректны
- [ ] Сетевая безопасность настроена
- [ ] Аудит безопасности пройден

### Производительность
- [ ] Ресурсы системы оптимизированы
- [ ] Ограничения контейнеров настроены
- [ ] База данных оптимизирована
- [ ] Нагрузочное тестирование пройдено
- [ ] Мониторинг производительности настроен

### Надежность
- [ ] Health checks добавлены для всех сервисов
- [ ] Restart policies настроены
- [ ] Резервное копирование работает
- [ ] Disaster recovery процедуры протестированы
- [ ] Логирование и алертинг настроены

### Конфигурация
- [ ] Docker Compose файлы валидны
- [ ] Переменные окружения настроены
- [ ] Volumes и networks оптимизированы
- [ ] Документация актуальна
- [ ] Процедуры развертывания протестированы

---

**Отчет создан**: $(date)
**Инструмент**: ERNI-KI Comprehensive Audit Script
**Версия**: 1.0

EOF
}

# Запуск аудита
main "$@"
