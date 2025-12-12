# Repository Guidelines

## Project Structure & Module Organization

- `compose/` — layered Docker Compose (base → monitoring). Use
  `./docker-compose.sh` for stack ops.
- `conf/` — service configs (Nginx, Prometheus, Grafana, Loki).
- `auth/` — Go auth/JWT service with its own `go.mod`.
- `scripts/` — maintenance/dev utilities.
- `docs/` — MkDocs site; localized user docs live in `docs/ru/` (default),
  `docs/en/`, `docs/de/`.
- `tests/` — JS/TS suites (`unit`, `integration`, `e2e`, `contracts`, `load`)
  plus Python tests in `tests/python/`.
- `env/` and `.env.example` — env templates; copy `*.example` → `*.env`.

## Build, Test, and Development Commands

- `bun install` — install JS/TS deps (Bun is pinned).
- `python -m venv .venv && source .venv/bin/activate && pip install -r requirements-dev.txt`
  — Python dev deps and pre‑commit.
- `./docker-compose.sh up -d` / `down` / `ps` — start/stop/status the platform.
- `bun run lint` / `bun run lint:fix` — ESLint (JS/TS) + Ruff (Python).
- `bun run format` / `format:check` — Prettier (JS/TS/MD) + Ruff format (py).
- `bun run test` / `test:unit` / `test:e2e:mock` / `test:e2e` — Vitest +
  Playwright suites.
- `cd auth && go test ./...` — Go auth service tests.

## Coding Style & Naming Conventions

- Indent 2 spaces; Go uses tabs (see `.editorconfig`).
- Python: Ruff lint/format, 100‑char lines, double quotes.
- JS/TS: strict typing, `async/await`, ESLint + Prettier.
- All code and configuration comments must be in English.
- `docs/` Markdown must include YAML frontmatter and follow the language policy.

## Testing Guidelines

- JS/TS tests use Vitest; name files `*.test.ts` under `tests/**`.
- E2E tests use Playwright; prefer the mock runner locally
  (`bun run test:e2e:mock`).
- Python tests use pytest; name files `tests/python/test_*.py`.
- CI enforces green tests and ≥80% coverage on protected branches.

## Commit & Pull Request Guidelines

- Conventional Commits required; commitlint blocks invalid messages.
- Branch from `develop` using `feature/<name>`, `fix/<name>`, `docs/<name>`,
  `ci/<name>`.
- Run pre‑commit before opening a PR: `pre-commit run --all-files` (or
  `bun run pre-commit:full`).
- PRs should explain the change, link issues, and update docs/config where
  relevant. No `TODO`/`FIXME` left in code.

## Security & Configuration Tips

- Never commit secrets; use `.env` files and Docker secrets instead.
- Optional local scan: `bun run security:scan`.
