---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Data & Storage Overview

> **Relevance:** November 2025 (Release v0.61.3). Use this section as an entry
> point before proceeding to individual guides.

## Current Status

| Component       | Status / Instructions                                                                                                       | Last Updated |
| --------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------ |
| PostgreSQL 17   | `database-monitoring-plan.md`, `database-production-optimizations.md` – describe pgvector, VACUUM, alerts.                  | 2025-10      |
| Redis 7-alpine  | `redis-monitoring-grafana.md`, `redis-operations-guide.md` – defragmentation, watchdog, Grafana monitoring.                 | 2025-10      |
| vLLM / LiteLLM  | `vllm-resource-optimization.md` + scripts `scripts/monitor-litellm-memory.sh`, `scripts/redis-performance-optimization.sh`. | 2025-11      |
| Troubleshooting | `database-troubleshooting.md` – checklists for latency/locks, pgvector, backups.                                            | 2025-10      |

## How to Maintain Relevance

1. When changing PostgreSQL/Redis settings, update the corresponding file from
   the table and record the date in the "Current Status" section.
2. When releasing new versions (LiteLLM/RAG) – synchronize status with
   `README.md` (Data & Storage section) and `docs/overview.md`.
3. Use `docs/archive/config-backup/monitoring-report*` to record cron results
   and links to these guide pages.
