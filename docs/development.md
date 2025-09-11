# 🔧 Development Guide — ERNI-KI

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

# Линтинг и форматирование
npm run lint
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

- Prometheus: http://localhost:9091
- Grafana: http://localhost:3000 (admin/admin123)
- Fluent Bit (Prometheus): http://localhost:2020/api/v1/metrics/prometheus
- RAG Exporter: http://localhost:9808/metrics

Горячая перезагрузка конфигов:

```bash
curl -X POST http://localhost:9091/-/reload  # Prometheus
curl -X POST http://localhost:9093/-/reload  # Alertmanager
```

## Конвенции кода

- Единый стиль форматирования (Prettier/ESLint)
- Понятные имена переменных и файлов
- Русские комментарии в ключевых конфигурациях

## Вклад в проект

Прочитайте CONTRIBUTING.md. Создавайте ветки feature/\*, оформляйте PR с кратким
описанием и ссылками на задачи/тикеты.
