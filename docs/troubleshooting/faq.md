---
language: ru
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-30'
title: 'FAQ: Частые вопросы по ERNI-KI'
---

# FAQ: Частые вопросы

Подборка быстрых ответов на типовые проблемы при работе с ERNI-KI. Для детальных
процедур см. runbooks в `docs/operations/`.

## Сервисы не стартуют после `docker compose up`

- Проверьте `.env` файлы скопированы из `env/*.example`.
- Убедитесь, что порты 8080/11434/4000 не заняты (`lsof -i :8080` и т.д.).
- Запустите `docker compose ps` и `docker compose logs --tail=50` для проблемных
  сервисов.

## Нет доступа к OpenWebUI

- Локально: откройте http://localhost:8080 (или прокси через Nginx/Cloudflare).
- Проверьте Nginx: `docker compose logs nginx | tail -n 50`.
- Убедитесь в валидности TLS/сертификатов при доступе снаружи.

## Модели Ollama не загружаются

- Проверьте доступ в интернет с хоста, где крутится Ollama.
- Убедитесь, что переменные GPU (`OLLAMA_GPU_VISIBLE_DEVICES`) корректны.
- Логи: `docker compose logs ollama --tail=50`.

## Ошибки LiteLLM / прокси

- Проверить Redis/PostgreSQL доступность (`docker compose ps redis db`).
- Убедиться, что `litellm_api_key` и `openai_api_key` заданы (secrets/или env).
- Логи: `docker compose logs litellm --tail=100`.

## Мониторинг/алерты не работают

- Проверьте, что Prometheus цели UP:
  `curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets | length'`.
- Grafana доступна на 3000 (локально): убедитесь в корректности admin-пароля из
  secret.
- Ссылки на процедуры: `docs/operations/monitoring/monitoring-guide.md`.

## Куда смотреть при инциденте

1. Проверить статус сервисов: `docker compose ps`.
2. Просмотреть последние ошибки:
   `docker compose logs --tail=50 | grep -i error`.
3. Проверить ресурсы: `docker stats`, `nvidia-smi` (для GPU).
4. Следовать runbook:
   `docs/operations/troubleshooting/troubleshooting-guide.md`.

## Как обновить образы

- Используйте чек-лист `docs/operations/maintenance/image-upgrade-checklist.md`.
- Pinned digests для образов указаны в `docs/architecture/service-inventory.md`.
- После обновления:
  `docker compose pull <service> && docker compose up -d <service>`.

## Куда репортить новые вопросы

- Создайте issue в GitHub с минимальным воспроизводимым примером и логами.
- Добавьте вопрос в этот FAQ после решения и обновите дату в frontmatter.
