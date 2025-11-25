---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Глоссарий'
---

# Глоссарий

Ключевые термины и концепции, используемые в документации ERNI-KI.

## Термины AI и ML

### Context7

Фреймворк контекстной инженерии, интегрированный с LiteLLM, который улучшает
ответы AI через лучшее управление контекстом и продвинутые рассуждения.

### Docling

Сервис обработки документов с возможностями:

- Многоязычное OCR (EN, DE, FR, IT)
- Извлечение текста из PDF, DOCX, PPTX
- Структурный анализ документов
- Распознавание таблиц и изображений

Порт: 5001

### EdgeTTS

Сервис преобразования текста в речь Microsoft Edge:

- Поддержка множества языков
- Различные варианты голосов
- Потоковый вывод аудио
- Интеграция с Open WebUI

Порт: 5050

### LiteLLM

Унифицированный API-шлюз для LLM:

- Единый API для разных провайдеров (OpenAI, Anthropic, Google, Azure)
- Балансировка нагрузки между моделями
- Мониторинг использования и отслеживание затрат
- Кэширование и ограничение скорости
- Контекстная инженерия через Context7

Порт: 4000

### MCP (Model Context Protocol)

Протокол для расширения возможностей AI через инструменты и интеграции. MCP
Server предоставляет:

- Безопасное выполнение инструментов
- Совместное использование контекста между агентами
- Стандартизированные схемы инструментов

Порт: 8000

### Ollama

Локальный LLM-сервер с GPU-ускорением. Хранит модели в `./data/ollama`.
Настраивается через `env/ollama.env`.

### OpenWebUI

Основной пользовательский интерфейс для AI-взаимодействий:

- Чат-интерфейс с поддержкой изображений и документов
- Управление моделями и маршрутизация через LiteLLM/Ollama
- RAG-интеграции через SearXNG/Docling
- SSE-потоковые эндпоинты

Порт: 8080 (проксируется через Nginx)

### RAG Exporter

Prometheus-экспортер для производительности RAG:

- `erni_ki_rag_response_latency_seconds`
- `erni_ki_rag_sources_count`
- Мониторинг SLA для RAG-эндпоинтов

Порт: 9808

### SearXNG

Мета-поисковая система, используемая для RAG:

- Поддержка множества поисковых провайдеров (Brave, Startpage, Bing, Wikipedia)
- API-эндпоинт: `/search?q=<query>&format=json`

Порт: 8080

## Операции и мониторинг

### Alertmanager

Сервис маршрутизации и уведомлений об алертах:

- Версия: v0.27.0
- Каналы: Slack/Teams
- Троттлинг и маршрутизация через конфигурацию Alertmanager

### Grafana Dashboards

Предустановленные дашборды (5):

- GPU/LLM
- Инфраструктура
- SLA/Alertmanager
- Логи (Loki через Explore)
- RAG-метрики

### Prometheus Alerts

20 активных правил алертов, покрывающих критические, производительность, базу
данных, GPU, Nginx. Определены в `conf/prometheus/alerts.yml`.

### Watchtower (режим мониторинга)

Мониторит образы без автоматического обновления критических сервисов; только
выборочные обновления.

## Автоматизация

### Maintenance Cron

Запланированные задачи:

- PostgreSQL VACUUM — 03:00
- Очистка Docker — 04:00
- Резервные копии Backrest — 01:30
- Ротация логов ежедневно
- Выборочные обновления Watchtower

### Scripts (Скрипты)

- `scripts/maintenance/docling-shared-cleanup.sh` — очистка shared volume
  Docling
- `scripts/maintenance/redis-fragmentation-watchdog.sh` — защита от фрагментации
- `scripts/monitoring/alertmanager-queue-watch.sh` — мониторинг очереди
- `scripts/infrastructure/security/monitor-certificates.sh` — мониторинг
  истечения TLS/Cloudflare

## Данные и хранилище

### PostgreSQL (17 + pgvector)

Общая БД для OpenWebUI и LiteLLM. См.:

- `docs/operations/database/database-monitoring-plan.md`
- `docs/operations/database/database-production-optimizations.md`
- `docs/operations/database/database-troubleshooting.md`

### Redis (7-alpine)

Менеджер кэша/WebSocket. См.:

- `docs/operations/database/redis-monitoring-grafana.md`
- `docs/operations/database/redis-operations-guide.md`

### Backrest

Локальные резервные копии (ежедневные + еженедельные) хранятся в
`.config-backup/`. Скрипт интеграции:
`scripts/setup/setup-backrest-integration.sh`.

## Безопасность

### Authentication (Аутентификация)

JWT-аутентификация для сервисов; Auth-сервис проксируется через Nginx. Секреты
хранятся в env-файлах (используйте `.example` и CI-секреты, не git).

### TLS

Nginx обрабатывает SSL-терминацию; Cloudflare-туннель опционален. Сертификаты в
`conf/ssl/`.

### Logging Pipeline (Конвейер логирования)

Fluent Bit → Loki через TLS с общим ключом; управление сертификатами через
`scripts/security/prepare-logging-tls.sh`.
