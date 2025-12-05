# ERNI-KI — Production AI Platform (wiki updated: 2025-12-05)

Добро пожаловать в wiki проекта ERNI-KI (OpenWebUI + Ollama + LiteLLM + Docling
с полной наблюдаемостью). Здесь собраны краткие инструкции и ссылки на первичные
источники в `docs/`.

- [[Architecture]] — ключевые сервисы и зависимости
- [[Deployment]] — запуск локально и требования прод (GPU, secrets)
- [[Operations]] — рутины, бэкапы, очистки, обновления образов
- [[Monitoring-Alerts]] — метрики, дашборды, алерты, ACL
- [[Security]] — секреты, CORS/CSP, периметр, политика обновлений
- [[Checklists]] — релизы, обновления образов, готовность к прод (учёт открытых
  задач)
- [[FAQ]] — частые вопросы
- [[Governance]] — кто и как обновляет wiki/конфиги

Полный каталог документов в репозитории: `docs/index.md`, `docs/en/index.md`,
`docs/de/index.md`.

## Pending (важные открытые задачи)

- Read-only для stateless (nginx cache, searxng cache, redis/postgres exporters,
  auth)
- Grafana admin → Docker secrets
- WebSocket rate limiting (Nginx)
- Redis pinned & автообновления выключены
- Централизованный лог-стек (Loki/Promtail)
- Интеграционные smoke-тесты docker-compose
- Автоверификация бэкапов Backrest
- Pre-commit refactor (фазы 1-3)
