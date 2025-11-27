---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Sicherheitsdokumentation

Dieses Verzeichnis enthält alle sicherheitsrelevanten Richtlinien, Leitfäden und
Prozesse für die ERNI-KI-Plattform.

## Inhalt

### Security Guides

- **[authentication.md](authentication.md)** – Authentifizierung und
  Autorisierung
  - JWT- und Token-Handling
  - Nutzer- und Service-Authentifizierung
  - API-Key-Verwaltung
  - Rate-Limiting

- **[ssl-tls-setup.md](ssl-tls-setup.md)** – SSL/TLS-Konfiguration
  - Zertifikatsverwaltung
  - Cloudflare- und Zero-Trust-Anbindung
  - Überwachung von Ablaufdaten

### Security Policies

- **[security-best-practices.md](security-best-practices.md)** – Richtlinien
  - Sichere Konfiguration
  - Netzwerksicherheit
  - Datenschutz und Zugriffskontrolle

- **[log-audit.md](log-audit.md)** – Prüf- und Audit-Report
  - Quellen und Methodik
  - Findings und Remediation

- **[security-policy.md](security-policy.md)** – Rollen, Prozesse,
  Versionspolitik

## Quick Reference

**Für Administrator:innen**

- Authentifizierung konfigurieren: [authentication.md](authentication.md)
- TLS/SSL bereitstellen: [ssl-tls-setup.md](ssl-tls-setup.md)

**Für Entwickler:innen**

- Best Practices lesen: [security-best-practices.md](security-best-practices.md)

## Sicherheitsarchitektur

ERNI-KI setzt auf mehrere Schutzschichten:

- **JWT-Authentifizierung** – sichere Sessions für UI und API
- **SSL/TLS** – Verschlüsselung aller Kommunikationswege
- **Cloudflare Zero Trust** – DDoS-Schutz und abgesicherte Tunnel
- **Rate-Limiting** – Schutz vor Missbrauch
- **Lokale Datenspeicherung** – Datenhoheit und Backups on-prem

## Sicherheitsvorfälle melden

**Kein** öffentliches GitHub-Issue erstellen. Bitte melden an:
<security@erni-gruppe.ch>

## Verwandte Dokumentation

- [Architecture](../architecture/README.md)
- [Operations](../operations/README.md)
- [Getting Started](../getting-started/index.md)

## Version

Dokumentationsversion: **12.1** – Letzte Aktualisierung: **2025-11-22**
