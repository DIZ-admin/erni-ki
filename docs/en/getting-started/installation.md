---
language: en
translation_status: complete
doc_version: '2025.11'
title: 'installation'
version: '12.1'
date: '2025-11-22'
status: 'Production Ready'
---

# 📦 Installation Guide - ERNI-KI

> **Version:** 12.1 · **Updated:** 2025-11-22 · **Status:** Production Ready  
> Monitoring stack: 5 provisioned Grafana dashboards, up-to-date Prometheus

## 📋 Overview

Step-by-step installation and configuration of ERNI-KI — a production-ready AI
platform (29 microservices, enterprise-grade DB performance).

## 📋 System requirements

### Minimum

- **OS:** Linux (Ubuntu 20.04+ / CentOS 8+ / Debian 11+)
- **CPU:** 4 cores (8+ recommended)
- **RAM:** 16GB (optimized for PostgreSQL & Redis)
- **Storage:** 100GB free (SSD recommended)
- **Network:** Stable internet
- **Sysctl:** `vm.overcommit_memory=1` (Redis)

### Recommended (Production)

- **CPU:** 8+ cores with AVX2
- **RAM:** 32GB+ (PostgreSQL: 256MB shared_buffers, Redis: 2GB limit)
- **GPU:** NVIDIA 8GB+ VRAM (Ollama GPU)
- **Storage:** 500GB+ NVMe SSD
- **Network:** 1Gbps+ (model downloads)
- **Monitoring:** Prometheus + Grafana + 8 exporters (optimized 2025-09-19)
  - ~2GB RAM for full monitoring
  - Ports: 9101, 9187, 9121, 9445, 9115, 9778, 9113, 9808

## 🔧 Prerequisites

### 1) Install Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo reboot
```

### 2) Install Docker Compose v2

```bash
sudo apt update
sudo apt install docker-compose-plugin
docker compose version
```

### 3) NVIDIA Container Toolkit (GPU)

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
```

## 🆕 New components (v7.0)

### LiteLLM Context Engineering

- **Purpose:** Unified API for multiple LLM providers
- **Context7:** Enhanced context for AI answers
- **Port:** 4000
- **Config:** `env/litellm.env`, `conf/litellm/config.yaml`

### Docling (OCR pipeline)

- **Purpose:** Multilingual document processing with OCR
- **Languages:** EN, DE, FR, IT
- **Port:** 5001

### Monitoring stack (current)

- 5 Grafana dashboards (provisioned)
- Prometheus queries with safe fallbacks
- Dashboard load time <3s; request success >85%

## 🚀 Quick install

### 1) Clone repo

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
```

### 2) Run setup script

```bash
# Interactive install
./scripts/setup/setup.sh

