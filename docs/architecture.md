# 🏗️ Архитектура системы ERNI-KI

> **Версия документа:** 9.0 **Дата обновления:** 2025-09-11 **Статус:**
> Production Ready (Полностью оптимизированная система с исправленными nginx
> конфигурациями, восстановленным SearXNG API, улучшенной HTTPS поддержкой и
> актуализированной документацией)

## 📋 Обзор архитектуры

ERNI-KI представляет собой современную микросервисную AI платформу, построенную
на принципах контейнеризации, безопасности и масштабируемости. Система включает
OpenWebUI, Ollama (GPU), LiteLLM (Context Engineering), SearXNG, Docling, Tika,
EdgeTTS, MCP Server и полный стек наблюдаемости (Prometheus, Grafana,
Alertmanager, Loki, Fluent Bit, Blackbox, cAdvisor, экспортёры). Для SLA RAG
добавлен отдельный экспортер (latency/sources). Внешний доступ осуществляется
через Cloudflare туннели и домены.

### 🚀 Последние обновления (v9.0 - сентябрь 2025)

#### 🔧 Критические оптимизации (11 сентября 2025)

- **Nginx конфигурация**: Полная оптимизация и дедупликация
  - Устранено 91 строка дублирующегося кода (-20% размера конфигурации)
  - Созданы 4 include файла для переиспользования (openwebui-common.conf,
    searxng-api-common.conf, websocket-common.conf, searxng-web-common.conf)
  - Добавлены map директивы для условной логики
  - Улучшена maintainability и консистентность настроек

- **HTTPS и CSP исправления**: Восстановлена полная функциональность
  - Оптимизирована Content Security Policy для поддержки localhost
  - Расширены CORS заголовки для разработки и production
  - Исправлена SSL конфигурация с ssl_verify_client off
  - Устранены критические ошибки загрузки скриптов

- **SearXNG API восстановление**: Полное исправление маршрутизации
  - Исправлена проблема с переменной $universal_request_id
  - Восстановлена функциональность /api/searxng/search эндпоинта
  - API возвращает корректные JSON ответы с результатами поиска (31 результат
    из 4500)
  - Поддержка 4 поисковых движков: Google, Bing, DuckDuckGo, Brave
  - Время ответа <2 секунд (соответствует SLA требованиям)

#### 🔴 Предыдущие исправления (29 августа 2025)

- **Cloudflare Tunnel**: Исправлены DNS resolution ошибки
- **Система диагностики**: Комплексная проверка 29 микросервисов
- **Все сервисы в статусе "Healthy"** (15+ контейнеров)

#### 🛡️ Архитектурные компоненты (актуализировано)

- **OpenWebUI v0.6.26**: Основной AI интерфейс с CUDA поддержкой
- **Ollama 0.11.8**: 9 загруженных AI моделей с GPU ускорением
- **LiteLLM (main-stable)**: Context Engineering Gateway
- **PostgreSQL 15.13 + pgvector 0.8.0**: Векторная база данных
- **Redis Stack**: WebSocket manager и кэширование
- **SearXNG**: RAG интеграция с 6+ источниками поиска

#### 📊 Мониторинг и наблюдаемость

- **Prometheus v2.55.1**: Сбор метрик с 35+ targets
- **Grafana**: Визуализация и дашборды
- **Loki**: Централизованное логирование через Fluent-bit
- **8 экспортеров**: node, postgres, redis, nginx, ollama, nvidia, cadvisor,
  blackbox
- **Backrest**: Локальные резервные копии (7 дней + 4 недели)

## 🎯 Архитектурные принципы

### 🔒 **Security First**

- JWT аутентификация для всех API запросов
- Rate limiting и защита от DDoS атак
- SSL/TLS шифрование всего трафика
- Изоляция сервисов через Docker networks

### 📈 **Scalability & Performance**

- Горизонтальное масштабирование через Docker Compose
- GPU ускорение для AI вычислений
- Кэширование через Redis
- Асинхронная обработка документов

### 🛡️ **Reliability & Monitoring**

- Health checks для всех сервисов
- Автоматические перезапуски при сбоях
- Централизованное логирование
- Автоматические резервные копии

## 🌐 Nginx Reverse Proxy Архитектура

### 📁 Модульная структура конфигурации (v9.0)

После оптимизации nginx конфигурация стала модульной и maintainable:

