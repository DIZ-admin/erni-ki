---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Prometheus Alerts Guide - ERNI-KI

[TOC]

**Version:**1.0**Zuletzt aktualisiert:**2025-10-24**Status:**Production Ready

---

## Übersicht

Dieser Leitfaden bietet eine umfassende Dokumentation für alle 27 aktiven
Prometheus-Alert-Regeln im ERNI-KI-System.

### Alert-Verteilung

| Kategorie               | Anzahl | Datei                                                   |
| ----------------------- | ------ | ------------------------------------------------------- |
| **System Alerts (Neu)** | 18     | `conf/prometheus/alerts.yml`                            |
| **Bestehende Alerts**   | 9      | `conf/prometheus/alert_rules.yml`, `logging-alerts.yml` |
| **Gesamt Aktiv**        | 27     | -                                                       |

### Schweregrade

-**Critical**- Sofortiges Handeln erforderlich (Systemausfall, Risiko von
Datenverlust)

- [WARNING]**Warning**- Aufmerksamkeit erforderlich (Leistungsabfall, Annäherung
  an Grenzwerte) -**Info**- Informativ (nicht-kritische Ereignisse)

---

## Kritische Alerts (Critical)

### 1. DiskSpaceCritical

**Schweregrad:**Critical**Komponente:**System**Schwellenwert:**
Festplattennutzung >85%**Dauer:**5 Minuten

**Ausdruck:**

```promql
(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
```

**Beschreibung:**Wird ausgelöst, wenn das Root-Dateisystem weniger als 15%
freien Speicherplatz hat.

**Auswirkung:**

- System kann nicht mehr reagieren
- Docker-Container starten möglicherweise nicht
- Datenbank-Schreibvorgänge können fehlschlagen
- Log-Dateien können abgeschnitten werden

**Lösung:**

```bash
# Festplattennutzung prüfen
df -h /

# Große Dateien finden
du -sh /* | sort -rh | head -n 10

# Docker-Ressourcen bereinigen
docker system prune -a --volumes -f

# Automatische Bereinigung ausführen
/tmp/docker-cleanup.sh
```

**Zugehörige Automatisierung:**Docker-Cleanup läuft jeden Sonntag um 04:00 Uhr

---

## 2. MemoryCritical

**Schweregrad:**Critical**Komponente:**System**Schwellenwert:**Verfügbarer
Speicher <5%**Dauer:**5 Minuten

**Ausdruck:**

```promql
(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 5
```

**Beschreibung:**Wird ausgelöst, wenn das System weniger als 5% verfügbaren
Arbeitsspeicher hat.

**Auswirkung:**

- OOM-Killer könnte Prozesse beenden
- Systemleistung stark beeinträchtigt
- Dienste könnten abstürzen

**Lösung:**

```bash
# Speichernutzung prüfen
free -h

# Speicherintensive Prozesse finden
ps aux --sort=-%mem | head -n 10

# Docker-Container-Speicher prüfen
docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}"

# Speicherintensive Container bei Bedarf neu starten
docker compose restart SERVICE_NAME
```

---

## 3. ContainerDown

**Schweregrad:**Critical**Komponente:**Docker**Schwellenwert:**Container läuft
nicht**Dauer:**1 Minute

**Ausdruck:**

```promql
up{job=~".*"} == 0
```

**Beschreibung:**Wird ausgelöst, wenn ein überwachter Container ausgefallen ist.

**Auswirkung:**

- Dienst nicht verfügbar
- Abhängige Dienste könnten fehlschlagen
- Benutzerfunktionen defekt

**Lösung:**

```bash
# Container-Status prüfen
docker compose ps

# Container-Logs ansehen
docker compose logs SERVICE_NAME --tail 50

# Container neu starten
docker compose restart SERVICE_NAME

# Healthcheck prüfen
docker inspect SERVICE_NAME | jq '.[0].State.Health'
```

---

## 4. PostgreSQLDown

**Schweregrad:**Critical**Komponente:**Database**Schwellenwert:**PostgreSQL
nicht verfügbar**Dauer:**1 Minute

**Ausdruck:**

```promql
pg_up == 0
```

**Beschreibung:**Wird ausgelöst, wenn die PostgreSQL-Datenbank nicht verfügbar
ist.

