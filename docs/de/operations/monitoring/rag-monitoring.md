---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# RAG System Monitoring Guide

**Erstellungsdatum**: 2025-10-24 **Version**: 1.0 **Autor**: Augment Agent

---

## Übersicht

Das RAG (Retrieval-Augmented Generation) Monitoring-System für ERNI-KI
gewährleistet:

- Überprüfung des Zustands aller RAG-Komponenten
- Leistungsmessung von Schlüsseloperationen
- Automatische Benachrichtigungen bei Problemen
- Protokollierung von Metriken zur Analyse

---

## Monitoring-Komponenten

### 1. RAG Health Monitor (`scripts/rag-health-monitor.sh`)

Das Hauptskript zur Überprüfung des Zustands des RAG-Systems.

**Überprüfte Komponenten**:

- ✅ OpenWebUI (Status healthy)
- ✅ SearXNG (Leistung <2s)
- ✅ PostgreSQL/pgvector (Leistung <100ms)
- ✅ Ollama (Verfügbarkeit des Embedding-Modells)
- ✅ Docling (Verfügbarkeit des Dienstes)
- ✅ Nginx (Caching)

**Verwendung**:

```bash
# Manueller Start
./scripts/rag-health-monitor.sh

# Ausgabe wird in logs/rag-health-YYYYMMDD.log protokolliert
```

**Schwellenwerte**:

- SearXNG Antwortzeit: <2000ms
- pgvector Abfragezeit: <100ms
- Ollama Embedding: <2000ms
- Docling Verarbeitung: <5000ms

**Exit-Codes**:

- `0` - Alle Prüfungen bestanden (RAG system healthy)
- `1` - Probleme entdeckt (RAG system has issues)

---

### 2. Webhook Notifications (`scripts/rag-webhook-notify.sh`)

Versenden von Benachrichtigungen über den RAG-Systemstatus via Webhook
(Discord/Slack).

**Einrichtung**:

```bash
# Webhook-Benachrichtigungen aktivieren
export RAG_WEBHOOK_ENABLED=true
export RAG_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"

# Oder in env/monitoring.env hinzufügen
echo "RAG_WEBHOOK_ENABLED=true" >> env/monitoring.env
echo "RAG_WEBHOOK_URL=https://discord.com/api/webhooks/..." >> env/monitoring.env
```

**Verwendung**:

```bash
# Benachrichtigung senden
./scripts/rag-webhook-notify.sh "healthy" "RAG system is operational" "All checks passed"
./scripts/rag-webhook-notify.sh "warning" "SearXNG slow response" "Response time: 3500ms"
./scripts/rag-webhook-notify.sh "error" "pgvector unavailable" "Database connection failed"
```

**Status-Typen**:

- `healthy` - ✅ Grün (alles funktioniert)
- `warning` - ⚠️ Gelb (Leistungsabfall)
- `error` - ❌ Rot (kritischer Fehler)

---

## Automatisches Monitoring

### Cron-Einrichtung

Für automatische Überprüfung alle 5 Minuten:

```bash
# Crontab bearbeiten
crontab -e

# Zeile hinzufügen (Überprüfung alle 5 Minuten)
*/5 * * * * cd /home/konstantin/Documents/augment-projects/erni-ki && ./scripts/rag-health-monitor.sh >> logs/rag-health-cron.log 2>&1

# Benachrichtigung bei Fehlern (alle 15 Minuten)
*/15 * * * * cd /home/konstantin/Documents/augment-projects/erni-ki && ./scripts/rag-health-monitor.sh || ./scripts/rag-webhook-notify.sh "error" "RAG health check failed" "Check logs/rag-health-$(date +\%Y\%m\%d).log"
```

### Systemd Timer (Alternative zu Cron)

Erstellen Sie einen Systemd-Service und Timer für zuverlässigeres Monitoring:

```bash
# /etc/systemd/system/rag-health-monitor.service
[Unit]
Description=ERNI-KI RAG Health Monitor
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/home/konstantin/Documents/augment-projects/erni-ki
ExecStart=/home/konstantin/Documents/augment-projects/erni-ki/scripts/rag-health-monitor.sh
User=konstantin
StandardOutput=append:/home/konstantin/Documents/augment-projects/erni-ki/logs/rag-health-systemd.log
StandardError=append:/home/konstantin/Documents/augment-projects/erni-ki/logs/rag-health-systemd.log

[Install]
WantedBy=multi-user.target
```

```bash
# /etc/systemd/system/rag-health-monitor.timer
[Unit]
Description=ERNI-KI RAG Health Monitor Timer
Requires=rag-health-monitor.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=rag-health-monitor.service

[Install]
WantedBy=timers.target
```

```bash
# Aktivierung
sudo systemctl daemon-reload
sudo systemctl enable rag-health-monitor.timer
sudo systemctl start rag-health-monitor.timer

# Status prüfen
sudo systemctl status rag-health-monitor.timer
```

---

## Metriken und Logs

### Log-Dateien

**Ort**: `logs/`

- `rag-health-YYYYMMDD.log` - Tägliche Health-Check-Logs
- `rag-health-cron.log` - Cron-Ausführungslogs
- `rag-health-systemd.log` - Systemd-Ausführungslogs

**Log-Format**:

