---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Поток данных

## Основные потоки данных в ERNI-KI

```mermaid
flowchart TB
    subgraph UserRequest["Пользовательский запрос"]
        User["Пользователь"] --> Browser["Браузер"]
        Browser --> |"HTTPS"| CF["Cloudflare Tunnel"]
        CF --> |"HTTP"| Nginx["Nginx"]
        Nginx --> |"JWT проверка"| Auth["Auth Service"]
        Auth --> |"Token"| Nginx
        Nginx --> |"HTTP"| OpenWebUI["Open WebUI"]
    end

    subgraph LLMProcessing["Обработка LLM запроса"]
        OpenWebUI --> |"Prompt + Context"| LiteLLM["LiteLLM Gateway"]
        LiteLLM --> |"Model Request"| Ollama["Ollama"]
        Ollama --> |"LLM Response"| LiteLLM
        LiteLLM --> |"Response"| OpenWebUI
    end

    subgraph SearchRAG["Поиск и RAG"]
        OpenWebUI --> |"Search Query"| SearXNG["SearXNG"]
        SearXNG --> |"Cache Check"| Redis["Redis"]
        Redis --> |"Cached Results"| SearXNG
        SearXNG --> |"Web Search"| Internet["Интернет"]
        Internet --> |"Results"| SearXNG
        SearXNG --> |"Results"| OpenWebUI

        OpenWebUI --> |"Vector Query"| PostgreSQL["PostgreSQL | (pgvector)"]
        PostgreSQL --> |"Similar Docs"| OpenWebUI
    end

    subgraph DocProcessing["Обработка документов"]
        OpenWebUI --> |"Upload File"| Tika["Apache Tika"]
        Tika --> |"Extracted Text"| OpenWebUI

        OpenWebUI --> |"PDF/Image"| Docling["Docling OCR"]
        Docling --> |"GPU Processing"| GPU["RTX 5000"]
        GPU --> |"OCR Result"| Docling
        Docling --> |"Structured Data"| OpenWebUI

        OpenWebUI --> |"Store Embeddings"| PostgreSQL
    end

    subgraph TTS["Синтез речи"]
        OpenWebUI --> |"Text"| EdgeTTS["EdgeTTS"]
        EdgeTTS --> |"Audio Stream"| OpenWebUI
    end

    subgraph Persistence["Персистентность"]
        OpenWebUI --> |"Save Chat"| PostgreSQL
        OpenWebUI --> |"Cache Data"| Redis
        LiteLLM --> |"Log Requests"| PostgreSQL
    end

    subgraph Monitoring["Мониторинг"]
        OpenWebUI --> |"Metrics"| Prometheus["Prometheus"]
        LiteLLM --> |"Metrics"| Prometheus
        Ollama --> |"Metrics"| Prometheus
        PostgreSQL --> |"Metrics"| PostgresExporter["PostgreSQL Exporter"]
        PostgresExporter --> |"Metrics"| Prometheus
        Redis --> |"Metrics"| RedisExporter["Redis Exporter"]
        RedisExporter --> |"Metrics"| Prometheus

        Prometheus --> |"Query"| Grafana["Grafana"]
        Prometheus --> |"Alerts"| Alertmanager["Alertmanager"]

        FluentBit["Fluent Bit"] --> |"Logs"| Loki["Loki"]
        Loki --> |"Query"| Grafana
    end

    subgraph Backup["Резервное копирование"]
        Backrest["Backrest"] --> |"Backup"| PostgreSQL
        Backrest --> |"Backup"| Redis
        Backrest --> |"Backup Files"| Storage["Local Storage"]
    end
```

## Описание потоков

### 1. Пользовательский запрос

1. Пользователь отправляет запрос через браузер
2. Cloudflare Tunnel обеспечивает безопасное соединение
3. Nginx проверяет JWT токен через Auth Service
4. Запрос передается в Open WebUI

### 2. Обработка LLM запроса

1. Open WebUI формирует промпт с контекстом
2. LiteLLM Gateway маршрутизирует запрос к Ollama
3. Ollama генерирует ответ на GPU
4. Ответ возвращается пользователю

### 3. Поиск и RAG

1. Поисковые запросы обрабатываются SearXNG
2. Результаты кэшируются в Redis
3. Векторный поиск выполняется в PostgreSQL (pgvector)
4. Релевантные документы добавляются в контекст

### 4. Обработка документов

1. Файлы обрабатываются Apache Tika для извлечения текста
2. PDF/изображения обрабатываются Docling с GPU-ускорением
3. Эмбеддинги сохраняются в PostgreSQL
4. Структурированные данные возвращаются в Open WebUI

### 5. Синтез речи

1. Текст отправляется в EdgeTTS
2. Генерируется аудио-поток
3. Аудио возвращается пользователю

### 6. Персистентность

1. Чаты сохраняются в PostgreSQL
2. Временные данные кэшируются в Redis
3. LiteLLM логирует все запросы в PostgreSQL

### 7. Мониторинг

1. Метрики собираются Prometheus
2. Логи агрегируются Fluent Bit → Loki
3. Grafana визуализирует метрики и логи
4. Alertmanager управляет алертами

### 8. Резервное копирование

1. Backrest создает резервные копии PostgreSQL и Redis
2. Бэкапы сохраняются локально
3. Автоматическое расписание через cron
