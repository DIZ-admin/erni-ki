# Repository Guidelines

## Project Structure & Modules

- `services/` Go & Python services (e.g., `auth/`), `frontend/` and `tests/` for
  JS/TS (Vitest, Playwright).
- `docs/` MkDocs sources in `docs/en|ru/...`; generated site lives in `site/`
  (ignored).
- `scripts/` operational tooling (docs checks, backups, monitoring) and
  `env/*.example` templates copied to `env/*.env` in CI.
- `compose.yml` is the source of truth for runtime versions;
  docs/reference/status.yml mirrors it via
  `scripts/docs/update_status_snippet_v2.py`.

## Build, Test, and Development

- Install JS deps: `bun install` (uses `bun.lock`); install Python tooling:
  `pip install -r requirements-dev.txt`.
- Lint/format: `bunx eslint .`, `bunx prettier --check .`, `ruff check .`,
  `ruff format --check .`, `mypy --config-file mypy.ini`.
- Tests: `bunx vitest`, `bunx playwright test --reporter=html` (mocks by
  default), `pytest`, `go test ./auth/...`.
- Docs: `mkdocs build --strict`; link check:
  `lychee docs/**/*.md --config .lychee.toml`.
- Security quick check:
  `trivy fs --ignorefile .github/trivy.ignore --severity CRITICAL,HIGH .` (skip
  caches: `--skip-dirs .cache,node_modules,tests/node_modules`).

## Coding Style & Naming

- TypeScript/JS: follow ESLint + Prettier; prefer named exports; kebab-case for
  files, PascalCase for React components.
- Python: Ruff + Black-compatible style; type hints required in new code; prefer
  snake_case for functions/vars.
- Go: gofmt/goimports, `golangci-lint`; package paths scoped under `auth/`.
- Shell: source `scripts/common.sh` when possible; keep `set -euo pipefail` and
  log helpers.

## Testing Guidelines

- Add unit coverage alongside new code (Vitest/Pytest/Go); keep Playwright specs
  isolated and mock external calls.
- Name tests after behavior (e.g., `should_return_401_on_invalid_token`); place
  fixtures under `tests/fixtures` or Playwright `tests/e2e/fixtures`.
- For docs scripts, mirror updates in `docs/en/reference/script-catalog.md` when
  adding/removing scripts.

## Commit & Pull Requests

- Commit messages: `type: summary` (e.g., `ci: harden trivy skips`,
  `docs: sync status block`).
- Before pushing: `pre-commit run -a` and ensure
  `scripts/docs/check_archive_readmes.py` passes.
- PRs should include: scope summary, linked issue/Archon task, test results
  (`bunx vitest`, `pytest`, `go test`, `mkdocs build`), and screenshots for UI
  changes if applicable.

## Security & Configuration Tips

- Copy env templates:
  `for f in env/*.example; do cp "$f" \"${f%.example}.env\"; done` and fill
  secrets (never commit real secrets).
- Sensitive dirs `data/`, `secrets/`, `.config-backup/` are excluded from
  scans/builds—keep them local.
- Keep versions in `docs/reference/status.yml` aligned with `compose.yml` and
  regenerate snippets after changes.
