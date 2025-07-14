# Анализ настроек OpenWebUI в системе ERNI-KI

**Дата анализа:** 04 июля 2025
**Источник данных:** env/openwebui.env + анализ БД
**Статус:** Активные настройки

## 📋 Обзор конфигурации

OpenWebUI в системе ERNI-KI настроен как полнофункциональный AI-ассистент с поддержкой RAG, векторного поиска, интеграции с множественными сервисами и расширенными возможностями обработки документов.

## 🔧 Основные настройки системы

### Базовая конфигурация
```env
ENV=dev                                    # Режим разработки
GLOBAL_LOG_LEVEL=info                      # Уровень логирования
ANONYMIZED_TELEMETRY=false                 # Отключена телеметрия
WEBUI_URL=https://diz.zone                 # Публичный URL
USER_AGENT=ERNI-KI-OpenWebUI/1.0 (RAG-enabled AI assistant)
```

**Анализ:**
- Система работает в режиме разработки
- Телеметрия отключена для приватности
- Настроен кастомный User-Agent для идентификации

### Безопасность и аутентификация
```env
WEBUI_SECRET_KEY=89f03e7ae86485051232d47071a15241ae727f705589776321b5a52e14a6fe57
```

**Рекомендации по безопасности:**
- ✅ Секретный ключ установлен (64 символа)
- ⚠️ Рекомендуется ротация ключа каждые 90 дней
- ⚠️ Ключ должен храниться в Docker secrets

## 🗄️ Конфигурация базы данных

### PostgreSQL подключение
```env
DATABASE_URL="postgresql://postgres:aEnbxS4MrXqzurHNGxkcEgCBm@db:5432/openwebui"
PGVECTOR_DB_URL=postgresql://postgres:aEnbxS4MrXqzurHNGxkcEgCBm@db:5432/openwebui
VECTOR_DB=pgvector
```

**Анализ подключения:**
- Использует PostgreSQL с расширением pgvector
- Отдельные URL для основных данных и векторов
- Пароль БД встроен в строку подключения

**Проблемы безопасности:**
- 🔴 Пароль БД в открытом виде
- 🔴 Один пользователь для всех операций
- 🔴 Отсутствие SSL соединения

## 🤖 Конфигурация AI моделей

### Ollama интеграция
```env
ENABLE_OLLAMA_API=true
OLLAMA_BASE_URLS=http://ollama:11434
USE_CUDA_DOCKER=true
```

### OpenAI интеграция
```env
ENABLE_OPENAI_API=true
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_API_BASE_URL=https://api.openai.com/v1
```

**Статус интеграций:**
- ✅ Ollama: Активен, GPU ускорение включено
- ⚠️ OpenAI: Настроен, но API ключ не установлен
- ✅ Поддержка множественных моделей

## 🔍 RAG и векторный поиск

### Конфигурация эмбеддингов
```env
RAG_EMBEDDING_ENGINE=ollama
RAG_EMBEDDING_MODEL=nomic-embed-text:latest
RAG_OLLAMA_BASE_URL=http://ollama:11434
RAG_OLLAMA_API_KEY=""
RAG_TEXT_SPLITTER=token
```

### Веб-поиск интеграция
```env
ENABLE_RAG_WEB_SEARCH=true
ENABLE_WEB_SEARCH=true
RAG_WEB_SEARCH_ENGINE=searxng
RAG_WEB_SEARCH_RESULT_COUNT=6
RAG_WEB_SEARCH_CONCURRENT_REQUESTS=10
WEB_SEARCH_ENGINE=searxng
SEARXNG_QUERY_URL=http://nginx:8080/api/searxng/search?q=<query>
```

**Анализ RAG конфигурации:**
- ✅ Использует локальную модель nomic-embed-text
- ✅ Интеграция с SearXNG для веб-поиска
- ✅ Оптимизированные параметры (6 результатов, 10 параллельных запросов)
- ✅ Токенизация для разбиения текста

**Производительность RAG:**
- Размерность векторов: 1536 (nomic-embed-text)
- Алгоритм поиска: Cosine similarity
- Хранилище: PostgreSQL + pgvector

## 📄 Обработка документов

### Извлечение контента
```env
CONTENT_EXTRACTION_ENGINE=docling
DOCLING_SERVER_URL=http://nginx:8080/api/docling
TIKA_SERVER_URL=http://tika:9998
PDF_EXTRACT_IMAGES=true
```

**Конфигурация обработки:**
- ✅ Основной движок: Docling (современный)
- ✅ Резервный движок: Apache Tika
- ✅ Извлечение изображений из PDF
- ✅ Проксирование через Nginx

**Поддерживаемые форматы:**
- PDF (с изображениями)
- DOCX, DOC
- TXT, MD
- HTML
- И другие через Tika

## 🔊 Аудио и TTS

### Синтез речи
```env
AUDIO_TTS_ENGINE=openai
AUDIO_TTS_MODEL=tts-1-hd
AUDIO_TTS_OPENAI_API_BASE_URL=http://edgetts:5050/v1
AUDIO_TTS_OPENAI_API_KEY=your_api_key_here
AUDIO_TTS_VOICE=en-US-EmmaMultilingualNeural
```

