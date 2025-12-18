---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-16'
---

# Статус системы

Онлайн-панель: **[Status Dashboard](https://status.ki.erni-gruppe.ch)** (Uptime
Kuma).

## Текущее состояние

**Статус:** PRODUCTION READY (аудит 2025-12-16)

| Компонент  | Версия          | Статус  |
| ---------- | --------------- | ------- |
| Ollama     | 0.13.4          | Healthy |
| OpenWebUI  | v0.6.40         | Healthy |
| LiteLLM    | v1.80.0         | Healthy |
| PostgreSQL | 17.7 + pgvector | Healthy |
| Redis      | 7.0.15          | Healthy |
| nginx      | 1.29.3          | Healthy |

**Контейнеры:** 33/33 healthy

### Ресурсы

| Ресурс | Использование                    |
| ------ | -------------------------------- |
| RAM    | 40 GB / 125 GB (32%)             |
| Disk   | 318 GB / 468 GB (72%)            |
| GPU    | Quadro RTX 5000 (34% util, 32°C) |

### Backup

- **Последний backup:** ежедневно в 00:01
- **Retention:** 7 daily, 4 weekly, 3 monthly
- **Статус:** Healthy

## Значения статусов

- **Работает** — все сервисы в норме.
- **Частично** — есть деградация, часть функций недоступна.
- **Обслуживание** — плановые работы, возможны перерывы.
- **Не работает** — критический простой, используйте резервные каналы.

## Что мониторится

- Open WebUI (`https://ki.erni-gruppe.ch`) и LiteLLM gateway.
- Backend/интеграции: БД, Redis, Docling/Tika, EdgeTTS.
- Обсервабилити: Prometheus, Grafana, Alertmanager, Loki.
- Сети и прокси: Nginx/reverse-proxy, Cloudflare Zero Trust.
- 92 alert rules с автоматическим оповещением.

## Что делать, если горит красным

1. Проверьте, указан ли инцидент в панели (Uptime Kuma).
2. Сообщите в поддержку ERNI KI с указанием времени и действий; приложите ссылку
   на конкретный монитор.
3. Избегайте массовых перезапусков сервисов, пока нет обновления от SRE.

## Документация

- [Production Readiness Audit 2025-12-16](../archive/audits/production-readiness-audit-2025-12-16.md)
