# 📊 ERNI-KI Monitoring Guide

Comprehensive guide for monitoring ERNI-KI system with 8 specialized exporters,
standardized healthchecks, and production-ready observability stack.

## 🎯 Overview

ERNI-KI monitoring system includes:

- **8 Specialized Exporters** - optimized and standardized (September 19, 2025)
- **Prometheus v2.55.1** - metrics collection and storage
- **Grafana** - visualization and dashboards
- **Loki + Fluent Bit** - centralized logging
- **AlertManager** - notifications and alerting

## 📈 Exporters Configuration

### 🖥️ Node Exporter (Port 9101)

**Purpose:** System-level metrics (CPU, memory, disk, network)

```yaml
# Configuration in compose.yml
node-exporter:
  image: prom/node-exporter:latest
  ports:
    - '9101:9100'
  healthcheck:
    test:
      [
        'CMD-SHELL',
        'wget --no-verbose --tries=1 --spider http://localhost:9100/metrics ||
        exit 1',
      ]
    interval: 30s
    timeout: 10s
    retries: 3
```

**Key Metrics:**

- `node_cpu_seconds_total` - CPU usage by mode
- `node_memory_MemAvailable_bytes` - available memory
- `node_filesystem_avail_bytes` - disk space available
- `node_load1` - 1-minute load average

**Health Check:**

```bash
curl -s http://localhost:9101/metrics | grep node_up
```

### 🐘 PostgreSQL Exporter (Port 9187)

**Purpose:** Database performance and health metrics

```yaml
# Configuration in compose.yml
postgres-exporter:
  image: prometheuscommunity/postgres-exporter:latest
  ports:
    - '9187:9187'
  environment:
    - DATA_SOURCE_NAME=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/openwebui?sslmode=disable
  healthcheck:
    test:
      [
        'CMD-SHELL',
        'wget --no-verbose --tries=1 --spider http://localhost:9187/metrics ||
        exit 1',
      ]
```

**Key Metrics:**

- `pg_up` - PostgreSQL availability
- `pg_stat_activity_count` - active connections
- `pg_stat_database_blks_hit` / `pg_stat_database_blks_read` - cache hit ratio
- `pg_locks_count` - database locks

**Health Check:**

```bash
curl -s http://localhost:9187/metrics | grep pg_up
```

### 🔴 Redis Exporter (Port 9121) - 🔧 Fixed 19.09.2025

**Purpose:** Redis cache performance and health metrics

```yaml
# Configuration in compose.yml (FIXED)
Redis мониторинг через Grafana:
  image: oliver006/redis_monitoring_grafana:latest
  ports:
    - '9121:9121'
  environment:
    - REDIS_ADDR=redis://:ErniKiRedisSecurePassword2024@redis:6379
    - REDIS_EXPORTER_INCL_SYSTEM_METRICS=true
  healthcheck:
    test: ['CMD-SHELL', "timeout 5 sh -c '</dev/tcp/localhost/9121' || exit 1"] # FIXED: TCP check
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 10s
```

**Status:** 🔧 Running | HTTP 200 | TCP healthcheck (fixed from wget) **Issue:**
Redis authentication (not critical for HTTP metrics endpoint)

**Key Metrics:**

- `redis_up` - Redis availability (shows 0 due to auth issue)
- `redis_memory_used_bytes` - memory usage
- `redis_connected_clients` - connected clients
- `redis_keyspace_hits_total` / `redis_keyspace_misses_total` - hit ratio

**Health Check:**

```bash
# HTTP endpoint works (returns metrics)
curl -s http://localhost:9121/metrics | head -5

# TCP healthcheck
timeout 5 sh -c '</dev/tcp/localhost/9121' && echo "Redis Exporter available"

# Direct Redis check (with password)
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ping
```

### 🎮 NVIDIA GPU Exporter (Port 9445) - ✅ Improved 19.09.2025

**Purpose:** GPU utilization and performance metrics

```yaml
# Configuration in compose.yml (IMPROVED)
nvidia-exporter:
  image: mindprince/nvidia_gpu_prometheus_exporter:latest
  ports:
    - '9445:9445'
  healthcheck:
    test: ['CMD-SHELL', "timeout 5 sh -c '</dev/tcp/localhost/9445' || exit 1"] # IMPROVED: TCP check
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 15s
```

**Status:** ✅ Healthy | HTTP 200 | TCP healthcheck (improved from pgrep)

**Key Metrics:**

