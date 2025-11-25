# SQL Скрипты для диагностики ERNI-KI

Коллекция SQL скриптов для анализа и диагностики базы данных PostgreSQL системы
ERNI-KI.

## Доступные скрипты

### `analyze-openwebui-config.sql`

**Назначение:** Анализ настроек OpenWebUI в базе данных PostgreSQL
**Использование:**

```bash
# Подключение к базе данных и выполнение скрипта
docker exec -i erni-ki-db-1 psql -U postgres -d openwebui -f /path/to/analyze-openwebui-config.sql

# Или через psql клиент
psql -h localhost -U postgres -d openwebui -f scripts/core/diagnostics/sql/analyze-openwebui-config.sql
```

**Что анализирует:**

- Все настройки из таблицы config
- Настройки RAG и эмбеддингов
- Настройки моделей
- Настройки пользователей и аутентификации
- Настройки интеграций (SearXNG, Ollama)

**Пример вывода:**

```
=== НАСТРОЙКИ OPENWEBUI ===
 setting_key | setting_value | created_at | updated_at
-------------+---------------+------------+------------
 rag.enabled | true | 2025-08-29 | 2025-08-29
```

## Как использовать

### Подготовка

1. Убедитесь, что контейнер PostgreSQL запущен
2. Проверьте доступность базы данных:

```bash
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "SELECT version();"
```

### Выполнение скриптов

```bash
# Метод 1: Через docker exec
docker exec -i erni-ki-db-1 psql -U postgres -d openwebui < scripts/core/diagnostics/sql/analyze-openwebui-config.sql

# Метод 2: Через psql клиент (если установлен локально)
PGPASSWORD=your_password psql -h localhost -p 5432 -U postgres -d openwebui -f scripts/core/diagnostics/sql/analyze-openwebui-config.sql

# Метод 3: Интерактивный режим
docker exec -it erni-ki-db-1 psql -U postgres -d openwebui
\i /path/to/analyze-openwebui-config.sql
```

## Интерпретация результатов

### Настройки RAG

- `rag.enabled` - включен ли RAG
- `rag.template` - шаблон для RAG запросов
- `embedding.model` - модель для эмбеддингов

### Настройки моделей

- `models.default` - модель по умолчанию
- `models.available` - доступные модели

### Настройки интеграций

- `searxng.url` - URL SearXNG сервиса
- `ollama.url` - URL Ollama API

## Безопасность

**Внимание:** SQL скрипты могут содержать чувствительную информацию из базы
данных.

- Не выполняйте скрипты на production без понимания их содержимого
- Результаты могут содержать пароли и API ключи
- Используйте только для диагностики и отладки

## Добавление новых скриптов

При добавлении новых SQL скриптов:

1. Поместите файл в эту директорию
2. Добавьте описание в этот README.md
3. Используйте комментарии в SQL для объяснения логики
4. Тестируйте на тестовой базе данных

### Шаблон нового скрипта:

```sql
-- Описание скрипта
-- Автор: Имя автора
-- Дата: YYYY-MM-DD

\echo '=== НАЗВАНИЕ АНАЛИЗА ==='
SELECT
 column1,
 column2
FROM table_name
WHERE condition
ORDER BY column1;
```
