#!/bin/bash
# Скрипт настройки локального бэкапа ERNI-KI через Backrest
# Создает репозиторий и план бэкапа для критических данных

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

# Конфигурация
BACKREST_URL="http://localhost:9898"
REPO_ID="erni-ki-local"
REPO_PATH="/backup-sources/.config-backup"
PLAN_ID="erni-ki-critical-data"

# Получение учетных данных
get_credentials() {
    if [ -f ".backrest_secrets" ]; then
        BACKREST_PASSWORD=$(grep "BACKREST_PASSWORD=" .backrest_secrets | cut -d'=' -f2)
        RESTIC_PASSWORD=$(grep "RESTIC_PASSWORD=" .backrest_secrets | cut -d'=' -f2)

        if [ -z "$BACKREST_PASSWORD" ] || [ -z "$RESTIC_PASSWORD" ]; then
            error "Не удалось получить учетные данные из .backrest_secrets"
        fi

        success "Учетные данные загружены"
    else
        error "Файл .backrest_secrets не найден. Запустите сначала ./scripts/backrest-setup.sh"
    fi
}

# Проверка доступности Backrest
check_backrest() {
    log "Проверка доступности Backrest..."

    if ! curl -s -o /dev/null -w "%{http_code}" "$BACKREST_URL/" | grep -q "200"; then
        error "Backrest недоступен по адресу $BACKREST_URL"
    fi

    success "Backrest доступен"
}

# Создание репозитория через веб-интерфейс (инструкции)
create_repository_instructions() {
    log "Создание локального репозитория..."

    echo ""
    echo "=== ИНСТРУКЦИИ ПО СОЗДАНИЮ РЕПОЗИТОРИЯ ==="
    echo ""
    echo "1. Откройте веб-интерфейс Backrest: $BACKREST_URL"
    echo "2. Войдите с учетными данными:"
    echo "   - Пользователь: admin"
    echo "   - Пароль: $BACKREST_PASSWORD"
    echo ""
    echo "3. Нажмите 'Add Repository' и заполните:"
    echo "   - Repository ID: $REPO_ID"
    echo "   - Repository URI: $REPO_PATH"
    echo "   - Password: $RESTIC_PASSWORD"
    echo ""
    echo "4. В разделе 'Prune Policy' установите:"
    echo "   - Schedule: 0 3 * * * (ежедневно в 3:00)"
    echo "   - Max Unused Bytes: 1GB"
    echo ""
    echo "5. В разделе 'Check Policy' установите:"
    echo "   - Schedule: 0 4 * * 0 (еженедельно в воскресенье в 4:00)"
    echo ""
    echo "6. Нажмите 'Create Repository'"
    echo ""
}

# Создание плана бэкапа (инструкции)
create_backup_plan_instructions() {
    log "Создание плана бэкапа..."

    echo ""
    echo "=== ИНСТРУКЦИИ ПО СОЗДАНИЮ ПЛАНА БЭКАПА ==="
    echo ""
    echo "1. После создания репозитория нажмите 'Add Plan'"
    echo ""
    echo "2. Заполните основные настройки:"
    echo "   - Plan ID: $PLAN_ID"
    echo "   - Repository: $REPO_ID"
    echo ""
    echo "3. В разделе 'Paths' добавьте:"
    echo "   - /backup-sources/env"
    echo "   - /backup-sources/conf"
    echo "   - /backup-sources/data/postgres"
    echo "   - /backup-sources/data/openwebui"
    echo "   - /backup-sources/data/ollama"
    echo ""
    echo "4. В разделе 'Excludes' добавьте:"
    echo "   - *.log"
    echo "   - *.tmp"
    echo "   - **/cache/**"
    echo "   - **/temp/**"
    echo "   - **/.git/**"
    echo "   - **/node_modules/**"
    echo ""
    echo "5. В разделе 'Schedule' установите:"
    echo "   - Schedule: 0 2 * * * (ежедневно в 2:00)"
    echo ""
    echo "6. В разделе 'Retention Policy' выберите 'Time-based' и установите:"
    echo "   - Keep Daily: 7"
    echo "   - Keep Weekly: 4"
    echo "   - Keep Monthly: 0"
    echo "   - Keep Yearly: 0"
    echo ""
    echo "7. Нажмите 'Create Plan'"
    echo ""
}

