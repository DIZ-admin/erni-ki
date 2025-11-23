---
language: ru
translation_status: archived
doc_version: '2025.11'
---

# ERNI-KI — портал документации (RU)

ERNI-KI — production-ready AI платформа на базе OpenWebUI, Ollama, LiteLLM и
MCP, окружённая полным стеком наблюдаемости, мониторинга и безопасности. Здесь
собраны актуальные гайды для DevOps/SRE и ML-инженеров, а также понятные
инструкции для офисных сотрудников о том, как безопасно работать с AI в
повседневных задачах.

**Academy KI** — отдельный вход для сотрудников с быстрым стартом, обучением и
готовыми сценариями. Начните с [портала Academy KI](../academy/index.md), чтобы
получить ссылки на базовые уроки, примеры промптов и актуальные новости.

## Обновления

<!-- STATUS_SNIPPET_START -->

> **Статус системы (2025-11-14) — Production Ready v12.1**
>
> - Контейнеры: 30/30 контейнеров healthy
> - Графана: 18/18 Grafana дашбордов
> - Алерты: 27 Prometheus alert rules активны
> - AI/GPU: Ollama 0.12.11 + OpenWebUI v0.6.36 (GPU), Go 1.24.10
> - Context & RAG: LiteLLM v1.80.0.rc.1 + Context7, Docling, Tika, EdgeTTS
> - Мониторинг: Prometheus v3.0.1, Grafana v11.6.6, Loki v3.5.5, Fluent Bit
>   v3.2.0, Alertmanager v0.28.0
> - Автоматизация: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Примечание: Наблюдаемость и AI стек актуализированы в ноябре 2025

<!-- STATUS_SNIPPET_END -->

## Быстрые переходы

- **Архитектура и сервисы** — `../architecture/architecture.md`,
  `../architecture/service-inventory.md`,
  `../architecture/services-overview.md`.
- **Операции** — `../operations/operations-handbook.md`,
  `../operations/monitoring/monitoring-guide.md`,
  `../operations/automation/automated-maintenance-guide.md`,
  `../operations/runbooks/`.
- **Хранилище и данные** — `../data/database-monitoring-plan.md`,
  `../data/redis-operations-guide.md`,
  `../data/database-production-optimizations.md`.
- **ML и API** — `reference/api-reference.md`, `README.md` (вне MkDocs, но
  всегда актуален в корне репозитория).
- **Безопасность** — `security/security-policy.md` и related compliance notes.
- **Academy KI** — входная точка для сотрудников: [портал](../academy/index.md),
  базовые уроки ([Open WebUI basics](../academy/openwebui-basics.md),
  [Prompting 101](../academy/prompting-101.md)), сценарии
  ([HowTo](../academy/howto/write-customer-email.md)) и
  [News](../news/index.md).
- **Проверить статус ERNI-KI** — смотрите
  [status page](../operations/status-page.md) (ссылку на конкретный URL укажите
  в конфигурации).

> Для быстрых решений используйте Archon (runbooks, checklists, status updates)
> и держите синхронизацию с этими материалами.
