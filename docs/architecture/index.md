---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Architecture Documentation

This directory contains comprehensive technical documentation of the ERNI-KI
system architecture.

## Contents

- **[architecture.md](architecture.md)** - Complete system architecture overview
  (v12.1)
  - System components and their interactions
  - Network architecture and port mappings
  - Service inventory and dependencies
  - Mermaid diagrams for visual reference

- **[services-overview.md](services-overview.md)** - Detailed service catalog
  - AI/ML services (Ollama, LiteLLM, Context7)
  - Data services (PostgreSQL, Redis)
  - Infrastructure services (Nginx, Cloudflare)
  - Monitoring stack (Prometheus, Grafana, Loki)

- **[service-inventory.md](service-inventory.md)** - Machine-readable service
  catalog

- **[nginx-configuration.md](nginx-configuration.md)** - Nginx reverse proxy
  setup
  - SSL/TLS configuration
  - Rate limiting
  - WebSocket proxying
  - Security headers

## Quick Links

- [System Overview](../overview.md)
- [Operations Guide](../operations/index.md)
- [Installation Guide](../getting-started/installation.md)

## Version

Current architecture version: **12.1** (Wave 3) Last updated: **2025-11-22**
