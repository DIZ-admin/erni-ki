# Automations

## Cron / Maintenance

- VACUUM: 03:00 (database housekeeping).
- Backrest backup: 01:30 (postgres/config backups).
- Docker cleanup: 04:00.
- Docling shared cleanup:
  `scripts/maintenance/docling-shared-cleanup.sh --apply` (cron recommended, see
  runbook).

## Watchtower / Image Updates

- Auto-update scopes: `ai-services`, `document-processing`, `auth-services`,
  `cache-services`, `logging-stack` (Fluent Bit), `tunnel-services`.
- Auto-update disabled for criticals: `nginx`, `postgres`, `ollama`, `openwebui`
  (monitor-only label).
- Digests pinned (e.g., redis:7.0.15-alpine; docling digest override). Use
  `docs/operations/maintenance/image-upgrade-checklist.md`.

## CI/CD (GitHub Actions)

- Pipelines: `ci` (lint/tests Go/TS/Python), `security` (CodeQL/Trivy),
  `deploy-environments`.
- Pre-commit enforced via husky and `.pre-commit-config.yaml`.
- golangci-lint used for auth service (complexity fixed in `verifyToken`).

## Pre-commit / Local Hooks

- Husky + lint-staged + pre-commit: prettier, detect-secrets, yaml/json/toml
  checks, Go fmt/imports, ESLint (where applicable).
- Phases of refactor (in progress): Phase 1–3 (performance quick wins,
  consolidation, DX/monitoring).

## Secrets & Checks

- detect-secrets runs in pre-commit; secrets stored in Docker secrets/GitHub
  envs only.
- CSP/CORS/ACL updates required when adding domains (see Security).

## Logging & Metrics Automation

- Logs: Fluent Bit → Loki (json-file drivers per tier); Promtail tails container
  logs to Loki (`conf/promtail/`).
- Metrics: exporters → Prometheus; Alertmanager routes to Webhook receiver
  (Slack/PagerDuty).
- Dashboards provisioned in `conf/grafana/provisioning/`.

## Pending/Planned Automations

- Read-only stateless: mount tmpfs/ro for nginx cache, searxng cache,
  redis/postgres exporters, auth.
- Grafana admin → Docker secrets.
- WebSocket rate limiting for Nginx.
- Centralized logging stack (Loki/Promtail) rollout.
- Integration smoke-tests for docker-compose (test yml + CI).
- Automated backup verification (Backrest restore on stage).
