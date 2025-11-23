---
language: de
translation_status: outdated
doc_version: '2025.11'
title: 'Runbooks & Troubleshooting (DE summary)'
version: '12.1'
date: '2025-11-22'
status: 'Production Ready'
audience: 'administrators'
---

# Runbooks & Troubleshooting (DE summary)

Kurzer Überblick über die wichtigsten Runbooks auf Deutsch. Die vollständigen
Versionen finden sich weiterhin unter `docs/operations/maintenance/` und
`docs/operations/troubleshooting/` (EN).

| Runbook               | Pfad                                                   | Beschreibung                                                               |
| :-------------------- | :----------------------------------------------------- | :------------------------------------------------------------------------- |
| Backup & Restore      | `operations/maintenance/backup-restore-procedures.md`  | PostgreSQL + Backrest Wiederherstellung, Validation-Schritte enthalten.    |
| Service Restart       | `operations/maintenance/service-restart-procedures.md` | Sicheres Neustarten einzelner Container mit Healthchecks.                  |
| Docling Shared Volume | `operations/maintenance/docling-shared-volume.md`      | Reinigung des Docling Upload-Volumes + Rechtefix.                          |
| Troubleshooting       | `operations/troubleshooting/troubleshooting-guide.md`  | Häufige Fehler (GPU, Redis, RAG) inkl. Befehle `docker logs`/`nvidia-smi`. |
| Configuration Changes | `operations/core/configuration-change-process.md`      | Genehmigter Prozess für Änderungen an Config/Compose.                      |

> Für laufende Vorfälle siehe auch `docs/archive/incidents/README.md` und die
> entsprechenden Berichte (Phase 1/2 usw.). Archon Tasks sollten alle Schritte
> spiegeln.

### Beispielbefehle

```bash
# Container neu starten (aus dem Service-Runbook)
docker compose restart openwebui

# Log-Analyse (Troubleshooting)
docker compose logs -f litellm | tail -n 100

# Backrest Restore ausführen (Backup-Runbook)
curl -X POST http://localhost:9898/v1.Backrest/Restore -d '{"name":"daily"}'
```

> Nach jedem Schritt bitte die Checks aus dem englischen Runbook ausführen
> (Health-Endpoint, `docker compose ps`) und Ergebnisse im Archon-Ticket
> dokumentieren.
