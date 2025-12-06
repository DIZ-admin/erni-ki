---
title: Documentation Revision Plan (December 2025)
language: ru
page_id: documentation-revision-plan-2025-12
doc_version: '2025.11'
translation_status: original
---

# План ревизии документации (декабрь 2025)

**Создано**: 2025-12-06 **Статус**: Планирование **Приоритет**: HIGH
**Ответственный**: Documentation Team **Базовый аудит**:
[documentation-audit.md](../archive/audits/documentation-audit.md) (ноябрь 2025)

## Executive Summary

Комплексный аудит и ревизия документации ERNI-KI для обеспечения актуальности,
консистентности и полноты технической и пользовательской документации.

### Текущее состояние

- **Объём**: 411 файлов Markdown, ~101,349 строк
- **Языки**: Русский (основной), Немецкий, Английский
- **Генератор**: MkDocs Material
- **Последний аудит**: Ноябрь 2025

### Критические проблемы

1. Неполное покрытие ролей (support, management, developers)
2. Отсутствие единого стандарта frontmatter
3. Устаревшие ссылки и примеры кода
4. Несинхронизированные переводы (EN/DE)
5. Отсутствие процесса регулярного аудита

## Методология ревизии

### Фазы проверки

#### Фаза 1: Автоматизированный аудит (3h)

**Инструменты**:

- `lychee` - проверка битых ссылок
- `markdownlint` - валидация Markdown
- Custom scripts - валидация frontmatter
- `yamllint` - проверка YAML frontmatter

**Проверки**:

```bash
# 1. Битые внутренние ссылки
lychee "docs/**/*.md" \
 --exclude-path "docs/archive" \
 --format detailed \
 --output broken-links-report.md

# 2. Frontmatter валидация
python scripts/docs/validate_metadata.py \
 --output frontmatter-audit.json

# 3. Markdown линтинг
markdownlint "docs/**/*.md" \
 --config .markdownlint.json \
 --output markdownlint-report.txt

# 4. Проверка актуальности дат
find docs -name "*.md" -mtime +90 \
 -not -path "docs/archive/*" > stale-docs.txt
```

#### Фаза 2: Ручной аудит структуры (5h)

**Чек-лист по разделам**:

- [ ] **Getting Started** (8 файлов)
 - Актуальность версий сервисов
 - Корректность портов и URL
 - Наличие скриншотов

- [ ] **Architecture** (9 файлов + diagrams)
 - Соответствие текущей архитектуре
 - Актуальность диаграм Mermaid
 - Версии сервисов в service-inventory.md

- [ ] **Operations** (60+ файлов)
 - Runbook актуальность
 - Monitoring запросы Prometheus
 - Backup процедуры

- [ ] **Academy** (13 файлов, 3 языка)
 - Синхронизация переводов
 - Актуальность HowTo
 - UI примеры и скриншоты

- [ ] **Security** (6 файлов)
 - Политики безопасности
 - SSL/TLS конфигурации
 - Audit логи

- [ ] **Development** (новый раздел)
 - Contract testing plan
 - GitHub secrets setup
 - Testing guides

- [ ] **Reference** (15+ файлов)
 - API документация
 - Webhook спецификации
 - Code standards

#### Фаза 3: Контент-аудит (8h)

**Критерии оценки**:

| Критерий | Вес | Метрика |
| --------------- | --- | -------------------------------------- |
| Актуальность | 30% | Дата последнего обновления < 90 дней |
| Полнота | 25% | Все обязательные секции присутствуют |
| Точность | 20% | Команды/скрипты выполняются без ошибок |
| Консистентность | 15% | Frontmatter соответствует стандарту |
| Читаемость | 10% | Markdown линтинг пройден |

**Процесс проверки**:

1. **Технические документы** (operations, architecture, development)
 - Выполнить все команды и скрипты
 - Проверить корректность путей и URL
 - Верифицировать конфигурации

2. **Пользовательские гайды** (academy, getting-started)
 - Пройти все HowTo пошагово
 - Обновить скриншоты если UI изменился
 - Проверить актуальность примеров

3. **API документация** (api, reference)
 - Проверить соответствие реальным эндпоинтам
 - Валидировать примеры запросов/ответов
 - Обновить версии API

#### Фаза 4: Мультиязычная синхронизация (4h)

**Статус переводов**:

```bash
# Генерация отчёта о статусе переводов
find docs/de docs/en -name "*.md" | while read file; do
 ru_file="docs/$(echo $file | sed 's|docs/de/||;s|docs/en/||')"
 if [ -f "$ru_file" ]; then
 ru_date=$(git log -1 --format="%ai" "$ru_file")
 trans_date=$(git log -1 --format="%ai" "$file")
 echo "$file: RU=$ru_date, TRANS=$trans_date"
 fi
done > translation-sync-report.txt
```

