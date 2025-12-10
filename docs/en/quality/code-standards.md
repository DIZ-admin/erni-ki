---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-09'
---

# Code Quality Standards

A unified set of rules for internal scripts, services, and infrastructure
artifacts. Compliance with these standards is a mandatory entry point for code
review and CI.

## 1. Goals and Scope

- Ensure stability of the ERNI-KI platform and reproducibility of builds.
- Reduce risks through unified rules for security, testing, and style.
- Accelerate onboarding: all projects (Go, Python, JS/TS, Bash, Infra-as-Code)
  follow one checklist.
- Ensure traceability: any exceptions are documented, agreed upon, and have an
  expiration date.
- Maintain documentation quality at ≥ 95/100 on internal maturity scale
  (completeness, relevance, actionability).

### Roles and Responsibilities

- **Author** — ensures the presence of tests, documentation, and up-to-date
  checklists for their changes.
- **Reviewer** — verifies compliance with standards, validates risks, and
  clearly documents remarks.
- **Product/Component Owner** — approves exceptions to rules and their closure
  deadlines.

### Severity Levels and Exceptions

- Blocking: security, secret leaks, missing tests for public API, linter
  failures — cannot merge without fix.
- Warnings: cosmetic style inconsistencies with explicit reviewer agreement, if
  they don't harm readability or carry risk.
- Exceptions are documented via PR comment with justification, deadline, and
  responsible person; recorded in CHANGELOG or documentation.
- Each exception includes a remediation plan and expiration date label;
  reviewers track their closure in subsequent releases.

### Documentation Management

- Component owner appoints a **documentation curator**, who is responsible for
  keeping instructions fresh and controlling text quality.
- Before release, conduct a mini-audit: update launch examples, CI commands,
  environment variables, and ADR references.
- For user-facing changes, publish a brief summary (tl;dr), list of user
  impacts, and verified scenarios (smoke-check).

## 2. Mandatory Principles (for all languages)

- **Style and Formatting:** run formatters before commit (`gofmt`,
  `ruff format`, `eslint --fix`, `shfmt`). Don't disable lint rules without
  reason and without comment.
- **Typing and Contracts:** enable strict modes (`pyproject.toml` with
  `mypy`/`ruff`, `tsconfig.json` with `strict: true`, `go vet`).
- **Testability:** accompany each new module with unit tests; changes are not
  accepted without tests. Minimum — happy path + negative cases.
- **Errors and Logging:** use structured logs, return informative errors with
  context; don't suppress exceptions/errors.
- **Dependencies:** pin versions (`go.mod`, `requirements*.txt`,
  `package-lock.json`), avoid direct `latest`. Remove unused packages.
- **Security:** secrets in code/logs are forbidden. Enable security linters
  (Trivy, `npm audit`, `pip-audit`, `gosec`) and fix blocking findings.
- **Documentation:** accompany public functions/scripts with docstring/`//`
  comments. Update README/mkdocs when behavior changes.
- **Traceability:** link changes to tasks/tickets, provide references in PR
  description. In CHANGELOG reflect significant user-facing changes and
  migrations.

## 3. Языковые профили

### Go

- Форматирование: `gofmt` + `goimports` обязательны.
- Проверки: `go vet`, `staticcheck` (если доступен в проекте),
  `go test ./... -race` для сервисов, использующих конкурентность.
- Ошибки: заворачивайте ошибки через `fmt.Errorf("context: %w", err)`; не
  теряйте оригинальный `err`.
- Конфигурация: храните в `.env`/`config` с валидацией; не используйте
  глобальные переменные для состояния.
- Тесты: покрывайте конкурентные участки `-race` и таблицами тестов; избегайте
  глобального состояния между кейсами.

### Python

- Линтеры: `ruff check` + `ruff format`, опционально `mypy` для критичных путей.
- Импорты: сортировка `ruff --select I`; не используйте `from module import *`.
- Исключения: ловите только ожидаемые типы, не скрывайте стеки; логируйте через
  структурированные логгеры.
- Пакеты: объявляйте версии в `requirements*.txt`; для CLI-утилит используйте
  `argparse/typer` с подробным `--help`.
- Тесты: используйте `pytest` с `pytest-cov`, фикстуры для подготовки окружения,
  маркируйте интеграционные тесты и отделяйте их в CI.

### JavaScript/TypeScript

- Типобезопасность: `strict` режим в `tsconfig.json`; избегайте `any` и `!` без
  пояснения.
- Линтеры/форматтеры: `eslint`, `prettier` (если подключён), `npm run lint` в
  CI.
- Тесты: `vitest`/`jest` минимум для публичных функций и UI-компонентов;
  снапшоты храните под контролем версий.
- UI: не смешивайте логику и представление; отделяйте хуки/сервисы от
  компонентов.