**Auswirkung:**

- OpenWebUI kann keine Daten speichern
- LiteLLM kann nicht auf Konfiguration zugreifen
- Alle datenbankabhängigen Funktionen fallen aus

**Lösung:**

```bash
# PostgreSQL-Status prüfen
docker compose ps db

# PostgreSQL-Logs ansehen
docker compose logs db --tail 50

# Verbindungen prüfen
docker compose exec db psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Bei Bedarf neu starten
docker compose restart db
```

---

## 5. RedisDown

**Schweregrad:**Critical**Komponente:**Cache**Schwellenwert:**Redis nicht
verfügbar**Dauer:**1 Minute

**Ausdruck:**

```promql
redis_up == 0
```

**Beschreibung:**Wird ausgelöst, wenn der Redis-Cache nicht verfügbar ist.

**Auswirkung:**

- WebSocket-Manager fällt aus
- SearXNG-Caching deaktiviert
- Sitzungsverwaltung defekt

**Lösung:**

```bash
# Redis-Status prüfen
docker compose ps redis

# Redis-Verbindung testen
docker compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Redis-Logs ansehen
docker compose logs redis --tail 50

# Bei Bedarf neu starten
docker compose restart redis
```

---

## 6. OllamaGPUDown

**Schweregrad:**Critical**Komponente:**AI/GPU**Schwellenwert:**Ollama GPU nicht
verfügbar**Dauer:**2 Minuten

**Ausdruck:**

```promql
ollama_up == 0
```

**Beschreibung:**Wird ausgelöst, wenn der Ollama AI-Dienst mit GPU nicht
verfügbar ist.

**Auswirkung:**

- AI-Modell-Inferenz schlägt fehl
- OpenWebUI kann keine Antworten generieren
- GPU-Ressourcen verschwendet

**Lösung:**

```bash
# Ollama-Status prüfen
docker compose ps ollama

# GPU-Verfügbarkeit prüfen
nvidia-smi

# Ollama API testen
curl http://localhost:11434/api/tags

# Ollama-Logs ansehen
docker compose logs ollama --tail 50

# Bei Bedarf neu starten
docker compose restart ollama
```

---

## 7. NginxDown

**Schweregrad:**Critical**Komponente:**Gateway**Schwellenwert:**Nginx nicht
verfügbar**Dauer:**1 Minute

**Ausdruck:**

```promql
nginx_up == 0
```

**Beschreibung:**Wird ausgelöst, wenn der Nginx Reverse Proxy nicht verfügbar
ist.

**Auswirkung:**

- Alle Webdienste nicht erreichbar
- SSL-Terminierung schlägt fehl
- Externer Zugriff unterbrochen

**Lösung:**

```bash
# Nginx-Status prüfen
docker compose ps nginx

# Nginx-Konfiguration testen
docker compose exec nginx nginx -t

# Nginx-Logs ansehen
docker compose logs nginx --tail 50

# Bei Bedarf neu starten
docker compose restart nginx
```

---

## [WARNING] Warnungen (Warning)

### 8. DiskSpaceWarning

**Schweregrad:**Warning**Komponente:**System**Schwellenwert:**
Festplattennutzung >75%**Dauer:**10 Minuten

**Ausdruck:**

```promql
(1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|vfat",mountpoint!="/boot/efi"} /
 node_filesystem_size_bytes{fstype!~"tmpfs|vfat",mountpoint!="/boot/efi"})) * 100 > 80
```

**Hinweise:**EFI-Partition (`/boot/efi`, `vfat`) ist ausgeschlossen, um
Fehlalarme aufgrund des kleinen Boot-Volumes zu vermeiden.

**Lösung:**Siehe DiskSpaceCritical, aber weniger dringend.

---

### 9. MemoryWarning

**Schweregrad:**Warning**Komponente:**System**Schwellenwert:**Verfügbarer
Speicher <15%**Dauer:**10 Minuten

**Lösung:**Siehe MemoryCritical, aber weniger dringend.

---

### 10. HighCPUUsage

**Schweregrad:**Warning**Komponente:**System**Schwellenwert:**
CPU-Auslastung >80%**Dauer:**5 Minuten

