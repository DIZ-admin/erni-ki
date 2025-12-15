# ERNI-KI — Production AI Platform

**ERNI-KI** — Enterprise AI platform with 23+ services: OpenWebUI v0.6.40,
Ollama 0.13.0, LiteLLM v1.80.0, GPU acceleration, and full observability stack
(Prometheus, Grafana, Loki). Built with Go 1.24.11 auth service.

<!-- STATUS_SNIPPET_START -->

> **Статус системы (2025-12-15) — Production Ready v0.61.3**
>
> - Контейнеры: 34/34 services healthy
> - Графана: 5/5 Grafana dashboards (provisioned)
> - Алерты: 20 Prometheus alert rules active
> - AI/GPU: Ollama 0.13.0 + OpenWebUI v0.6.40 (GPU)
> - Context & RAG: LiteLLM v1.80.0-stable.1 + Context7, Docling, Tika, EdgeTTS
> - Мониторинг: Prometheus v3.7.3, Grafana v12.3.0, Loki v3.6.2, Fluent Bit
>   v4.2.0, Alertmanager v0.29.0
> - Автоматизация: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Примечание: Compose-synced: searxng 2025.11.21, cloudflared 2025.11.1, Tika
>   3.2.3.0-full, exporters hardened

<!-- STATUS_SNIPPET_END -->

[![CI](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml)
[![Security](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml)
[![Coverage](https://img.shields.io/badge/coverage-vitest%20v8-blue)](#testing)
[![Python Tests](https://img.shields.io/badge/pytest-332%20passed-brightgreen)](#testing)

## Quick Start

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki

# Create .env files from examples
# Linux/macOS:
for f in env/*.example; do cp "$f" "${f%.example}.env"; done

# (Recommended) Download Docling models once
./scripts/maintenance/download-docling-models.sh

# Start all services using modular compose configuration
./docker-compose.sh up -d
./docker-compose.sh ps

# Full merged config (manual) — use all layers together
docker compose -f compose/base.yml -f compose/data.yml -f compose/ai.yml -f compose/gateway.yml -f compose/monitoring.yml config >/tmp/erni-ki.compose.yaml
```

Access: Locally at <http://localhost:8080>, production —
`https://ki.erni-gruppe.ch`.

## Testing

- **TypeScript/JavaScript**: `bun run test:unit` (Vitest, coverage in
  `coverage/`)
- **Python**: `.venv/bin/python -m pytest tests/python/` (332 tests, pytest with
  hooks)
- **Mock E2E**: `bun run test:e2e:mock` (Playwright mock server)
- **Go**: `cd auth && go test ./...`
- **Full pipeline**: see `.github/workflows/ci.yml`

## Branches, CI, and Policies

- Work is done in `develop`, releases in `main`. All changes via PR + review.
- Mandatory checks: `ci` (ESLint/Ruff/Vitest/Go), `security` (CodeQL/Trivy),
  `deploy-environments`.
- Locally run: `pip install -r requirements-dev.txt` (for Ruff/pre-commit),
  `npm run lint`, `npm run test`, `go test ./auth/...`.
- Governance, CODEOWNERS, and Dependabot — see
  [`docs/en/operations/core/github-governance.md`](docs/en/operations/core/github-governance.md).
- GitHub Environments (development/staging/production), secrets, and audit logs
  are described in
  [`docs/en/reference/github-environments-setup.md`](docs/en/reference/github-environments-setup.md).
- CI/GitHub Actions incidents are recorded in
  [`docs/ru/archive/audits/ci-health.md`](docs/ru/archive/audits/ci-health.md).

## Architecture (Brief)

- **Modular Docker Compose:** 5 layered compose files (base → data → ai →
  gateway → monitoring). See `compose/README.md` for details. Use
  `./docker-compose.sh` wrapper for all operations.
- **AI Layer (9 services):** OpenWebUI v0.6.40, Ollama 0.13.0 (GPU), LiteLLM
  v1.80.0 gateway, MCP Server, Docling, Tika 3.2.3, SearXNG, EdgeTTS, Auth.
- **Data (2 services):** PostgreSQL 17 + pgvector, Redis 7.0.15, Backrest v1.10.
- **Gateway (3 services):** Nginx 1.29.3, Cloudflared 2025.11.1, Backrest.
- **Monitoring (7 services):** Prometheus v3.7.3, Grafana 12.3.0, Alertmanager
  v0.29.0, Loki 3.6.2, Uptime Kuma 2.0.2, Node Exporter, Postgres Exporter.
- **Security:** Cloudflare Zero Trust, Nginx WAF, TLS 1.2/1.3, Docker Secrets,
  JWT-auth service (Go 1.24.11).

## Documentation

> **Documentation Version:** 2025.11 - Last updated: December 2025

| Topic                   | Where to find                                                    |
| :---------------------- | :--------------------------------------------------------------- |
| Architecture & Overview | `docs/ru/architecture/`, `docs/ru/overview.md`                   |
| Monitoring/Operations   | `docs/ru/operations/monitoring/monitoring-guide.md`              |
| GitHub/CI Governance    | `docs/en/operations/core/github-governance.md`, `.github/`       |
| Environments & Secrets  | `docs/en/reference/github-environments-setup.md`                 |
| Incidents/Audits        | `docs/ru/archive/incidents/`, `docs/ru/archive/audits/`          |
| Academy / Users         | `docs/ru/academy/`, `docs/en/academy/`, `docs/de/academy/`       |
| System Status           | `docs/ru/system/status.md`, `docs/en/system/`, `docs/de/system/` |
| API Reference           | `docs/ru/api/index.md`, `docs/api/index.md`                      |

## Academy KI and User Scenarios

- **User Portal:** Visit `docs/ru/index.md` (canonical Russian portal) or
  localizations `docs/en/index.md` / `docs/de/index.md`.
- **Quick Start:** Use `docs/ru/academy/getting-started/` for onboarding.
- **By Role:** Guides for developers, managers, support in
  `docs/ru/academy/by-role/`.
- **Service Status:** Check `docs/ru/system/status.md` or localized status
  pages.

## Contribution

1. Create an issue (templates in `.github/ISSUE_TEMPLATE/`).
2. Features — from `develop`, fixes in PR -> `develop` -> `main`.
3. Ensure CI is green and documents are updated.

License: MIT.
