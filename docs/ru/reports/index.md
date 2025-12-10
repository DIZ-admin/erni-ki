---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-10'
---

# Отчеты и аудиты проекта

Эта директория содержит постоянную справочную документацию об аудитах проекта,
анализах и текущем обслуживании документации.

## Постоянная документация

### Конфигурация и планирование

- [Аудит согласованности конфигурации](./configuration-consistency-audit.md) -
  Комплексный аудит файлов конфигурации проекта
- [Анализ TODO](./todo-analysis.md) - Анализ комментариев TODO/FIXME в кодовой
  базе
- [План преобразования TODO](./todo-conversion-plan.md) - План управления и
  преобразования элементов TODO

## Исторические отчеты

Все датированные отчеты и разовые аудиты перенесены в
[архив](../archive/reports/index.md):

- [ERNI-KI Comprehensive Analysis 2025-12-02](../archive/reports/erni-ki-comprehensive-analysis-2025-12-02.md)
- [Redis Comprehensive Analysis 2025-12-02](../archive/reports/redis-comprehensive-analysis-2025-12-02.md)
- [TODO/FIXME Triage 2025-12-03](../archive/reports/todo-fixme-triage-2025-12-03.md)

Отчеты по безопасности см. в
[Плане действий по безопасности](../operations/security-action-plan.md).

## Частота аудитов

Согласно
[Стратегии обслуживания документации](../reference/documentation-maintenance-strategy.md):

- **Комплексные аудиты:** Ежеквартально (каждые 3 месяца)
- **Быстрые аудиты:** Ежемесячно (автоматизированные через скрипты)
- **Проверки CI/CD:** На каждом PR

## Последний аудит

**Дата последнего системного анализа:** 2025-12-02 **Следующий аудит:** по плану
maintenance strategy или по запросу

## Инструменты аудита

Скрипты аудита документации находятся в `scripts/docs/`:

- `scripts/docs/audit-documentation.py` - автоматический аудит документации
- `scripts/remove-all-emoji.py` - удаление эмоджи
- `scripts/validate-no-emoji.py` - валидация no-emoji policy

## Связанные документы

- [Стратегия обслуживания документации](../reference/documentation-maintenance-strategy.md)
- [Политика NO-EMOJI](../reference/NO-EMOJI-POLICY.md)
- [Руководство по стилю](../reference/style-guide.md)
- [Стандарты метаданных](../reference/metadata-standards.md)
