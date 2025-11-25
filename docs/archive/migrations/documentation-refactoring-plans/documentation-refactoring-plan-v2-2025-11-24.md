---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# План рефакторинга документации v2 (2025-11-24)

> **Полные аудиты:**
>
> - [Первый аудит](../archive/audits/comprehensive-documentation-audit-2025-11-24.md)

- [Повторный аудит с фокусом на рефакторинг](../audits/documentation-refactoring-audit-2025-11-24.md)
  > [TOC]

## 🎯 Ключевые проблемы

### Критические

1. 🔴 **101 orphaned документ** (54%) - нет входящих ссылок
2. 🔴 **20 stub документов** (<50 слов) - нуждаются в действиях
3. 🔴 **EN покрытие 18.2%** - критически низкое

### Важные

4. 🟡 **39 guides** разбросаны - нужна консолидация
5. 🟡 **4 дубликата** main/archive - требуют проверки
6. 🟡 **4 документа** с deprecation markers - требуют обновления

### Положительное

✅ Все документы свежие (<90 дней) ✅ Хорошие стандарты метаданных ✅ Отсутствие
критически устаревшего контента

---

## 📋 Фазы рефакторинга

### 📅 Фаза 1: Критические исправления (3 дня)

**Статус:** 🔴 Ожидает начала

#### День 1: Stub документы (20 файлов)

**EN Academy (7 файлов) - Настроить redirects:**

```bash
# Удалить stubs, настроить redirects в mkdocs.yml
rm en/academy/openwebui-basics.md
rm en/academy/prompting-101.md
rm en/academy/howto/write-customer-email.md
rm en/academy/howto/create-jira-ticket-with-ai.md
rm en/academy/howto/summarize-meeting-notes.md
rm en/academy/news/2025-01-release-x.md
```

**DE Academy (6 файлов) - Настроить redirects:**

```bash
rm de/academy/howto/summarize-meeting-notes.md
rm de/academy/prompting-101.md
rm de/academy/howto/write-customer-email.md
rm de/academy/howto/create-jira-ticket-with-ai.md
rm de/academy/news/2025-01-release-x.md
```

**Operations (4 файла) - Расширить:**

- [ ] de/operations/backup-guide.md (8 слов → 200+)
- [ ] de/operations/troubleshooting.md (9 слов → 200+)
- [ ] de/operations/database/database-production-optimizations.md (17 слов →
      200+)
- [ ] operations/database/database-production-optimizations.md (17 слов → 200+)

**Остальные (3 файла) - Расширить:**

- [ ] en/academy/openwebui-basics.md - полный перевод (12 → 500+ слов)
- [ ] en/academy/prompting-101.md - полный перевод (16 → 500+ слов)
- [ ] de/academy/openwebui-basics.md - полный перевод (12 → 500+ слов)

## День 2: Дубликаты и устаревшее (4+4 файла)

**Проверить дубликаты:**

- [ ] operations/diagnostics/README.md vs archive/diagnostics/README.md
- [ ] de/academy/prompting-101.md vs archive/training/prompting-101.md
- [ ] de/academy/openwebui-basics.md vs archive/training/openwebui-basics.md
- [ ] academy/howto/summarize-meeting-notes.md vs
      archive/howto/summarize-meeting-notes.md

**Обновить deprecation markers:**

- [ ] architecture/architecture.md - обновить PostgreSQL версии
- [ ] reference/CHANGELOG.md - очистить устаревшие записи
- [ ] security/log-audit.md - обновить практики
- [ ] operations/core/configuration-change-process.md - завершить TODO

### День 3: Создать navigation README

**Создать недостающие README:**

- [ ] operations/automation/README.md
- [ ] operations/maintenance/README.md
- [ ] operations/monitoring/README.md
- [ ] operations/troubleshooting/README.md

**Обновить существующие:**

- [ ] operations/core/README.md - добавить ссылки на все документы
- [ ] operations/database/README.md - добавить ссылки на все документы
- [ ] operations/diagnostics/README.md - добавить ссылки на все документы

