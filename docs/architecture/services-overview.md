---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
title: 'Детальная таблица активных сервисов ERNI-KI'
---

# Детальная таблица активных сервисов ERNI-KI

**Статус:** Production Ready v12.1 · Все 30 сервисов работают (30/30 Healthy) ·
27 Prometheus alerts · Автоматизированное обслуживание

## Application Layer (AI & Core)

| Сервис     | Статус/Порты              | Конфигурация                    | Примечания                                               |
| ---------- | ------------------------- | ------------------------------- | -------------------------------------------------------- |
| ollama     | Healthy · `11434:11434`   | `env/ollama.env`                | Критичный; Ollama 0.12.11; GPU 4GB; автообновление выкл. |
| openwebui  | Healthy · `8080` internal | `conf/openwebui/*.json`, env    | Критичный; v0.6.40; GPU (NVIDIA runtime); MCP интеграция |
| litellm    | Healthy · `4000:4000`     | `conf/litellm/config.yaml`, env | LiteLLM v1.80.0.rc.1; Thinking tokens; Memory limit 12G  |
| searxng    | Healthy · `8080` internal | `conf/searxng/*.yml`, env       | RAG поиск; 6+ источников; Redis кэширование              |
| mcposerver | Healthy · `8000:8000`     | `conf/mcposerver/config.json`   | MCP Server; инструменты Time/Postgres/Filesystem/Memory  |

## Processing Layer (Docs & Media)

| Сервис  | Статус/Порты   | Конфигурация | Примечания                           |
| ------- | -------------- | ------------ | ------------------------------------ |
| tika    | Healthy · 9998 | env          | Apache Tika; извлечение текста/метад |
| edgetts | Healthy · 5050 | env          | EdgeTTS; синтез речи                 |

## Data Layer (DB & Cache)

| Сервис | Статус/Порты            | Конфигурация                 | Примечания                                                |
| ------ | ----------------------- | ---------------------------- | --------------------------------------------------------- |
| db     | Healthy · internal      | env, custom Postgres         | Критичный; PostgreSQL 17 + pgvector; автообновление выкл. |
| redis  | Healthy · internal 6379 | `conf/redis/redis.conf`, env | Redis 7-alpine; WebSocket manager; defrag; кэш/очереди    |

## Gateway Layer (Proxy & Auth)

| Сервис      | Статус/Порты           | Конфигурация                      | Примечания                              |
| ----------- | ---------------------- | --------------------------------- | --------------------------------------- |
| nginx       | Up · `80, 443, 8080`   | `conf/nginx/*.conf`               | Критичный; SSL терминация; автообн выкл |
| auth        | Up · `9092:9090`       | `env/auth.env`                    | JWT аутентификация (Go)                 |
| cloudflared | Up · no external ports | `conf/cloudflare/config.yml`, env | Healthcheck выкл; Cloudflare Tunnel     |

## Monitoring Layer

| Сервис           | Статус/Порты       | Конфигурация                  | Примечания                          |
| ---------------- | ------------------ | ----------------------------- | ----------------------------------- |
| prometheus       | Up · `9091:9090`   | `conf/prometheus/*.yml`, env  | Сбор метрик; 35 targets             |
| grafana          | Up · `3000:3000`   | `conf/grafana/**`, env        | Дашборды/визуализация               |
| alertmanager     | Up · `9093-9094`   | env                           | Управление алертами                 |
| loki             | Up · `3100:3100`   | `conf/loki/loki-config.yaml`  | Централизованный логинг             |
| fluent-bit       | Up · `2020, 24224` | `conf/fluent-bit/*.conf`, env | Healthcheck выкл; сбор логов → Loki |
| webhook-receiver | Up · `9095:9093`   | env                           | Обработка алертов                   |

## Exporters

| Сервис            | Статус/Порты     | Конфигурация                        | Примечания                   |
| ----------------- | ---------------- | ----------------------------------- | ---------------------------- |
| node-exporter     | Up · `9101:9100` | env                                 | Системные метрики            |
| cadvisor          | Up · `8081:8080` | env                                 | Метрики контейнеров          |
| blackbox-exporter | Up · `9115:9115` | env                                 | Проверка доступности         |
| nvidia-exporter   | Up · `9445:9445` | env                                 | GPU метрики (NVIDIA runtime) |
| ollama-exporter   | Up · `9778:9778` | env                                 | Метрики AI моделей           |
| postgres-exporter | Up · `9187:9187` | `conf/postgres-exporter/*.yml`, env | Метрики PostgreSQL           |
