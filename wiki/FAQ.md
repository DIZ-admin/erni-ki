# FAQ

**Где смотреть статус системы?**  
`docs/operations/core/status-page.md` + локализованные страницы
`docs/*/system/status.md`.

**Как обновить модели Docling?**  
`./scripts/maintenance/download-docling-models.sh` (кэшируются в
`data/docling/docling-models`).

**Как почистить Docling shared volume?**  
`./scripts/maintenance/docling-shared-cleanup.sh --apply` (dry-run по
умолчанию). Политика и cron —
`docs/operations/runbooks/docling-shared-volume.md`.

**Как ограничить доступ к мониторингу?**  
Порты Prometheus/Grafana/Loki/Alertmanager проброшены только на localhost; для
удалённого доступа используйте Nginx c auth/TLS, VPN или SSH-туннель.

**Что делать при обновлении образов без версий (`latest`)?**  
Зафиксировать digest, обновить `compose.yml` и таблицу в
`docs/architecture/service-inventory.md`, затем
`docker compose pull <svc> && docker compose up -d <svc>`.

**Какой порядок веток?**  
Работа — в `develop`, релизы — через PR в `main`; обязательны проверки `ci`,
`security`, `deploy-environments`.

**Где найти политики GitHub/CI?**  
`docs/operations/core/github-governance.md`, `docs/reference/github-environments-setup.md`,
`.github/workflows/*.yml`.