**Результат Фазы 1:**

- ✅ 0 stub документов
- ✅ 0 дубликатов
- ✅ 0 deprecation markers
- ✅ 7/7 подразделов operations/ с README

---

### 📅 Фаза 2: Навигация и связность (1 неделя)

**Статус:** ⏳ Запланировано

#### Задача 2.1: Обновить главные порталы (2 часа)

**docs/index.md:**

```markdown
## 📚 Разделы документации

### Для пользователей

- [Academy KI](academy/index.md) - обучение и практика
- [Начало работы](getting-started/README.md) - установка и настройка
- [HowTo](academy/howto/index.md) - практические руководства
- [Новости](news/index.md) - обновления платформы

### Для администраторов

- [Операции](operations/README.md) - администрирование
- [Мониторинг](operations/monitoring/README.md) - мониторинг системы
- [База данных](operations/database/README.md) - PostgreSQL и Redis
- [Безопасность](security/README.md) - политики безопасности

### Для разработчиков

- [Архитектура](architecture/README.md) - архитектура системы
- [API Reference](reference/api-reference.md) - API документация
- [Разработка](reference/development.md) - инструкции для разработчиков

### Справка

- [Глоссарий](GLOSSARY.md) - термины и определения
- [Статус системы](system/status.md) - текущий статус
```

**docs/de/index.md и docs/en/index.md:**

- [ ] Перевести обновленную структуру навигации
- [ ] Добавить все ссылки

#### Задача 2.2: Добавить "Связанные документы" (6 часов)

**Топ-30 документов для обновления:**

1. architecture/architecture.md
2. operations/monitoring/monitoring-guide.md
3. security/log-audit.md
4. operations/diagnostics/erni-ki-diagnostic-methodology.md
5. reference/api-reference.md
6. getting-started/installation.md
7. operations/maintenance/backup-restore-procedures.md
8. architecture/service-inventory.md
9. architecture/services-overview.md
10. operations/core/operations-handbook.md

... и еще 20

**Шаблон секции "Связанные документы":**

```markdown
## Связанные документы

### В этом разделе

- [Document 1](relative/path.md)
- [Document 2](relative/path.md)

### Смежные темы

- [Related Topic 1](../path/doc.md)
- [Related Topic 2](../path/doc.md)

### Предыдущий/Следующий

- ⬅️ [Предыдущий: Title](prev.md)
- ➡️ [Следующий: Title](next.md)
```

#### Задача 2.3: Обновить academy/howto/index.md (1 час)

```markdown
# HowTo Guides

Практические руководства для повседневных задач.

## Работа с документами

- [Создать JIRA ticket](create-jira-ticket.md) - ручное создание
- [Создать JIRA ticket с AI](create-jira-ticket-with-ai.md) - с помощью AI
- [Написать email клиенту](write-customer-email.md) - шаблоны и примеры

## Работа с встречами

- [Суммаризировать заметки встречи](summarize-meeting-notes.md) - быстрое резюме
```

**Метрика:** Снизить orphaned документы с 101 до <30

---

### 📅 Фаза 3: Консолидация (3 недели)

**Статус:** ⏳ Запланировано

#### Неделя 1: Monitoring (23 → 8-10 файлов)

**Новая структура:**

```
operations/monitoring/
├── README.md (обзор)
├── monitoring-guide.md (главный)
├── dashboards/
│   ├── grafana-setup.md (было: grafana-dashboards-guide.md)
│   └── dashboard-reference.md
├── alerts/
│   ├── prometheus-alerts.md (было: prometheus-alerts-guide.md)
│   ├── alertmanager-config.md (было: alertmanager-noise-reduction.md)
│   └── alert-examples.md
├── queries/
│   └── prometheus-queries.md (было: prometheus-queries-reference.md)
├── components/
│   ├── rag-monitoring.md
│   ├── redis-monitoring.md (из database/)
│   └── logs-sync.md (было: access-log-sync-and-fluentbit.md)
└── troubleshooting.md (было: searxng-redis-issue-analysis.md + другие)
```

