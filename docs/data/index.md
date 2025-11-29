---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Data & Storage Overview

>**Актуальность:**ноябрь 2025 (Release v0.61.3).  
> Используйте этот раздел как точку входа перед переходом к отдельным гайдам.

## Краткое состояние

>**Каноничные файлы хранятся в `docs/operations/database/` (этот раздел — навигационный индекс без дублирующих копий).**

| Компонент         | Статус / инструкция                                                                                            | Последнее обновление |
| ----------------- | -------------------------------------------------------------------------------------------------------------- | -------------------- |
| PostgreSQL 17     | [`operations/database/database-monitoring-plan.md`](../operations/database/database-monitoring-plan.md),<br>`database-production-optimizations.md` – pgvector, VACUUM, алерты. | 2025-10 |
| Redis 7-alpine    | [`operations/database/redis-monitoring-grafana.md`](../operations/database/redis-monitoring-grafana.md),<br>`redis-operations-guide.md` – дефрагментация, watchdog, мониторинг Grafana. | 2025-10 |
| vLLM / LiteLLM    | [`operations/database/vllm-resource-optimization.md`](../operations/database/vllm-resource-optimization.md) + скрипты `scripts/monitor-litellm-memory.sh`, `scripts/redis-performance-optimization.sh`. | 2025-11 |
| Troubleshooting   | [`operations/database/database-troubleshooting.md`](../operations/database/database-troubleshooting.md) – чек-листы по latency/locks, pgvector, бэкапы. | 2025-10 |

## Как поддерживать актуальность

1. При изменении настроек PostgreSQL/Redis обновляйте соответствующий файл из
   таблицы и фиксируйте дату в разделе «Краткое состояние».
2. При релизе новых версий (LiteLLM/RAG) – синхронизируйте статус с
   `README.md` (раздел Data & Storage) и `docs/overview.md`.
3. Используйте `docs/archive/config-backup/monitoring-report*` для фиксации
   cron-результатов и ссылок на эти гайд-страницы.