```bash
conf/nginx/
├── nginx.conf                    # Основная конфигурация с map директивами
├── conf.d/default.conf          # Server блоки (80, 443, 8080)
└── includes/                     # Переиспользуемые модули
    ├── openwebui-common.conf     # Общие настройки OpenWebUI proxy
    ├── searxng-api-common.conf   # SearXNG API конфигурация
    ├── searxng-web-common.conf   # SearXNG веб-интерфейс
    └── websocket-common.conf     # WebSocket proxy настройки
```

### 🔧 Ключевые улучшения

- **Дедупликация**: Устранено 91 строка дублирующегося кода (-20%)
- **Универсальные переменные**: `$universal_request_id` для всех include файлов
- **Условная логика**: Map директивы для различий между портами
- **Hot-reload**: Изменения применяются без перезапуска системы

### 🚪 Server блоки и маршрутизация

| Порт     | Назначение                       | Особенности                           |
| -------- | -------------------------------- | ------------------------------------- |
| **80**   | HTTP → HTTPS redirect            | Автоматическое перенаправление        |
| **443**  | HTTPS с полной функциональностью | SSL, CSP, CORS для production         |
| **8080** | Cloudflare туннель               | Оптимизированный для внешнего доступа |

### 🔍 API эндпоинты (актуализировано)

- **`/health`** ✅ - Проверка состояния системы
- **`/api/searxng/search`** ✅ - RAG веб-поиск (исправлено)
- **`/api/config`** ✅ - Конфигурация системы
- **`/api/mcp/`** ✅ - Model Context Protocol
- **WebSocket endpoints** ✅ - Real-time коммуникация

## 🏛️ Диаграмма высокого уровня

