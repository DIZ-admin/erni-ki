---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Project Budget Analysis

**Analysis Date:**November 24, 2025**Project Version:**Production Ready
v0.61.3**Technology Stack:**32 microservices, GPU acceleration, full
observability

---

## 1. Project Overview

**ERNI-KI**is an enterprise-grade AI platform built on:

-**Open WebUI v0.6.36**— User interface -**Ollama 0.12.11**— LLM server with GPU
acceleration -**LiteLLM v1.80.0.rc.1**— Context Engineering Gateway -**32
microservices**in Docker containers -**Full monitoring stack**(Prometheus,
Grafana, Loki, Alertmanager) -**Enterprise Security**(Cloudflare Zero Trust,
Nginx WAF, JWT Auth)

### Key System Components:

#### Application Layer (AI & Core)

- OpenWebUI (GPU) — Web interface with CUDA runtime
- Ollama — LLM inference engine (RTX 5000, 16GB VRAM)
- LiteLLM — API gateway with Context7 integration
- SearXNG — Search engine for RAG
- MCP Server — 7 active tools

#### Processing Layer

- Docling — OCR and document processing (GPU)
- Apache Tika — Text extraction
- EdgeTTS — Speech synthesis

#### Data Layer

- PostgreSQL 17 + pgvector — Main database
- Redis 7 — Cache and queues
- Backrest — Backup system

#### Gateway & Security

- Nginx 1.29.3 — Reverse proxy, WAF, SSL/TLS
- Auth (Go 1.24) — JWT authentication service
- Cloudflared — Cloudflare Tunnel for external access

#### Observability Stack

- Prometheus v3.0.0 — Metrics collection (27 alert rules)
- Grafana v11.3.0 — Visualization (18 dashboards)
- Loki v3.0.0 — Centralized logs
- Fluent Bit v3.1.0 — Log collection
- Alertmanager v0.27.0 — Alert management
- 8 metric exporters (node, postgres, redis, nvidia, cadvisor, blackbox, ollama,
  nginx)

#### Infrastructure

- Watchtower — Automatic container updates
- Uptime Kuma — Service availability monitoring

---

## 2. Technology Stack

### Backend

-**Go 1.24.10**— Auth service, high-performance components -**Python 3.x**—
Scripting, automation, LiteLLM custom providers -**Shell/Bash**— Infrastructure
automation scripts

### Frontend & Web

-**TypeScript/JavaScript**— Frontend logic, testing -**Node.js 20.18.0**— Build
toolchain -**Nginx 1.29.3**— Web server & reverse proxy

### Databases & Storage

-**PostgreSQL 17**— Main DB with pgvector for vector search -**Redis 7**—
In-memory cache, pub/sub, queues

### CI/CD & DevOps

-**Docker & Docker Compose**— Containerization -**GitHub Actions**— CI/CD
pipelines -**Pre-commit hooks**— Code quality -**Playwright**— E2E
testing -**Vitest**— Unit testing

### Security & Compliance

-**Cloudflare Zero Trust**— External access -**CodeQL**— Static security
analysis -**Trivy/Grype**— Container scanning -**Checkov**— IaC security
scanner -**Gitleaks**— Secret detection -**Snyk**— Dependency scanning

### AI/ML Stack

-**CUDA 12.6**— GPU acceleration -**NVIDIA Container Runtime**— GPU in
Docker -**Ollama**— LLM inference -**OpenWebUI**— AI interface -**MCP (Model
Context Protocol)**— Tool integration

### Monitoring & Observability

-**Prometheus Stack**— Metrics collection -**Grafana Stack**— Visualization &
dashboards -**Loki**— Log aggregation -**Fluent Bit**— Log shipping

---

## 3. Detailed Effort Estimation

### 3.1 Architecture and Design (8-12 weeks)

#### Phase 1: Requirements and Design (3-4 weeks)

| Task                   | Role                    | Time      | Description                                        |
| ---------------------- | ----------------------- | --------- | -------------------------------------------------- |
| Requirements gathering | Solution Architect + PM | 1 week    | Business requirements analysis, AI model selection |
| Architecture design    | Solution Architect      | 1.5 weeks | Microservice architecture design                   |
| Security design        | Security Architect      | 1 week    | Zero Trust, WAF, encryption, compliance            |
| Data design            | Data Architect          | 0.5 weeks | DB schema, vector storage, backups                 |

**Team:**1 Solution Architect, 1 Security Architect, 1 Data Architect, 1 PM
**Total:**3-4 weeks parallel work

