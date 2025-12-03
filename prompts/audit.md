# Goal

Conduct a comprehensive professional audit of the DIZ-admin/erni-ki project to
identify areas for improvement in code quality, security, infrastructure, and
maintainability. Produce a prioritized list of actionable recommendations to
reach industry best practices.

> **User Review Required (IMPORTANT)**  
> Этот документ описывает процесс аудита. Итоговый результат — отдельный Audit
> Report с конкретными задачами на исправление.

# Proposed Audit Areas

## 1) Codebase Hygiene & Standards

- Linting & formatting: eslint, prettier, ruff, shellcheck применены везде.
- Dead code: выявить устаревшие скрипты (например, health-monitor.sh vs v2),
  депрекейтнутые конфиги, «осиротевшие» ассеты.
- Project structure: логичная группировка в `scripts/`, `conf/`, `docs/`.
- Language compliance: англ. комментарии и доки (кроме локализованных файлов).

## 2) Security Posture

- Secret scanning: проверить `.gitleaks.toml`, историю коммитов на секреты.
- Dependency auditing: `package.json`, `poetry.lock`, `go.mod` на устаревшие или
  уязвимые версии (npm audit / snyk / dependabot).
- Container security: `compose.yml`, Dockerfile — non-root, pinned версии,
  минимальные базы.
- Permissions: права на файлы в `scripts/`, токены/permissions в CI/CD.

## 3) Infrastructure & DevOps

- CI/CD: анализ `.github/workflows` на эффективность и полноту проверок.
- Docker config: лимиты ресурсов, изоляция сетей, volume management.
- Environment management: соответствие `.env.example` и фактических переменных
  между dev/prod.

## 4) Testing & QA

- Coverage: покрытие pytest и JS/TS.
- E2E: сценарии Playwright в `tests/e2e` для ключевых пользовательских потоков.
- Reliability: flaky тесты, длительность прогонов.

## 5) Documentation & Onboarding

- Completeness: README, CONTRIBUTING, docs/ — сетап, архитектура, троблшутинг.
- Accuracy: соответствие текущему состоянию кода (шаги установки работают?).
- Localization: состояние переводов (например, `docs/locales/de/`).

# Verification Plan

Это план аудита; верификация означает выполнение шагов выше.

## Manual Checks

- `bun run lint` и `ruff check .` — базовая проверка.
- `gitleaks detect` — отсутствие секретов.
- Ручной обзор `scripts/` на дубликаты/устаревшие части.
- История GitHub Actions — паттерны падений и пропусков проверок.
