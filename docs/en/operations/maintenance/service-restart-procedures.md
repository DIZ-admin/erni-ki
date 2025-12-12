---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Service Restart Procedures

[TOC]

**Version:** 1.0 **Created:** 2025-09-25 **Last Updated:** 2025-09-25 **Owner:**
Tech Lead

---

## GENERAL PRINCIPLES

### **Before restarting ALWAYS:**

1. **Create backup** of current configurations 2. **Check status** of dependent
   services 3. **Notify users** about planned maintenance 4. **Prepare rollback
   plan** in case of problems

### **Restart order (critically important):**

1. **Monitoring services** (Exporters, Fluent-bit) 2. **Infrastructure
   services** (Redis, PostgreSQL) 3. **AI services** (Ollama, LiteLLM) 4.
   **Critical services** (OpenWebUI, Nginx)

---

## EMERGENCY RESTART (CRITICAL ISSUES)

### **Full system restart**

```bash
# 1. Create emergency backup
BACKUP_DIR=".config-backup/emergency-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp -r env/ conf/ compose.yml "$BACKUP_DIR/"

# 2. Stop all services
docker compose down

# 3. Clean logs (optional)
docker system prune -f --volumes

# 4. Start system
docker compose up -d

# 5. Check status
docker compose ps
docker compose logs --tail=50
```

## **Critical service restart**

```bash
# OpenWebUI (main interface)
docker compose restart openwebui
docker compose logs openwebui --tail=20

# Nginx (reverse proxy)
docker compose restart nginx
docker compose logs nginx --tail=20

# PostgreSQL (database)
docker compose restart db
docker compose logs db --tail=20
```

---

## PLANNED SERVICE RESTART

### **1. AUXILIARY SERVICES (low priority)**

#### **EdgeTTS (Text-to-Speech)**

```bash
# Check status
docker compose ps edgetts
curl -f http://localhost:5050/health || echo "EdgeTTS unavailable"

# Restart
docker compose restart edgetts

# Check after restart
sleep 10
docker compose logs edgetts --tail=10
curl -f http://localhost:5050/health && echo "EdgeTTS restored"
```

## **Apache Tika (documents)**

```bash
# Check status
docker compose ps tika
curl -f http://localhost:9998/tika || echo "Tika unavailable"

# Restart
docker compose restart tika

# Check after restart
sleep 15
docker compose logs tika --tail=10
curl -f http://localhost:9998/tika && echo "Tika restored"
```

```bash
# Check status

# Restart

# Check after restart
sleep 20
```

## **2. MONITORING SERVICES**

### **Prometheus (metrics)**

```bash
# Check configuration
docker exec erni-ki-prometheus promtool check config /etc/prometheus/prometheus.yml

# Restart
docker compose restart prometheus

# Check after restart
sleep 10
curl -f http://localhost:9090/-/healthy && echo "Prometheus restored"
```

## **Grafana (dashboards)**

```bash
# Restart
docker compose restart grafana

# Check after restart
sleep 15
curl -f http://localhost:3000/api/health && echo "Grafana restored"
```

## **3. INFRASTRUCTURE SERVICES**

### **Redis (cache)**

```bash
# Check status
docker exec erni-ki-redis-1 redis-cli -a $REDIS_PASSWORD ping

# Restart
docker compose restart redis

# Check after restart
sleep 5
docker exec erni-ki-redis-1 redis-cli -a $REDIS_PASSWORD ping
```

## **PostgreSQL (database)**

```bash
# WARNING: Critical service! Notify users!

# Check status
docker exec erni-ki-db-1 pg_isready -U postgres

# Create database backup
docker exec erni-ki-db-1 pg_dump -U postgres openwebui > backup-$(date +%Y%m%d-%H%M%S).sql

# Restart
docker compose restart db

# Check after restart
sleep 10
docker exec erni-ki-db-1 pg_isready -U postgres
```

## **4. AI SERVICES**

### **Ollama (LLM server)**

```bash
# WARNING: GPU service! Check NVIDIA drivers!

# Check GPU
nvidia-smi

# Check Ollama status
curl -f http://localhost:11434/api/tags || echo "Ollama unavailable"

# Restart
docker compose restart ollama

# Check after restart (may take up to 60 seconds)
sleep 30
curl -f http://localhost:11434/api/tags && echo "Ollama restored"

# Check GPU usage
docker exec erni-ki-ollama-1 nvidia-smi
```

## **LiteLLM (AI Gateway)**

```bash
# Check status
curl -f http://localhost:4000/health || echo "LiteLLM unavailable"

# Restart
docker compose restart litellm

# Check after restart
sleep 15
curl -f http://localhost:4000/health && echo "LiteLLM restored"
```

## **5. CRITICAL SERVICES**

### **OpenWebUI (main interface)**

```bash
# WARNING: Main user interface!

# Check dependencies
docker compose ps db redis ollama

# Restart
docker compose restart openwebui

# Check after restart
sleep 20
curl -f http://localhost:8080/health && echo "OpenWebUI restored"

# Check through nginx
curl -f http://localhost/health && echo "OpenWebUI accessible through nginx"
```

## **Nginx (reverse proxy)**

```bash
# WARNING: Critical service for external access!

# Check configuration
docker exec erni-ki-nginx-1 nginx -t

# Restart
docker compose restart nginx

# Check after restart
sleep 5
curl -I http://localhost && echo "Nginx restored"
curl -I https://localhost && echo "HTTPS working"
```

---

## POST-RESTART VERIFICATION

### **Automatic check of all services**

```bash
# !/bin/bash
# System health check script after restart

echo "=== SERVICE STATUS CHECK ==="
docker compose ps

echo -e "\n=== CRITICAL ENDPOINTS CHECK ==="
curl -f http://localhost/health && echo " OpenWebUI accessible" || echo " OpenWebUI unavailable"
curl -f http://localhost:11434/api/tags && echo " Ollama working" || echo " Ollama unavailable"
curl -f http://localhost:9090/-/healthy && echo " Prometheus working" || echo " Prometheus unavailable"

echo -e "\n=== EXTERNAL ACCESS CHECK ==="
curl -s -I https://ki.erni-gruppe.ch/health | head -1 && echo " External access working" || echo " External access unavailable"

echo -e "\n=== GPU CHECK ==="
docker exec erni-ki-ollama-1 nvidia-smi | grep "NVIDIA-SMI" && echo " GPU available" || echo " GPU unavailable"

echo -e "\n=== ERROR LOG CHECK ==="
docker compose logs --tail=100 | grep -i error | tail -5
```

---

## PROBLEM ESCALATION

### **Level 1: Automatic recovery**

- Simple service restart
- Log review
- Basic diagnostics

### **Level 2: Manual intervention**

- Configuration analysis
- Dependency check
- Rollback to previous version

### **Level 3: Critical escalation**

- Full restore from backup
- Contact Tech Lead
- Incident documentation

---

## RELATED DOCUMENTS

- [Troubleshooting](../troubleshooting/index.md)
- [System Architecture](../../architecture/architecture.md)

---

_Document created as part of ERNI-KI configuration optimization 2025-09-25_
