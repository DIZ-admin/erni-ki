---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Budgetanalyse des ERNI-KI Projekts

**Analysedatum:**24. November 2025**Projektversion:**Production Ready v0.61.3
**Technologie-Stack:**32 Microservices, GPU-Beschleunigung, vollständige
Observability

---

## 1. Projektübersicht

**ERNI-KI**ist eine Enterprise-Grade KI-Plattform, basierend auf:

-**Open WebUI v0.6.36**— Benutzeroberfläche -**Ollama 0.12.11**— LLM-Server mit
GPU-Beschleunigung -**LiteLLM v1.80.0.rc.1**— Context Engineering Gateway -**32
Microservices**in Docker-Containern -**Full Monitoring Stack**(Prometheus,
Grafana, Loki, Alertmanager) -**Enterprise Security**(Cloudflare Zero Trust,
Nginx WAF, JWT Auth)

### Hauptkomponenten des Systems:

#### Application Layer (AI & Core)

- OpenWebUI (GPU) — Web-Interface mit CUDA Runtime
- Ollama — LLM Inference Engine (RTX 5000, 16GB VRAM)
- LiteLLM — API Gateway mit Context7 Integration
- SearXNG — Suchmaschine für RAG
- MCP Server — 7 aktive Tools

#### Processing Layer

- Docling — OCR und Dokumentenverarbeitung (GPU)
- Apache Tika — Textextraktion
- EdgeTTS — Sprachsynthese

#### Data Layer

- PostgreSQL 17 + pgvector — Hauptdatenbank
- Redis 7 — Cache und Queues
- Backrest — Backup-System

#### Gateway & Security

- Nginx 1.29.3 — Reverse Proxy, WAF, SSL/TLS
- Auth (Go 1.24) — JWT-Authentifizierungsservice
- Cloudflared — Cloudflare Tunnel für externen Zugriff

#### Observability Stack

- Prometheus v3.0.0 — Metrik-Sammlung (27 Alert Rules)
- Grafana v11.3.0 — Visualisierung (18 Dashboards)
- Loki v3.0.0 — Zentralisierte Logs
- Fluent Bit v3.1.0 — Log-Sammlung
- Alertmanager v0.27.0 — Alert-Management
- 8 Metrik-Exporters (node, postgres, redis, nvidia, cadvisor, blackbox, ollama,
  nginx)

#### Infrastructure

- Watchtower — Automatische Container-Updates
- Uptime Kuma — Service-Verfügbarkeitsüberwachung

---

## 2. Technologie-Stack

### Backend

-**Go 1.24.10**— Auth-Service, hochperformante Komponenten -**Python 3.x**—
Scripting, Automation, LiteLLM Custom Providers -**Shell/Bash**— Infrastructure
Automation Scripts

### Frontend & Web

-**TypeScript/JavaScript**— Frontend-Logik, Testing -**Node.js 20.18.0**— Build
Toolchain -**Nginx 1.29.3**— Webserver & Reverse Proxy

### Datenbanken & Storage

-**PostgreSQL 17**— Hauptdatenbank mit pgvector für Vektorsuche -**Redis 7**—
In-Memory Cache, Pub/Sub, Queues

### CI/CD & DevOps

-**Docker & Docker Compose**— Containerisierung -**GitHub Actions**— CI/CD
Pipelines -**Pre-commit Hooks**— Code-Qualität -**Playwright**— E2E
Testing -**Vitest**— Unit Testing

### Security & Compliance

-**Cloudflare Zero Trust**— Externer Zugriff -**CodeQL**— Statische
Sicherheitsanalyse -**Trivy/Grype**— Container-Scanning -**Checkov**— IaC
Security Scanner -**Gitleaks**— Secret Detection -**Snyk**— Dependency Scanning

### AI/ML Stack