```
[2025-10-24 15:38:50] === RAG Health Check Started ===
[2025-10-24 15:38:50] SearXNG: 6ms - OK
[2025-10-24 15:38:50] pgvector: 1ms - OK
[2025-10-24 15:38:50] Ollama: nomic-embed model available
[2025-10-24 15:38:50] Docling: 0ms - OK
[2025-10-24 15:38:52] Nginx caching: 138x speedup
[2025-10-24 15:38:52] === RAG Health Check: PASSED ===
```

### Log-Analyse

```bash
# Letzte 50 Einträge
tail -50 logs/rag-health-$(date +%Y%m%d).log

# Fehlersuche
grep "FAILED\|ERROR\|SLOW" logs/rag-health-*.log

# SearXNG Leistungsstatistik
grep "SearXNG:" logs/rag-health-*.log | awk '{print $3}' | sed 's/ms//' | sort -n

# pgvector Leistungsstatistik
grep "pgvector:" logs/rag-health-*.log | awk '{print $3}' | sed 's/ms//' | sort -n
```

---

## Integration mit Prometheus/Grafana

Für erweitertes Monitoring kann eine Integration mit Prometheus erfolgen:

### Node Exporter Textfile Collector

```bash
# Metrik-Export-Skript erstellen
cat > scripts/rag-metrics-exporter.sh << 'EOF'
#!/bin/bash
METRICS_FILE="/var/lib/node_exporter/textfile_collector/rag_metrics.prom"

# Health Monitor starten und Ergebnisse parsen
./scripts/rag-health-monitor.sh > /tmp/rag-health-output.txt 2>&1
EXIT_CODE=$?

# Metriken im Prometheus-Format exportieren
cat > "$METRICS_FILE" << PROM
# HELP rag_health_status RAG system health status (1=healthy, 0=unhealthy)
# TYPE rag_health_status gauge
rag_health_status{component="overall"} $([ $EXIT_CODE -eq 0 ] && echo 1 || echo 0)

# HELP rag_searxng_response_time_ms SearXNG response time in milliseconds
# TYPE rag_searxng_response_time_ms gauge
rag_searxng_response_time_ms $(grep "SearXNG:" /tmp/rag-health-output.txt | awk '{print $3}' | sed 's/ms//' || echo 0)

# HELP rag_pgvector_query_time_ms pgvector query time in milliseconds
# TYPE rag_pgvector_query_time_ms gauge
rag_pgvector_query_time_ms $(grep "pgvector:" /tmp/rag-health-output.txt | awk '{print $3}' | sed 's/ms//' || echo 0)

# HELP rag_chunks_total Total number of chunks in pgvector
# TYPE rag_chunks_total gauge
rag_chunks_total $(grep "Total Chunks:" /tmp/rag-health-output.txt | awk '{print $3}' || echo 0)

# HELP rag_collections_total Total number of collections in pgvector
# TYPE rag_collections_total gauge
rag_collections_total $(grep "Collections:" /tmp/rag-health-output.txt | awk '{print $2}' || echo 0)
PROM
EOF

chmod +x scripts/rag-metrics-exporter.sh
```

---

## Fehlerbehebung (Troubleshooting)

### Problem: SearXNG langsame Antwort (>2s)

**Diagnose**:

```bash
# SearXNG Logs prüfen
docker logs --tail 100 erni-ki-searxng-1

# Rate Limiting prüfen
docker logs --tail 100 erni-ki-nginx-1 | grep "limiting requests"

# Redis Cache prüfen
docker exec erni-ki-redis-1 redis-cli INFO stats
```

**Lösung**:

- Timeout in `env/searxng.env` erhöhen
- Verfügbarkeit der Suchmaschinen prüfen
- Redis Cache leeren: `docker exec erni-ki-redis-1 redis-cli FLUSHDB`

---

### Problem: pgvector langsame Abfragen (>100ms)

**Diagnose**:

```bash
# Tabellengröße prüfen
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "SELECT pg_size_pretty(pg_total_relation_size('document_chunk'));"

# Indizes prüfen
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "\d document_chunk"

# Leistungsanalyse
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "EXPLAIN ANALYZE SELECT * FROM document_chunk LIMIT 10;"
```

**Lösung**:

- VACUUM ANALYZE ausführen:
  `docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "VACUUM ANALYZE document_chunk;"`
- Indizes neu erstellen (siehe Phase 2.3)

---

### Problem: Ollama Embedding-Modell nicht verfügbar

**Diagnose**:

```bash
# Modell-Liste prüfen
docker exec erni-ki-ollama-1 ollama list

# Ollama Logs prüfen
docker logs --tail 50 erni-ki-ollama-1
```

**Lösung**:

```bash
# Modell neu laden
docker exec erni-ki-ollama-1 ollama pull nomic-embed-text:latest
```

---

## Best Practices

1. **Regelmäßiges Monitoring**: Health Check mindestens alle 5-15 Minuten
   ausführen
2. **Logging**: Logs mindestens 30 Tage für Trendanalysen aufbewahren
3. **Benachrichtigungen**: Webhook für kritische Fehler einrichten
4. **Baseline-Metriken**: Normale Leistungswerte dokumentieren
5. **Alarme**: Alarme bei Überschreitung der Schwellenwerte um 50%+ einrichten

---

## Kontakte

**Systemadministrator**: Kostiantyn Konstantinov **Email**:
kostiantyn.konstantinov@erni-gruppe.ch **Teams**: Verfügbar für Fragen

---

**Zuletzt aktualisiert**: 2025-10-24 **Dokumentversion**: 1.0
