---
language: ru
translation_status: archived
doc_version: '2025.11'
---

# Архив аудитов ERNI-KI

| Файл                                              | Фокус / ключевые выводы                                               |
| ------------------------------------------------- | --------------------------------------------------------------------- |
| `documentation-audit-2025-10-24.md`               | Проверка полноты документации, выявлены дубли и пробелы в runbook’ах. |
| `documentation-cleanup-audit-2025-10-24.md`       | План очистки/структурирования docs, внедрение MkDocs best practices.  |
| `documentation-cleanup-summary-2025-10-24.md`     | Результат cleanup: 82 файла, упорядочены гайды/handbooks.             |
| `documentation-audit.md`                          | Базовый аудит документации (сводка без дат), стартовая точка.         |
| `best-practices-audit-2025-10-20.md`              | Проверка DevOps/MLOps практик (backups, observability, security).     |
| `comprehensive-audit-2025-10-14.md`               | Полный аудит инфраструктуры и процессов (pre-prod).                   |
| `comprehensive-project-audit-2025-10-17.md`       | Часть 1 проектного аудита: архитектура, observability, runbooks.      |
| `comprehensive-project-audit-2025-10-17-part2.md` | Часть 2 проектного аудита: интеграции, SRE процессы.                  |
| `monitoring-audit.md`                             | Чек наблюдаемости, покрытие метрик/алертов/дашбордов.                 |
| `ci-health.md`                                    | Проверка CI: линтеры, тесты, покрытие хуков и статуса workflow.       |
| `code-audit-2025-11-24.md`                        | Аудит кодовой базы: структура, качество, покрытие тестами.            |
| `documentation-refactoring-audit-2025-11-24.md`   | Быстрый аудит refactoring-плана, выравнивание метаданных.             |
| `comprehensive-documentation-audit-2025-11-24.md` | Полный аудит документации: метаданные, переводы, TOC, битые ссылки.   |
| `comprehensive-documentation-audit-2025-11-25.md` | Обновлённый аудит документации: фиксация прогресса и новых пробелов.  |
| `configuration-audit-report-2025-11-25.md`        | Конфигурационный аудит: параметры окружений, конфигов и секретов.     |
| `service-version-audit-2025-11-25.md`             | Базовый аудит версий сервисов и целевых обновлений.                   |
| `service-version-matrix-2025-11-25.md`            | Матрица версий (25.11.2025): текущие/доступные версии, разрывы.       |
| `service-version-matrix-2025-11-28.md`            | Матрица версий (28.11.2025): обновленные цели после Cloudflared.      |
| `index.md`                                        | Оглавление архива аудитов и навигация по отчётам.                     |

> Используйте эти файлы при оценке регресса документации и подготовке новых
> аудитов. Ссылки в operations-handbook.md должны вести на краткое summary и
> конкретный отчёт при необходимости детализации.
