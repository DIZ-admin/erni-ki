---
language: en
translation_status: original
doc_version: '2025.11'
title: 'Installation'
system_version: '12.1'
last_updated: '2025-11-28'
system_status: 'Production Ready'
---

# Installation Guide - ERNI-KI

> **Version:**12.1**Updated:**2025-11-28**System Status:**Production Ready
> (Monitoring System: 5 provisioned Grafana dashboards, updated Prometheus)

[TOC]

## Overview

Detailed guide for installing and configuring the ERNI-KI system -
Production-Ready AI Platform with 29 microservices architecture and
enterprise-grade DB performance.

## Visualization: Installation Path

```mermaid
flowchart TD
 Prep[1. Environment Prep] --> Docker[2. Install Docker/Compose]
 Docker --> GPU[3. NVIDIA Toolkit (Optional)]
 GPU --> Env[4. Copy env/*.example]
 Env --> Up[5. docker compose up -d]
 Up --> Health[6. Check healthcheck & ports]
 Health --> Smoke[7. Smoke-tests OpenWebUI/LLM]
```

## System Requirements

### Minimum Requirements

-**OS:**Linux (Ubuntu 20.04+ / CentOS 8+ / Debian 11+) -**CPU:**4 cores (8+
recommended) -**RAM:**16GB (optimized for PostgreSQL and
Redis) -**Storage:**100GB free space (SSD recommended) -**Network:**Stable
internet connection -**System Settings:**vm.overcommit_memory=1 (for Redis)

### Recommended Requirements (Production)

-**CPU:**8+ cores with AVX2 support -**RAM:**32GB+ (PostgreSQL: 256MB
shared_buffers, Redis: 2GB limit) -**GPU:**NVIDIA GPU with 8GB+ VRAM (for Ollama
GPU acceleration) -**Storage:**500GB+ NVMe SSD -**Network:**1Gbps+ for fast
model downloads -**Monitoring:**Prometheus + Grafana + 8 Exporters (optimized
2025-09-19)

- Additional: ~2GB RAM for full monitoring stack
- Ports: 9101, 9187, 9121, 9445, 9115, 9778, 9113, 9808

## Preliminary Setup

### 1. Install Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Reboot to apply changes
sudo reboot
```

### 2. Install Docker Compose v2

```bash
# Install Docker Compose v2
sudo apt update
sudo apt install docker-compose-plugin

# Check version
docker compose version
```

### 3. Configure NVIDIA Container Toolkit (for GPU)

```bash
# Add NVIDIA repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-container-toolkit
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker
```

## New Components (v7.0)

### LiteLLM Context Engineering

-**Purpose:**Unified API for various LLM providers -**Context7
Integration:**Improved context for AI
responses -**Port:**4000 -**Configuration:**`env/litellm.env`,
`conf/litellm/config.yaml`

### Docling OCR

-**Purpose:**Multilingual document processing with OCR -**Supported
Languages:**EN, DE, FR, IT -**Port:**5001

### Monitoring System (Current State)

-**5 Grafana dashboards (provisioned)**-**Updated Prometheus queries with
fallback values**-**Dashboard load time <3 seconds**-**Request success
rate >85%**

## Quick Installation

### 1. Clone Repository

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
```

### 2. Run Setup Script

```bash
# Interactive setup
./scripts/setup/setup.sh

# Or quick start with default settings
./scripts/setup/quick-start.sh
```

### 3. Verify Installation

```bash
# Check status of all services
./scripts/maintenance/health-check.sh

# Check web interfaces
./scripts/maintenance/check-web-interfaces.sh
```

## Manual Installation

### 1. Configure Environment Variables

```bash
# Copy example configurations (optimized structure)
cp env/*.example env/
# Download Docling models once (OCR)
./scripts/maintenance/download-docling-models.sh
# Remove .example extension from copied files

# Edit main settings
nano env/db.env
nano env/ollama.env
nano env/openwebui.env
```

> ℹ**Info:**Configuration structure optimized (August 2025). All duplicate
> configurations removed, naming convention standardized.

### 2. Configure SSL Certificates

```bash
# Generate self-signed certificates (for testing)
./conf/ssl/generate-ssl-certs.sh

# Or place your own certificates
cp your-cert.pem conf/ssl/cert.pem
cp your-key.pem conf/ssl/key.pem
```

