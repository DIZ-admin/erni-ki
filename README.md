# 🤖 ERNI-KI - Production-Ready AI Platform

**ERNI-KI** — современная AI платформа на базе OpenWebUI v0.6.32 с полной
контейнеризацией, GPU ускорением и enterprise-grade безопасностью. Система
включает **30 микросервисов ERNI-KI** с полным мониторингом стеком, AI
метриками, централизованным логированием и автоматизированным управлением.

> **✅ Статус системы (02 октября 2025):** Система работает стабильно с **30/30
> здоровыми контейнерами**. **18 дашбордов Grafana (100% функциональны)**, все
> критические проблемы устранены. **LiteLLM Context Engineering
> v1.77.3-stable**, **Docling Document Processing**, **MCP Server**, **Apache
> Tika**, **Watchtower автообновления**. GPU ускорение активно (Ollama 0.12.3 +
> OpenWebUI v0.6.32). Мониторинг обновлён (Prometheus v3.0.1, Loki v3.5.5,
> Fluent Bit v3.2.0). Система готова к продакшену.

[![CI](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml)
[![Security](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![GPU](https://img.shields.io/badge/NVIDIA-GPU%20Accelerated-green?logo=nvidia)](https://nvidia.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Quick Start

```bash
# 1. Клонирование репозитория
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki

# 2. Настройка переменных окружения
cp env/*.example env/
# Отредактируйте файлы в директории env/ согласно вашим требованиям
# Примечание: Структура конфигураций оптимизирована (август 2025)

# 3. Запуск системы (Docker Compose v2)
docker compose up -d

# 4. Проверка статуса
docker compose ps
```

**🌐 Доступ к интерфейсу:**

- **Основной домен:** <https://ki.erni-gruppe.ch>
- **Локальный доступ:** <http://localhost:8080>

## ✨ Ключевые возможности

### 🤖 **AI & Machine Learning**

- **OpenWebUI v0.6.32** - современный веб-интерфейс с CUDA поддержкой
  - ✅ Статус: Healthy
  - 🎮 GPU ускорение активно (NVIDIA runtime)
  - 🔧 Порт: 8080 (internal)
- **Ollama 0.12.3** - локальный сервер языковых моделей с GPU ускорением
  - 🎮 NVIDIA GPU активно (4GB VRAM limit)
  - 📚 Множественные модели (llama3.2, gemma3, llava, whisper и др.)
  - ⚡ Время генерации: <0.5 секунды (GPU ускорение)
  - ✅ Статус: Healthy
  - 🔧 Порт: 11434
- **LiteLLM v1.77.3-stable** - Context Engineering Gateway
  - 🔧 Порт: 4000
  - 🚀 Thinking tokens поддержка
  - 🧠 Context7 интеграция для улучшенного контекста
  - 🔄 Унифицированный API для различных LLM провайдеров
  - 💾 Memory: 12GB limit (увеличено для стабильности)
  - ✅ Статус: Healthy
- **MCP Server** - Model Context Protocol для расширенных AI возможностей
  - ✅ Статус: Healthy
  - 🔧 Порт: 8000
  - 🛠️ 4 активных инструмента (Time, PostgreSQL, Filesystem, Memory)
- **Docling** - обработка документов с многоязычным OCR
  - 🌍 Поддержка: EN, DE, FR, IT (автоопределение языка)
  - 🔧 Порт: 5001 (internal)
  - 💾 Memory: 12GB limit, CPU: 8 cores
  - ⚡ CPU оптимизация (CUDA отключен для Quadro P2200)
  - ✅ Статус: Healthy
- **Apache Tika** - извлечение текста из документов
  - 🔧 Порт: 9998
  - ✅ Статус: Healthy
- **EdgeTTS** - синтез речи
  - 🔧 Порт: 5050
  - ✅ Статус: Healthy
- **RAG поиск** - интеграция с SearXNG
  - ⚡ Время ответа: <2 секунды
  - 🔍 6+ источников поиска (Brave, Startpage, Bing, Wikipedia)
  - ✅ JSON API работает
  - ✅ Статус: Healthy

### 🔒 **Enterprise Security**

- **JWT аутентификация** - собственный Go сервис
  - 🔧 Порт: 9092
  - ✅ Статус: Healthy (2 часа работы)
- **Cloudflare Zero Trust** - безопасные туннели
  - ✅ 5 доменов активны (ki.erni-gruppe.ch, webui.diz.zone, search.diz.zone,
    diz.zone, lite.diz.zone)
  - 🔧 4 туннельных соединения (zrh02, fra17, fra18)
  - ✅ DNS проблемы исправлены (29.08.2025)
- **Nginx WAF** - защита от атак с rate limiting
  - 🔧 Порты: 80, 443, 8080
  - 🛡️ Security headers (X-Frame-Options, X-XSS-Protection, HSTS)
  - 📦 Gzip сжатие активно
  - 🔌 WebSocket поддержка
  - ✅ Статус: Healthy (1 час работы)
- **SSL/TLS** - полное шифрование TLS 1.2/1.3
- **Docker Secrets** - безопасное хранение конфигураций
- **Сетевая изоляция** - многоуровневая архитектура

### 📊 **Data & Storage**

- **PostgreSQL 17 + pgvector** - векторная база данных
  - 🔧 Порт: 5432 (internal)
  - ✅ Connections accepting
  - 🔗 Shared database (OpenWebUI + LiteLLM)
  - 🔒 Автообновление отключено (критический сервис)
  - ✅ Статус: Healthy
- **Redis 7-alpine** - кэширование и WebSocket manager
  - 🔧 Порт: 6379 (internal)
  - 🔐 Аутентификация настроена
  - 🔄 Active defragmentation включен
  - 📝 Конфигурация: conf/redis/redis.conf
  - ✅ Статус: Healthy
- **Backrest v1.9.2** - автоматические резервные копии
  - 🔧 Порт: 9898
  - 📅 7 дней daily + 4 недели weekly retention
  - 📁 Локальные бэкапы в .config-backup/
  - ✅ Статус: Healthy
- **Persistent volumes** - надежное хранение данных

### 📈 **Monitoring & Operations**

- **Prometheus v3.0.1** - сбор метрик (обновлено 2025-10-02)
  - 🔧 Порт: 9091
  - 🎯 132 правила алертов (было 120)
  - 📈 +30% производительность, -14% память
  - ✅ Статус: Healthy
- **Grafana v11.6.6** - визуализация и дашборды
  - 🔧 Порт: 3000
  - 📊 **18 дашбордов (100% функциональны)** - оптимизировано 19.09.2025
  - 🎯 Все Prometheus запросы исправлены с fallback значениями
  - ✅ Статус: Healthy
- **Alertmanager v0.28.0** - уведомления о событиях (обновлено 2025-10-02)
  - 🔧 Порты: 9093-9094
  - 🎨 Улучшенный UI
  - 📉 -9% память
  - ✅ Статус: Healthy
- **Loki v3.5.5** - централизованное логирование (обновлено 2025-10-02)
  - 🔧 Порт: 3100
  - 🚀 TSDB v13 schema, +40% скорость запросов
  - 📉 -9% память
  - ✅ Статус: Healthy
- **Fluent Bit v3.2.0** - сбор логов (обновлено 2025-10-02)
  - 🔧 Порты: 24224 (forward), 2020 (HTTP Service)
  - 🧪 Prometheus формат: `http://localhost:2020/api/v1/metrics/prometheus`
  - 📉 -10% память
  - ✅ Статус: Running
- **8 Exporters** - специализированные метрики (оптимизированы 19.09.2025)
  - 🖥️ Node Exporter (порт 9101) - системные метрики
    - ✅ Статус: Healthy | HTTP 200 | Стандартный healthcheck
  - 🐘 PostgreSQL Exporter (порт 9187) - метрики БД
    - ✅ Статус: Healthy | HTTP 200 | wget healthcheck
  - 🔴 Redis Exporter (порт 9121) - метрики кэша
    - 🔧 Статус: Running | HTTP 200 | **TCP healthcheck (исправлен)**
  - 🎮 NVIDIA GPU Exporter (порт 9445) - метрики GPU
    - ✅ Статус: Healthy | HTTP 200 | **TCP healthcheck (улучшен)**
  - 📦 Blackbox Exporter (порт 9115) - мониторинг доступности
    - ✅ Статус: Healthy | HTTP 200 | wget healthcheck
  - 🧠 Ollama AI Exporter (порт 9778) - метрики AI сервисов
    - ✅ Статус: Healthy | HTTP 200 | **wget healthcheck (стандартизирован)**
  - 🚪 Nginx Web Exporter (порт 9113) - метрики веб-сервера
    - 🔧 Статус: Running | HTTP 200 | **TCP healthcheck (исправлен)**
  - 📈 RAG Exporter (порт 9808) - SLA RAG латентность/источники
    - ✅ Статус: Healthy | HTTP 200 | Python healthcheck
- **Watchtower** - автоматические обновления
  - 🔧 Порт: 8091
  - ✅ Статус: Healthy (3 дня работы)

## 🏗️ Архитектура системы

ERNI-KI состоит из **30 микросервисов**, организованных в несколько слоев:

```text
🌐 External Layer (Cloudflare Zero Trust)
    ↓ ✅ 5 доменов активны (ki.erni-gruppe.ch, diz.zone, webui.diz.zone, search.diz.zone, lite.diz.zone)
🚪 Gateway Layer (Nginx 1.28.0 + Auth Service + Cloudflared 2025.9.1)
    ↓ ✅ Все сервисы Healthy, SSL/TLS терминация, WAF защита
🤖 Application Layer (OpenWebUI v0.6.32 + Ollama 0.12.3 + LiteLLM v1.77.3 + MCP)
    ↓ ✅ GPU ускорение активно, множественные модели загружены
🔍 Search & Processing (SearXNG + Docling + Tika + EdgeTTS)
    ↓ ✅ RAG интеграция работает, <2с ответ, многоязычный OCR
💾 Data Layer (PostgreSQL 17 + pgvector + Redis 7 + Backrest v1.9.2)
    ↓ ✅ Shared database, WebSocket manager, автоматические бэкапы
📊 Monitoring & Observability (Prometheus v3.0.1 + Grafana v11.6.6 + Loki v3.5.5 + Fluent Bit v3.2.0 + 8 Exporters)
    ↓ ✅ 30/30 контейнеров работают | 18 дашбордов (100% функциональны) | Обновлено 2025-10-02
🛠️ Infrastructure (Watchtower 1.7.1 + Docker + NVIDIA Runtime)
    ↓ ✅ Автообновления, GPU поддержка, селективные обновления
```

**Подробная архитектура:** [docs/architecture.md](docs/architecture.md)

## 📋 Системные требования

### Минимальные требования

- **OS:** Linux (Ubuntu 20.04+ / CentOS 8+ / Debian 11+)
- **CPU:** 4 cores (Intel/AMD x64)
- **RAM:** 16 GB (оптимизировано для PostgreSQL и Redis)
- **Storage:** 100 GB SSD
- **Docker:** 24.0+ с Docker Compose v2
- **Network:** 1 Gbps
- **Системные настройки:** vm.overcommit_memory=1 (для Redis)

### Рекомендуемые требования (Production)

- **CPU:** 8+ cores
- **RAM:** 32+ GB (PostgreSQL: 256MB shared_buffers, Redis: 2GB limit)
- **GPU:** NVIDIA с 8+ GB VRAM (для Ollama GPU ускорения)
- **Storage:** 500+ GB NVMe SSD
- **Network:** 10 Gbps
- **Мониторинг:** Prometheus + Grafana для метрик БД

## 📚 Документация

| Документ                                                                 | Описание                                  |
| ------------------------------------------------------------------------ | ----------------------------------------- |
| [📦 Installation Guide](docs/installation.md)                            | Детальная установка и настройка           |
| [🏗️ Architecture](docs/architecture.md)                                  | Архитектура системы с диаграммами         |
| [👨‍💼 Admin Guide](docs/admin-guide.md)                                    | Администрирование и мониторинг            |
| [👤 User Guide](docs/user-guide.md)                                      | Руководство пользователя                  |
| [🔧 Database Troubleshooting](docs/database-troubleshooting.md)          | **🆕** Решение проблем PostgreSQL и Redis |
| [📊 Database Monitoring](docs/database-monitoring-plan.md)               | **🆕** План мониторинга БД                |
| [⚡ Production Optimizations](docs/database-production-optimizations.md) | **🆕** Оптимизации для production         |

### Языковые версии

- 🇷🇺 **Русский:** [docs/ru/](docs/ru/)
- 🇩🇪 **Deutsch:** [docs/de/](docs/de/)

## 🚀 Production Deployment

### Быстрое развертывание

```bash
# Клонирование и настройка
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki

# Настройка production конфигурации
./scripts/setup.sh --production

# Запуск с мониторингом
docker compose up -d
./scripts/health_check.sh
```

### Security Checklist

- [ ] Настроены уникальные пароли в env/ файлах
- [ ] Настроен SSL сертификат в conf/nginx/ssl/
- [ ] Настроен Cloudflare tunnel в env/cloudflared.env
- [ ] Настроены backup в env/backrest.env
- [ ] Настроены алерты в monitoring/alertmanager.yml

**Подробное руководство:** [docs/installation.md](docs/installation.md)

## 🔧 Основные команды

```bash
# Управление системой
docker compose up -d              # Запуск всех сервисов
docker compose down               # Остановка всех сервисов
docker compose ps                 # Статус сервисов
docker compose logs -f [service]  # Просмотр логов

# Мониторинг
./scripts/health_check.sh         # Проверка здоровья системы
./scripts/quick-audit.sh          # Быстрый аудит
./scripts/system-health-monitor.sh # Мониторинг производительности

# Backup & Restore
./scripts/setup-local-backup.sh   # Настройка backup
./scripts/check-local-backup.sh   # Проверка backup
```

## 📊 Производительность

**Последний аудит (05.08.2025):**

- ✅ **15+ сервисов healthy**
- ✅ **Ollama генерация:** 0.6s (qwen2.5:0.5b)
- ✅ **SearXNG поиск:** <2s (6+ источников)
- ✅ **Конфигурации:** Оптимизированы (-883KB, -26 файлов)
- ✅ **MCP Server:** Продакшн конфигурация активна

**Оптимизации (август 2025):**

- Очистка временных файлов и логов
- Консолидация дублирующихся конфигураций
- Стандартизация naming convention

## 🤝 Contributing

Мы приветствуем вклад в развитие проекта! Пожалуйста, ознакомьтесь с
[CONTRIBUTING.md](CONTRIBUTING.md) для получения информации о процессе
разработки.

### Development Setup

```bash
# Установка зависимостей разработки
npm install

# Запуск тестов
npm test

# Линтинг кода
npm run lint

# Проверка безопасности
npm run security-check
```

## 🆕 Последние обновления

### ✅ Исправления (Август 2025)

- **SearXNG RAG интеграция восстановлена**
  - Отключен DuckDuckGo из-за CAPTCHA блокировки
  - Активны движки: Startpage, Brave, Bing
  - Время ответа: <3 секунды, 60+ результатов

- **Backrest API восстановлен**
  - Переход на JSON RPC endpoints (`/v1.Backrest/*`)
  - Автоматизированный мониторинг бэкапов работает

- **Ollama модели обновлены**
  - Добавлена qwen2.5-coder:1.5b для кодирования
  - Всего 6 моделей, GPU ускорение оптимизировано

- **Система мониторинга оптимизирована (19.09.2025)**
  - 8/8 exporters стандартизированы и оптимизированы
  - Redis/Nginx Exporter healthcheck исправлены (TCP проверки)
  - NVIDIA Exporter улучшен (TCP вместо pgrep)
  - Ollama Exporter стандартизирован (localhost вместо 127.0.0.1)
  - 100% доступность метрик на всех портах (HTTP 200)
  - Унифицированы timeout/retries параметры healthcheck

- **Система полностью восстановлена (29.08.2025)**
  - 37/37 контейнера работают стабильно
  - Все 29 ERNI-KI микросервисов работают
  - Cloudflare туннели восстановлены
  - Внешний доступ через все 5 доменов
  - Время отклика системы <0.01 секунды
  - GPU утилизация 25% (оптимально)

## 🔧 Troubleshooting

### Часто встречающиеся проблемы

#### 🌐 Проблемы с внешним доступом

```bash
# Проверка статуса Cloudflare туннеля
docker logs erni-ki-cloudflared-1 --tail 20

# Проверка DNS resolution
curl -s -o /dev/null -w "%{http_code}" https://diz.zone/
```

#### 🐳 Проблемы с контейнерами

```bash
# Проверка статуса всех сервисов
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(healthy|unhealthy)"

# Перезапуск проблемного сервиса
docker restart <container-name>
```

#### 🎮 Проблемы с GPU

```bash
# Проверка GPU статуса
nvidia-smi

# Проверка GPU в Ollama
curl -s http://localhost:11434/api/tags | jq '.models[].name'
```

#### 🔍 Проблемы с RAG поиском

```bash
# Тест SearXNG API
curl -s "http://localhost:8080/api/searxng/search?q=test&format=json" | jq '.results | length'
```

**Подробное руководство:** [docs/troubleshooting.md](docs/troubleshooting.md)

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле
[LICENSE](LICENSE).

## 🆘 Поддержка

- **📖 Документация:** [docs/](docs/)
- **🐛 Issues:** [GitHub Issues](https://github.com/DIZ-admin/erni-ki/issues)
- **💬 Discussions:**
  [GitHub Discussions](https://github.com/DIZ-admin/erni-ki/discussions)
- **🔧 Troubleshooting:** [docs/troubleshooting.md](docs/troubleshooting.md)

---

**⭐ Если проект оказался полезным, поставьте звезду на GitHub!**

## 🌐 Доступность веб-интерфейсов

- ✅ **OpenWebUI:** <http://localhost:8080/>
- ✅ **Tika:** <http://localhost:9998/>
- ✅ **Docling:** <http://localhost:8080/api/docling/>
- ✅ **EdgeTTS:** <http://localhost:5050/>
- ✅ **MCP Server:** <http://localhost:8000/>
- ✅ **LiteLLM:** <http://localhost:4000/>
- ✅ **Loki:** <http://localhost:3100/>
- ✅ **Fluent Bit:** <http://localhost:2020/>
  - Prometheus: <http://localhost:2020/api/v1/metrics/prometheus>
- ✅ **Webhook Receiver:** <http://localhost:9095/>
- ✅ **Prometheus:** <http://localhost:9091/>
- ✅ **Grafana:** <http://localhost:3000/>
- ✅ **Alertmanager:** <http://localhost:9093/>
- ✅ **Backrest:** <http://localhost:9898/>
- ✅ **cAdvisor:** <http://localhost:8081/>
- ✅ **Ollama Exporter:** <http://localhost:9778/metrics>
- ✅ **Nginx Exporter:** <http://localhost:9113/metrics>
- ✅ **RAG Exporter:** <http://localhost:9808/metrics>

---

## 📜 История обновлений

### 2025-10-02: Обновление мониторинга и логирования

**Обновленные сервисы:**

- ✅ **Prometheus:** v2.47.2 → v3.0.1 (+30% производительность, -14% память, 132
  правила алертов)
- ✅ **Loki:** v2.9.2 → v3.5.5 (TSDB v13, +40% скорость запросов, -9% память)
- ✅ **Fluent Bit:** v2.2.0 → v3.2.0 (новый синтаксис конфигурации, -10% память)
- ✅ **Alertmanager:** v0.26.0 → v0.28.0 (улучшенный UI, -9% память)

**Исправленные проблемы:**

- ✅ Добавлен volume mount для `conf/prometheus/alerts/` (12 дополнительных
  правил)
- ⚠️ Дублирование парсера 'postgres' в Fluent Bit (некритично)

**Результаты:**

- Все 30+ сервисов работают стабильно
- Общее улучшение производительности: +10-15%
- Снижение использования памяти: -10-14%
- Downtime: ~5 минут

**Документация:**
[.config-backup/update-execution-report-2025-10-02.md](.config-backup/update-execution-report-2025-10-02.md)

---

**Подготовлено:** Альтэон Шульц, Tech Lead **Дата:** 2025-10-02 **Версия:** 1.1
