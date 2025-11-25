---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
title: 'Service-Inventar ERNI-KI'
---

# Service-Inventar ERNI-KI

Aggregierte Infos aus `compose.yml` und `env/*.env`: Zweck, Ports,
Abhängigkeiten, Security-Anforderungen. Für Image-Updates siehe
[checklist](../operations/image-upgrade-checklist.md).

## Basis-Infrastruktur und Storage

| Service      | Zweck                              | Ports                                  | Abhängigkeiten/Konfig                                                                | Updates/Notizen                                                                                      |
| ------------ | ---------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `watchtower` | Auto-Updates, Cleanup alter Images | `127.0.0.1:8091->8080` (nur localhost) | `env/watchtower.env`, Docker socket, Secret `watchtower_api_token`                   | API nur mit Token; Limits `mem_limit=256M`, `mem_reservation=128M`, `cpus=0.2`, `oom_score_adj=500`. |
| `db`         | PostgreSQL 17 + pgvector           | Nur intern                             | `env/db.env`, Secret `postgres_password`, `postgresql.conf`, Daten `./data/postgres` | Kein Auto-Update; Healthcheck `pg_isready`.                                                          |
| `redis`      | Cache/Queues/Rate Limit            | Nur intern                             | `env/redis.env`, `./conf/redis/redis.conf`, Daten `./data/redis`                     | Watchtower erlaubt (`cache-services`); RDB-Kompatibilität prüfen.                                    |
| `backrest`   | Backups Daten/Konfig               | `9898:9898`                            | `env/backrest.env`, viele Volumes, Docker socket                                     | Auto-Update an; Rechte auf Backup-Pfade prüfen.                                                      |

## Zugang & Peripherie

| Service       | Zweck                                                                                                   | Ports                     | Abhängigkeiten/Konfig                                                                                                                                                                                         | Updates/Notizen                                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `nginx`       | Reverse Proxy, TLS Termination                                                                          | `80`, `443`, `8080`       | Konfig `./conf/nginx`, SSL `./conf/nginx/ssl`                                                                                                                                                                 | Watchtower aus; Healthcheck `/etc/nginx/healthcheck.sh`.                                                               |
| `cloudflared` | Tunnel nach außen                                                                                       | Keine                     | `env/cloudflared.env`, `./conf/cloudflare/config`                                                                                                                                                             | Watchtower an; gültiger CF-Tunnel-Token nötig.                                                                         |
| `auth`        | JWT-Auth für interne APIs                                                                               | `9092:9090`               | `env/auth.env`, Image aus `./auth`                                                                                                                                                                            | Auto-Update erlaubt (`auth-services`).                                                                                 |
| `mcposerver`  | MCP Server (Time, Context7 Docs, PostgreSQL, Filesystem, Memory, SearXNG Web Search, Desktop Commander) | `127.0.0.1:8000->8000`    | `env/mcposerver.env`, `./conf/mcposerver`, Daten `./data`, Desktop Commander HOME `./data/desktop-commander`, FS Sandbox `/app/data/mcpo-desktop`                                                             | Auto-Update an; hängt von `db`; bind auf localhost. Desktop Commander mit eingeschränkten Directories, Telemetrie aus. |
| `searxng`     | Metasuche                                                                                               | intern                    | `env/searxng.env`, `./conf/searxng/*.yml`                                                                                                                                                                     | Watchtower an; Image per Digest fixiert.                                                                               |
| `edgetts`     | Text-to-Speech                                                                                          | `5050:5050`               | `env/edgetts.env`, Healthcheck über Python socket                                                                                                                                                             | Watchtower an; Digest fixiert.                                                                                         |
| `tika`        | Content/OCR-Extraktion                                                                                  | `9998:9998`               | `env/tika.env`                                                                                                                                                                                                | Watchtower an; Digest fixiert.                                                                                         |
| `litellm`     | LiteLLM Proxy (Thinking Tokens)                                                                         | `4000:4000`               | `env/litellm.env`, `./conf/litellm/config.yaml`, Daten `./data/litellm`, entrypoint `scripts/entrypoints/litellm.sh`, Secrets `litellm_*`, `openai_api_key`; hängt von `db`, `ollama`                         | Auto-Update an; Limits `mem_limit=12G`, `mem_reservation=6G`, `cpus=1.0`, `oom_score_adj=-300`.                        |
| `ollama`      | GPU LLM Server                                                                                          | `11434:11434`             | `env/ollama.env`, Modelle `./data/ollama`, GPU via `.env` (`OLLAMA_GPU_*`)                                                                                                                                    | Watchtower aus; Limits `mem_limit=16G`, `mem_reservation=8G`, `cpus=12`, `oom_score_adj=-900`.                         |
| `openwebui`   | Haupt-UI (Next.js)                                                                                      | via Nginx (`8080` intern) | `env/openwebui.env`, Daten `./data/openwebui`, `./data/docling/shared`, entrypoint `scripts/entrypoints/openwebui.sh`, Secrets `postgres_password`, `litellm_api_key`, `openwebui_secret_key`, GPU via `.env` | Watchtower an; Limits `mem_limit=8G`, `mem_reservation=4G`, `cpus=4`, `oom_score_adj=-600`.                            |
| `docling`     | OCR/Doc Ingestion                                                                                       | intern (`5001`)           | `env/docling.env`, Modelle `./data/docling/docling-models`, Shared `./data/docling/shared`, GPU via `.env`                                                                                                    | Auto-Update an; Limits `mem_limit=12G`, `mem_reservation=8G`, `cpus=8`, `oom_score_adj=-500`.                          |

