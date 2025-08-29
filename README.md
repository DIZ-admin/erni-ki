# 🤖 ERNI-KI - Production-Ready AI Platform

**ERNI-KI** — современная AI платформа на базе OpenWebUI v0.6.26 с полной
контейнеризацией, GPU ускорением и enterprise-grade безопасностью. Система
включает **29 микросервисов ERNI-KI** + **9 внешних сервисов** с полным
мониторингом стеком (33/33 контейнера в статусе Healthy), AI метриками,
централизованным логированием и автоматизированным управлением.

> **✅ Статус системы (29 августа 2025):** Все критические проблемы устранены.
> Cloudflare туннели восстановлены, внешний доступ работает через все 5 доменов.
> Время отклика системы <0.01 секунды. GPU утилизация 25% (оптимально). Система
> полностью функциональна и готова к продуктивному использованию.

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

# 3. Запуск системы
docker-compose up -d

# 4. Проверка статуса
docker-compose ps
```

**🌐 Доступ к интерфейсу:**

- **Основной домен:** <https://ki.erni-gruppe.ch>
- **Альтернативный:** <https://diz.zone>
- **Локальный доступ:** <http://localhost:8080>

## ✨ Ключевые возможности

### 🤖 **AI & Machine Learning**

- **OpenWebUI v0.6.26** - современный веб-интерфейс с CUDA поддержкой
  - ✅ Статус: Healthy (9 минут работы)
  - 🔧 Порт: 8080
  - 🎮 GPU ускорение активно
- **Ollama 0.11.8** - локальный сервер языковых моделей с GPU ускорением
  - 🎮 NVIDIA Quadro P2200 (25% утилизация - оптимально)
  - 📚 9 загруженных моделей (llama3.2, gemma3, llava, whisper-tiny и др.)
  - ⚡ Время генерации: <0.5 секунды (GPU ускорение)
  - ✅ Статус: Healthy (1 час работы)
- **LiteLLM main-stable** - Context Engineering Gateway
  - 🔧 Порт: 4000
  - 🚀 Thinking tokens поддержка
  - ✅ Статус: Healthy (1 час работы)
- **RAG поиск** - интеграция с SearXNG
  - ⚡ Время ответа: <2 секунды
  - 🔍 6+ источников поиска
  - ✅ JSON API работает
- **MCP Server** - Model Context Protocol
  - 🔧 Порт: 8000
  - 🛠️ 4 активных инструмента (Time, PostgreSQL, Filesystem, Memory)
  - ✅ Статус: Healthy (2 часа работы)
- **Docling CPU** - обработка документов с многоязычным OCR
  - 🌍 Поддержка: EN, DE, FR, IT
  - 🔧 Порт: 5001
  - ✅ Статус: Healthy (2 дня работы)
- **Apache Tika** - извлечение текста из документов
  - 🔧 Порт: 9998
  - ✅ Статус: Healthy (3 дня работы)
- **EdgeTTS** - синтез речи
  - 🔧 Порт: 5050
  - ✅ Статус: Healthy (3 дня работы)

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

- **PostgreSQL 15.13 + pgvector 0.8.0** - векторная база данных
  - 🔧 Порт: 5432
  - ✅ Connections accepting
  - 🔗 Shared database (OpenWebUI + LiteLLM)
  - ✅ Статус: Healthy (2 часа работы)
- **Redis Stack** - кэширование и WebSocket manager
  - 🔧 Порт: 6379
  - 🔐 Аутентификация настроена
  - 🔄 LRU eviction policy
  - ✅ Статус: Healthy (9 минут работы)
- **Backrest** - автоматические резервные копии
  - 🔧 Порт: 9898
  - 📅 7 дней daily + 4 недели weekly retention
  - 📁 Локальные бэкапы в .config-backup/
  - ✅ Статус: Healthy (5 часов работы)
- **Persistent volumes** - надежное хранение данных

### 📈 **Monitoring & Operations (33/33 Healthy)**

- **Prometheus v2.55.1** - сбор метрик
  - 🔧 Порт: 9091
  - ✅ Статус: Healthy (57 минут работы)
- **Grafana** - визуализация и дашборды
  - 🔧 Порт: 3000
  - ✅ Статус: Healthy (58 минут работы)
- **AlertManager** - уведомления о событиях
  - 🔧 Порты: 9093-9094
  - ✅ Статус: Healthy (1 час работы)
- **Loki** - централизованное логирование
  - 🔧 Порт: 3100
  - ✅ Статус: Healthy (59 минут работы)
- **Fluent-bit** - сбор логов
  - 🔧 Порт: 24224
  - ✅ Статус: Running (1 час работы)
- **8 Exporters** - специализированные метрики
  - 🐘 PostgreSQL Exporter (порт 9187)
  - 🔴 Redis Exporter (порт 9121)
  - 🎮 NVIDIA GPU Exporter (порт 9445)
  - 🧠 Ollama AI Exporter (порт 9778)
  - 🚪 Nginx Web Exporter (порт 9113)
  - 🖥️ Node Exporter (порт 9101)
  - 🐳 cAdvisor (порт 8081)
  - 📦 Blackbox Exporter (порт 9115)
  - ✅ Все в статусе Healthy
- **Watchtower** - автоматические обновления
  - 🔧 Порт: 8091
  - ✅ Статус: Healthy (3 дня работы)

## 🏗️ Архитектура системы

ERNI-KI состоит из **29 микросервисов ERNI-KI** + **9 внешних сервисов**,
организованных в несколько слоев:

```text
🌐 External Layer (Cloudflare Zero Trust)
    ↓ ✅ 5 доменов активны, DNS исправлены
🚪 Gateway Layer (Nginx + Auth Service + Cloudflared)
    ↓ ✅ Все сервисы Healthy
🤖 Application Layer (OpenWebUI v0.6.26 + Ollama 0.11.8 + LiteLLM + MCP)
    ↓ ✅ GPU ускорение 25%, 9 моделей загружено
🔍 Search & Processing (SearXNG + Docling + Tika + EdgeTTS)
    ↓ ✅ RAG интеграция работает, <2с ответ
💾 Data Layer (PostgreSQL 15.13 + pgvector 0.8.0 + Redis Stack + Backrest)
    ↓ ✅ Shared database, WebSocket manager
📊 Monitoring & Observability (Prometheus v2.55.1 + Grafana + Loki + 8 Exporters)
    ↓ ✅ 33/33 контейнера Healthy
🛠️ Infrastructure (Watchtower + Docker + NVIDIA Runtime)
    ↓ ✅ Автообновления, GPU поддержка
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
| [📦 Installation Guide](docs/installation-guide.md)                      | Детальная установка и настройка           |
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
docker-compose up -d
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
docker-compose up -d              # Запуск всех сервисов
docker-compose down               # Остановка всех сервисов
docker-compose ps                 # Статус сервисов
docker-compose logs -f [service]  # Просмотр логов

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

- **Система полностью восстановлена (29.08.2025)**
  - 33/33 контейнера в статусе Healthy (100% успех)
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
- ✅ **Webhook Receiver:** <http://localhost:9095/>
- ✅ **Prometheus:** <http://localhost:9091/>
- ✅ **Grafana:** <http://localhost:3000/>
- ✅ **Alertmanager:** <http://localhost:9093/>
- ✅ **Backrest:** <http://localhost:9898/>
- ✅ **cAdvisor:** <http://localhost:8081/>
- ✅ **Ollama Exporter:** <http://localhost:9778/metrics>
- ✅ **Nginx Exporter:** <http://localhost:9113/metrics>
