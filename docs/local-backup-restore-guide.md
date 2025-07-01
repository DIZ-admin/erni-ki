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