**Приоритеты синхронизации**:

1. **P0 (Critical)**: getting-started, academy/index, operations/core
2. **P1 (High)**: security, architecture, operations/monitoring
3. **P2 (Medium)**: reference, examples, development

## Стандарты документации

### Обязательный Frontmatter

```yaml
---
title: Human-readable document title
language: ru|de|en
page_id: unique-kebab-case-id
doc_version: 'YYYY.MM' # Синхронизировано с docs/VERSION.md
translation_status: original|translated|outdated|in_progress
last_updated: YYYY-MM-DD # Опционально
author: Team/Person Name # Опционально
tags: # Опционально
 - category1
 - category2
---
```

### Шаблон HowTo документа

````markdown
---
title: How to [Action]
language: ru
page_id: howto-action-name
doc_version: '2025.11'
translation_status: original
---

# How to [Action]

**Целевая аудитория**: [Developers/Operators/Users] **Время выполнения**: [XX
минут] **Сложность**: [Beginner/Intermediate/Advanced] **Последнее обновление**:
YYYY-MM-DD

## Цель

[Описание задачи в 1-2 предложениях]

## Предварительные требования

- [ ] Requirement 1
- [ ] Requirement 2

## Шаги

### Шаг 1: [Название]

[Подробное описание]

\`\`\`bash

# Команда с комментариями

command --flag value \`\`\`

**Ожидаемый результат**: \`\`\` [Пример вывода] \`\`\`

### Шаг 2: [Название]

[...]

## Проверка результата

```bash
# Как проверить что всё работает
verification-command
```
````

## Rollback

Если что-то пошло не так:

```bash
# Команды отката
rollback-command
```

## Дополнительные ресурсы

- [Link to related docs]
- [External reference]

## Troubleshooting

| Проблема | Решение |
| -------- | ---------- |
| Error X | Solution Y |

````

### Шаблон Runbook документа

```markdown
---
title: [Service] Runbook
language: ru
page_id: runbook-service-name
doc_version: '2025.11'
translation_status: original
---

# [Service] Runbook

**Service**: service-name
**Owner**: Team Name
**Severity**: P0/P1/P2/P3
**On-call**: [Rotation schedule link]

## Быстрые ссылки

- Grafana Dashboard: [URL]
- Logs: [URL]
- Alerts: [URL]
- Service Repo: [URL]

## Обзор сервиса

[Краткое описание сервиса и его роли]

## Типичные инциденты

### [Incident Type 1]

**Симптомы**:
- Symptom 1
- Symptom 2

**Диагностика**:
```bash
# Команды для проверки
check-command
````

**Решение**:

```bash
# Шаги по исправлению
fix-command
```

**Escalation**: [Когда эскалировать и к кому]

## Обычное обслуживание

### [Maintenance Task]

**Частота**: Daily/Weekly/Monthly **Время**: [Best time to run]

```bash
# Команды обслуживания
maintenance-command
```

## Contacts

| Role | Contact | Timezone |
| --------- | ------- | -------- |
| Primary | Name | UTC+X |
| Secondary | Name | UTC+X |

````

## План работ (Timeline)

### Неделя 1: Подготовка и автоматизация (12h)

#### День 1-2: Настройка инструментов (6h)

**Задачи**:

1. **Установить инструменты аудита**:
```bash
# Link checker
npm install -g lychee

# Markdown linter
npm install -g markdownlint-cli

# YAML linter
pip install yamllint
````

2. **Создать скрипты валидации**:
 - `scripts/docs/validate-frontmatter.py` - проверка frontmatter
 - `scripts/docs/check-stale-docs.sh` - поиск устаревших файлов
 - `scripts/docs/translation-sync-check.sh` - статус переводов

3. **Настроить CI проверки**:

```yaml
# .github/workflows/docs-quality.yml
name: Documentation Quality

on:
 pull_request:
 paths:
 - 'docs/**'
 schedule:
 - cron: '0 3 * * 1' # Weekly on Monday

jobs:
 validate:
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v4

 - name: Check links
 uses: lycheeverse/lychee-action@v2
 with:
 args: --verbose 'docs/**/*.md'

 - name: Lint Markdown
 run: markdownlint 'docs/**/*.md'

 - name: Validate frontmatter
 run: python scripts/docs/validate-frontmatter.py
```

#### День 3-4: Автоматизированный аудит (6h)

**Задачи**:

1. **Запустить все проверки**:

