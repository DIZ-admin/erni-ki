---
language: ru
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-30'
title: 'Webhook API'
---

# Webhook API

Краткая справка по вебхукам ERNI-KI (Alertmanager, пользовательские события).
Для полного описания маршрутов см. `docs/reference/api-reference.md`.

## Эндпоинты

- `POST /webhooks/prometheus` — приём алертов Alertmanager.
- `POST /webhooks/custom/:channel` — пользовательские интеграции (канал задаёт
  тип маршрутизации).

Headers: `Content-Type: application/json`, опционально `X-Signature` для HMAC
(см. секцию безопасности).

## Подпись и безопасность

- Секрет: `ALERTMANAGER_WEBHOOK_SECRET` или секрет канала (docker secret / env).
- Подпись формируется HMAC-SHA256 по телу запроса. Проверка включена по
  умолчанию.
- Рекомендуется ограничить доступ по сети через Nginx/Cloudflare и rate limit.

## Мониторинг и тесты

- Руководство по проверке и мониторингу webhook-пайплайна:
  [Monitoring Guide](../operations/monitoring/monitoring-guide.md).
- Тестовый клиент: `docs/examples/webhook-client-python.py` (см.
  `docs/en/examples/index.md`).

## Примеры

```bash
curl -X POST https://ki.erni-gruppe.ch/webhooks/prometheus \
  -H "Content-Type: application/json" \
  -H "X-Signature: <hmac>" \
  -d '{"alerts":[{"status":"firing","labels":{"alertname":"Test"}}]}'
```

```bash
curl -X POST https://ki.erni-gruppe.ch/webhooks/custom/critical \
  -H "Content-Type: application/json" \
  -d '{"message":"hello"}'
```
