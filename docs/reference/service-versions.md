---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-29'
---

# Service Versions Reference

> **Document Version:** 1.0 **Last Updated:** 2025-11-29 **Services:** 34 total
> **Source of Truth:**
> [compose.yml (GitHub)](https://github.com/DIZ-admin/erni-ki/blob/main/compose.yml)

This document is the single source of truth for all service versions in ERNI-KI.
It's automatically synchronized from `docker-compose.yml`.

## Core Services (9 total)

| Service          | Component                   | Version        | Image                                 | Port   | Status |
| ---------------- | --------------------------- | -------------- | ------------------------------------- | ------ | ------ |
| OpenWebUI        | Frontend/Chat UI            | 0.6.40         | ghcr.io/open-webui/open-webui:v0.6.40 | 8080   | Stable |
| Ollama           | LLM Inference Engine        | 0.6.2          | ollama:0.6.2                          | 11434  | Stable |
| LiteLLM          | Gateway/Context Engineering | 1.80.0-rc.1    | litellm:1.80.0-rc.1                   | 4000   | Beta   |
| PostgreSQL       | Database                    | 15.4           | postgres:15.4                         | 5432   | Stable |
| Redis            | Cache/Session Store         | 7.2.1          | redis:7.2.1-alpine                    | 6379   | Stable |
| Nginx            | Reverse Proxy               | 1.26.0         | nginx:1.26.0-alpine                   | 80,443 | Stable |
| Docling          | Document Processing         | latest         | ds4sd/docling:latest                  | 5001   | Stable |
| SearXNG          | Meta Search Engine          | 1.1.0          | searxng:1.1.0                         | 8888   | Stable |
| Webhook Receiver | Alert Processor             | 1.0.0 (custom) | erni-ki:webhook-receiver              | 5001   | Custom |

## Monitoring & Observability (8 total)

| Service       | Component                  | Version | Image                            | Port  | Status |
| ------------- | -------------------------- | ------- | -------------------------------- | ----- | ------ |
| Prometheus    | Metrics Collection         | 3.0.0   | prom/prometheus:v3.0.0           | 9090  | Stable |
| Grafana       | Dashboards & Visualization | 11.3.0  | grafana/grafana:11.3.0           | 3000  | Stable |
| Alertmanager  | Alert Management           | 0.27.0  | prom/alertmanager:v0.27.0        | 9093  | Stable |
| Loki          | Log Aggregation            | 3.0.0   | grafana/loki:3.0.0               | 3100  | Stable |
| Promtail      | Log Shipper                | 3.0.0   | grafana/promtail:3.0.0           | 9080  | Stable |
| Fluent Bit    | Log Processor              | 3.1.0   | fluent/fluent-bit:3.1.0          | 24224 | Stable |
| Node Exporter | Host Metrics               | 1.8.0   | prom/node-exporter:v1.8.0        | 9101  | Stable |
| cAdvisor      | Container Metrics          | 0.48.0  | gcr.io/cadvisor/cadvisor:v0.48.0 | 8080  | Stable |

## Exporters (8 total)

| Service           | Purpose          | Version        | Image                                         | Port | Status |
| ----------------- | ---------------- | -------------- | --------------------------------------------- | ---- | ------ |
| Postgres Exporter | Database Metrics | 0.15.0         | prometheuscommunity/postgres-exporter:v0.15.0 | 9187 | Stable |
| Redis Exporter    | Cache Metrics    | 1.58.0         | oliver006/redis_exporter:v1.58.0              | 9121 | Stable |
| Nginx Exporter    | Proxy Metrics    | 0.11.0         | nginx/nginx-prometheus-exporter:0.11.0        | 9113 | Stable |
| Blackbox Exporter | Endpoint Testing | 0.25.0         | prom/blackbox-exporter:v0.25.0                | 9115 | Stable |
| NVIDIA Exporter   | GPU Metrics      | 1.3.0          | nvcr.io/nvidia/k8s/dcgm-exporter:3.1.3        | 9445 | Beta   |
| Ollama Exporter   | Ollama Metrics   | 1.0.0 (custom) | erni-ki:ollama-exporter                       | 9778 | Custom |
| RAG Exporter      | RAG Health       | 1.0.0 (custom) | erni-ki:rag-exporter                          | 9808 | Custom |
| Backrest Exporter | Backup Metrics   | 0.1.0          | custom                                        | 9898 | Custom |

## Data Storage & Management (3 total)

| Service    | Purpose                 | Version             | Image              | Port | Status |
| ---------- | ----------------------- | ------------------- | ------------------ | ---- | ------ |
| PostgreSQL | Primary Database        | 15.4                | postgres:15.4      | 5432 | Stable |
| Redis      | Cache Store             | 7.2.1               | redis:7.2.1-alpine | 6379 | Stable |
| pgVector   | Vector Search Extension | 0.5.1 (in postgres) | Built-in           | -    | Stable |

## Utilities & Support (6 total)

| Service    | Purpose           | Version | Image                        | Port      | Status |
| ---------- | ----------------- | ------- | ---------------------------- | --------- | ------ |
| Backrest   | Backup Management | 0.81.0  | garethgeorge/backrest:0.81.0 | 9898      | Stable |
| dnsmasq    | DNS Resolution    | 2.89    | jpillora/dnsmasq:latest      | 53        | Stable |
| Watchtower | Auto-Update       | 1.7.1   | containrrr/watchtower:1.7.1  | -         | Stable |
| whoami     | Debugging         | latest  | traefik/whoami:latest        | 8000      | Stable |
| mailhog    | Email Testing     | latest  | mailhog/mailhog:latest       | 1025,8025 | Stable |
| Milvus     | Vector Database   | 2.3.0   | milvusdb/milvus:v2.3.0       | 19530     | Stable |

## Key Service Descriptions

### OpenWebUI

- **Version:** 0.6.40
- **Purpose:** Chat interface, model management, document upload
- **Key Features:** RAG integration, multi-user support, theme customization
- **Breaking Changes:** None since 0.6.36
- **Migration Path:** Automatic (backward compatible)
- **Documentation:** https://docs.openwebui.com

### Ollama

- **Version:** 0.6.2
- **Purpose:** Local LLM inference engine
- **Supported Models:** Llama, Mistral, Neural Chat, Phi, etc.
- **Hardware:** GPU-accelerated (NVIDIA CUDA 11.8+), CPU fallback
- **Key Features:** Model management, streaming responses, embeddings
- **Documentation:** https://github.com/ollama/ollama

### LiteLLM

- **Version:** 1.80.0-rc.1 (Beta)
- **Purpose:** Multi-provider LLM gateway with Context Engineering
- **Features:**
- OpenAI-compatible API
- Context7 thinking tokens
- Model Context Protocol integration
- Request/response transformation
- **Note:** Release Candidate - Test thoroughly in staging first
- **Documentation:** https://docs.litellm.ai

### PostgreSQL

- **Version:** 15.4
- **Extensions:** pgVector 0.5.1 (for vector search)
- **Configuration:**
- Max connections: 100
- Shared buffers: 256MB
- Work memory: 4MB
- **Backup:** Daily snapshots, 30-day retention
- **Documentation:** https://www.postgresql.org/docs/15/

### Redis

- **Version:** 7.2.1
- **Purpose:** Session storage, caching, rate limiting
- **Configuration:**
- Max memory: 512MB
- Eviction policy: allkeys-lru
- **Persistence:** RDB snapshots every 5 minutes
- **Documentation:** https://redis.io/docs

### Prometheus

- **Version:** 3.0.0
- **Purpose:** Metrics collection and time-series database
- **Scrape Interval:** 15 seconds
- **Retention:** 15 days
- **Targets:** 20+ services and exporters
- **Documentation:** https://prometheus.io/docs

### Grafana

- **Version:** 11.3.0
- **Purpose:** Visualization and dashboarding
- **Pre-configured Dashboards:** 5 (provisioned)

1.  System Overview
2.  Service Health
3.  GPU Monitoring
4.  Database Performance
5.  Alert Statistics

- **Data Sources:** Prometheus, Loki, PostgreSQL
- **Documentation:** https://grafana.com/docs

### Alertmanager

- **Version:** 0.27.0
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

- **Version:** 3.0.0
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

### LiteLLM 1.80.0-rc.1 (Beta)

**Breaking Changes:**

- Context Engineering API may change before release
- Not recommended for production until 1.80.0 stable
- Fallback to standard LLM endpoints works

**Testing Requirement:** Must validate in staging environment

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
| Stable     | 28    | OpenWebUI, Ollama, PostgreSQL, Redis, Prometheus, Grafana, etc. |
| Beta       | 2     | LiteLLM (1.80.0-rc.1), NVIDIA Exporter                          |
| Deprecated | 0     | None                                                            |
| Broken     | 0     | None                                                            |

## Version History

### Current Release: November 2025

```
OpenWebUI: 0.6.40
Ollama: 0.6.2
LiteLLM: 1.80.0-rc.1
Prometheus: 3.0.0
Grafana: 11.3.0
PostgreSQL: 15.4

```

### Previous Release: October 2025

```
OpenWebUI: 0.6.36
Ollama: 0.6.0
LiteLLM: 1.75.0
Prometheus: 2.50.0
Grafana: 11.0.0
PostgreSQL: 15.3

```

### Release Notes

- [October Release](https://github.com/erni-gruppe/erni-ki-1/releases/tag/v2.0.0-oct)
- [September Release](https://github.com/erni-gruppe/erni-ki-1/releases/tag/v1.9.0)
- [All Releases](https://github.com/erni-gruppe/erni-ki-1/releases)

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

1. Check GitHub Releases: https://github.com/erni-gruppe/erni-ki-1/releases
2. Review Changelog:
   [CHANGELOG.md](https://github.com/DIZ-admin/erni-ki/blob/develop/CHANGELOG.md)
3. Check Issues: https://github.com/erni-gruppe/erni-ki/issues
4. Contact: support@erni-gruppe.ch

---

**Last verified:** 2025-11-29 **Source:** docker-compose.yml (automatically
synchronized) **Update frequency:** On each release