```mermaid
graph TB
    subgraph "🌐 External Layer"
        USER[👤 User Browser]
        CF[☁️ Cloudflare Zero Trust<br/>✅ 5 доменов активны<br/>🔧 DNS исправлены 29.08.2025]
    end

    subgraph "🚪 Gateway Layer"
        NGINX[🚪 Nginx Reverse Proxy<br/>🛡️ Security Headers<br/>📦 Gzip Compression<br/>⚡ WebSocket Support<br/>🔧 Порты: 80,443,8080<br/>✅ Healthy]
        AUTH[🔐 Auth Service JWT<br/>🔧 Порт: 9092<br/>✅ 2 часа работы]
        TUNNEL[🔗 Cloudflared Tunnel<br/>✅ 4 соединения активны<br/>🔧 Исправлены имена контейнеров]
    end

    subgraph "🤖 Application Layer"
        OWUI[🤖 OpenWebUI v0.6.26<br/>🎮 CUDA Support<br/>🔧 Порт: 8080<br/>✅ 9 минут работы]
        OLLAMA[🧠 Ollama 0.11.8<br/>🎮 GPU Quadro P2200 (25%)<br/>📚 9 моделей загружено<br/>🔧 Порт: 11434<br/>✅ 1 час работы]
        SEARXNG[🔍 SearXNG Search<br/>🔧 RAG Integration<br/>🔧 Порт: 8080<br/>✅ 5 часов работы]
        MCP[🔌 MCP Server<br/>🔧 Порт: 8000<br/>✅ 2 часа работы]
    end

    subgraph "🔧 Processing Layer"
        DOCLING[📄 Docling CPU<br/>🔧 Порт: 5001<br/>🌍 Multilingual OCR<br/>✅ 2 дня работы]
        TIKA[📋 Apache Tika<br/>🔧 Порт: 9998<br/>✅ 3 дня работы]
        EDGETTS[🎤 EdgeTTS<br/>🔧 Порт: 5050<br/>✅ 3 дня работы]
        LITELLM[🌐 LiteLLM main-stable<br/>🔧 Context Engineering<br/>🔧 Порт: 4000<br/>✅ 1 час работы]
    end

    subgraph "💾 Data Layer"
        POSTGRES[(🗄️ PostgreSQL 15.13 + pgvector 0.8.0<br/>🔧 Порт: 5432<br/>✅ Connections accepting<br/>⚡ Shared database)]
        REDIS[(⚡ Redis Stack<br/>🔧 WebSocket Manager<br/>🔧 Порт: 6379<br/>✅ 9 минут работы<br/>🔐 Auth configured)]
        BACKREST[💾 Backrest<br/>📅 7д + 4н retention<br/>🔧 Порт: 9898<br/>✅ 5 часов работы]
    end

    subgraph "📊 Monitoring & Observability (33/33 Healthy)"
        PROMETHEUS[📈 Prometheus v2.55.1<br/>🔧 Порт: 9091<br/>✅ 57 минут работы]
        GRAFANA[📊 Grafana<br/>🔧 Порт: 3000<br/>✅ 58 минут работы]
        ALERTMANAGER[🚨 Alert Manager<br/>🔧 Порты: 9093-9094<br/>✅ 1 час работы]
        LOKI[📝 Loki<br/>🔧 Порт: 3100<br/>✅ 59 минут работы]
        FLUENT_BIT[📝 Fluent Bit<br/>🔧 Порт: 24224<br/>✅ 1 час работы]
        WEBHOOK_REC[📨 Webhook Receiver<br/>🔧 Порт: 9095<br/>✅ 3 дня работы]
    end

    subgraph "📊 Metrics Exporters (All Healthy)"
        NODE_EXP[📊 Node Exporter<br/>🔧 Порт: 9101<br/>✅ 1 час работы]
        PG_EXP[📊 PostgreSQL Exporter<br/>🔧 Порт: 9187<br/>✅ 1 час работы]
        REDIS_EXP[📊 Redis Exporter<br/>🔧 Порт: 9121<br/>✅ 9 минут работы]
        NVIDIA_EXP[📊 NVIDIA GPU Exporter<br/>🔧 Порт: 9445<br/>✅ 3 дня работы]
        BLACKBOX_EXP[📊 Blackbox Exporter<br/>🔧 Порт: 9115<br/>✅ 1 час работы]
        CADVISOR[📊 cAdvisor<br/>🔧 Порт: 8081<br/>✅ 3 дня работы]
        OLLAMA_EXP[🤖 Ollama Exporter<br/>🔧 Порт: 9778<br/>✅ 3 дня работы]
        NGINX_EXP[🌐 Nginx Exporter<br/>🔧 Порт: 9113<br/>✅ 4 дня работы]
    end

    subgraph "🛠️ Infrastructure Layer"
        WATCHTOWER[🔄 Watchtower<br/>🔧 Порт: 8091<br/>✅ 3 дня работы<br/>🛡️ Selective updates]
        DOCKER[🐳 Docker + NVIDIA Runtime<br/>🎮 GPU Support<br/>✅ All containers healthy]
    end

    %% External connections
    USER --> CF
    CF --> TUNNEL
    TUNNEL --> NGINX

    %% Gateway layer
    NGINX --> AUTH
    NGINX --> OWUI
    NGINX --> SEARXNG
    NGINX --> LITELLM

    %% Application connections
    OWUI --> OLLAMA
    OWUI --> SEARXNG
    OWUI --> MCP
    OWUI --> DOCLING
    OWUI --> TIKA
    OWUI --> EDGETTS
    OWUI --> LITELLM
    LITELLM --> OLLAMA

    %% Data connections
    OWUI --> POSTGRES
    OWUI --> REDIS
    SEARXNG --> REDIS
    BACKREST --> POSTGRES
    BACKREST --> REDIS
    BACKREST --> OWUI

    %% Monitoring connections
    PROMETHEUS --> NODE_EXP
    PROMETHEUS --> PG_EXP
    PROMETHEUS --> REDIS_EXP
    PROMETHEUS --> NVIDIA_EXP
    PROMETHEUS --> BLACKBOX_EXP
    PROMETHEUS --> CADVISOR
    PROMETHEUS --> OLLAMA_EXP
    PROMETHEUS --> NGINX_EXP
    PROMETHEUS --> RAG_EXP
    GRAFANA --> PROMETHEUS
    ALERTMANAGER --> PROMETHEUS
    ALERTMANAGER --> WEBHOOK_REC
    FLUENT_BIT --> LOKI
    GRAFANA --> LOKI

    %% Infrastructure
    WATCHTOWER -.-> OWUI
    WATCHTOWER -.-> OLLAMA
    WATCHTOWER -.-> SEARXNG
    WATCHTOWER -.-> OLLAMA
    WATCHTOWER -.-> SEARXNG

    %% RAG Exporter & Panels
    RAG_EXP[⏱️ RAG Exporter\nLatency & Sources\nПорт: 9808]
    OWUI --> RAG_EXP
```