- `nvidia_gpu_utilization_gpu` - GPU utilization percentage
- `nvidia_gpu_memory_used_bytes` - GPU memory usage
- `nvidia_gpu_temperature_celsius` - GPU temperature
- `nvidia_gpu_power_draw_watts` - power consumption

**Health Check:**

```bash
curl -s http://localhost:9445/metrics | grep nvidia_gpu_utilization
```

### 📦 Blackbox Exporter (Port 9115)

**Purpose:** External service availability monitoring

```yaml
# Configuration in compose.yml
blackbox-exporter:
  image: prom/blackbox-exporter:latest
  ports:
    - '9115:9115'
  healthcheck:
    test:
      [
        'CMD-SHELL',
        'wget --no-verbose --tries=1 --spider http://localhost:9115/metrics ||
        exit 1',
      ]
```

**Status:** ✅ Healthy | HTTP 200 | wget healthcheck

**Key Metrics:**

- `probe_success` - probe success status
- `probe_duration_seconds` - probe duration
- `probe_http_status_code` - HTTP response code

**Health Check:**

```bash
curl -s http://localhost:9115/metrics | grep probe_success
```

### 🧠 Ollama AI Exporter (Port 9778) - ✅ Standardized 19.09.2025

**Purpose:** AI model performance and availability metrics

```yaml
# Configuration in compose.yml (STANDARDIZED)
ollama-exporter:
  image: ricardbejarano/ollama_exporter:latest
  ports:
    - '9778:9778'
  healthcheck:
    test: [
        'CMD-SHELL',
        'wget --no-verbose --tries=1 --spider http://localhost:9778/metrics ||
        exit 1',
      ] # STANDARDIZED: localhost
    interval: 30s
    timeout: 10s
    retries: 3
```

**Status:** ✅ Healthy | HTTP 200 | wget healthcheck (standardized from
127.0.0.1)

**Key Metrics:**

- `ollama_models_total` - total number of models
- `ollama_model_size_bytes{model="model_name"}` - model sizes
- `ollama_info{version="x.x.x"}` - Ollama version
- GPU usage for AI workloads

**Health Check:**

```bash
curl -s http://localhost:9778/metrics | grep ollama_models_total
```

### 🚪 Nginx Web Exporter (Port 9113) - 🔧 Fixed 19.09.2025

**Purpose:** Web server performance and traffic metrics

```yaml
# Configuration in compose.yml (FIXED)
nginx-exporter:
  image: nginx/nginx-prometheus-exporter:latest
  ports:
    - '9113:9113'
  command:
    - '--nginx.scrape-uri=http://nginx:80/nginx_status'
    - '--web.listen-address=:9113'
  healthcheck:
    test: ['CMD-SHELL', "timeout 5 sh -c '</dev/tcp/localhost/9113' || exit 1"] # FIXED: TCP check
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 10s
```

**Status:** 🔧 Running | HTTP 200 | TCP healthcheck (fixed from wget)

**Key Metrics:**

- `nginx_connections_active` - active connections
- `nginx_connections_accepted` - accepted connections
- `nginx_http_requests_total` - total HTTP requests
- `nginx_connections_handled` - handled connections

**Health Check:**

```bash
# HTTP endpoint works
curl -s http://localhost:9113/metrics | grep nginx_connections_active

# TCP healthcheck
timeout 5 sh -c '</dev/tcp/localhost/9113' && echo "Nginx Exporter available"
```

### 📈 RAG SLA Exporter (Port 9808)

**Purpose:** RAG (Retrieval-Augmented Generation) performance metrics

```yaml
# Configuration in compose.yml
rag-exporter:
  build: ./monitoring/rag-exporter
  ports:
    - '9808:8000'
  environment:
    - RAG_TEST_URL=http://openwebui:8080
    - RAG_TEST_INTERVAL=30
  healthcheck:
    test:
      [
        'CMD-SHELL',
        'python -c "import requests;
        requests.get(''http://localhost:8000/metrics'')"',
      ]
```

**Status:** ✅ Healthy | HTTP 200 | Python healthcheck

**Key Metrics:**

- `erni_ki_rag_response_latency_seconds` - RAG response latency histogram
- `erni_ki_rag_sources_count` - number of sources in response
- RAG availability and performance SLA tracking

**Health Check:**

```bash
curl -s http://localhost:9808/metrics | grep erni_ki_rag_response_latency
```

## 🔧 Healthcheck Standardization

### Problems and Solutions (September 19, 2025)

