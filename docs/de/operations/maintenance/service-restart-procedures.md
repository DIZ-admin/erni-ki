---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Service-Neustartverfahren

[TOC]

**Version:** 1.0 **Erstellungsdatum:** 2025-09-25 **Zuletzt aktualisiert:**
2025-09-25 **Verantwortlich:** Tech Lead

---

## ALLGEMEINE PRINZIPIEN

### **Vor dem Neustart IMMER:**

1. **Backup erstellen** der aktuellen Konfigurationen
2. **Status prüfen** der abhängigen Dienste
3. **Benutzer benachrichtigen** über geplante Wartungsarbeiten
4. **Rollback-Plan vorbereiten** für den Fall von Problemen

### **Neustart-Reihenfolge (kritisch wichtig):**

1. **Monitoring Services** (Exporters, Fluent-bit)
2. **Infrastructure Services** (Redis, PostgreSQL)
3. **AI Services** (Ollama, LiteLLM)
4. **Critical Services** (OpenWebUI, Nginx)

---

## NOTFALL-NEUSTART (KRITISCHE PROBLEME)

### **Vollständiger Systemneustart**

```bash
# 1. Notfall-Backup erstellen
BACKUP_DIR=".config-backup/emergency-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp -r env/ conf/ compose.yml "$BACKUP_DIR/"

# 2. Alle Dienste stoppen
docker compose down

# 3. Logs bereinigen (optional)
docker system prune -f --volumes

# 4. System starten
docker compose up -d

# 5. Status prüfen
docker compose ps
docker compose logs --tail=50
```

## **Neustart kritischer Dienste**

```bash
# OpenWebUI (Hauptschnittstelle)
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

## GEPLANTER SERVICE-NEUSTART

### **1. AUXILIARY SERVICES (niedrige Priorität)**

#### **EdgeTTS (Text-to-Speech)**

```bash
# Status prüfen
docker compose ps edgetts
curl -f http://localhost:5050/health || echo "EdgeTTS nicht verfügbar"

# Neustart
docker compose restart edgetts

# Prüfung nach Neustart
sleep 10
docker compose logs edgetts --tail=10
curl -f http://localhost:5050/health && echo "EdgeTTS wiederhergestellt"
```

## **Apache Tika (Dokumente)**

```bash
# Status prüfen
docker compose ps tika
curl -f http://localhost:9998/tika || echo "Tika nicht verfügbar"

# Neustart
docker compose restart tika

# Prüfung nach Neustart
sleep 15
docker compose logs tika --tail=10
curl -f http://localhost:9998/tika && echo "Tika wiederhergestellt"
```

## **2. MONITORING SERVICES**

### **Prometheus (Metriken)**

```bash
# Konfiguration prüfen
docker exec erni-ki-prometheus promtool check config /etc/prometheus/prometheus.yml

# Neustart
docker compose restart prometheus

# Prüfung nach Neustart
sleep 10
curl -f http://localhost:9090/-/healthy && echo "Prometheus wiederhergestellt"
```

## **Grafana (Dashboards)**

```bash
# Neustart
docker compose restart grafana

# Prüfung nach Neustart
sleep 15
curl -f http://localhost:3000/api/health && echo "Grafana wiederhergestellt"
```

## **3. INFRASTRUCTURE SERVICES**

### **Redis (Cache)**

```bash
# Status prüfen
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ping

# Neustart
docker compose restart redis

# Prüfung nach Neustart
sleep 5
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ping
```

## **PostgreSQL (Datenbank)**

```bash
# ACHTUNG: Kritischer Dienst! Benutzer benachrichtigen!

# Status prüfen
docker exec erni-ki-db-1 pg_isready -U postgres

# DB-Backup erstellen
docker exec erni-ki-db-1 pg_dump -U postgres openwebui > backup-$(date +%Y%m%d-%H%M%S).sql

# Neustart
docker compose restart db

# Prüfung nach Neustart
sleep 10
docker exec erni-ki-db-1 pg_isready -U postgres
```

## **4. AI SERVICES**

### **Ollama (LLM Server)**

```bash
# ACHTUNG: GPU-Dienst! NVIDIA-Treiber prüfen!

