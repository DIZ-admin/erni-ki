---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Data Flow

## Main Data Flows in ERNI-KI

```mermaid
flowchart TB
    subgraph UserRequest["User Request"]
        User["User"] --> Browser["Browser"]
        Browser --> |"HTTPS"| CF["Cloudflare Tunnel"]
        CF --> |"HTTP"| Nginx["Nginx"]
        Nginx --> |"JWT check"| Auth["Auth Service"]
        Auth --> |"Token"| Nginx
        Nginx --> |"HTTP"| OpenWebUI["Open WebUI"]
    end

    subgraph LLMProcessing["LLM Request Processing"]
        OpenWebUI --> |"Prompt + Context"| LiteLLM["LiteLLM Gateway"]
        LiteLLM --> |"Model Request"| Ollama["Ollama"]
        Ollama --> |"LLM Response"| LiteLLM
        LiteLLM --> |"Response"| OpenWebUI
    end

    subgraph SearchRAG["Search and RAG"]
        OpenWebUI --> |"Search Query"| SearXNG["SearXNG"]
        SearXNG --> |"Cache Check"| Redis["Redis"]
        Redis --> |"Cached Results"| SearXNG
        SearXNG --> |"Web Search"| Internet["Internet"]
        Internet --> |"Results"| SearXNG
        SearXNG --> |"Results"| OpenWebUI

        OpenWebUI --> |"Vector Query"| PostgreSQL["PostgreSQL | (pgvector)"]
        PostgreSQL --> |"Similar Docs"| OpenWebUI
    end

    subgraph DocProcessing["Document Processing"]
        OpenWebUI --> |"Upload File"| Tika["Apache Tika"]
        Tika --> |"Extracted Text"| OpenWebUI

        OpenWebUI --> |"PDF/Image"| Docling["Docling OCR"]
        Docling --> |"GPU Processing"| GPU["RTX 5000"]
        GPU --> |"OCR Result"| Docling
        Docling --> |"Structured Data"| OpenWebUI

        OpenWebUI --> |"Store Embeddings"| PostgreSQL
    end

    subgraph TTS["Text-to-Speech"]
        OpenWebUI --> |"Text"| EdgeTTS["EdgeTTS"]
        EdgeTTS --> |"Audio Stream"| OpenWebUI
    end

    subgraph Persistence["Persistence"]
        OpenWebUI --> |"Save Chat"| PostgreSQL
        OpenWebUI --> |"Cache Data"| Redis
        LiteLLM --> |"Log Requests"| PostgreSQL
    end

    subgraph Monitoring["Monitoring"]
        OpenWebUI --> |"Metrics"| Prometheus["Prometheus"]
        LiteLLM --> |"Metrics"| Prometheus
        Ollama --> |"Metrics"| Prometheus
        PostgreSQL --> |"Metrics"| PostgresExporter["PostgreSQL Exporter"]
        PostgresExporter --> |"Metrics"| Prometheus
        Redis --> |"Metrics"| RedisExporter["Redis Exporter"]
        RedisExporter --> |"Metrics"| Prometheus

        Prometheus --> |"Query"| Grafana["Grafana"]
        Prometheus --> |"Alerts"| Alertmanager["Alertmanager"]

        FluentBit["Fluent Bit"] --> |"Logs"| Loki["Loki"]
        Loki --> |"Query"| Grafana
    end

    subgraph Backup["Backup"]
        Backrest["Backrest"] --> |"Backup"| PostgreSQL
        Backrest --> |"Backup"| Redis
        Backrest --> |"Backup Files"| Storage["Local Storage"]
    end
```

## Flow Descriptions

### 1. User Request

1. User sends request via browser
2. Cloudflare Tunnel provides secure connection
3. Nginx validates JWT token via Auth Service
4. Request is forwarded to Open WebUI

### 2. LLM Request Processing

1. Open WebUI forms prompt with context
2. LiteLLM Gateway routes request to Ollama
3. Ollama generates response on GPU
4. Response is returned to user

### 3. Search and RAG

1. Search queries are processed by SearXNG
2. Results are cached in Redis
3. Vector search is performed in PostgreSQL (pgvector)
4. Relevant documents are added to context

### 4. Document Processing

1. Files are processed by Apache Tika for text extraction
2. PDFs/images are processed by Docling with GPU acceleration
3. Embeddings are stored in PostgreSQL
4. Structured data is returned to Open WebUI

### 5. Text-to-Speech

1. Text is sent to EdgeTTS
2. Audio stream is generated
3. Audio is returned to user

### 6. Persistence

1. Chats are saved to PostgreSQL
2. Temporary data is cached in Redis
3. LiteLLM logs all requests to PostgreSQL

### 7. Monitoring

1. Metrics are collected by Prometheus
2. Logs are aggregated by Fluent Bit → Loki
3. Grafana visualizes metrics and logs
4. Alertmanager manages alerts

### 8. Backup

1. Backrest creates backups of PostgreSQL and Redis
2. Backups are stored locally
3. Automated schedule via cron