| Exporter            | Problem                        | Solution                             | Status          |
| ------------------- | ------------------------------ | ------------------------------------ | --------------- |
| **Redis Exporter**  | wget unavailable in container  | TCP check `</dev/tcp/localhost/9121` | 🔧 Fixed        |
| **Nginx Exporter**  | wget unavailable in container  | TCP check `</dev/tcp/localhost/9113` | 🔧 Fixed        |
| **NVIDIA Exporter** | pgrep process inefficient      | TCP check `</dev/tcp/localhost/9445` | ✅ Improved     |
| **Ollama Exporter** | 127.0.0.1 instead of localhost | wget localhost standardized          | ✅ Standardized |

### Standard Healthcheck Methods

```yaml
# TCP check (for minimal containers without wget/curl)
healthcheck:
  test: ["CMD-SHELL", "timeout 5 sh -c '</dev/tcp/localhost/PORT' || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s

# HTTP check (for containers with wget)
healthcheck:
  test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:PORT/metrics || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s

# Custom check (for specialized containers)
healthcheck:
  test: ["CMD-SHELL", "python -c \"import requests; requests.get('http://localhost:PORT/metrics')\""]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

## 📊 Metrics Verification

### All Exporters Status Check

```bash
# Check all exporters HTTP status
for port in 9101 9187 9121 9445 9115 9778 9113 9808; do
  echo "Port $port: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/metrics)"
done

# Expected output: All ports should return 200
```

### Docker Health Status

```bash
# Check Docker health status
docker ps --format "table {{.Names}}\t{{.Status}}" | grep exporter

# Check specific healthcheck details
docker inspect erni-ki-Redis мониторинг через Grafana --format='{{.State.Health.Status}}'
```

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Exporter Returns HTTP 200 but Docker Shows No Health Status

**Problem:** Healthcheck configuration uses unavailable tools (wget/curl)
**Solution:** Use TCP check for minimal containers

```bash
# Diagnosis
docker inspect CONTAINER_NAME --format='{{.State.Health}}'

# If returns <nil>, healthcheck is not working
# Fix: Update compose.yml with TCP check
healthcheck:
  test: ["CMD-SHELL", "timeout 5 sh -c '</dev/tcp/localhost/PORT' || exit 1"]
```

#### 2. Redis Exporter Shows redis_up = 0

**Problem:** Authentication issue with Redis **Solution:** Verify Redis
connection string and password

```bash
# Test Redis connection directly
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ping

# Check Redis Exporter logs
docker logs erni-ki-Redis мониторинг через Grafana --tail 20
```

#### 3. NVIDIA Exporter Not Showing GPU Metrics

**Problem:** GPU not accessible or NVIDIA runtime not configured **Solution:**
Verify GPU access and runtime

```bash
# Check GPU availability
nvidia-smi

# Check container GPU access
docker exec erni-ki-nvidia-exporter nvidia-smi

# Verify runtime in compose.yml
runtime: nvidia
```

#### 4. Metrics Endpoint Returns 404

**Problem:** Incorrect endpoint path or port configuration **Solution:** Verify
exporter configuration

```bash
# Check container logs
docker logs EXPORTER_CONTAINER --tail 20

# Verify port mapping
docker port EXPORTER_CONTAINER

# Test different endpoints
curl -s http://localhost:PORT/
curl -s http://localhost:PORT/metrics
```

## 📈 Performance Optimization

### Metrics Collection Optimization

1. **Scrape Intervals:** Adjust based on metric importance
   - Critical metrics: 15s interval
   - Standard metrics: 30s interval
   - Historical metrics: 60s interval

2. **Retention Policies:** Configure appropriate data retention
   - High-resolution: 7 days
   - Medium-resolution: 30 days
   - Low-resolution: 1 year

3. **Resource Allocation:** Monitor exporter resource usage
   ```bash
   # Check exporter resource usage
   docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep exporter
   ```

## 🎯 Success Criteria

### System Health Indicators

- ✅ **All 8 exporters return HTTP 200** on /metrics endpoint
- ✅ **Docker healthcheck status** shows healthy or running
- ✅ **Prometheus targets** show all exporters as UP
- ✅ **Grafana dashboards** display current metrics
- ✅ **AlertManager** receives and processes alerts

### Performance Targets

- **Response Time:** <2s for all metrics endpoints
- **Availability:** >99.9% uptime for critical exporters
- **Resource Usage:** <5% CPU, <500MB RAM per exporter
- **Data Freshness:** <30s lag for real-time metrics

## 🔗 Related Documentation

- [Admin Guide](admin-guide.md) - System administration
- [Architecture](architecture.md) - System architecture
- [Installation Guide](installation.md) - Setup instructions
- [Troubleshooting](database-troubleshooting.md) - Problem resolution