-**CUDA 12.6**— GPU-Beschleunigung -**NVIDIA Container Runtime**— GPU in
Docker -**Ollama**— LLM Inference -**OpenWebUI**— AI Interface -**MCP (Model
Context Protocol)**— Tool-Integration

### Monitoring & Observability

-**Prometheus Stack**— Metrik-Sammlung -**Grafana Stack**— Visualisierung &
Dashboards -**Loki**— Log-Aggregation -**Fluent Bit**— Log-Shipping

---

## 3. Detaillierte Aufwandsschätzung

### 3.1 Architektur und Design (8-12 Wochen)

#### Phase 1: Anforderungen und Design (3-4 Wochen)

| Aufgabe             | Rolle                   | Zeit       | Beschreibung                                 |
| ------------------- | ----------------------- | ---------- | -------------------------------------------- |
| Anforderungsanalyse | Solution Architect + PM | 1 Woche    | Business-Anforderungen, AI-Modellauswahl     |
| Architektur-Design  | Solution Architect      | 1.5 Wochen | Microservice-Architektur Design              |
| Sicherheits-Design  | Security Architect      | 1 Woche    | Zero Trust, WAF, Verschlüsselung, Compliance |
| Daten-Design        | Data Architect          | 0.5 Wochen | DB-Schema, Vektorspeicher, Backups           |

**Team:**1 Solution Architect, 1 Security Architect, 1 Data Architect, 1 PM
**Gesamt:**3-4 Wochen parallele Arbeit

#### Phase 2: Infrastructure & DevOps (2-3 Wochen)

| Aufgabe               | Rolle             | Zeit       | Beschreibung                       |
| --------------------- | ----------------- | ---------- | ---------------------------------- |
| Docker-Umgebung Setup | DevOps Engineer   | 1 Woche    | Docker Compose, Netzwerke, Volumes |
| CI/CD Pipelines       | DevOps Engineer   | 1 Woche    | GitHub Actions, Security Scans     |
| Monitoring Setup      | DevOps Engineer   | 0.5 Wochen | Prometheus, Grafana, Loki          |
| GPU Infrastructure    | DevOps + SysAdmin | 0.5 Wochen | NVIDIA Runtime, CUDA Setup         |

**Team:**1 Senior DevOps Engineer, 1 SysAdmin**Gesamt:**2-3 Wochen

#### Phase 3: Security & Networking (2-3 Wochen)

| Aufgabe               | Rolle                  | Zeit       | Beschreibung              |
| --------------------- | ---------------------- | ---------- | ------------------------- |
| Cloudflare Zero Trust | Security Engineer      | 1 Woche    | Tunnels, Access Policies  |
| WAF & SSL/TLS         | Security Engineer      | 0.5 Wochen | Nginx Security Config     |
| JWT Auth Service      | Backend Developer (Go) | 1 Woche    | Entwicklung und Testing   |
| Security Scanning     | Security Engineer      | 0.5 Wochen | Setup Trivy, CodeQL, Snyk |

**Team:**1 Security Engineer, 1 Go Developer**Gesamt:**2-3 Wochen

---

### 3.2 Core Services Entwicklung (12-16 Wochen)

#### AI & ML Layer (4-6 Wochen)

| Komponente               | Rolle                      | Zeit       | Komplexität |
| ------------------------ | -------------------------- | ---------- | ----------- |
| Ollama Integration       | ML Engineer                | 1.5 Wochen |             |
| OpenWebUI Setup & Config | Full-stack Developer       | 2 Wochen   |             |
| LiteLLM Gateway          | Backend Developer (Python) | 2 Wochen   |             |
| MCP Server (7 Tools)     | Backend Developer (Python) | 1.5 Wochen |             |
| Docling OCR Pipeline     | ML Engineer                | 1 Woche    |             |
| SearXNG Integration      | Backend Developer          | 1 Woche    |             |

**Team:**1 ML Engineer, 1 Full-stack Developer, 2 Backend Developers (Python)
**Gesamt:**4-6 Wochen parallele Arbeit

