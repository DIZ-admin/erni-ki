---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# 🔄 Verfahren zum Neustart der ERNI-KI-Services

**Version:** 1.0  
**Erstellt:** 2025-09-25  
**Zuletzt aktualisiert:** 2025-09-25  
**Verantwortlich:** Tech Lead

---

## 📋 Grundsätze

### ✅ Vor jedem Neustart

1. Backup der aktuellen Konfigurationen erstellen
2. Status abhängiger Services prüfen
3. Nutzer über Wartung informieren
4. Rollback-Plan bereithalten

### ⚠️ Reihenfolge (kritisch)

1. Monitoring-Services (Exporter, Fluent Bit)
2. Infrastruktur (Redis, PostgreSQL)
3. AI-Services (Ollama, LiteLLM)
4. Kritische Services (OpenWebUI, Nginx)

---

## 🚨 Notfall-Neustart (kritische Probleme)

### Vollständiger Neustart

```bash
BACKUP_DIR=".config-backup/emergency-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp -r env/ conf/ compose.yml "$BACKUP_DIR/"

docker compose down
docker system prune -f --volumes   # optional
docker compose up -d

docker compose ps
docker compose logs --tail=50
```

### Neustart kritischer Services

```bash
# OpenWebUI (UI)
docker compose restart openwebui
docker compose logs openwebui --tail=20

# Nginx (Reverse Proxy)
docker compose restart nginx
docker compose logs nginx --tail=20

# PostgreSQL (Datenbank)
docker compose restart db
docker compose logs db --tail=20
```

---

## 🔧 Geplanter Neustart

### 1) Auxiliary-Services

**EdgeTTS (Text-to-Speech)**

```bash
docker compose ps edgetts
curl -f http://localhost:5050/health || echo "EdgeTTS down"
docker compose restart edgetts
sleep 10
docker compose logs edgetts --tail=10
curl -f http://localhost:5050/health && echo "EdgeTTS ok"
```

**Apache Tika (Dokumente)**

```bash
docker compose ps tika
curl -f http://localhost:9998/tika || echo "Tika down"
docker compose restart tika
sleep 15
docker compose logs tika --tail=10
curl -f http://localhost:9998/tika && echo "Tika ok"
```

### 2) Monitoring-Services

**Prometheus**

```bash
docker exec erni-ki-prometheus promtool check config /etc/prometheus/prometheus.yml
docker compose restart prometheus
sleep 10
curl -f http://localhost:9090/-/healthy && echo "Prometheus ok"
```

**Grafana**

```bash
docker compose restart grafana
sleep 15
curl -f http://localhost:3000/api/health && echo "Grafana ok"
```

### 3) Infrastruktur

**Redis (Cache)**

```bash
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ping
docker compose restart redis
sleep 5
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ping
```

**PostgreSQL (DB)**

```bash
docker exec erni-ki-db-1 pg_isready -U postgres
docker exec erni-ki-db-1 pg_dump -U postgres openwebui > backup-$(date +%Y%m%d-%H%M%S).sql
docker compose restart db
sleep 10
docker exec erni-ki-db-1 pg_isready -U postgres
```

### 4) AI-Services

**Ollama (LLM)**

```bash
nvidia-smi                                 # GPU prüfen
curl -f http://localhost:11434/api/tags || echo "Ollama down"
docker compose restart ollama
sleep 30
curl -f http://localhost:11434/api/tags && echo "Ollama ok"
docker exec erni-ki-ollama-1 nvidia-smi   # GPU Nutzung prüfen
```

**LiteLLM (Gateway)**

```bash
curl -f http://localhost:4000/health || echo "LiteLLM down"
docker compose restart litellm
sleep 15
curl -f http://localhost:4000/health && echo "LiteLLM ok"
```

### 5) Kritische Services

**OpenWebUI**

```bash
docker compose ps db redis ollama
docker compose restart openwebui
sleep 20
curl -f http://localhost:8080/health && echo "OpenWebUI ok"
curl -f http://localhost/health && echo "OpenWebUI via nginx ok"
```

**Nginx (Reverse Proxy)**

```bash
docker exec erni-ki-nginx-1 nginx -t
docker compose restart nginx
sleep 5
curl -I http://localhost && echo "Nginx ok"
curl -I https://localhost && echo "HTTPS ok"
```

---

## 🔍 Checks nach dem Neustart

```bash
docker compose ps
curl -f http://localhost/health
curl -f http://localhost:11434/api/tags
curl -f http://localhost:9090/-/healthy
curl -s -I https://ki.erni-gruppe.ch/health | head -1
docker exec erni-ki-ollama-1 nvidia-smi | grep "NVIDIA-SMI"
docker compose logs --tail=100 | grep -i error | tail -5
```

---

## 📞 Eskalation

1. Automatische Wiederherstellung (Restart, Logs prüfen)
2. Manuelles Troubleshooting (Konfig, Abhängigkeiten, Rollback)
3. Vollständiges Restore aus Backup, Tech Lead informieren, Incident
   dokumentieren

---

## 📚 Verwandte Dokumente

- [Troubleshooting Guide](../troubleshooting/troubleshooting-guide.md)
- [Configuration Change Process](../core/configuration-change-process.md)
- [Backup Restore Procedures](backup-restore-procedures.md)
- [System Architecture](../../architecture/architecture.md)

---

_Dokument im Rahmen der Optimierung der ERNI-KI-Konfigurationen (25.09.2025)
erstellt._
