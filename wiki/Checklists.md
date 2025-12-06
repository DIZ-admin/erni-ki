# Checklists

## Перед релизом

- CI `ci` и `security` зелёные.
- Обновить версии/статус в `README.md` и `docs/system/status.md`.
- Проверить лимиты ресурсов в `compose.yml` и актуальность digest.
- Обновить дашборды/алерты при изменении метрик.
- Убедиться, что открытые задачи не блокируют релиз (read-only stateless,
  Grafana secrets → secrets, WebSocket rate limit, Redis pin, logging stack,
  backup verification, integration tests, pre-commit refactor).

## Обновление образов

- Получить новый digest (`docker manifest inspect ...`).
- Обновить `compose.yml` и таблицы в `docs/architecture/service-inventory.md`.
- Для сервисов с автообновлением (watchtower labels) — убедиться, что лейблы
  заданы корректно; для критичных — обновлять вручную.

## Операции и обслуживание

- Запуск `docling-shared-cleanup.sh --apply` по расписанию, проверка логов.
- Контроль объёма логов Loki/Fluent Bit; при необходимости чистка `data/loki`,
  `data/logs-optimized` (согласно runbook).
- Проверка бэкапов Backrest и тестовое восстановление на стейдж.

## Безопасность

- Секреты: только в Docker secrets/GitHub Environments, не в
  repo/env/\*.example.
- Обновить блокировки зависимостей (npm, Python, Go) и прогнать security сканеры
  (CodeQL, Trivy, Gosec, Grype, Checkov).
- Верифицировать Cloudflare tunnel токены и TLS.
- Проверить, что CORS/CSP/ACL остаются актуальными после изменений доменов.
