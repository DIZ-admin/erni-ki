---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Backup Guide

Quick guide to ERNI-KI backup procedures and links to detailed documentation.

## What We Cover

- PostgreSQL (OpenWebUI data)
- Configurations: `env/`, `conf/`, `compose.yml`
- User artifacts (uploads, Ollama models)
- Critical logs (last 7 days)
- TLS certificates

## Quick Checklist

1.**Automated Backrest Backups**

- Status: `docker compose ps backrest`
- Logs: `docker compose logs backrest --tail=50`
- History: `curl -s http://localhost:9898/api/v1/repos`

  2.**Pre-Change Backup**

- Take snapshot (Backrest full/incremental)
- Export config: `tar -czf config-$(date +%F).tgz env conf compose.yml`

  3.**Restore Validation (monthly)**

- Deploy to test environment
- Verify OpenWebUI + DB startup
- Ensure uploads and models are accessible

## When to Use What

-**Routine backups and vacuum/maintenance:**see
`operations/automation/automated-maintenance-guide.md`

-**Complete step-by-step backup/restore procedures:** use Backrest docs +
service restart runbook until a dedicated restore guide is published.

-**Service restart after restore:**see
`operations/maintenance/service-restart-procedures.md`

## RPO/RTO

-**RPO:**≤ 15 minutes (incremental backups + WAL streaming) -**RTO:**≤ 45
minutes for OpenWebUI + DB

- Check metrics monthly and record results in Backrest dashboard.

## Visualization: Backup Cycle

```mermaid
flowchart LR
  Schedule[Cron 01:30] --> Backrest[Backrest backup]
  Backrest --> Store[Storage ./data/backrest]
  Store --> Verify[Check restore --dry-run]
  Verify --> Report[Report to Archon/Jira]
```

## Checklist

- Verify successful nightly backup in Backrest logs.
- Perform weekly `--dry-run` restore to test environment.
- Update runbook instructions when changing schedule/storage.
