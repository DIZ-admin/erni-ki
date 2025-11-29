---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Architecture Documentation

Dieses Verzeichnis enthält die technische Dokumentation der ERNI-KI
Systemarchitektur.

## Inhalt

- **[architecture.md](architecture.md)** – Gesamtüberblick v0.61.3
  - Komponenten und Abhängigkeiten
  - Netzwerk/Ports
  - Service-Inventar und Mermaid-Diagramme

- **[services-overview.md](services-overview.md)** – Service-Katalog
  - AI/ML (Ollama, LiteLLM, Context7)
  - Daten (PostgreSQL, Redis)
  - Infrastruktur (Nginx, Cloudflare)
  - Monitoring (Prometheus, Grafana, Loki)

- **[service-inventory.md](service-inventory.md)** – Maschinenlesbarer Katalog

- **[nginx-configuration.md](nginx-configuration.md)** – Reverse Proxy Setup
  - SSL/TLS, Rate Limiting, WebSocket Proxy, Security Headers

## Quick Links

- [System Overview](../overview.md)
- [Operations Guide](../operations/README.md)
- [Installation Guide](../getting-started/installation.md)

## Version

Architekturversion: **12.1** (Wave 3) · Letzte Aktualisierung: **2025-11-22**
