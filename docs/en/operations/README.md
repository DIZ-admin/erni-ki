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

- **[admin-guide.md](core/admin-guide.md)** — admin handbook (users, config,
  backup/restore, security)
- **[monitoring-guide.md](monitoring/monitoring-guide.md)** — Prometheus alerts,
  Grafana dashboards, Loki logs, SLOs

### Troubleshooting & Runbooks

- **[troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md)** —
  diagnostics and common issues
- Maintenance: [Service restarts](maintenance/service-restart-procedures.md),
  [Backup & Restore](maintenance/backup-restore-procedures.md)

### Specialized

- **Automation:**
  [Automated maintenance](automation/automated-maintenance-guide.md)
- **Database:** [Operations overview](database/README.md)
- **Monitoring:** [Monitoring guide](monitoring/monitoring-guide.md)

### Diagnostics

- **[diagnostics/README.md](diagnostics/README.md)** — reports and methodology

## Quick Start

- Operators: [admin-guide.md](core/admin-guide.md)
- Monitoring: [monitoring-guide.md](monitoring/monitoring-guide.md)
- Incidents:
  [troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md)

## Rhythm

- Daily: status page, CronJobFailed, backup checks
- Weekly: change audit per `configuration-change-process.md`, maintenance log
- Monthly: restore drills per `maintenance/backup-restore-procedures.md`

## Related

- [Architecture Overview](../architecture/README.md)
- [Getting Started](../getting-started/README.md)
- [Security Guide](../security/README.md)

## Version

Docs version: **12.1** · Last updated: **2025-11-24**
