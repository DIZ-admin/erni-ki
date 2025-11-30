---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-30'
title: 'CI/CD и автоматизация'
---

# Обзор CI/CD и автоматизации ERNI-KI

Документ описывает локальные проверки, GitHub Actions и вспомогательные задачи,
которые обеспечивают качество кода и инфраструктуры.

## 1. Локальные проверки

- `pre-commit run --all-files` обязателен перед коммитом. Хуки включают:
  - `prettier`, `ruff`, `black`, `isort`, `mypy`
  - `detect-secrets`, `trufflehog`, `markdownlint`
  - `lychee` (офлайн), `status-snippet-check`, `no-emoji`
- Полный цикл: `npm run lint && npm run test && npm run test:coverage && mypy .`
  (см. [Testing Guide](../../development/testing-guide.md)).

## 2. GitHub Actions

### 2.1 `ci.yml` — Continuous Integration

| Job                   | Назначение                                        |
| --------------------- | ------------------------------------------------- |
| `lint`                | ESLint + Ruff + Prettier + npm audit + link check |
| `mypy`                | Статический анализ Python                         |
| `test-go`             | Go тесты + покрытие                               |
| `test-python`         | Pytest (tests/python) + coverage + report         |
| `test-js`             | Vitest + Playwright (mock mode)                   |
| `metadata-validation` | Проверка frontmatter и статуса локализаций        |
| `docker-build`        | Сборка и сканирование образа auth service         |
| `notify`              | Сводка результатов и статуса                      |

### 2.2 `security.yml`

- CodeQL анализ (Go/Node)
- `govulncheck`, `npm audit --omit=dev`, `pip-audit`
- TruffleHog + Gitleaks
- Trivy + Grype (образы), Checkov (Dockerfile/GitHub Actions/secrets)
- Проверка стуктуры секретов в env (development/staging/production)
- Итоговый отчёт `security-report`.

### 2.3 `docs-deploy.yml`

- Автоматическая сборка `mkdocs` и деплой на GitHub Pages при изменениях docs/
  или вручную (`workflow_dispatch`).

### 2.4 Прочие workflow

- `deploy-environments.yml` — деплой окружений через Terraform/Compose (manual).
- `nightly-audit.yml` — ночные проверки (link check, архивные отчёты).
- `update-status.yml` — синхронизация статус-сниппетов
  (`scripts/docs/update_status_snippet.py`).
- `release.yml` — релизная цепочка (теги, changelog).

## 3. Автоматизация в репозитории

- Bash/ Python скрипты в `scripts/`:
  - `scripts/docs/update_status_snippet_v2.py` — валидация и обновление
    статусных блоков.
  - `scripts/health-monitor-v2.sh` — отчёты по состоянию контейнеров.
  - `scripts/entrypoints/` — единообразные запускные скрипты сервисов.
- Cron задачи документированы в
  [automated-maintenance-guide](../automation/automated-maintenance-guide.md).

## 4. Как добавить новую проверку

1. Добавьте локальный скрипт/симку в `scripts/` или npm/python.
2. Подключите к `pre-commit` (если линтер) — `.pre-commit-config.yaml`.
3. Для CI:
   - либо расширьте существующий job в `ci.yml`,
   - либо создайте отдельный job с явной зависимостью от `lint`.
4. Обновите документацию (этот файл + Testing Guide), при необходимости mention
   в `README.md`.

## 5. Мониторинг CI/CD

- Статус workflow виден в GitHub → Actions. Критические ветки (`main`,
  `develop`) защищены обязательными проверками `ci`, `security`, `docs-deploy`.
- Рекомендация: перед merge запускать `pre-commit run --all-files` и
  `npm run test:coverage` локально, чтобы уменьшить время ожидания CI.

> Если workflow упал из-за link-check или status-snippet, запустите
> `python scripts/docs/visuals_and_links_check.py` и
> `python scripts/docs/update_status_snippet.py --check` локально, исправьте
> проблемы и повторите push.
