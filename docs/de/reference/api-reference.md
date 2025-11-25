---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# ERNI-KI API Referenz

> **Dokumentversion:** 5.0 · **Stand:** 2025-11-14 · **API Version:** v1
> **Status:** Core Endpoints, LiteLLM Context7 und RAG verifiziert

## API-Überblick

[TOC]

REST-API für Chats, Modelle, Suche, Backups und User-Management. JWT ist für
alle Requests Pflicht (`Authorization: Bearer <token>`); Antworten enthalten
`model`, `estimated_tokens`, `sources[]`.

### RAG und Model Context Protocol

- **LiteLLM Context Engineering** (`/lite/api/v1/context`, `/lite/api/v1/think`)
  injiziert History und routet auf Ollama/Docling.
- **MCP Server** (`/api/mcp/**`) stellt Tools (Time, FS, Postgres, Memory) für
  MCPO bereit.
- **RAG** (`/api/search`, `/api/documents`, `/api/v1/chats/{chat_id}/rag`)
  spricht Docling/SearXNG an und liefert `source_id`, `source_url`, `cursor`,
  `tokens_used`.

### LiteLLM Context7 Gateway

LiteLLM v1.80.0.rc.1 als Context Layer (Thinking Tokens, MCP Tools, Ollama).

| Komponente       | Wert                                                   |
| ---------------- | ------------------------------------------------------ |
| Basis-URL        | `http://localhost:4000` (via nginx)                    |
| Health           | `/health`, `/health/liveliness`, `/health/readiness`   |
| Kontext-Methoden | `POST /lite/api/v1/context`, `POST /lite/api/v1/think` |
| Clients          | OpenWebUI, externe Agents, cURL/MCPO                   |
| Monitoring       | `scripts/monitor-litellm-memory.sh`, Grafana Dashboard |

#### Beispiel: Context API

```bash
curl -X POST http://localhost:4000/lite/api/v1/context \
 -H "Authorization: Bearer $LITELLM_TOKEN" \
 -H "Content-Type: application/json" \
 -d '{
 "input": "Summarize the latest Alertmanager queue state",
 "enable_thinking": true,
 "metadata": { "chat_id": "chat-uuid", "source": "api-reference" }
 }'
```

Antwort (gekürzt):

```json
{
  "model": "context7-lite-llama3",
  "context": [
    { "type": "history", "content": "..." },
    { "type": "rag", "content": "Alertmanager queue stable" }
  ],
  "thinking_tokens_used": 128,
  "estimated_tokens": 342
}
```

#### Thinking API `/lite/api/v1/think`

Streamt Server-Sent Events mit Phasen `thinking`, `action`, `observation`,
`final`. Ohne Streaming: JSON mit `reasoning_trace`, `output`, `tokens_used`.

### RAG Endpoints (Docling + SearXNG)

- `GET /api/v1/rag/status` – Health RAG-Pipeline
- `POST /api/search` – Föderierte Suche (Brave, Bing, Wikipedia)
- `POST /api/documents` – Upload/Indexierung via Docling
- `POST /api/v1/chats/{chat_id}/rag` – Quellen in Chat injizieren

Beispiel (Docling Upload):

```bash
curl -X POST https://ki.erni-gruppe.ch/api/documents \
 -H "Authorization: Bearer $TOKEN" \
 -F "file=@sample.pdf" \
 -F "metadata={\"category\":\"operations\",\"tags\":[\"redis\",\"alertmanager\"]};type=application/json"
```

### API Updates (September 2025)

- **SearXNG** `/api/searxng/search` gefixt: 404 behoben, RAG-Suche stabil, <2s,
  4 Engines.
- **Stabile Endpoints:** `/health`, `/v1.Backrest/*`, `/api/mcp/*`.

### Basis-URLs

- Production: `https://ki.erni-gruppe.ch/api/v1`
- Alternative: `https://diz.zone/api/v1`
- Dev: `http://localhost:8080/api/v1`