## Monitoring & Logging

| Service                   | Zweck                 | Ports                       | Abhängigkeiten/Konfig                                               | Updates/Notizen                                                                           |
| ------------------------- | --------------------- | --------------------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `prometheus`              | Metrik-Sammlung       | `127.0.0.1:9091->9090`      | `./conf/prometheus`, Daten `./data/prometheus`                      | Nur lokal; externer Zugriff via Nginx/SSH.                                                |
| `grafana`                 | Dashboards & Alerts   | `127.0.0.1:3000->3000`      | Daten `./data/grafana`, Provisioning `./conf/grafana`, Admin-Secret | Lokal; Zugang via Proxy/VPN.                                                              |
| `loki`                    | Log-Storage           | `127.0.0.1:3100->3100`      | `./conf/loki/loki-config.yaml`, Daten `./data/loki`                 | Watchtower an; Port nur lokal.                                                            |
| `alertmanager`            | Prometheus Alerts     | `127.0.0.1:9093/9094`       | `./conf/alertmanager`, Daten `./data/alertmanager`                  | Lokal-only; Proxy bei Bedarf.                                                             |
| `node-exporter`           | Host-Metriken         | `127.0.0.1:9101->9100`      | Mounts `/proc`, `/sys`, `/rootfs`, `pid: host`                      | Lokal.                                                                                    |
| `postgres-exporter`       | Postgres-Metriken     | `127.0.0.1:9188->9188`      | DSN aus Secret `postgres_exporter_dsn`, hängt von `db`              | Lokal.                                                                                    |
| `postgres-exporter-proxy` | Socat IPv4→IPv6       | shared network mit exporter | Alpine/socat                                                        | Ressourcen im Blick, Auto-Update an.                                                      |
| `redis-exporter`          | Redis-Metriken        | `127.0.0.1:9121->9121`      | Auth via `REDIS_PASSWORD_FILE`                                      | Lokal.                                                                                    |
| `nvidia-exporter`         | GPU-Metriken          | `127.0.0.1:9445->9445`      | runtime nvidia                                                      | Kein Healthcheck; lokal.                                                                  |
| `blackbox-exporter`       | HTTP/TCP Checks       | `127.0.0.1:9115->9115`      | `./conf/blackbox-exporter/blackbox.yml`                             | Lokal.                                                                                    |
| `nginx-exporter`          | Nginx-Metriken        | `127.0.0.1:9113->9113`      | `--nginx.scrape-uri=http://nginx:80/nginx_status`                   | Lokal.                                                                                    |
| `ollama-exporter`         | Ollama-Metriken       | `127.0.0.1:9778->9778`      | Dockerfile `monitoring/Dockerfile.ollama-exporter`                  | Kein Healthcheck; lokal.                                                                  |
| `cadvisor`                | Container-Metriken    | `127.0.0.1:8081->8080`      | Mounts root FS                                                      | Lokal; Zugriff via Proxy.                                                                 |
| `fluent-bit`              | Log-Sammlung → Loki   | `127.0.0.1:2020/2021/24224` | `./conf/fluent-bit`, Volume `erni-ki-logs`                          | Zugriff nur lokal.                                                                        |
| `rag-exporter`            | SLA-Monitoring RAG    | `127.0.0.1:9808->9808`      | `RAG_TEST_URL`, hängt von `openwebui`                               | Lokal.                                                                                    |
| `webhook-receiver`        | Alertmanager Webhooks | `127.0.0.1:9095->9093`      | Skripte `./conf/webhook-receiver`, Logs `./data/webhook-logs`       | Limits `mem_limit=256M`, `mem_reservation=128M`, `cpus=0.25`, `oom_score_adj=250`; lokal. |