## 📊 Диаграмма производительности БД (Production Optimizations)

```mermaid
graph LR
    subgraph "🐘 PostgreSQL 15.13 Performance"
        PG_CONFIG[📊 Configuration<br/>shared_buffers: 256MB<br/>max_connections: 200<br/>work_mem: 4MB]
        PG_VACUUM[🧹 Autovacuum<br/>4 workers<br/>15s naptime<br/>threshold: 25]
        PG_CACHE[⚡ Cache Performance<br/>Hit Ratio: 99.76%<br/>Response: <100ms<br/>Active Connections: 1-5]
    end

    subgraph "🔴 Redis 7.4.5 Performance"
        REDIS_MEM[💾 Memory Management<br/>Limit: 2GB<br/>Policy: allkeys-lru<br/>Usage: 2.20M (0.1%)]
        REDIS_PERF[⚡ Performance<br/>SET: <60ms<br/>GET: <50ms<br/>Clients: 17 active]
        REDIS_AUTH[🔐 Authentication<br/>WebSocket Support<br/>0 auth errors<br/>Stable connections]
        REDIS_SYS[🛠️ System Tuning<br/>vm.overcommit_memory=1<br/>No warnings<br/>Stable operation]
    end

    subgraph "🛡️ Security & Monitoring"
        SEC_HEADERS[🛡️ Security Headers<br/>X-Frame-Options<br/>X-XSS-Protection<br/>HSTS enabled]
        GZIP[📦 Compression<br/>60-80% traffic reduction<br/>All text/* types<br/>Active on all ports]
        MONITORING[📊 DB Monitoring<br/>PostgreSQL Exporter<br/>Redis Exporter<br/>Real-time metrics]
    end

    PG_CONFIG --> PG_CACHE
    PG_VACUUM --> PG_CACHE
    REDIS_MEM --> REDIS_PERF
    REDIS_SYS --> REDIS_PERF
    SEC_HEADERS --> MONITORING
    GZIP --> MONITORING
```

## 🔌 Сетевые порты и endpoints (локально)

- Nginx: 80, 443, 8080
- OpenWebUI: 8080
- LiteLLM: 4000 (`/health/liveliness`, `/health/readiness`)
- PostgreSQL Exporter: 9187 (`/metrics`)
- Redis Exporter: 9121 (`/metrics`)
- Node Exporter: 9101 (`/metrics`)
- cAdvisor: 8081 → контейнер 8080 (`/metrics`)
- NVIDIA GPU Exporter: 9445 (`/metrics`)
- Nginx Exporter: 9113 (`/metrics`)
- Blackbox Exporter: 9115 (`/probe`)
- Prometheus: 9091 (`/-/ready`, `/api/v1/targets`)
- Grafana: 3000 (`/api/health`)
- Alertmanager: 9093–9094 (`/-/healthy`, `/api/v2/status`)
- Loki: 3100 (`/ready`)
- Fluent Bit Service: 2020 (`/api/v1/metrics`, Prometheus:
  `/api/v1/metrics/prometheus`)
- RAG Exporter: 9808 (`/metrics`)

## 🔧 Детальная архитектура сервисов

### 🚪 **Gateway Layer (Шлюз)**

#### Nginx Reverse Proxy

- **Назначение**: Единая точка входа, балансировка нагрузки, SSL терминация
- **Порты**: 80 (HTTP), 443 (HTTPS), 8080 (Internal)
- **Функции**:
  - Rate limiting (100 req/min для общих запросов, 10 req/min для SearXNG)
  - SSL/TLS терминация с современными cipher suites
  - Проксирование WebSocket соединений
  - Статическая раздача файлов
  - Кэширование статического контента

#### Auth Service (JWT)

- **Технология**: Go 1.23+
- **Порт**: 9090
- **Функции**:
  - Генерация и валидация JWT токенов
  - Интеграция с nginx auth_request
  - Управление сессиями пользователей
  - Rate limiting для аутентификации

#### Cloudflared Tunnel

- **Назначение**: Безопасное подключение к Cloudflare Zero Trust
- **Статус**: ✅ DNS проблемы устранены (август 2025)
- **Функции**:
  - Шифрованные туннели без открытых портов
  - Автоматическое управление SSL сертификатами
  - DDoS защита на уровне Cloudflare
  - Географическое распределение трафика
  - Корректная резолюция имен сервисов в Docker network

