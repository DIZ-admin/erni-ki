#!/bin/bash
# Быстрый аудит системы ERNI-KI для создания отчета
# Упрощенная версия для генерации детального отчета

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Переменные для отчета
AUDIT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
AUDIT_REPORT_FILE="comprehensive-audit-report-$(date +%Y%m%d_%H%M%S).md"

# Сбор информации о системе
collect_system_info() {
    log "Сбор информации о системе..."

    HOSTNAME=$(hostname)
    USER=$(whoami)
    DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Не установлен")
    COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "Не установлен")

    # Системные ресурсы
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1 2>/dev/null || echo "N/A")
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "N/A")
    DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' 2>/dev/null || echo "N/A")

    success "Информация о системе собрана"
}

# Аудит безопасности
audit_security() {
    log "Проведение аудита безопасности..."

    SECURITY_ISSUES=()

    # Проверка дефолтных паролей в production файлах
    if grep -r "CHANGE_BEFORE_GOING_LIVE\|password123\|admin123" env/ --exclude="*.example" 2>/dev/null; then
        SECURITY_ISSUES+=("CRITICAL|Дефолтные пароли|Найдены незамененные дефолтные пароли в production файлах|Замените все дефолтные пароли на безопасные")
    fi

    # Проверка прав доступа к .env файлам
    if find env/ -name "*.env" -not -name "*.example" -not -perm 600 2>/dev/null | grep -q .; then
        SECURITY_ISSUES+=("HIGH|Небезопасные права доступа|Файлы с секретами имеют слишком открытые права|Установите права 600 для всех .env файлов")
    fi

    # Проверка Docker socket
    if grep -q "/var/run/docker.sock" compose.yml 2>/dev/null; then
        SECURITY_ISSUES+=("MEDIUM|Docker socket доступ|Контейнеры имеют доступ к Docker socket|Ограничьте доступ только необходимым сервисам")
    fi

    # Проверка SSL/TLS
    if ! grep -q "ssl\|tls\|https" conf/nginx/ 2>/dev/null; then
        SECURITY_ISSUES+=("HIGH|Отсутствует SSL/TLS|Веб-трафик не зашифрован|Настройте SSL/TLS сертификаты")
    fi

    success "Аудит безопасности завершен (найдено ${#SECURITY_ISSUES[@]} проблем)"
}

# Аудит производительности
audit_performance() {
    log "Проведение аудита производительности..."

    PERFORMANCE_ISSUES=()

    # Проверка использования ресурсов
    if [ "$CPU_USAGE" != "N/A" ] && [ "$CPU_USAGE" -gt 80 ] 2>/dev/null; then
        PERFORMANCE_ISSUES+=("MEDIUM|Высокая нагрузка CPU|CPU загружен на ${CPU_USAGE}%|Оптимизируйте процессы или увеличьте ресурсы")
    fi

    if [ "$MEMORY_USAGE" != "N/A" ] && [ "${MEMORY_USAGE%.*}" -gt 85 ] 2>/dev/null; then
        PERFORMANCE_ISSUES+=("MEDIUM|Высокое использование памяти|ОЗУ загружено на ${MEMORY_USAGE}%|Оптимизируйте использование памяти или увеличьте ОЗУ")
    fi

    if [ "$DISK_USAGE" != "N/A" ] && [ "${DISK_USAGE%\%}" -gt 85 ] 2>/dev/null; then
        PERFORMANCE_ISSUES+=("HIGH|Недостаток дискового пространства|Диск заполнен на ${DISK_USAGE}|Очистите диск или увеличьте объем хранилища")
    fi

    # Проверка ограничений ресурсов
    if ! grep -q "mem_limit\|cpus\|memory" compose.yml 2>/dev/null; then
        PERFORMANCE_ISSUES+=("MEDIUM|Отсутствуют ограничения ресурсов|Контейнеры могут потреблять неограниченные ресурсы|Настройте mem_limit и cpus для всех сервисов")
    fi

    success "Аудит производительности завершен (найдено ${#PERFORMANCE_ISSUES[@]} проблем)"
}