### 3. Configure Cloudflare Tunnel (Optional)

```bash
# Configure cloudflared
nano env/cloudflared.env

# Add tunnel token
echo "TUNNEL_TOKEN=your_tunnel_token_here" >> env/cloudflared.env
```

### 4. Start System

```bash
# Create Docker networks
./scripts/setup/create-networks.sh

# Start all services
docker compose up -d

# Check status
docker compose ps
```

## Configure GPU for Ollama

### 1. Check GPU

```bash
# Check GPU availability
nvidia-smi

# Test GPU in Docker
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

### 2. Configure Ollama for GPU

```bash
# Run GPU setup script
./scripts/setup/gpu-setup.sh

# Or manual configuration
nano env/ollama.env
# Add: OLLAMA_GPU_ENABLED=true
```

### 3. Verify GPU in Ollama

```bash
# Check GPU usage
./scripts/performance/gpu-performance-test.sh

# Monitor GPU
./scripts/performance/gpu-monitor.sh
```

## Monitoring Setup (Updated 2025-09-19)

### 1. Deploy Monitoring System

```bash
# Automatic setup
./scripts/setup/deploy-monitoring-system.sh

# Check monitoring status
./scripts/performance/monitoring-system-status.sh

# Check all 8 exporters (optimized)
for port in 9101 9187 9121 9445 9115 9778 9113 9808; do
 echo "Port $port: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/metrics)"
done

# Check webhook-receiver
curl -s http://localhost:9095/health
```

### 2. Access Monitoring Interfaces

**Core Services:**

-**Grafana:**<http://localhost:3000>
(admin/admin) -**Prometheus:**<http://localhost:9091> -**AlertManager:**<http://localhost:9093> -**Loki:**<http://localhost:3100>
(use header `X-Scope-OrgID: erni-ki`)

**8 Exporters (Standardized and Optimized):**

-**Node Exporter:**<http://localhost:9101/metrics> - system
metrics -**PostgreSQL Exporter:**<http://localhost:9187/metrics> - DB
metrics -**Redis Exporter:**<http://localhost:9121/metrics> - cache metrics (TCP
healthcheck) -**NVIDIA GPU Exporter:**<http://localhost:9445/metrics> - GPU
metrics (improved) -**Blackbox Exporter:**<http://localhost:9115/metrics> -
availability monitoring -**Ollama AI
Exporter:**<http://localhost:9778/metrics> - AI metrics (standardized) -**Nginx
Web Exporter:**<http://localhost:9113/metrics> - web server metrics (TCP
healthcheck) -**RAG SLA Exporter:**<http://localhost:9808/metrics> - RAG
performance metrics

**Additional Services:**

-**Webhook Receiver:**<http://localhost:9095/health> -**Fluent Bit (Prometheus
format):**<http://localhost:2020/api/v1/metrics/prometheus>

> ℹ**Info:**For external access use domain ki.erni-gruppe.ch

### 3. Verify Exporters Health (New 2025-09-19)

```bash
# Check status of all exporters
docker ps --format "table {{.Names}}\t{{.Status}}" | grep exporter

# Check Docker healthcheck status
docker inspect erni-ki-redis-exporter erni-ki-nginx-exporter erni-ki-nvidia-exporter --format='{{.Name}}: {{.State.Health.Status}}'

# Check metrics availability (all should return 200)
for port in 9101 9187 9121 9445 9115 9778 9113 9808; do
 status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/metrics)
 echo "Port $port: $status"
done
```

## 4. Configure GPU Monitoring

```bash
# Check NVIDIA GPU Exporter (improved with TCP healthcheck)
curl -s http://localhost:9445/metrics | grep nvidia_gpu

# Check GPU dashboard in Grafana
# Open: http://localhost:3000/d/gpu-monitoring

# Check GPU availability in container
docker exec erni-ki-nvidia-exporter nvidia-smi
```

## 5. Monitoring Troubleshooting

```bash
# If exporter shows <nil> healthcheck status
# Issue: wget/curl unavailable in minimal containers
# Solution: TCP checks are used

# Check TCP healthcheck manually
timeout 5 sh -c '</dev/tcp/localhost/9121' && echo "Redis Exporter available"
timeout 5 sh -c '</dev/tcp/localhost/9113' && echo "Nginx Exporter available"