```bash
# Создать директорию для отчётов
mkdir -p docs/reports/audit-2025-12

# Битые ссылки
lychee "docs/**/*.md" \
 --exclude-path "docs/archive" \
 --format detailed \
 > docs/reports/audit-2025-12/broken-links.md

# Markdown линтинг
markdownlint "docs/**/*.md" \
 --config .markdownlint.json \
 > docs/reports/audit-2025-12/markdown-lint.txt

# Frontmatter
python scripts/docs/validate-frontmatter.py \
 --output docs/reports/audit-2025-12/frontmatter.json

# Устаревшие документы
bash scripts/docs/check-stale-docs.sh \
 > docs/reports/audit-2025-12/stale-docs.txt

# Статус переводов
bash scripts/docs/translation-sync-check.sh \
 > docs/reports/audit-2025-12/translations.txt
```

2. **Анализ результатов**:
 - Categorize issues by severity (P0/P1/P2)
 - Create prioritized task list in Archon
 - Estimate effort for fixes

### Неделя 2-3: Контент-аудит и исправления (32h)

#### Приоритет P0: Критические проблемы (8h)

**Фокус**: Getting Started, Security, Operations/Core

1. **Getting Started** (3h):
 - [ ] Обновить версии сервисов в installation.md
 - [ ] Проверить все команды установки
 - [ ] Обновить конфигурационные примеры
 - [ ] Добавить скриншоты текущего UI

2. **Security** (3h):
 - [ ] Проверить актуальность security-policy.md
 - [ ] Обновить SSL/TLS конфигурации
 - [ ] Валидировать audit процедуры
 - [ ] Синхронизировать с GitHub secrets guide

3. **Operations/Core** (2h):
 - [ ] Обновить operations-handbook.md
 - [ ] Проверить runbooks на актуальность
 - [ ] Валидировать backup процедуры

#### Приоритет P1: Важные обновления (12h)

**Фокус**: Architecture, Academy, Operations/Monitoring

1. **Architecture** (4h):
 - [ ] Обновить architecture-overview.md
 - [ ] Перерисовать диаграммы Mermaid
 - [ ] Синхронизировать service-inventory.md с docker-compose
 - [ ] Обновить версии сервисов

2. **Academy** (4h):
 - [ ] Обновить openwebui-basics.md
 - [ ] Проверить все HowTo
 - [ ] Обновить скриншоты
 - [ ] Синхронизировать переводы (EN/DE)

3. **Operations/Monitoring** (4h):
 - [ ] Проверить Prometheus запросы
 - [ ] Обновить Grafana dashboard гайды
 - [ ] Валидировать alerting правила
 - [ ] Обновить troubleshooting guides

#### Приоритет P2: Улучшения (12h)

**Фокус**: Reference, Development, Examples

1. **Development (NEW)** (4h):
 - [ ] Проверить contract-testing-plan.md
 - [ ] Исправить битую ссылку на Pact.io
 - [ ] Добавить testing-guide.md
 - [ ] Создать setup-guide.md

2. **Reference** (4h):
 - [ ] Обновить API документацию
 - [ ] Проверить webhook спецификации
 - [ ] Синхронизировать code-standards.md
 - [ ] Обновить metadata-standards.md

3. **Examples** (4h):
 - [ ] Проверить API примеры
 - [ ] Обновить Nginx конфигурации
 - [ ] Добавить новые use cases

### Неделя 4: Мультиязычная синхронизация (16h)

#### Немецкий перевод (8h)

**Приоритетные файлы**:

```bash
# P0 файлы для синхронизации
docs/de/getting-started/index.md
docs/de/getting-started/installation.md
docs/de/academy/index.md
docs/de/operations/core/operations-handbook.md
docs/de/security/security-policy.md
```

**Процесс**:

1. Сравнить с русской версией
2. Обновить устаревший контент
3. Добавить недостающие секции
4. Обновить `translation_status` frontmatter

#### Английский перевод (8h)

**Приоритетные файлы**:

```bash
# P0 файлы для синхронизации
docs/en/getting-started/index.md
docs/en/getting-started/installation.md
docs/en/academy/index.md
docs/en/operations/core/operations-handbook.md
docs/en/security/security-policy.md
```

### Неделя 5: Финализация и процессы (8h)

#### Документация процессов (4h)

1. **Создать documentation-maintenance-guide.md**:

```markdown
# Documentation Maintenance Guide

## Регулярный аудит

**Частота**: Ежемесячно + после каждого релиза

**Процесс**:

1. Запустить автоматизированные проверки
2. Проверить P0 документы вручную
3. Обновить VERSION.md
4. Синхронизировать переводы
5. Создать отчёт аудита

## Обновление при релизе

**Триггеры**:

- Новая версия OpenWebUI/Ollama/LiteLLM
- Изменения в UI/API
- Новые фичи
- Изменения безопасности

**Шаги**:

1. Обновить getting-started guides
2. Обновить скриншоты
3. Проверить API примеры
4. Синхронизировать версии
5. Increment doc_version
```

