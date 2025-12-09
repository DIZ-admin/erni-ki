---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'ERNI-KI Service Inventory'
---

# ERNI-KI Service Inventory

This document aggregates information from `compose.yml` and `env/*.env` about
each service, so engineers can quickly understand container purposes, entry
points, dependencies, and security requirements. For image updates, use the
[checklist](../operations/maintenance/image-upgrade-checklist.md).

## Base Infrastructure and Storage

| Service      | Purpose                                     | Ports                                             | Dependencies and Configuration                                                                 | Updates and Notes                                                                                                                                 |
| ------------ | ------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `watchtower` | Auto-update containers, cleanup old images. | `127.0.0.1:8091->8080` (HTTP API localhost only). | `env/watchtower.env`, mounts `/var/run/docker.sock`, secret `watchtower_api_token`.            | API requires token from Docker secret, port bound to localhost; limits `mem_limit=256M`, `mem_reservation=128M`, `cpus=0.2`, `oom_score_adj=500`. |
| `db`         | PostgreSQL 17 + pgvector, main storage.     | Internal network only.                            | `env/db.env`, secret `postgres_password`, custom `postgresql.conf`, data in `./data/postgres`. | Auto-update disabled; healthcheck `pg_isready`.                                                                                                   |
| `redis`      | Cache, queues and rate limiting.            | Internal network only.                            | `env/redis.env`, config `./conf/redis/redis.conf`, data `./data/redis`.                        | Watchtower allowed (`cache-services`); pinned `redis:7.0.15-alpine` due to RDB v12 incompatibility.                                               |
| `backrest`   | Backup data/configs.                        | `9898:9898`.                                      | `env/backrest.env`, multiple volumes, Docker socket access.                                    | Auto-update enabled; requires permission control on backup directories.                                                                           |

## Access and Edge Services