### 🤖 **Application Layer (Приложения)**

#### Open WebUI

- **Технология**: Python FastAPI + Svelte
- **Порт**: 8080
- **GPU**: NVIDIA CUDA поддержка
- **Функции**:
  - Веб-интерфейс для работы с AI моделями
  - RAG (Retrieval-Augmented Generation) поиск
  - Управление чатами и историей
  - Интеграция с внешними сервисами
  - Загрузка и обработка документов
  - Голосовой ввод/вывод

#### Ollama LLM Server

- **Технология**: Go + CUDA
- **Порт**: 11434
- **GPU**: Полная поддержка NVIDIA GPU
- **Функции**:
  - Локальный запуск языковых моделей
  - Автоматическое управление GPU памятью
  - API совместимый с OpenAI
  - Поддержка множественных моделей
  - Streaming ответы

#### SearXNG Search Engine

- **Технология**: Python Flask
- **Порт**: 8080 (internal)
- **API Endpoint**: `/api/searxng/search` (через nginx proxy)
- **Производительность**: ✅ <0.8s время ответа (оптимизировано август 2025)
- **Функции**:
  - Метапоисковый движок (Google, Bing, DuckDuckGo, Brave, Startpage)
  - Приватный поиск без трекинга
  - JSON API для интеграции с RAG (47+ результатов)
  - Кэширование результатов в Redis
  - Rate limiting и защита от блокировок

#### LiteLLM Proxy

- **Технология**: Python FastAPI
- **Порт**: 4000
- **Функции**:
  - Унифицированный API для различных LLM провайдеров
  - Поддержка OpenAI, Anthropic, Google, Azure
  - Балансировка нагрузки между моделями
  - Мониторинг использования и затрат
  - Кэширование ответов
  - Rate limiting и квоты

#### MCP Servers (Context Engineering)

- **Технология**: Model Context Protocol
- **Порт**: 8000
- **Функции**:
  - Расширение возможностей AI через инструменты
  - Интеграция с внешними API и сервисами
  - Выполнение кода и команд
  - Доступ к базам данных и файловым системам
  - Context Engineering для улучшения AI ответов

### 🔧 **Processing Layer (Обработка)**

#### Docling Document Parser

- **Технология**: Python + AI models
- **Порт**: 5001
- **Функции**:
  - Извлечение текста из PDF, DOCX, PPTX
  - OCR для сканированных документов
  - Структурный анализ документов
  - Поддержка таблиц и изображений

#### Apache Tika

- **Технология**: Java
- **Порт**: 9998
- **Функции**:
  - Извлечение метаданных из файлов
  - Поддержка 1000+ форматов файлов
  - Детекция типов файлов
  - Извлечение текста и структуры

#### EdgeTTS Speech Synthesis

- **Технология**: Python + Microsoft Edge TTS
- **Порт**: 5050
- **Функции**:
  - Высококачественный синтез речи
  - Поддержка множественных языков и голосов
  - Streaming аудио
  - Интеграция с Open WebUI

### 💾 **Data Layer (Production Optimized)**

#### PostgreSQL 15.13 + pgvector 0.8.0

- **Версия**: PostgreSQL 15.13 + pgvector 0.8.0 (Production Ready)
- **Порт**: 5432 (внутренний Docker network)
- **🚀 Production конфигурация**:
  - **shared_buffers**: 256MB (оптимизировано для производительности)
  - **max_connections**: 200 (увеличено для высокой нагрузки)
  - **work_mem**: 4MB (оптимально для сложных запросов)
  - **wal_buffers**: 16MB (улучшенная запись WAL)
  - **maintenance_work_mem**: 64MB (быстрый VACUUM и индексирование)
- **🧹 Автовакуум оптимизация**:
  - **autovacuum_max_workers**: 4 (агрессивная очистка)
  - **autovacuum_naptime**: 15s (частые проверки)
  - **autovacuum_vacuum_threshold**: 25 (низкий порог)
- **📊 Производительность**:
  - **Cache hit ratio**: 99.76% (отличная эффективность кэша)
  - **Время ответа**: <100ms для 95% запросов
  - **Активные подключения**: 1-5 (низкая нагрузка)
