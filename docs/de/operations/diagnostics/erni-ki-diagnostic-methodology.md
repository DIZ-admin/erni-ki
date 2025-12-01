---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# UMFASSENDE ANLEITUNG ZUR DIAGNOSE DES ERNI-KI SYSTEMS

[TOC]

## Übersicht

Diese Anleitung basiert auf Erfahrungen bei der Behebung kritischer Fehler in
der Testmethodik, die zu einer Unterschätzung der Systembewertung von realen
95%+ auf fehlerhafte 43-56% führten. Das Befolgen dieser Methodik gewährleistet
eine genaue Diagnose des tatsächlichen Zustands von ERNI-KI.

---

## 1. KORREKTE TESTMETHODIK FÜR KOMPONENTEN

### LiteLLM - AI Model Proxy

**FALSCH:**

```bash
curl http://localhost:4000/health # Ohne Authentifizierung
curl http://localhost:4000/v1/models # Ohne Bearer Token
```

**RICHTIG:**

```bash
# Prüfung der Modellverfügbarkeit
curl -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
 http://localhost:4000/v1/models

# Testen der Generierung
curl -X POST "http://localhost:4000/v1/chat/completions" \
 -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
 -H "Content-Type: application/json" \
 -d '{"model": "gpt-4.1-nano-2025-04-14", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 50}'

# Prüfung des Health-Endpoints (ohne Authentifizierung)
curl http://localhost:4000/health
```

**Erfolgskriterien:**

- `/v1/models` gibt JSON mit einem Array von Modellen zurück
- `/v1/chat/completions` generiert eine Textantwort
- `/health` gibt Status ohne 401-Fehler zurück

---

## SearXNG - Suchmaschine

**FALSCH:**

```bash
curl http://localhost:8080/search?q=test # Falscher Pfad - gibt HTML zurück
curl -I http://localhost:8080 # Nur HTTP-Codes
curl http://localhost:8080/searxng/search?q=test&format=json # Veralteter Pfad
```

**RICHTIG:**

```bash
# KRITISCH WICHTIG: Verwenden Sie den korrekten API-Pfad über Nginx
curl -s "http://localhost:8080/api/searxng/search?q=test&format=json" | jq -r '.results | length'

# Prüfung der Antwortzeit (korrekter Pfad)
curl -s -w "TIME: %{time_total}s\n" "http://localhost:8080/api/searxng/search?q=test&format=json" | tail -1

# Prüfung der JSON-Antwortstruktur
curl -s "http://localhost:8080/api/searxng/search?q=test&format=json" | jq -r 'keys[]'

# Testen der Integration mit OpenWebUI
docker logs erni-ki-openwebui-1 --since=5m | grep "GET /search?q=" | tail -5
```

**Erfolgskriterien:**

- JSON API gibt valides JSON mit Feld `results` zurück (normalerweise 10-50
  Ergebnisse)
- Antwortstruktur enthält Schlüssel: `answers`, `corrections`, `infoboxes`,
  `number_of_results`, `query`, `results`, `suggestions`, `unresponsive_engines`
- Antwortzeit <2 Sekunden über `/api/searxng/search`
- OpenWebUI-Logs zeigen erfolgreiche Anfragen an SearXNG -**WICHTIG:**Direkter
  Zugriff auf `/search` gibt HTML zurück - das ist normal!

---

## Redis - Cache & Session Store

**FALSCH:**

```bash
docker exec erni-ki-redis-1 redis-cli ping # Ohne Passwort
docker exec erni-ki-redis-1 redis-cli get test # NOAUTH Fehler
```

**RICHTIG:**

```bash
# Verbindungsprüfung mit Passwort
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" ping

# Testen von Schreib-/Leseoperationen
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" set test_key "test_value"
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" get test_key

# Prüfung von Version und Status
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" info server | grep redis_version
```

**Erfolgskriterien:**

- `ping` gibt `PONG` zurück
- Schreib-/Leseoperationen funktionieren ohne NOAUTH-Fehler
- Redis-Version ist aktuell (7.4+)

---

## Docling - Dokumentenverarbeitung

**RICHTIG:**

1. Sicherstellen, dass der Container tatsächlich die GPU nutzt.

```bash
docker compose exec docling nvidia-smi
docker compose exec docling python - <<'PY'
import torch
print("CUDA:", torch.cuda.is_available(), "device:", torch.cuda.get_device_name(0))
PY
```

