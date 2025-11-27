---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Operations Documentation

This directory contains operational guides, runbooks, and procedures for
managing the ERNI-KI platform.

## Contents

### Core Guides

- **[admin-guide.md](core/admin-guide.md)** - System administration handbook
- User management
- Service configuration
- Backup and restore procedures
- Security management

- **[monitoring-guide.md](monitoring/monitoring-guide.md)** - Comprehensive
  monitoring documentation
- Prometheus metrics and alerts
- Grafana dashboards (5 provisioned)
- Loki log aggregation
- SLO (Service Level Objective) tracking

### Troubleshooting & Runbooks

- **[troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md)** -
  Diagnostic procedures and common issues
- **Maintenance:**
  [Service restarts](maintenance/service-restart-procedures.md),
  [Backup & Restore](maintenance/backup-restore-procedures.md)

### Specialized Guides

- **Automation:**
  [Automated maintenance](automation/automated-maintenance-guide.md)
- **Database:** [Operations overview](database/index.md)
- **Monitoring:** [Monitoring guide](monitoring/monitoring-guide.md)

### Diagnostics

- **[diagnostics/index.md](diagnostics/index.md)** - Diagnostic reports and
  methodologies

## Quick Start

**For Operators:** Start with the [admin-guide.md](core/admin-guide.md). **For
Monitoring:** See [monitoring-guide.md](monitoring/monitoring-guide.md). **For
Incidents:** Check
[troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md).

## Операционный ритм

- **Ежедневно:** проверка статус-страницы, `CronJobFailed`, контроль бэкапов.
- **Еженедельно:** аудит изменений по `configuration-change-process.md` и
  обновление журнала maintenance.
- **Ежемесячно:** тренировочные восстановления по
  `maintenance/backup-restore-procedures.md`.

## Связанная документация

- [Architecture Overview](../architecture/index.md)
- [Getting Started](../getting-started/index.md)
- [Security Guide](../security/README.md)

## Version

Documentation version: **12.1** Last updated: **2025-11-24**
