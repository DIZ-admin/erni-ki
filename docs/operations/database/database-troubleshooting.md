---
language: ru
title: 'Database Troubleshooting'
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Database Troubleshooting

## Введение

В этом документе приведены шаги по диагностике и устранению распространенных
проблем с базой данных.

## Инструменты диагностики

- Используйте `docker compose exec db psql` для прямого доступа к базе данных.
- Проверяйте текущую активность через представление `pg_stat_activity`.

## Известные проблемы

- Сравните текущие симптомы с отчетом
  `../../archive/reports/log-analysis-correction-2025-11-04.md` для выявления
  повторяющихся проблем.