#### Data Layer (3-4 Wochen)

| Komponente                | Rolle             | Zeit       | Komplexität |
| ------------------------- | ----------------- | ---------- | ----------- |
| PostgreSQL + pgvector     | Database Engineer | 1.5 Wochen |             |
| Redis Setup & Optimierung | Database Engineer | 1 Woche    |             |
| Backrest Backup System    | DevOps Engineer   | 1 Woche    |             |
| Database Migrationen      | Backend Developer | 0.5 Wochen |             |

**Team:**1 Database Engineer, 1 DevOps Engineer, 1 Backend Developer
**Gesamt:**3-4 Wochen

#### Processing Layer (2-3 Wochen)

| Komponente               | Rolle             | Zeit    | Komplexität |
| ------------------------ | ----------------- | ------- | ----------- |
| Apache Tika Integration  | Backend Developer | 1 Woche |             |
| EdgeTTS Service          | Backend Developer | 1 Woche |             |
| File Processing Pipeline | Backend Developer | 1 Woche |             |

**Team:**1-2 Backend Developers**Gesamt:**2-3 Wochen

#### Gateway & Proxy (2-3 Wochen)

| Komponente          | Rolle                  | Zeit       | Komplexität |
| ------------------- | ---------------------- | ---------- | ----------- |
| Nginx Konfiguration | DevOps Engineer        | 1.5 Wochen |             |
| Auth Service (Go)   | Backend Developer (Go) | 1.5 Wochen |             |
| Cloudflared Tunnels | DevOps Engineer        | 1 Woche    |             |

**Team:**1 DevOps Engineer, 1 Go Developer**Gesamt:**2-3 Wochen

---

### 3.3 Observability & Monitoring (4-5 Wochen)

| Komponente               | Rolle           | Zeit       | Komplexität |
| ------------------------ | --------------- | ---------- | ----------- |
| Prometheus Setup         | DevOps Engineer | 1 Woche    |             |
| 27 Alert Rules           | DevOps + SRE    | 1.5 Wochen |             |
| 18 Grafana Dashboards    | DevOps Engineer | 2 Wochen   |             |
| Loki Log Aggregation     | DevOps Engineer | 1 Woche    |             |
| Fluent Bit Konfiguration | DevOps Engineer | 0.5 Wochen |             |
| Alertmanager Setup       | SRE Engineer    | 1 Woche    |             |
| 8 Exporters Deployment   | DevOps Engineer | 1 Woche    |             |
| Uptime Kuma              | DevOps Engineer | 0.5 Wochen |             |

**Team:**1 Senior DevOps Engineer, 1 SRE Engineer**Gesamt:**4-5 Wochen

---

### 3.4 Dokumentation & Knowledge Base (6-8 Wochen)

| Aufgabe                  | Rolle             | Zeit       | Beschreibung                               |
| ------------------------ | ----------------- | ---------- | ------------------------------------------ |
| Technische Dokumentation | Technical Writer  | 3 Wochen   | Architektur, Betrieb, Troubleshooting      |
| User Academy Guides      | Technical Writer  | 2 Wochen   | Open WebUI Basics, Prompting, HowTo Guides |
| API Dokumentation        | Backend Developer | 1 Woche    | REST API, MCP Tools                        |
| Runbooks & Operations    | SRE Engineer      | 1.5 Wochen | Incident Response, Wartungsverfahren       |
| Übersetzungen (DE, EN)   | Technical Writer  | 1.5 Wochen | Mehrsprachigkeit (3 Sprachen)              |

**Team:**1 Technical Writer, 1 SRE Engineer, 1 Backend Developer**Gesamt:**6-8
Wochen parallele Arbeit

---

### 3.5 Testing & QA (6-8 Wochen)

