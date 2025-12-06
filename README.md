# ERNI-KI — Production AI Platform

**ERNI-KI** — A stack of 30 services built around OpenWebUI v0.6.36 and Ollama
0.12.11, Go 1.24.10 in CI, with GPU acceleration, Context7/LiteLLM gateway, and
full observability.

<!-- STATUS_SNIPPET_START -->

> **Статус системы (2025-11-23) — Production Ready v0.61.3**
>
> - Контейнеры: 34/34 services healthy
> - Графана: 5/5 Grafana dashboards (provisioned)
> - Алерты: 20 Prometheus alert rules active
> - AI/GPU: Ollama 0.12.11 + OpenWebUI v0.6.36 (GPU)
> - Context & RAG: LiteLLM v1.80.0.rc.1 + Context7, Docling, Tika, EdgeTTS
> - Мониторинг: Prometheus v3.0.0, Grafana v11.3.0, Loki v3.0.0, Fluent Bit
>   v3.1.0, Alertmanager v0.27.0
> - Автоматизация: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Примечание: Versions and dashboard/alert counts synced with compose.yml

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
  [`docs/operations/core/github-governance.md`](docs/operations/core/github-governance.md).
- GitHub Environments (development/staging/production), secrets, and audit logs
  are described in
  [`docs/reference/github-environments-setup.md`](docs/reference/github-environments-setup.md).
- CI/GitHub Actions incidents are recorded in
  [`docs/archive/audits/ci-health.md`](docs/archive/audits/ci-health.md).

## Architecture (Brief)

- **Modular Docker Compose:** Infrastructure organized into 5 layered compose
  files (base → data → ai → gateway → monitoring). See `compose/README.md` for
  details. Use `./docker-compose.sh` wrapper for all operations.
- **AI Layer:** OpenWebUI + Ollama (GPU), LiteLLM gateway, MCP Server, Docling,
  Tika, EdgeTTS, RAG via SearXNG. Details — `docs/ai/` and
  `docs/reference/api-reference.md`.
- **Data:** PostgreSQL 17 + pgvector, Redis 7, Backrest, persistent volumes.
  Guides — `docs/data/`.
- **Observability:** Prometheus, Grafana, Alertmanager, Loki, Fluent Bit, 8
  exporters. Schemas/alarms — `docs/operations/monitoring/monitoring-guide.md`.
- **Security & Networking:** Cloudflare Zero Trust, Nginx WAF, TLS 1.2/1.3,
  Docker Secrets, JWT-auth service. Instructions —
  `scripts/infrastructure/security` and `docs/security/`.

## Documentation

> **Documentation Version:** See [docs/VERSION.md](docs/VERSION.md) for the
> current version number, date, and update rules.

| Topic                   | Where to find                                                                                                          |
| :---------------------- | :--------------------------------------------------------------------------------------------------------------------- |
| Architecture & Overview | `docs/architecture/`, `docs/overview.md`                                                                               |
| Monitoring/Operations   | `docs/operations/monitoring/monitoring-guide.md`, `docs/archive/audits/monitoring-audit.md`                            |
| GitHub/CI Governance    | `docs/operations/core/github-governance.md`, `.github/`                                                                |
| Environments & Secrets  | `docs/reference/github-environments-setup.md` + `scripts/infrastructure/security/`                                     |
| Incidents/Audits        | `docs/archive/incidents/`, `docs/archive/audits/`                                                                      |
| Academy / Users         | `docs/academy/README.md`, `docs/index.md`, `docs/en/index.md`, `docs/de/index.md`                                      |
| HowTo / Scenarios       | `docs/howto/`, `docs/en/academy/howto/`                                                                                |
| System Status           | `docs/operations/core/status-page.md`, `docs/system/status.md`, `docs/en/system/status.md`, `docs/de/system/status.md` |
| Documentation Audit     | `docs/archive/audits/documentation-audit.md`                                                                           |

## Academy KI and User Scenarios

- **User Portal:** Visit `docs/index.md` (canonical Russian portal) or
  localizations `docs/en/index.md` / `docs/de/index.md`.
- **Quick Start:** Use `docs/training/openwebui-basics.md` and checklists
  `docs/training/prompting-101.md`.
- **Practice:** Ready-made templates and scenarios — in `docs/howto/` and
  translations in `docs/en/academy/howto/`.
- **Service Status:** Before reporting issues, check
  `docs/operations/core/status-page.md` or localized status pages
  (`docs/*/system/status.md`).

## Contribution

1. Create an issue (templates in `.github/ISSUE_TEMPLATE/`).
2. Features — from `develop`, fixes in PR -> `develop` -> `main`.
3. Ensure CI is green and documents are updated.

License: MIT.
