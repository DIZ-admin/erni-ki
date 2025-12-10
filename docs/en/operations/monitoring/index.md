---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Monitoring

Central navigator for monitoring guides: from here you can access the main
guide, runbooks for alerts, dashboards and investigations.

## What's Inside

- [monitoring-guide.md](monitoring-guide.md) — complete overview of monitoring
  architecture, exporters, health checks and procedures.
- [grafana-dashboards-guide.md](grafana-dashboards-guide.md) — description of
  key dashboards, metrics and best practices.
- [prometheus-alerts-guide.md](prometheus-alerts-guide.md) — alerting rules
  configuration and Alertmanager integration.
- [prometheus-queries-reference.md](prometheus-queries-reference.md) — reference
  for useful Prometheus queries.
- [legacy-monitoring-scripts-migration.md](legacy-monitoring-scripts-migration.md)
  — quick plan for migrating to `health-monitor-v2.sh` and other updated
  utilities.
- [rag-monitoring.md](rag-monitoring.md) and
  [searxng-redis-issue-analysis.md](searxng-redis-issue-analysis.md) — specific
  cases and playbooks.
- [access-log-sync-and-fluentbit.md](access-log-sync-and-fluentbit.md) —
  Nginx/Fluent Bit log collection and delivery.
- [alertmanager-noise-reduction.md](alertmanager-noise-reduction.md) — dealing
  with noisy alerts.

## Practical Application

1. Setting up monitoring for new environment — start with general guide.
2. Need a metric/query — open reference document.
3. For alerts use appropriate playbook or noise reduction analysis.

When adding a new exporter or runbook, update the README so that developers and
DevOps can quickly find materials.

## On-call Routine

1. Check Alertmanager for new incidents and compare with status page.
2. Review Grafana dashboards `Platform Overview`, `Exporters Health`,
   `Cost & Tokens`.
3. Daily check status of `PrometheusTargetsDown` and `LogPipelineLag`.

## What to Improve Next

- Add diagrams (Mermaid) with metrics/logs flows to new articles.
- When new exporter appears describe its configuration, ports and targets in
  separate section.

Update README when new exporters or runbooks appear.
