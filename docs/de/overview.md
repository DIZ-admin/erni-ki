---
language: de
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
title: ' ERNI-KI Dokumentation (Deutsch)'
system_version: '12.1'
date: '2025-11-22'
system_status: 'Production Ready'
audience: 'administrators'
---

# ERNI-KI Dokumentation (Deutsch)

> **Willkommen zur deutschen Dokumentation von ERNI-KI** **Version:** 12.1
> (Wave 3) · **Aktualisiert:** 2025-11-14

## Über ERNI-KI

<!-- STATUS_SNIPPET_DE_START -->

> **Systemstatus (2025-11-14) — Production Ready v12.1**
>
> - Container: 30/30 контейнеров healthy
> - Grafana: 5/5 Grafana Dashboards
> - Alerts: 20 Prometheus alert rules aktiv
> - AI/GPU: Ollama 0.12.11 + OpenWebUI v0.6.36 (GPU)
> - Context & RAG: LiteLLM v1.80.0.rc.1 + Context7, Docling, Tika, EdgeTTS
> - Monitoring: Prometheus v3.0.0, Grafana v11.3.0, Loki v3.0.0, Fluent Bit
>   v3.1.0, Alertmanager v0.27.0
> - Automatisierung: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00,
>   Backrest 01:30, Watchtower selective updates
> - Hinweis: Наблюдаемость и AI стек актуализированы в ноябре 2025

<!-- STATUS_SNIPPET_DE_END -->

ERNI-KI ist eine moderne, produktionsreife AI-Plattform basierend auf Open WebUI
mit vollständiger Containerisierung, GPU-Beschleunigung und umfassendem
Sicherheitssystem. Die Plattform bietet eine benutzerfreundliche Weboberfläche
für die Arbeit mit lokalen Sprachmodellen, RAG-Suche, Dokumentenverarbeitung und
Sprachinteraktion.

## Dokumentations-Übersicht

### Erste Schritte

- **[Installationsanleitung](getting-started/installation.md)** - Detaillierte
  Installationsschritte
- **[Benutzerhandbuch](getting-started/user-guide.md)** - Anleitung für
  Endbenutzer

### Technische Dokumentation

- **[Systemarchitektur](architecture/architecture.md)** - Technische Architektur
  und Service-Details
- **[Administrator-Handbuch](operations/core/admin-guide.md)** -
  Systemverwaltung und Betrieb
- **[Monitoring Übersicht](operations/monitoring/monitoring-guide.md)** -
  Kennzahlen, Skripte und Alerts
- **[Runbooks](operations/core/runbooks-summary.md)** - Deutsche
  Zusammenfassungen der wichtigsten Abläufe (englische Originale в
  `operations/maintenance/` und `operations/troubleshooting/`)
- **[API-Referenz](../reference/api-reference.md)** - API-Dokumentation
  (Englisch)

### Entwicklung

- **[Entwicklerhandbuch](../reference/development.md)** - Entwicklungsumgebung
  einrichten (Englisch)

## Zielgruppen

### **Endbenutzer**

Wenn Sie ERNI-KI verwenden möchten:

1. Beginnen Sie mit dem **[Benutzerhandbuch](getting-started/user-guide.md)**
2. Lernen Sie die Grundlagen der AI-Interaktion
3. Entdecken Sie erweiterte Funktionen wie RAG-Suche und Dokumentenverarbeitung

### ‍ **Administratoren**

Wenn Sie ERNI-KI installieren und verwalten:

1. Folgen Sie der **[Installationsanleitung](getting-started/installation.md)**
2. Studieren Sie die **[Systemarchitektur](architecture/architecture.md)**
3. Verwenden Sie das
   **[Administrator-Handbuch](operations/core/admin-guide.md)** für die tägliche
   Verwaltung

### ‍ **Entwickler**

Wenn Sie ERNI-KI erweitern oder anpassen möchten:

1. Verstehen Sie die **[Systemarchitektur](architecture/architecture.md)**
2. Lesen Sie das **[Entwicklerhandbuch](../reference/development.md)**
3. Nutzen Sie die **[API-Referenz](../reference/api-reference.md)**

## Schnellstart-Pfade

### ‍ **Schnelle Installation (30 Minuten)**

```bash
# Repository klonen
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki

# Konfiguration einrichten
cp compose.yml.example compose.yml
./scripts/generate-secrets.sh

# System starten
docker compose up -d

# Erstes Modell laden
docker compose exec ollama ollama pull llama3.2:3b
```

→ **Weiter mit:** [Installationsanleitung](getting-started/installation.md)

## **Erste Nutzung (10 Minuten)**

1. Browser öffnen: `https://ki.erni-gruppe.ch` (oder lokal:
   `http://localhost:8080`)
2. Administrator-Account erstellen
3. Ollama-Verbindung konfigurieren: `http://ollama:11434`
4. Ersten Chat mit AI starten

