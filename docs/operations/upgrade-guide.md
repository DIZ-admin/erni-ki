---
language: ru
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-30'
title: 'Upgrade Guide'
---

# Upgrade Guide

Процедура обновления ERNI-KI (образы, конфигурации, миграции). Следуйте порядку,
чтобы минимизировать простой и сохранить совместимость.

## Подготовка (T-1 день)

- Зафиксируйте текущую версию и чекпоинт БД:
  `docker compose exec db pg_dump -U openwebui_user openwebui > backup.sql`.
- Обновите changelog и планы: что меняется (версии OpenWebUI/LiteLLM/Docling,
  зависимости, конфиги).
- Проверьте совместимость: сравните `compose.yml` с
  `docs/architecture/service-inventory.md` и `env/*.env`.

## Обновление образов

1. Обновите pinned образы (по digest или версии) в `compose.yml`.
2. Протяните образы: `docker compose pull <service1> <service2>`.
3. Примените: `docker compose up -d <service1> <service2>`.
4. Верификация: healthchecks `docker compose ps`, логи
   `docker compose logs --tail=50 | grep -i error`.

## Миграции баз и конфигов

- Запустите миграции (если есть): `./scripts/migrations/run.sh` или инструкции
  сервиса.
- Проверьте совместимость схемы:
  `psql -U openwebui_user -d openwebui -c "SELECT version();"`.
- Для Redis/кашей — очистка только при несовместимости (см. release notes).

## Тестирование после обновления

- Юнит/интеграция: `npm run test`, `pytest tests/`, `go test ./auth/...`.
- E2E smoke: `npm run test:e2e:mock` или минимальный набор из
  `docs/deployment/production-checklist.md`.
- Мониторинг: цели Prometheus UP, дашборды Grafana загружены, алерты активны.

## Откат

- Вернуть предыдущие образы:
  `docker compose pull <service>=<old_tag_or_digest> && docker compose up -d <service>`.
- Восстановить БД из снапшота при необходимости.
- Зафиксировать инцидент/причину отката в runbook.

## Документация

- После успешного обновления обновите `last_updated` и версии в затронутых
  документах.
- Добавьте примечания об изменениях в `docs/architecture/service-inventory.md` и
  релиз-ноты в `CHANGELOG.md`.