Beide Aufrufe sollten ohne Fehler ausgeführt werden. Wenn die GPU nicht sichtbar
ist, setzen Sie `DOCLING_GPU_VISIBLE_DEVICES`/`DOCLING_CUDA_VISIBLE_DEVICES` in
`.env` und starten Sie den Stack neu.

2. Konfiguration `env/docling.env`:

- `DOCLING_DEVICE=cuda:0`, `DOCLING_NUM_THREADS=4`.
- `EASYOCR_GPU=true`, `EASYOCR_FORCE_CPU=false` — EasyOCR läuft auf CUDA.
- `DOCLING_SERVE_ENABLE_REMOTE_SERVICES=true` — erlaubt VLM/LLM-Aufrufe.
- `DOCLING_SHARED_VOLUME_PATH=/docling-shared`,
  `DOCLING_SERVE_ARTIFACTS_PATH=/docling-artifacts` (Host-Ordner
  `./data/docling/docling-models`).

Nach Änderung der Variablen `docker compose up -d docling` ausführen.

3. Für Bildbeschreibungen aktivieren Sie den Block**Dokumente → Bilder
   beschreiben**in OpenWebUI (Admin-Panel `/admin/settings/documents`). Im
   Konfigurationsfeld geben Sie die OpenAI-kompatible Ollama/VLLM API an:

```json
{
  "url": "http://ollama:11434/v1/chat/completions",
  "params": {
    "model": "llava:latest",
    "max_tokens": 800,
    "temperature": 0.1
  },
  "prompt": "Analyze this image in detail. Describe text, objects, layout and relations. Languages: English, German, French, Italian."
}
```

Docling setzt automatisch `picture_description_api` ein und ruft llava über
Ollama auf, wenn der Benutzer in der UI "Bilder beschreiben" aktiviert.

4. Smoke-Test:

```bash
curl -s -X POST http://docling:5001/v1/convert/file \
-F files=@sample.pdf \
-F 'options={"do_picture_description": true, "picture_description_api": {"url": "http://ollama:11434/v1/chat/completions","params":{"model":"llava:latest"}}}' \
| jq '.status,.document.picture_descriptions[0].summary'
```

`status` sollte `success` sein, und das Array `picture_descriptions` — nicht
leer.

5. Bei der Verarbeitung großer Dokumente ist der asynchrone Modus aktiviert: in
   `env/openwebui.env` ist `DOCLING_USE_ASYNC=true` gesetzt, daher sendet
   OpenWebUI die Datei über `/v1/convert/file/async`, fragt dann alle
   `DOCLING_POLL_INTERVAL` Sekunden (Standard 3) `/v1/status/poll/{task_id}` ab,
   maximal `DOCLING_MAX_POLL_ATTEMPTS` Mal (Wert 600 ≈ 30 Minuten). Nach dem
   Status `success` wird das Ergebnis über `/v1/result/{task_id}` abgerufen.
   Wenn Sie die Wartezeit verkürzen oder die Last verringern müssen, passen Sie
   diese Parameter an und starten Sie OpenWebUI neu.

---

### Cloudflare Tunnel - Externer Zugriff

**FALSCH:**

```bash
curl https://erni-ki.diz-admin.com # Nicht existierende Domain
nslookup erni-ki-dev.diz-admin.com # Falsche Domain
```

**RICHTIG:**

```bash
# Zuerst aktuelle Konfiguration prüfen
cat conf/cloudflare/config.yml | grep hostname

# Echte konfigurierte Domains testen
curl -I "https://ki.erni-gruppe.ch"
curl -I "https://diz.zone"
curl -I "https://webui.diz.zone"
curl -I "https://lite.diz.zone"
curl -I "https://search.diz.zone"

# Prüfung der SSL-Zertifikate
openssl s_client -connect ki.erni-gruppe.ch:443 -servername ki.erni-gruppe.ch </dev/null 2>/dev/null | openssl x509 -noout -issuer -dates

# Prüfung der Antwortzeit
curl -s -w "TIME: %{time_total}s\nHTTP: %{http_code}\n" "https://ki.erni-gruppe.ch" -o /dev/null
```

**Erfolgskriterien:**

- Alle konfigurierten Domains geben HTTP 200 zurück
- SSL-Zertifikate sind gültig und nicht abgelaufen
- Antwortzeit <5 Sekunden (normalerweise <0.1s)

---

## 2. VERMEIDUNG TYPISCHER DIAGNOSEFEHLER

### Kritische Fehler, die vermieden werden müssen