→ **Weiter mit:** [Benutzerhandbuch](getting-started/user-guide.md)

### **System-Administration**

1. Service-Status überwachen: `docker compose ps`
2. Logs prüfen: `docker compose logs -f`
3. Backups konfigurieren: `http://localhost:9898`
4. Benutzer verwalten

→ **Weiter mit:** [Administrator-Handbuch](operations/core/admin-guide.md)

## Hauptfunktionen

### **AI-Funktionen**

- **Lokale Sprachmodelle** - Vollständige Kontrolle über Ihre Daten
- **RAG-Suche** - Aktuelle Informationen aus dem Internet
- **Dokumentenverarbeitung** - PDF, DOCX, PPTX Analyse
- **Sprachinteraktion** - Ein- und Ausgabe über Sprache

### **Sicherheit**

- **JWT-Authentifizierung** - Sichere Benutzeranmeldung
- **SSL/TLS-Verschlüsselung** - Vollständige HTTPS-Unterstützung
- **Cloudflare Zero Trust** - Sichere Tunnel ohne offene Ports
- **Lokale Datenspeicherung** - Ihre Daten bleiben bei Ihnen

### **DevOps-Features**

- **Docker Compose** - Einfache Containerisierung
- **Automatische Backups** - Datenschutz durch Backrest
- **Health Monitoring** - Systemüberwachung
- **Auto-Updates** - Aktuelle Software-Versionen

## Systemanforderungen

### Minimum (Testen)

- **OS**: Ubuntu 20.04+ / Debian 11+
- **CPU**: 4 Kerne
- **RAM**: 8GB
- **Festplatte**: 50GB SSD
- **Docker**: 20.10+

### Empfohlen (Produktion)

- **CPU**: 8+ Kerne mit AVX2
- **RAM**: 32GB
- **GPU**: NVIDIA RTX 4060+ (8GB VRAM)
- **Festplatte**: 200GB+ NVMe SSD
- **Netzwerk**: 100 Mbps+

## Hilfe und Support

### **Dokumentation**

- Alle Anleitungen sind in dieser Dokumentation verfügbar
- Schritt-für-Schritt-Anleitungen mit Code-Beispielen
- Fehlerbehebungs-Guides für häufige Probleme

### **Problem-Meldung**

- **GitHub Issues**:
  [github.com/DIZ-admin/erni-ki/issues](https://github.com/DIZ-admin/erni-ki/issues)
- **Diskussionen**: GitHub Discussions für Fragen
- **Community**: Austausch mit anderen Benutzern

### **Diagnose-Tools**

## Pflegehinweis

- Status-Blöcke (oben auf dieser Seite und in anderen deutschen Dateien) werden
  aus `docs/reference/status.yml` generiert. Bei Änderungen bitte
  `scripts/docs/update_status_snippet.py` ausführen, damit deutsche und
  russische Fassungen synchron bleiben.
- Für detaillierte Runbooks und Monitoring-Schritte nutzen Sie die englischen
  Originale unter `docs/operations/` und
  `docs/operations/monitoring/monitoring-guide.md`.

```bash
# System-Gesundheit prüfen
docker compose ps
docker stats

# Logs analysieren
docker compose logs service-name

# API-Tests
curl http://localhost:8080/health
```

## Erweiterte Themen

### **Anpassung**

- Eigene Sprachmodelle hinzufügen
- Custom Nginx-Konfiguration
- Erweiterte Sicherheitseinstellungen
- Performance-Optimierung

### **Skalierung**

- Multi-GPU-Konfiguration
- Load Balancing
- Hochverfügbarkeits-Setup
- Monitoring und Alerting

### **Integration**

- API-Integration in eigene Anwendungen
- Single Sign-On (SSO) Konfiguration
- Externe Datenbank-Anbindung
- Custom MCP-Server

## Dokumentations-Beiträge

Diese Dokumentation ist Open Source und Beiträge sind willkommen:

1. **Übersetzungen verbessern** - Korrekturen und Verbesserungen
2. **Neue Anleitungen** - Zusätzliche Use Cases dokumentieren
3. **Screenshots hinzufügen** - Visuelle Hilfen für Benutzer
4. **FAQ erweitern** - Häufige Fragen beantworten

→ **Beitragen:** [Entwicklerhandbuch](../reference/development.md)

## Versionshinweise

- **v2.0** - Vollständige deutsche Übersetzung
- **v1.x** - Ursprüngliche englische/russische Dokumentation
- **Aktualisierungen** - Regelmäßige Updates mit neuen Features

---

## Los geht's

**Bereit zum Start?** Wählen Sie Ihren Pfad:

- **[Schnelle Installation](getting-started/installation.md)** - System in 30
  Minuten aufsetzen
- **[Benutzer-Guide](getting-started/user-guide.md)** - Sofort mit AI arbeiten
- **[Architektur verstehen](architecture/architecture.md)** - Technische Details

**Viel Erfolg mit ERNI-KI!**
