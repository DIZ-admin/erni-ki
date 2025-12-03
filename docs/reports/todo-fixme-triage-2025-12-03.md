---
language: ru
translation_status: original
doc_version: '2025.12'
last_updated: '2025-12-03'
title: 'TODO/FIXME Triage'
---

# TODO/FIXME Triage — 2025-12-03

Пробег по репозиторию `rg "(TODO|FIXME)"` (prod-ветка). Категоризация:

## Actionable (созданы задачи в Archon)

1. `conf/nginx/conf.d/default.conf` — TODO восстановить ограничения
   - Задача: Restore Nginx restrictions in default.conf (security) — task
     `abfa42f6-9eed-4b0c-b1ea-8b77c28469e7`.

2. `docs/en/security/index.md` — TODO placeholders (контент)
   - Задача: Fill security landing page content — task
     `1791290e-7bdc-4da5-91cf-18337fb0a77d`.

3. `docs/reports/follow-up-audit-2025-11-28.md` — TODO content/links
   - Задача: Complete follow-up audit report content — task
     `300b61d7-d679-4278-9004-799626ee4b31`.

## Informational / Archive (no immediate action)

- `CONTRIBUTING.md` — упоминание TODO/FIXME без задач (описательная).
- Архив/аудиты/планы (`docs/archive/...`, `docs/archive/migrations/...`,
  `docs/reports/comprehensive-audit-2025-11-28.md`) — исторические заметки, без
  прод-эффекта.
- `scripts/archon/README.md` — описание работы с TODO в Archon (не исполнение).

## Summary

- Actionable: 3 (созданы отдельные задачи).
- Archive/info-only: остальные (оставлены как есть).

Следующие шаги: закрыть три задачи выше; после выполнения пересканировать при
необходимости.\*\*\*