1.**Testen ohne Authentifizierung**

- Prüfen Sie immer die Authentifizierungsanforderungen in der Dokumentation
- Verwenden Sie korrekte API-Schlüssel und Passwörter

  2.**Verlassen nur auf HTTP-Codes**

- HTTP 200 garantiert keine Funktionalität
- Prüfen Sie den Inhalt der Antworten und die Datenstruktur

  3.**Verwendung falscher Endpoints**

- Studieren Sie die API-Dokumentation vor dem Testen
- Prüfen Sie aktuelle Konfigurationsdateien

  4.**Ignorieren von Integrationen**

- Testen Sie Verbindungen zwischen Services
- Prüfen Sie Logs auf Integrationsfehler

  5.**Testen nicht existierender Ressourcen**

- Prüfen Sie immer die aktuelle Konfiguration
- Raten Sie keine Domainnamen oder Endpoints

### Richtiger Ansatz

1.**Studium der Konfiguration vor dem Testen**2.**Verwendung korrekter
Authentifizierungsparameter**3.**Prüfung des Antwortinhalts, nicht nur der
Statuscodes**4.**Testen von Integrationen zwischen Komponenten**5.**Validierung
von Leistung und Funktionalität**

---

## 2.1. AKTUELLE KORREKTUREN UND LEKTIONEN (September 2025)

### Behobene Diagnoseprobleme

#### SearXNG JSON API - Behoben 25.09.2025

**Problem:**SearXNG gab HTML statt JSON bei Anfragen mit `format=json` zurück

**Ursachen:**

1. Falsche Konfiguration `base_url: "/searxng"` in `conf/searxng/settings.yml`
2. Verwendung des falschen Pfads `/search` statt `/api/searxng/search`
3. Nginx-Konfiguration erfordert Nutzung des API-Pfads

**Korrekturen:**

- Konfiguration geändert zu `base_url: ""` in `conf/searxng/settings.yml`
- Alle Tests aktualisiert zur Nutzung von `/api/searxng/search`
- Korrekten API-Pfad dokumentiert

**Lektion:**Prüfen Sie immer die Nginx-Konfiguration, um korrekte API-Pfade zu
verstehen

#### Docling Service

Docling wird als Teil des Stacks bereitgestellt (siehe
`docker compose ps docling`) und verwendet das offizielle Image
`ghcr.io/docling-project/docling-serve-cu126`. Stellen Sie vor der Diagnose
sicher, dass Modelle heruntergeladen sind
(`scripts/maintenance/download-docling-models.sh`) und Volumes `data/docling/*`
verfügbar sind. Siehe Abschnitt oben "Docling - Dokumentenverarbeitung" für
Prüfbefehle.

### Schlüsselprinzipien nach Korrekturen

1.**Verwenden Sie immer korrekte API-Pfade über Nginx**2.**Prüfen Sie die Docker
Compose Konfiguration, um Ports zu verstehen**3.**Testen Sie sowohl innerhalb
des Docker-Netzwerks als auch über externe Pfade**4.**Dokumentieren Sie alle
gefundenen Probleme für zukünftige Diagnosen**

---

## 3. STRUKTUR DES DIAGNOSEBERICHTS

### Berichtsvorlage

```markdown
# ERNI-KI DIAGNOSEBERICHT

Datum: [YYYY-MM-DD HH:MM] Methodik-Version: 2.0

## EXECUTIVE SUMMARY

- Gesamtsystembewertung: [XX]%
- Kritische Probleme: [N]
- Warnungen: [N]
- Diagnosezeit: [XX] Minuten

## DETAILLIERTE ERGEBNISSE

### FUNKTIONIERENDE KOMPONENTEN

| Komponente | Status | Antwortzeit | Anmerkungen         |
| ---------- | ------ | ----------- | ------------------- |
| LiteLLM    | OK     | 0.05s       | 3 Modelle verfügbar |

### PROBLEME UND EMPFEHLUNGEN

| Priorität | Komponente | Problem | Lösung              | Zeit  |
| --------- | ---------- | ------- | ------------------- | ----- |
| HIGH      | Redis      | NOAUTH  | Passwort hinzufügen | 15min |

### LEISTUNGSMETRIKEN

- API-Antwortzeit: [Durchschnitt/Median]
- Durchsatz: [Anfragen/Sek]
- Ressourcennutzung: [CPU/RAM/GPU]

### BEFEHLE ZUR REPRODUKTION

[Genaue Befehle zur Wiederholung der Ergebnisse]
```