| Test-Typ               | Rolle                  | Zeit       | Beschreibung                                  |
| ---------------------- | ---------------------- | ---------- | --------------------------------------------- |
| Unit Tests             | Developers (alle)      | 2 Wochen   | Go, Python, TypeScript Tests                  |
| Integration Tests      | QA Engineer            | 2 Wochen   | API-Integrationen, Service Mesh               |
| E2E Tests (Playwright) | QA Automation Engineer | 2 Wochen   | UI Flows, kritische Pfade                     |
| Load Testing           | Performance Engineer   | 1.5 Wochen | GPU-Nutzung, API-Latenz                       |
| Security Testing       | Security Engineer      | 1.5 Wochen | Penetration Testing, Vulnerability Assessment |
| UAT                    | Product Owner + Users  | 1 Woche    | User Acceptance Testing                       |

**Team:**2 QA Engineers, 1 QA Automation Engineer, 1 Performance Engineer, 1
Security Engineer**Gesamt:**6-8 Wochen (teilweise parallel mit Entwicklung)

---

### 3.6 Deployment & Production Readiness (3-4 Wochen)

| Aufgabe                | Rolle                | Zeit       | Beschreibung                      |
| ---------------------- | -------------------- | ---------- | --------------------------------- |
| Production Environment | DevOps + SysAdmin    | 1.5 Wochen | Hardware Setup, GPU-Konfiguration |
| Migration Scripts      | Backend Developer    | 1 Woche    | Datenmigration, Konfiguration     |
| Performance Tuning     | Performance Engineer | 1 Woche    | GPU-Optimierung, Caching          |
| Disaster Recovery      | SRE Engineer         | 1 Woche    | Backup-Tests, Failover-Verfahren  |
| Production Deployment  | DevOps Team          | 0.5 Wochen | Go-Live, Rollback-Plan            |

**Team:**1 DevOps, 1 SRE, 1 SysAdmin, 1 Performance Engineer, 1 Backend
Developer**Gesamt:**3-4 Wochen

---

## 4. Team-Schätzung

### Minimales Team (für MVP)

| Rolle                      | Anzahl | Gehalt/Monat      | Projektzeit |
| -------------------------- | ------ | ----------------- | ----------- |
| Solution Architect         | 1      | 12,000-18,000 CHF | 3 Monate    |
| Senior DevOps Engineer     | 1      | 10,000-14,000 CHF | 6 Monate    |
| Backend Developer (Go)     | 1      | 8,000-12,000 CHF  | 4 Monate    |
| Backend Developer (Python) | 2      | 8,000-12,000 CHF  | 5 Monate    |
| ML Engineer                | 1      | 10,000-15,000 CHF | 4 Monate    |
| Full-stack Developer       | 1      | 9,000-13,000 CHF  | 5 Monate    |
| QA Engineer                | 1      | 7,000-10,000 CHF  | 3 Monate    |
| Technical Writer           | 1      | 6,000-9,000 CHF   | 2 Monate    |
| Project Manager            | 1      | 9,000-13,000 CHF  | 6 Monate    |

**Minimales Team:**10 Personen

### Optimales Team (für Production-Ready)

| Rolle                      | Anzahl | Gehalt/Monat | Projektzeit |
| -------------------------- | ------ | ------------ | ----------- |
| Solution Architect         | 1      | 15,000 CHF   | 4 Monate    |
| Security Architect         | 1      | 14,000 CHF   | 3 Monate    |
| Senior DevOps Engineer     | 2      | 12,000 CHF   | 6 Monate    |
| SRE Engineer               | 1      | 11,000 CHF   | 5 Monate    |
| Backend Developer (Go)     | 2      | 10,000 CHF   | 5 Monate    |
| Backend Developer (Python) | 3      | 10,000 CHF   | 5 Monate    |
| ML Engineer                | 2      | 13,000 CHF   | 5 Monate    |
| Full-stack Developer       | 2      | 11,000 CHF   | 5 Monate    |
| Database Engineer          | 1      | 11,000 CHF   | 4 Monate    |
| QA Engineer                | 2      | 8,500 CHF    | 4 Monate    |
| QA Automation Engineer     | 1      | 10,000 CHF   | 4 Monate    |
| Performance Engineer       | 1      | 11,000 CHF   | 3 Monate    |
| Security Engineer          | 1      | 12,000 CHF   | 4 Monate    |
| Technical Writer           | 1      | 7,500 CHF    | 3 Monate    |
| Project Manager            | 1      | 11,000 CHF   | 6 Monate    |
| Product Owner              | 1      | 10,000 CHF   | 6 Monate    |

