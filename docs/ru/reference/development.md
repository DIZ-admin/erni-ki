---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Development Guide — ERNI-KI

Этот документ описывает настройку окружения разработчика и базовые процессы.

## Требования

- Node.js 20+, npm
- Docker 24+ и Docker Compose v2
- (Опционально) NVIDIA Container Toolkit для локального теста GPU

## Быстрый старт разработчика

```bash
# Установка JS-зависимостей (фронт/скрипты)
npm install

# Юнит‑тесты
npm test

# Линтинг и форматирование (ESLint + Ruff + Prettier)
python -m pip install -r requirements-dev.txt
bun run lint
# Автоформат Python при необходимости
bun run format:py
```

## Локальный запуск сервисов

```bash
# Запуск всех контейнеров
docker compose up -d

# Логи сервиса
docker compose logs -f <service>

# Статус
docker compose ps
```

## Мониторинг и отладка

- Prometheus: <http://localhost:9091>
- Grafana: <http://localhost:3000> (admin/admin123)
- Fluent Bit (Prometheus): <http://localhost:2020/api/v1/metrics/prometheus>
- RAG Exporter: <http://localhost:9808/metrics>
- LiteLLM Context7: <http://localhost:4000/health> (liveliness/readiness)

Горячая перезагрузка конфигов:

```bash
curl -X POST http://localhost:9091/-/reload # Prometheus
curl -X POST http://localhost:9093/-/reload # Alertmanager
```

### LiteLLM & Context7 контроль

- Основные endpoints: `/lite/api/v1/context`, `/lite/api/v1/think`,
  `/lite/api/v1/models`, `/health/liveliness`.
- Для теста используйте `curl -s http://localhost:4000/health/liveliness` и
  `curl -X POST http://localhost:4000/lite/api/v1/context ...`.
- Скрипты наблюдения:
- `scripts/monitor-litellm-memory.sh` — cron/webhook уведомления при росте
  памяти LiteLLM.
- `scripts/infrastructure/monitoring/test-network-performance.sh` —
  latency-проверки маршрутов nginx ↔ LiteLLM ↔ Ollama/PostgreSQL/Redis.

## Конвенции кода

- Единый стиль форматирования (Prettier/ESLint)
- Понятные имена переменных и файлов
- Русские комментарии в ключевых конфигурациях

## Вклад в проект

Прочитайте CONTRIBUTING.md. Создавайте ветки feature/\*, оформляйте PR с кратким
описанием и ссылками на задачи/тикеты.

## Документация и статус-блок

- После изменения `docs/reference/status.yml` обязательно выполните
  `scripts/docs/update_status_snippet.py` — скрипт обновит
  `docs/reference/status-snippet.md` и вставку в `README.md`.
- Для MkDocs страниц используйте вставку сниппета. См. `docs/overview.md` как
  пример использования директивы `include-markdown`.
- В PR приложите результат `git status` подтверждающий, что README и snippet
  синхронизированы.
