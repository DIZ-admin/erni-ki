# 🤖 ERNI-KI - Production-Ready AI Platform

**ERNI-KI** — современная AI платформа на базе Open WebUI с полной
контейнеризацией, GPU ускорением и enterprise-grade безопасностью. Система
включает **29 микросервисов ERNI-KI** с полным мониторингом стеком (35+ активных
targets), AI метриками, централизованным логированием и автоматизированным
управлением.

> **🚀 Последние обновления (август 2025):** Устранены критические проблемы DNS
> в Cloudflare туннелях, оптимизирован SearXNG API (<0.8s), настроено ручное
> управление Backrest, подтверждено GPU ускорение Ollama. Elasticsearch заменен
> на Loki для централизованного логирования. Система готова к production
> использованию.

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

- **Основной домен:** https://ki.erni-gruppe.ch
- **Альтернативный:** https://diz.zone
- **Локальный доступ:** http://localhost:8080

## ✨ Ключевые возможности

### 🤖 **AI & Machine Learning**

- **Open WebUI** - современный веб-интерфейс для работы с LLM
- **Ollama** - локальный сервер языковых моделей с GPU ускорением (NVIDIA Quadro
  P2200)
  - 6 предустановленных моделей включая qwen2.5-coder:1.5b для кодирования
  - Время генерации: ~1.5 секунды (GPU ускорение)
- **LiteLLM** - унифицированный API для различных LLM провайдеров
  (оптимизированная конфигурация с 6GB memory limits)
- **RAG поиск** - интеграция с SearXNG (Startpage, Brave, Bing движки)
  - Время ответа: <3 секунды, 60+ результатов поиска
- **MCP серверы** - расширенные возможности через Model Context Protocol
- **Docling** - обработка документов с OCR поддержкой (EN, DE, FR, IT)
- **Apache Tika** - извлечение текста из документов различных форматов
- **EdgeTTS** - синтез речи для голосового вывода

### 🔒 **Enterprise Security**

- **JWT аутентификация** - собственный Go сервис для безопасного доступа
- **Cloudflare Zero Trust** - безопасные туннели без открытых портов
- **Nginx WAF** - защита от XSS, CSRF, DDoS атак с rate limiting
  - ✨ **Новое**: Оптимизированное логирование с условными правилами
  - ✨ **Новое**: WebSocket поддержка для real-time соединений
  - ✨ **Новое**: Увеличенные timeout (до 15 минут) для загрузки больших файлов
- **SSL/TLS** - полное шифрование с HSTS и современными cipher suites
- **Docker Secrets** - безопасное хранение паролей и ключей
- **Сетевая изоляция** - многоуровневая архитектура с изолированными сетями

### 📊 **Data & Storage**

- **PostgreSQL 15 + pgvector** - векторная база данных для RAG
- **Redis Stack** - высокопроизводительное кэширование и сессии
- **Backrest** - автоматические резервные копии с шифрованием (7 дней daily + 4
  недели weekly)
- **Apache Tika** - извлечение текста из документов
- **Persistent volumes** - надежное хранение данных

### 📈 **Monitoring & Operations**

- **Prometheus** - сбор метрик производительности (35 активных targets)
- **Grafana** - визуализация и дашборды
- **AlertManager** - уведомления о критических событиях
- **Webhook Receiver** - обработка и логирование алертов
- **GPU мониторинг** - NVIDIA GPU метрики (температура, память, утилизация)
- **AI метрики** - Ollama exporter (модели, размеры, производительность)
- **Веб-аналитика** - Nginx exporter (соединения, запросы, upstream'ы)
- **Health checks** - автоматический мониторинг состояния всех 29 сервисов
- **Watchtower** - автоматические обновления контейнеров
- **Centralized logging** - Fluent-bit → Elasticsearch для всех компонентов
- ✨ **Новое**: 100% покрытие мониторинга (35/35 targets активны)
- ✨ **Новое**: AI метрики для 3 моделей (nomic-embed-text, gpt-oss, gemma3n)

## 🏗️ Архитектура системы

ERNI-KI состоит из **29 микросервисов ERNI-KI**, организованных в несколько
слоев:

```text
🌐 External Layer (Cloudflare Zero Trust)
    ↓
🚪 Gateway Layer (Nginx + Auth Service + Cloudflared)
    ↓
🤖 Application Layer (OpenWebUI + Ollama GPU + LiteLLM + MCP)
    ↓
🔍 Search & Processing (SearXNG + Docling + Tika + EdgeTTS)
    ↓
💾 Data Layer (PostgreSQL + pgvector + Redis + Backrest)
    ↓
📊 Monitoring & Observability (Prometheus + Grafana + Loki + 8 Exporters)
    ↓
🛠️ Infrastructure (Watchtower + Docker + NVIDIA Runtime)
```

**Подробная архитектура:** [docs/architecture.md](docs/architecture.md)

## 📋 Системные требования

### Минимальные требования

- **OS:** Linux (Ubuntu 20.04+ / CentOS 8+ / Debian 11+)
- **CPU:** 4 cores (Intel/AMD x64)
- **RAM:** 16 GB
- **Storage:** 100 GB SSD
- **Docker:** 24.0+ с Docker Compose v2
- **Network:** 1 Gbps

### Рекомендуемые требования

- **CPU:** 8+ cores
- **RAM:** 32+ GB
- **GPU:** NVIDIA с 8+ GB VRAM (для Ollama)
- **Storage:** 500+ GB NVMe SSD
- **Network:** 10 Gbps

## 📚 Документация

| Документ                                          | Описание                                        |
| ------------------------------------------------- | ----------------------------------------------- |
| [📊 Services Overview](docs/services-overview.md) | **🆕 НОВОЕ** Детальная таблица всех 29 сервисов |
| [📦 Installation Guide](docs/installation.md)     | Детальная установка и настройка                 |
| [🏗️ Architecture](docs/architecture.md)           | Архитектура системы с диаграммами               |
| [👨‍💼 Administration](docs/administration.md)       | Администрирование и мониторинг                  |
| [🔧 Troubleshooting](docs/troubleshooting.md)     | Решение проблем и FAQ                           |
| [📡 API Reference](docs/api-reference.md)         | API документация для интеграций                 |

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

- **Мониторинг достиг совершенства**
  - 35/35 Prometheus targets активны (100% успех)
  - Все 29 ERNI-KI сервисов здоровы
  - AI метрики: 3 модели мониторятся
  - Централизованное логирование работает
  - Система работает на 100% от оптимального уровня

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

**⭐ Если проект оказался полезным, поставьте звезду на GitHub!** 🌐 Доступность
всех веб-интерфейсов: ✅ OpenWebUI: http://localhost:8080/ ✅ Tika:
http://localhost:9998/ ✅ Docling: http://localhost:8080/api/docling/ ✅
EdgeTTS: http://localhost:5050/ ✅ MCP Server: http://localhost:8000/ ✅
LiteLLM: http://localhost:4000/ ✅ Loki: http://localhost:3100/ ✅ Fluent Bit:
http://localhost:2020/ ✅ Webhook Receiver: http://localhost:9095/ ✅
Prometheus: http://localhost:9091/ ✅ Grafana: http://localhost:3000/ ✅
Alertmanager: http://localhost:9093/ ✅ Backrest: http://localhost:9898/ ✅
cAdvisor: http://localhost:8081/ ✅ Ollama Exporter:
http://localhost:9778/metrics ✅ Nginx Exporter: http://localhost:9113/metrics
