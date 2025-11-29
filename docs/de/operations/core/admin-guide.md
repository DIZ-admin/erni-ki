---
language: de
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
title: '‍ ERNI-KI Administrator-Handbuch'
system_version: '12.1'
date: '2025-11-22'
system_status: 'Production Ready'
audience: 'administrators'
---

# ‍ ERNI-KI Administrator-Handbuch

> **Dokumentversion:**7.0**Aktualisierungsdatum:**2025-09-11**Zielgruppe:**
> Systemadministratoren (Optimiertes Nginx + Korrigierte APIs + Verbesserte
> Diagnose) [TOC]

## Überblick der administrativen Aufgaben

Als ERNI-KI Administrator sind Sie verantwortlich für:

- Überwachung des Status aller 15+ Services
- Benutzer- und Zugriffsverwaltung
- Backup-Konfiguration
- Systemsicherheit gewährleisten
- Performance und Skalierung
- Fehlerbehebung

## Kritische Updates (September 2025)

### Nginx-Optimierung und Korrekturen (11. September 2025)

#### Modulare Nginx-Architektur

-**Konfigurationsdeduplizierung**: 91 Zeilen doppelten Codes eliminiert
(-20%) -**Include-Dateien**: 4 wiederverwendbare Module erstellt

- `openwebui-common.conf` - gemeinsame OpenWebUI Proxy-Einstellungen
- `searxng-api-common.conf` - SearXNG API-Konfiguration
- `searxng-web-common.conf` - SearXNG Web-Interface
- `websocket-common.conf` - WebSocket Proxy-Einstellungen -**Map-Direktiven**:
  Bedingte Logik für verschiedene Ports -**Universelle Variablen**:
  `$universal_request_id` für alle Include-Dateien

#### HTTPS und CSP Korrekturen

-**Content Security Policy**: Für localhost und Production
optimiert -**CORS-Header**: Für Entwicklungs- und Produktionsumgebungen
erweitert -**SSL-Konfiguration**: `ssl_verify_client off` für localhost
hinzugefügt -**Kritische Fehler**: Skript-Ladefehler behoben

#### SearXNG API Wiederherstellung

-**Routing korrigiert**: 404-Fehler für `/api/searxng/search`
behoben -**RAG-Funktionalität**: Vollständig für OpenWebUI
wiederhergestellt -**Performance**: Antwortzeit <2 Sekunden (entspricht
SLA) -**Suchmaschinen**: Unterstützung für Google, Bing, DuckDuckGo,
Brave -**Suchergebnisse**: 31+ Ergebnisse von 4500+ verfügbaren

### Hot-Reload Verfahren

```bash
# Nginx-Konfiguration überprüfen
docker exec erni-ki-nginx-1 nginx -t

# Änderungen ohne Systemneustart anwenden
docker exec erni-ki-nginx-1 nginx -s reload

# Aktualisierte Include-Dateien kopieren
docker cp conf/nginx/includes/ erni-ki-nginx-1:/etc/nginx/
```

# monitoring

## Monitoring

### System-Monitoring

### Service-Status prüfen

{% raw %}

```bash
# Allgemeiner Status aller Container
docker compose ps

# Detaillierte Service-Gesundheitsinformationen
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Logs eines spezifischen Services prüfen
docker compose logs -f service-name

# Ressourcen-Monitoring in Echtzeit
docker stats
```

{% endraw %}

## Wichtige Monitoring-Metriken

### Service-Status (sollten "healthy" sein)

-**nginx**- Web-Gateway und Load Balancer -**auth**-
JWT-Authentifizierung -**openwebui**- Haupt-AI-Interface -**ollama**-
Sprachmodell-Server -**db**- PostgreSQL-Datenbank -**redis**- Cache und
Sessions -**searxng**- Suchmaschine -**backrest**- Backup-System

#### Ressourcenverbrauch

{% raw %}

```bash
# CPU und Speicher pro Container
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Festplattenverbrauch
df -h
docker system df

# GPU-Verbrauch (falls installiert)
nvidia-smi
```

{% endraw %}

## Automatisiertes Monitoring

