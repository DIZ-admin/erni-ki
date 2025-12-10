---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Technical Maintenance

All advanced maintenance procedures: backups, service restarts, Docling volume
cleanup and image update checklists. Summary of regulations for backup, image
updates and shared storage cleanup.

## Documents

- [backup-restore-procedures.md](backup-restore-procedures.md) — regulations for
  creating backups and restoration.
- [docling-shared-volume.md](docling-shared-volume.md) — storage policy,
  security and cleanup of Docling shared volume.
- [image-upgrade-checklist.md](image-upgrade-checklist.md) — step-by-step guide
  for updating containers and checking digests.
- [service-restart-procedures.md](service-restart-procedures.md) — matrix for
  safe restart of critical services.

## How to use

- Before updating dependencies — go through checklist.
- Planning Docling artifacts cleanup — reference the corresponding file.
- Before restarting services in production — follow procedures from
  `service-restart-procedures.md`.

Record operation results in Jira/Archon and update this README when adding new
procedures.

## Regular tasks

- **Daily:** check backups (`backrest`) and Docling volume free space. -
  **Weekly:** update images through checklist and smoke-test services. -
  **Monthly:** audit cron scripts, certificate rotation, inspect `./data/*` for
  garbage accumulation.

## Communication

1. Create ticket in Jira/Archon with description and window.
2. Notify interested teams 24 hours in advance.
3. After actions, attach logs, mark results in ticket and status page.

Use this README before performing maintenance work and record results in
Jira/Archon.