# Аудит надежности
audit_reliability() {
    log "Проведение аудита надежности..."

    RELIABILITY_ISSUES=()

    # Проверка health checks
    SERVICES_WITHOUT_HEALTHCHECK=()
    while IFS= read -r service; do
        if ! grep -A 10 "^  $service:" compose.yml | grep -q "healthcheck:" 2>/dev/null; then
            SERVICES_WITHOUT_HEALTHCHECK+=("$service")
        fi
    done < <(grep -E "^  [a-zA-Z].*:" compose.yml | sed 's/://g' | awk '{print $1}' 2>/dev/null || true)

    if [ ${#SERVICES_WITHOUT_HEALTHCHECK[@]} -gt 0 ]; then
        RELIABILITY_ISSUES+=("MEDIUM|Отсутствуют health checks|Сервисы ${SERVICES_WITHOUT_HEALTHCHECK[*]} не имеют проверок здоровья|Добавьте healthcheck для всех критических сервисов")
    fi

    # Проверка restart policies
    if ! grep -q "restart:" compose.yml 2>/dev/null; then
        RELIABILITY_ISSUES+=("MEDIUM|Отсутствуют restart policies|Некоторые сервисы не перезапустятся автоматически|Добавьте restart: unless-stopped для всех сервисов")
    fi

    # Проверка резервного копирования
    if [ ! -d ".config-backup" ] || [ ! "$(ls -A .config-backup 2>/dev/null)" ]; then
        RELIABILITY_ISSUES+=("HIGH|Отсутствует резервное копирование|Backrest не настроен или не содержит данных|Настройте и протестируйте систему резервного копирования")
    fi

    success "Аудит надежности завершен (найдено ${#RELIABILITY_ISSUES[@]} проблем)"
}

# Аудит конфигурации
audit_configuration() {
    log "Проведение аудита конфигурации..."

    CONFIG_ISSUES=()

    # Проверка версии Docker Compose
    COMPOSE_VERSION_NUM=$(grep "version:" compose.yml | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'" 2>/dev/null || echo "")
    if [ -z "$COMPOSE_VERSION_NUM" ]; then
        CONFIG_ISSUES+=("LOW|Отсутствует версия Compose|Версия Docker Compose файла не указана|Добавьте version: '3.8' в начало файла")
    fi

    # Проверка example файлов
    for env_file in env/*.env; do
        if [ -f "$env_file" ]; then
            example_file="${env_file}.example"
            if [ ! -f "$example_file" ]; then
                CONFIG_ISSUES+=("LOW|Отсутствует example файл|Нет $example_file|Создайте example файл с безопасными значениями по умолчанию")
            fi
        fi
    done 2>/dev/null || true

    # Проверка bind mounts
    if grep -E "^\s*-\s*\./.*:" compose.yml | grep -v ":ro" 2>/dev/null; then
        CONFIG_ISSUES+=("MEDIUM|Небезопасные bind mounts|Bind mounts без :ro могут быть изменены контейнерами|Добавьте :ro для read-only bind mounts где возможно")
    fi

    success "Аудит конфигурации завершен (найдено ${#CONFIG_ISSUES[@]} проблем)"
}

# Подсчет проблем по критичности
count_issues_by_severity() {
    CRITICAL_COUNT=0
    HIGH_COUNT=0
    MEDIUM_COUNT=0
    LOW_COUNT=0

    # Объединяем все массивы проблем
    ALL_ISSUES=()
    ALL_ISSUES+=("${SECURITY_ISSUES[@]}")
    ALL_ISSUES+=("${PERFORMANCE_ISSUES[@]}")
    ALL_ISSUES+=("${RELIABILITY_ISSUES[@]}")
    ALL_ISSUES+=("${CONFIG_ISSUES[@]}")

    for issue in "${ALL_ISSUES[@]}"; do
        severity=$(echo "$issue" | cut -d'|' -f1)
        case $severity in
            "CRITICAL") ((CRITICAL_COUNT++)) ;;
            "HIGH") ((HIGH_COUNT++)) ;;
            "MEDIUM") ((MEDIUM_COUNT++)) ;;
            "LOW") ((LOW_COUNT++)) ;;
        esac
    done
}

# Генерация отчета
generate_report() {
    log "Создание детального отчета..."

    cat > "$AUDIT_REPORT_FILE" << EOF
# 🔍 Комплексный предпродакшн аудит ERNI-KI

**Дата аудита**: $AUDIT_DATE
**Система**: $HOSTNAME
**Пользователь**: $USER
**Версия Docker**: $DOCKER_VERSION
**Версия Docker Compose**: $COMPOSE_VERSION

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
    add_detailed_sections

    success "Отчет создан: $AUDIT_REPORT_FILE"
}

# Добавление детальных разделов в отчет
add_detailed_sections() {
    cat >> "$AUDIT_REPORT_FILE" << 'EOF'

## 📈 Системные ресурсы

EOF

    echo "- **CPU**: ${CPU_USAGE}% загружен" >> "$AUDIT_REPORT_FILE"
    echo "- **Память**: ${MEMORY_USAGE}% использовано" >> "$AUDIT_REPORT_FILE"
    echo "- **Диск**: ${DISK_USAGE} заполнен" >> "$AUDIT_REPORT_FILE"
    echo "" >> "$AUDIT_REPORT_FILE"

    # Добавление проблем по категориям
    add_issues_section "🔒 Аудит безопасности" "${SECURITY_ISSUES[@]}"
    add_issues_section "⚡ Аудит производительности" "${PERFORMANCE_ISSUES[@]}"
    add_issues_section "🛡️ Аудит надежности" "${RELIABILITY_ISSUES[@]}"
    add_issues_section "⚙️ Аудит конфигурации" "${CONFIG_ISSUES[@]}"

    # Добавление рекомендаций и плана действий
    cat >> "$AUDIT_REPORT_FILE" << 'EOF'

## 💡 Приоритетные рекомендации

### 🔴 Критический приоритет
- Замените все дефолтные пароли на безопасные
- Настройте SSL/TLS шифрование для всех веб-сервисов
- Исправьте критические уязвимости безопасности

### 🟠 Высокий приоритет
- Настройте ограничения ресурсов для всех контейнеров
- Добавьте health checks для критических сервисов
- Настройте и протестируйте систему резервного копирования

### 🟡 Средний приоритет
- Оптимизируйте конфигурацию базы данных PostgreSQL
- Настройте централизованное логирование и мониторинг
- Ограничьте доступ к Docker socket

### 🟢 Низкий приоритет
- Обновите версию Docker Compose файла
- Создайте example файлы для всех конфигураций
- Настройте пользовательские Docker сети

## 📅 План действий (4 недели)

### Неделя 1: Критические проблемы безопасности
- [ ] Замена всех дефолтных паролей
- [ ] Настройка SSL/TLS сертификатов
- [ ] Исправление прав доступа к файлам
- [ ] Аудит сетевой безопасности

### Неделя 2: Высокие проблемы надежности
- [ ] Настройка ограничений ресурсов контейнеров
- [ ] Добавление health checks для всех сервисов
- [ ] Настройка и тестирование Backrest
- [ ] Проверка restart policies

### Неделя 3: Средние проблемы производительности
- [ ] Оптимизация конфигурации PostgreSQL
- [ ] Настройка мониторинга ресурсов
- [ ] Централизованное логирование
- [ ] Нагрузочное тестирование

### Неделя 4: Низкие проблемы и финализация
- [ ] Обновление конфигурационных файлов
- [ ] Создание недостающей документации
- [ ] Финальное тестирование системы
- [ ] Подготовка к продакшн развертыванию

## 📋 Чек-лист готовности к продакшну

### Безопасность ✅
- [ ] Все дефолтные пароли заменены
- [ ] SSL/TLS настроен и работает
- [ ] Права доступа к файлам корректны (600 для .env)
- [ ] Сетевая безопасность настроена
- [ ] Firewall правила применены

### Производительность ⚡
- [ ] Системные ресурсы оптимизированы
- [ ] Ограничения контейнеров настроены
- [ ] База данных оптимизирована
- [ ] Кэширование настроено
- [ ] Нагрузочное тестирование пройдено

### Надежность 🛡️
- [ ] Health checks добавлены для всех сервисов
- [ ] Restart policies настроены
- [ ] Резервное копирование работает и протестировано
- [ ] Disaster recovery процедуры документированы
- [ ] Мониторинг и алертинг настроены

### Конфигурация ⚙️
- [ ] Docker Compose файлы валидны
- [ ] Переменные окружения настроены
- [ ] Volumes и networks оптимизированы
- [ ] Документация актуальна
- [ ] Процедуры развертывания протестированы

---

**Отчет создан**: $(date)
**Инструмент**: ERNI-KI Quick Audit Script
**Версия**: 1.0
**Статус**: Готов для технического руководства

EOF
}

# Функция добавления проблем в отчет
add_issues_section() {
    local section_title="$1"
    shift
    local issues=("$@")

    cat >> "$AUDIT_REPORT_FILE" << EOF

## $section_title

EOF

    if [ ${#issues[@]} -eq 0 ]; then
        echo "✅ Проблемы не обнаружены" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Обнаруженные проблемы:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${issues[@]}"; do
            IFS='|' read -r severity title description recommendation <<< "$issue"
            echo "#### [$severity] $title" >> "$AUDIT_REPORT_FILE"
            echo "**Описание**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Рекомендация**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

# Основная функция
main() {
    log "Запуск быстрого аудита ERNI-KI..."
    echo "Дата аудита: $AUDIT_DATE"
    echo "Отчет будет сохранен в: $AUDIT_REPORT_FILE"
    echo ""

    collect_system_info
    audit_security
    audit_performance
    audit_reliability
    audit_configuration
    count_issues_by_severity
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
    echo "  📊 Всего: $((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))"
}

# Запуск аудита
main "$@"
