# 📋 ERNI-KI: Краткое резюме архитектуры

## 🎯 Обзор системы

**ERNI-KI** — это комплексная AI-платформа, построенная на микросервисной архитектуре с использованием Docker Compose. Система включает 25+ сервисов, организованных в 5 основных категорий.

## 📊 Статистика сервисов

| Категория | Количество | Основные компоненты |
|-----------|------------|-------------------|
| **Основные сервисы** | 3 | OpenWebUI, Ollama, LiteLLM |
| **Базы данных** | 3 | PostgreSQL, Redis, Elasticsearch |
| **Мониторинг** | 13 | Prometheus, Grafana, экспортеры, логирование |
| **Инфраструктура** | 4 | Nginx, Auth, Cloudflare, Watchtower |
| **Утилиты** | 6 | SearXNG, Backrest, Tika, Docling, EdgeTTS, MCP |

## 🔧 Ключевые технологии

- **Контейнеризация**: Docker Compose с 2 сетями (default, monitoring)
- **AI/ML**: Ollama (локальные LLM), LiteLLM (внешние провайдеры), GPU поддержка
- **Базы данных**: PostgreSQL с pgvector, Redis, Elasticsearch
- **Мониторинг**: Prometheus + Grafana + AlertManager + 7 экспортеров
- **Безопасность**: JWT аутентификация, SSL/TLS, Cloudflare туннели
- **Резервное копирование**: Backrest с автоматизированными бэкапами

## 🌐 Сетевая архитектура

```
Internet → Cloudflare → Nginx → OpenWebUI → Ollama/LiteLLM
                    ↓              ↓
                SearXNG ←→ PostgreSQL (векторная БД)
                    ↓              ↓
                 Redis ←→ Утилиты (Tika, Docling, EdgeTTS)
```

## 📈 Ресурсные требования

| Конфигурация | CPU | RAM | Storage | GPU |
|--------------|-----|-----|---------|-----|
| **Минимум** | 4 cores | 8GB | 100GB | Опционально |
| **Рекомендуемо** | 8 cores | 16GB | 500GB SSD | RTX 3060+ |
| **Production** | 16 cores | 32GB | 1TB NVMe | RTX 4090 |

## 🚀 Быстрый старт

```bash
# 1. Клонирование и настройка
git clone https://github.com/your-org/erni-ki.git
cd erni-ki
cp env/*.example env/*.env  # Настроить переменные

# 2. Запуск основных сервисов
docker compose up -d watchtower db redis auth nginx
docker compose up -d ollama litellm openwebui

# 3. Запуск мониторинга (опционально)
cd monitoring && docker compose -f docker-compose.monitoring.yml up -d

# 4. Проверка статуса
docker compose ps
```

## 🔍 Ключевые порты

| Сервис | Порт | Назначение |
|--------|------|------------|
| OpenWebUI | 8080 | Основной AI интерфейс |
| Ollama | 11434 | API языковых моделей |
| LiteLLM | 4000 | Прокси для внешних LLM |
| Grafana | 3000 | Дашборды мониторинга |
| Prometheus | 9091 | Сбор метрик |
| Backrest | 9898 | Управление бэкапами |
| Nginx | 80/443 | Веб-шлюз |

## 📊 Мониторинг и алерты

- **13 компонентов мониторинга** включая Prometheus, Grafana, AlertManager
- **7 экспортеров метрик**: Node, cAdvisor, Postgres, Redis, Nvidia, Blackbox
- **Централизованное логирование**: Fluent Bit → Elasticsearch → Kibana
- **Автоматические алерты** на критические события и производительность

## 🔒 Безопасность

- **Централизованная аутентификация** через JWT Auth Service
- **SSL/TLS терминация** в Nginx с автоматическими сертификатами
- **Cloudflare туннели** для безопасного внешнего доступа
- **Rate limiting** и защита от DDoS атак
- **Audit логирование** всех действий пользователей

## 💾 Резервное копирование

- **Автоматизированные бэкапы** через Backrest
- **Ежедневные и еженедельные** копии с ротацией
- **Веб-интерфейс управления** на порту 9898
- **Восстановление одним кликом** из любой точки времени

## 📚 Документация

Полная документация доступна в директории `docs/`:
- **[Подробная архитектура](erni-ki-architecture-documentation.md)** - Детальное описание всех сервисов
- **[Руководство администратора](admin-guide.md)** - Управление и обслуживание
- **[Руководство по установке](installation-guide.md)** - Пошаговая установка
- **[API справочник](api-reference.md)** - Документация API

---

> 💡 **Совет**: Начните с минимальной конфигурации и постепенно добавляйте компоненты мониторинга и дополнительные сервисы по мере необходимости.
