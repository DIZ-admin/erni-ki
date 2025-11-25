# ERNI-KI — Production AI Platform

**ERNI-KI** — стэк из 30 сервисов вокруг OpenWebUI v0.6.36 и Ollama 0.12.11, Go
1.24.10 в CI, с GPU-ускорением, Context7/LiteLLM gateway и полной обсервабилити.

<!-- STATUS_SNIPPET_START -->

> **Статус системы (2025-11-23) — Production Ready v12.1**
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

## Quick Start

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
cp env/*.example env/ # заполните .env файлы
# (Рекомендуется) один раз скачать модели Docling
./scripts/maintenance/download-docling-models.sh
docker compose up -d
docker compose ps
```

Доступ: локально <http://localhost:8080>, production —
`https://ki.erni-gruppe.ch`.

## Branches, CI и политики

- Работа ведётся в `develop`, релизы в `main`. Все изменения через PR + review.
- Обязательные проверки: `ci` (ESLint/Ruff/Vitest/Go), `security`
  (CodeQL/Trivy), `deploy-environments`. Локально запускайте
  `pip install -r requirements-dev.txt` (для Ruff/pre-commit), `npm run lint`,
  `npm run test`, `go test ./auth/...`.
- Governance, CODEOWNERS и Dependabot — см.
  [`docs/operations/core/github-governance.md`](docs/operations/core/github-governance.md).
- GitHub Environments (development/staging/production), секреты и журнал
  проверок описаны в
  [`docs/reference/github-environments-setup.md`](docs/reference/github-environments-setup.md).
- Инциденты CI/GitHub Actions фиксируются в
  [`docs/archive/audits/ci-health.md`](docs/archive/audits/ci-health.md).

## Архитектура (коротко)

- **AI слой:** OpenWebUI + Ollama (GPU), LiteLLM gateway, MCP Server, Docling,
  Tika, EdgeTTS, RAG через SearXNG. Детали — `docs/ai/` и
  `docs/reference/api-reference.md`.
- **Данные:** PostgreSQL 17 + pgvector, Redis 7, Backrest, persistent volumes.
  Руководства — `docs/data/`.
- **Обсервабилити:** Prometheus, Grafana, Alertmanager, Loki, Fluent Bit, 8
  exporters. Схемы/alarms — `docs/operations/monitoring/monitoring-guide.md`.
- **Security & Networking:** Cloudflare Zero Trust, Nginx WAF, TLS 1.2/1.3,
  Docker Secrets, JWT-auth service. Инструкции —
  `scripts/infrastructure/security` и `docs/security/`.

## Документация

> **Версия документации:** см. [docs/VERSION.md](docs/VERSION.md) для текущего
> номера версии, даты и правил обновления.

| Тема                   | Где искать                                                                                                             |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Архитектура и обзор    | `docs/architecture/`, `docs/overview.md`                                                                               |
| Мониторинг/операции    | `docs/operations/monitoring/monitoring-guide.md`, `docs/archive/audits/monitoring-audit.md`                            |
| GitHub/CI Governance   | `docs/operations/core/github-governance.md`, `.github/`                                                                |
| Environments & секреты | `docs/reference/github-environments-setup.md` + `scripts/infrastructure/security/`                                     |
| Инциденты/аудиты       | `docs/archive/incidents/`, `docs/archive/audits/`                                                                      |
| Academy / Пользователи | `docs/academy/README.md`, `docs/index.md`, `docs/en/index.md`, `docs/de/index.md`                                      |
| HowTo / сценарии       | `docs/howto/`, `docs/en/academy/howto/`                                                                                |
| Статус системы         | `docs/operations/core/status-page.md`, `docs/system/status.md`, `docs/en/system/status.md`, `docs/de/system/status.md` |
| Аудит документации     | `docs/archive/audits/documentation-audit.md`                                                                           |

## Academy KI и пользовательские сценарии

- **Портал для пользователей:** заходите в `docs/index.md` (каноничный русский
  портал) или локализации `docs/en/index.md` / `docs/de/index.md`. или
  локализации `docs/en/index.md` / `docs/de/index.md`.
- **Быстрый старт:** используйте `docs/training/openwebui-basics.md` и чек-листы
  `docs/training/prompting-101.md`.
- **Практика:** готовые шаблоны и сценарии — в `docs/howto/` и переводах в
  `docs/en/academy/howto/`.
- **Статус сервисов:** перед обращением проверяйте
  `docs/operations/core/status-page.md` или локализованные страницы статуса
  (`docs/*/system/status.md`).

## Участие

1. Создайте issue (шаблоны в `.github/ISSUE_TEMPLATE/`).
2. Фичи — из `develop`, фиксы в PR -> `develop` -> `main`.
3. Убедитесь, что CI зелёный и документы обновлены.

License: MIT.