**Optimales Team:**23 Personen

---

## 5. Zeitschätzung

### Szenario 1: MVP (Minimal Viable Product)

**Zeit:**5-6 Monate**Team:**10 Personen**Beschreibung:**Basisfunktionalität,
begrenzte Dokumentation, minimales Monitoring

### Szenario 2: Production-Ready (aktuelle Version v0.61.3)

**Zeit:**8-10 Monate**Team:**20-23 Personen**Beschreibung:**Volle
Funktionalität, Enterprise Security, umfassende Dokumentation, 32 Services

### Aufschlüsselung nach Phasen (Production-Ready):

| Phase                       | Dauer      | Team (FTE)               |
| --------------------------- | ---------- | ------------------------ |
| Design und Architektur      | 2-3 Monate | 4-5                      |
| Core Development            | 4-5 Monate | 12-15                    |
| Observability & Monitoring  | 2-3 Monate | 2-3 (parallel)           |
| Dokumentation               | 3-4 Monate | 1-2 (parallel)           |
| Testing & QA                | 2-3 Monate | 4-5 (teilweise parallel) |
| Deployment & Stabilisierung | 1-2 Monate | 6-8                      |

**Gesamtzeit:**8-10 Monate unter Berücksichtigung paralleler Arbeit

---

## 6. Budgetschätzung (CHF)

### 6.1 Personalkosten

#### MVP-Szenario (5-6 Monate)

| Rolle              | Anzahl | Monate | Gehalt | Gesamt  |
| ------------------ | ------ | ------ | ------ | ------- |
| Solution Architect | 1      | 3      | 15,000 | 45,000  |
| Senior DevOps      | 1      | 6      | 12,000 | 72,000  |
| Backend (Go)       | 1      | 4      | 10,000 | 40,000  |
| Backend (Python)   | 2      | 5      | 10,000 | 100,000 |
| ML Engineer        | 1      | 4      | 13,000 | 52,000  |
| Full-stack Dev     | 1      | 5      | 11,000 | 55,000  |
| QA Engineer        | 1      | 3      | 8,500  | 25,500  |
| Technical Writer   | 1      | 2      | 7,500  | 15,000  |
| Project Manager    | 1      | 6      | 11,000 | 66,000  |

**Personal MVP gesamt:**470,500 CHF

#### Production-Ready Szenario (8-10 Monate)

| Rolle              | Anzahl × Monate | Gehalt | Gesamt  |
| ------------------ | --------------- | ------ | ------- |
| Solution Architect | 1 × 4           | 15,000 | 60,000  |
| Security Architect | 1 × 3           | 14,000 | 42,000  |
| Senior DevOps      | 2 × 6           | 12,000 | 144,000 |
| SRE Engineer       | 1 × 5           | 11,000 | 55,000  |
| Backend (Go)       | 2 × 5           | 10,000 | 100,000 |
| Backend (Python)   | 3 × 5           | 10,000 | 150,000 |
| ML Engineer        | 2 × 5           | 13,000 | 130,000 |
| Full-stack Dev     | 2 × 5           | 11,000 | 110,000 |
| Database Engineer  | 1 × 4           | 11,000 | 44,000  |
| QA Engineer        | 2 × 4           | 8,500  | 68,000  |
| QA Automation      | 1 × 4           | 10,000 | 40,000  |
| Performance Eng    | 1 × 3           | 11,000 | 33,000  |
| Security Engineer  | 1 × 4           | 12,000 | 48,000  |
| Technical Writer   | 1 × 3           | 7,500  | 22,500  |
| Project Manager    | 1 × 8           | 11,000 | 88,000  |
| Product Owner      | 1 × 8           | 10,000 | 80,000  |

