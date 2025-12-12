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

- **[Operations Handbook](./core/operations-handbook.md)** - System
  administration playbooks and escalation paths.
- **[Monitoring Guide](./monitoring/monitoring-guide.md)** - Monitoring
  architecture, exporters, dashboards, and alerting.

### Troubleshooting & Runbooks

- **Troubleshooting index:** [Common scenarios](./troubleshooting/index.md)
- **Maintenance:** [Service restarts](./maintenance/service-restart-procedures.md),
  [Docling volume](./maintenance/docling-shared-volume.md),
  [Image upgrades](./maintenance/image-upgrade-checklist.md)

### Specialized Guides

- **Automation:** [Automated maintenance](./automation/automated-maintenance-guide.md),
  [Docker log rotation](./automation/docker-log-rotation.md)
- **Database:** [Operations overview](./database/index.md)
- **Monitoring:** [Monitoring guide](./monitoring/monitoring-guide.md)

### Diagnostics

- **Diagnostics:** [Reports and methodology](./diagnostics/index.md)

## Quick Start

**For Operators:** Start with the [Operations Handbook](./core/operations-handbook.md).
**For Monitoring:** See [monitoring-guide.md](./monitoring/monitoring-guide.md).
**For Incidents:** Check [Troubleshooting](./troubleshooting/index.md).

## Operational Rhythm

- **Daily:** check status page, `CronJobFailed`, backup monitoring.
- **Weekly:** review automation logs and maintenance records.
- **Monthly:** practice restores and verify backup integrity.

## Related Documentation

- [Architecture Overview](../architecture/index.md)
- [Getting Started](../getting-started/index.md)
- [Security Guide](../security/index.md)

## Version

Documentation version:**12.1**Last updated:**2025-11-24**
