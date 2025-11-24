---
language: en
translation_status: complete
doc_version: '2025.11'
title: 'Glossary'
---

# Glossary

Key terms and concepts used across the ERNI-KI documentation.

## AI & ML Terms

### Context7

A context engineering framework integrated with LiteLLM that improves AI
responses through better context management and advanced reasoning.

### Docling

Document processing service with:

- Multilingual OCR (EN, DE, FR, IT)
- Text extraction from PDF, DOCX, PPTX
- Structural analysis of documents
- Table and image recognition

Port: 5001

### EdgeTTS

Microsoft Edge Text-to-Speech service:

- Multiple language support
- Various voice options
- Streaming audio output
- Integration with Open WebUI

Port: 5050

### LiteLLM

Unified API gateway for LLMs:

- Consistent API across providers (OpenAI, Anthropic, Google, Azure)
- Load balancing between models
- Usage monitoring and cost tracking
- Caching and rate limiting
- Context Engineering via Context7

Port: 4000

### MCP (Model Context Protocol)

Protocol for extending AI capabilities via tools and integrations. MCP Server
provides:

- Secure tool execution
- Context sharing between agents
- Standardized tool schemas

Port: 8000

### Ollama

Local LLM server with GPU acceleration. Stores models in `./data/ollama`.
Configured via `env/ollama.env`.

### OpenWebUI

Main user interface for AI interactions:

- Chat UI with image and document support
- Model management and routing via LiteLLM/Ollama
- RAG integrations through SearXNG/Docling
- SSE streaming endpoints

Port: 8080 (proxied by Nginx)

### RAG Exporter

Prometheus exporter for RAG performance:

- `erni_ki_rag_response_latency_seconds`
- `erni_ki_rag_sources_count`
- Monitors SLA for RAG endpoints

Port: 9808

### SearXNG

Meta-search engine used for RAG:

- Supports multiple search providers (Brave, Startpage, Bing, Wikipedia)
- API endpoint: `/search?q=<query>&format=json`

Port: 8080

## Operations & Monitoring

### Alertmanager

Alert routing and notification service:

- Version: v0.27.0
- Channels: Slack/Teams
- Throttling and routing via Alertmanager config

### Grafana Dashboards

Provisioned dashboards (5):

- GPU/LLM
- Infrastructure
- SLA/Alertmanager
- Logs (Loki via Explore)
- RAG metrics

### Prometheus Alerts

20 active alert rules covering critical, performance, database, GPU, Nginx.
Defined in `conf/prometheus/alerts.yml`.

### Watchtower (monitor-only)

Monitors images without auto-updating critical services; selective updates only.

## Automation

### Maintenance Cron

Scheduled tasks:

- PostgreSQL VACUUM — 03:00
- Docker cleanup — 04:00
- Backrest backups — 01:30
- Log rotation daily
- Watchtower selective updates

### Scripts

- `scripts/maintenance/docling-shared-cleanup.sh` — cleans Docling shared volume
- `scripts/maintenance/redis-fragmentation-watchdog.sh` — defrag guard
- `scripts/monitoring/alertmanager-queue-watch.sh` — queue watchdog
- `scripts/infrastructure/security/monitor-certificates.sh` — TLS/Cloudflare
  expiry monitor

## Data & Storage

### PostgreSQL (17 + pgvector)

Shared DB for OpenWebUI and LiteLLM. See:

- `docs/operations/database/database-monitoring-plan.md`
- `docs/operations/database/database-production-optimizations.md`
- `docs/operations/database/database-troubleshooting.md`

### Redis (7-alpine)

Cache/WebSocket manager. See:

- `docs/operations/database/redis-monitoring-grafana.md`
- `docs/operations/database/redis-operations-guide.md`

### Backrest

Local backups (daily + weekly) stored in `.config-backup/`. Integration script:
`scripts/setup/setup-backrest-integration.sh`.

## Security

### Authentication

JWT-based auth for services; Auth service proxied via Nginx. Secrets stored in
env files (use `.example` and CI secrets, not git).

### TLS

Nginx handles SSL termination; Cloudflare tunnel optional. Certs in `conf/ssl/`.

### Logging Pipeline

Fluent Bit → Loki over TLS with shared key; certificate management via
`scripts/security/prepare-logging-tls.sh`.
