---
language: ru
translation_status: draft
doc_version: '2025.12'
last_updated: '2025-12-01'
---

# Миграция legacy скриптов мониторинга

## Что поменялось

- `scripts/health-monitor.sh` перемещён в `scripts/legacy/health-monitor.sh` и
  помечен как LEGACY; основной скрипт — `scripts/health-monitor-v2.sh`.
- `scripts/health-monitor.sh` в корне теперь тонкая обёртка, которая вызывает
  v2 и предупреждает о депрекации.
- Cron-настройки в `scripts/setup-monitoring.sh` и совместимые входные точки
  (`scripts/erni-ki-health-check.sh`, `scripts/core/diagnostics/health-check.sh`)
  переключены на v2.
- `docs/update_status_snippet.py` остаётся только как совместимая оболочка к
  `docs/update_status_snippet_v2.py`.

## Как перейти

1. Замените вызовы `./scripts/health-monitor.sh` в cron/CI на
   `./scripts/health-monitor-v2.sh`.
2. Для ручных проверок используйте:
   `./scripts/health-monitor-v2.sh --report /tmp/health.md`.
3. Если нужно старое поведение, оно доступно в
   `scripts/legacy/health-monitor.sh` (см. LEGACY-комментарий внутри).

## Обратная совместимость

- Обёртка `scripts/health-monitor.sh` остаётся работоспособной, но выводит
  предупреждение. Для тихого режима задайте
  `SUPPRESS_HEALTH_MONITOR_LEGACY_NOTICE=1`.
- Переменные из `env/health-monitor.env` продолжают работать и для v2.

## Проверки

- `./scripts/health-monitor-v2.sh --report /tmp/health.md` — формирует свежий
  отчёт без ошибок.
- `./scripts/erni-ki-health-check.sh` — генерирует markdown-репорт, используя
  v2.
- `crontab -l | grep health-monitor-v2.sh` — убедитесь, что расписание обновлено.
