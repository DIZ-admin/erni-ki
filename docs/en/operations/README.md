---
language: en
translation_status: partial
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Operations Documentation

Operational guides, runbooks, and procedures for ERNI-KI.

## Contents

### Core Guides

-**[admin-guide.md](../../de/operations/core/admin-guide.md)**— admin handbook
(users, config, backup/restore,
security) -**[monitoring-guide.md](../../de/operations/monitoring/monitoring-guide.md)**
— Prometheus alerts, Grafana dashboards, Loki logs, SLOs

### Troubleshooting & Runbooks

-**[troubleshooting-guide.md](../../de/operations/troubleshooting/troubleshooting-guide.md)**
— diagnostics and common issues

- Maintenance:
  [Service restarts](../../de/operations/maintenance/service-restart-procedures.md),
  [Backup & Restore](../../de/operations/maintenance/backup-restore-procedures.md)

### Specialized

-**Automation:**
[Automated maintenance](../../de/operations/automation/automated-maintenance-guide.md) -**Database:**[Operations overview](index.md) -**Monitoring:**
[Monitoring guide](../../de/operations/monitoring/monitoring-guide.md)

### Diagnostics

-**[index.md](index.md)**— reports and methodology

## Quick Start

- Operators: [admin-guide.md](../../de/operations/core/admin-guide.md)
- Monitoring:
  [monitoring-guide.md](../../de/operations/monitoring/monitoring-guide.md)
- Incidents:
  [troubleshooting-guide.md](../../de/operations/troubleshooting/troubleshooting-guide.md)

## Rhythm

- Daily: status page, CronJobFailed, backup checks
- Weekly: change audit per `configuration-change-process.md`, maintenance log
- Monthly: restore drills per `maintenance/backup-restore-procedures.md`

## Related

- [Architecture Overview](../architecture/index.md)
- [Getting Started](../getting-started/index.md)
- [Security Guide](../security/README.md)

## Version

Docs version:**12.1**· Last updated:**2025-11-24**
