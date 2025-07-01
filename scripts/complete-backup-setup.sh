#!/bin/bash
# Полная автоматизация настройки локального бэкапа ERNI-KI
# Выполняет все необходимые шаги для настройки Backrest

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    exit 1
}

# Проверка предварительных условий
check_prerequisites() {
    log "Проверка предварительных условий..."
    
    # Проверка Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose не найден"
    fi
    
    # Проверка файлов проекта
    if [ ! -f "compose.yml" ]; then
        error "Файл compose.yml не найден. Запустите из корня проекта ERNI-KI"
    fi
    
    # Проверка Backrest
    if ! docker-compose ps backrest | grep -q "Up"; then
        warning "Backrest не запущен. Запускаем..."
        docker-compose up -d backrest
        sleep 15
    fi
    
    # Проверка доступности веб-интерфейса
    if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:9898/ | grep -q "200"; then
        error "Backrest веб-интерфейс недоступен"
    fi
    
    success "Все предварительные условия выполнены"
}

# Создание директории бэкапа
setup_backup_directory() {
    log "Настройка директории бэкапа..."
    
    # Создание директории
    mkdir -p .config-backup
    
    # Проверка .gitignore
    if ! grep -q ".config-backup/" .gitignore 2>/dev/null; then
        echo ".config-backup/" >> .gitignore
        success "Добавлена директория .config-backup в .gitignore"
    fi
    
    success "Директория бэкапа настроена"
}

# Получение учетных данных
get_credentials() {
    log "Получение учетных данных..."
    
    if [ ! -f ".backrest_secrets" ]; then
        error "Файл .backrest_secrets не найден. Запустите сначала ./scripts/backrest-setup.sh"
    fi
    
    BACKREST_PASSWORD=$(grep "BACKREST_PASSWORD=" .backrest_secrets | cut -d'=' -f2)
    RESTIC_PASSWORD=$(grep "RESTIC_PASSWORD=" .backrest_secrets | cut -d'=' -f2)
    
    if [ -z "$BACKREST_PASSWORD" ] || [ -z "$RESTIC_PASSWORD" ]; then
        error "Не удалось получить учетные данные"
    fi
    
    success "Учетные данные загружены"
}

# Показ инструкций по настройке
show_setup_instructions() {
    log "Отображение инструкций по настройке..."
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    НАСТРОЙКА BACKREST ЧЕРЕЗ ВЕБ-ИНТЕРФЕЙС                   ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "🌐 URL: http://localhost:9898"
    echo "👤 Пользователь: admin"
    echo "🔑 Пароль: $BACKREST_PASSWORD"
    echo ""
    echo "📋 ШАГИ НАСТРОЙКИ:"
    echo ""
    echo "1️⃣  СОЗДАНИЕ РЕПОЗИТОРИЯ:"
    echo "   • Нажмите 'Add Repository'"
    echo "   • Repository ID: erni-ki-local"
    echo "   • Repository URI: /backup-sources/.config-backup"
    echo "   • Password: $RESTIC_PASSWORD"
    echo "   • Prune Schedule: 0 3 * * *"
    echo "   • Check Schedule: 0 4 * * 0"
    echo ""
    echo "2️⃣  СОЗДАНИЕ ПЛАНА БЭКАПА:"
    echo "   • Нажмите 'Add Plan'"
    echo "   • Plan ID: erni-ki-critical-data"
    echo "   • Repository: erni-ki-local"
    echo "   • Paths:"
    echo "     - /backup-sources/env"
    echo "     - /backup-sources/conf"
    echo "     - /backup-sources/data/postgres"
    echo "     - /backup-sources/data/openwebui"
    echo "     - /backup-sources/data/ollama"
    echo "   • Excludes: *.log, *.tmp, **/cache/**, **/temp/**, **/.git/**"
    echo "   • Schedule: 0 2 * * *"
    echo "   • Retention: Daily=7, Weekly=4"
    echo ""
    echo "3️⃣  СОЗДАНИЕ ТЕСТОВОГО БЭКАПА:"
    echo "   • Перейдите в 'Plans'"
    echo "   • Нажмите 'Backup Now' для плана erni-ki-critical-data"
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║  После настройки нажмите Enter для продолжения проверки...                  ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
}

# Ожидание завершения настройки
wait_for_setup() {
    echo ""
    read -p "Нажмите Enter после завершения настройки в веб-интерфейсе..."
    echo ""
}

# Проверка созданного бэкапа
verify_backup() {
    log "Проверка созданного бэкапа..."
    
    # Проверка директории
    if [ ! -d ".config-backup" ] || [ ! "$(ls -A .config-backup 2>/dev/null)" ]; then
        warning "Директория .config-backup пуста"
        echo "Возможные причины:"
        echo "1. Репозиторий не был создан"
        echo "2. Бэкап не был запущен"
        echo "3. Ошибка в конфигурации"
        return 1
    fi
    
    # Проверка размера
    BACKUP_SIZE=$(du -sh .config-backup | cut -f1)
    success "Размер бэкапа: $BACKUP_SIZE"
    
    # Проверка с помощью restic
    if command -v restic &> /dev/null; then
        export RESTIC_REPOSITORY=".config-backup"
        export RESTIC_PASSWORD="$RESTIC_PASSWORD"
        
        if restic snapshots &>/dev/null; then
            success "Репозиторий restic корректен"
            
            echo ""
            log "=== Информация о снапшотах ==="
            restic snapshots --compact
        else
            warning "Не удалось проверить репозиторий restic"
        fi
    else
        log "restic не установлен, используем Docker для проверки..."
        
        if docker run --rm \
            -v "$(pwd)/.config-backup:/repo" \
            -e RESTIC_REPOSITORY=/repo \
            -e RESTIC_PASSWORD="$RESTIC_PASSWORD" \
            restic/restic:latest \
            snapshots &>/dev/null; then
            
            success "Репозиторий restic корректен (проверено через Docker)"
        else
            warning "Не удалось проверить репозиторий через Docker"
        fi
    fi
    
    return 0
}