---

## 4. KRITERIEN ZUR BEWERTUNG DER SYSTEMGESUNDHEIT

### Bewertungssystem (0-100%)

#### [OK] AUSGEZEICHNET (90-100%)

- Alle Docker-Container "healthy"
- Alle API-Endpoints antworten korrekt
- Integrationen funktionieren fehlerfrei
- Externer Zugriff über HTTPS
- Leistung innerhalb SLA

#### [WARNING] GUT (70-89%)

- Hauptservices funktionieren
- Kleinere Konfigurationsprobleme
- Lokaler Zugriff funktional
- Einige Integrationen erfordern Konfiguration

#### 🟠 BEFRIEDIGEND (50-69%)

- Teil der Services nicht verfügbar
- Probleme mit Authentifizierung
- Eingeschränkte Funktionalität
- Externer Zugriff funktioniert nicht

#### KRITISCH (<50%)

- Hauptservices funktionieren nicht
- Mehrere Konfigurationsfehler
- System nicht nutzbar

### Gewichtung der Komponenten

| Komponente     | Gewicht | Begründung                         |
| -------------- | ------- | ---------------------------------- |
| OpenWebUI      | 25%     | Hauptbenutzeroberfläche            |
| Ollama/LiteLLM | 20%     | AI-Generierung - Schlüsselfunktion |
| SearXNG        | 15%     | RAG-Funktionalität                 |
| PostgreSQL     | 15%     | Datenspeicherung                   |
| Nginx          | 10%     | Web-Server und Proxying            |
| Redis          | 5%      | Caching und Sessions               |
| Cloudflare     | 5%      | Externer Zugriff                   |
| Sonstige       | 5%      | Hilfsdienste                       |

---

## FAZIT

Das Befolgen dieser Methodik gewährleistet:

- Genaue Diagnose des tatsächlichen Systemzustands
- Vermeidung falscher negativer Ergebnisse
- Richtige Priorisierung von Problemen
- Effiziente Nutzung der Diagnosezeit

**Denken Sie daran:**Das System kann besser funktionieren, als fehlerhaftes
Testen zeigt!

---

## 5. PRAKTISCHE BEISPIELE FÜR DIAGNOSEBEFEHLE

### Vollständige Systemdiagnose (5-Minuten-Checkliste)

{% raw %}

```bash
# !/bin/bash
# ERNI-KI Quick Health Check Script

echo "=== ERNI-KI SYSTEM DIAGNOSTICS ==="
echo "Timestamp: $(date)"
echo

# 1. Docker Container
echo "1. DOCKER CONTAINERS STATUS:"
docker ps --filter "name=erni-ki" --format "table {{.Names}}\t{{.Status}}" | grep -c "healthy"
echo

# 2. LiteLLM API
echo "2. LITELLM API TEST:"
curl -s -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
 "http://localhost:4000/v1/models" | jq -r '.data | length' 2>/dev/null || echo "FAILED"
echo

# 3. SearXNG Search (BEHOBEN: korrekter API-Pfad)
echo "3. SEARXNG SEARCH TEST:"
curl -s "http://localhost:8080/api/searxng/search?q=test&format=json" | jq -r '.results | length' 2>/dev/null || echo "FAILED"
echo

# 4. Redis Connection
echo "4. REDIS CONNECTION TEST:"
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null || echo "FAILED"
echo

# 5. Docling Health (BEHOBEN: korrekter Pfad über Nginx)
echo "5. DOCLING HEALTH TEST:"
echo

# 6. External HTTPS Access
echo "6. EXTERNAL HTTPS ACCESS:"
curl -s -w "ki.erni-gruppe.ch: %{http_code} (%{time_total}s)\n" "https://ki.erni-gruppe.ch" -o /dev/null
curl -s -w "webui.diz.zone: %{http_code} (%{time_total}s)\n" "https://webui.diz.zone" -o /dev/null
echo

echo "=== DIAGNOSTICS COMPLETE ==="
```

{% endraw %}

## Detaillierte Diagnose von Integrationen

```bash
# Testen der OpenWebUI → SearXNG Integration
echo "Testing OpenWebUI → SearXNG integration:"
docker logs erni-ki-openwebui-1 --since=10m | grep -c "GET /search?q=" || echo "No recent searches"

# Testen der OpenWebUI → LiteLLM Integration
echo "Testing OpenWebUI → LiteLLM integration:"
docker logs erni-ki-openwebui-1 --since=10m | grep -c "litellm" || echo "No LiteLLM calls"

# Testen von Redis Caching
echo "Testing Redis caching:"
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" info stats | grep keyspace_hits

# Prüfung der GPU-Nutzung von Ollama
echo "Testing Ollama GPU usage:"
docker exec erni-ki-ollama-1 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "GPU not available"
```