**Ausdruck:**

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```

**Lösung:**

```bash
# CPU-Auslastung prüfen
top -bn1 | head -n 20

# CPU-intensive Prozesse finden
ps aux --sort=-%cpu | head -n 10

# Docker-Container-CPU prüfen
docker stats --no-stream --format "table {{.Container}}\t{{CPUPerc}}"
```

---

## 11. ContainerRestarting

**Schweregrad:**Warning**Komponente:**Docker**Schwellenwert:**≥2 Neustarts pro
Container innerhalb von 15 Minuten**Dauer:**1 Minute (Debounce)

**Ausdruck:**

```promql
sum by (name) (
 changes(
 container_start_time_seconds{
 job="cadvisor",
 container_label_com_docker_compose_project="erni-ki",
 name!~"erni-ki-(cadvisor|node-exporter|alertmanager).*"
 }[15m]
 )
) >= 2
```

**Hinweise:**

- `changes(container_start_time_seconds...)` reagiert nur, wenn der Container
  tatsächlich neu startet, wodurch Rauschen von `container_last_seen` vermieden
  wird.
- Infrastruktur-Container (cadvisor, node-exporter, alertmanager) sind
  ausgeschlossen, damit der Alert nicht auf Monitoring-Agenten auslöst.

**Lösung:**

```bash
# Tatsächliche Anzahl der Neustarts prüfen
docker inspect SERVICE_NAME | jq '.[0].RestartCount'

# Letzte Logs und Exit-Gründe ansehen
docker compose logs SERVICE_NAME --since 15m

# Healthcheck/Exit Code prüfen
docker inspect SERVICE_NAME | jq '.[0].State | {Status, ExitCode, Health}'
```

---

## 12. PostgreSQLHighConnections

**Schweregrad:**Warning**Komponente:**Database**Schwellenwert:**>80
Verbindungen**Dauer:**5 Minuten

**Ausdruck:**

```promql
pg_stat_database_numbackends{datname="openwebui"} > 80
```

**Lösung:**

```bash
# Aktive Verbindungen prüfen
docker compose exec db psql -U postgres -d openwebui -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# Verbindungsdetails ansehen
docker compose exec db psql -U postgres -d openwebui -c "SELECT pid, usename, application_name, client_addr, state FROM pg_stat_activity;"

# Inaktive Verbindungen bei Bedarf beenden
docker compose exec db psql -U postgres -d openwebui -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND state_change < now() - interval '1 hour';"
```

---

## 13. RedisHighMemory

**Schweregrad:**Warning**Komponente:**Cache**Schwellenwert:**
Speichernutzung >1GB**Dauer:**10 Minuten

**Ausdruck:**

```promql
redis_memory_used_bytes > 1073741824
```

**Lösung:**

```bash
# Redis-Speicher prüfen
docker compose exec redis redis-cli -a $REDIS_PASSWORD INFO memory

# Anzahl der Keys prüfen
docker compose exec redis redis-cli -a $REDIS_PASSWORD DBSIZE

# Cache leeren bei Bedarf (VORSICHT)
docker compose exec redis redis-cli -a $REDIS_PASSWORD FLUSHDB
```

---

## 14. RedisHighFragmentation

**Schweregrad:**Warning**Komponente:**Cache**Schwellenwert:**
`redis_mem_fragmentation_ratio > 5`**Dauer:**10 Minuten

**Ausdruck:**

```promql
redis_mem_fragmentation_ratio > 5
```

**Lösung:**

```bash
# Aktuelle Fragmentierung und Speicher prüfen
docker compose exec redis redis-cli INFO memory | grep -E "mem_fragmentation_ratio|used_memory"

# Watchdog-Log prüfen
tail -n 50 logs/redis-fragmentation-watchdog.log

# Bereinigung erzwingen (falls Watchdog nicht ausgelöst hat)
docker compose exec redis redis-cli MEMORY PURGE
```

**Hinweise:**Der Cron-Job `*/5 * * * * ... redis-fragmentation-watchdog.sh`
führt automatisch `MEMORY PURGE` aus. Der Alert dient als Frühwarnsystem und
verweist auf das Runbook unter _docs/security/log-audit.md › Durchgeführte
Remediation_.

---

## 15. OllamaHighVRAM

**Schweregrad:**Warning**Komponente:**AI/GPU**Schwellenwert:**
VRAM-Nutzung >80%**Dauer:**10 Minuten

**Ausdruck:**

```promql
(nvidia_gpu_memory_used_bytes / nvidia_gpu_memory_total_bytes) * 100 > 80
```

**Lösung:**

```bash
# GPU-Speicher prüfen
nvidia-smi

