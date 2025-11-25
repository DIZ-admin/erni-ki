# Scripts Overview (current)

Lightweight inventory of active scripts. Rule of thumb: code comments/output
stay in English; docs live under `docs/`.

## Top-level helpers

- `rag-health-monitor.sh`, `rag-webhook-notify.sh`, `monitor-litellm-memory.sh`,
  `erni-ki-health-check.sh`, `cleanup-logs.sh`, `cleanup-backups.sh`
- `rotate-logs.sh`, `monitor-disk-space.sh` (portable paths; configure via env)
- `run-playwright-mock.sh`, `test-redis-connections.sh`,
  `redis-performance-optimization.sh`

## Docs tooling

- `docs/update_status_snippet.py`, `docs/check_archive_readmes.py`

## Entrypoints

- `entrypoints/litellm.sh`, `entrypoints/openwebui.sh`

## Maintenance

- `maintenance/docling-shared-cleanup.sh`,
  `maintenance/enforce-docling-shared-policy.sh`
- `maintenance/render-docling-cleanup-sudoers.sh`,
  `maintenance/install-docling-cleanup-unit.sh`
- `maintenance/redis-fragmentation-watchdog.sh`,
  `maintenance/download-docling-models.sh`
- `maintenance/webhook-logs-rotate.sh`

## Monitoring

- `monitoring/alertmanager-queue-cleanup.sh`,
  `monitoring/alertmanager-queue-watch.sh`
- `monitoring/docling-cleanup-permission-metric.sh`
- `monitoring/record-cron-status.sh`, `monitoring/update-cron-metrics.sh`
- `monitoring/test-alert-delivery.sh`

## Infrastructure

- `infrastructure/postgres-exporter-entrypoint.sh`
- `setup-monitoring.sh`, `health-monitor.sh`

## Utilities

- `utilities/log-monitoring.sh`, `utilities/setup-log-monitoring-cron.sh`
- `prettier-run.sh`, `post-websocket-monitor.sh`
- `functions/*.py` (RAG helpers), `rag-health-monitor.sh`,
  `rag-webhook-notify.sh`

Removed legacy wrappers: `update-critical-services.sh`, `critical-alert.sh`,
`translate_comments.py` (no targets/obsolete).
