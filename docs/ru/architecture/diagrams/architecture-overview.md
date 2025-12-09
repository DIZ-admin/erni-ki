---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Обзор архитектуры ERNI-KI

## Высокоуровневая архитектура

```mermaid
graph TB
    subgraph User_Level["Пользовательский уровень"]
        User["Пользователь"]
        Browser["Браузер"]
    end

    subgraph Access_Level["Уровень доступа"]
        CF["Cloudflare Tunnel"]
        Nginx["Nginx Reverse Proxy"]
        Auth["JWT Auth Service"]
    end

    subgraph App_Level["Уровень приложений"]
        OpenWebUI["Open WebUI#40;GPU#41;"]
        LiteLLM["LiteLLM Gateway"]
        SearXNG["SearXNG Search"]
    end

    subgraph AI_Level["AI/ML уровень"]
        Ollama["Ollama#40;GPU#41;"]
        Docling["Docling OCR#40;GPU#41;"]
        EdgeTTS["EdgeTTS"]
    end

    subgraph Data_Level["Уровень данных"]
        PostgreSQL["PostgreSQL#40;pgvector#41;"]
        Redis["Redis Cache"]
    end

    subgraph Aux_Services["Вспомогательные сервисы"]
        Tika["Apache Tika"]
        MCP["MCP Server"]
        Backrest["Backrest Backup"]
    end

    subgraph Monitoring["Мониторинг"]
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

## Описание уровней

### Пользовательский уровень

- Доступ через веб-браузер
- HTTPS соединение

### Уровень доступа

-**Cloudflare Tunnel**: Безопасный внешний доступ -**Nginx**: Reverse proxy и
SSL termination -**Auth**: JWT аутентификация

### Уровень приложений

-**Open WebUI**: Основной пользовательский интерфейс
(GPU-ускорение) -**LiteLLM**: Context Engineering Gateway -**SearXNG**:
Поисковый движок

### AI/ML уровень

-**Ollama**: LLM инференс (GPU RTX 5000) -**Docling**: OCR и обработка
документов (GPU) -**EdgeTTS**: Синтез речи

### Уровень данных

-**PostgreSQL**: Основная БД с pgvector расширением -**Redis**: Кэш и очереди

### Вспомогательные сервисы

-**Apache Tika**: Обработка файлов -**MCP Server**: Обработка
запросов -**Backrest**: Резервное копирование

### Мониторинг

-**Prometheus**: Сбор метрик -**Grafana**: Визуализация -**Loki**:
Логирование -**Alertmanager**: Управление алертами -**Uptime Kuma**: Мониторинг
доступности
