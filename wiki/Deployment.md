# Deployment

## Быстрый старт (локально)

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
for f in env/*.example; do cp "$f" "${f%.example}.env"; done
./scripts/maintenance/download-docling-models.sh   # кэш Docling
docker compose up -d
```

Доступ: `http://localhost:8080`.

## Прод/стейджинг

- Домен: `https://ki.erni-gruppe.ch` (Nginx + Cloudflare Tunnel).
- Образы закреплены на версиях/digest (см. `compose.yml`).
- Обязательные секреты хранятся в Docker secrets (пароли БД, ключи
  LiteLLM/OpenWebUI и др.). Grafana переводится на secrets (задача в работе).
- GPU включается через `.env` (`OLLAMA_GPU_*`, `OPENWEBUI_GPU_*`,
  `DOCLING_GPU_*`).
- Auth: поддержка audience в `WEBUI_JWT_AUDIENCE` (опционально), секрет —
  `WEBUI_SECRET_KEY` (secret file).

## Обновления образов

- Критичный прокси (`nginx`) и Ollama — без автообновлений.
- Остальные группы помечены лейблами watchtower: `ai-services`,
  `document-processing`, `auth-services`, `cache-services`.
- Обновление digest для образов с `latest` — чеклист в
  `docs/operations/maintenance/image-upgrade-checklist.md`.
- Redis pinned на `redis:7.0.15-alpine` (не обновлять до RDB v12 без плана).

## Полезные документы

- GitHub/CI: `docs/operations/core/github-governance.md`,
  `docs/reference/github-environments-setup.md`.
- Сервисы и порты: `docs/architecture/service-inventory.md`.
- Статусы и SLA: `docs/system/status.md`, `docs/operations/core/status-page.md`.