- **📝 Логирование**:
  - Включены connection/disconnection логи
  - Медленные запросы >100ms
  - Lock waits мониторинг
- **🔍 Функции**:
  - Основная база данных приложения (6 пользователей, 29 чатов)
  - Векторное хранилище для RAG (968 векторных чанков, 28MB)
  - Полнотекстовый поиск
  - ACID транзакции
  - Автоматические резервные копии

#### Redis 7.4.5 Stack

- **Версия**: Redis 7.4.5 Stack (Production Optimized)
- **Порты**: 6379 (Redis), 8001 (RedisInsight)
- **💾 Memory Management**:
  - **maxmemory**: 2GB (предотвращение OOM)
  - **maxmemory-policy**: allkeys-lru (умная очистка)
  - **Текущее использование**: 2.20M (0.1% от лимита)
- **⚡ Производительность**:
  - **SET операции**: <60ms
  - **GET операции**: <50ms
  - **Подключенные клиенты**: 17 активных
  - **Количество ключей**: 932 (активное кэширование)
- **🛠️ Системные оптимизации**:
  - **vm.overcommit_memory=1** (исправлен memory overcommit warning)
  - Автосохранение: 900s/1, 300s/100, 60s/10000 изменений
  - Стабильная работа без предупреждений
- **🔍 Функции**:
  - Кэширование поисковых запросов
  - Сессии пользователей OpenWebUI
  - Конфигурационные данные
  - Временные данные обработки
  - Pub/Sub для real-time уведомлений

#### Backrest Backup System

- **Технология**: Go + Restic
- **Порт**: 9898
- **API Endpoints**: ✅ `/v1.Backrest/Backup`, `/v1.Backrest/GetOperations`
- **Статус**: ✅ Ручное управление настроено (август 2025)
- **Функции**:
  - Автоматические инкрементальные бэкапы (план "daily")
  - Шифрование данных AES-256
  - Дедупликация и сжатие
  - Веб-интерфейс управления
  - Восстановление на определенную дату
  - REST API для автоматизации

### 🛠️ **Infrastructure Layer (Инфраструктура)**

#### Watchtower Auto-updater

- **Порт**: 8091
- **Функции**:
  - Автоматическое обновление Docker образов
  - Мониторинг новых версий
  - Graceful перезапуск сервисов
  - Уведомления об обновлениях
  - HTTP API для управления

### 📊 **Monitoring Layer (Мониторинг)**

#### Prometheus Metrics Server

- **Версия**: v2.48.0
- **Порт**: 9091
- **Функции**:
  - Сбор метрик со всех сервисов
  - Time-series база данных
  - Alerting rules
  - Service discovery
  - 30-дневное хранение данных

#### Grafana Dashboards

- **Версия**: 10.2.0
- **Порт**: 3000
- **Функции**:
  - Визуализация метрик
  - Интерактивные дашборды
  - Alerting и уведомления
  - Пользовательские панели
  - Интеграция с Prometheus

#### AlertManager

- **Версия**: v0.26.0
- **Порты**: 9093, 9094
- **Функции**:
  - Управление алертами
  - Группировка уведомлений
  - Маршрутизация алертов
  - Интеграция с внешними системами
  - Silencing и inhibition

#### Webhook Receiver

- **Технология**: Python Flask
- **Порт**: 9095 (внешний), 9093 (внутренний)
- **Функции**:
  - Обработка алертов от AlertManager
  - Логирование критических событий
  - Выполнение автоматических действий
  - Интеграция с внешними системами уведомлений
  - JSON форматирование алертов

#### Node Exporter

- **Версия**: v1.7.0
- **Порт**: 9101
- **Функции**:
  - Системные метрики хоста
  - CPU, память, диск, сеть
  - Процессы и systemd сервисы
  - Hardware мониторинг

#### PostgreSQL Exporter

- **Версия**: v0.15.0
- **Порт**: 9187
- **Функции**:
  - Метрики базы данных
  - Производительность запросов
  - Соединения и блокировки
  - Репликация и бэкапы

#### Redis Exporter

- **Версия**: v1.55.0
- **Порт**: 9121
- **Функции**:
  - Метрики Redis сервера
  - Использование памяти
  - Производительность команд
  - Keyspace статистика

#### NVIDIA GPU Exporter