#### Phase 2: Infrastructure & DevOps (2-3 weeks)

| Task                     | Role              | Time      | Description                       |
| ------------------------ | ----------------- | --------- | --------------------------------- |
| Docker environment setup | DevOps Engineer   | 1 week    | Docker Compose, networks, volumes |
| CI/CD pipelines          | DevOps Engineer   | 1 week    | GitHub Actions, security scans    |
| Monitoring setup         | DevOps Engineer   | 0.5 weeks | Prometheus, Grafana, Loki         |
| GPU infrastructure       | DevOps + SysAdmin | 0.5 weeks | NVIDIA runtime, CUDA setup        |

**Team:**1 Senior DevOps Engineer, 1 SysAdmin**Total:**2-3 weeks

#### Phase 3: Security & Networking (2-3 weeks)

| Task                  | Role                   | Time      | Description               |
| --------------------- | ---------------------- | --------- | ------------------------- |
| Cloudflare Zero Trust | Security Engineer      | 1 week    | Tunnels, access policies  |
| WAF & SSL/TLS         | Security Engineer      | 0.5 weeks | Nginx security config     |
| JWT Auth service      | Backend Developer (Go) | 1 week    | Development and testing   |
| Security scanning     | Security Engineer      | 0.5 weeks | Setup Trivy, CodeQL, Snyk |

**Team:**1 Security Engineer, 1 Go Developer**Total:**2-3 weeks

---

### 3.2 Core Services Development (12-16 weeks)

#### AI & ML Layer (4-6 weeks)

| Component                | Role                       | Time      | Complexity |
| ------------------------ | -------------------------- | --------- | ---------- |
| Ollama integration       | ML Engineer                | 1.5 weeks |            |
| OpenWebUI setup & config | Full-stack Developer       | 2 weeks   |            |
| LiteLLM gateway          | Backend Developer (Python) | 2 weeks   |            |
| MCP Server (7 tools)     | Backend Developer (Python) | 1.5 weeks |            |
| Docling OCR pipeline     | ML Engineer                | 1 week    |            |
| SearXNG integration      | Backend Developer          | 1 week    |            |

**Team:**1 ML Engineer, 1 Full-stack Developer, 2 Backend Developers (Python)
**Total:**4-6 weeks parallel work

#### Data Layer (3-4 weeks)

| Component                  | Role              | Time      | Complexity |
| -------------------------- | ----------------- | --------- | ---------- |
| PostgreSQL + pgvector      | Database Engineer | 1.5 weeks |            |
| Redis setup & optimization | Database Engineer | 1 week    |            |
| Backrest backup system     | DevOps Engineer   | 1 week    |            |
| Database migrations        | Backend Developer | 0.5 weeks |            |

**Team:**1 Database Engineer, 1 DevOps Engineer, 1 Backend Developer**Total:**
3-4 weeks

#### Processing Layer (2-3 weeks)

| Component                | Role              | Time   | Complexity |
| ------------------------ | ----------------- | ------ | ---------- |
| Apache Tika integration  | Backend Developer | 1 week |            |
| EdgeTTS service          | Backend Developer | 1 week |            |
| File processing pipeline | Backend Developer | 1 week |            |

**Team:**1-2 Backend Developers**Total:**2-3 weeks

#### Gateway & Proxy (2-3 weeks)

| Component           | Role                   | Time      | Complexity |
| ------------------- | ---------------------- | --------- | ---------- |
| Nginx configuration | DevOps Engineer        | 1.5 weeks |            |
| Auth service (Go)   | Backend Developer (Go) | 1.5 weeks |            |
| Cloudflared tunnels | DevOps Engineer        | 1 week    |            |

**Team:**1 DevOps Engineer, 1 Go Developer**Total:**2-3 weeks

---

### 3.3 Observability & Monitoring (4-5 weeks)

| Component                | Role            | Time      | Complexity |
| ------------------------ | --------------- | --------- | ---------- |
| Prometheus setup         | DevOps Engineer | 1 week    |            |
| 27 Alert rules           | DevOps + SRE    | 1.5 weeks |            |
| 18 Grafana Dashboards    | DevOps Engineer | 2 weeks   |            |
| Loki log aggregation     | DevOps Engineer | 1 week    |            |
| Fluent Bit configuration | DevOps Engineer | 0.5 weeks |            |
| Alertmanager setup       | SRE Engineer    | 1 week    |            |
| 8 Exporters deployment   | DevOps Engineer | 1 week    |            |
| Uptime Kuma              | DevOps Engineer | 0.5 weeks |            |

