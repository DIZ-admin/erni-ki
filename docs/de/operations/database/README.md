---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Data & Storage Übersicht

> **Aktualität:** November 2025 (Release v12.1). Verwenden Sie diesen Abschnitt
> als Einstiegspunkt vor dem Übergang zu einzelnen Guides.

## Kurzstatus

| Komponente      | Status / Anleitung                                                                                                          | Letztes Update |
| --------------- | --------------------------------------------------------------------------------------------------------------------------- | -------------- |
| PostgreSQL 17   | `database-monitoring-plan.md`, `database-production-optimizations.md` – beschreiben pgvector, VACUUM, Alerts.               | 2025-10        |
| Redis 7-alpine  | `redis-monitoring-grafana.md`, `redis-operations-guide.md` – Defragmentierung, Watchdog, Grafana-Monitoring.                | 2025-10        |
| vLLM / LiteLLM  | `vllm-resource-optimization.md` + Skripte `scripts/monitor-litellm-memory.sh`, `scripts/redis-performance-optimization.sh`. | 2025-11        |
| Troubleshooting | `database-troubleshooting.md` – Checklisten für Latency/Locks, pgvector, Backups.                                           | 2025-10        |

## Wie Aktualität erhalten

1. Bei Änderungen der PostgreSQL/Redis-Einstellungen entsprechende Datei aus
   Tabelle aktualisieren und Datum im Abschnitt „Kurzstatus" festhalten.
2. Bei neuen Versionen (LiteLLM/RAG) – Status mit `README.md` (Abschnitt Data &
   Storage) und `docs/overview.md` synchronisieren.
3. `docs/archive/config-backup/monitoring-report*` verwenden zur Fixierung von
   Cron-Ergebnissen und Links zu diesen Guide-Seiten.