# Restart problematic exporters
docker restart erni-ki-redis-exporter erni-ki-nginx-exporter

# Check logs
docker logs erni-ki-redis-exporter --tail 10
docker logs erni-ki-nginx-exporter --tail 10
```

## Production DB Optimizations (Recommended)

### 1. PostgreSQL Optimization

```bash
# Apply production PostgreSQL configuration
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET shared_buffers = '256MB';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET max_connections = 200;"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET wal_buffers = '16MB';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET maintenance_work_mem = '64MB';"

# Configure aggressive autovacuum
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET autovacuum_max_workers = 4;"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET autovacuum_naptime = '15s';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET autovacuum_vacuum_threshold = 25;"

# Enable logging
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET log_connections = 'on';"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "ALTER SYSTEM SET log_min_duration_statement = '100ms';"
```

### 2. Redis Optimization

```bash
# Configure memory limits
docker exec erni-ki-redis-1 redis-cli CONFIG SET maxmemory 2gb
docker exec erni-ki-redis-1 redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Fix memory overcommit warning
sudo sysctl vm.overcommit_memory=1
echo 'vm.overcommit_memory = 1' | sudo tee -a /etc/sysctl.conf
```

### 3. Verify Optimizations

```bash
# Check PostgreSQL settings
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "SHOW shared_buffers;"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "SHOW max_connections;"

# Check Redis settings
docker exec erni-ki-redis-1 redis-cli CONFIG GET maxmemory
docker exec erni-ki-redis-1 redis-cli CONFIG GET maxmemory-policy

# Check performance
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "
SELECT round(sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100, 2) as cache_hit_ratio_percent
FROM pg_statio_user_tables;"
```

**Expected Results:**

- PostgreSQL cache hit ratio: >95%
- Redis memory usage: <10% of limit
- DB response time: <100ms
- No warnings in logs

## Backup Setup

### 1. Configure Backrest

```bash
# Automatic setup
./scripts/setup/setup-backrest-integration.sh

# Check backup
./scripts/backup/check-local-backup.sh
```

### 2. Configure Backup Schedule

```bash
# Configure cron for automatic backups
./scripts/setup/setup-cron-rotation.sh
```

## Security Setup

### 1. Security Hardening

```bash
# Apply security hardening
./scripts/security/security-hardening.sh

# Configure security monitoring
./scripts/security/security-monitor.sh
```

### 2. Configure Firewall

```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## System Access

### Main Interfaces

-**OpenWebUI:**<https://your-domain/> (main
interface) -**Grafana:**<https://your-domain/grafana> (monitoring) -**Grafana
Explore (Loki):**<https://your-domain/grafana> →**Explore**tab

### First Login

1. Open <https://your-domain/>
2. Create first user
3. Configure models in Ollama
4. Check integrations

## Troubleshooting

### Common Issues

```bash
# Check logs
docker compose logs -f

# Restart problematic services
docker compose restart service-name

# Full diagnostics
./scripts/troubleshooting/automated-recovery.sh
```

### GPU Issues

```bash
# GPU Diagnostics
./scripts/troubleshooting/test-healthcheck.sh

# Check NVIDIA drivers
nvidia-smi
```

## Support

-**Documentation:**
[docs/operations/troubleshooting/troubleshooting-guide.md](../../operations/troubleshooting/troubleshooting-guide.md) -**Issues:**[GitHub Issues](https://github.com/DIZ-admin/erni-ki/issues) -**Discussions:**
[GitHub Repository](https://github.com/DIZ-admin/erni-ki)

## Important Updates

### August 2025 - Version 5.0

**Post-installation Fixes:**

1.**SearXNG RAG Integration**- if search is not working:

```bash
# Check SearXNG status
docker logs erni-ki-searxng-1 --tail 20

# If CAPTCHA errors from DuckDuckGo - already fixed in configuration
# Active engines: Startpage, Brave, Bing
```

2.**Backrest API**- use correct endpoints:

```bash
# Correct JSON RPC endpoints
curl -X POST 'http://localhost:9898/v1.Backrest/GetOperations' \
--data '{}' -H 'Content-Type: application/json'
```

3.**Ollama Models**- 6 models available including qwen2.5-coder:1.5b

---

> ℹ**Info:**This guide is updated for 20+ services architecture of ERNI-KI
> version 5.0.
