---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Диаграмма развертывания

## Docker Compose архитектура

```mermaid
graph TB
    subgraph "Критические сервисы (Tier 1)"
        OpenWebUI["openwebui<br/>v0.6.36<br/>GPU: RTX 5000<br/>8GB RAM"]
        Ollama["ollama<br/>v0.12.11<br/>GPU: RTX 5000<br/>24GB RAM"]
        PostgreSQL["db (PostgreSQL)<br/>pgvector/pg17<br/>4GB RAM"]
        Nginx["nginx<br/>v1.29.3<br/>512MB RAM"]
    end

    subgraph "Важные сервисы (Tier 2)"
        LiteLLM["litellm<br/>v1.80.0.rc.1<br/>12GB RAM"]
        Redis["redis<br/>v7.0.15<br/>1GB RAM"]
        SearXNG["searxng<br/>latest<br/>1GB RAM"]
        Auth["auth<br/>custom build"]
        Cloudflared["cloudflared<br/>2025.11.1"]
        Backrest["backrest<br/>v1.9.2"]
    end

    subgraph "Вспомогательные сервисы (Tier 3)"
        Docling["docling<br/>GPU: RTX 5000<br/>12GB RAM"]
        EdgeTTS["edgetts<br/>latest"]
        Tika["tika<br/>latest"]
        MCP["mcposerver<br/>git-91e8f94"]
    end

    subgraph "Мониторинг (Tier 4)"
        Prometheus["prometheus<br/>v3.0.0"]
        Grafana["grafana<br/>v11.3.0"]
        Loki["loki<br/>v3.0.0"]
        Alertmanager["alertmanager<br/>v0.27.0"]
        UptimeKuma["uptime-kuma<br/>v2.0.2"]
        NodeExporter["node-exporter<br/>v1.8.2"]
        PostgresExporter["postgres-exporter<br/>v0.16.0"]
        RedisExporter["redis-exporter<br/>v1.67.0"]
    end

    subgraph "Инфраструктура"
        Watchtower["watchtower<br/>v1.7.1"]
        FluentBit["fluent-bit<br/>v3.2.2"]
    end

    OpenWebUI --> PostgreSQL
    OpenWebUI --> Redis
    OpenWebUI --> LiteLLM
    OpenWebUI --> Docling
    OpenWebUI --> SearXNG
    OpenWebUI --> Tika
    OpenWebUI --> MCP
    OpenWebUI --> EdgeTTS

    LiteLLM --> Ollama
    LiteLLM --> PostgreSQL

    Docling --> Ollama
    Docling --> Redis

    SearXNG --> Redis

    Nginx --> Auth
    Nginx --> OpenWebUI

    Cloudflared --> Nginx

    Backrest --> PostgreSQL
    Backrest --> Redis

    Prometheus --> NodeExporter
    Prometheus --> PostgresExporter
    Prometheus --> RedisExporter
    Prometheus --> Alertmanager

    Grafana --> Prometheus
    Grafana --> Loki

    FluentBit --> Loki
```

## Ресурсы и ограничения

### GPU-сервисы (NVIDIA RTX 5000, 16GB VRAM)

- **Ollama**: 24GB RAM, 12 CPU cores, OOM score: -900
- **OpenWebUI**: 8GB RAM, 4 CPU cores, OOM score: -600
- **Docling**: 12GB RAM, 8 CPU cores, OOM score: -500

### Критические сервисы

- **PostgreSQL**: 4GB RAM, 2 CPU cores
- **Nginx**: 512MB RAM, 1 CPU core
- **LiteLLM**: 12GB RAM, 1 CPU core, OOM score: -300

### Стратегия логирования (4-tier)

- **Tier 1 (Critical)**: Dual logging (json-file + fluentd backup)
- **Tier 2 (Important)**: Fluentd with buffering
- **Tier 3 (Auxiliary)**: Fluentd with separate tags
- **Tier 4 (Monitoring)**: Minimal logging

## Auto-update политика

### Отключены (monitor-only)

- Ollama (GPU-critical)
- PostgreSQL (database)
- Nginx (proxy)
- OpenWebUI (web interface)
- LiteLLM (gateway)
- Docling (GPU service)

### Включены

- Redis, SearXNG, Auth
- Cloudflared, Backrest
- Все мониторинг-сервисы
- Tika, EdgeTTS, MCP