```bash
# Tägliches Health-Check-Skript erstellen
cat > /usr/local/bin/erni-ki-health.sh << 'EOF'
# !/bin/bash
LOG_FILE="/var/log/erni-ki-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] === ERNI-KI Health Check ===" >> $LOG_FILE

# Container-Status prüfen
UNHEALTHY=$(docker compose ps --format json | jq -r '.[] | select(.Health != "healthy" and .Health != "") | .Name')
if [ -n "$UNHEALTHY" ]; then
 echo "[$DATE] Ungesunde Services: $UNHEALTHY" >> $LOG_FILE
else
 echo "[$DATE] Alle Services gesund" >> $LOG_FILE
fi

# Festplattenverbrauch prüfen
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
 echo "[$DATE] Hoher Festplattenverbrauch: ${DISK_USAGE}%" >> $LOG_FILE
fi

# API-Verfügbarkeit prüfen (lokal)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
if [ "$HTTP_CODE" != "200" ]; then
 echo "[$DATE] OpenWebUI nicht erreichbar (HTTP $HTTP_CODE)" >> $LOG_FILE
fi

# Externe Verfügbarkeit prüfen
HTTP_CODE_EXT=$(curl -s -o /dev/null -w "%{http_code}" https://ki.erni-gruppe.ch/)
if [ "$HTTP_CODE_EXT" != "200" ]; then
 echo "[$DATE] Externe Domain nicht erreichbar (HTTP $HTTP_CODE_EXT)" >> $LOG_FILE
fi
EOF

chmod +x /usr/local/bin/erni-ki-health.sh

# Zu Crontab für tägliche Ausführung hinzufügen
echo "0 9 * * * /usr/local/bin/erni-ki-health.sh" | crontab -
```

## Datenbank-Management

### PostgreSQL-Verbindung

```bash
# Zur Datenbank verbinden
docker compose exec db psql -U postgres -d openwebui

# Datenbankgröße prüfen
docker compose exec db psql -U openwebui -d openwebui -c "
SELECT
 schemaname,
 tablename,
 pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

## Datenbank-Wartung

```bash
# Alte Daten löschen (älter als 90 Tage)
docker compose exec db psql -U openwebui -d openwebui -c "
DELETE FROM chat WHERE created_at < NOW() - INTERVAL '90 days';
VACUUM ANALYZE;
"

# Indizes prüfen
docker compose exec db psql -U openwebui -d openwebui -c "
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_tup_read DESC;
"

# Datenbank-Backup
docker compose exec db pg_dump -U openwebui openwebui > backup_$(date +%Y%m%d).sql
```

## Backup

## Backup-Management

### Backrest-Konfiguration

1. Web-Interface öffnen: `http://your-server:9898`
2. Mit Anmeldedaten aus `env/backrest.env` einloggen
3. Neues Repository für Backups erstellen
4. Backup-Zeitplan konfigurieren

### Backup-Konfiguration

# pragma: allowlist secret (Beispiel-Config, без боевых значений)

```json
{
  "repos": [
    {
      "id": "local-backup",
      "uri": "/data/repositories/erni-ki",
      "password": "<encryption-password>"
    }
  ],
  "plans": [
    {
      "id": "daily-backup",
      "repo": "local-backup",
      "paths": [
        "/backup-sources/data/postgres",
        "/backup-sources/data/openwebui",
        "/backup-sources/data/redis",
        "/backup-sources/env",
        "/backup-sources/conf"
      ],
      "schedule": "0 2 * * *",
      "retention": {
        "policy": "POLICY_KEEP_N",
        "keepDaily": 7,
        "keepWeekly": 4,
        "keepMonthly": 6
      }
    }
  ]
}
```

## Wiederherstellung aus Backup

# pragma: allowlist secret (пример пароля в payload)

```bash
# Services stoppen
docker compose down

# Daten über Backrest UI wiederherstellen
# oder über Kommandozeile:
docker compose exec backrest restic -r /data/repositories/erni-ki restore latest --target /

# Services starten
docker compose up -d
```

## Sicherheit und Zugriff

### Benutzerverwaltung

```bash
# Neuen Benutzer über API erstellen
curl -X POST http://localhost:8080/api/v1/auths/signup \
 -H "Content-Type: application/json" \
 -d '{
 "name": "Neuer Benutzer",
 "email": "user@example.com",
 "password": "<secure-password>"
 }'

# Benutzerliste anzeigen (erfordert Admin-Rechte)
docker compose exec db psql -U openwebui -d openwebui -c "
SELECT id, name, email, role, created_at FROM user ORDER BY created_at DESC;
"
```

## SSL/TLS-Konfiguration

