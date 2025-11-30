---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Мониторинг ERNI-KI

Центральный навигатор по руководствам мониторинга: отсюда можно перейти в
основной гайд, runbook-и по алертам, дашбордам и расследованиям.

## Что внутри

- [monitoring-guide.md](monitoring-guide.md) — полный обзор архитектуры
  мониторинга, exporters, health-checks и процедур.
- [grafana-dashboards-guide.md](grafana-dashboards-guide.md) — описание ключевых
  дашбордов, метрик и best practices.
- [prometheus-alerts-guide.md](prometheus-alerts-guide.md) — настройка правил
  алертинга и связь с Alertmanager.
- [prometheus-queries-reference.md](prometheus-queries-reference.md) —
  справочник полезных Prometheus-запросов.
- [rag-monitoring.md](rag-monitoring.md) и
  [searxng-redis-issue-analysis.md](searxng-redis-issue-analysis.md) — узкие
  случаи и playbooks.
- [access-log-sync-and-fluentbit.md](access-log-sync-and-fluentbit.md) — сбор и
  доставка логов Nginx/Fluent Bit.
- [alertmanager-noise-reduction.md](alertmanager-noise-reduction.md) — борьба с
  шумными алертами.

## Практическое применение

1. Настройка мониторинга новой среды — начните с общего гайда.
2. Нужна метрика/запрос — откройте reference-документ.
3. При алерте используйте соответствующий playbook или анализ noise reduction.

При добавлении нового exporter-а или runbook-а обновляйте README, чтобы
разработчики и DevOps быстро находили материалы.

## Рутина дежурного

1. Проверяйте Alertmanager на новые инциденты и сверяйте со статус-страницей.
2. Просматривайте Grafana дашборды `Platform Overview`, `Exporters Health`,
   `Cost & Tokens`.
3. Раз в сутки сверяйте состояние `PrometheusTargetsDown` и `LogPipelineLag`.

## Что улучшать дальше

- Добавляйте диаграммы (Mermaid) с потоками метрик/логов в новые статьи.
- При появлении нового экспортера описывайте его конфигурацию, порты и таргеты в
  отдельном разделе.

Обновляйте README при появлении новых exporter-ов или runbook-ов.