# Создание отчета о настройке
create_setup_report() {
    log "Создание отчета о настройке..."
    
    REPORT_FILE="backup-setup-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$REPORT_FILE" << EOF
# Отчет о настройке локального бэкапа ERNI-KI

**Дата настройки**: $(date)
**Хост**: $(hostname)

## ✅ Выполненные шаги

1. **Настройка Backrest**: Контейнер запущен и доступен
2. **Создание директории**: .config-backup создана и добавлена в .gitignore
3. **Конфигурация репозитория**: erni-ki-local
4. **План бэкапа**: erni-ki-critical-data
5. **Тестовый бэкап**: $([ -d ".config-backup" ] && [ "$(ls -A .config-backup)" ] && echo "Выполнен" || echo "Не выполнен")

## 📊 Статистика

- **Размер бэкапа**: $([ -d ".config-backup" ] && du -sh .config-backup | cut -f1 || echo "N/A")
- **URL Backrest**: http://localhost:9898
- **Пользователь**: admin

## 🔧 Конфигурация

### Репозиторий
- **ID**: erni-ki-local
- **Путь**: /backup-sources/.config-backup
- **Расписание очистки**: Ежедневно в 3:00
- **Проверка целостности**: Еженедельно в воскресенье в 4:00

### План бэкапа
- **ID**: erni-ki-critical-data
- **Расписание**: Ежедневно в 2:00
- **Retention**: 7 дней ежедневных, 4 недели еженедельных

### Пути для бэкапа
- env/ (переменные окружения)
- conf/ (конфигурации сервисов)
- data/postgres/ (база данных)
- data/openwebui/ (пользовательские данные)
- data/ollama/ (модели ИИ)

## 🚀 Следующие шаги

1. **Мониторинг**: Настройте алерты на неудачные бэкапы
2. **Тестирование**: Регулярно тестируйте восстановление
3. **Внешнее хранилище**: Рассмотрите настройку S3/B2 для дополнительной защиты
4. **Документация**: Ознакомьтесь с docs/local-backup-restore-guide.md

## 📚 Полезные команды

\`\`\`bash
# Проверка статуса бэкапа
./scripts/check-local-backup.sh

# Управление Backrest
./scripts/backrest-management.sh status

# Полная проверка с restic
./scripts/check-local-backup.sh --full
\`\`\`

## 🔐 Безопасность

- ✅ Пароли сохранены в .backrest_secrets
- ✅ Директория .config-backup исключена из Git
- ✅ Данные зашифрованы с помощью restic

---

**Важно**: Сохраните файл .backrest_secrets в безопасном месте!
EOF

    success "Отчет создан: $REPORT_FILE"
}

# Финальные инструкции
show_final_instructions() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           НАСТРОЙКА ЗАВЕРШЕНА!                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    success "Локальный бэкап ERNI-KI настроен и готов к использованию"
    echo ""
    echo "📋 ПОЛЕЗНЫЕ КОМАНДЫ:"
    echo ""
    echo "   ./scripts/check-local-backup.sh           # Проверка бэкапа"
    echo "   ./scripts/backrest-management.sh status   # Статус Backrest"
    echo "   ./scripts/check-local-backup.sh --report  # Детальный отчет"
    echo ""
    echo "📚 ДОКУМЕНТАЦИЯ:"
    echo ""
    echo "   docs/backrest-quick-setup-guide.md        # Быстрое руководство"
    echo "   docs/local-backup-restore-guide.md        # Руководство по восстановлению"
    echo ""
    echo "🌐 ВЕБ-ИНТЕРФЕЙС:"
    echo ""
    echo "   http://localhost:9898                      # Управление бэкапами"
    echo ""
    echo "🔐 УЧЕТНЫЕ ДАННЫЕ:"
    echo ""
    echo "   cat .backrest_secrets                      # Просмотр паролей"
    echo ""
    warning "ВАЖНО: Сохраните файл .backrest_secrets в безопасном месте!"
}

# Основная функция
main() {
    log "Запуск полной настройки локального бэкапа ERNI-KI..."
    
    check_prerequisites
    setup_backup_directory
    get_credentials
    show_setup_instructions
    
    # Открытие веб-интерфейса
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:9898" &>/dev/null &
    elif command -v open &> /dev/null; then
        open "http://localhost:9898" &>/dev/null &
    fi
    
    wait_for_setup
    
    if verify_backup; then
        create_setup_report
        show_final_instructions
    else
        echo ""
        warning "Бэкап не был создан или настроен неправильно"
        echo ""
        echo "Проверьте:"
        echo "1. Создан ли репозиторий в веб-интерфейсе"
        echo "2. Создан ли план бэкапа"
        echo "3. Выполнен ли тестовый бэкап"
        echo ""
        echo "Для повторной проверки запустите:"
        echo "  ./scripts/check-local-backup.sh"
    fi
}

# Запуск скрипта
main "$@"
