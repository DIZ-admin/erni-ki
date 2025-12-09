---
language: en
translation_status: complete
doc_version: '2025.12'
last_updated: '2025-12-09'
---

# Service Versions Reference

> **Document Version:** 2.0 **Last Updated:** 2025-12-09 **Services:** 30 total
> **Source of Truth:**
> [compose.yml (GitHub)](https://github.com/DIZ-admin/erni-ki/blob/main/compose.yml)

This document is the single source of truth for all service versions in ERNI-KI.
It's automatically synchronized from `compose.yml`.

## Core Services (11 total)

| Service          | Component                   | Version           | Image                                              | Port   | Status |
| ---------------- | --------------------------- | ----------------- | -------------------------------------------------- | ------ | ------ |
| OpenWebUI        | Frontend/Chat UI            | 0.6.40            | ghcr.io/open-webui/open-webui:v0.6.40              | 8080   | Stable |
| Ollama           | LLM Inference Engine        | 0.13.0            | ollama/ollama:0.13.0                               | 11434  | Stable |
| LiteLLM          | Gateway/Context Engineering | 1.80.0-stable.1   | ghcr.io/berriai/litellm:v1.80.0-stable.1           | 4000   | Stable |
| PostgreSQL       | Database + pgvector         | 17 (pgvector)     | pgvector/pgvector:pg17                             | 5432   | Stable |
| Redis            | Cache/Session Store         | 7.0.15            | redis:7.0.15-alpine                                | 6379   | Stable |
| Nginx            | Reverse Proxy               | 1.29.3            | nginx:1.29.3                                       | 80,443 | Stable |
| Docling          | Document Processing (GPU)   | cu126 (sha256)    | ghcr.io/docling-project/docling-serve-cu126        | 5001   | Stable |
| SearXNG          | Meta Search Engine          | 2025.11.21        | searxng/searxng:2025.11.21-b876d0bed               | 8888   | Stable |
| MCPO Server      | MCP Tools Server            | git-91e8f94       | ghcr.io/open-webui/mcpo:git-91e8f94                | 8000   | Stable |
| Cloudflared      | Cloudflare Tunnel           | 2025.11.1         | cloudflare/cloudflared:2025.11.1                   | -      | Stable |
| EdgeTTS          | Text-to-Speech              | sha256 (pinned)   | travisvn/openai-edge-tts@sha256:4e7e2773...        | 5050   | Stable |

## Monitoring & Observability (8 total)

| Service       | Component                  | Version | Image                            | Port  | Status |
| ------------- | -------------------------- | ------- | -------------------------------- | ----- | ------ |
| Prometheus    | Metrics Collection         | 3.7.3   | prom/prometheus:v3.7.3           | 9090  | Stable |
| Grafana       | Dashboards & Visualization | 12.3.0  | grafana/grafana:12.3.0           | 3000  | Stable |
| Alertmanager  | Alert Management           | 0.29.0  | prom/alertmanager:v0.29.0        | 9093  | Stable |
| Loki          | Log Aggregation            | 3.6.2   | grafana/loki:3.6.2               | 3100  | Stable |
| Promtail      | Log Shipper                | 3.0.0   | grafana/promtail:3.0.0           | 9080  | Stable |
| Fluent Bit    | Log Processor              | 4.2.0   | fluent/fluent-bit:4.2.0          | 24224 | Stable |
| Node Exporter | Host Metrics               | 1.10.2  | prom/node-exporter:v1.10.2       | 9101  | Stable |
| cAdvisor      | Container Metrics          | 0.52.1  | gcr.io/cadvisor/cadvisor:v0.52.1 | 8080  | Stable |

## Exporters (7 total)

| Service           | Purpose          | Version        | Image                                          | Port | Status |
| ----------------- | ---------------- | -------------- | ---------------------------------------------- | ---- | ------ |
| Postgres Exporter | Database Metrics | 0.18.1         | prometheuscommunity/postgres-exporter:v0.18.1  | 9187 | Stable |
| Redis Exporter    | Cache Metrics    | 1.80.1         | oliver006/redis_exporter:v1.80.1               | 9121 | Stable |
| Nginx Exporter    | Proxy Metrics    | 1.5.1          | nginx/nginx-prometheus-exporter:1.5.1          | 9113 | Stable |
| Blackbox Exporter | Endpoint Testing | 0.27.0         | prom/blackbox-exporter:v0.27.0                 | 9115 | Stable |
| NVIDIA Exporter   | GPU Metrics      | 0.1            | mindprince/nvidia_gpu_prometheus_exporter:0.1  | 9445 | Stable |
| Ollama Exporter   | Ollama Metrics   | 1.0.0 (custom) | erni-ki:ollama-exporter                        | 9778 | Custom |
| RAG Exporter      | RAG Health       | 1.0.0 (custom) | erni-ki:rag-exporter                           | 9808 | Custom |

## Data Storage & Management (2 total)

| Service    | Purpose          | Version         | Image                  | Port | Status |
| ---------- | ---------------- | --------------- | ---------------------- | ---- | ------ |
| PostgreSQL | Primary Database | 17 + pgvector   | pgvector/pgvector:pg17 | 5432 | Stable |
| Redis      | Cache Store      | 7.0.15          | redis:7.0.15-alpine    | 6379 | Stable |

## Utilities & Support (4 total)

| Service     | Purpose           | Version | Image                         | Port | Status |
| ----------- | ----------------- | ------- | ----------------------------- | ---- | ------ |
| Backrest    | Backup Management | 1.10.1  | garethgeorge/backrest:v1.10.1 | 9898 | Stable |
| Watchtower  | Auto-Update       | 1.7.1   | containrrr/watchtower:1.7.1   | -    | Stable |
| Uptime Kuma | Uptime Monitoring | 2.0.2   | louislam/uptime-kuma:2.0.2    | 3001 | Stable |
| Tika        | Content Extraction| 3.2.3.0 | apache/tika:3.2.3.0-full      | 9998 | Stable |

## Key Service Descriptions

### OpenWebUI

- **Version:** 0.6.40
- **Purpose:** Chat interface, model management, document upload
- **Key Features:** RAG integration, multi-user support, theme customization
- **Breaking Changes:** None since 0.6.36
- **Migration Path:** Automatic (backward compatible)
- **Documentation:** https://docs.openwebui.com

### Ollama

- **Version:** 0.13.0
- **Purpose:** Local LLM inference engine
- **Supported Models:** Llama 3.x, Mistral, Qwen, Phi, DeepSeek, etc.
- **Hardware:** GPU-accelerated (NVIDIA CUDA 12.0+), Vulkan support, CPU fallback
- **Key Features:** Model management, streaming responses, embeddings, vision models
- **Documentation:** https://github.com/ollama/ollama

### LiteLLM

- **Version:** 1.80.0-stable.1
- **Purpose:** Multi-provider LLM gateway with Context Engineering
- **Features:**
  - OpenAI-compatible API
  - Context7 thinking tokens
  - Model Context Protocol integration
  - Request/response transformation
- **Status:** Stable release
- **Documentation:** https://docs.litellm.ai

### PostgreSQL

- **Version:** 17 with pgvector
- **Image:** pgvector/pgvector:pg17
- **Extensions:** pgVector (built-in for vector search)
- **Configuration:**
  - Max connections: 100
  - Shared buffers: 256MB
  - Work memory: 4MB
- **Backup:** Daily snapshots, 30-day retention
- **Documentation:** https://www.postgresql.org/docs/17/

### Redis

- **Version:** 7.0.15
- **Purpose:** Session storage, caching, rate limiting
- **Note:** Pinned to 7.0.x due to RDB format v12 incompatibility in 7.2+
- **Configuration:**
  - Max memory: 512MB
  - Eviction policy: allkeys-lru
- **Persistence:** RDB snapshots every 5 minutes
- **Documentation:** https://redis.io/docs

### Prometheus

- **Version:** 3.7.3
- **Purpose:** Metrics collection and time-series database
- **Scrape Interval:** 15 seconds
- **Retention:** 15 days
- **Targets:** 20+ services and exporters
- **Documentation:** https://prometheus.io/docs

### Grafana

- **Version:** 12.3.0
- **Purpose:** Visualization and dashboarding
- **Pre-configured Dashboards:** 18 (provisioned)

1. System Overview
2. Service Health
3. GPU Monitoring
4. Database Performance
5. Alert Statistics

- **Data Sources:** Prometheus, Loki, PostgreSQL
- **Documentation:** https://grafana.com/docs

### Alertmanager

- **Version:** 0.29.0
- **Purpose:** Alert deduplication, grouping, routing
- **Notification Channels:**
  - Discord (configured)
  - Slack (configurable)
  - Telegram (configurable)
  - Webhook (HMAC-secured)
- **Group Interval:** 10 seconds
- **Repeat Interval:** 12 hours
- **Documentation:** https://prometheus.io/docs/alerting/latest/alertmanager/

### Loki

- **Version:** 3.6.2
- **Purpose:** Log aggregation and analysis
- **Retention:** 30 days
- **Scrape Interval:** 15 seconds
- **Integration:** Promtail, Fluent Bit
- **Documentation:** https://grafana.com/docs/loki/latest/

## Version Compatibility Matrix

| Component      | Min Version | Current | Max Version | Notes                      |
| -------------- | ----------- | ------- | ----------- | -------------------------- |
| Docker         | 20.10+      | 25.0+   | Latest      | Docker Compose v2 required |
| Docker Compose | 2.0+        | 2.20+   | Latest      | YAML 3.8+ syntax required  |
| Python         | 3.9+        | 3.11    | 3.12        | Type hints require 3.9+    |
| Node.js        | 16.13+      | 18.17+  | 22          | ESM modules supported      |
| CUDA           | 11.8+       | 12.0+   | Latest      | GPU acceleration           |

## Breaking Changes

### Version 0.6.40 (Current)

**From 0.6.36:**

- No breaking changes
- Backward compatible
- Auto-migration of data

**New Features:**

- Improved RAG integration
- Enhanced vector search
- Better error handling

### LiteLLM 1.80.0-stable.1

**Status:** Stable release

- Context Engineering API is now stable
- Production ready
- Full backward compatibility with standard LLM endpoints

## Upgrade Path

### Minor Updates (Same Major Version)

Example: 0.6.40 → 0.6.41

1. Update image tag in docker-compose.yml
2. Run `docker-compose pull`
3. Run `docker-compose up -d`
4. Verify services healthy
5. Expected downtime: <30 seconds

### Major Updates (Different Major Version)

Example: 0.6.40 → 1.0.0

1. **Test in staging first**
2. Review breaking changes
3. Plan migration path
4. Create full backup: `docker-compose exec db pg_dump > backup.sql`
5. Coordinate deployment window
6. Expected downtime: 5-10 minutes

## Patch Management

### Security Patches

Apply immediately:

- Python library vulnerabilities (pip audit)
- System vulnerabilities (Ubuntu security updates)
- Cryptographic algorithm changes

Command:

```bash
docker-compose build --no-cache
docker-compose up -d

```

### Regular Updates (Quarterly)

Review and plan quarterly:

- `npm outdated` - Check JavaScript package updates
- `pip list --outdated` - Check Python package updates
- `docker images` - Check service image updates

Process:

1. Test in staging
2. Coordinate with team
3. Deploy in maintenance window

## Service Status

### Status Definitions

- **Stable:** Production-ready, minimal issues
- **Beta:** Functional but may have issues, test thoroughly
- **Deprecated:** No longer supported, plan migration
- **Broken:** Not working, requires attention

### Current Status Summary

| Status     | Count | Services                                                        |
| ---------- | ----- | --------------------------------------------------------------- |
| Stable     | 30    | OpenWebUI, Ollama, LiteLLM, PostgreSQL, Redis, Prometheus, etc. |
| Beta       | 0     | None                                                            |
| Deprecated | 0     | None                                                            |
| Broken     | 0     | None                                                            |

## Version History

### Current Release: December 2025

```
OpenWebUI: 0.6.40
Ollama: 0.13.0
LiteLLM: 1.80.0-stable.1
Prometheus: 3.7.3
Grafana: 12.3.0
PostgreSQL: 17 (pgvector)
Nginx: 1.29.3
Loki: 3.6.2
Fluent Bit: 4.2.0
```

### Previous Release: November 2025

```
OpenWebUI: 0.6.40
Ollama: 0.6.2
LiteLLM: 1.80.0-rc.1
Prometheus: 3.0.0
Grafana: 11.3.0
PostgreSQL: 15.4
```

### Release Notes

- [October Release](https://github.com/DIZ-admin/erni-ki/releases)
- [September Release](https://github.com/DIZ-admin/erni-ki/releases)
- [All Releases](https://github.com/DIZ-admin/erni-ki/releases)

## Service Health Checks

### Health Endpoint URLs

```bash
# OpenWebUI
curl http://localhost:8080/health

# Ollama
curl http://localhost:11434/api/tags

# Prometheus
curl http://localhost:9090/-/ready

# Grafana
curl http://localhost:3000/api/health

# Alertmanager
curl http://localhost:9093/-/healthy

# PostgreSQL
docker-compose exec db psql -U openwebui_user -d openwebui -c "SELECT 1;"

# Redis
docker-compose exec redis redis-cli PING

# LiteLLM
curl http://localhost:4000/health

# Webhook Receiver
curl http://localhost:5001/health

```

## Maintenance Schedule

| Task                   | Frequency | Responsible |
| ---------------------- | --------- | ----------- |
| Security patch review  | Weekly    | DevSecOps   |
| Dependency updates     | Monthly   | Engineering |
| Major version upgrades | Quarterly | Tech Lead   |
| Database maintenance   | Monthly   | DBA         |
| Backup verification    | Weekly    | Operations  |

## Getting Latest Versions

### Check Image Registry

```bash
# OpenWebUI
docker pull ghcr.io/open-webui/open-webui:latest
docker inspect ghcr.io/open-webui/open-webui:latest | grep RepoTags

# Ollama
docker pull ollama:latest
docker inspect ollama:latest | grep RepoTags

# Official Registries
# - GitHub Container Registry (ghcr.io)
# - Docker Hub (docker.io)
# - NVIDIA Registry (nvcr.io)

```

## Related Documentation

- [Deployment Guide](../deployment/production-checklist.md)
- See [Upgrade Guide](../operations/maintenance/image-upgrade-checklist.md) for
  upgrade instructions.
- See
  [Changelog](https://github.com/DIZ-admin/erni-ki/blob/develop/CHANGELOG.md)
  for version history.
- [API Reference](./api-reference.md)
- [Webhook API](./webhook-api.md)

## Support & Questions

For version-related questions:

1. Check GitHub Releases: https://github.com/DIZ-admin/erni-ki/releases
2. Review Changelog:
   [CHANGELOG.md](https://github.com/DIZ-admin/erni-ki/blob/develop/CHANGELOG.md)
3. Check Issues: https://github.com/DIZ-admin/erni-ki/issues
4. Contact: support@erni-gruppe.ch

---

**Last verified:** 2025-12-09 **Source:** compose.yml (automatically
synchronized) **Update frequency:** On each release
