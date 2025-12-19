---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-19'
---

# ERNI Academy KI

Willkommen im zentralen Lern- und Supportportal für ERNI KI. Hier finden Sie
Anleitungen zur Arbeit mit Open WebUI, Prompt-Beispiele und Produktneuigkeiten
auf Deutsch.

- Für den Schnellstart gehen Sie zu [Academy KI](academy/index.md).
- Folgen Sie Updates im [Newsfeed](academy/news/index.md).
- Wenn etwas nicht funktioniert, prüfen Sie zuerst den
  **[Systemstatus](system/status.md)**.

## Aktueller Plattformstatus

<!-- STATUS_SNIPPET_DE_START -->

> **Systemstatus (2025-12-15) — Production Ready v0.61.3**
>
> - Container: 34/34 services healthy
> - Grafana: 5/5 Grafana dashboards (provisioned)
> - Alerts: 20 Prometheus alert rules active
> - AI/GPU: Ollama 0.13.0 + OpenWebUI v0.6.40 (GPU)
> - Context & RAG: LiteLLM v1.80.0-stable.1 + Context7, Docling, Tika, EdgeTTS
> - Monitoring: Prometheus v3.7.3, Grafana v12.3.0, Loki v3.6.2, Fluent Bit
>   v4.2.0, Alertmanager v0.29.0
> - Automatisierung: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00,
>   Backrest 01:30, Watchtower selective updates
> - Hinweis: Mit compose.yml synchronisiert: searxng 2025.11.21, cloudflared
>   2025.11.1, Tika 3.2.3.0-full, Exporter gehärtet

<!-- STATUS_SNIPPET_DE_END -->

## Portal-Aufbau

1.**Russisch ist die kanonische Sprache.**Alle Materialien werden zuerst hier
veröffentlicht und dienen als Quelle für
Übersetzungen. 2.**Sprachumschalter**ermöglicht den Wechsel zu deutschen und
englischen Versionen der Seiten, wenn diese verfügbar sind. 3.**Einheitliche
Struktur**: Academy KI → Grundlagen, Prompting, HowTo, Neuigkeiten, sowie
Systembereich mit Zugriff auf Service-Status.
