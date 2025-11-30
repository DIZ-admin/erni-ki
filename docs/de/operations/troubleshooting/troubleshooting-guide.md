---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Leitfaden zur Problemdiagnose ERNI-KI

> **Version:**1.0**Datum:**25.09.2025**Status:**Production Ready [TOC]

## 1. Einführung

Dieses Handbuch beschreibt die Diagnose und Behebung von Störungen in ERNI-KI.
Es unterscheidet kritische Incidents (sofortiges Eingreifen) und häufige
Probleme.

## 2. Voraussetzungen

Für wirksame Diagnose benötigt man:

-**Zugriff:**SSH (`sudo`), Grafana, Portainer. -**Tools:**`docker`, `curl`,
`nc`, `htop`, `nvidia-smi`. -**Logs:**Zugriff via `docker logs` oder
Grafana/Loki.

## 3. Diagnose-Anleitungen

### 3.1 Kritische Probleme (SLA < 15 Min)

### **Gesamtsystem nicht erreichbar**

#### **Symptome:**

- Externe Domains antworten nicht (ki.erni-gruppe.ch, webui.diz.zone)
- Lokaler Zugriff <http://localhost> nicht erreichbar
- Viele Container "unhealthy" oder "exited"

#### **Diagnose:**

```bash
# 1. Service-Status
docker compose ps

# 2. Systemressourcen
df -h # Plattenplatz
free -h # RAM
nvidia-smi # GPU

# 3. Docker
docker system df # Docker-Platzverbrauch
docker system events --since 1h # Events letzte Stunde
```

## **Lösung:**

```bash
# 1. Notfall-Neustart
docker compose down
docker compose up -d

# 2. Falls nicht hilft – Cleanup + Neustart
docker system prune -f
docker compose up -d --force-recreate

# 3. Letztes Mittel – vollständige Bereinigung
docker compose down -v
docker system prune -a -f
docker compose up -d
```

## **OpenWebUI nicht erreichbar (Haupt-UI)**

### **Symptome:**

- <http://localhost/health> liefert 502/503/504
- Nutzer können sich nicht anmelden
- DB-Verbindungsfehler

#### **Diagnose:**

```bash
# 1. OpenWebUI-Logs
docker compose logs openwebui --tail=50

# 2. Abhängigkeiten
docker compose ps db redis ollama

# 3. DB-Verbindung
docker exec erni-ki-db-1 pg_isready -U postgres

# 4. Redis
docker exec erni-ki-redis-1 redis-cli -a $REDIS_PASSWORD ping
```

## **Lösung:**

```bash
# 1. Abhängigkeiten neu starten
docker compose restart db redis

# 2. OpenWebUI neu starten
docker compose restart openwebui

# 3. Verfügbarkeit prüfen
sleep 30
curl -f http://localhost/health
```

---

## Häufige Probleme und Lösungen

### **GPU/AI Services**

#### **Problem: Ollama nutzt GPU nicht**

```bash
# Diagnose
nvidia-smi # GPU-Verfügbarkeit
docker exec erni-ki-ollama-1 nvidia-smi # GPU im Container

# Lösung
docker compose restart ollama
# GPU-Auslastung nach Modellstart prüfen
docker exec erni-ki-ollama-1 nvidia-smi
```

## **Problem: LiteLLM liefert 500**

```bash
# Diagnose
docker compose logs litellm --tail=30
curl -f http://localhost:4000/health

# Lösung
docker compose restart litellm
sleep 15
curl -f http://localhost:4000/health
```

## **Netzwerk**

### **Problem: Nginx 502 Bad Gateway**

```bash
# Diagnose
docker compose logs nginx --tail=20
docker exec erni-ki-nginx-1 nginx -t # Konfiguration prüfen

# Upstream-Checks
curl -f http://openwebui:8080/health # aus dem nginx-Container
curl -f http://localhost:8080/health # direkt

# Lösung
docker compose restart nginx
```

## **Problem: Cloudflare-Tunnel down**

```bash
# Diagnose
docker compose logs cloudflared --tail=20
docker exec erni-ki-cloudflared-1 nslookup nginx

# Lösung
docker compose restart cloudflared
```

## **Datenbank**

### **Problem: PostgreSQL connection refused**

```bash
# Diagnose
docker compose logs db --tail=30
docker exec erni-ki-db-1 pg_isready -U postgres

# Verbindungen prüfen
docker exec erni-ki-db-1 psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Lösung
docker compose restart db
sleep 10
docker exec erni-ki-db-1 pg_isready -U postgres
```

## **Problem: Redis connection timeout**

```bash
# Diagnose
docker compose logs redis --tail=20
docker exec erni-ki-redis-1 redis-cli -a $REDIS_PASSWORD info

# Lösung
docker compose restart redis
sleep 5
docker exec erni-ki-redis-1 redis-cli -a $REDIS_PASSWORD ping
```

## **Monitoring**

### **Problem: Prometheus sammelt keine Metriken**

```bash
# Diagnose
curl -f http://localhost:9090/api/v1/targets
docker compose logs prometheus --tail=20

# Lösung
docker exec erni-ki-prometheus promtool check config /etc/prometheus/prometheus.yml
docker compose restart prometheus
```

## **Problem: Grafana zeigt keine Daten**

```bash
# Diagnose
curl -f http://localhost:3000/api/health
docker compose logs grafana --tail=20

# Lösung
docker compose restart grafana
```

---

## 4. Verifikation & Werkzeuge

Nutzen Sie diese Kommandos zur Bestätigung der Fehlerbehebung und des
allgemeinen Systemzustands.

### Systemdiagnose

```bash
# Gesamtstatus
docker compose ps
docker stats --no-stream

# Ressourcennutzung
df -h
free -h
nvidia-smi

# Netzwerkdiagnose
docker network ls
docker network inspect erni-ki_default
```

## Log-Diagnose

```bash
# Fehler der letzten Stunde
docker compose logs --since 1h | grep -i error

# Kritische Fehler
docker compose logs --since 1h | grep -E "(FATAL|CRITICAL|ERROR)"

# Verbindungsprobleme
docker compose logs --since 1h | grep -E "(connection|timeout|refused)"

# GPU-Probleme
docker compose logs --since 1h | grep -E "(cuda|gpu|nvidia)"
```

## Konfiguration prüfen

```bash
# Nginx-Konfiguration
docker exec erni-ki-nginx-1 nginx -t

# Prometheus-Konfiguration
docker exec erni-ki-prometheus promtool check config /etc/prometheus/prometheus.yml

# Umgebungsvariablen
docker compose config | grep -A 5 -B 5 "environment:"
```

## 5. Verwandte Dokumentation

- [Admin Guide](../core/admin-guide.md)
- [Monitoring Guide](../monitoring/monitoring-guide.md)
- [Service Restart Procedures](../../../operations/maintenance/service-restart-procedures.md)
