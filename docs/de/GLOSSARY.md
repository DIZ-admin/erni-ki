---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
title: 'Glossar'
---

# Glossar

Zentrale Begriffe in den ERNI-KI-Dokumenten.

## AI/ML Begriffe

### Context7

Context-Engineering-Framework mit LiteLLM-Integration für bessere Antworten
durch optimiertes Kontext- und Reasoning-Handling.

### Docling

Dokumenten-Service mit mehrsprachigem OCR (EN/DE/FR/IT), PDF/DOCX/PPTX-Parsing,
Strukturanalyse, Tabellen-/Bild-Erkennung. Port: 5001.

### EdgeTTS

Microsoft Edge Text-to-Speech: viele Sprachen, diverse Voices, Streaming,
Integration in OpenWebUI. Port: 5050.

### LiteLLM

Einheitlicher LLM-Gateway: mehrere Provider (OpenAI/Anthropic/Google/Azure),
Load-Balancing, Usage/Cost-Monitoring, Caching, Rate-Limits, Context7 Layer.
Port: 4000.

### MCP (Model Context Protocol)

Protokoll für Tools/Integrationen. MCP Server bietet sichere Tool-Ausführung,
geteilten Kontext und standardisierte Schemas. Port: 8000.

### Ollama

Lokaler LLM-Server mit GPU; Modelle in `./data/ollama`, konfiguriert via
`env/ollama.env`.

### OpenWebUI

Haupt-UI: Chat mit Bildern/Dokumenten, Modellverwaltung über LiteLLM/Ollama, RAG
via SearXNG/Docling, SSE-Endpoints. Port: 8080 (über Nginx).
