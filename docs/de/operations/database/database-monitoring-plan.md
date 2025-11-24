---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Database Monitoring Plan

- PostgreSQL Exporter (`9188`) und LVM Metriken verwenden.
- Alert Rules setzen: `PostgreSQLDown`, `PostgreSQLHighConnections`.
- Mit `docs/operations/monitoring/monitoring-guide.md` und
  `conf/prometheus/alerts.yml` vergleichen.
