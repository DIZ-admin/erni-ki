# Универсальное исправление прав доступа для Snyk сканера

## 🎯 Обзор проблемы

Snyk сканер безопасности не мог получить доступ к различным директориям в
`data/` из-за ошибок "EACCES: permission denied". Проблемы возникали с:

- `/data/backrest/repos/erni-ki-local`
- `/data/grafana/alerting/1`
- Другими директориями, создаваемыми Docker контейнерами с правами root

## 🔍 Анализ проблемы

### Исходные права доступа

**Backrest:**

```bash
drwxr--r--  3 root root 4096 Jul 14 09:00 repos
drwxr--r--  7 root root 4096 Jul 14 09:00 erni-ki-local
```

**Grafana:**

```bash
drwxr-xr--  3 472 root 4096 Jul 17 13:44 alerting
drwxr--r--  2 472 root 4096 Jul 17 13:44 csv
drwxr--r--  2 472 root 4096 Jul 17 13:44 png
```

**Проблема**: Права `744` и `754` (drwxr--r--, drwxr-xr--) не предоставляют
право на выполнение (execute) для "остальных" пользователей, что не позволяет
Snyk войти в директорию.

### Причина возникновения

- Docker контейнеры (Backrest, Grafana) запускаются с пользователем root или
  специальными UID
- Директории создаются с ограничительными правами по умолчанию
- Snyk сканер работает от имени пользователя konstantin
- Различные сервисы используют разные стратегии безопасности для своих данных

## ✅ Решение

### 1. Универсальное исправление прав доступа

```bash
# Автоматическое исправление всех проблемных директорий
sudo ./scripts/maintenance/fix-data-permissions.sh

# Или ручное исправление конкретных директорий:
sudo chmod 755 data/backrest/repos
sudo chmod -R 755 data/backrest/repos/erni-ki-local
sudo chmod -R 755 data/grafana/alerting
sudo chmod 755 data/grafana/csv data/grafana/png
```

### 2. Результат исправления

**Backrest:**

```bash
drwxr-xr-x  3 root root 4096 Jul 14 09:00 repos
drwxr-xr-x  7 root root 4096 Jul 14 09:00 erni-ki-local
```

**Grafana:**

```bash
drwxr-xr-x  3 472 root 4096 Jul 17 13:44 alerting
drwxr-xr-x  2 472 root 4096 Jul 17 13:44 csv
drwxr-xr-x  2 472 root 4096 Jul 17 13:44 png
```

**Права `755` (drwxr-xr-x)**:

- Владелец (root): чтение, запись, выполнение
- Группа: чтение, выполнение
- Остальные: чтение, выполнение

## 🛡️ Безопасность

### Сохранённая безопасность

- ✅ Только root может изменять файлы Backrest
- ✅ Другие пользователи имеют только доступ на чтение
- ✅ Структура репозитория остаётся защищённой
- ✅ Шифрование данных Backrest не затронуто

### Конфигурация Snyk

Файл `.snyk` уже содержит правильные исключения:

```yaml
exclude:
  - data/** # Покрывает data/backrest/repos/
  - .config-backup/**
```

## 🔧 Автоматизация

### Универсальный скрипт исправления

Создан скрипт `scripts/maintenance/fix-data-permissions.sh` для:

- Автоматического поиска и исправления всех проблемных директорий в `data/`
- Проверки работоспособности всех сервисов (Backrest, Grafana, PostgreSQL)
- Создания подробных отчётов об исправлениях
- Поддержки различных стратегий прав доступа для разных сервисов

### Использование

```bash
sudo ./scripts/maintenance/fix-data-permissions.sh
```

## ✅ Проверка решения

### 1. Доступ к директориям

```bash
# Проверка Backrest
ls -la data/backrest/repos/erni-ki-local/
# Проверка Grafana
ls -la data/grafana/alerting/1/
# Должны показать содержимое без ошибок
```

### 2. Работа сервисов

```bash
# Backrest
curl -s http://localhost:9898/ | head -5
# Grafana
curl -s http://localhost:3000/api/health
# Должны вернуть корректные ответы
```

### 3. Snyk сканирование

```bash
# Проверка доступа ко всем ранее проблемным директориям
find data/grafana/alerting/1 -type f | wc -l
find data/backrest/repos/erni-ki-local -type f | wc -l
# Должны показать количество файлов без ошибок доступа
```

## 🔄 Предотвращение повторения

### Мониторинг прав доступа

Добавить в cron проверку прав доступа:

```bash
# Ежедневная проверка в 06:00
0 6 * * * /path/to/erni-ki/scripts/maintenance/fix-backrest-permissions.sh
```

### Документация для команды

- При обновлении Backrest проверять права доступа
- При возникновении ошибок доступа использовать готовый скрипт
- Сохранять логи исправлений в `logs/`

## 📊 Результаты

### До исправления

- ❌ Snyk: "EACCES: permission denied" для data/backrest/repos/erni-ki-local
- ❌ Snyk: "EACCES: permission denied" для data/grafana/alerting/1
- ❌ Невозможность сканирования безопасности
- ❌ Ограниченный доступ к данным сервисов

### После исправления

- ✅ Snyk сканирует проект без ошибок доступа
- ✅ Все сервисы (Backrest, Grafana, PostgreSQL) продолжают работать корректно
- ✅ Безопасность данных сохранена (только чтение для других пользователей)
- ✅ Универсальное автоматизированное решение готово
- ✅ PostgreSQL корректно исключён из сканирования (требует строгие права)

## 🔗 Связанные документы

- [Backrest Integration](backrest-integration.md)
- [Local Backup Restore Guide](local-backup-restore-guide.md)
- [Security Configuration](security-configuration.md)

---

**Статус**: ✅ Решено **Дата**: 2025-08-04 **Автор**: Альтэон Шульц (Tech Lead)
**Версия**: 1.0
