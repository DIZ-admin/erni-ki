---
language: en
translation_status: partial
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# Image Upgrade Checklist (EN placeholder)

Use `docs/ru/operations/maintenance/image-upgrade-checklist.md` as the current
source. This placeholder will be replaced once an English version is authored.

## Upgrade Process

```mermaid
flowchart TD
    A[Check Release Notes] --> B[Backup Current State]
    B --> C[Pull New Image]
    C --> D[Test in Staging]
    D --> E{Tests Pass?}
    E -->|Yes| F[Deploy to Production]
    E -->|No| G[Rollback]
    F --> H[Monitor Health]
    H --> I[Update Documentation]
```

## Quick Steps

1. Review changelog for breaking changes
2. Backup volumes: `./scripts/maintenance/backup.sh`
3. Pull image: `docker compose pull <service>`
4. Restart: `docker compose up -d <service>`
5. Verify healthchecks
