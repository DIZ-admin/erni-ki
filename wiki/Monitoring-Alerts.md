# Monitoring & Alerts

## Стек

- Prometheus, Grafana, Alertmanager, Loki, Fluent Bit,
  blackbox/node/postgres/redis/ollama exporters.
- Все мониторинговые порты проброшены на `127.0.0.1`; для удалённого доступа
  используйте Nginx/VPN/SSH.

## Дашборды

- Provisioning: `conf/grafana/provisioning/`.
- Основные: системный обзор, сервисы AI, Docling pipeline, RAG SLA, базы данных,
  Nginx/Edge.

## Алерты

- Правила в `conf/prometheus/alerts/` (20 активных правил по состоянию на
  2025-11-23).
- Alertmanager конфиг: `conf/alertmanager/alertmanager.yml` (пример —
  `conf/alertmanager/alertmanager.yml.example`).
- Webhook receiver для кастомных действий: `conf/webhook-receiver/`.

## Логи

- Loki + Fluent Bit + Promtail (`conf/fluent-bit/`, `conf/promtail/`), заголовок
  многотенантности `X-Scope-OrgID: erni-ki`.
- Очистка логов выполнялась 2025-11-12 (см. проектные заметки).

## Диагностика

- Проверка целостности таргетов: `prometheus/targets` (через прокси).
- Blackbox-пробы для внешних endpoint (HTTP/TCP).
- Экспортер GPU: `nvidia-exporter` (локальный порт 9445).
- Диаграмма наблюдаемости: [[Diagrams#observability-pipeline]]
- SearXNG API ограничен ACL (RFC1918/localhost); для внешнего доступа обновите
  allowlist в `conf/nginx/conf.d/default.conf`.
