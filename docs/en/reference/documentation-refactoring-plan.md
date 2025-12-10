---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Professional Documentation & Refactoring Plan (ноябрь 2025)

> **Цель:**унифицировать производственную документацию ERNI-KI, устранить дубли,
> закрыть устаревшие разделы и обеспечить понятную структуру для DevOps, ML и
> SRE команд. [TOC]

## 1. Текущее состояние (аудит 82 Markdown-файлов)

| Область              | Покрытие                                                                                                       | Актуальность |
| -------------------- | -------------------------------------------------------------------------------------------------------------- | ------------ |
| **Сводки**           | `README.md`, `docs/index.md`, `docs/overview.md` описывают одно и то же состояние (30/30 контейнеров и т. д.). | 07–11.2025   |
| **Архитектура**      | `docs/architecture/*.md`, `service-inventory.md`, `services-overview.md`, `nginx-configuration.md`.            | 07.11.2025   |
| **Операции**         | `docs/operations/*` + runbook директория (`backup`, `docling`, `service restart`, `troubleshooting`).          | 10–11.2025   |
| **Наблюдаемость**    | `monitoring-guide.md`, `prometheus-alerts-guide.md`, `grafana-dashboards-guide.md`, `log-audit-2025-11-14.md`. | 14.11.2025   |
| **Data & Storage**   | `docs/operations/database/*.md` (мониторинг/оптимизации Postgres, Redis, vLLM).                                | 09–10.2025   |
| **Security**         | `docs/security/security-policy.md`, `log-audit.md`, точечные отчёты.                                           | 09–11.2025   |
| **Reference/API**    | `docs/reference/api-reference.md` (обновлена 2025-09-19), `mcpo-integration-guide.md`, `development.md`.       | 09–10.2025   |
| **Архив / отчёты**   | 15+ отчётов в `docs/archive/reports/` (аудиты, диагностика, remediation).                                      | 10–11.2025   |
| **Локализации (DE)** | 11 файлов в `docs/locales/de` (перевод основных гайдов, без runbooks).                                         | 09.2025      |

**Наблюдения:**

- Метрики и статусы дублируются минимум в 4 файлах (`README.md`,
  `docs/index.md`, `docs/overview.md`, `docs/architecture/architecture.md`),
  обновляются вручную и расходятся по датам.
- Runbook-и и отчёты (например, `docs/log-audit-2025-11-14.md`) не имеют единой
  кармы в MkDocs, что затрудняет поиск инцидентов.
- Data & Storage раздел не упомянут в README/index → инженеры часто не знают о
  `database-monitoring-plan.md` и `redis-operations-guide.md`.
- API справочник (`docs/reference/api-reference.md`) и MCPO гайд не отражают
  ноябрьские обновления (LiteLLM 1.80.0.rc.1, новые эндпоинты Context7).
- Ряд cron/alert документов живёт только в `docs/archive/config-backup`, хотя их
  стоит вынести в operations.

## 2. Целевая структура профессиональной документации

| Уровень                     | Документ / раздел                                               | Содержание                                                                              |
| --------------------------- | --------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **Executive**               | `docs/overview.md` (single source of truth)                     | SLA, 30/30 здоровье, последние апдейты, ссылка на отчёты.                               |
| **Architecture**            | `architecture/architecture.md`, `service-inventory.md`          | L3 диаграммы, зависимости, профили Compose, конфигурации ingress/security.              |
| **Operations**              | `operations/core/operations-handbook.md`, `monitoring-guide.md` | Роли, on-call, алерты, процедуры реагирования.                                          |
| **Runbooks**                | `operations/*`                                                  | Шаблон: _Purpose → Preconditions → Steps → Validation_, связь со скриптами `scripts/*`. |
| **Data & Storage**          | `operations/database/*.md`                                      | Постгрес/Redis планы, pgvector, retention, логика watchdog.                             |
| **Security**                | `security/security-policy.md`, `log-audit.md`                   | Политики, аудит логов, WAF и Zero Trust.                                                |
| **API & Integrations**      | `reference/api-reference.md`, `mcpo-integration-guide.md`       | JWT, LiteLLM, MCP, Context7, RAG endpoints, примерные payloads.                         |
| **Reports & Audits**        | `archive/reports/*.md`                                          | Исторические документы (Phase reports, audits, diagnostics) + конспекты в operations.   |
| **Locales / Consumer Docs** | `locales/de/*`, пользовательские инструкции                     | Переведённые руководства (install, user guide, admin).                                  |

## 3. Гэп-анализ и приоритеты

