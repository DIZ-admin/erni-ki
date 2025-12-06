# Test Suites Overview

- `tests/unit` — fast unit checks; run `bun run test:unit`.
- `tests/integration` — service-level integration; may require local services.
- `tests/e2e` — Playwright UI flows; use `bun run test:e2e:mock` locally, ensure
  Playwright browsers installed.
- `tests/contracts` — API contract tests; require `CONTRACT_BASE_URL` and
  `CONTRACT_BEARER_TOKEN`. CI fails on `main/develop` if secrets missing; on
  other branches tests are skipped when base URL unset. Run:
  `CONTRACT_BASE_URL=... CONTRACT_BEARER_TOKEN=... bun run test:contracts`.
- `tests/load` — k6 smoke (`tests/load/smoke-auth-rag.js`); require
  `SMOKE_BASE_URL` (and optional `SMOKE_AUTH_TOKEN`, paths). CI uploads
  `artifacts/k6/summary.json` when enabled and fails on `main/develop` if base
  URL absent. Run: `SMOKE_BASE_URL=... k6 run tests/load/smoke-auth-rag.js`.
- `tests/python` — Python utilities; run `pytest tests/python/`.
- `tests/fixtures` — shared fixtures for JS/TS suites.

# Coverage

- Go/Python/JS coverage artifacts are uploaded only for primary toolchain
  versions (Go 1.24.x, Python 3.12, Bun 1.3.x) to avoid matrix duplication.
- Merge job expects artifacts: `go-coverage-report`, `python-coverage`,
  `js-coverage`.

# CI failure lookup

- Contract tests: job `contract-tests` (fails on protected branches if secrets
  absent).
- Load smoke: job `load-smoke`; artifacts in `k6-smoke-summary`.
- Observability configs: job `observability-configs` (fails on env
  placeholders/empty values on protected branches).
