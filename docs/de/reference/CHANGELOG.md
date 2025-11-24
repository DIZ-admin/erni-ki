---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# 📋 CHANGELOG - ERNI-KI Dokumentation


[TOC]

## [5.2.0] - 2025-11-18

### 🚀 OpenWebUI-Update

#### ✅ **OpenWebUI v0.6.34 → v0.6.36**

- **Aktualisierungsdatum**: 2025-11-18  
- **Version**: v0.6.34 → v0.6.36  
- **Status**: ✅ Erfolgreich aktualisiert  
- **Downtime**: 0 Minuten (Rolling Update)  
- **Kompatibilität**: LiteLLM, Docling, RAG und MCP-Integrationen bleiben erhalten

#### 🧹 **Veraltete Patches entfernt**

- Verzeichnis `patches/openwebui` geleert – Container läuft ohne lokale Patches
- Skript `scripts/entrypoints/openwebui.sh` wendet keine Patches mehr an
- `compose.yml` mountet das Patch-Verzeichnis nicht mehr

#### 📝 **Dokumentation synchronisiert**

- ✅ README.md / docs/index.md / docs/overview.md – Statusblöcke auf v0.6.36 gebracht
- ✅ docs/architecture/* (RU/DE) – Diagramme und Beschreibungen aktualisiert
- ✅ docs/reference/status*.md/yml – gemeinsame Snippets verweisen auf v0.6.36
- ✅ docs/operations/core/operations-handbook.md – Zielversionen aktualisiert

#### 🧪 **Post-Update-Checks**

- Voller Health-Check ausgeführt (`scripts/health-monitor.sh`)
- Service-Endpunkte OpenWebUI, LiteLLM, Docling, Monitoring sind healthy

#### 📟 **Monitoring**

- `postgres-exporter` erhält Flag `--no-collector.stat_bgwriter`, Fehler `checkpoints_timed` verschwinden
- Container neu gebaut (`docker compose up -d postgres-exporter postgres-exporter-proxy`), Logs sauber

#### 🔒 **Zusätzliche Härtung**

- Stub-Config `conf/postgres-exporter/config.yml` wird nun via `--config.file` übergeben
- LiteLLM (Port `127.0.0.1:4000`) und OpenWebUI in Watchtower „monitor-only“
- `scripts/health-monitor.sh` bekommt `HEALTH_MONITOR_LOG_WINDOW` und `HEALTH_MONITOR_LOG_IGNORE_REGEX`, entfernt Rauschen (LiteLLM cron, node-exporter broken pipe, cloudflared context canceled, redis-exporter Errorstats)
- Fluent Bit, nginx-exporter, nvidia-exporter, ollama-exporter, postgres-exporter-proxy und redis-exporter erhalten Docker Healthchecks → health-monitor zeigt 31/31 healthy
- Alertmanager Slack-Templates ohne `| default` → Fehler „function default not defined“ behoben
- Neuer Bericht: `logs/diagnostics/hardening-20251118.md`

---

## [5.1.0] - 2025-11-04

### 🚀 OpenWebUI-Update

#### ✅ **OpenWebUI v0.6.32 → v0.6.34**

- **Aktualisierungsdatum**: 2025-11-04  
- **Version**: v0.6.32 → v0.6.34  
- **Status**: ✅ Erfolgreich aktualisiert  
- **Downtime**: ~5 Minuten (Container-Neustart)  
- **Kompatibilität**: Alle Integrationen bleiben erhalten

#### 🔧 **Beibehaltener Integrationen**

- ✅ **PostgreSQL**: DB-Anbindung funktioniert
- ✅ **Ollama**: 4 Modelle verfügbar (gpt-oss:20b, gemma3:12b, llama3.2 (128K), nomic-embed-text)
- ✅ **SearXNG RAG**: Websuche funktionsfähig
- ✅ **LiteLLM**: Integration mit Context Engineering Gateway
- ✅ **GPU Acceleration**: NVIDIA Runtime aktiv

#### 🌐 **Cloudflare Tunnels – Routing-Fix**

- **Problem**: nginx:8080 in Docker-Netz nicht erreichbar (i/o timeout)
- **Lösung**: Konfiguration im Cloudflare-Dashboard angepasst  
  - `diz.zone`: `http://nginx:8080` → `http://openwebui:8080` ✅  
  - `lite.diz.zone`: `http://nginx:8080` → `http://litellm:4000` ✅  
  - `search.diz.zone`: `http://searxng:8080` (unverändert) ✅
- **Ergebnis**: Alle 5 Domains via HTTPS erreichbar  
  - ✅ diz.zone – HTTP 200 (OpenWebUI)  
  - ✅ webui.diz.zone – HTTP 200 (OpenWebUI)  
  - ✅ ki.erni-gruppe.ch – HTTP 200 (OpenWebUI)  
  - ✅ search.diz.zone – HTTP 200 (SearXNG)  
  - ✅ lite.diz.zone – HTTP 401 (LiteLLM erfordert Auth)

#### 📊 **Systemstatus nach Update**

- **Container**: 30/30 laufen
- **Healthy Services**: 25/30 (5 Exporter ohne Healthcheck)
- **Kritische Fehler**: Keine
- **GPU**: Verfügbar, Modelle werden bei Bedarf geladen
- **Performance**: Keine Degradierung

#### 📝 **Dokumentation aktualisiert**

- ✅ README.md – Version OpenWebUI auf v0.6.34
- ✅ docs/architecture/architecture.md – Diagramm aktualisiert
- ✅ docs/locales/de/architecture.md – deutsche Version synchronisiert
- ✅ CHANGELOG.md – Eintrag hinzugefügt

#### 🔍 **Gefundene Probleme**

1. **PostgreSQL Exporter** (🟡 Mittel)  
   - Fehler: `column "checkpoints_timed" does not exist`  
   - Auswirkung: Einige PostgreSQL-Metriken fehlen  
   - Status: Nicht kritisch, erfordert Config-Update

2. **Nginx Docker Network** (🟡 Mittel)  
   - Problem: nginx:8080 aus Docker-Netz nicht erreichbar  
   - Workaround: Direkte Anbindung über Cloudflare Dashboard  
   - Status: Weitere Analyse nötig

#### 🎯 **Erfolgskriterien erfüllt**

- ✅ OpenWebUI auf v0.6.34 aktualisiert  
- ✅ Alle Domains via HTTPS (HTTP 200) erreichbar  
- ✅ Alle Integrationen funktionsfähig  
- ✅ GPU-Beschleunigung aktiv  
- ✅ Keine kritischen cloudflared-Fehler  
- ✅ Doku aktualisiert

---

## [5.0.0] - 2025-07-25

### 🚀 Major Updates

#### ✅ **Architekturdokumentation aktualisiert**

- **Dokuversion**: 4.0 → 5.0  
- **Services**: 24 → 25 (webhook-receiver hinzugefügt)  
- **Mermaid-Diagramme**: Alle aktualisiert  
- **Ports/Endpoints**: Vollständig aktualisiert

#### 📨 **Webhook Receiver Integration**

- **Neuer Service**: webhook-receiver zur Architektur hinzugefügt  
- **Ports**: 9095 (extern), 9093 (intern)  
- **Funktionen**: Alertmanager-Alerts empfangen, loggen, JSON formatieren  
- **Diagramme**: In allen Architekturschemata ergänzt

#### 🎮 **GPU-Monitoring erweitert**

- **NVIDIA GPU Exporter**: Port 9445 dokumentiert  
- **Metriken**: Temperatur, Auslastung, GPU-Speicher  
- **Dashboards**: GPU-Dashboard in Grafana beschrieben  
- **Alerts**: Kritische GPU-Parameter dokumentiert

#### 📊 **Monitoring-System-Doku**

- **Prometheus**: Port 9091 (statt 9090)  
- **Grafana**: Port 3000  
- **Alertmanager**: Ports 9093–9094  
- **Exporter**: Ports aktualisiert

### 🔧 **Operations-Dokumentation**

#### 📖 **Troubleshooting Guide Updates**

- **Webhook Receiver**: Neuer Diagnostik-Abschnitt  
  - Status- und Log-Checks  
  - Endpoint-Tests  
  - Wiederherstellungsprozeduren
- **GPU Monitoring**: Erweiterte Diagnostik  
  - NVIDIA GPU Exporter Checks  
  - GPU-Metrik-Validierung  
  - Container-GPU-Tests

#### 🛠️ **Installation Guide Updates**

- **Monitoring**: UI-URLs aktualisiert  
  - Grafana: <http://localhost:3000>  
  - Prometheus: <http://localhost:9091>  
  - Alertmanager: <http://localhost:9093>  
  - Webhook Receiver: <http://localhost:9095/health>  
- **GPU Setup**: Checks für GPU-Monitoring ergänzt

### 🌍 **Mehrsprachige Dokumentation**

#### 🇩🇪 **Deutsche Lokalisierung**

- **Architecture.md**: Mit russischer Version synchronisiert  
- **Version**: 3.0 → 5.0  
- **Services**: 16 → 25  
- **Monitoring Layer**: Vollständig ergänzt  
- **Webhook Receiver**: In DE-Diagramm aufgenommen

### 📁 **Geänderte Dateien**

#### 🔄 **Aktualisierte Dateien**

- `docs/architecture/architecture.md` – Hauptarchitektur-Doku  
- `docs/operations/troubleshooting.md` – Troubleshooting Guide  
- `docs/getting-started/installation.md` – Installationsanleitung  
- `docs/locales/de/architecture.md` – Deutsche Architektur  
- `README.md` – Projektstartseite

#### 📦 **Backups**

- `.config-backup/docs/20250725_145457/` – Vollbackup der vorherigen Version  
- Enthält alle Doku-Dateien und README.md

### 🎯 **Erfolgskriterien erreicht**

#### ✅ **Architektur-Doku**

- [x] Darstellung aller 25+ Services  
- [x] Aktuelle Mermaid-Diagramme inkl. webhook-receiver  
- [x] Ports und Endpoints aktualisiert  
- [x] Integration mit Cloudflare Tunnels

#### ✅ **Operations-Doku**

- [x] Anleitungen für webhook-receiver  
- [x] GPU-Monitoring-Prozeduren  
- [x] Troubleshooting Guide erweitert  
- [x] Installation Guide aktualisiert

#### ✅ **Mehrsprachige Unterstützung**

- [x] Deutsche Lokalisierung synchronisiert  
- [x] Konsistente Terminologie  
- [x] Versionsangaben aktualisiert

#### ✅ **Backups & Versionierung**

- [x] Backup der Vorversion erstellt  
- [x] Versionssprung 4.0 → 5.0 dokumentiert  
- [x] Dieser Changelog enthält alle Schritte  
- [x] `last_updated`-Werte aktualisiert

### 🔗 **Verknüpfte Änderungen**

#### 🐳 **Docker Compose**

- webhook-receiver zu `compose.production.yml` hinzugefügt  
- Port 9095:9093 gemappt  
- Healthchecks aktiviert

#### 📈 **Monitoring Stack**

- Prometheus-Konfiguration aktualisiert  
- Grafana-Dashboards mit GPU-Metriken erweitert  
- Alertmanager → webhook-receiver angebunden

### 📊 **Änderungs-Statistik**

- **Aktualisierte Dateien**: 5  
- **Hinzugefügte Zeilen**: ~200  
- **Neue Abschnitte**: 3  
- **Aktualisierte Diagramme**: 2  
- **Synchronisierte Sprachen**: 2 (RU, DE)

---

## [4.0.0] - 2025-07-15

### Änderungen der Vorgängerversion

- LiteLLM-Integration  
- Docling-Service ergänzt  
- Context Engineering implementiert  
- Netzwerkoptimierung abgeschlossen

---

**Hinweis:** Dieser Changelog fasst die Doku-Aktualisierungen zusammen, die mit
der Wiederherstellung und Optimierung des ERNI-KI-Monitorings einhergingen.