**Шаги:**

1. Создать новую структуру директорий
2. Переместить файлы
3. Обновить ссылки во всех документах
4. Обновить mkdocs.yml navigation
5. Создать redirects для старых путей

#### Неделя 2: Database (19 → 8-10 файлов)

**Новая структура:**

```
operations/database/
├── README.md
├── postgresql/
│   ├── setup.md
│   ├── optimizations.md (было: database-production-optimizations.md)
│   ├── monitoring.md (было: database-monitoring-plan.md)
│   └── troubleshooting.md (было: database-troubleshooting.md)
├── redis/
│   ├── operations.md (было: redis-operations-guide.md)
│   ├── monitoring.md (переехало из monitoring/)
│   └── troubleshooting.md
└── vllm/
    └── resource-optimization.md (было: vllm-resource-optimization.md)
```

#### Неделя 3: Troubleshooting (9 → 5-6 файлов)

**Объединить diagnostics/ и troubleshooting/:**

```
operations/troubleshooting/
├── README.md (обзор)
├── methodology.md (было: erni-ki-diagnostic-methodology.md)
├── guides/
│   ├── database-issues.md
│   ├── monitoring-issues.md
│   ├── application-issues.md
│   └── network-issues.md
└── runbooks/
    └── common-scenarios.md
```

---

### 📅 Фаза 4: Критичные переводы EN (1 месяц)

**Статус:** ⏳ Запланировано

**Цель:** EN покрытие с 18.2% до 50% (+36 файлов)

#### Неделя 1: Getting Started (7 файлов, ~8 часов)

- [ ] getting-started/README.md
- [ ] getting-started/configuration-guide.md
- [ ] getting-started/dnsmasq-setup-instructions.md
- [ ] getting-started/external-access-setup.md
- [ ] getting-started/local-network-dns-setup.md
- [ ] getting-started/port-forwarding-setup.md
- [ ] getting-started/user-guide.md

#### Неделя 2: Academy (4 файла, ~6 часов)

- [ ] academy/howto/create-jira-ticket.md
- [ ] academy/openwebui-basics.md (полный перевод)
- [ ] academy/prompting-101.md (полный перевод)
- [ ] academy/howto/index.md

#### Неделя 3: Operations Core (6 файлов, ~8 часов)

- [ ] operations/README.md
- [ ] operations/core/operations-handbook.md
- [ ] operations/core/runbooks-summary.md
- [ ] operations/core/admin-guide.md
- [ ] operations/core/status-page.md
- [ ] operations/core/github-governance.md

#### Неделя 4: Security (5 файлов, ~6 часов)

- [ ] security/README.md
- [ ] security/authentication.md
- [ ] security/security-best-practices.md
- [ ] security/ssl-tls-setup.md
- [ ] security/log-audit.md

---

### 📅 Фаза 5: Расширенные переводы (1 месяц)

**Статус:** ⏳ Запланировано

#### Operations (15 файлов, ~20 часов)

**Monitoring (8 файлов):**

- [ ] operations/monitoring/README.md
- [ ] operations/monitoring/monitoring-guide.md
- [ ] operations/monitoring/dashboards/grafana-setup.md
- [ ] operations/monitoring/alerts/prometheus-alerts.md
- [ ] operations/monitoring/alerts/alertmanager-config.md
- [ ] operations/monitoring/queries/prometheus-queries.md
- [ ] operations/monitoring/components/rag-monitoring.md
- [ ] operations/monitoring/troubleshooting.md

**Database (7 файлов):**

- [ ] operations/database/README.md
- [ ] operations/database/postgresql/setup.md
- [ ] operations/database/postgresql/optimizations.md
- [ ] operations/database/postgresql/monitoring.md
- [ ] operations/database/postgresql/troubleshooting.md
- [ ] operations/database/redis/operations.md
- [ ] operations/database/vllm/resource-optimization.md