**Personal Production gesamt:**1,214,500 CHF

### 6.2 Infrastrukturkosten

#### GPU Server (On-Premise)

| Komponente      | Spezifikation                         | Kosten            |
| --------------- | ------------------------------------- | ----------------- |
| GPU Server      | NVIDIA RTX 5000 (16GB) oder ähnlich   | 15,000-25,000 CHF |
| CPU/RAM/Storage | High-end Server (64GB+ RAM, NVMe SSD) | 8,000-12,000 CHF  |
| Backup-Hardware | Backup Server                         | 10,000-15,000 CHF |

**Hardware gesamt:**33,000-52,000 CHF

#### Cloud-Alternative (falls Cloud genutzt wird)

| Service                | Konfiguration              | Kosten/Monat    |
| ---------------------- | -------------------------- | --------------- |
| GPU Instance           | NVIDIA T4/A10 equivalent   | 1,500-3,000 CHF |
| Datenbank (PostgreSQL) | Managed, High-Availability | 500-800 CHF     |
| Object Storage         | Backups, Modelle, Daten    | 200-400 CHF     |
| Netzwerk/Traffic       | CDN, Bandbreite            | 300-500 CHF     |

**Cloud gesamt:**2,500-4,700 CHF/Monat × 12 Monate =**30,000-56,400 CHF/Jahr**

#### Lizenzen und Abonnements (jährliche Kosten)

| Service               | Zweck                          | Kosten/Jahr     |
| --------------------- | ------------------------------ | --------------- |
| Cloudflare Zero Trust | Externer Zugriff, Sicherheit   | 2,400-6,000 CHF |
| GitHub Enterprise     | CI/CD, Code-Management         | 2,500-5,000 CHF |
| Snyk                  | Security Scanning              | 1,200-3,000 CHF |
| Monitoring-Tools      | Uptime Kuma, zusätzliche Tools | 500-1,500 CHF   |
| SSL-Zertifikate       | Enterprise SSL/TLS             | 500-1,000 CHF   |
| AI API Keys           | OpenAI, PublicAI Fallbacks     | 1,000-3,000 CHF |

**Lizenzen gesamt:**8,100-19,500 CHF/Jahr

#### Entwicklung und DevOps Tooling

| Tool                   | Zweck                   | Kosten         |
| ---------------------- | ----------------------- | -------------- |
| JetBrains All Products | IDE für Team (20 Pers.) | 7,000 CHF/Jahr |
| Docker Hub Pro         | Container Registry      | 500 CHF/Jahr   |
| Confluence/Jira        | Dokumentation, PM       | 3,000 CHF/Jahr |
| Slack Business+        | Team-Kommunikation      | 1,500 CHF/Jahr |

**Tooling gesamt:**12,000 CHF/Jahr

---

### 6.3 Sonstige Kosten

| Kategorie                 | Beschreibung                        | Kosten             |
| ------------------------- | ----------------------------------- | ------------------ |
| Beratung                  | Security Audit, Compliance          | 15,000-30,000 CHF  |
| Schulung                  | Team-Training (AI, Security, Tools) | 10,000-20,000 CHF  |
| Unvorhergesehene Ausgaben | 10-15% des Budgets                  | 50,000-100,000 CHF |
| Legal & Compliance        | DSGVO, Datenschutz                  | 5,000-15,000 CHF   |

**Sonstige gesamt:**80,000-165,000 CHF

---