> Docling wieder im Haupt-Compose; Shared Volume `./data/docling/shared`
> gemeinsam mit OpenWebUI.
>
> Alle Monitoring-Services nur auf `127.0.0.1`; für Remote-Zugriff Nginx/VPN/SSH
> nutzen; innerhalb des Docker-Netzes unverändert.

## Ressourcen-Policy (Update 2025-11-12)

- Watchtower/webhook-receiver nutzen `mem_limit`, `mem_reservation`, `cpus`,
  `oom_score_adj`.
- LiteLLM, Ollama, OpenWebUI, Docling mit fixen Limits und negativen
  `oom_score_adj` (Ollama -900, OpenWebUI -600, Docling -500, LiteLLM -300).
- GPU-Zuweisung über `.env` (`*_GPU_VISIBLE_DEVICES`, `*_CUDA_VISIBLE_DEVICES`,
  `*_GPU_DEVICE_IDS`); MIG/Slices per .env konfigurierbar.

## Docling Shared Volume

- Struktur: `uploads/` (2 Tage), `processed/` (14), `exports/` (30),
  `quarantine/` (60), `tmp/` (1). Details:
  `operations/runbooks/docling-shared-volume.md`.
- Rechte: Besitzer = Host-User; Gruppe `docling-data` `rwx`; Auditoren via ACL
  `docling-readonly` (`rx` auf `exports/`).
- Cleanup/Quotas: `scripts/maintenance/docling-shared-cleanup.sh` (dry-run
  default, `--apply` entfernt), warnt bei `DOC_SHARED_MAX_SIZE_GB` (20 GB).
- Empfohlenes Cron: `10 2 * * * ... docling-shared-cleanup.sh --apply`.

## Digests für Images ohne Tags

- Fixe sha256 für SearXNG, EdgeTTS, Apache Tika; siehe aktuelle Digests (Stand
  2025-11-12) in RU-Version.
- Ablauf: Manifest prüfen → compose.yml Digest ersetzen → Pull & Restart →
  Healthcheck.

## Ops Notizen (Compose)

- `docker compose ps --status=running` / `--status=exited` für schnellen
  Zustand.
- `docker compose top` für Prozesse (LiteLLM/Ollama Debug).
- Watchtower optional; Stack startet ohne ihn.
- GPU-Zuweisung über `.env` (z. B. GPU0→Ollama, GPU1→OpenWebUI/Docling).
- Logs: kritische Services → Loki + json-file Tag `critical.*`; Zugriff über
  Grafana Explore.

## Observability & Security

- LiteLLM v1.80.0.rc.1, MCP Server 8000, RAG APIs nutzen PostgreSQL + Redis
  (Kontext). Routen/SLA in `reference/api-reference.md` und
  `operations/operations-handbook.md`.
- Docling/EdgeTTS intern; mehrsprachiger RAG-Pfad.
- Prometheus 3.0.1, 32 Targets, 27 Alerts (`conf/prometheus/alerts.yml`).