# Geladene Modelle prüfen
docker compose exec ollama ollama list

# Ungenutzte Modelle entladen
docker compose exec ollama ollama rm MODEL_NAME
```

---

## 16. NginxHighErrorRate

**Schweregrad:**Warning**Komponente:**Gateway**Schwellenwert:**>10 5xx
Fehler/Min**Dauer:**5 Minuten

**Ausdruck:**

```promql
rate(nginx_http_requests_total{status=~"5.."}[1m]) > 10
```

**Lösung:**

```bash
# Nginx-Fehlerlogs prüfen
docker compose logs nginx --tail 100 | grep "error"

# Upstream-Status prüfen
curl -s http://localhost:8080/nginx_status

# Backend-Dienste testen
curl -I http://localhost:8080
```

---

## Performance Alerts

### 17. OpenWebUISlowResponse

**Schweregrad:**Warning**Komponente:**Application**Schwellenwert:**
Antwortzeit >5s**Dauer:**5 Minuten

**Lösung:**

```bash
# OpenWebUI-Logs prüfen
docker compose logs openwebui --tail 50

# Datenbankleistung prüfen
docker compose exec db psql -U postgres -d openwebui -c "SELECT query, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# Ollama-Antwortzeit prüfen
time curl -X POST http://localhost:11434/api/generate -d '{"model":"llama3.2","prompt":"test"}'
```

---

## 18. SearXNGSlowSearch

**Schweregrad:**Warning**Komponente:**Search**Schwellenwert:**Suchzeit >3s
**Dauer:**5 Minuten

**Lösung:**

```bash
# SearXNG API testen
time curl -s "http://localhost:8080/search?q=test&format=json"

# Redis-Cache prüfen
docker compose exec redis redis-cli -a $REDIS_PASSWORD INFO stats

# SearXNG-Logs prüfen
docker compose logs searxng --tail 50
```

---

## 19. DockerStoragePoolAlmostFull

**Schweregrad:**Warning**Komponente:**Infrastructure**Schwellenwert:**
Docker-Speicher >85%**Dauer:**10 Minuten

**Lösung:**

```bash
# Docker-Festplattennutzung prüfen
docker system df

# Bereinigung ausführen
docker system prune -a --volumes -f

# Automatisiertes Bereinigungsskript ausführen
/tmp/docker-cleanup.sh
```

---

## Alert Management

### Alerts anzeigen

**Prometheus UI:**

```
http://localhost:9091/alerts
```

**API:**

```bash
# Alle Alerts
curl -s http://localhost:9091/api/v1/alerts

# Nur feuernde Alerts
curl -s http://localhost:9091/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing")'

# Alerts nach Schweregrad
curl -s http://localhost:9091/api/v1/rules | jq '.data.groups[].rules[] | select(.labels.severity=="critical")'
```

## Alerts testen

Siehe [Monitoring Guide](monitoring-guide.md) für Testverfahren.

### Alerts stummschalten (Silencing)

**Temporäres Stummschalten (via Alertmanager):**

```bash
# Spezifischen Alert für 1 Stunde stummschalten
curl -X POST http://localhost:9093/api/v1/silences \
 -H "Content-Type: application/json" \
 -d '{
 "matchers": [{"name":"alertname","value":"DiskSpaceWarning","isRegex":false}],
 "startsAt":"'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'",
 "endsAt":"'$(date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%S.000Z)'",
 "createdBy":"admin",
 "comment":"Wartungsfenster"
 }'
```

---

## Verwandte Dokumentation

- [Monitoring Guide](monitoring-guide.md) - Vollständige
  Monitoring-Dokumentation
- [Admin Guide](../core/admin-guide.md) - Systemadministration
- [Architecture](../../architecture/architecture.md) - Systemarchitektur

---

**Zuletzt aktualisiert:**2025-10-24**Nächste Überprüfung:**2025-11-24