## 7. Gesamtbudget

### MVP-Szenario (5-6 Monate)

| Kategorie                  | Kosten      |
| -------------------------- | ----------- |
| Personal                   | 470,500 CHF |
| Infrastruktur (on-premise) | 40,000 CHF  |
| Lizenzen (6 Monate)        | 4,000 CHF   |
| Tooling (6 Monate)         | 6,000 CHF   |
| Sonstige                   | 50,000 CHF  |

**MVP gesamt:** **570,500 CHF**

### Production-Ready Szenario (8-10 Monate)

| Kategorie                  | Kosten        |
| -------------------------- | ------------- |
| Personal                   | 1,214,500 CHF |
| Infrastruktur (on-premise) | 45,000 CHF    |
| Lizenzen (12 Monate)       | 14,000 CHF    |
| Tooling (12 Monate)        | 12,000 CHF    |
| Sonstige                   | 100,000 CHF   |

**Production-Ready gesamt:** **1,385,500 CHF**

### Cloud-Alternative (Production-Ready)

| Kategorie                       | Kosten        |
| ------------------------------- | ------------- |
| Personal                        | 1,214,500 CHF |
| Cloud-Infrastruktur (12 Monate) | 42,000 CHF    |
| Lizenzen (12 Monate)            | 14,000 CHF    |
| Tooling (12 Monate)             | 12,000 CHF    |
| Sonstige                        | 100,000 CHF   |

**Cloud gesamt:** **1,382,500 CHF**(erstes Jahr)**Folgejahre (OpEx):**
~50,000-70,000 CHF/Jahr (Cloud + Lizenzen + Support)

---

## 8. Risikofaktoren & Contingency

### Budgetrelevante Risiken:

| Risiko                         | Wahrscheinlichkeit | Auswirkung     | Mitigation                                    |
| ------------------------------ | ------------------ | -------------- | --------------------------------------------- |
| GPU Knappheit/Verzögerungen    | Mittel             | +2-4 Wochen    | Hardware frühzeitig bestellen, Cloud-Fallback |
| Scope Creep                    | Hoch               | +20-30% Budget | Strikte Scope-Kontrolle, Change Management    |
| Integrations-Herausforderungen | Mittel             | +3-6 Wochen    | Proof-of-Concept für kritische Integrationen  |
| Sicherheits-Compliance         | Mittel             | +15,000 CHF    | Frühzeitiges Audit, Berater                   |
| Team-Verfügbarkeit             | Hoch               | +2-4 Wochen    | Reserve-Kandidaten, Überlappungsphasen        |

**Empfohlener Contingency Buffer:**15-20% des Gesamtbudgets

---

## 9. OpEx (Betriebskosten)

### Jährliche Kosten nach Launch (Production)

| Kategorie                         | Kosten/Jahr       |
| --------------------------------- | ----------------- |
| DevOps/SRE Team (2 FTE)           | 288,000 CHF       |
| Cloud-Infrastruktur (falls Cloud) | 30,000-50,000 CHF |
| Lizenzen und Abonnements          | 14,000 CHF        |
| Strom (on-premise GPU)            | 3,000-5,000 CHF   |
| Wartungsverträge                  | 5,000-10,000 CHF  |
| Security Updates/Patches          | 10,000-15,000 CHF |
| Dokumentations-Updates            | 15,000-20,000 CHF |

**OpEx gesamt (on-premise):**335,000-352,000 CHF/Jahr**OpEx gesamt (Cloud):**
362,000-397,000 CHF/Jahr

---

## 10. Vergleich Build vs Buy

### Build (aktuelles ERNI-KI Projekt)

-**CapEx:**1,385,500 CHF -**OpEx:**335,000 CHF/Jahr -**Total Cost of Ownership
(3 Jahre):**2,390,500 CHF -**Vorteile:**Volle Kontrolle, Anpassungsfähigkeit,
On-Premise Daten -**Nachteile:**Hohe Anfangsinvestition, Team erforderlich

