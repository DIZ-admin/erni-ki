---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# 📡 Мониторинг ERNI-KI

Индекс руководств по мониторингу, алертам и логированию.

## Основные материалы

- [monitoring-guide.md](monitoring-guide.md) — архитектура мониторинга,
  экспортёры и health checks.
- [grafana-dashboards-guide.md](grafana-dashboards-guide.md) — описание
  дашбордов и ключевых метрик.
- [prometheus-alerts-guide.md](prometheus-alerts-guide.md) — работа с правилами
  и Alertmanager.
- [prometheus-queries-reference.md](prometheus-queries-reference.md) — полезные
  запросы.
- [rag-monitoring.md](rag-monitoring.md) и
  [searxng-redis-issue-analysis.md](searxng-redis-issue-analysis.md) — частные
  кейсы RAG/поиска.
- [access-log-sync-and-fluentbit.md](access-log-sync-and-fluentbit.md) и
  [alertmanager-noise-reduction.md](alertmanager-noise-reduction.md) —
  логирование и снижение шума по алертам.

## Рутина дежурного

1. Проверяйте Alertmanager на новые инциденты и сверяйте с статус-страницей.
2. Просматривайте Grafana дашборды `Platform Overview`, `Exporters Health`,
   `Cost & Tokens`.
3. Раз в сутки сверяйте состояние `PrometheusTargetsDown` и `LogPipelineLag`.

## Что улучшать дальше

- Добавляйте диаграммы (Mermaid) с потоками метрик/логов в новые статьи.
- При появлении нового экспортера описывайте его конфигурацию, порты и таргеты в
  отдельном разделе.

Обновляйте README при появлении новых exporter-ов или runbook-ов.
