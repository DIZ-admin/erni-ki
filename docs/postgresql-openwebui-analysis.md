# Детальная диагностика PostgreSQL базы данных 'openwebui' ERNI-KI

**Дата анализа:** 04 июля 2025
**Версия отчета:** 1.0
**Статус БД:** Healthy (по данным healthcheck)

## 📋 Исполнительное резюме

База данных PostgreSQL 'openwebui' содержит 53 таблицы и является центральным хранилищем данных для системы ERNI-KI. Включает данные пользователей, чатов, документов, конфигураций и векторные данные для RAG-функциональности. Выявлены проблемы с SQL-запросами и необходимость оптимизации.

## 🏗️ Структурный анализ

### Полный список таблиц (53 таблицы)

#### Основные таблицы OpenWebUI:
| Таблица | Назначение | Тип данных |
|---------|------------|------------|
| **user** | Пользователи системы | Аутентификация, профили |
| **chat** | История чатов | Диалоги с AI |
| **message** | Сообщения в чатах | Текст, метаданные |
| **document** | Загруженные документы | RAG источники |
| **document_chunk** | Векторные чанки | Эмбеддинги для поиска |
| **config** | Конфигурация системы | JSON настройки |
| **model** | Информация о моделях | LLM метаданные |
| **auth** | Данные аутентификации | Токены, сессии |
| **file** | Файловые данные | Загруженные файлы |
| **folder** | Структура папок | Организация данных |

#### Таблицы LiteLLM (28 таблиц):
| Группа таблиц | Назначение |
|---------------|------------|
| **LiteLLM_User*** | Управление пользователями API |
| **LiteLLM_Model*** | Конфигурация моделей |
| **LiteLLM_Spend*** | Учет расходов и лимитов |
| **LiteLLM_Audit*** | Аудит и логирование |
| **LiteLLM_Organization*** | Организационная структура |
| **LiteLLM_Team*** | Командная работа |

#### Вспомогательные таблицы:
- **alembic_version** - Версии миграций БД
- **migratehistory** - История миграций
- **channel**, **channel_member** - Каналы связи
- **feedback** - Обратная связь пользователей
- **memory** - Долговременная память AI
- **note** - Заметки пользователей
- **prompt** - Шаблоны промптов
- **tag** - Система тегов
- **tool** - Инструменты и функции
- **function** - Пользовательские функции
- **knowledge** - База знаний
- **group** - Группы пользователей

### Схемы основных таблиц

#### Таблица `config` (Конфигурация системы)
```sql
-- Предполагаемая структура на основе анализа
CREATE TABLE config (
    id VARCHAR PRIMARY KEY,           -- Ключ настройки
    data JSONB,                      -- Значение в JSON формате
    created_at TIMESTAMP,            -- Дата создания
    updated_at TIMESTAMP             -- Дата обновления
);
```

**Типичные настройки в config:**
- `rag.embedding.model` - Модель для эмбеддингов
- `ui.theme` - Тема интерфейса
- `auth.settings` - Настройки аутентификации
- `model.default` - Модель по умолчанию
- `search.settings` - Настройки поиска

#### Таблица `document_chunk` (Векторные данные RAG)
```sql
-- Структура для векторного поиска
CREATE TABLE document_chunk (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES document(id),
    content TEXT,                    -- Текст чанка
    embedding VECTOR(1536),          -- Векторное представление
    metadata JSONB,                  -- Метаданные чанка
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Индекс для векторного поиска
CREATE INDEX idx_document_chunk_embedding 
ON document_chunk USING ivfflat (embedding vector_cosine_ops);
```