2. **Обновить README.md**:
 - Добавить секцию Documentation Owners
 - Линк на maintenance guide
 - Процесс эскалации

3. **Создать реестр владельцев**:

```markdown
# docs/operations/documentation-owners.md

| Раздел | Владелец | Резервный | SLA обновления |
| --------------- | ------------- | ------------- | ---------------- |
| Getting Started | DevOps Team | Platform Team | При релизе |
| Architecture | Platform Team | DevOps Team | Ежемесячно |
| Operations | DevOps Team | SRE Team | Еженедельно |
| Academy | Product Team | Support Team | При изменении UI |
| Security | Security Team | DevOps Team | При инцидентах |
| Development | Dev Team | QA Team | При изменении CI |
```

#### Настройка мониторинга (4h)

1. **GitHub Actions для еженедельного аудита**:

```yaml
# .github/workflows/weekly-docs-audit.yml
name: Weekly Documentation Audit

on:
 schedule:
 - cron: '0 9 * * 1' # Every Monday at 9 AM UTC
 workflow_dispatch:

jobs:
 audit:
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v4

 - name: Run audit checks
 run: |
 bash scripts/docs/run-weekly-audit.sh

 - name: Create issue if problems found
 if: failure()
 uses: actions/github-script@v7
 with:
 script: |
 github.rest.issues.create({
 owner: context.repo.owner,
 repo: context.repo.repo,
 title: ' Weekly Documentation Audit Failed',
 body: 'Automated documentation audit found issues. Check workflow logs.',
 labels: ['documentation', 'maintenance']
 })
```

2. **Metrics дашборд**:
 - Количество устаревших документов
 - Процент битых ссылок
 - Статус синхронизации переводов
 - Coverage по разделам

## Метрики успеха

### Количественные

| Метрика | Текущее | Целевое | Срок |
| ------------------------------- | ------- | ------- | -------- |
| Битые ссылки | TBD | 0 | Неделя 3 |
| Устаревшие документы (>90 дней) | TBD | <5% | Неделя 4 |
| Frontmatter покрытие | ~60% | 95% | Неделя 3 |
| DE синхронизация | ~40% | 80% | Неделя 4 |
| EN синхронизация | ~30% | 70% | Неделя 4 |
| Markdown lint issues | TBD | 0 | Неделя 2 |

### Качественные

- [ ] Все P0 документы актуализированы
- [ ] Создан процесс регулярного аудита
- [ ] Назначены владельцы разделов
- [ ] Настроен CI для проверки документации
- [ ] Созданы шаблоны для HowTo/Runbooks
- [ ] Документирован процесс обновления при релизе

## Риски и митигация

| Риск | Вероятность | Влияние | Митигация |
| --------------------------- | ----------- | ------- | -------------------------------- |
| Недостаток ресурсов | HIGH | HIGH | Привлечь команду, автоматизация |
| Устаревание во время аудита | MEDIUM | MEDIUM | Фокус на P0, fast iteration |
| Сопротивление процессам | MEDIUM | LOW | Clear documentation, automation |
| Технические изменения | MEDIUM | MEDIUM | Continuous monitoring, CI checks |

## Следующие шаги (Immediate)

1. Создать план ревизии (этот документ)
2. ⏳ Создать Archon project для документации
3. ⏳ Создать задачи в Archon по неделям
4. ⏳ Установить инструменты аудита
5. ⏳ Запустить первый автоматизированный аудит
6. ⏳ Анализ результатов и приоритизация
7. ⏳ Начать исправления P0

## Связанные документы

- [Documentation Audit (Nov 2025)](../archive/audits/documentation-audit.md)
- [Metadata Standards](../reference/metadata-standards.md)
- [Style Guide](../reference/style-guide.md)
- [Language Policy](../reference/language-policy.md)
- [VERSION](../VERSION.md)

## Примечания

### Инструменты

- **lychee**: Link checker - https://github.com/lycheeverse/lychee
- **markdownlint**: Markdown linter - https://github.com/DavidAnson/markdownlint
- **yamllint**: YAML linter - https://github.com/adrienverge/yamllint
- **MkDocs Material**: Documentation generator -
 https://squidfunk.github.io/mkdocs-material/

### Команда

- **Documentation Owner**: TBD
- **DevOps Lead**: TBD
- **Platform Lead**: TBD
- **Translation Team**: TBD

---

**Автор**: Claude Sonnet 4.5 **Создано**: 2025-12-06 **Последнее обновление**:
2025-12-06 **Статус**: DRAFT - Требуется утверждение