- Доступность (a11y): проверяйте контраст, фокусируемость, ARIA-атрибуты для
  интерактивных элементов; добавляйте истории в Storybook при наличии.

### Bash и CLI-скрипты

- Шебанг `#!/usr/bin/env bash` и `set -euo pipefail` обязательны.
- Проверяйте входные параметры, выводите понятные сообщения об ошибках.
- Не используйте `sudo` внутри скриптов; требуйте права заранее.
- Совместимость: пишите POSIX-совместимые конструкции, если не требуется
  специфичный Bash 5.x.

## 4. Git и pull requests

- Коммиты атомарные, с описательными сообщениями в повелительном наклонении.
- Перед PR обязательно: `npm run lint`, `npm run test`, `go test ./...` (для
  Go), `ruff check`, `pre-commit run --all-files` — согласно стеку изменения.
- Запрещено форс-пушить в `main`/`develop`. Все изменения проходят через PR и
  review.
- Изменения конфигурации/секретов сопровождайте миграционными инструкциями в
  `docs/` или в описании PR.
- Требование минимальных воспроизводимых окружений: для CLI/скриптов добавляйте
  пример запуска с набором переменных и зависимостей; для сервисов — команду для
  локального старта.
- Документация по изменениям — часть определения готовности (Definition of
  Done): без обновления Usage/ADR/README изменение не принимается.

## 5. Документация и комментирование

- Каждый публичный API/CLI имеет раздел "Usage" и примеры. Изменения интерфейсов
  отражайте в `docs/api/` или `docs/reference/`.
- Внутренние функции документируйте кратко: цель, входы/выходы, ключевые
  побочные эффекты.
- Не дублируйте знания: источник правды выбирается один (код или документ с
  автогенерацией). Обновляйте статусы и версии вместе с релизами.
- Для архитектурных решений фиксируйте ADR с контекстом, альтернативами и
  критериями выбора. Обновляйте диаграммы при изменении потоков данных.
- Поддерживайте единый стиль написания документации: актуальная дата, версионный
  тег, короткое резюме изменений и ссылки на связанные задачи.
- Готовность документации измеряйте по шкале 0–100: полнота (40%), актуальность
  (35%), применимость/пошаговость (25%). Минимум для мёрджа — 95.
- Для CLI и API добавляйте блоки: входные параметры, коды ответов/ошибок,
  примеры вызова, ограничения и частые ловушки (gotchas).
- Для инфраструктуры и CI/CD фиксируйте источники секретов, схемы хранения
  артефактов и политику ротации ключей.

## 6. Контроль качества и CI/CD

- В CI запрещено игнорировать падение линтеров/тестов; `allow_failures` только
  для экспериментальных матриц с явной пометкой.
- Покрытие: для новых модулей не ниже 80%; снижение покрытие допустимо только с
  оформленным исключением и планом на рост.
- Подписи контейнеров/артефактов: включайте SBOM и результаты сканирования на
  уязвимости; не публикуйте артефакты с критичными находками.
- Каталоги артефактов сборки должны быть исключены из коммитов, если не являются
  частью релиза.
- Включайте шаг проверки документации в CI: сборка mkdocs, линт ссылок, проверку
  примеров команд (doctest/`make docs-verify`) и наличие обновлённых версий/дат.
- После релиза фиксируйте итоговую оценку качества документации и ключевые риски
  в `DOCUMENTATION_AUDIT_REPORT.md` или сопутствующем ADR.

## 7. Самооценка и контроль списка

- Раз в квартал проводите самоаудит по чек-листу: синхронизация версий, актуалы
  переменных окружения, наличие сценариев восстановления и проверенных примером
  команд запуска.
- Храните результаты аудита в репозитории (reports/ или docs/quality) с датой и
  ответственным.
- Для статей/гайдов используйте шаблон: цель → контекст → требования к среде →
  пошаговая инструкция → валидация результата → ошибки/траблшутинг → ссылки.
- Любой найденный долг фиксируется тикетом с датой закрытия и попадает в
  ближайший релизный план.

## 8. Чек-лист code review

- [ ] Линтеры/форматтеры пройдены, нет отключённых правил без обоснования.
- [ ] Покрытие тестами достаточное; негативные сценарии учтены.
- [ ] Ошибки и логи содержат контекст, нет глушения исключений.
- [ ] Зависимости и версии актуализированы; нет секретов в коде/конфигурации.
- [ ] Документация и миграционные заметки обновлены; примеры запуска проверены.
- [ ] Наличие ADR/диаграмм при значимых архитектурных изменениях.
- [ ] Обоснованы все исключения и зафиксированы сроки их закрытия.

Соблюдение этих стандартов обеспечивает предсказуемое качество, ускоряет ревью и
снижает эксплуатационные риски.
