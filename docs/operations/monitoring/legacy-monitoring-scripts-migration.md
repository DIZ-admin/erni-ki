---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-01'
---

# Legacy Monitoring Scripts Migration

## What Changed

- `scripts/health-monitor.sh` moved to `scripts/legacy/health-monitor.sh` and
  marked as LEGACY; main script is now `scripts/health-monitor-v2.sh`.
- `scripts/health-monitor.sh` in root is now a thin wrapper that calls v2 and
  warns about deprecation.
- Cron settings in `scripts/setup-monitoring.sh` and compatible entry points
  (`scripts/erni-ki-health-check.sh`,
  `scripts/core/diagnostics/health-check.sh`) switched to v2.
- `docs/update_status_snippet.py` remains only as a compatible wrapper to
  `docs/update_status_snippet_v2.py`.

## How to Migrate

1. Replace `./scripts/health-monitor.sh` calls in cron/CI with
   `./scripts/health-monitor-v2.sh`.
2. For manual checks use:
   `./scripts/health-monitor-v2.sh --report /tmp/health.md`.
3. If you need old behavior, it's available in
   `scripts/legacy/health-monitor.sh` (see LEGACY comment inside).

## Backward Compatibility

- Wrapper `scripts/health-monitor.sh` remains functional but outputs warning.
  For silent mode set `SUPPRESS_HEALTH_MONITOR_LEGACY_NOTICE=1`.
- Variables from `env/health-monitor.env` continue to work for v2 as well.

## Checks

- `./scripts/health-monitor-v2.sh --report /tmp/health.md` — generates fresh
  report without errors.
- `./scripts/erni-ki-health-check.sh` — generates markdown report using v2.
- `crontab -l | grep health-monitor-v2.sh` — verify schedule is updated.
