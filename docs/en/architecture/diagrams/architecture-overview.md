---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# ERNI-KI Architecture Overview

## High-Level Architecture

```mermaid
graph TB
    subgraph User_Level["User Level"]
        User["User"]
        Browser["Browser"]
    end

    subgraph Access_Level["Access Level"]
        CF["Cloudflare Tunnel"]
        Nginx["Nginx Reverse Proxy"]
        Auth["JWT Auth Service"]
    end

    subgraph App_Level["Application Level"]
        OpenWebUI["Open WebUI#40;GPU#41;"]
        LiteLLM["LiteLLM Gateway"]
        SearXNG["SearXNG Search"]
    end

    subgraph AI_Level["AI/ML Level"]
        Ollama["Ollama#40;GPU#41;"]
        Docling["Docling OCR#40;GPU#41;"]
        EdgeTTS["EdgeTTS"]
    end

    subgraph Data_Level["Data Level"]
        PostgreSQL["PostgreSQL#40;pgvector#41;"]
        Redis["Redis Cache"]
    end

    subgraph Aux_Services["Auxiliary Services"]
        Tika["Apache Tika"]
        MCP["MCP Server"]
        Backrest["Backrest Backup"]
    end

    subgraph Monitoring["Monitoring"]
        Prometheus["Prometheus"]
        Grafana["Grafana"]
        Loki["Loki"]
        Alertmanager["Alertmanager"]
        UptimeKuma["Uptime Kuma"]
    end

    User --> Browser
    Browser --> CF
    CF --> Nginx
    Nginx --> Auth
    Nginx --> OpenWebUI

    OpenWebUI --> LiteLLM
    OpenWebUI --> SearXNG
    OpenWebUI --> PostgreSQL
    OpenWebUI --> Redis
    OpenWebUI --> Docling

    LiteLLM --> Ollama
    LiteLLM --> PostgreSQL

    Docling --> Ollama
    Docling --> Redis

    SearXNG --> Redis

    OpenWebUI --> Tika
    OpenWebUI --> MCP
    OpenWebUI --> EdgeTTS

    Backrest --> PostgreSQL
    Backrest --> Redis

    Prometheus --> Grafana
    Prometheus --> Alertmanager
    Grafana --> Loki
```

## Layer Descriptions

### User Level

- Access via web browser
- HTTPS connection

### Access Level

- **Cloudflare Tunnel**: Secure external access
- **Nginx**: Reverse proxy and SSL termination
- **Auth**: JWT authentication

### Application Level

- **Open WebUI**: Main user interface (GPU-accelerated)
- **LiteLLM**: Context Engineering Gateway
- **SearXNG**: Search engine

### AI/ML Level

- **Ollama**: LLM inference (GPU RTX 5000)
- **Docling**: OCR and document processing (GPU)
- **EdgeTTS**: Speech synthesis

### Data Level

- **PostgreSQL**: Main database with pgvector extension
- **Redis**: Cache and queues

### Auxiliary Services

- **Apache Tika**: File processing
- **MCP Server**: Request processing
- **Backrest**: Backup

### Monitoring

- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **Loki**: Logging
- **Alertmanager**: Alert management
- **Uptime Kuma**: Availability monitoring