#### Reference (11 файлов, ~12 часов)

- [ ] reference/README.md
- [ ] reference/api-reference.md
- [ ] reference/development.md
- [ ] reference/github-environments-setup.md
- [ ] reference/mcpo-integration-guide.md
- [ ] reference/pre-commit-hooks.md
- [ ] reference/language-policy.md
- [ ] reference/metadata-standards.md
- [ ] reference/documentation-refactoring-plan-v2-2025-11-24.md
- [ ] reference/status-snippet.md
- [ ] reference/CHANGELOG.md

#### DE недостающие (28 файлов, ~14 часов)

**Приоритет:**

- [ ] getting-started/README.md
- [ ] getting-started/dnsmasq-setup-instructions.md
- [ ] getting-started/external-access-setup.md
- [ ] getting-started/local-network-dns-setup.md
- [ ] getting-started/port-forwarding-setup.md
- [ ] academy/howto/create-jira-ticket.md
- [ ] GLOSSARY.md
- [ ] VERSION.md

---

## 📊 Метрики прогресса

### Текущее состояние

| Метрика                    | Значение |
| -------------------------- | -------- |
| Stub документов            | 20       |
| Orphaned документов        | 101      |
| Дубликатов main/archive    | 4        |
| Документов с deprecations  | 4        |
| EN покрытие                | 18.2%    |
| DE покрытие                | 73.9%    |
| README в operations/       | 3/7      |
| Консолидированных разделов | 0        |

### Цели после каждой фазы

**После Фазы 1 (3 дня):**

| Метрика                   | Цель |
| ------------------------- | ---- |
| Stub документов           | 0    |
| Дубликатов                | 0    |
| Документов с deprecations | 0    |
| README в operations/      | 7/7  |

**После Фазы 2 (1 неделя):**

| Метрика             | Цель |
| ------------------- | ---- |
| Orphaned документов | <30  |

**После Фазы 3 (3 недели):**

| Метрика                    | Цель |
| -------------------------- | ---- |
| Консолидированных разделов | 3    |

**После Фазы 4 (1 месяц):**

| Метрика     | Цель |
| ----------- | ---- |
| EN покрытие | 50%  |

**После Фазы 5 (2 месяца):**

| Метрика     | Цель |
| ----------- | ---- |
| EN покрытие | 70%  |
| DE покрытие | 90%  |

---

## 🎯 Quick Start

### Начать сегодня - Фаза 1 День 1

```bash
# 1. Создать ветку
git checkout -b docs/refactoring-phase-1-stubs

# 2. Удалить EN/DE academy stubs (настроить redirects в mkdocs.yml)
rm en/academy/openwebui-basics.md
rm en/academy/prompting-101.md
# ... остальные 11 файлов

# 3. Расширить operations stubs
# Отредактировать de/operations/backup-guide.md (8 → 200+ слов)
# Отредактировать de/operations/troubleshooting.md (9 → 200+ слов)
# ... и т.д.

# 4. Коммит
git add .
git commit -m "docs(refactor): remove stub documents, setup redirects"

# 5. Обновить mkdocs.yml с redirects
# Добавить плагин redirects и настроить

# 6. Протестировать
mkdocs serve

# 7. Создать PR
gh pr create --title "docs: Phase 1 Day 1 - Remove stub documents"
```

---

## 📚 Связанные документы

- [Первый комплексный аудит](../archive/audits/comprehensive-documentation-audit-2025-11-24.md)
- [Повторный аудит с фокусом на рефакторинг](../archive/audits/documentation-refactoring-audit-2025-11-24.md)
- [Оригинальный план рефакторинга](documentation-refactoring-plan-2025-11-24.md)
- [Стандарты метаданных](metadata-standards.md)
- [Языковая политика](language-policy.md)
- [VERSION](../VERSION.md)

---

**План создан:** 2025-11-24 **Базируется на:** 2 комплексных аудитах **Статус:**
🔴 Фаза 1 готова к началу **Следующий пересмотр:** После завершения Фазы 1