**Team:**1 Senior DevOps Engineer, 1 SRE Engineer**Total:**4-5 weeks

---

### 3.4 Documentation & Knowledge Base (6-8 weeks)

| Task                    | Role              | Time      | Description                                |
| ----------------------- | ----------------- | --------- | ------------------------------------------ |
| Technical documentation | Technical Writer  | 3 weeks   | Architecture, operations, troubleshooting  |
| User Academy guides     | Technical Writer  | 2 weeks   | Open WebUI basics, prompting, HowTo guides |
| API documentation       | Backend Developer | 1 week    | REST API, MCP tools                        |
| Runbooks & operations   | SRE Engineer      | 1.5 weeks | Incident response, maintenance procedures  |
| Translations (DE, EN)   | Technical Writer  | 1.5 weeks | Multilingual support (3 languages)         |

**Team:**1 Technical Writer, 1 SRE Engineer, 1 Backend Developer**Total:**6-8
weeks parallel work

---

### 3.5 Testing & QA (6-8 weeks)

| Testing Type           | Role                   | Time      | Description                                   |
| ---------------------- | ---------------------- | --------- | --------------------------------------------- |
| Unit tests             | Developers (all)       | 2 weeks   | Go, Python, TypeScript tests                  |
| Integration tests      | QA Engineer            | 2 weeks   | API integrations, service mesh                |
| E2E tests (Playwright) | QA Automation Engineer | 2 weeks   | UI flows, critical paths                      |
| Load testing           | Performance Engineer   | 1.5 weeks | GPU utilization, API latency                  |
| Security testing       | Security Engineer      | 1.5 weeks | Penetration testing, vulnerability assessment |
| UAT                    | Product Owner + Users  | 1 week    | User acceptance testing                       |

**Team:**2 QA Engineers, 1 QA Automation Engineer, 1 Performance Engineer, 1
Security Engineer**Total:**6-8 weeks (some parallel with development)

---

### 3.6 Deployment & Production Readiness (3-4 weeks)

| Task                   | Role                 | Time      | Description                         |
| ---------------------- | -------------------- | --------- | ----------------------------------- |
| Production environment | DevOps + SysAdmin    | 1.5 weeks | Hardware setup, GPU configuration   |
| Migration scripts      | Backend Developer    | 1 week    | Data migration, configuration       |
| Performance tuning     | Performance Engineer | 1 week    | GPU optimization, caching           |
| Disaster recovery      | SRE Engineer         | 1 week    | Backup testing, failover procedures |
| Production deployment  | DevOps Team          | 0.5 weeks | Go-live, rollback plan              |

**Team:**1 DevOps, 1 SRE, 1 SysAdmin, 1 Performance Engineer, 1 Backend
Developer**Total:**3-4 weeks

---

## 4. Team Estimation

### Minimum Team (for MVP)

| Role                       | Count | Salary/Month      | Project Time |
| -------------------------- | ----- | ----------------- | ------------ |
| Solution Architect         | 1     | 12,000-18,000 CHF | 3 months     |
| Senior DevOps Engineer     | 1     | 10,000-14,000 CHF | 6 months     |
| Backend Developer (Go)     | 1     | 8,000-12,000 CHF  | 4 months     |
| Backend Developer (Python) | 2     | 8,000-12,000 CHF  | 5 months     |
| ML Engineer                | 1     | 10,000-15,000 CHF | 4 months     |
| Full-stack Developer       | 1     | 9,000-13,000 CHF  | 5 months     |
| QA Engineer                | 1     | 7,000-10,000 CHF  | 3 months     |
| Technical Writer           | 1     | 6,000-9,000 CHF   | 2 months     |
| Project Manager            | 1     | 9,000-13,000 CHF  | 6 months     |

**Minimum team:**10 people

### Optimal Team (for Production-Ready)

