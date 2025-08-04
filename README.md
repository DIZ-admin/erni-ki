# 🤖 ERNI-KI - Production-Ready AI Platform

**ERNI-KI** — современная AI платформа на базе Open WebUI с полной
контейнеризацией, GPU ускорением и enterprise-grade безопасностью.

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

# 3. Запуск системы
docker-compose up -d

# 4. Проверка статуса
docker-compose ps
```

**🌐 Доступ к интерфейсу:** http://localhost:8080

## ✨ Ключевые возможности

### 🤖 **AI & Machine Learning**

- **Open WebUI** - современный веб-интерфейс для работы с LLM
- **Ollama** - локальный сервер языковых моделей с GPU ускорением (NVIDIA Quadro
  P2200)
  - 6 предустановленных моделей включая qwen2.5-coder:1.5b для кодирования
  - Время генерации: ~1.5 секунды (GPU ускорение)
- **LiteLLM** - унифицированный API для различных LLM провайдеров (3 модели)
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

- **Prometheus** - сбор метрик производительности
- **Grafana** - визуализация и дашборды
- **AlertManager** - уведомления о критических событиях
- **Webhook Receiver** - обработка и логирование алертов
- **GPU мониторинг** - NVIDIA GPU метрики (температура, память, утилизация)
- **Health checks** - автоматический мониторинг состояния всех 25+ сервисов
- **Watchtower** - автоматические обновления контейнеров
- **Centralized logging** - структурированные логи всех компонентов

## 🏗️ Архитектура системы

ERNI-KI состоит из **20+ микросервисов**, организованных в несколько слоев:

```
🌐 External Layer (Cloudflare Zero Trust)
    ↓
🚪 Gateway Layer (Nginx + Auth Service)
    ↓
🤖 Application Layer (OpenWebUI + Ollama + LiteLLM)
    ↓
🔍 Search & Processing (SearXNG + Docling + Tika)
    ↓
💾 Data Layer (PostgreSQL + Redis)
    ↓
📊 Monitoring Layer (Prometheus + Grafana)
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

| Документ                                      | Описание                          |
| --------------------------------------------- | --------------------------------- |
| [📦 Installation Guide](docs/installation.md) | Детальная установка и настройка   |
| [🏗️ Architecture](docs/architecture.md)       | Архитектура системы с диаграммами |
| [👨‍💼 Administration](docs/administration.md)   | Администрирование и мониторинг    |
| [🔧 Troubleshooting](docs/troubleshooting.md) | Решение проблем и FAQ             |
| [📡 API Reference](docs/api-reference.md)     | API документация для интеграций   |

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

**Последний аудит (25.07.2025):**

- ✅ **25/25 сервисов healthy**
- ✅ **Ollama генерация:** 0.6s (qwen2.5:0.5b)
- ✅ **SearXNG поиск:** <1s (70+ результатов)
- ✅ **LiteLLM память:** 65% (4GB лимит)
- ✅ **Время восстановления:** 59 секунд

**Детальные результаты:**
[audit-report-erni-ki-2025-07-25.md](audit-report-erni-ki-2025-07-25.md)

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

- **Мониторинг улучшен**
  - 3 активных алерта для SearXNG
  - Все 20+ сервисов здоровы
  - Система работает на 98% от оптимального уровня

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
