---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Operations Dokumentation

Runbooks, Anleitungen und Prozesse zur Verwaltung der ERNI-KI Plattform.

## Inhalt

### Kern-Guides

- **[admin-guide.md](core/admin-guide.md)** – Administration
  - Nutzerverwaltung, Service-Konfiguration, Backup/Restore, Security

- **[monitoring-guide.md](monitoring/monitoring-guide.md)** – Monitoring
  - Prometheus Metriken/Alerts, Grafana Dashboards (5), Loki Logs, SLO-Tracking

### Troubleshooting & Runbooks

- **[troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md)** –
  Diagnosen & typische Issues
- **Maintenance:**
  [Service restarts](maintenance/service-restart-procedures.md),
  [Backup & Restore](maintenance/backup-restore-procedures.md)

### Spezialisierte Guides

- **Automation:**
  [Automated maintenance](automation/automated-maintenance-guide.md)
- **Database:** [Operations overview](database/README.md)
- **Monitoring:** [Monitoring guide](monitoring/monitoring-guide.md)

### Diagnostics

- **[diagnostics/README.md](diagnostics/README.md)** – Reports & Methodik

## Quick Start

**Operatoren:** [admin-guide.md](core/admin-guide.md)  
**Monitoring:** [monitoring-guide.md](monitoring/monitoring-guide.md)  
**Incidents:** [troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md)

## Operations-Rhythmus

- **Täglich:** Status-Page, `CronJobFailed`, Backup-Kontrolle.
- **Wöchentlich:** Audit laut `configuration-change-process.md`, Maintenance-Log
  pflegen.
- **Monatlich:** Restore-Übungen gemäß
  `maintenance/backup-restore-procedures.md`.

## Verwandte Doku

- [Architecture Overview](../architecture/README.md)
- [Getting Started](../getting-started/README.md)
- [Security Guide](../security/README.md)

## Version

Dokuversion: **12.1** · Letzte Aktualisierung: **2025-11-24**
