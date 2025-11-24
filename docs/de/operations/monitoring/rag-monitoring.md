---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# RAG System Monitoring Guide

**Erstellt**: 2025-10-24  
**Version**: 1.0  
**Autor**: Augment Agent

---

## Überblick

Das RAG-Monitoring (Retrieval-Augmented Generation) für ERNI-KI stellt sicher:

- Gesundheitsprüfungen aller RAG-Komponenten
- Messung der Performance zentraler Operationen
- Automatische Benachrichtigungen bei Problemen
- Logging von Metriken für Analysen

---

## Monitoring-Komponenten

### 1. RAG Health Monitor (`scripts/rag-health-monitor.sh`)

**Prüft**:

- ✅ OpenWebUI (healthy)
- ✅ SearXNG (<2s)
- ✅ PostgreSQL/pgvector (<100ms)
- ✅ Ollama (Embedding-Modell verfügbar)
- ✅ Docling (Dienst erreichbar)
- ✅ Nginx (Caching)

**Nutzung**:

```bash
# Manuell
./scripts/rag-health-monitor.sh
# Logs: logs/rag-health-YYYYMMDD.log
```

**Schwellwerte**:

- SearXNG Response: <2000ms
- pgvector Query: <100ms
- Ollama Embedding: <2000ms
- Docling Verarbeitung: <5000ms

Exit-Codes:

- `0` – alles OK
- `1` – Probleme gefunden

### 2. Webhook Notifications (`scripts/rag-webhook-notify.sh`)

Webhook-Versand (Discord/Slack):

```bash
export RAG_WEBHOOK_ENABLED=true
export RAG_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"
```

Beispiele:

```bash
./scripts/rag-webhook-notify.sh "healthy" "RAG ok" "All checks passed"
./scripts/rag-webhook-notify.sh "warning" "SearXNG slow" "Response: 3500ms"
./scripts/rag-webhook-notify.sh "error" "pgvector down" "DB connection failed"
```

Status-Typen:

- `healthy` ✅
- `warning` ⚠️
- `error` ❌

---

## Automatisches Monitoring

### Cron

```bash
*/5 * * * * cd /home/konstantin/Documents/augment-projects/erni-ki && ./scripts/rag-health-monitor.sh >> logs/rag-health-cron.log 2>&1
*/15 * * * * cd /home/konstantin/Documents/augment-projects/erni-ki && ./scripts/rag-health-monitor.sh || ./scripts/rag-webhook-notify.sh "error" "RAG health check failed" "Check logs/rag-health-$(date +\\%Y\\%m\\%d).log"
```

### Systemd Timer (Alternative)

Service/Timer (Beispiel):

```ini
[Service]
Type=oneshot
WorkingDirectory=/home/konstantin/Documents/augment-projects/erni-ki
ExecStart=/home/konstantin/Documents/augment-projects/erni-ki/scripts/rag-health-monitor.sh
User=konstantin
StandardOutput=append:/home/konstantin/Documents/augment-projects/erni-ki/logs/rag-health-systemd.log
StandardError=append:/home/konstantin/Documents/augment-projects/erni-ki/logs/rag-health-systemd.log

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=rag-health-monitor.service
```

Aktivierung:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rag-health-monitor.timer
sudo systemctl start rag-health-monitor.timer
```

---

## Metriken & Logs

**Logs** (`logs/`):

- `rag-health-YYYYMMDD.log` – tägliche Health-Checks
- `rag-health-cron.log` – Cron-Läufe
- `rag-health-systemd.log` – Systemd-Läufe

Analyse:

```bash
tail -50 logs/rag-health-$(date +%Y%m%d).log
grep "FAILED\\|ERROR\\|SLOW" logs/rag-health-*.log
```

---

## Prometheus/Grafana Integration

Textfile Collector (Node Exporter):

```bash
METRICS_FILE="/var/lib/node_exporter/textfile_collector/rag_metrics.prom"
./scripts/rag-health-monitor.sh > /tmp/rag-health-output.txt 2>&1
EXIT_CODE=$?

cat > "$METRICS_FILE" << PROM
# TYPE rag_health_status gauge
rag_health_status{component="overall"} $([ $EXIT_CODE -eq 0 ] && echo 1 || echo 0)
PROM
```

Weitere Werte aus dem Script auslesen (SearXNG/pgvector Zeiten,
Chunks/Collections).

---

## Troubleshooting

### SearXNG langsam (>2s)

- Logs prüfen: `docker logs --tail 100 erni-ki-searxng-1`
- Rate-Limits:
  `docker logs --tail 100 erni-ki-nginx-1 | grep "limiting requests"`
- Redis-Cache prüfen: `docker exec erni-ki-redis-1 redis-cli INFO stats`
- Maßnahmen: Timeout in `env/searxng.env` erhöhen; Engines prüfen; Cache leeren.

### pgvector langsam (>100ms)

- Größe:
  `docker exec erni-ki-db-1 psql ... pg_total_relation_size('document_chunk')`
- Indizes: `\d document_chunk`
- VACUUM/ANALYZE oder Reindex (siehe Phase 2.3)

### Ollama Embedding fehlt

- Modelle: `docker exec erni-ki-ollama-1 ollama list`
- Pull: `docker exec erni-ki-ollama-1 ollama pull nomic-embed-text:latest`

---

## Best Practices

1. Health-Check alle 5–15 Minuten
2. Logs mind. 30 Tage aufbewahren
3. Webhook-Alerts für kritische Fehler
4. Baseline-Metriken dokumentieren
5. Alerts bei >50% Abweichung von Normalwerten

---

**Letztes Update**: 2025-10-24  
**Dokumentversion**: 1.0
