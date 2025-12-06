# ERNI-KI Modular Docker Compose

This directory contains the modularized Docker Compose configuration for
ERNI-KI, split into logical layers for better maintainability and flexibility.

## Architecture

The original monolithic `compose.yml` (1519 lines) has been refactored into 5
modular files organized by layer:

```
compose/
 base.yml - Networks, logging anchors, infrastructure (watchtower)
 data.yml - Data layer (PostgreSQL, Redis)
 ai.yml - AI services (Ollama, LiteLLM, OpenWebUI, Docling, Auth, etc.)
 gateway.yml - Gateway layer (Nginx, Cloudflared, Backrest)
 monitoring.yml - Observability (Prometheus, Grafana, Loki, Alertmanager, exporters)
 README.md - This file
```

## Dependency Order

The files must be loaded in this specific order to respect service dependencies:

1. **base.yml** - Provides networks and infrastructure
2. **data.yml** - Database and cache (required by ai.yml services)
3. **ai.yml** - AI services (depend on data layer)
4. **gateway.yml** - Reverse proxy and tunnels (depend on ai.yml services)
5. **monitoring.yml** - Observability stack (monitors all other layers)

## Usage

Use the provided wrapper script `docker-compose.sh` in the project root:

```bash
# Start all services
./docker-compose.sh up -d

# Stop all services
./docker-compose.sh down

# View service status
./docker-compose.sh ps

# View logs
./docker-compose.sh logs -f nginx

# Restart a specific service
./docker-compose.sh restart openwebui

# Execute command in container
./docker-compose.sh exec db psql -U postgres
```

## Manual Execution

If you prefer to use `docker compose` directly:

```bash
docker compose \
 -f compose/base.yml \
 -f compose/data.yml \
 -f compose/ai.yml \
 -f compose/gateway.yml \
 -f compose/monitoring.yml \
 up -d
```

## Starting Subsets

You can start specific layers only by including their dependencies:

```bash
# Only data layer (base + data)
docker compose -f compose/base.yml -f compose/data.yml up -d

# AI services without gateway (base + data + ai)
docker compose -f compose/base.yml -f compose/data.yml -f compose/ai.yml up -d
```

## Services by Layer

### Base Layer (base.yml)

- **watchtower** - Container update monitoring

### Data Layer (data.yml)

- **db** - PostgreSQL 17 + pgvector extension
- **redis** - Redis 7.0.15 with ACL support

### AI Layer (ai.yml)

- **ollama** - Local LLM engine (GPU-enabled)
- **litellm** - AI router/gateway
- **openwebui** - Main chat UI (GPU-enabled)
- **docling** - Document processing (GPU-enabled)
- **auth** - JWT authentication service
- **searxng** - Privacy-focused metasearch
- **edgetts** - Text-to-speech service
- **tika** - Apache Tika document extraction
- **mcposerver** - Model Context Protocol server

### Gateway Layer (gateway.yml)

- **nginx** - Reverse proxy and load balancer
- **cloudflared** - Cloudflare tunnel for secure external access
- **backrest** - Backup management with Restic

### Monitoring Layer (monitoring.yml)

- **prometheus** - Metrics collection and storage
- **grafana** - Visualization and dashboards
- **loki** - Log aggregation
- **alertmanager** - Alert routing and management
- **uptime-kuma** - Uptime monitoring
- **node-exporter** - System metrics exporter
- **postgres-exporter** - PostgreSQL metrics exporter

## Networks

Four isolated Docker networks for security and organization:

- **frontend** - Public-facing services (Nginx, Cloudflared)
- **backend** - Application logic (OpenWebUI, APIs)
- **data** - Stateful services (DB, Redis) - **Internal only**
- **monitoring** - Observability stack

## Logging Strategy

4-tier logging configuration:

- **critical-logging** - Critical services (DB, Nginx) - 50MB x 10 files
- **important-logging** - Important services (Redis, LiteLLM) - 10MB x 5 files
- **auxiliary-logging** - Support services (Searxng, TTS) - 10MB x 5 files
- **monitoring-logging** - Observability stack - 10MB x 5 files

## Secrets

All secrets are file-based and located in `./secrets/`:

- Database credentials
- API keys
- TLS certificates
- Service passwords
- Webhook URLs

See individual compose files for the complete secrets list.

## Configuration Files

Service configurations are organized in `./conf/` by service:

```
conf/
 nginx/
 postgres-enhanced/
 redis/
 prometheus/
 grafana/
 loki/
 alertmanager/
 ...
```

## YAML Anchor Compatibility

**Note:** YAML anchors (e.g., `*critical-logging`) don't work across multiple
compose files. Each modular file duplicates the necessary logging anchors to
maintain compatibility.

## Benefits of Modular Architecture

1. **Maintainability** - Each layer is self-contained and easier to understand
2. **Flexibility** - Start only the services you need
3. **Clarity** - Clear separation of concerns by layer
4. **Development** - Faster iteration when working on specific layers
5. **Resource Management** - Run minimal stacks in development environments

## Migration from Monolithic compose.yml

The original `compose.yml` remains available for reference. To migrate:

1. Use `./docker-compose.sh` for all operations
2. Or update your scripts to use the multi-file command shown above
3. All environment variables, volumes, and secrets remain unchanged

## Validation

To validate the merged configuration:

```bash
./docker-compose.sh config --quiet
```

To see the full merged configuration:

```bash
./docker-compose.sh config > merged-compose.yml
```

## Additional Services

Some optional exporters from the original configuration are not included in the
modular files. To add them, copy their configuration from the original
`compose.yml`:

- postgres-exporter-proxy (HAProxy for Postgres exporter)
- nvidia-exporter (GPU metrics)
- blackbox-exporter (Endpoint probing)
- redis-exporter (Redis metrics)
- ollama-exporter (Ollama-specific metrics)
- nginx-exporter (Nginx metrics)
- cadvisor (Container metrics)
- fluent-bit (Log collector)
- promtail (Loki log shipper)
- rag-exporter (RAG-specific metrics)
- webhook-receiver (Webhook alert receiver)

---

**Version:** 1.0.0 **Author:** ERNI-KI Team **Last Updated:** 2024-12-06
