---
language: en
translation_status: complete
doc_version: '2025.11'
title: 'Installation Guide'
system_status: 'Production Ready'
---

# Installation Guide

Comprehensive guide for deploying the ERNI-KI AI Platform.

## Prerequisites

### Minimum Requirements

- **OS**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- **CPU**: 4 cores (AVX2 support recommended)
- **RAM**: 16GB (32GB+ for production)
- **Storage**: 100GB SSD
- **GPU**: NVIDIA GPU (8GB+ VRAM) for local LLM inference (optional but
  recommended)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
```

### 2. Setup Environment

```bash
# Copy example env files
for f in env/*.example; do cp "$f" "${f%.example}.env"; done

# Download Docling models (OCR)
./scripts/maintenance/download-docling-models.sh
```

### 3. Launch System

```bash
docker compose up -d
```

Access the application at `http://localhost:8080`.

## Detailed Installation

### 1. Docker Installation

Ensure Docker and Docker Compose v2 are installed.

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Compose Plugin
sudo apt update && sudo apt install docker-compose-plugin
```

### 2. GPU Setup (NVIDIA)

Required for local LLM inference acceleration.

```bash
# Install NVIDIA Container Toolkit
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Verify GPU availability:

```bash
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

### 3. Monitoring Setup

The system includes a full Prometheus/Grafana stack.

```bash
# Check status
./scripts/performance/monitoring-system-status.sh
```

**Dashboards:**

- Grafana: `http://localhost:3000` (admin/admin)
- Prometheus: `http://localhost:9091`

## Configuration

### Core Configuration

Edit the `.env` files in `env/` directory:

- `openwebui.env`: Frontend settings.
- `ollama.env`: Model and GPU settings.
- `db.env`: Database credentials.

### SSL & Networking

- **SSL**: Place certificates in `conf/ssl/` (`cert.pem`, `key.pem`) or use the
  generator script `./conf/ssl/generate-ssl-certs.sh`.
- **Cloudflare**: Configure tunnel token in `env/cloudflared.env`.

## Troubleshooting

### Common Issues

- **GPU not found**: Check `nvidia-smi` and Docker runtime config.
- **Port conflicts**: Ensure ports 80, 443, 8080, 3000 are free.

### Diagnostic Tools

```bash
# Health check
./scripts/maintenance/health-check.sh

# GPU monitor
./scripts/performance/gpu-monitor.sh
```
