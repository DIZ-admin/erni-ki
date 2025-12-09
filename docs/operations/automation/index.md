---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Operational Task Automation

Section describes regulations and scripts that help maintain ERNI-KI clusters
without manual intervention. Use this index to quickly find cleanup, maintenance
or regular check procedures.

## Key documents

- [automated-maintenance-guide.md](automated-maintenance-guide.md) — schedule of
  daily/weekly tasks, watchdog script control, policy for auto-start
  Cron/systemd timers.
- [docker-cleanup-guide.md](docker-cleanup-guide.md) — automatic cleanup of
  Docker images/volumes, rotation of stuck containers, resource recommendations.
- [docker-log-rotation.md](docker-log-rotation.md) — logrotate and Fluent Bit
  configuration for container logs, storage parameters and monitoring overflows.

## When to refer to this section

- Regular preventive work before release.
- Preparing new environment (dev/stage/prod) with same automations.
- Setting up alerting for Cron/maintenance tasks.

**Tip:** after executing automated procedure, record result in
`docs/operations/maintenance/index.md` or in maintenance ticket.

## Automation health control

1. Check `logs/maintenance/*.log` daily for errors and duration.
2. Prometheus rule `CronJobFailed` should have SLA ≤ 1% unavailability.
3. All scripts run through `systemd` units; use
   `systemctl status erni-maintenance@*` before release.

## Contributing to automation library

- Place scripts in `scripts/automation/` with `erni-` prefix.
- Add dry-run mode to check changes before applying.
- Update corresponding section of this README and link script to runbook.

Update README when adding new automation scenarios.