---

## 6. REFERENZINFORMATIONEN

### Wichtige Konfigurationsdateien

| Datei                        | Zweck                 | Kritische Parameter              |
| ---------------------------- | --------------------- | -------------------------------- |
| `env/litellm.env`            | LiteLLM Konfiguration | LITELLM_MASTER_KEY, DATABASE_URL |
| `env/redis.env`              | Redis Einstellungen   | REDIS_PASSWORD                   |
| `conf/cloudflare/config.yml` | Cloudflare Tunnel     | tunnel, ingress rules            |
| `conf/nginx/nginx.conf`      | Nginx Konfiguration   | upstream, proxy_pass             |
| `compose.yml`                | Docker Compose        | services, networks, volumes      |

### Netzwerkarchitektur

```
Internet → Cloudflare → Nginx (8080) → OpenWebUI (8080)
 ↓
 LiteLLM (4000) ← → Ollama (11434)
 ↓
 SearXNG (8080) ← → Redis (6379)
 ↓
 PostgreSQL (5432)
```

### SLA und Leistungsmetriken

| Metrik                    | Zielwert | Kritischer Schwellenwert |
| ------------------------- | -------- | ------------------------ |
| API-Antwortzeit           | <1s      | >5s                      |
| Web-Interface Antwortzeit | <2s      | >10s                     |
| Systemverfügbarkeit       | >99%     | <95%                     |
| AI-Generierungszeit (GPU) | <3s      | >30s                     |
| SearXNG Suchzeit          | <2s      | >10s                     |

### Befehle zur Behebung typischer Probleme

{% raw %}

```bash
# Neustart eines problematischen Containers
docker restart erni-ki-[service-name]

# Logs bereinigen (falls voll)
docker logs erni-ki-[service-name] --since=1h > /tmp/service-logs.txt
docker exec erni-ki-[service-name] truncate -s 0 /var/log/*.log

# Ressourcennutzung prüfen
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Netzwerkverbindungen prüfen
docker network inspect erni-ki_default | jq -r '.[] | .Containers | keys[]'
```

{% endraw %}

---

## 7. AUTOMATISIERUNG DER DIAGNOSE

### Erstellung eines Diagnoseskripts

```bash
# Speichern als: scripts/health-check.sh
# !/bin/bash
set -e

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_FILE="diagnostic-report-${TIMESTAMP}.md"

{
 echo "# ERNI-KI DIAGNOSTIC REPORT"
 echo "Generated: $(date)"
 echo "Methodology Version: 2.0"
 echo

 # Alle Diagnosetests ausführen
 # ... (Befehle aus vorherigen Abschnitten)

 echo "## SUMMARY"
 echo "System Health: ${HEALTH_SCORE}%"
 echo "Critical Issues: ${CRITICAL_COUNT}"
 echo "Recommendations: ${RECOMMENDATION_COUNT}"

} > "${REPORT_FILE}"

echo "Diagnostic report saved to: ${REPORT_FILE}"
```

## Einrichtung regelmäßiger Diagnose

```bash
# Zu crontab hinzufügen für tägliche Diagnose um 06:00
0 6 * * * /path/to/erni-ki/scripts/health-check.sh >> /var/log/erni-ki-health.log 2>&1
```

---

## FAZIT

Diese Methodik zur Diagnose von ERNI-KI gewährleistet:

**Diagnosegenauigkeit**- Vermeidung falscher negativer Ergebnisse**Effizienz**-
schnelles Erkennen realer Probleme**Reproduzierbarkeit**- klare Befehle zur
Wiederholung von Tests**Priorisierung**- Fokus auf kritisch wichtige
Komponenten**Automatisierung**- Möglichkeit zur Erstellung automatischer
Prüfungen

**Schlüsselprinzip:**Prüfen Sie immer die aktuelle Konfiguration vor dem Testen
und verwenden Sie die korrekten Authentifizierungsparameter für jeden Service.

**Denken Sie daran:**Ein gut konfiguriertes ERNI-KI System kann auf einem Niveau
von 95%+ arbeiten - lassen Sie nicht zu, dass falsche Diagnose die reale
Bewertung senkt!
