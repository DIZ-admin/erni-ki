---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-12-19'
---

# ERNI Academy KI

English portal for ERNI KI users. Russian pages remain the canonical source;
this version tracks them and highlights the most important user links.

> **System status (2025-12-15) — Production Ready v0.61.3**
>
> - Services: 34/34 services healthy
> - Grafana: 5/5 Grafana dashboards (provisioned)
> - Alerts: 20 Prometheus alert rules active
> - AI/GPU: Ollama 0.13.0 + OpenWebUI v0.6.40 (GPU)
> - Context & RAG: LiteLLM v1.80.0-stable.1 + Context7, Docling, Tika, EdgeTTS
> - Monitoring: Prometheus v3.7.3, Grafana v12.3.0, Loki v3.6.2, Fluent Bit
>   v4.2.0, Alertmanager v0.29.0
> - Automation: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Note: Compose-synced: searxng 2025.11.21, cloudflared 2025.11.1, Tika
>   3.2.3.0-full, exporters hardened

- Start here: [Academy KI](./academy/index.md) — Open WebUI basics, Prompting
  101, HowTo, News.
- Quick start: [Open WebUI basics](./academy/openwebui-basics.md) and
  [Prompting 101](./academy/prompting-101.md).
- Practical scenarios: [HowTo collection](./academy/howto/index.md).
- Uptime first: **[System status](https://status.erni-ki.ch)** before you
  escalate an issue.