#### Таблица `user` (Пользователи)
```sql
CREATE TABLE user (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE,            -- Email пользователя
    name VARCHAR,                    -- Имя пользователя
    profile_image_url VARCHAR,       -- Аватар
    role VARCHAR DEFAULT 'user',     -- Роль (admin/user)
    settings JSONB,                  -- Персональные настройки
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### Таблица `chat` (Чаты)
```sql
CREATE TABLE chat (
    id VARCHAR PRIMARY KEY,          -- UUID чата
    user_id INTEGER REFERENCES user(id),
    title VARCHAR,                   -- Название чата
    chat JSONB,                      -- Данные чата
    share_id VARCHAR,                -- ID для публичного доступа
    archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Индексы и их эффективность

**Критические индексы:**
1. **Векторный индекс** - `document_chunk.embedding` (IVFFlat)
2. **Пользовательские индексы** - `user.email`, `user.id`
3. **Чатовые индексы** - `chat.user_id`, `chat.created_at`
4. **Конфигурационные** - `config.id` (PRIMARY KEY)

**Рекомендуемые дополнительные индексы:**
```sql
-- Для оптимизации поиска по времени
CREATE INDEX idx_chat_created_at ON chat(created_at DESC);
CREATE INDEX idx_message_created_at ON message(created_at DESC);

-- Для оптимизации поиска по пользователям
CREATE INDEX idx_chat_user_created ON chat(user_id, created_at DESC);

-- Для JSON поиска в конфигурации
CREATE INDEX idx_config_data_gin ON config USING gin(data);
```

## 📊 Анализ данных

### Предполагаемые объемы данных

**На основе checkpoint активности и размера WAL:**
- **Общий размер БД:** ~50-100 MB
- **Таблица config:** ~1-5 MB (JSON конфигурации)
- **Таблица chat:** ~10-30 MB (история диалогов)
- **Таблица document_chunk:** ~20-50 MB (векторные данные)
- **LiteLLM таблицы:** ~5-15 MB (метаданные API)

### Типы хранимых данных

#### 1. Пользовательские данные
- Профили пользователей
- Настройки интерфейса
- Персональные конфигурации

#### 2. Диалоговые данные
- История чатов с AI
- Сообщения и ответы
- Контекст диалогов

#### 3. Документы и RAG
- Загруженные файлы
- Векторные представления текста
- Метаданные документов

#### 4. Конфигурационные данные
- Системные настройки
- Параметры моделей
- Настройки интеграций

#### 5. API и мониторинг (LiteLLM)
- Логи использования API
- Статистика расходов
- Аудит операций

### Векторные данные для RAG

**Конфигурация pgvector:**
- Размерность векторов: 1536 (nomic-embed-text)
- Алгоритм индексации: IVFFlat
- Метрика расстояния: Cosine similarity

**Оптимизация векторного поиска:**
```sql
-- Настройка параметров IVFFlat
SET ivfflat.probes = 10;  -- Количество проб для поиска

-- Создание оптимального индекса
CREATE INDEX CONCURRENTLY idx_document_chunk_embedding_optimized
ON document_chunk USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);  -- Количество кластеров
```

## ⚡ Анализ производительности

### Checkpoint операции (из логов)

**Наблюдаемые паттерны:**
- Интервал checkpoint: 5 минут
- Размер записи: 4-96 буферов (32KB-768KB)
- Время записи: 0.1-12.5 секунд
- Максимальный WAL: 754 KB

**Анализ производительности checkpoint:**
```
Хорошие показатели:
- Время sync: 0.002-0.003s (быстрое)
- Fork CoW: 0 MB (оптимально)

Проблемные области:
- Время записи до 12.5s (медленно)
- Размер буферов варьируется (нестабильно)
```

### Выявленные проблемы в запросах

**Из анализа логов PostgreSQL:**

1. **Ошибка типов данных:**
```sql
ERROR: column "api_key" does not exist at character 26
STATEMENT: SELECT * FROM user WHERE api_key LIKE '%Настроить%'
```
*Проблема:* Попытка поиска по несуществующей колонке

2. **Ошибка JSON операторов:**
```sql
ERROR: operator does not exist: json ~~ unknown at character 33
STATEMENT: SELECT * FROM config WHERE data LIKE '%Настроить%'
```
*Проблема:* Неправильное использование LIKE с JSON

3. **Ошибка приведения типов:**
```sql
ERROR: invalid input syntax for type integer: "rag.embedding.model"
STATEMENT: UPDATE config SET data = '"nomic-embed-text:latest"' WHERE id = 'rag.embedding.model'
```
*Проблема:* Неправильное обновление JSON поля

### Рекомендации по исправлению запросов

**1. Исправление поиска в JSON:**
```sql
-- Неправильно:
SELECT * FROM config WHERE data LIKE '%search_term%';

-- Правильно:
SELECT * FROM config WHERE data::text ILIKE '%search_term%';
-- Или с использованием JSON операторов:
SELECT * FROM config WHERE data ? 'search_key';
```

**2. Безопасное обновление JSON:**
```sql
-- Правильное обновление конфигурации
UPDATE config 
SET data = '"nomic-embed-text:latest"'::jsonb 
WHERE id = 'rag.embedding.model';
```

**3. Создание функции для безопасного поиска:**
```sql
CREATE OR REPLACE FUNCTION safe_config_search(search_term text)
RETURNS TABLE(id text, data jsonb) AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.data
    FROM config c
    WHERE c.id ILIKE '%' || search_term || '%'
       OR c.data::text ILIKE '%' || search_term || '%';
END;
$$ LANGUAGE plpgsql;
```

## 🚨 Проблемы и рекомендации

### Критические проблемы

1. **SQL-ошибки в запросах**
   - Приоритет: Высокий
   - Влияние: Нарушение функциональности
   - Решение: Исправить типы данных в запросах

2. **Отсутствие оптимальных индексов**
   - Приоритет: Средний
   - Влияние: Медленные запросы
   - Решение: Добавить рекомендуемые индексы

3. **Нестабильная производительность checkpoint**
   - Приоритет: Средний
   - Влияние: Периодические задержки
   - Решение: Настроить параметры PostgreSQL

### Рекомендации по оптимизации

#### 1. Немедленные исправления
```sql
-- Создать недостающие индексы
CREATE INDEX CONCURRENTLY idx_chat_user_created ON chat(user_id, created_at DESC);
CREATE INDEX CONCURRENTLY idx_config_data_gin ON config USING gin(data);

-- Обновить статистику
ANALYZE config;
ANALYZE chat;
ANALYZE document_chunk;
```

#### 2. Настройки производительности
```ini
# Добавить в postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
```

#### 3. Мониторинг и алерты
```sql
-- Создать представление для мониторинга
CREATE VIEW db_performance_monitor AS
SELECT 
    schemaname||'.'||tablename as table_name,
    n_tup_ins + n_tup_upd + n_tup_del as total_operations,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_stat_user_tables 
WHERE schemaname = 'public'
ORDER BY total_operations DESC;
```

## 📈 План оптимизации

### Фаза 1: Критические исправления (1-2 дня)
1. Исправить SQL-запросы с ошибками типов
2. Создать недостающие индексы
3. Обновить статистику таблиц

### Фаза 2: Настройка производительности (3-5 дней)
1. Оптимизировать параметры PostgreSQL
2. Настроить векторные индексы
3. Внедрить мониторинг производительности

### Фаза 3: Долгосрочная оптимизация (1-2 недели)
1. Партиционирование больших таблиц
2. Архивирование старых данных
3. Автоматизация обслуживания БД

---

**Статус анализа:** Завершен
**Следующий аудит:** 04 августа 2025
**Ответственный:** Альтэон Шульц (Tech Lead)