### Buy (Kommerzielle AI-Plattform)

-**CapEx:**0-50,000 CHF (Setup) -**OpEx:**150,000-400,000 CHF/Jahr (Lizenzen +
Support) -**Total Cost of Ownership (3 Jahre):**500,000-1,250,000
CHF -**Vorteile:**Schneller Start, Vendor Support -**Nachteile:**Vendor Lock-in,
eingeschränkte Anpassung, Daten in der Cloud

### Hybrid (Managed + Custom Components)

-**CapEx:**400,000-600,000 CHF -**OpEx:**180,000-250,000 CHF/Jahr -**Total Cost
of Ownership (3 Jahre):**940,000-1,350,000 CHF

---

## 11. ROI-Analyse (Return on Investment)

### Erwarteter Projektwert

| Metrik                         | Wert/Jahr                        |
| ------------------------------ | -------------------------------- |
| Developer Productivity Gain    | 20-30% Effizienz                 |
| Cost Avoidance (Cloud AI APIs) | 50,000-150,000 CHF/Jahr          |
| Forschungsbeschleunigung       | 2-3x Prototyping-Geschwindigkeit |
| Wissensspeicherung             | Zentralisierte AI Knowledge Base |
| Wettbewerbsvorteil             | Proprietäre AI-Plattform         |

### Break-even Analyse (Build)

-**Initiale Investition:**1,385,500 CHF -**Jährliche Einsparungen vs.
Cloud-Plattformen:**~100,000 CHF -**Produktivitätsgewinne:**~200,000 CHF/Jahr
(geschätzt) -**Break-even:** **~4-5 Jahre**

---

## 12. Empfehlungen

### Für Projektstart von Grund auf:

1.**Mit MVP beginnen (6 Monate, 570K CHF)**

- Konzept beweisen
- Anforderungen validieren
- Schnelle Feedback-Schleife

  2.**Zu Production iterieren (zusätzlich 4 Monate, +800K CHF)**

- Basierend auf echtem Feedback skalieren
- Enterprise-Features schrittweise hinzufügen
- Risiken minimieren

  3.**Hybrid-Ansatz**

- Managed Services wo möglich nutzen (DB, Monitoring)
- Nur kritische Komponenten anpassen
- Cloud-first für Dev/Staging, On-Premise für Production

### Kritische Erfolgsfaktoren:

**Starke Architektur-Expertise**— Solution Architect ist kritisch**DevOps
Automation**— CI/CD von Tag 1**Security by Design**— nicht nachträglich
**Umfassende Dokumentation**— Wissen muss geteilt werden**Agile Methodik**—
iterative Lieferung, kein Wasserfall**Stakeholder Buy-in**— Executive Support
und klarer ROI

---

## 13. Fazit

**Das ERNI-KI Projekt**ist eine Enterprise-Grade AI-Plattform mit**32
Microservices**, die erhebliche Investitionen sowohl in Entwicklung als auch in
operativen Support erfordert.

### Kernzahlen:

-**Realisierungszeit:**8-10 Monate (production-ready) -**Team:**20-23
Spezialisten (Peak) -**CapEx (Build):**1,385,500 CHF -**OpEx
(Jährlich):**335,000-397,000 CHF -**TCO (3 Jahre):**2,39M CHF

### Alternativen:

-**MVP:**6 Monate, 570K CHF — Konzept beweisen -**Cloud-basiert:**Schneller,
aber +27K/Jahr OpEx -**Commercial kaufen:**Kurzfristig günstiger, aber Vendor
Lock-in

Das Projekt ist gerechtfertigt für Organisationen mit**hohen
Datensicherheitsanforderungen**,**Compliance**und**langfristiger AI-Strategie**.

---

**Erstellt von:**Antigravity AI Assistant**Datum:**24. November 2025
