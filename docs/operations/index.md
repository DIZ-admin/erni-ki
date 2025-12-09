---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Operations Documentation

This directory contains operational guides, runbooks, and procedures for
managing the ERNI-KI platform.

## Contents

### Core Guides

-**[admin-guide.md](../../operations/core/admin-guide.md)**- System
administration handbook (RU)

- User management
- Service configuration
- Backup and restore procedures
- Security management

-**[monitoring-guide.md](../../operations/monitoring/monitoring-guide.md)**-
Comprehensive monitoring documentation (RU)

- Prometheus metrics and alerts
- Grafana dashboards (5 provisioned)
- Loki log aggregation
- SLO (Service Level Objective) tracking

### Troubleshooting & Runbooks

-**[troubleshooting-guide.md](../../operations/troubleshooting/troubleshooting-guide.md)**-
Diagnostic procedures and common issues (RU) -**Maintenance:**
[Service restarts](../../operations/maintenance/service-restart-procedures.md)
(RU),
[Backup & Restore](../../operations/maintenance/backup-restore-procedures.md)
(RU)

### Specialized Guides

-**Automation:**
[Automated maintenance](../../operations/automation/automated-maintenance-guide.md)
(RU) -**Database:**[Operations overview](../../operations/database/index.md)
(RU) -**Monitoring:**
[Monitoring guide](../../operations/monitoring/monitoring-guide.md) (RU)

### Diagnostics

-**[diagnostics/index.md](../../operations/diagnostics/index.md)**- Diagnostic
reports and methodologies (RU)

## Quick Start

**For Operators:**Start with the
[admin-guide.md](../../operations/core/admin-guide.md) (RU).**For Monitoring:**
See [monitoring-guide.md](../../operations/monitoring/monitoring-guide.md) (RU).
**For Incidents:**Check
[troubleshooting-guide.md](../../operations/troubleshooting/troubleshooting-guide.md)
(RU).

## Operational Rhythm

-**Daily:**check status page, `CronJobFailed`, backup
monitoring. -**Weekly:**configuration change audit per
`configuration-change-process.md` and maintenance log
updates. -**Monthly:**practice restores per
`maintenance/backup-restore-procedures.md`.

## Related Documentation

- [Architecture Overview](../architecture/index.md)
- [Getting Started](../getting-started/index.md)
- [Security Guide](../../security/index.md) (RU)

## Version

Documentation version:**12.1**Last updated:**2025-11-24**