# Or quick install with defaults
./scripts/setup/quick-start.sh
```

### 3) Verify install

```bash
./scripts/maintenance/health-check.sh
./scripts/maintenance/check-web-interfaces.sh
```

## 🔧 Manual install

### 1) Configure environment variables

```bash
cp env/*.example env/
./scripts/maintenance/download-docling-models.sh
# remove .example suffix from copied files
nano env/db.env
nano env/ollama.env
nano env/openwebui.env
```

> Config structure optimized (Aug 2025); duplicates removed, naming
> standardized.

### 2) SSL certificates

```bash
./conf/ssl/generate-ssl-certs.sh
# or place your own cert/key
cp your-cert.pem conf/ssl/cert.pem
cp your-key.pem conf/ssl/key.pem
```

### 3) Cloudflare Tunnel (optional)

```bash
nano env/cloudflared.env
echo "TUNNEL_TOKEN=your_tunnel_token_here" >> env/cloudflared.env
```

### 4) Start the stack

```bash
./scripts/setup/create-networks.sh
docker compose up -d
docker compose ps
```

## 🎯 GPU setup for Ollama

### 1) Check GPU

```bash
nvidia-smi
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

### 2) Enable GPU for Ollama

```bash
./scripts/setup/gpu-setup.sh
nano env/ollama.env  # set OLLAMA_GPU_ENABLED=true
```

### 3) Verify GPU in Ollama

```bash
./scripts/performance/gpu-performance-test.sh
./scripts/performance/gpu-monitor.sh
```

## 📊 Monitoring setup (Updated 2025-09-19)

### Deploy monitoring

```bash
./scripts/setup/deploy-monitoring-system.sh
./scripts/performance/monitoring-system-status.sh
for port in 9101 9187 9121 9445 9115 9778 9113 9808; do
  echo "Port $port: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/metrics)"
done
curl -s http://localhost:9095/health  # webhook receiver
```

### Monitoring UIs

- **Grafana:** http://localhost:3000 (admin/admin)
- **Prometheus:** http://localhost:9091
- **Alertmanager:** http://localhost:9093
- **Loki:** http://localhost:3100 (header `X-Scope-OrgID: erni-ki`)
- **Exporters:** node 9101, postgres 9187, redis 9121, nvidia 9445, blackbox
  9115, ollama 9778, nginx 9113, rag 9808
- **Fluent Bit metrics:** http://localhost:2020/api/v1/metrics/prometheus

### Exporter checks

```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep exporter
for port in 9101 9187 9121 9445 9115 9778 9113 9808; do
  status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/metrics)
  echo "Port $port: $status"
done
curl -s http://localhost:9101/metrics | grep node_up
curl -s http://localhost:9187/metrics | grep pg_up
curl -s http://localhost:9121/metrics | head -5
curl -s http://localhost:9445/metrics | grep nvidia_gpu_utilization
curl -s http://localhost:9115/metrics | grep probe_success
curl -s http://localhost:9778/metrics | grep ollama_models_total
curl -s http://localhost:9113/metrics | grep nginx_connections_active
curl -s http://localhost:9808/metrics | grep erni_ki_rag_response
```

## 🚀 Production DB optimizations

```bash
# PostgreSQL tuning
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET shared_buffers = '256MB';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET max_connections = 200;"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET wal_buffers = '16MB';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET maintenance_work_mem = '64MB';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET autovacuum_max_workers = 4;"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET autovacuum_naptime = '15s';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET autovacuum_vacuum_threshold = 25;"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET log_connections = 'on';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET log_min_duration_statement = '100ms';"
```

### RAG monitoring

- `rag-exporter` (port 9808) metrics:
  - `erni_ki_rag_response_latency_seconds` (histogram)
  - `erni_ki_rag_sources_count` (sources per response)
- Set `RAG_TEST_URL` in `compose.yml` for real endpoint checks.
- Grafana OpenWebUI dashboard includes p95 < 2s and Sources Count panels.

### Hot reload Prometheus/Alertmanager

```bash
curl -X POST http://localhost:9091/-/reload
curl -X POST http://localhost:9093/-/reload
```

## 💾 Backup setup

```bash
./scripts/setup/setup-backrest-integration.sh
./scripts/backup/check-local-backup.sh
./scripts/setup/setup-cron-rotation.sh
```

## 🔒 Security hardening

```bash
./scripts/security/security-hardening.sh
./scripts/security/security-monitor.sh
```

## 🌐 Access

- **OpenWebUI:** https://your-domain/
- **Grafana:** https://your-domain/grafana (incl. Loki via Explore)

### First login

1. Open https://your-domain/
2. Create first user
3. Configure models in Ollama
4. Verify integrations

## 🔧 Troubleshooting

```bash
docker compose logs -f
docker compose restart service-name
./scripts/troubleshooting/automated-recovery.sh
./scripts/troubleshooting/test-healthcheck.sh   # GPU checks
nvidia-smi
```

## 📞 Support

- Docs:
  [Troubleshooting Guide](../operations/troubleshooting/troubleshooting-guide.md)
- Issues: https://github.com/DIZ-admin/erni-ki/issues
- Discussions: https://github.com/DIZ-admin/erni-ki/discussions
