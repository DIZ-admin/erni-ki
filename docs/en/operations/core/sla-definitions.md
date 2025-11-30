---
language: en
translation_status: complete
doc_version: '2025.11'
title: 'SLA and SLI Definitions'
system_version: '0.6.3'
last_updated: '2025-11-30'
system_status: 'Production Ready'
---

# SLA and SLI Definitions for ERNI-KI

**Purpose:** Define explicit Service Level Agreements (SLA) and Service Level Indicators (SLI) for monitoring and accountability.

**Audience:** DevOps, SRE, Product, Management
**Last reviewed:** 2025-11-30
**Next review:** 2026-02-28

---

## Executive Summary

ERNI-KI is a production AI platform with the following SLAs:

| Service | Availability | Response Time (p99) | Error Rate | Status |
|---------|--------------|-------------------|-----------|--------|
| OpenWebUI | 99.95% | 5,000ms | <0.1% | 🟢 Active |
| Ollama (LLM) | 99.9% | 10,000ms | <0.5% | 🟢 Active |
| PostgreSQL | 99.99% | 100ms | 0% | 🟢 Active |
| Redis Cache | 99.95% | 10ms | <0.1% | 🟢 Active |
| SearXNG (RAG) | 99.9% | 3,000ms | <1% | 🟢 Active |
| Infrastructure | 99.95% | - | - | 🟢 Active |

**Overall System SLA:** 99.9% uptime (8.77 hours downtime per year)

---

## SLO vs SLI vs SLA (Terminology)

| Term | Definition | Example |
|------|-----------|---------|
| **SLO** (Service Level Objective) | Internal target we strive for | "99.95% uptime" |
| **SLI** (Service Level Indicator) | Metric that measures SLO | "uptime = 99.94%" |
| **SLA** (Service Level Agreement) | Contract with users, usually looser | "99.9% uptime guaranteed" |

**Rule of thumb:**
- SLO > SLA (we aim higher than we promise)
- SLI measures against SLO (alert if SLI < SLO)

---

## Core Services

### 1. OpenWebUI

**Role:** User-facing chat interface and AI interaction

#### SLA
```yaml
availability_slo: "99.95%"           # 21 min/month downtime acceptable
availability_sla: "99.9%"             # 43 min/month guaranteed to users
response_time_p50: "500ms"           # Median response time
response_time_p99: "5000ms"          # 99th percentile (5 seconds)
response_time_p999: "15000ms"        # 99.9th percentile (15 seconds)
error_rate_target: "<0.1%"           # Max 1 error per 1000 requests
```

#### SLI - Metrics to Monitor
```prometheus
# Request latency
histogram_quantile(0.99, http_request_duration_seconds{service="openwebui"})
# Expected: < 5000ms

# Request success rate
rate(http_requests_total{service="openwebui", status=~"2.."}[5m]) /
rate(http_requests_total{service="openwebui"}[5m])
# Expected: > 99.9%

# Container uptime
up{job="openwebui"}
# Expected: 1 (up) 100% of time

# Database connectivity
pg_up{service="openwebui"}
# Expected: 1 (connected)
```

#### Alerting Rules
```yaml
- alert: OpenWebUIHighLatency
  expr: histogram_quantile(0.99, http_request_duration_seconds{service="openwebui"}) > 5000
  for: 5m
  severity: warning

- alert: OpenWebUIHighErrorRate
  expr: rate(http_requests_total{service="openwebui", status=~"5.."}[5m]) > 0.001
  for: 5m
  severity: critical

- alert: OpenWebUIDown
  expr: up{job="openwebui"} == 0
  for: 1m
  severity: critical
```

#### Maintenance Windows
- **Scheduled:** Sundays 03:00-04:00 UTC (SLA suspended)
- **Unplanned:** 30 min/quarter allowed for emergency fixes

---

### 2. Ollama (LLM Engine)

**Role:** Local LLM inference with GPU acceleration

#### SLA
```yaml
availability_slo: "99.9%"             # 43 min/month downtime
availability_sla: "99.5%"             # 217 min/month guaranteed
response_time_p99: "10000ms"         # 10 seconds for LLM inference
error_rate_target: "<0.5%"           # May be higher during model loads
gpu_memory_utilization: "50-90%"     # Healthy range
model_load_time: "<5s"               # Loading models from cache
```

#### SLI - Metrics
```prometheus
# Ollama process uptime
up{job="ollama"}
# Expected: 1

# GPU memory usage
nvidia_smi_memory_used_mb / nvidia_smi_memory_total_mb
# Expected: 0.5-0.9 (50-90%)

# Inference latency
histogram_quantile(0.99, ollama_request_duration_seconds)
# Expected: < 10000ms

# Model availability
ollama_models_loaded
# Expected: >= 1 (at least one model loaded)
```

#### Critical Thresholds
| Metric | Threshold | Action |
|--------|-----------|--------|
| GPU Memory | >95% | Alert WARNING, consider model unload |
| Inference Time | >15s | Alert CRITICAL, likely GPU hang |
| Model Load Failure | Any | Alert CRITICAL, restart container |
| VRAM Limit Exceeded | >4GB | Auto-kill process (configured) |

