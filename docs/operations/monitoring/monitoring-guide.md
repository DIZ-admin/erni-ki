---
language: en
translation_status: partial
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# Monitoring Guide (EN placeholder)

The authoritative monitoring guide lives in
`docs/ru/operations/monitoring/monitoring-guide.md`. This placeholder will be
replaced when the EN version is ready.

## Monitoring Stack Overview

```mermaid
graph TD
    subgraph "Data Collection"
        NE[Node Exporter] --> P[Prometheus]
        CE[cAdvisor] --> P
        PE[Postgres Exporter] --> P
        RE[Redis Exporter] --> P
    end
    subgraph "Visualization"
        P --> G[Grafana]
        L[Loki] --> G
    end
    subgraph "Alerting"
        P --> A[Alertmanager]
        A --> W[Webhook Receiver]
    end
```

## Quick Links

- Prometheus: `http://localhost:9091`
- Grafana: `http://localhost:3000`
- Alertmanager: `http://localhost:9093`
