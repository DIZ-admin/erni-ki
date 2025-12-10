---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Development Guide — ERNI-KI

This document describes developer environment setup and basic processes.

## Requirements

- Node.js 20+, npm
- Docker 24+ and Docker Compose v2
- (Optional) NVIDIA Container Toolkit for local GPU testing

## Developer Quick Start

```bash
# Install JS dependencies (frontend/scripts)
npm install

# Unit tests
npm test

# Linting and formatting (ESLint + Ruff + Prettier)
python -m pip install -r requirements-dev.txt
bun run lint
# Auto-format Python if needed
bun run format:py
```

## Local Service Startup

```bash
# Start all containers
docker compose up -d

# Service logs
docker compose logs -f <service>

# Status
docker compose ps
```

## Monitoring and Debugging

- Prometheus: <http://localhost:9091>
- Grafana: <http://localhost:3000> (admin/admin123)
- Fluent Bit (Prometheus): <http://localhost:2020/api/v1/metrics/prometheus>
- RAG Exporter: <http://localhost:9808/metrics>
- LiteLLM Context7: <http://localhost:4000/health> (liveliness/readiness)

Hot reload configs:

```bash
curl -X POST http://localhost:9091/-/reload # Prometheus
curl -X POST http://localhost:9093/-/reload # Alertmanager
```

### LiteLLM & Context7 Control

- Main endpoints: `/lite/api/v1/context`, `/lite/api/v1/think`,
  `/lite/api/v1/models`, `/health/liveliness`.
- For testing use `curl -s http://localhost:4000/health/liveliness` and
  `curl -X POST http://localhost:4000/lite/api/v1/context ...`.
- Monitoring scripts:
- `scripts/monitor-litellm-memory.sh` — cron/webhook notifications on LiteLLM
  memory growth.
- `scripts/infrastructure/monitoring/test-network-performance.sh` — latency
  checks for nginx ↔ LiteLLM ↔ Ollama/PostgreSQL/Redis routes.

## Code Conventions

- Consistent formatting style (Prettier/ESLint)
- Clear variable and file names
- English comments in key configurations

## Contributing to the Project

Read CONTRIBUTING.md. Create feature/\* branches, submit PRs with brief
descriptions and links to tasks/tickets.

## Documentation and Status Block

- After changing `docs/reference/status.yml` make sure to run
  `scripts/docs/update_status_snippet.py` — the script will update
  `docs/reference/status-snippet.md` and the insert in `README.md`.
- For MkDocs pages use the snippet insert. See `docs/overview.md` for example
  usage of the `include-markdown` directive.
- In your PR attach the result of `git status` confirming that README and
  snippet are synchronized.
