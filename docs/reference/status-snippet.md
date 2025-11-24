> **Статус системы (2025-11-23) — Production Ready v12.1**
>
> - Контейнеры: 32/32 services healthy
> - Графана: 5/5 Grafana dashboards (provisioned)
> - Алерты: 20 Prometheus alert rules active
> - AI/GPU: Ollama 0.12.11 + OpenWebUI v0.6.36 (GPU)
> - Context & RAG: LiteLLM v1.80.0.rc.1 + Context7, Docling, Tika, EdgeTTS
> - Мониторинг: Prometheus v3.0.0, Grafana v11.3.0, Loki v3.0.0, Fluent Bit
>   v3.1.0, Alertmanager v0.27.0
> - Автоматизация: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Примечание: Versions and dashboard/alert counts synced with compose.yml
---
language: ru
translation_status: complete
doc_version: '2025.11'
---