---

### 3. PostgreSQL Database

**Role:** Primary data store with pgvector for embeddings

#### SLA
```yaml
availability_slo: "99.99%"            # 4 min/month downtime only
availability_sla: "99.95%"            # 21 min/month guaranteed
response_time_p99: "100ms"           # Database queries
error_rate_target: "0%"              # No query errors
backup_rpo: "1 hour"                 # Recovery Point Objective
backup_rto: "15 minutes"             # Recovery Time Objective
```

#### SLI - Key Metrics
```prometheus
# Database connectivity
pg_up
# Expected: 1

# Transaction duration (p99)
histogram_quantile(0.99, pg_transactions_duration_seconds)
# Expected: < 100ms

# Active connections
pg_stat_activity_count
# Expected: < 50 (out of 100 max)

# Replication lag (if applicable)
pg_replication_lag_bytes
# Expected: < 1MB

# Disk space
pg_database_size_bytes / (1024^3)
# Expected: < 80% of volume
```

#### Alerting
```yaml
- alert: PostgreSQLDown
  expr: pg_up == 0
  for: 30s
  severity: critical

- alert: PostgreSQLDiskFull
  expr: pg_database_size_bytes / (1024^3) > 0.8 * max_volume_size
  for: 5m
  severity: critical

- alert: PostgreSQLSlowQueries
  expr: histogram_quantile(0.99, pg_transactions_duration_seconds) > 100
  for: 5m
  severity: warning

- alert: PostgreSQLBackupStale
  expr: time() - pg_backup_timestamp_seconds > 3600
  for: 30m
  severity: critical
```

---

### 4. Redis Cache

**Role:** Session storage, caching, rate limiting

#### SLA
```yaml
availability_slo: "99.95%"            # 21 min/month
availability_sla: "99.9%"             # 43 min/month
response_time_p99: "10ms"            # Very fast
error_rate_target: "<0.1%"
memory_limit: "2GB"
eviction_policy: "allkeys-lru"
```

#### SLI - Metrics
```prometheus
# Connection health
redis_up
# Expected: 1

# Memory usage
redis_memory_used_bytes / (2 * 1024^3)
# Expected: < 80%

# Command latency
histogram_quantile(0.99, redis_command_duration_seconds)
# Expected: < 10ms

# Cache hit ratio
rate(redis_keyspace_hits_total[5m]) /
(rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m]))
# Expected: > 80%
```

---

### 5. SearXNG (RAG Search)

**Role:** Retrieval-Augmented Generation search engine

#### SLA
```yaml
availability_slo: "99.9%"
availability_sla: "99.5%"
response_time_p99: "3000ms"          # Search queries
error_rate_target: "<1%"             # May timeout occasionally
search_sources: ">=4"                # Min Google, Bing, DuckDuckGo, Brave
```

#### SLI - Metrics
```prometheus
# Availability
up{job="searxng"}
# Expected: 1

# Search latency
histogram_quantile(0.99, searxng_search_duration_seconds)
# Expected: < 3000ms

# Results returned
searxng_results_count
# Expected: >= 10 results per query

# Source availability
searxng_source_up{source=~"google|bing|duckduckgo|brave"}
# Expected: >= 3 sources working
```

---

## Infrastructure Services

### 6. Prometheus Monitoring

#### SLA
```yaml
availability_slo: "99.95%"
response_time_p99: "1000ms"          # Query latency
scrape_interval: "30s"               # Data collection frequency
targets_up: "32/32"                  # All services being scraped
```

#### SLI - Metrics
```prometheus
# Prometheus uptime
up{job="prometheus"}

# Scrape success rate
rate(scrape_duration_seconds_count{job="prometheus"}[5m])

# Target health
count(up{job!="prometheus"} == 1) / count(up{job!="prometheus"})
# Expected: 100% (all 32 targets up)
```

---

### 7. Grafana Dashboards

#### SLA
```yaml
availability_slo: "99.9%"
response_time_p99: "2000ms"          # Dashboard load time
dashboards_provisioned: "5/5"
```

---

### 8. Alertmanager

#### SLA
```yaml
availability_slo: "99.95%"
notification_latency_p99: "5s"       # Time to send alert
delivery_success_rate: ">99%"        # Alerts reach channels
```

#### SLI - Metrics
```prometheus
# Alertmanager uptime
up{job="alertmanager"}

# Alert delivery
rate(alertmanager_notify_total[5m])

# Failed notifications
rate(alertmanager_notify_failed_total[5m])
# Expected: < 1% of total notifications
```

---

## System-Wide SLIs

### Overall Uptime Calculation

```
System Uptime = (Services Up / Total Services) × 100%

Alerting Rules:
- WARNING if < 99.5% (33/34 services)
- CRITICAL if < 99% (33.7/34 services = ~34 services down or 1-2 critical ones)
```

### Disk Space Monitoring

