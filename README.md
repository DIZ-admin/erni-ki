# 🤖 ERNI-KI — Production AI Platform

**ERNI-KI** — стэк из 30 сервисов вокруг OpenWebUI v0.6.36 и Ollama 0.12.11, Go
1.24.10 в CI, с GPU-ускорением, Context7/LiteLLM gateway и полной обсервабилити.

<!-- STATUS_SNIPPET_START -->

> **Статус системы (2025-11-14) — Production Ready v12.1**
>
> - Контейнеры: 30/30 контейнеров healthy
> - Графана: 18/18 Grafana дашбордов
> - Алерты: 27 Prometheus alert rules активны
> - AI/GPU: Ollama 0.12.11 + OpenWebUI v0.6.36 (GPU)
> - Context & RAG: LiteLLM v1.80.0.rc.1 + Context7, Docling, Tika, EdgeTTS
> - Мониторинг: Prometheus v3.0.1, Grafana v11.6.6, Loki v3.5.5, Fluent Bit
>   v3.2.0, Alertmanager v0.28.0
> - Автоматизация: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Примечание: Наблюдаемость и AI стек актуализированы в ноябре 2025

<!-- STATUS_SNIPPET_END -->

[![CI](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/ci.yml)
[![Security](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml/badge.svg)](https://github.com/DIZ-admin/erni-ki/actions/workflows/security.yml)

## 🚀 Quick Start

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
cp env/*.example env/   # заполните .env файлы
# (Рекомендуется) один раз скачать модели Docling
./scripts/maintenance/download-docling-models.sh
docker compose up -d
docker compose ps
```

Доступ: локально <http://localhost:8080>, production —
`https://ki.erni-gruppe.ch`.

## 🛠️ Branches, CI и политики

- Работа ведётся в `develop`, релизы в `main`. Все изменения через PR + review.
- Обязательные проверки: `ci` (ESLint/Vitest/Go), `security` (CodeQL/Trivy),
  `deploy-environments`. Локально запускайте `npm run lint`, `npm run test`,
  `go test ./auth/...`.
- Governance, CODEOWNERS и Dependabot — см.
  [`docs/operations/github-governance.md`](docs/operations/github-governance.md).
- GitHub Environments (development/staging/production), секреты и журнал
  проверок описаны в
  [`docs/reference/github-environments-setup.md`](docs/reference/github-environments-setup.md).
- Инциденты CI/GitHub Actions фиксируются в
  [`docs/operations/ci-health.md`](docs/operations/ci-health.md).

## 🧱 Архитектура (коротко)

- **AI слой:** OpenWebUI + Ollama (GPU), LiteLLM gateway, MCP Server, Docling,
  Tika, EdgeTTS, RAG через SearXNG. Детали — `docs/ai/` и
  `docs/reference/api-reference.md`.
- **Данные:** PostgreSQL 17 + pgvector, Redis 7, Backrest, persistent volumes.
  Руководства — `docs/data/`.
- **Обсервабилити:** Prometheus, Grafana, Alertmanager, Loki, Fluent Bit, 8
  exporters. Схемы/alarms — `docs/operations/monitoring-guide.md`.
- **Security & Networking:** Cloudflare Zero Trust, Nginx WAF, TLS 1.2/1.3,
  Docker Secrets, JWT-auth service. Инструкции —
  `scripts/infrastructure/security` и `docs/security/`.

## 📚 Документация

| Тема                   | Где искать                                                                         |
| ---------------------- | ---------------------------------------------------------------------------------- |
| Архитектура и обзор    | `docs/architecture/`, `docs/overview.md`                                           |
| Мониторинг/операции    | `docs/operations/monitoring-guide.md`, `docs/operations/monitoring-audit.md`       |
| GitHub/CI Governance   | `docs/operations/github-governance.md`, `.github/`                                 |
| Environments & секреты | `docs/reference/github-environments-setup.md` + `scripts/infrastructure/security/` |
| Инциденты/аудиты       | `docs/archive/incidents/`, `docs/archive/audits/`                                  |

## 🤝 Участие

1. Создайте issue (шаблоны в `.github/ISSUE_TEMPLATE/`).
2. Фичи — из `develop`, фиксы в PR -> `develop` -> `main`.
3. Убедитесь, что CI зелёный и документы обновлены.

License: MIT.