# GPU prüfen
nvidia-smi

# Ollama-Status prüfen
curl -f http://localhost:11434/api/tags || echo "Ollama nicht verfügbar"

# Neustart
docker compose restart ollama

# Prüfung nach Neustart (kann bis zu 60 Sekunden dauern)
sleep 30
curl -f http://localhost:11434/api/tags && echo "Ollama wiederhergestellt"

# GPU-Nutzung prüfen
docker exec erni-ki-ollama-1 nvidia-smi
```

## **LiteLLM (AI Gateway)**

```bash
# Status prüfen
curl -f http://localhost:4000/health || echo "LiteLLM nicht verfügbar"

# Neustart
docker compose restart litellm

# Prüfung nach Neustart
sleep 15
curl -f http://localhost:4000/health && echo "LiteLLM wiederhergestellt"
```

## **5. CRITICAL SERVICES**

### **OpenWebUI (Hauptschnittstelle)**

```bash
# ACHTUNG: Hauptbenutzeroberfläche!

# Abhängigkeiten prüfen
docker compose ps db redis ollama

# Neustart
docker compose restart openwebui

# Prüfung nach Neustart
sleep 20
curl -f http://localhost:8080/health && echo "OpenWebUI wiederhergestellt"

# Prüfung über Nginx
curl -f http://localhost/health && echo "OpenWebUI über Nginx verfügbar"
```

## **Nginx (Reverse Proxy)**

```bash
# ACHTUNG: Kritischer Dienst für externen Zugriff!

# Konfiguration prüfen
docker exec erni-ki-nginx-1 nginx -t

# Neustart
docker compose restart nginx

# Prüfung nach Neustart
sleep 5
curl -I http://localhost && echo "Nginx wiederhergestellt"
curl -I https://localhost && echo "HTTPS funktioniert"
```

---

## PRÜFUNG NACH NEUSTART

### **Automatische Überprüfung aller Dienste**

```bash
# !/bin/bash
# Skript zur Überprüfung des Systemzustands nach Neustart

echo "=== STATUSPRÜFUNG DER DIENSTE ==="
docker compose ps

echo -e "\n=== PRÜFUNG KRITISCHER ENDPUNKTE ==="
curl -f http://localhost/health && echo " OpenWebUI verfügbar" || echo " OpenWebUI nicht verfügbar"
curl -f http://localhost:11434/api/tags && echo " Ollama läuft" || echo " Ollama nicht verfügbar"
curl -f http://localhost:9090/-/healthy && echo " Prometheus läuft" || echo " Prometheus nicht verfügbar"

echo -e "\n=== PRÜFUNG DES EXTERNEN ZUGRIFFS ==="
curl -s -I https://ki.erni-gruppe.ch/health | head -1 && echo " Externer Zugriff funktioniert" || echo " Externer Zugriff nicht verfügbar"

echo -e "\n=== GPU-PRÜFUNG ==="
docker exec erni-ki-ollama-1 nvidia-smi | grep "NVIDIA-SMI" && echo " GPU verfügbar" || echo " GPU nicht verfügbar"

echo -e "\n=== LOG-PRÜFUNG AUF FEHLER ==="
docker compose logs --tail=100 | grep -i error | tail -5
```

---

## ESKALATION VON PROBLEMEN

### **Level 1: Automatische Wiederherstellung**

- Einfacher Neustart des Dienstes
- Log-Prüfung
- Basis-Diagnose

### **Level 2: Manuelles Eingreifen**

- Analyse der Konfigurationen
- Prüfung der Abhängigkeiten
- Rollback auf vorherige Version

### **Level 3: Kritische Eskalation**

- Vollständige Wiederherstellung aus Backup
- Kontakt mit Tech Lead
- Dokumentation des Vorfalls

---

## VERWANDTE DOKUMENTE

- [Troubleshooting Guide](../troubleshooting/troubleshooting-guide.md)
- [Configuration Change Process](../core/configuration-change-process.md)
- [Backup Restore Procedures](backup-restore-procedures.md)
- [System Architecture](../../architecture/architecture.md)

---

_Dokument erstellt im Rahmen der Konfigurationsoptimierung ERNI-KI 2025-09-25_