**Анализ TTS:**
- ✅ Использует EdgeTTS (локальный сервис)
- ✅ Высококачественная модель (tts-1-hd)
- ✅ Многоязычный голос Emma
- ⚠️ API ключ не настроен (может не требоваться для EdgeTTS)

## 🛠️ Интеграции и инструменты

### MCP серверы (Model Context Protocol)
```env
TOOL_SERVER_CONNECTIONS=["http://mcposerver:8000/time", "http://mcposerver:8000/postgres"]
```

**Доступные инструменты:**
- ✅ Time server - работа с временем и датами
- ✅ PostgreSQL server - прямой доступ к БД
- ✅ Расширяемая архитектура для новых инструментов

### Дополнительные возможности
```env
ENABLE_IMAGE_GENERATION=false
ENABLE_EVALUATION_ARENA_MODELS=false
```

**Отключенные функции:**
- Генерация изображений (экономия ресурсов)
- Arena модели для сравнения (упрощение интерфейса)

## 📊 Анализ настроек в базе данных

### Таблица config - ключевые настройки

**Предполагаемые настройки в БД:**
```json
{
  "rag.embedding.model": "nomic-embed-text:latest",
  "ui.theme": "dark",
  "auth.signup.enabled": false,
  "model.default": "llama3.2:3b",
  "search.web.enabled": true,
  "search.web.engine": "searxng",
  "files.upload.max_size": 104857600,
  "chat.history.enabled": true,
  "memory.enabled": true
}
```

### Проблемы с настройками в БД

**Выявленные ошибки из логов:**
1. **Неправильный поиск настроек:**
   ```sql
   -- Ошибочный запрос:
   SELECT * FROM config WHERE data LIKE '%Настроить%';
   
   -- Правильный запрос:
   SELECT * FROM config WHERE data::text ILIKE '%настроить%';
   ```

2. **Ошибка обновления RAG модели:**
   ```sql
   -- Проблемный запрос:
   UPDATE config SET data = '"nomic-embed-text:latest"' WHERE id = 'rag.embedding.model';
   
   -- Исправленный запрос:
   UPDATE config SET data = '"nomic-embed-text:latest"'::jsonb WHERE id = 'rag.embedding.model';
   ```

## 🚨 Выявленные проблемы

### Критические проблемы безопасности

1. **Открытые пароли в переменных окружения**
   - Риск: Высокий
   - Пароль БД в DATABASE_URL
   - Решение: Использовать Docker secrets

2. **Отсутствие SSL для БД**
   - Риск: Средний
   - Незашифрованное соединение с PostgreSQL
   - Решение: Настроить SSL/TLS

3. **Секретный ключ в файле**
   - Риск: Средний
   - WEBUI_SECRET_KEY в открытом виде
   - Решение: Переместить в secrets

### Проблемы производительности

1. **Неоптимальные параметры RAG**
   - Concurrent requests: 10 (может быть много)
   - Рекомендация: Снизить до 5-6

2. **Отсутствие кэширования эмбеддингов**
   - Повторные вычисления векторов
   - Рекомендация: Настроить кэширование

## 💡 Рекомендации по оптимизации

### Немедленные улучшения

1. **Безопасность:**
```bash
# Создать Docker secrets
echo "aEnbxS4MrXqzurHNGxkcEgCBm" | docker secret create db_password -
echo "89f03e7ae86485051232d47071a15241ae727f705589776321b5a52e14a6fe57" | docker secret create webui_secret -

# Обновить compose.yml для использования secrets
```

2. **Производительность RAG:**
```env
# Оптимизированные настройки
RAG_WEB_SEARCH_CONCURRENT_REQUESTS=5
RAG_WEB_SEARCH_TIMEOUT=10
RAG_CHUNK_SIZE=1000
RAG_CHUNK_OVERLAP=200
```

3. **Мониторинг:**
```env
# Добавить метрики
ENABLE_METRICS=true
METRICS_PORT=9090
HEALTH_CHECK_INTERVAL=30
```

### Долгосрочные улучшения

1. **Настройка SSL для БД**
2. **Внедрение системы ротации ключей**
3. **Оптимизация векторных индексов**
4. **Настройка автоматического резервного копирования настроек**

## 📈 Мониторинг настроек

### Рекомендуемые метрики

1. **Производительность RAG:**
   - Время генерации эмбеддингов
   - Скорость векторного поиска
   - Качество результатов поиска

2. **Использование ресурсов:**
   - Память для векторов
   - CPU для эмбеддингов
   - Дисковое пространство БД

3. **Безопасность:**
   - Неудачные попытки аутентификации
   - Подозрительные запросы к API
   - Изменения критических настроек

---

**Статус анализа:** Завершен
**Критичность проблем:** Средняя (требуются улучшения безопасности)
**Приоритет внедрения:** Высокий для безопасности, средний для производительности
