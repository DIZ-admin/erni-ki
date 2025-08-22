# 🏗️ Архитектура системы ERNI-KI

> **Версия документа:** 6.4 **Дата обновления:** 2025-08-19 **Статус:**
> Production Ready (Полный мониторинг стек + AI метрики + централизованное
> логирование)

## 📋 Обзор архитектуры

ERNI-KI представляет собой современную микросервисную AI платформу, построенную
на принципах контейнеризации, безопасности и масштабируемости. Система состоит
из **29 взаимосвязанных сервисов ERNI-KI**, включая компоненты LiteLLM, Docling,
MCP Server, полный мониторинг стек с 35+ активными targets, ollama-exporter для
AI метрик, nginx-exporter для веб-аналитики и централизованное логирование через
Fluent-bit. Дополнительно система включает 9 внешних сервисов (RAGFlow,
Photo-ERNI, Audio-ERNI).

### 🚀 Последние оптимизации (v6.5 - август 2025)

- **Система мониторинга**: Достигнуто 100% покрытие с 35+ активными targets
- **AI Метрики**: Развернут ollama-exporter (порт 9778) для мониторинга моделей
  ИИ
- **Веб-аналитика**: Добавлен nginx-exporter (порт 9113) для мониторинга трафика
- **Централизованное логирование**: Elasticsearch заменен на Loki, Fluent-bit →
  Loki для сбора логов всех сервисов
- **Cloudflare туннели**: Устранены DNS проблемы, обновлена конфигурация
- **SearXNG API**: Оптимизирован доступ через nginx proxy (<0.8s время ответа)
- **Backrest API**: Настроено ручное управление резервными копиями
- **GPU ускорение**: Подтверждена работа NVIDIA Quadro P2200 в Ollama
- **Production Ready**: Все критичные компоненты стабильны и мониторятся

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

## 🏛️ Диаграмма высокого уровня

```mermaid
graph TB
    subgraph "🌐 External Layer"
        USER[👤 User Browser]
        CF[☁️ Cloudflare Zero Trust]
    end

    subgraph "🚪 Gateway Layer"
        NGINX[🚪 Nginx Reverse Proxy]
        AUTH[🔐 Auth Service JWT]
        TUNNEL[🔗 Cloudflared Tunnel]
    end

    subgraph "🤖 Application Layer"
        OWUI[🤖 Open WebUI]
        OLLAMA[🧠 Ollama LLM Server + GPU]
        SEARXNG[🔍 SearXNG Search Engine]
        MCP[🔌 MCP Server]
    end

    subgraph "🔧 Processing Layer"
        DOCLING[📄 Docling Document Parser]
        TIKA[📋 Apache Tika Extractor]
        EDGETTS[🎤 EdgeTTS Speech Synthesis]
        LITELLM[🌐 LiteLLM API Gateway]
    end

    subgraph "💾 Data Layer"
        POSTGRES[(🗄️ PostgreSQL + pgvector)]
        REDIS[(⚡ Redis Cache & Stack)]
        BACKREST[💾 Backrest Backup System]
    end

    subgraph "📊 Monitoring & Observability"
        PROMETHEUS[📈 Prometheus Metrics Server]
        GRAFANA[📊 Grafana Dashboards]
        ALERTMANAGER[🚨 Alert Manager]
        LOKI[📝 Loki Log Aggregation]
        FLUENT_BIT[📝 Fluent Bit Log Collector]
        WEBHOOK_REC[📨 Webhook Receiver]
    end

    subgraph "📊 Metrics Exporters"
        NODE_EXP[📊 Node Exporter]
        PG_EXP[📊 PostgreSQL Exporter]
        REDIS_EXP[📊 Redis Exporter]
        NVIDIA_EXP[📊 NVIDIA GPU Exporter]
        BLACKBOX_EXP[📊 Blackbox Exporter]
        CADVISOR[📊 cAdvisor Container Metrics]
        OLLAMA_EXP[🤖 Ollama AI Metrics]
        NGINX_EXP[🌐 Nginx Web Analytics]
    end

    subgraph "🛠️ Infrastructure Layer"
        WATCHTOWER[🔄 Watchtower Auto-Updates]
        DOCKER[🐳 Docker Engine + NVIDIA Runtime]
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
```

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

### 💾 **Data Layer (Данные)**

#### PostgreSQL + pgvector

- **Версия**: PostgreSQL 16 + pgvector extension
- **Порт**: 5432
- **Функции**:
  - Основная база данных приложения
  - Векторное хранилище для RAG
  - Полнотекстовый поиск
  - ACID транзакции
  - Репликация и бэкапы

#### Redis Cache

- **Версия**: Redis Stack (Redis + RedisInsight)
- **Порты**: 6379 (Redis), 8001 (RedisInsight)
- **Функции**:
  - Кэширование поисковых запросов
  - Сессии пользователей
  - Очереди задач
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