```prometheus
# Alert thresholds
- 90%: WARNING "Disk usage high"
- 95%: CRITICAL "Disk almost full, potential service impact"
- 98%: CRITICAL "IMMEDIATE action required"

# Healthy state
/ : < 75% used
/var/lib/docker : < 80% used (volume storage)
PostgreSQL data : < 75% used
```

### Network Health

```prometheus
# Network latency (between services)
ping_latency_ms{source="nginx", target="openwebui"}
# Expected: < 10ms

# Packet loss
ping_packet_loss_percent
# Expected: 0%
```

---

## Error Budget

**Error Budget = (1 - SLA) × time period**

### Monthly Error Budget (99.9% SLA)

```
99.9% × 30 days = 0.1% downtime allowed
0.1% × 43,200 minutes = 43.2 minutes/month

This means:
- We can afford 43 minutes of downtime per month
- Any downtime beyond 43 minutes violates SLA
- Must be tracked and reported to stakeholders
```

### Quarterly Error Budget

```
99.9% × 90 days = 129 minutes/quarter
99.95% SLO × 90 days = 64 minutes/quarter

If we consume > 64 minutes, we're below SLO and need action plan.
If we consume > 129 minutes, we've violated SLA.
```

---

## Maintenance Windows

### Scheduled Maintenance (Excluded from SLA)

```yaml
Regular Window:
  day: Sunday
  time: "03:00-04:00 UTC"
  duration: "60 minutes"
  services_affected: "All (acceptable)"
  frequency: "Weekly"
  advance_notice: "24 hours"

Emergency Maintenance:
  trigger: "Critical security patch required"
  notice: "ASAP (minimum 1 hour)"
  max_frequency: "Once per quarter"
  duration: "30 minutes (target)"
```

### Maintenance Notification Template

```
🔧 SCHEDULED MAINTENANCE
- Date/Time: [ISO 8601]
- Duration: 30-60 minutes
- Services: [List affected]
- Impact: [Expected user impact]
- Reason: [Brief explanation]
- Status page: [Link]
```

---

## Incident Response

### Severity Levels & Response Times

| Severity | Condition | Response Time | Resolution Time |
|----------|-----------|---------------|-----------------|
| **P0 Critical** | System completely down, data loss risk | <15 min | <1 hour |
| **P1 Major** | Core functionality broken, high impact | <30 min | <4 hours |
| **P2 Medium** | Partial functionality broken | <2 hours | <8 hours |
| **P3 Minor** | Non-critical issue, workaround available | <1 day | <1 week |

### Escalation Matrix

```
On-call: Receives alert (5 min)
  ↓ (no response in 5 min)
Lead Engineer: Escalated
  ↓ (no resolution in 30 min)
Engineering Manager: Escalated
  ↓ (no resolution in 1 hour)
Director/VP: Escalated + Customer notification
```

---

## Monitoring and Reporting

### Daily Monitoring
- [ ] Check dashboard health (Grafana)
- [ ] Review error logs
- [ ] Monitor error budget consumption
- [ ] Verify backups completed

### Weekly Reporting (Monday morning)
```
ERNI-KI Weekly Health Report
- Uptime: [X.XX%]
- Major incidents: [N]
- Error budget used: [X%]
- Planned maintenance: [Scheduled]
```

### Monthly SLA Review (Last Friday)
```
November 2025 SLA Report
- Target: 99.9%
- Achieved: 99.94%
- Status: PASSED ✅
- Error budget remaining: 15 minutes
- Incidents: 1 (P2, resolved in 2 hours)
- Improvement actions: [List]
```

### Quarterly Business Review

Document for stakeholders:
- Actual uptime vs. SLA
- Incidents and root causes
- Improvement actions implemented
- Forecast for next quarter
- Budget request (if additional resources needed)

---

## Dashboard Queries (Prometheus)

### Uptime Dashboard
```prometheus
# Overall uptime (last 30 days)
avg_over_time(up[30d]) * 100

# By service
avg_over_time(up{job="openwebui"}[30d]) * 100
avg_over_time(up{job="ollama"}[30d]) * 100
avg_over_time(up{job="postgres"}[30d]) * 100

# System uptime
count(up == 1) / count(up) * 100
```

### Performance Dashboard
```prometheus
# Response times
histogram_quantile(0.50, http_request_duration_seconds)
histogram_quantile(0.99, http_request_duration_seconds)
histogram_quantile(0.999, http_request_duration_seconds)

# Error rates
rate(http_requests_total{status=~"5.."}[5m]) * 100

# Resource utilization
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

---

## Review and Updates

**Last reviewed:** 2025-11-30
**Next review:** 2026-02-28
**Owner:** DevOps / SRE Team
**Approver:** Engineering Manager

Changes require:
1. Engineering team review
2. Product approval (if affecting user-facing SLA)
3. Update in this document + version bump
4. Alert rule updates in Prometheus
5. Dashboard updates in Grafana

---

## See Also

- [Pre-Deployment Checklist](./pre-deployment-checklist.md)
- [Monitoring Guide](../monitoring/monitoring-guide.md)
- [Admin Guide](./admin-guide.md)
- [Incident Response Plan](../incidents/incident-response-playbook.md)