```bash
# SSL-Zertifikate aktualisieren
# Bei Let's Encrypt:
certbot renew --nginx

# Bei eigenen Zertifikaten:
cp new-cert.pem conf/nginx/ssl/
cp new-key.pem conf/nginx/ssl/
docker compose restart nginx
```

## Sicherheits-Audit

```bash
# Offene Ports prüfen
netstat -tulpn | grep LISTEN

# Logs auf verdächtige Aktivitäten prüfen
docker compose logs nginx | grep -E "(40[0-9]|50[0-9])" | tail -20

# Fehlgeschlagene Login-Versuche prüfen
docker compose logs auth | grep "authentication failed" | tail -10
```

## Performance und Optimierung

### Performance-Monitoring

```bash
# Langsame PostgreSQL-Abfragen analysieren
docker compose exec db psql -U openwebui -d openwebui -c "
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
"

# Redis-Monitoring
docker compose exec redis redis-cli info memory
docker compose exec redis redis-cli info stats
```

## GPU-Nutzung optimieren

```bash
# GPU-Nutzung prüfen
nvidia-smi -l 1

# GPU-Speicher überwachen
watch -n 1 'nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits'

# GPU-Speicher-Limits in Ollama konfigurieren
docker compose exec ollama ollama show llama3.2:3b --modelfile
```

## Service-Skalierung

```bash
# Anzahl nginx-Instanzen erhöhen
docker compose up -d --scale nginx=2

# Load Balancing überwachen
docker compose logs nginx | grep upstream
```

## Fehlerbehebung

### Problem-Diagnose

```bash
# Status aller Services prüfen
docker compose ps

# Logs des problematischen Services analysieren
docker compose logs --tail=100 service-name

# Netzwerkverbindung zwischen Services prüfen
docker compose exec nginx ping ollama
docker compose exec openwebui curl -I http://ollama:11434
```

## Häufige Probleme und Lösungen

### Service startet nicht

```bash
# Ressourcen prüfen
docker system df
free -h

# Ungenutzte Ressourcen bereinigen
docker system prune -f

# Problematischen Service neu starten
docker compose restart service-name
```

## Langsame AI-Performance

```bash
# GPU-Last prüfen
nvidia-smi

# Verfügbaren Speicher prüfen
free -h

# Ollama für Speicher-Bereinigung neu starten
docker compose restart ollama
```

## Such-Probleme

```bash
# SearXNG prüfen
curl "http://localhost:8080/api/searxng/search?q=test&format=json"

# Redis-Cache prüfen
docker compose exec redis redis-cli ping
docker compose exec redis redis-cli info memory
```

## Kapazitätsplanung

### Ressourcen-Empfehlungen

#### Für kleine Teams (bis 10 Benutzer)

-**CPU**: 8 Kerne -**RAM**: 32GB -**GPU**: RTX 4060 (8GB VRAM) -**Festplatte**:
500GB SSD

#### Für mittlere Teams (10-50 Benutzer)

-**CPU**: 16 Kerne -**RAM**: 64GB -**GPU**: RTX 4080 (16GB
VRAM) -**Festplatte**: 1TB NVMe SSD

#### Für große Teams (50+ Benutzer)

-**CPU**: 32+ Kerne -**RAM**: 128GB+ -**GPU**: RTX 4090 oder mehrere
GPUs -**Festplatte**: 2TB+ NVMe SSD in RAID

## System-Updates

### ERNI-KI aktualisieren

```bash
# Backup vor Update erstellen
docker compose exec backrest restic backup /backup-sources

# Updates abrufen
git pull origin main

# Docker-Images aktualisieren
docker compose pull

# Updates anwenden
docker compose up -d

# Status nach Update prüfen
docker compose ps
```

## Rollback zur vorherigen Version

```bash
# Zu vorherigem Commit zurückkehren
git log --oneline -10
git checkout previous-commit-hash

# Vorherige Images wiederherstellen
docker compose down
docker compose up -d
```

---

**Wichtig**: Erstellen Sie immer Backups vor kritischen Systemänderungen!

## ⏱ RAG SLA Exporter

-**URL:**<http://localhost:9808/metrics> -**Metriken:**

- `erni_ki_rag_response_latency_seconds` — Latenz-Histogramm
- `erni_ki_rag_sources_count` — Anzahl der Quellen -**Grafana:**RAG-Panels auf
  dem OpenWebUI-Dashboard (Schwellwert 2s für p95)