- **Версия**: 0.1
- **Порт**: 9445
- **Функции**:
  - GPU утилизация
  - Память GPU
  - Температура и энергопотребление
  - CUDA процессы

#### Blackbox Exporter

- **Версия**: v0.24.0
- **Порт**: 9115
- **Функции**:
  - Мониторинг доступности сервисов
  - HTTP/HTTPS проверки
  - TCP/UDP connectivity
  - SSL сертификаты

#### cAdvisor Container Metrics

- **Версия**: v0.47.2
- **Порт**: 8081
- **Функции**:
  - Метрики контейнеров
  - Использование ресурсов
  - Производительность I/O
  - Network статистика

#### Ollama AI Exporter

- **Версия**: Custom Python exporter
- **Порт**: 9778
- **Функции**:
  - Мониторинг AI моделей (`ollama_models_total`)
  - Размеры моделей (`ollama_model_size_bytes`)
  - Версия Ollama (`ollama_info`)
  - Статус GPU использования
  - Производительность инференса

#### Nginx Web Exporter

- **Версия**: nginx/nginx-prometheus-exporter:1.1.0
- **Порт**: 9113
- **Функции**:
  - HTTP метрики веб-сервера
  - Количество активных соединений
  - Статистика запросов/ответов
  - Производительность upstream'ов
  - Rate limiting метрики

#### Fluent Bit Log Collector

- **Версия**: fluent/fluent-bit:2.2.0
- **Порт**: 2020 (метрики)
- **Функции**:
  - Централизованный сбор логов
  - Парсинг и фильтрация логов
  - Отправка в Loki
  - Метрики обработки логов

#### Loki Log Aggregation

- **Версия**: grafana/loki:2.9.0
- **Порт**: 3100
- **Функции**:
  - Хранение централизованных логов
  - Интеграция с Grafana для визуализации
  - Эффективное сжатие и индексирование
  - LogQL для запросов логов
  - Совместимость с Prometheus метриками

## 🌐 Сетевая архитектура

### Порты и протоколы

| Сервис            | Внешний порт  | Внутренний порт | Протокол   | Назначение            |
| ----------------- | ------------- | --------------- | ---------- | --------------------- |
| nginx             | 80, 443, 8080 | 80, 443, 8080   | HTTP/HTTPS | Web gateway           |
| auth              | -             | 9090            | HTTP       | JWT validation        |
| openwebui         | -             | 8080            | HTTP/WS    | AI interface          |
| ollama            | -             | 11434           | HTTP       | LLM API               |
| litellm           | 4000          | 4000            | HTTP       | LLM proxy             |
| db                | -             | 5432            | PostgreSQL | Database              |
| redis             | -             | 6379, 8001      | Redis/HTTP | Cache & UI            |
| searxng           | -             | 8080            | HTTP       | Search API            |
| mcposerver        | -             | 8000            | HTTP       | MCP protocol          |
| docling           | -             | 5001            | HTTP       | Document parsing      |
| tika              | -             | 9998            | HTTP       | Metadata extraction   |
| edgetts           | -             | 5050            | HTTP       | Speech synthesis      |
| backrest          | 9898          | 9898            | HTTP       | Backup management     |
| cloudflared       | -             | -               | HTTPS      | Tunnel service        |
| watchtower        | 8091          | 8080            | HTTP       | Auto-updater          |
| prometheus        | 9091          | 9090            | HTTP       | Metrics collection    |
| grafana           | 3000          | 3000            | HTTP       | Monitoring dashboards |
| alertmanager      | 9093, 9094    | 9093, 9094      | HTTP       | Alert management      |
| webhook-receiver  | 9095          | 9093            | HTTP       | Alert processing      |
| node-exporter     | 9101          | 9100            | HTTP       | System metrics        |
| postgres-exporter | 9187          | 9187            | HTTP       | PostgreSQL metrics    |
| redis-exporter    | 9121          | 9121            | HTTP       | Redis metrics         |
| nvidia-exporter   | 9445          | 9445            | HTTP       | GPU metrics           |
| blackbox-exporter | 9115          | 9115            | HTTP       | Endpoint monitoring   |
| cadvisor          | 8081          | 8080            | HTTP       | Container metrics     |

### Docker Networks