| Role                       | Count | Salary/Month | Project Time |
| -------------------------- | ----- | ------------ | ------------ |
| Solution Architect         | 1     | 15,000 CHF   | 4 months     |
| Security Architect         | 1     | 14,000 CHF   | 3 months     |
| Senior DevOps Engineer     | 2     | 12,000 CHF   | 6 months     |
| SRE Engineer               | 1     | 11,000 CHF   | 5 months     |
| Backend Developer (Go)     | 2     | 10,000 CHF   | 5 months     |
| Backend Developer (Python) | 3     | 10,000 CHF   | 5 months     |
| ML Engineer                | 2     | 13,000 CHF   | 5 months     |
| Full-stack Developer       | 2     | 11,000 CHF   | 5 months     |
| Database Engineer          | 1     | 11,000 CHF   | 4 months     |
| QA Engineer                | 2     | 8,500 CHF    | 4 months     |
| QA Automation Engineer     | 1     | 10,000 CHF   | 4 months     |
| Performance Engineer       | 1     | 11,000 CHF   | 3 months     |
| Security Engineer          | 1     | 12,000 CHF   | 4 months     |
| Technical Writer           | 1     | 7,500 CHF    | 3 months     |
| Project Manager            | 1     | 11,000 CHF   | 6 months     |
| Product Owner              | 1     | 10,000 CHF   | 6 months     |

**Optimal team:**23 people

---

## 5. Time Estimation

### Scenario 1: MVP (Minimum Viable Product)

**Time:**5-6 months**Team:**10 people**Description:**Basic functionality,
limited documentation, minimal monitoring

### Scenario 2: Production-Ready (current version v0.61.3)

**Time:**8-10 months**Team:**20-23 people**Description:**Full functionality,
enterprise security, comprehensive documentation, 32 services

### Breakdown by phases (Production-Ready):

| Phase                      | Duration   | Team (FTE)               |
| -------------------------- | ---------- | ------------------------ |
| Design and architecture    | 2-3 months | 4-5                      |
| Core development           | 4-5 months | 12-15                    |
| Observability & monitoring | 2-3 months | 2-3 (parallel)           |
| Documentation              | 3-4 months | 1-2 (parallel)           |
| Testing & QA               | 2-3 months | 4-5 (partially parallel) |
| Deployment & stabilization | 1-2 months | 6-8                      |

**Total time:**8-10 months considering parallel work

---

## 6. Budget Estimation (CHF)

### 6.1 Personnel Costs

#### MVP Scenario (5-6 months)

| Role               | Count | Months | Salary | Total   |
| ------------------ | ----- | ------ | ------ | ------- |
| Solution Architect | 1     | 3      | 15,000 | 45,000  |
| Senior DevOps      | 1     | 6      | 12,000 | 72,000  |
| Backend (Go)       | 1     | 4      | 10,000 | 40,000  |
| Backend (Python)   | 2     | 5      | 10,000 | 100,000 |
| ML Engineer        | 1     | 4      | 13,000 | 52,000  |
| Full-stack Dev     | 1     | 5      | 11,000 | 55,000  |
| QA Engineer        | 1     | 3      | 8,500  | 25,500  |
| Technical Writer   | 1     | 2      | 7,500  | 15,000  |
| Project Manager    | 1     | 6      | 11,000 | 66,000  |

**Total personnel MVP:**470,500 CHF

#### Production-Ready Scenario (8-10 months)

| Role               | Count × Months | Salary | Total   |
| ------------------ | -------------- | ------ | ------- |
| Solution Architect | 1 × 4          | 15,000 | 60,000  |
| Security Architect | 1 × 3          | 14,000 | 42,000  |
| Senior DevOps      | 2 × 6          | 12,000 | 144,000 |
| SRE Engineer       | 1 × 5          | 11,000 | 55,000  |
| Backend (Go)       | 2 × 5          | 10,000 | 100,000 |
| Backend (Python)   | 3 × 5          | 10,000 | 150,000 |
| ML Engineer        | 2 × 5          | 13,000 | 130,000 |
| Full-stack Dev     | 2 × 5          | 11,000 | 110,000 |
| Database Engineer  | 1 × 4          | 11,000 | 44,000  |
| QA Engineer        | 2 × 4          | 8,500  | 68,000  |
| QA Automation      | 1 × 4          | 10,000 | 40,000  |
| Performance Eng    | 1 × 3          | 11,000 | 33,000  |
| Security Engineer  | 1 × 4          | 12,000 | 48,000  |
| Technical Writer   | 1 × 3          | 7,500  | 22,500  |
| Project Manager    | 1 × 8          | 11,000 | 88,000  |
| Product Owner      | 1 × 8          | 10,000 | 80,000  |

**Total personnel Production:**1,214,500 CHF

### 6.2 Infrastructure Costs

#### GPU Server (On-Premise)