| Service       | Purpose                                                                                                                                      | Ports                        | Dependencies and Configuration                                                                                                                                                                                                                                                       | Updates and Notes                                                                                                                                                     |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nginx`       | Reverse proxy, TLS termination.                                                                                                              | `80`, `443`, `8080`.         | Configs from `./conf/nginx`, SSL in `./conf/nginx/ssl`.                                                                                                                                                                                                                              | Watchtower disabled (critical proxy); healthcheck `/etc/nginx/healthcheck.sh`.                                                                                        |
| `cloudflared` | Expose Nginx externally via Cloudflare Tunnel.                                                                                               | No external ports.           | `env/cloudflared.env`, config `./conf/cloudflare/config`.                                                                                                                                                                                                                            | Watchtower enabled; requires valid Cloudflare token.                                                                                                                  |
| `auth`        | JWT authentication service for internal APIs.                                                                                                | `9092:9090`.                 | `env/auth.env`, image built from `./auth`.                                                                                                                                                                                                                                           | Auto-update allowed (`auth-services`).                                                                                                                                |
| `mcposerver`  | MCP server for OpenWebUI (git-91e8f94). 7 tools: Time, Context7 Docs, PostgreSQL, Filesystem, Memory, SearXNG Web Search, Desktop Commander. | `127.0.0.1:8000->8000`.      | `env/mcposerver.env`, config `./conf/mcposerver`, data `./data`, Desktop Commander HOME `./data/desktop-commander`, working FS for MCP `/app/data/mcpo-desktop`.                                                                                                                     | Auto-update enabled; depends on `db`. Binding localhost only; Desktop Commander restricted to directories (`allowedDirectories`) with telemetry disabled.             |
| `searxng`     | Metasearch, web results source.                                                                                                              | No public port (internal).   | `env/searxng.env`, configs `./conf/searxng/*.yml`.                                                                                                                                                                                                                                   | Watchtower enabled; image pinned to digest `searxng/searxng@sha256:aaa855e8...` (linux/amd64).                                                                        |
| `edgetts`     | Speech synthesis (Edge TTS).                                                                                                                 | `5050:5050`.                 | `env/edgetts.env`. Healthcheck via Python socket.                                                                                                                                                                                                                                    | Watchtower enabled; uses digest `travisvn/openai-edge-tts@sha256:4e7e2773...` (schema2 compatible).                                                                   |
| `tika`        | Extract content/metadata from files.                                                                                                         | `9998:9998`.                 | `env/tika.env`.                                                                                                                                                                                                                                                                      | Watchtower enabled; image pinned to `apache/tika@sha256:3fafa194...` (linux/amd64).                                                                                   |
| `litellm`     | LiteLLM proxy with thinking tokens.                                                                                                          | `4000:4000`.                 | `env/litellm.env`, `./conf/litellm/config.yaml`, data `./data/litellm`, entrypoint `scripts/entrypoints/litellm.sh`, secrets `litellm_db_password`, `litellm_master_key`, `litellm_salt_key`, `litellm_ui_password`, `litellm_api_key`, `openai_api_key`. Depends on `db`, `ollama`. | Auto-update enabled (`ai-services`); limits `mem_limit=12G`, `mem_reservation=6G`, `cpus=1.0`, `oom_score_adj=-300` protect from OOM.                                 |
| `ollama`      | GPU LLM server, stores models in `./data/ollama`.                                                                                            | `11434:11434`.               | `env/ollama.env`, GPU defined via `.env` (`OLLAMA_GPU_VISIBLE_DEVICES`, `OLLAMA_GPU_DEVICE_IDS`).                                                                                                                                                                                    | Watchtower disabled; `mem_limit=16G`, `mem_reservation=8G`, `cpus=12`, `oom_score_adj=-900`; GPU assigned via `.env`.                                                 |
| `openwebui`   | Main UI (Next.js) with GPU support.                                                                                                          | Via Nginx (`8080` internal). | `env/openwebui.env`, shared data `./data/openwebui`, `./data/docling/shared`, entrypoint `scripts/entrypoints/openwebui.sh`, secrets `postgres_password`, `litellm_api_key`, `openwebui_secret_key`, GPU via `.env` (`OPENWEBUI_GPU_*`).                                             | Watchtower enabled; limits `mem_limit=8G`, `mem_reservation=4G`, `cpus=4`, `oom_score_adj=-600`, shared volume synchronized with Docling.                             |
| `docling`     | OCR/Doc ingestion pipeline (Docling Serve).                                                                                                  | Internal network (`5001`).   | `env/docling.env`, images `./data/docling/*`, artifacts `./data/docling/docling-models` (mounted as `/docling-artifacts` and as Docling cache), shared volume `./data/docling/shared`, GPU via `.env` (`DOCLING_GPU_*`).                                                             | Auto-update enabled (`document-processing`); limits `mem_limit=12G`, `mem_reservation=8G`, `cpus=8`, `oom_score_adj=-500`, shared volume synchronized with OpenWebUI. |

## Monitoring and Logging

| Service                   | Purpose                                                | Ports                                    | Dependencies and Configuration                                                              | Updates and Notes                                                                                                       |
| ------------------------- | ------------------------------------------------------ | ---------------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `prometheus`              | Metrics collection.                                    | `127.0.0.1:9091->9090`.                  | Configs in `./conf/prometheus`, data `./data/prometheus`.                                   | Accessible locally only; external access via Nginx/SSH tunnel.                                                          |
| `grafana`                 | Dashboards and alerts.                                 | `127.0.0.1:3000->3000`.                  | Data `./data/grafana`, provisioning `./conf/grafana`, secret `grafana_admin_password`.      | Port accessible locally only; admin password from Docker secret, external access via Nginx/VPN.                         |
| `loki`                    | Log storage (header `X-Scope-OrgID: erni-ki`).         | `127.0.0.1:3100->3100`.                  | Config `./conf/loki/loki-config.yaml`, data `./data/loki`.                                  | Watchtower enabled; port now accessible locally only.                                                                   |
| `alertmanager`            | Prometheus alert management.                           | `127.0.0.1:9093/9094`.                   | Config `./conf/alertmanager`, data `./data/alertmanager`.                                   | Now localhost only; proxy via Nginx if needed.                                                                          |
| `node-exporter`           | Node metrics.                                          | `127.0.0.1:9101->9100`.                  | Mounts `/proc`, `/sys`, `/rootfs`, `pid: host`.                                             | Listens localhost only, external leaks excluded.                                                                        |
| `postgres-exporter`       | PostgreSQL metrics.                                    | `127.0.0.1:9188->9188`.                  | DSN read from Docker secret `postgres_exporter_dsn` (shell wrapper), depends on `db`.       | Local access; external connection via tunnel.                                                                           |
| `postgres-exporter-proxy` | Socat proxy IPv4→IPv6.                                 | Shares network with `postgres-exporter`. | No env/volumes, runs on `alpine/socat@sha256:86b69d2e...`.                                  | Monitor resources, auto-update allowed.                                                                                 |
| `redis-exporter`          | Redis metrics.                                         | `127.0.0.1:9121->9121`.                  | Authorization via `REDIS_PASSWORD_FILE` (`redis_exporter_url` contains JSON host→password). | Now visible only from localhost.                                                                                        |
| `nvidia-exporter`         | GPU metrics.                                           | `127.0.0.1:9445->9445`.                  | Requires GPU (`runtime: nvidia`).                                                           | No healthcheck, but port is local.                                                                                      |
| `blackbox-exporter`       | HTTP/TCP availability checks.                          | `127.0.0.1:9115->9115`.                  | Config `./conf/blackbox-exporter/blackbox.yml`.                                             | Use Nginx/SSH for remote access.                                                                                        |
| `nginx-exporter`          | Nginx metrics.                                         | `127.0.0.1:9113->9113`.                  | Command `--nginx.scrape-uri=http://nginx:80/nginx_status`.                                  | Port accessible locally only.                                                                                           |
| `ollama-exporter`         | Ollama metrics.                                        | `127.0.0.1:9778->9778`.                  | Dockerfile in `./monitoring/Dockerfile.ollama-exporter`.                                    | No healthcheck; port not published externally.                                                                          |
| `cadvisor`                | Container metrics.                                     | `127.0.0.1:8081->8080`.                  | Mounts root FS.                                                                             | Port limited to localhost; external access via proxy.                                                                   |
| `fluent-bit`              | Centralized log collection → Loki.                     | `127.0.0.1:2020/2021/24224`.             | Configs `./conf/fluent-bit`, volume `erni-ki-logs`.                                         | Access to HTTP/metrics/forward via localhost only.                                                                      |
| `rag-exporter`            | RAG SLA monitoring.                                    | `127.0.0.1:9808->9808`.                  | Variables `RAG_TEST_URL`, depends on `openwebui`.                                           | Endpoint visible locally only.                                                                                          |
| `webhook-receiver`        | Receive Alertmanager notifications and custom scripts. | `127.0.0.1:9095->9093`.                  | Scripts `./conf/webhook-receiver`, logs `./data/webhook-logs`.                              | Endpoint accessible via local proxy; limits `mem_limit=256M`, `mem_reservation=128M`, `cpus=0.25`, `oom_score_adj=250`. |

> **Note:** Docling restored in main `compose.yml`; shared volume
> `./data/docling/shared` used jointly with OpenWebUI.
>
> **Metrics Access:** all monitoring services bound to `127.0.0.1` only. For
> remote viewing use Nginx (with auth/TLS), VPN or SSH tunnel; inside docker
> network services continue to work unchanged.

## Resource Limits Policy (updated 2025-11-12)

- Watchtower and webhook-receiver now use native fields `mem_limit`,
  `mem_reservation`, `cpus` and `oom_score_adj`, so limits work in
  `docker compose` without Swarm.
- LiteLLM, Ollama, OpenWebUI and Docling fix memory/CPU limits and negative
  `oom_score_adj`, which reduces the probability of killing critical processes
  (Ollama: -900, OpenWebUI: -600, Docling: -500, LiteLLM: -300).
- GPU binding is done via `.env` variables (`*_GPU_VISIBLE_DEVICES`,
  `*_CUDA_VISIBLE_DEVICES`, `*_GPU_DEVICE_IDS`) and `nvidia-container-runtime`;
  to separate services across different devices or MIG slices, just update
  `.env` and restart services.

## Docling Shared Volume Policy

- Volume structure: `uploads/` (raw, 2 days), `processed/` (intermediate
  artifacts, 14 days), `exports/` (results, 30 days), `quarantine/` (incidents,
  60 days), `tmp/` (1 day). Details —
  `docs/operations/runbooks/docling-shared-volume.md`.
- Access rights: owner — docker host user; group `docling-data` has `rwx`;
  auditors added via ACL `docling-readonly` with `rx` on `exports/`.
- Cleanup and quotas: `scripts/maintenance/docling-shared-cleanup.sh` (dry-run
  by default, `--apply` to delete). Script warns when exceeding
  `DOC_SHARED_MAX_SIZE_GB` (20 GB).
- Recommended cron:
  `10 2 * * * cd /home/konstantin/Documents/augment-projects/erni-ki && ./scripts/maintenance/docling-shared-cleanup.sh --apply >> logs/docling-shared-cleanup.log 2>&1`.

## Updating Digest for Images Without Version Tags

Some services (SearXNG, EdgeTTS, Apache Tika) only publish `latest`, so we pin
sha256-digest to prevent Watchtower from pulling unexpected releases.

1. Get fresh digest for amd64:

   ```bash
   docker manifest inspect <image>:latest | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest' | head -n1
   # EdgeTTS uses single-arch image → can use .config.digest
   ```

2. Update `compose.yml`, replacing line like `image: <img>@sha256:...`.
3. Record new digest in table above and in Archon document (section
   «recent_updates»).
4. After push execute
   `docker compose pull <service> && docker compose up -d <service>` and monitor
   healthchecks.

Current digests as of 2025-11-12:

- `travisvn/openai-edge-tts@sha256:4e7e2773350a3296f301b5f66e361daad243bdc4b799eec32613fddcee849040`
- `apache/tika@sha256:3fafa194474c5f3a8cff25a0eefd07e7c0513b7f552074ad455e1af58a06bbea`
- `searxng/searxng@sha256:aaa855e878bd4f6e61c7c471f03f0c9dd42d223914729382b34b875c57339b98`

## Operational Notes (from Context7 /docker/compose)

- For quick container status diagnostics use
  `docker compose ps --status=running` or `--filter status=running`, and for
  exited services — `--status=exited`. This is more convenient than viewing the
  full long stack list.
- `docker compose top` shows processes inside services with PID/UID — useful
  when debugging LiteLLM/Ollama hangs without entering container.
- It's recommended to regularly run linters/tests for Compose project (see
  official recommendations `golint`, `go test`), if stack management tools
  change.
- Watchtower is now optional: all services start without `depends_on` on it, so
  when Watchtower fails the rest of infrastructure starts autonomously.
- GPU for Ollama/OpenWebUI/Docling assigned via `.env` (`OLLAMA_GPU_*`,
  `OPENWEBUI_GPU_*`, `DOCLING_GPU_*`). Recommended template in `.env.example`:
  GPU0 → Ollama, GPU1 → OpenWebUI/Docling. For single-GPU systems specify same
  values or use MIG slices.
- Kibana/Elasticsearch excluded; for log viewing use Grafana → Explore (Loki),
  and for storage maintenance —
  `scripts/maintenance/docling-shared-cleanup.sh` + Fluent Bit ↔ Loki pipeline.

## Observability and Security

- **LLM & Model Context**: LiteLLM v1.80.0.rc.1, MCP Server 8000 and RAG API
  (`/api/mcp/*`, `/api/search`) use PostgreSQL + Redis for context storage;
  `docs/reference/api-reference.md` and `docs/operations/operations-handbook.md`
  contain routes, SLA and tool list.
- **Docling/EdgeTTS**: operate via internal ports, use CPU, provide multilingual
  RAG pipeline and serve as source for `docs/operations/monitoring-guide.md`.
- Logs sent to Fluent Bit (24224 forward, 2020 HTTP) and forwarded to Loki, and
  critical services (OpenWebUI, Ollama, PostgreSQL, Nginx) also write to
  `json-file` with tag `critical.*` per `compose.yml` configuration.
- Prometheus 3.0.1 polls 32 targets and contains 27 active rules in
  `conf/prometheus/alerts.yml` (Critical, Performance, Database, GPU, Nginx).
  Alertmanager v0.28.0 sends alerts via predefined channel (Slack/Teams via
  Watchtower metrics API).
- Grafana v11.6.6 contains 18 dashboards, including GPU/LLM, PostgreSQL, Redis,
  Docker host. Each dashboard update recorded in
  `docs/operations/grafana-dashboards-guide.md`.
- Security based on Nginx WAF, Cloudflare Zero Trust (5 tunnels), JWT Go service
  and secrets in `secrets/`. Details see `security/security-policy.md`.

## Sources and References

- Docker Compose: `compose.yml` (logging tiers, healthchecks, restart policies,
  GPU labels).
- Configurations: `env/*.env`, `conf/nginx`, `conf/redis/redis.conf`,
  `conf/litellm`, `conf/prometheus`.
- Monitoring and runbooks: `docs/operations/monitoring-guide.md`,
  `docs/operations/automated-maintenance-guide.md`, `docs/operations/runbooks/`.
- Architecture: `docs/architecture/architecture.md` (GPU allocation, Cloudflare
  tunnels, 30 services).
- Security: `security/security-policy.md`,
  `docs/archive/reports/documentation-audit-2025-10-24.md` (risks indicated and
  required updates).
