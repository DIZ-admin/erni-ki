---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
title: 'Detailed Table of Active ERNI-KI Services'
---

# Detailed Table of Active ERNI-KI Services

**Status:** Production Ready v0.61.3 · All 30 services running (30/30 Healthy) ·
27 Prometheus alerts · Automated maintenance

## Application Layer (AI & Core)

| Service    | Status/Ports              | Configuration                   | Notes                                                    |
| ---------- | ------------------------- | ------------------------------- | -------------------------------------------------------- |
| ollama     | Healthy · `11434:11434`   | `env/ollama.env`                | Critical; Ollama 0.12.11; GPU 4GB; auto-update disabled  |
| openwebui  | Healthy · `8080` internal | `conf/openwebui/*.json`, env    | Critical; v0.6.40; GPU (NVIDIA runtime); MCP integration |
| litellm    | Healthy · `4000:4000`     | `conf/litellm/config.yaml`, env | LiteLLM v1.80.0.rc.1; Thinking tokens; Memory limit 12G  |
| searxng    | Healthy · `8080` internal | `conf/searxng/*.yml`, env       | RAG search; 6+ sources; Redis caching                    |
| mcposerver | Healthy · `8000:8000`     | `conf/mcposerver/config.json`   | MCP Server; tools Time/Postgres/Filesystem/Memory        |

## Processing Layer (Docs & Media)

| Service | Status/Ports   | Configuration | Notes                                 |
| ------- | -------------- | ------------- | ------------------------------------- |
| tika    | Healthy · 9998 | env           | Apache Tika; text/metadata extraction |
| edgetts | Healthy · 5050 | env           | EdgeTTS; speech synthesis             |

## Data Layer (DB & Cache)

| Service | Status/Ports            | Configuration                | Notes                                                    |
| ------- | ----------------------- | ---------------------------- | -------------------------------------------------------- |
| db      | Healthy · internal      | env, custom Postgres         | Critical; PostgreSQL 17 + pgvector; auto-update disabled |
| redis   | Healthy · internal 6379 | `conf/redis/redis.conf`, env | Redis 7-alpine; WebSocket manager; defrag; cache/queues  |

## Gateway Layer (Proxy & Auth)

| Service     | Status/Ports           | Configuration                     | Notes                                           |
| ----------- | ---------------------- | --------------------------------- | ----------------------------------------------- |
| nginx       | Up · `80, 443, 8080`   | `conf/nginx/*.conf`               | Critical; SSL termination; auto-update disabled |
| auth        | Up · `9092:9090`       | `env/auth.env`                    | JWT authentication (Go)                         |
| cloudflared | Up · no external ports | `conf/cloudflare/config.yml`, env | Healthcheck disabled; Cloudflare Tunnel         |

## Monitoring Layer

| Service          | Status/Ports       | Configuration                 | Notes                                       |
| ---------------- | ------------------ | ----------------------------- | ------------------------------------------- |
| prometheus       | Up · `9091:9090`   | `conf/prometheus/*.yml`, env  | Metrics collection; 35 targets              |
| grafana          | Up · `3000:3000`   | `conf/grafana/**`, env        | Dashboards/visualization                    |
| alertmanager     | Up · `9093-9094`   | env                           | Alert management                            |
| loki             | Up · `3100:3100`   | `conf/loki/loki-config.yaml`  | Centralized logging                         |
| fluent-bit       | Up · `2020, 24224` | `conf/fluent-bit/*.conf`, env | Healthcheck disabled; log collection → Loki |
| webhook-receiver | Up · `9095:9093`   | env                           | Alert processing                            |

## Exporters

| Service           | Status/Ports     | Configuration                       | Notes                        |
| ----------------- | ---------------- | ----------------------------------- | ---------------------------- |
| node-exporter     | Up · `9101:9100` | env                                 | System metrics               |
| cadvisor          | Up · `8081:8080` | env                                 | Container metrics            |
| blackbox-exporter | Up · `9115:9115` | env                                 | Availability checks          |
| nvidia-exporter   | Up · `9445:9445` | env                                 | GPU metrics (NVIDIA runtime) |
| ollama-exporter   | Up · `9778:9778` | env                                 | AI model metrics             |
| postgres-exporter | Up · `9187:9187` | `conf/postgres-exporter/*.yml`, env | PostgreSQL metrics           |