| Component       | Specification                         | Cost              |
| --------------- | ------------------------------------- | ----------------- |
| GPU Server      | NVIDIA RTX 5000 (16GB) or equivalent  | 15,000-25,000 CHF |
| CPU/RAM/Storage | High-end server (64GB+ RAM, NVMe SSD) | 8,000-12,000 CHF  |
| Backup hardware | Backup server                         | 10,000-15,000 CHF |

**Total hardware:**33,000-52,000 CHF

#### Cloud Alternative (if using cloud)

| Service               | Configuration              | Cost/Month      |
| --------------------- | -------------------------- | --------------- |
| GPU Instance          | NVIDIA T4/A10 equivalent   | 1,500-3,000 CHF |
| Database (PostgreSQL) | Managed, High-availability | 500-800 CHF     |
| Object Storage        | Backups, models, data      | 200-400 CHF     |
| Network/Traffic       | CDN, bandwidth             | 300-500 CHF     |

**Total cloud:**2,500-4,700 CHF/month × 12 months =**30,000-56,400 CHF/year**

#### Licenses and Subscriptions (annual cost)

| Service               | Purpose                       | Cost/Year       |
| --------------------- | ----------------------------- | --------------- |
| Cloudflare Zero Trust | External access, security     | 2,400-6,000 CHF |
| GitHub Enterprise     | CI/CD, code management        | 2,500-5,000 CHF |
| Snyk                  | Security scanning             | 1,200-3,000 CHF |
| Monitoring tools      | Uptime Kuma, additional tools | 500-1,500 CHF   |
| SSL Certificates      | Enterprise SSL/TLS            | 500-1,000 CHF   |
| AI API Keys           | OpenAI, PublicAI fallbacks    | 1,000-3,000 CHF |

**Total licenses:**8,100-19,500 CHF/year

#### Development and DevOps Tooling

| Tool                   | Purpose                  | Cost           |
| ---------------------- | ------------------------ | -------------- |
| JetBrains All Products | IDE for team (20 people) | 7,000 CHF/year |
| Docker Hub Pro         | Container registry       | 500 CHF/year   |
| Confluence/Jira        | Documentation, PM        | 3,000 CHF/year |
| Slack Business+        | Team communication       | 1,500 CHF/year |

**Total tooling:**12,000 CHF/year

---

### 6.3 Other Costs

| Category           | Description                         | Cost               |
| ------------------ | ----------------------------------- | ------------------ |
| Consulting         | Security audit, compliance          | 15,000-30,000 CHF  |
| Training           | Team training (AI, security, tools) | 10,000-20,000 CHF  |
| Contingency        | 10-15% of budget                    | 50,000-100,000 CHF |
| Legal & Compliance | GDPR, data protection               | 5,000-15,000 CHF   |

**Total other:**80,000-165,000 CHF

---

## 7. Total Budget

### MVP Scenario (5-6 months)

| Category                    | Cost        |
| --------------------------- | ----------- |
| Personnel                   | 470,500 CHF |
| Infrastructure (on-premise) | 40,000 CHF  |
| Licenses (6 months)         | 4,000 CHF   |
| Tooling (6 months)          | 6,000 CHF   |
| Other                       | 50,000 CHF  |

**Total MVP:** **570,500 CHF**

### Production-Ready Scenario (8-10 months)

| Category                    | Cost          |
| --------------------------- | ------------- |
| Personnel                   | 1,214,500 CHF |
| Infrastructure (on-premise) | 45,000 CHF    |
| Licenses (12 months)        | 14,000 CHF    |
| Tooling (12 months)         | 12,000 CHF    |
| Other                       | 100,000 CHF   |

**Total Production-Ready:** **1,385,500 CHF**

### Cloud Alternative (Production-Ready)

| Category                         | Cost          |
| -------------------------------- | ------------- |
| Personnel                        | 1,214,500 CHF |
| Cloud infrastructure (12 months) | 42,000 CHF    |
| Licenses (12 months)             | 14,000 CHF    |
| Tooling (12 months)              | 12,000 CHF    |
| Other                            | 100,000 CHF   |

**Total Cloud:** **1,382,500 CHF**(first year)**Subsequent years (OpEx):**
~50,000-70,000 CHF/year (cloud + licenses + support)

---

## 8. Risk Factors & Contingency

### Budget-affecting risks:

| Risk                   | Probability | Impact         | Mitigation                                 |
| ---------------------- | ----------- | -------------- | ------------------------------------------ |
| GPU shortage/delays    | Medium      | +2-4 weeks     | Order hardware early, cloud fallback       |
| Scope creep            | High        | +20-30% budget | Strict scope control, change management    |
| Integration challenges | Medium      | +3-6 weeks     | Proof-of-concept for critical integrations |
| Security compliance    | Medium      | +15,000 CHF    | Early audit, consultants                   |
| Team availability      | High        | +2-4 weeks     | Reserve candidates, overlap periods        |

**Recommended contingency buffer:**15-20% of total budget

---

## 9. OpEx (Operating Expenses)

### Annual costs after launch (Production)

| Category                        | Cost/Year         |
| ------------------------------- | ----------------- |
| DevOps/SRE team (2 FTE)         | 288,000 CHF       |
| Cloud infrastructure (if cloud) | 30,000-50,000 CHF |
| Licenses and subscriptions      | 14,000 CHF        |
| Power (on-premise GPU)          | 3,000-5,000 CHF   |
| Maintenance contracts           | 5,000-10,000 CHF  |
| Security updates/patches        | 10,000-15,000 CHF |
| Documentation updates           | 15,000-20,000 CHF |

**Total OpEx (on-premise):**335,000-352,000 CHF/year**Total OpEx (cloud):**
362,000-397,000 CHF/year

---

## 10. Build vs Buy Comparison

### Build (current ERNI-KI project)

-**CapEx:**1,385,500 CHF -**OpEx:**335,000 CHF/year -**Total Cost of Ownership
(3 years):**2,390,500 CHF -**Advantages:**Full control, customization,
on-premise data -**Disadvantages:**High initial investment, requires team

### Buy (Commercial AI Platform)

-**CapEx:**0-50,000 CHF (setup) -**OpEx:**150,000-400,000 CHF/year (licenses +
support) -**Total Cost of Ownership (3 years):**500,000-1,250,000
CHF -**Advantages:**Fast start, vendor support -**Disadvantages:**Vendor
lock-in, limited customization, cloud data

### Hybrid (Managed + Custom Components)

-**CapEx:**400,000-600,000 CHF -**OpEx:**180,000-250,000 CHF/year -**Total Cost
of Ownership (3 years):**940,000-1,350,000 CHF

---

## 11. ROI Analysis (Return on Investment)

### Expected project value

| Metric                         | Value/Year                    |
| ------------------------------ | ----------------------------- |
| Developer productivity gain    | 20-30% efficiency             |
| Cost avoidance (cloud AI APIs) | 50,000-150,000 CHF/year       |
| Research acceleration          | 2-3x prototyping speed        |
| Knowledge retention            | Centralized AI knowledge base |
| Competitive advantage          | Proprietary AI platform       |

### Break-even Analysis (Build)

-**Initial investment:**1,385,500 CHF -**Annual savings vs. cloud
platforms:**~100,000 CHF -**Productivity gains:**~200,000 CHF/year
(estimated) -**Break-even:** **~4-5 years**

---

## 12. Recommendations

### For starting the project from scratch:

1.**Start with MVP (6 months, 570K CHF)**

- Prove concept
- Validate requirements
- Fast feedback loop

  2.**Iterate to Production (additional 4 months, +800K CHF)**

- Scale based on real feedback
- Add enterprise features incrementally
- Minimize risks

  3.**Hybrid approach**

- Use managed services where possible (DB, monitoring)
- Customize only critical components
- Cloud-first for dev/staging, on-premise for production

### Critical success factors:

**Strong architectural expertise**— Solution Architect is critical**DevOps
automation**— CI/CD from day 1**Security by design**— not an afterthought
**Comprehensive documentation**— knowledge must be shared**Agile methodology**—
iterative delivery, not waterfall**Stakeholder buy-in**— executive support and
clear ROI

---

## 13. Conclusion

**The ERNI-KI project**is an enterprise-grade AI platform with**32
microservices**requiring significant investment in both development and
operational support.

### Key figures:

-**Implementation time:**8-10 months (production-ready) -**Team:**20-23
specialists (peak) -**CapEx (Build):**1,385,500 CHF -**OpEx
(Annual):**335,000-397,000 CHF -**TCO (3 years):**2.39M CHF

### Alternatives:

-**MVP:**6 months, 570K CHF — prove concept -**Cloud-based:**Faster, but
+27K/year OpEx -**Buy commercial:**Cheaper short-term, but vendor lock-in

The project is justified for organizations with**high data security
requirements**,**compliance needs**, and**long-term AI strategy**.

---

**Prepared by:**Antigravity AI Assistant**Date:**November 24, 2025