# Создание тестового бэкапа (инструкции)
create_test_backup_instructions() {
    log "Создание тестового бэкапа..."

    echo ""
    echo "=== ИНСТРУКЦИИ ПО СОЗДАНИЮ ТЕСТОВОГО БЭКАПА ==="
    echo ""
    echo "1. После создания плана перейдите на страницу 'Plans'"
    echo "2. Найдите план '$PLAN_ID'"
    echo "3. Нажмите кнопку 'Backup Now' рядом с планом"
    echo "4. Дождитесь завершения операции бэкапа"
    echo "5. Проверьте, что в директории .config-backup/ появились файлы"
    echo ""
}

# Проверка созданного бэкапа
check_backup() {
    log "Проверка созданного бэкапа..."

    if [ -d ".config-backup" ] && [ "$(ls -A .config-backup 2>/dev/null)" ]; then
        success "Директория .config-backup содержит данные бэкапа"
        echo "Содержимое директории:"
        ls -la .config-backup/
    else
        warning "Директория .config-backup пуста или не содержит данных бэкапа"
        echo "Убедитесь, что вы создали и запустили план бэкапа через веб-интерфейс"
    fi
}

# Создание инструкций по восстановлению
create_restore_instructions() {
    log "Создание инструкций по восстановлению..."

    cat > docs/local-backup-restore-guide.md << 'EOF'
# Руководство по восстановлению из локального бэкапа ERNI-KI

## 🎯 Обзор

Данное руководство описывает процедуры восстановления данных из локального бэкапа, созданного с помощью Backrest в директории `.config-backup/`.

## 📋 Что включено в бэкап

- **Конфигурационные файлы**: `env/` и `conf/`
- **База данных PostgreSQL**: `data/postgres/`
- **Данные Open WebUI**: `data/openwebui/`
- **Модели Ollama**: `data/ollama/`

## 🔧 Восстановление через веб-интерфейс Backrest

### 1. Доступ к интерфейсу восстановления

1. Откройте http://localhost:9898
2. Войдите с учетными данными из `.backrest_secrets`
3. Перейдите в раздел "Snapshots"
4. Выберите нужный снапшот для восстановления

### 2. Восстановление отдельных файлов

1. В списке снапшотов нажмите "Browse"
2. Навигируйте к нужным файлам
3. Выберите файлы для восстановления
4. Нажмите "Restore" и укажите путь назначения

### 3. Полное восстановление системы

1. Остановите все сервисы ERNI-KI:
   ```bash
   docker-compose down
   ```

2. Создайте резервную копию текущих данных:
   ```bash
   mv data data.backup.$(date +%Y%m%d_%H%M%S)
   mv env env.backup.$(date +%Y%m%d_%H%M%S)
   mv conf conf.backup.$(date +%Y%m%d_%H%M%S)
   ```

3. Восстановите данные через Backrest веб-интерфейс:
   - Выберите последний успешный снапшот
   - Восстановите каждую директорию в соответствующее место
   - Убедитесь, что права доступа корректны

4. Запустите сервисы:
   ```bash
   docker-compose up -d
   ```

## 🛠️ Восстановление через командную строку

### 1. Прямое использование restic

```bash
# Установка переменных окружения
export RESTIC_REPOSITORY="/path/to/.config-backup"
export RESTIC_PASSWORD="your_restic_password_from_.backrest_secrets"

# Просмотр доступных снапшотов
restic snapshots

# Восстановление конкретного снапшота
restic restore latest --target ./restore-temp

# Восстановление конкретных файлов
restic restore latest --target ./restore-temp --include "*/env/*"
```

### 2. Использование Docker контейнера Backrest

```bash
# Вход в контейнер Backrest
docker-compose exec backrest sh

# Внутри контейнера
export RESTIC_REPOSITORY="/backup-sources/.config-backup"
export RESTIC_PASSWORD="your_restic_password"

# Просмотр снапшотов
restic snapshots

# Восстановление
restic restore latest --target /tmp/restore
```

## 🚨 Процедуры экстренного восстановления

### Сценарий 1: Потеря конфигурационных файлов

```bash
# 1. Остановка сервисов
docker-compose down

# 2. Восстановление конфигураций
# Через веб-интерфейс Backrest восстановите:
# - /backup-sources/env -> ./env
# - /backup-sources/conf -> ./conf

# 3. Проверка и запуск
docker-compose up -d
```

### Сценарий 2: Повреждение базы данных

```bash
# 1. Остановка сервисов
docker-compose down

# 2. Резервное копирование поврежденной БД
mv data/postgres data/postgres.corrupted.$(date +%Y%m%d_%H%M%S)

# 3. Восстановление БД из бэкапа
# Через Backrest восстановите /backup-sources/data/postgres -> ./data/postgres

# 4. Проверка прав доступа
sudo chown -R 999:999 data/postgres

# 5. Запуск сервисов
docker-compose up -d db
# Дождитесь запуска БД, затем запустите остальные сервисы
docker-compose up -d
```

### Сценарий 3: Потеря моделей Ollama

```bash
# 1. Остановка Ollama
docker-compose stop ollama

# 2. Восстановление моделей
# Через Backrest восстановите /backup-sources/data/ollama -> ./data/ollama

# 3. Проверка прав доступа
sudo chown -R 1000:1000 data/ollama

# 4. Запуск Ollama
docker-compose start ollama
```

## ✅ Проверка успешности восстановления

### 1. Проверка сервисов

```bash
# Статус всех контейнеров
docker-compose ps

# Проверка логов
docker-compose logs --tail=50
```

### 2. Проверка функциональности

1. **Open WebUI**: http://localhost (или ваш домен)
2. **Backrest**: http://localhost:9898
3. **База данных**:
   ```bash
   docker-compose exec db psql -U postgres -d openwebui -c "SELECT COUNT(*) FROM users;"
   ```

### 3. Проверка данных

- Убедитесь, что пользователи могут войти в систему
- Проверьте доступность загруженных моделей Ollama
- Убедитесь, что чаты и настройки сохранены

## 📝 Рекомендации

1. **Регулярное тестирование**: Проводите тестовое восстановление ежемесячно
2. **Документирование**: Ведите журнал всех операций восстановления
3. **Мониторинг**: Настройте алерты на неудачные бэкапы
4. **Безопасность**: Храните пароли шифрования в безопасном месте

## 🆘 Поддержка

При возникновении проблем с восстановлением:

1. Проверьте логи Backrest: `docker-compose logs backrest`
2. Убедитесь в целостности бэкапа: `restic check`
3. Обратитесь к документации Backrest: https://garethgeorge.github.io/backrest/
4. Проверьте права доступа к файлам и директориям

---

**Важно**: Всегда создавайте резервную копию текущих данных перед восстановлением!
EOF

    success "Создано руководство по восстановлению: docs/local-backup-restore-guide.md"
}

# Основная функция
main() {
    log "Настройка локального бэкапа ERNI-KI..."

    get_credentials
    check_backrest
    create_repository_instructions
    create_backup_plan_instructions
    create_test_backup_instructions
    create_restore_instructions

    echo ""
    success "Настройка локального бэкапа завершена!"
    echo ""
    warning "СЛЕДУЮЩИЕ ШАГИ:"
    echo "1. Откройте веб-интерфейс Backrest: $BACKREST_URL"
    echo "2. Следуйте инструкциям выше для создания репозитория и плана"
    echo "3. Создайте тестовый бэкап"
    echo "4. Проверьте содержимое директории .config-backup/"
    echo ""
    echo "Учетные данные для входа:"
    echo "- Пользователь: admin"
    echo "- Пароль: $BACKREST_PASSWORD"
}

# Запуск скрипта
main "$@"
