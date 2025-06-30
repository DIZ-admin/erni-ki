# ERNI-KI 🤖

AI платформа на базе Open WebUI с полной контейнеризацией

[![CI](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml)
[![Security](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Обзор проекта

ERNI-KI — это комплексная AI платформа, построенная на базе
[Open WebUI](https://openwebui.com/) с полной контейнеризацией и современной
архитектурой. Проект включает в себя:

- **🔐 JWT Authentication Service** (Go) - безопасная аутентификация
- **🌐 Open WebUI** - пользовательский интерфейс для работы с LLM
- **🧠 Ollama** - локальный сервер для запуска языковых моделей
- **🔍 SearXNG** - приватный поисковый движок
- **📄 Document Processing** - обработка документов (Tika, Docling)
- **🗣️ Text-to-Speech** - синтез речи (EdgeTTS)
- **☁️ Cloudflare Integration** - безопасный доступ через туннели
- **📊 Monitoring** - мониторинг с Prometheus и Grafana

## 📋 Содержание

- [🚀 Обзор проекта](#-обзор-проекта)
- [⚡ Быстрый старт](#-быстрый-старт)
- [🔧 Конфигурация](#-конфигурация)
- [🐳 Docker сервисы](#-docker-сервисы)
- [🛠️ Разработка](#️-разработка)
- [📊 Мониторинг](#-мониторинг)
- [🔒 Безопасность](#-безопасность)
- [🤝 Участие в проекте](#-участие-в-проекте)
- [📄 Лицензия](#-лицензия)

## ⚡ Быстрый старт

### Требования

- **Docker** и **Docker Compose** v2.0+
- **Git**
- **Node.js** 20+ (для разработки)
- **Go** 1.23+ (для auth сервиса)
- Доменное имя (для Cloudflare)
- NVIDIA GPU (опционально, для ускорения)

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
# Сборка auth сервиса
npm run docker:build

# Запуск всех сервисов
npm run docker:run

# Просмотр логов
npm run docker:logs
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

## 🐳 Docker сервисы

Проект использует Docker Compose для оркестрации следующих сервисов:

- **auth** - Go сервис для JWT аутентификации
- **openwebui** - основной веб-интерфейс
- **ollama** - сервер языковых моделей
- **db** - PostgreSQL с pgvector
- **redis** - кэш и брокер сообщений
- **searxng** - метапоисковый движок
- **nginx** - обратный прокси
- **cloudflared** - Cloudflare туннель
- **docling** - обработка документов
- **tika** - извлечение метаданных
- **edgetts** - синтез речи
- **watchtower** - автообновление контейнеров

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

## 🤝 Участие в проекте

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'feat: add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Создайте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для
деталей.

---

**Создано с ❤️ командой ERNI-KI**
