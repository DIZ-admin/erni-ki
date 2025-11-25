---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# MCP-Integrationsleitfaden für ERNI-KI

> **Dokumentversion:** 9.0 **Stand:** 2025-11-14 **Status:** Healthy (Port 8000,
> LiteLLM/Context7-Integration geprüft) [TOC]

## MCP-Überblick

Der MCP-Server in ERNI-KI stellt eine standardisierte Schnittstelle bereit, um
AI-Werkzeuge über das Model Context Protocol mit OpenWebUI v0.6.36 zu verbinden.
Aktiv sind derzeit vier MCP-Werkzeuge:

- **Time Server** – Zeitinformationen und Zeitzonen
- **PostgreSQL Server** – SQL-Abfragen gegen PostgreSQL 15.13 + pgvector 0.8.0
- **Filesystem Server** – Dateioperationen im freigegebenen Workspace
- **Memory Server** – Steuerung des Knowledge Graph / Memories

**Status:** Healthy, Laufzeit 2h, Port 8000.

## Architektur

```mermaid
graph TB
 A[OpenWebUI] --> B[Nginx Proxy]
 B --> C[MCPO Server :8000]
 C --> D[Time MCP Server]
 C --> E[PostgreSQL MCP Server]
 C --> F[Filesystem MCP Server]
 C --> G[Memory MCP Server]
 C --> H[SearXNG MCP Server]

 E --> I[PostgreSQL Database]
 H --> J[SearXNG Service]
 F --> K[File System]
```

### Verbindung zu LiteLLM / Context7

- Der LiteLLM-Gateway (Port 4000) ruft MCP-Tools über nginx (`/api/mcp/*`) auf,
  reichert sie mit Thinking Tokens an und leitet sie an Ollama weiter.
- Health-Checks: `curl -s http://localhost:4000/health/liveliness` und
  `curl -s http://localhost:8080/api/mcp/time/docs`.
- Monitoring: `scripts/monitor-litellm-memory.sh` sowie
  `scripts/infrastructure/monitoring/test-network-performance.sh` messen
  Verzögerungen LiteLLM ↔ MCP ↔ Ollama/PostgreSQL/Redis.
- Für Diagnosen Archon-Tasks + LiteLLM-Logs (`logs/litellm.log`) prüfen und
  sicherstellen, dass Context-Antworten `sources[]` und `reasoning_trace`
  enthalten.

## Aktueller Integrationsstatus

### Läuft stabil

1. **MCPO Server** – Port 8000 erreichbar
2. **Swagger UI** – <http://localhost:8000/docs>
3. **OpenAPI** – <http://localhost:8000/openapi.json>
4. **Alle 5 MCP-Server** – initialisiert und antworten
5. **Nginx Proxy** – routet korrekt zu den MCP-Servern
6. **OpenWebUI Konfiguration** – `TOOL_SERVER_CONNECTIONS` gesetzt

### Performance

- **API-Latenz:** <50 ms bei Standardoperationen
- **Time Server:** ~11 ms für `get_current_time`
- **PostgreSQL Server:** ~22 ms für einfache SELECTs
- **Verfügbarkeit:** 99,9 % (alle Health-Checks grün)

## Verfügbare MCP-Tools

### 1. Time Server (`/time`)

**Endpoints**

- `POST /time/get_current_time`
- `POST /time/convert_time`

**Beispiel**

```bash
curl -X POST "http://localhost:8000/time/get_current_time" \
 -H "Content-Type: application/json" \
 -d '{"timezone": "Europe/Berlin"}'
```

**Antwort**

```json
{
  "timezone": "Europe/Berlin",
  "datetime": "2025-08-25T14:17:47+02:00",
  "is_dst": true
}
```

### 2. PostgreSQL Server (`/postgres`)

- `POST /postgres/query` – beliebige SQL-Statements

```bash
curl -X POST "http://localhost:8000/postgres/query" \
 -H "Content-Type: application/json" \
 -d '{"sql": "SELECT version();"}'
```

### 3. Memory Server (`/memory`)

- 9 Operations: `add_memory`, `query_memory`, `delete_memory`, …
- Nutzt denselben Auth-Layer wie Time/Postgres

### 4. Filesystem Server (`/fs`)

- Dateiliste unterhalb des erlaubten Pfads
- Lesen/Schreiben kleiner Dateien und Directory-Watch

### 5. SearXNG Server (`/searxng`)

- Weiterleitung an SearXNG-Suche (nur intern freigeschaltet)

## Konfiguration

### `.env` (MCPO Server)

```
MCP_SERVER_HOST=0.0.0.0
MCP_SERVER_PORT=8000
MCP_POSTGRES_DSN=postgresql://erni_ki:${POSTGRES_PASSWORD}@postgres:5432/erni_ki
MCP_FILESYSTEM_ROOT=/workspace
MCP_LITELLM_BASE_URL=http://litellm:4000
```

### OpenWebUI `.env`

```
TOOL_SERVER_CONNECTIONS=http://mcp-server:8000
WORKFLOWS_DEFAULTS__toolconfig__0__connection_id=mcp-server
WORKFLOWS_DEFAULTS__toolconfig__0__tools__0=time
WORKFLOWS_DEFAULTS__toolconfig__0__tools__1=postgres
```

