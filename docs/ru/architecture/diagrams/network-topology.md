---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Сетевая топология

## Сетевая архитектура и порты

```mermaid
graph TB
    subgraph External["Внешняя сеть"]
        Internet["Интернет"]
        ExternalUser["Внешний | пользователь"]
    end

    subgraph Local["Локальная сеть (192.168.62.0/24)"]
        LocalUser["Локальный | пользователь"]
        Router["LANCOM Router | 192.168.62.1"]
        Server["ERNI-KI Server | 192.168.62.153"]
    end

    subgraph Public["Публичные порты (Server)"]
        Port80["80/tcp | HTTP"]
        Port443["443/tcp | HTTPS"]
        Port8080["8080/tcp | HTTP Alt"]
        Port3001["3001/tcp | Uptime Kuma"]
    end

    subgraph Localhost["Localhost-only порты"]
        Port4000["127.0.0.1:4000 | LiteLLM API"]
        Port11434["127.0.0.1:11434 | Ollama"]
        Port9091["127.0.0.1:9091 | Prometheus"]
        Port3000["127.0.0.1:3000 | Grafana"]
        Port3100["127.0.0.1:3100 | Loki"]
        Port9093["127.0.0.1:9093 | Alertmanager"]
        Port9092["127.0.0.1:9092 | Auth"]
        Port9898["127.0.0.1:9898 | Backrest"]
        Port5050["127.0.0.1:5050 | EdgeTTS"]
        Port9998["127.0.0.1:9998 | Tika"]
        Port8000["127.0.0.1:8000 | MCP"]
        Port8091["127.0.0.1:8091 | Watchtower API"]
    end

    subgraph Docker["Docker Bridge Network"]
        DockerBridge["docker0 | 172.17.0.0/16"]
    end

    Internet --> ExternalUser
    ExternalUser --> |"Cloudflare Tunnel"| Server

    LocalUser --> Router
    Router --> Server

    Server --> Port80
    Server --> Port443
    Server --> Port8080
    Server --> Port3001

    Server --> Port4000
    Server --> Port11434
    Server --> Port9091
    Server --> Port3000
    Server --> Port3100
    Server --> Port9093
    Server --> Port9092
    Server --> Port9898
    Server --> Port5050
    Server --> Port9998
    Server --> Port8000
    Server --> Port8091

    Port80 --> DockerBridge
    Port443 --> DockerBridge
    Port8080 --> DockerBridge
```

## Таблица портов

### Публичные порты (доступны из локальной сети)

| Порт | Сервис      | Протокол | Описание               |
| ---- | ----------- | -------- | ---------------------- |
| 80   | Nginx       | HTTP     | HTTP редирект на HTTPS |
| 443  | Nginx       | HTTPS    | Основной HTTPS доступ  |
| 8080 | Nginx       | HTTP     | Альтернативный HTTP    |
| 3001 | Uptime Kuma | HTTP     | Status page            |

### Localhost-only порты (доступны только с сервера)

| Порт  | Сервис       | Протокол | Описание          |
| ----- | ------------ | -------- | ----------------- |
| 4000  | LiteLLM      | HTTP     | LiteLLM Proxy API |
| 11434 | Ollama       | HTTP     | Ollama API        |
| 9091  | Prometheus   | HTTP     | Prometheus UI     |
| 3000  | Grafana      | HTTP     | Grafana UI        |
| 3100  | Loki         | HTTP     | Loki API          |
| 9093  | Alertmanager | HTTP     | Alertmanager UI   |
| 9092  | Auth         | HTTP     | JWT Auth Service  |
| 9898  | Backrest     | HTTP     | Backrest UI       |
| 5050  | EdgeTTS      | HTTP     | EdgeTTS API       |
| 9998  | Tika         | HTTP     | Tika API          |
| 8000  | MCP          | HTTP     | MCP Server API    |
| 8091  | Watchtower   | HTTP     | Watchtower API    |

### Внутренние порты (Docker network)

| Порт | Сервис              | Описание       |
| ---- | ------------------- | -------------- |
| 5432 | PostgreSQL          | Database       |
| 6379 | Redis               | Cache & Queues |
| 8080 | SearXNG             | Search Engine  |
| 8080 | OpenWebUI           | Web Interface  |
| 5001 | Docling             | OCR Service    |
| 9100 | Node Exporter       | System metrics |
| 9187 | PostgreSQL Exporter | DB metrics     |
| 9121 | Redis Exporter      | Redis metrics  |

## Сетевая безопасность

### Firewall правила

- Публичные порты: 80, 443, 8080, 3001
- Localhost-only: все остальные сервисы
- Docker bridge: изолированная сеть для контейнеров

### SSL/TLS

- Let's Encrypt сертификат для `ki.erni-gruppe.ch`
- Nginx SSL termination
- Внутренние соединения через HTTP (Docker network)

### Cloudflare Tunnel

- Безопасный внешний доступ без port forwarding
- DDoS защита
- Автоматический SSL
