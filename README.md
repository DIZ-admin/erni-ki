# 🤖 ERNI-KI - Современная AI платформа

**ERNI-KI** — это production-ready AI платформа на базе Open WebUI с полной контейнеризацией, GPU ускорением и комплексной системой безопасности.

[![CI](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml)
[![Security](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![GPU](https://img.shields.io/badge/NVIDIA-GPU%20Accelerated-green?logo=nvidia)](https://nvidia.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Возможности

### 🤖 **AI Интерфейс**
- **Open WebUI** - современный веб-интерфейс для работы с AI
- **Ollama** - локальный сервер языковых моделей с GPU ускорением
- **RAG поиск** - интеграция с SearXNG для поиска в реальном времени
- **MCP серверы** - расширенные возможности через Model Context Protocol

### 🔒 **Безопасность**
- **JWT аутентификация** - собственный Go сервис для безопасного доступа
- **Nginx reverse proxy** - защищенное проксирование с rate limiting
- **SSL/TLS шифрование** - полная поддержка HTTPS
- **Cloudflare Zero Trust** - безопасные туннели без открытых портов

### 📊 **Данные и хранение**
- **PostgreSQL + pgvector** - векторная база данных для RAG
- **Redis** - высокопроизводительное кэширование и сессии
- **Backrest** - автоматические резервные копии с шифрованием
- **Обработка документов** - поддержка Docling и Apache Tika

### 🛠️ **DevOps готовность**
- **Docker Compose** - полная контейнеризация всех сервисов
- **Health checks** - автоматический мониторинг состояния
- **Автообновления** - Watchtower для актуальных образов
- **Логирование** - централизованные логи всех компонентов

## 📋 Содержание

- [🚀 Возможности](#-возможности)
- [📋 Системные требования](#-системные-требования)
- [⚡ Быстрый старт](#-быстрый-старт)
- [🔧 Конфигурация](#-конфигурация)
- [🐳 Сервисы Docker Compose](#-сервисы-docker-compose)
- [🛠️ Разработка](#️-разработка)
- [📊 Мониторинг](#-мониторинг)
- [🔒 Безопасность](#-безопасность)
- [📚 Документация](#-документация)
- [🤝 Участие в разработке](#-участие-в-разработке)
- [📄 Лицензия](#-лицензия)

## 📋 Системные требования

### Минимальные требования
- **ОС**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **RAM**: 8GB (рекомендуется 16GB+)
- **Диск**: 50GB свободного места
- **Docker**: 20.10+ с Docker Compose v2

### Рекомендуемые требования
- **GPU**: NVIDIA GPU с 6GB+ VRAM для ускорения Ollama
- **RAM**: 32GB для больших языковых моделей
- **Диск**: SSD 100GB+ для оптимальной производительности

## ⚡ Быстрый старт

### Установка

1. **Клонирование репозитория**

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
```

2. **Создание конфигурационных файлов**

```bash
# Основной Docker Compose файл
cp compose.yml.example compose.yml

# Конфигурации сервисов
cp conf/cloudflare/config.example conf/cloudflare/config.yml
cp conf/mcposerver/config.example conf/mcposerver/config.json
cp conf/nginx/nginx.example conf/nginx/nginx.conf
cp conf/nginx/conf.d/default.example conf/nginx/conf.d/default.conf
cp conf/searxng/settings.yml.example conf/searxng/settings.yml
cp conf/searxng/uwsgi.ini.example conf/searxng/uwsgi.ini
```

3. **Настройка переменных окружения**

```bash
# Скопируйте и отредактируйте файлы окружения
cp env/auth.example env/auth.env
cp env/db.example env/db.env
cp env/ollama.example env/ollama.env
cp env/openwebui.example env/openwebui.env
cp env/redis.example env/redis.env
cp env/searxng.example env/searxng.env
# ... и другие по необходимости
```

4. **Запуск сервисов**

```bash
# Запускаем все сервисы
docker compose up -d

# Проверяем статус
docker compose ps

# Загружаем первую языковую модель
docker compose exec ollama ollama pull llama3.2:3b
```

## 🔧 Конфигурация

### Основные сервисы

| Сервис       | Порт  | Описание                 |
| ------------ | ----- | ------------------------ |
| Open WebUI   | 8080  | Основной веб-интерфейс   |
| Ollama       | 11434 | API для языковых моделей |
| Auth Service | 9090  | JWT аутентификация       |
| SearXNG      | 8080  | Поисковый движок         |
| PostgreSQL   | 5432  | База данных              |
| Redis        | 6379  | Кэш и очереди            |
| Nginx        | 80    | Обратный прокси          |

### Переменные окружения

Основные переменные для настройки в файлах `env/*.env`:

- `WEBUI_SECRET_KEY` - секретный ключ для JWT
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` - настройки БД
- `OLLAMA_BASE_URL` - URL для подключения к Ollama
- `SEARXNG_SECRET_KEY` - секретный ключ для SearXNG

## 🐳 Сервисы Docker Compose

| Сервис | Описание | Порты | Зависимости |
|--------|----------|-------|-------------|
| **nginx** | Reverse proxy и балансировщик | 80, 443, 8080 | - |
| **auth** | JWT аутентификация (Go) | 9090 | - |
| **openwebui** | Основной AI интерфейс | 8080 | auth, db, ollama |
| **ollama** | Сервер языковых моделей | 11434 | - |
| **db** | PostgreSQL + pgvector | 5432 | - |
| **redis** | Кэш и брокер сообщений | 6379, 8001 | - |
| **searxng** | Метапоисковый движок | 8080 | redis |
| **mcposerver** | MCP серверы | 8000 | - |
| **docling** | Обработка документов | 5001 | - |
| **tika** | Извлечение метаданных | 9998 | - |
| **edgetts** | Синтез речи | 5050 | - |
| **backrest** | Система резервного копирования | 9898 | db, redis |
| **cloudflared** | Cloudflare туннель | - | nginx |
| **watchtower** | Автообновление контейнеров | - | - |

## 🛠️ Разработка

### Настройка среды разработки

```bash
# Установка зависимостей Node.js
npm install

# Установка Git hooks
npm run prepare

# Проверка кода
npm run lint
npm run type-check
npm run format:check

# Тестирование
npm test

# Тестирование Go сервиса
cd auth && go test -v ./...
```

### Структура проекта

```
erni-ki/
├── auth/                 # Go JWT сервис
│   ├── main.go          # Основной файл
│   ├── main_test.go     # Тесты
│   ├── Dockerfile       # Docker образ
│   └── go.mod           # Go зависимости
├── conf/                # Конфигурации сервисов
├── env/                 # Переменные окружения
├── docs/                # Документация
├── monitoring/          # Конфигурации мониторинга
├── tests/               # TypeScript тесты
├── types/               # TypeScript типы
└── compose.yml.example  # Docker Compose шаблон
```

### Качество кода

Проект использует современные инструменты для обеспечения качества:

- **ESLint** (flat config) - статический анализ JavaScript/TypeScript
- **Prettier** - форматирование кода
- **TypeScript** - строгая типизация
- **Vitest** - тестирование с покрытием ≥90%
- **Husky** - Git hooks для автоматических проверок
- **Commitlint** - валидация conventional commits
- **Renovate** - автообновление зависимостей

## 📊 Мониторинг

Система мониторинга включает:

- **Prometheus** - сбор метрик
- **Grafana** - визуализация данных
- **Alertmanager** - уведомления о проблемах
- Health checks для всех сервисов

## 🔒 Безопасность

- JWT аутентификация с проверкой токенов
- Cloudflare Zero Trust туннели
- Регулярные security сканы (Gosec, npm audit)
- Принцип минимальных привилегий для контейнеров
- Автоматические обновления безопасности

## 📚 Документация

### 👤 Для пользователей
- [📖 Руководство пользователя](docs/user-guide.md) - работа с интерфейсом
- [🔍 Использование RAG поиска](docs/user-guide.md#rag-search) - поиск с SearXNG
- [🎤 Голосовые функции](docs/user-guide.md#voice) - синтез и распознавание речи

### 👨‍💼 Для администраторов
- [⚙️ Руководство администратора](docs/admin-guide.md) - управление системой
- [🔧 Руководство по установке](docs/installation-guide.md) - детальная установка
- [🛡️ Мониторинг и логи](docs/admin-guide.md#monitoring) - отслеживание состояния

### 👨‍💻 Для разработчиков
- [🏗️ Архитектура системы](docs/architecture.md) - техническая документация
- [🔌 Справочник API](docs/api-reference.md) - документация API
- [💻 Руководство разработчика](docs/development.md) - настройка среды разработки

## 🤝 Участие в разработке

Мы приветствуем вклад в развитие ERNI-KI! Пожалуйста, ознакомьтесь с [руководством разработчика](docs/development.md) для получения подробной информации.

### Быстрый старт для разработчиков
```bash
# Установка зависимостей для разработки
npm install

# Запуск тестов
npm test

# Линтинг кода
npm run lint

# Сборка auth сервиса
cd auth && go build
```

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

---

## 🎯 Статус проекта

- ✅ **Production Ready** - готов к использованию в продакшене
- 🔄 **Активная разработка** - регулярные обновления и улучшения
- 🛡️ **Безопасность** - регулярные аудиты безопасности
- 📊 **Мониторинг** - комплексная система мониторинга
- 🤖 **AI-First** - оптимизирован для AI рабочих нагрузок

**Создано с ❤️ командой ERNI-KI**
