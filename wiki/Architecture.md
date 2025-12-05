# Architecture

Ключевые слои и сервисы стека. Полный список и лимиты ресурсов смотрите в
`docs/architecture/service-inventory.md` (+ локализации).

## Слои

- **AI/UI:** OpenWebUI (GPU), LiteLLM (proxy), Ollama (GPU),
  Docling/Tika/EdgeTTS.
- **Gateway & Access:** Nginx (TLS, WAF), Auth (JWT), Cloudflared (tunnel).
- **Data:** PostgreSQL 17 + pgvector, Redis 7, Backrest (backup).
- **Observability:** Prometheus, Grafana, Loki, Fluent Bit, Alertmanager,
  exporters.
- **Automation:** Watchtower (выборочное автообновление), cron задачи (VACUUM,
  cleanup), pre-commit/CI.

## GPU/ресурсы

- GPU привязка через `.env` (`*_GPU_VISIBLE_DEVICES`, `*_GPU_DEVICE_IDS`).
- Критичные сервисы с отрицательным `oom_score_adj`: Ollama (-900), OpenWebUI
  (-600), Docling (-500), LiteLLM (-300).

## Точки входа

- Пользователи: `https://ki.erni-gruppe.ch` (или `localhost:8080` через Nginx).
- Внутренние API: Auth (`9092`), LiteLLM (`4000`), Docling (`5001`), Tika
  (`9998`), EdgeTTS (`5050`); обычно доступны через docker-сеть/Nginx.
- SearXNG API: ограничен ACL на RFC1918/localhost.

## Документы

- Справочник сервисов: `docs/architecture/service-inventory.md`.
- Обзор/архитектура: `docs/architecture/` и `docs/overview.md`.
- API/интеграции: `docs/reference/api-reference.md`.