- **erni-ki_default**: Основная сеть для всех сервисов
- **Изоляция**: Каждый сервис доступен только по имени контейнера
- **DNS**: Автоматическое разрешение имен через Docker DNS

## 🔄 Потоки данных

### Пользовательский запрос

1. **Browser** → **Cloudflare** → **Cloudflared** → **Nginx**
2. **Nginx** → **Auth Service** (валидация JWT)
3. **Nginx** → **Open WebUI** (основной интерфейс)
4. **Open WebUI** → **Ollama** (генерация ответа)
5. **Open WebUI** → **PostgreSQL** (сохранение истории)

### RAG поиск

1. **Open WebUI** → **SearXNG** (поиск информации)
2. **SearXNG** → **Redis** (кэширование результатов)
3. **Open WebUI** → **PostgreSQL/pgvector** (векторный поиск)
4. **Open WebUI** → **Ollama** (генерация с контекстом)

### Обработка документов

1. **Open WebUI** → **Docling/Tika** (парсинг документа)
2. **Open WebUI** → **PostgreSQL/pgvector** (сохранение векторов)
3. **Open WebUI** → **Ollama** (анализ содержимого)

## 📊 Мониторинг и наблюдаемость

### Health Checks

- Все сервисы имеют настроенные health checks
- Автоматический перезапуск при сбоях
- Мониторинг через `docker compose ps`

### Логирование

- Централизованные логи через Docker logging driver
- Ротация логов для предотвращения переполнения диска
- Структурированное логирование в JSON формате

### Метрики

- Использование ресурсов через `docker stats`
- Мониторинг GPU через nvidia-smi
- Производительность базы данных

## 🔧 Конфигурация и развертывание

### Переменные окружения

- Каждый сервис имеет отдельный `.env` файл
- Секретные ключи генерируются автоматически
- Конфигурация через Docker Compose

### Масштабирование

- Горизонтальное масштабирование через Docker Compose scale
- Балансировка нагрузки через Nginx upstream
- Автоматическое обнаружение новых экземпляров

### Безопасность

- Минимальные привилегии для всех контейнеров
- Изоляция сетей и файловых систем
- Регулярные обновления безопасности через Watchtower

## 🆕 Последние изменения архитектуры

### Август 2025 - Версия 6.0

#### ✅ Исправления и оптимизации

**SearXNG RAG интеграция:**

- Отключен DuckDuckGo движок из-за CAPTCHA блокировки
- Активные движки: Startpage, Brave, Bing
- Производительность: <3 секунды, 60+ результатов
- Статус: ✅ Полностью функциональна

**Backrest API:**

- Переход на JSON RPC endpoints (`/v1.Backrest/*`)
- Восстановлен автоматизированный мониторинг
- API endpoints: GetOperations, GetConfig работают корректно
- Статус: ✅ Полностью функционален

**Ollama модели:**

- Добавлена qwen2.5-coder:1.5b (986MB) для кодирования
- Всего 6 моделей: qwen2.5:0.5b, qwen2.5-coder:1.5b, phi4-mini-reasoning:3.8b,
  gemma3n:e4b, deepseek-r1:7b, nomic-embed-text
- GPU использование: 31% VRAM (1610MB/5120MB)
- Производительность: ~1.5 секунды генерация

**Мониторинг:**

- **35/35 Prometheus targets активны** (100% успех)
- Все 29 ERNI-KI сервисов здоровы
- Система работает на 100% от оптимального уровня
- AI метрики: 3 модели мониторятся (nomic-embed-text, gpt-oss, gemma3n)
- Централизованное логирование через Fluent-bit → Loki

#### 📊 Текущий статус системы

- **Общая оценка:** 🟢 ПРЕВОСХОДНО (100/100)
- **Сервисы:** 29/29 ERNI-KI сервисов здоровы
- **HTTPS доступ:** ✅ HTTP/2 работает
- **GPU ускорение:** ✅ Активно + мониторинг
- **RAG интеграция:** ✅ <2 секунды
- **Мониторинг:** ✅ Полный стек 35 targets
- **AI метрики:** ✅ Ollama + модели
- **Веб-аналитика:** ✅ Nginx метрики
- **Логирование:** ✅ Централизованное
- **Бэкапы:** ✅ 7-дневные + 4-недельные

---

**📝 Примечание**: Данная архитектура оптимизирована для production
использования с акцентом на безопасность, производительность и надежность.