### LiteLLM `.env`

```
LITELLM_MCP_SERVER_URL=http://mcp-server:8000
LITELLM_MCP_API_KEY=${MCP_API_KEY}
```

## Validierung

1. `docker compose logs mcp-server -f`
2. `curl http://localhost:8000/health`
3. `curl http://localhost:8080/api/mcp/time/docs`
4. OpenWebUI → Tools → `time.get_current_time`

## Troubleshooting

| Problem                     | Ursache                   | Lösung                                        |
| --------------------------- | ------------------------- | --------------------------------------------- |
| `401 Unauthorized`          | Token/Headers fehlen      | `MCP_API_KEY` prüfen                          |
| `504 Timeout`               | Netzwerk/Firewall         | Tunnel/Proxy testen                           |
| `context deadline exceeded` | LiteLLM ↔ MCP zu langsam | `scripts/test-network-performance.sh` starten |
| `500 Internal Server Error` | Traceback im MCP-Log      | `docker compose logs mcp-server` prüfen       |

### Health-Skripte

- `scripts/health-monitor.sh` – ruft `/health` zyklisch auf
- `scripts/diagnostics/quick-mcpo-check.sh` – End-to-End-Test (siehe
  `scripts/core/diagnostics`)

## Sicherheit

- Secrets ausschließlich über `.env` oder CI-Secrets injizieren
- Keine Tokens im Repo ablegen; Beispielvariablen in `.example`-Dateien
- Self-Signed-Zertifikate außerhalb des Repos speichern (`conf/ca/`)
- Watchtower in Monitor-Modus belassen, damit MCP-Container nicht unkontrolliert
  aktualisiert wird

## Verwandte Dokumente

- `docs/reference/github-environments-setup.md`
- `docs/operations/monitoring/monitoring-guide.md`
- `docs/operations/monitoring/rag-monitoring.md`
- `scripts/core/diagnostics/quick-mcpo-check.sh`

## Tests & Automatisierung

### Manuelle Tests der Endpunkte

```bash
# Time Server testen
curl -X POST "http://localhost:8000/time/get_current_time" \
 -H "Content-Type: application/json" \
 -d '{"timezone": "Europe/Berlin"}'

# PostgreSQL Server testen
curl -X POST "http://localhost:8000/postgres/query" \
 -H "Content-Type: application/json" \
 -d '{"sql": "SELECT version();"}'

# Zugriff über Nginx-Proxy verifizieren
curl -s "http://localhost:8080/api/mcp/time/docs" | grep -q "swagger" && echo " Proxy OK"
```

## Automatische Diagnostik

```bash
./scripts/mcp/test-mcp-integration.sh
```

Der Skript führt Health-Checks, Latenzmessungen und Proxy-Validation im Paket
aus.

## Nutzung in OpenWebUI

### 1. Tool-Aufrufe

Nach gesetzten `TOOL_SERVER_CONNECTIONS` können Agents folgende Aufgaben
ausführen:

- **Zeitabfragen** für beliebige Zeitzonen
- **SQL-Reads** gegen die ERNI-KI-Datenbank
- **Dateioperationen**: lesen, schreiben, Auflistungen
- **Memory-Verwaltung**: Entities und Beziehungen anlegen/abfragen
- **Recherche** über SearXNG

### 2. Chat-Beispiele

```
User: Wie spät ist es in Berlin?
AI: Ruft time.get_current_time mit Europe/Berlin auf
```

```
User: Wie viele Benutzer sind registriert?
AI: Führt SELECT COUNT(*) FROM users über den PostgreSQL-Server aus
```

```
User: Liste alle *.conf Dateien in conf/
AI: Nutzt Filesystem-Server für eine rekursive Suche
```

## Detaillierte Konfiguration

`conf/mcposerver/config.json`

```json
{
 "mcpServers": {
 "time": {
 "command": "uvx",
 "args": ["mcp-server-time", "--local-timezone=Europe/Berlin"]
 },
 "postgres": {
 "command": "npx",
 "args": [
 "-y",
 "@modelcontextprotocol/server-postgres",
 "postgresql://postgres:postgres@db/openwebui" # pragma: allowlist secret
 ]
 }
 }
}
```

`env/mcposerver.env` enthält Host/Port/DSN und Tokens für den Dienst.

## Wiederherstellung

```bash
# Komponenten neu starten
docker compose restart mcposerver nginx openwebui

# Logs prüfen
docker compose logs --tail=50 mcposerver

# Vollständiger Integrationscheck
./scripts/mcp/test-mcp-integration.sh
```

## Monitoring

- **Antwortzeit**: <2 s für alle Endpunkte
- **Verfügbarkeit**: 99,9 %
- **RAM**: <512 MB
- **CPU**: <10 % im Nominalbetrieb

Alle Requests enthalten Logging zu Statuscode, Dauer, Client-IP und Endpoint.

## Roadmap

1. Weitere MCP-Server zur Tool-Erweiterung
2. Externe APIs via MCP anbinden
3. Performance-Optimierungen + Caching
4. Analyse & Telemetrie für Tool-Nutzung
5. Automatisches Skalieren der MCP-Komponenten

---

**Stand:** 2025-08-29 — **ERNI-KI Version:** 8.0 — **MCP Server:** latest
