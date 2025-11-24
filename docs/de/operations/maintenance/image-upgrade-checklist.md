---
language: de
translation_status: in_progress
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Checklist: Image Upgrade

Kurzer Leitfaden für sichere Image-Updates.

## Vorbereitung

- Notieren: aktuelle Versionsstände/Tags
- Backup configs (`env/`, `conf/`, `compose.yml`)
- Prüfen: Changelogs/Breaking Changes

## Ablauf

1. **Pull neue Images**
   ```bash
   docker compose pull
   ```
2. **Optional: Test im Staging**
   - `docker compose -f compose.yml -f compose.staging.yml up -d`
   - Smoke-Tests (Healthchecks, UI, API)
3. **Deploy in Prod**
   ```bash
   docker compose up -d
   ```
4. **Verifikation**
   - `docker compose ps` – Status
   - Healthchecks: OpenWebUI, LiteLLM, Prometheus, Grafana
   - Logs: `docker compose logs --tail=50`

## Rollback

- Vorherige Tags notieren (z.B. `:prev`)
- `docker compose down` + `docker compose up -d` mit alten Tags
- Nach Rollback Healthchecks wiederholen

## Nacharbeiten

- Versionen in Docs/Statussnippet aktualisieren
- ggf. Alerting/Monitoringschwellen prüfen
