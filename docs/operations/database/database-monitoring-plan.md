---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Database Monitoring Plan

- Используйте PostgreSQL Exporter (`9188`) и LVM metrics.
- Установите alert rules: `PostgreSQLDown`, `PostgreSQLHighConnections`.
- Сравните с `docs/operations/monitoring/monitoring-guide.md` и
  `conf/prometheus/alerts.yml`.
