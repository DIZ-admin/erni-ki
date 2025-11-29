---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Statusseite (Uptime Kuma)

Eine benutzerfreundliche Statusseite zeigt an, ob ERNI-KI-Services aktiv,
beeinträchtigt oder in Wartung sind. Sie wird von Uptime Kuma betrieben und im
selben internen Netzwerk wie andere Observability-Tools gehalten.

## Wo man sie findet

- Standard-lokale URL: `http://localhost:3001` (nur an localhost gebunden).
- Produktions-URL: Konfiguration über Reverse Proxy (z.B. `/status` oder
  dedizierte Subdomain). Gewählte URL hier dokumentieren: `<STATUS_PAGE_URL>`.
- Falls SSO erforderlich: bestehende Reverse-Proxy-Auth-Konfiguration
  wiederverwenden.

## Was die Statusmeldungen bedeuten

-**Operational:**Alle überwachten Checks sind gesund. -**Degraded:**Mindestens
ein Check schlägt fehl oder ist langsam; Grundfunktionen können noch
funktionieren. -**Maintenance:**Geplante Arbeiten laufen; Unterbrechungen
erwarten. -**Unknown:**Statusseite kann Checks nicht erreichen — Netzwerk oder
Container-Health prüfen.

## Wie man sie nutzt

1. Statusseite öffnen, bevor ein Incident-Ticket erstellt wird.
2. Wenn etwas rot oder degraded ist, Statuslink in Support-Anfrage teilen.
3. Für geplante Wartung News-Posts in `News` prüfen.

## Betriebshinweise

- Service läuft via Docker Compose als `uptime-kuma` mit Daten in
  `./data/uptime-kuma`.
- Expose-Port oder Basispfad über Reverse Proxy anpassen; Container nicht direkt
  ins Internet exponieren.
- `data/uptime-kuma`-Ordner mit anderen Monitoring-Daten sichern.
- Falls Container down ist: Neustart mit `docker compose up -d uptime-kuma` und
  Healthchecks verifizieren.

## Kontakte

- Platform On-Call Engineer für Ausfälle.
- Security oder Compliance für Zugriffs- und Policy-Fragen.
- Dokumentations-Maintainer für Updates dieser Seite.