1.**Статусные сводки:**выровнять даты и формулировки между `README.md`,
`docs/index.md` и `docs/overview.md`, заведя единый YAML блок (вставка через
`include-markdown`). 2.**API & интеграции:**обновить
`docs/reference/api-reference.md` и `mcpo-integration-guide.md` на ноябрь 2025
(новые модели, Context7, RAG workflow). Сейчас последняя дата —
2025-09-19. 3.**Operations ↔ Archive:**выделить важные отчёты (например,
`log-audit-2025-11-14.md`, `full-server-diagnostics-2025-11-04.md`) в «Living»
раздел operations, оставив архиву только историю. 4.**Runbooks vs
scripts:**синхронизировать шаги runbook’ов с скриптами из `scripts/maintenance`
(часть инструкций описывает уже автоматизированные процессы). 5.**Localization
debt:**немецкие документы не включают monitoring/playbooks и не обновлены под
v0.61.3. 6.**Data & Storage discoverability:**добавить перекрёстные ссылки в
README и operations handbook, чтобы инженеры знают о
`operations/database/*.md`. 7.**MkDocs навигация:**привести порядок `nav` к
целевой структуре (сейчас Data & Storage идёт после Operations, но операции с
базами не ссылаются на runbook’и).

## 4. План рефакторинга (3 волны)

### Волна 1 — Инвентаризация и выравнивание статусов (2–3 дня)

- Создать `docs/reference/status.yml` и подключить его в README/index/overview
  через `include-markdown` (исключить ручные правки).
- Выпустить короткий отчёт о фактическом состоянии документации в Archon (данный
  файл).
- Добавить в MkDocs «Documentation Health» страницу (данный файл).

### Волна 2 — Операционные документы и API (3–4 дня)

- Обновить `operations/core/operations-handbook.md`, `monitoring-guide.md` и
  `automated-maintenance-guide.md`, добавив ссылки на новые cron/alert скрипты
  (`scripts/monitoring/*`).
- Перенести ключевые finding’и из `docs/log-audit-2025-11-14.md` в
  operations-runbook («Alertmanager queue remediation»).
- Переписать `reference/api-reference.md` (LiteLLM 1.80.0.rc.1, Context7,
  `/lite/api/v1/think`, новые RAG endpoints, JWT примеры).

### Волна 3 — Архив, локализация и data docs (4–5 дней)

- Создать конспект по архивным отчётам (по одному абзацу и ссылке) и добавить в
  operations handbook.
- Упростить `docs/archive/` (разложить по папкам `incidents`, `audits`,
  `diagnostics`), обновить `mkdocs.yml`.
- Освежить `locales/de/*` + добавить missing разделы (monitoring/playbooks).
- Добавить ссылки на `operations/database/*.md` в README и operations handbook +
  проверить актуальность pgvector/Redis настроек.

## 5. Предлагаемые deliverables

- `docs/reference/status.yml` + `scripts/docs/update_status_snippet.py` (единый
  workflow для README/index/overview + locales/de).
- `docs/archive/` реструктурирован на `audits/`, `diagnostics/`, `incidents/` с
  README-навигаторами и обновлённым `mkdocs.yml`.
- `docs/locales/de/` — добавлены status-блок, Monitoring/Runbooks обзоры.
- README/index/operations-handbook теперь содержат ссылки на
  `operations/database/*.md` и архивные отчёты.
- Обновлённые operations guides и runbooks с привязкой к `scripts/*`.
- Новый раздел «Documentation Health & Refactoring Plan» (этот документ) и
  Archon запись.
- План внедрения локализации и data docs в CI (например, проверка дат обновлений
  через pre-commit).

## 6. Wave 3 (архивы/locales/data)

- `docs/archive/` реструктурирован на `audits/`, `diagnostics/`, `incidents/`
- README-навигаторы; `mkdocs.yml` обновлён.
- Operations Handbook/Monitoring Guide теперь указывают на архив и
  `docs/archive/config-backup/*.md` (cron/monitorинг).
- `docs/locales/de/index.md` использует статус-блок из `status.yml`, добавлены
  Monitoring/Runbooks обзоры (`locales/de/monitoring.md`,
  `locales/de/runbooks.md`).
- README, `docs/index.md` и Operations Handbook содержат явные ссылки на
  `operations/database/*.md`.
- Продолжается расширение локализаций (de) и перевод runbook’ов; при каждом
  добавлении используйте общий статус-блок и README-навигаторы.

## 7. Следующие шаги

1. Подключить новые pre-commit проверки (`status-snippet-check`,
   `archive-readme-check`) к CI (pre-commit.ci/GitHub Actions), чтобы
   гарантировать выполнение вне локальной машины.
2. Продолжить расширять локализацию (de) — перевести ключевые runbook’и
   полностью и добавить больше health-check сценариев.
3. Добавить релизный чек-лист, подтверждающий актуальность
   `docs/reference/status.yml`, `docs/archive/*/README.md` и
   `docs/operations/database/*.md` перед каждой поставкой.
4. Поддерживать Archon документ (эта страница) при каждом релизе, фиксируя
   прогресс по задачам Wave 3+ и локализационным обновлениям.

## 8. Wave 4 — Visual content & automation

- Добавлены визуализации (Mermaid) в 20 ключевых документов (overview,
  operations, monitoring, reference) — см. `docs/visuals_targets.json`.
- Включена проверка `visuals_and_links_check` в pre-commit/CI для контроля
  диаграмм, базового TOC и валидности относительных ссылок.
- Добавить реальные UI скриншоты в `docs/images/` (guides: install, academy) и
  подключить оптимизацию изображений в CI.
