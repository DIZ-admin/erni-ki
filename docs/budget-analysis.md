---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# 📊 Анализ Затратного Бюджета Проекта ERNI-KI

**Дата анализа:** 24 ноября 2025 **Версия проекта:** Production Ready v12.1
**Технологический стек:** 32 микросервиса, GPU-ускорение, полная обсервабилити

---

## 1. Обзор Проекта

**ERNI-KI** — это корпоративная AI-платформа enterprise-класса, построенная на
базе:

- **Open WebUI v0.6.36** — пользовательский интерфейс
- **Ollama 0.12.11** — LLM-сервер с GPU-ускорением
- **LiteLLM v1.80.0.rc.1** — Context Engineering Gateway
- **32 микросервиса** в Docker контейнерах
- **Полный стек мониторинга** (Prometheus, Grafana, Loki, Alertmanager)
- **Enterprise Security** (Cloudflare Zero Trust, Nginx WAF, JWT Auth)

### Ключевые компоненты системы:

#### 🤖 Application Layer (AI & Core)

- OpenWebUI (GPU) — веб-интерфейс с CUDA runtime
- Ollama — LLM inference engine (RTX 5000, 16GB VRAM)
- LiteLLM — API gateway с Context7 интеграцией
- SearXNG — поисковый движок для RAG
- MCP Server — 7 активных инструментов

#### 🔧 Processing Layer

- Docling — OCR и обработка документов (GPU)
- Apache Tika — извлечение текста
- EdgeTTS — синтез речи

#### 💾 Data Layer

- PostgreSQL 17 + pgvector — основная база данных
- Redis 7 — кэш и очереди
- Backrest — система резервного копирования

#### 🚪 Gateway & Security

- Nginx 1.29.3 — reverse proxy, WAF, SSL/TLS
- Auth (Go 1.24) — JWT-сервис аутентификации
- Cloudflared — Cloudflare Tunnel для внешнего доступа

#### 📊 Observability Stack

- Prometheus v3.0.0 — сбор метрик (27 alert rules)
- Grafana v11.3.0 — визуализация (18 дашбордов)
- Loki v3.0.0 — централизованные логи
- Fluent Bit v3.1.0 — сбор логов
- Alertmanager v0.27.0 — управление алертами
- 8 экспортеров метрик (node, postgres, redis, nvidia, cadvisor, blackbox,
  ollama, nginx)

#### 🛠️ Infrastructure

- Watchtower — автоматические обновления контейнеров
- Uptime Kuma — мониторинг доступности сервисов

---

## 2. Технологический Стек

### Backend

- **Go 1.24.10** — Auth сервис, высокопроизводительные компоненты
- **Python 3.x** — Scripting, automation, LiteLLM custom providers
- **Shell/Bash** — Infrastructure automation scripts

### Frontend & Web

- **TypeScript/JavaScript** — Frontend logic, testing
- **Node.js 20.18.0** — Build toolchain
- **Nginx 1.29.3** — Web server & reverse proxy

### Databases & Storage

- **PostgreSQL 17** — Основная БД с pgvector для векторного поиска
- **Redis 7** — In-memory cache, pub/sub, queues

### CI/CD & DevOps

- **Docker & Docker Compose** — Контейнеризация
- **GitHub Actions** — CI/CD pipelines
- **Pre-commit hooks** — Код-качество
- **Playwright** — E2E тестирование
- **Vitest** — Unit тестирование

### Security & Compliance

- **Cloudflare Zero Trust** — Внешний доступ
- **CodeQL** — Статический анализ безопасности
- **Trivy/Grype** — Сканирование контейнеров
- **Checkov** — IaC security scanner
- **Gitleaks** — Поиск секретов
- **Snyk** — Dependency scanning

### AI/ML Stack

- **CUDA 12.6** — GPU ускорение
- **NVIDIA Container Runtime** — GPU в Docker
- **Ollama** — LLM inference
- **OpenWebUI** — AI interface
- **MCP (Model Context Protocol)** — Интеграция инструментов

### Monitoring & Observability

- **Prometheus Stack** — Metrics collection
- **Grafana Stack** — Visualization & Dashboards
- **Loki** — Log aggregation
- **Fluent Bit** — Log shipping

---

## 3. Детальная Оценка Трудозатрат

### 3.1 Архитектура и Проектирование (8-12 недель)

#### Фаза 1: Требования и Дизайн (3-4 недели)

| Задача               | Роль                    | Время      | Описание                                   |
| -------------------- | ----------------------- | ---------- | ------------------------------------------ |
| Сбор требований      | Solution Architect + PM | 1 неделя   | Анализ бизнес-требований, выбор AI моделей |
| Архитектурный дизайн | Solution Architect      | 1.5 недели | Проектирование микросервисной архитектуры  |
| Дизайн безопасности  | Security Architect      | 1 неделя   | Zero Trust, WAF, encryption, compliance    |
| Дизайн данных        | Data Architect          | 0.5 недели | Схема БД, векторное хранилище, бэкапы      |

**Команда:** 1 Solution Architect, 1 Security Architect, 1 Data Architect, 1 PM
**Итого:** 3-4 недели параллельной работы

#### Фаза 2: Инфраструктура и DevOps (2-3 недели)

| Задача                 | Роль              | Время      | Описание                       |
| ---------------------- | ----------------- | ---------- | ------------------------------ |
| Setup Docker окружения | DevOps Engineer   | 1 неделя   | Docker Compose, сети, volumes  |
| CI/CD pipelines        | DevOps Engineer   | 1 неделя   | GitHub Actions, security scans |
| Мониторинг setup       | DevOps Engineer   | 0.5 недели | Prometheus, Grafana, Loki      |
| GPU infrastructure     | DevOps + SysAdmin | 0.5 недели | NVIDIA runtime, CUDA setup     |

**Команда:** 1 Senior DevOps Engineer, 1 SysAdmin **Итого:** 2-3 недели

#### Фаза 3: Security & Networking (2-3 недели)

| Задача                | Роль                   | Время      | Описание                  |
| --------------------- | ---------------------- | ---------- | ------------------------- |
| Cloudflare Zero Trust | Security Engineer      | 1 неделя   | Tunnels, access policies  |
| WAF & SSL/TLS         | Security Engineer      | 0.5 недели | Nginx security config     |
| JWT Auth service      | Backend Developer (Go) | 1 неделя   | Разработка и тестирование |
| Security scanning     | Security Engineer      | 0.5 недели | Setup Trivy, CodeQL, Snyk |

**Команда:** 1 Security Engineer, 1 Go Developer **Итого:** 2-3 недели

---

### 3.2 Разработка Core Services (12-16 недель)

#### AI & ML Layer (4-6 недель)

| Компонент                | Роль                       | Время      | Сложность |
| ------------------------ | -------------------------- | ---------- | --------- |
| Ollama интеграция        | ML Engineer                | 1.5 недели | ⭐⭐⭐    |
| OpenWebUI setup & config | Full-stack Developer       | 2 недели   | ⭐⭐⭐⭐  |
| LiteLLM gateway          | Backend Developer (Python) | 2 недели   | ⭐⭐⭐⭐  |
| MCP Server (7 tools)     | Backend Developer (Python) | 1.5 недели | ⭐⭐⭐⭐  |
| Docling OCR pipeline     | ML Engineer                | 1 неделя   | ⭐⭐⭐    |
| SearXNG integration      | Backend Developer          | 1 неделя   | ⭐⭐      |

**Команда:** 1 ML Engineer, 1 Full-stack Developer, 2 Backend Developers
(Python) **Итого:** 4-6 недель параллельной работы

#### Data Layer (3-4 недели)

| Компонент                  | Роль              | Время      | Сложность |
| -------------------------- | ----------------- | ---------- | --------- |
| PostgreSQL + pgvector      | Database Engineer | 1.5 недели | ⭐⭐⭐    |
| Redis setup & optimization | Database Engineer | 1 неделя   | ⭐⭐      |
| Backrest backup system     | DevOps Engineer   | 1 неделя   | ⭐⭐      |
| Database migrations        | Backend Developer | 0.5 недели | ⭐⭐      |

**Команда:** 1 Database Engineer, 1 DevOps Engineer, 1 Backend Developer
**Итого:** 3-4 недели

#### Processing Layer (2-3 недели)

| Компонент                | Роль              | Время    | Сложность |
| ------------------------ | ----------------- | -------- | --------- |
| Apache Tika integration  | Backend Developer | 1 неделя | ⭐⭐      |
| EdgeTTS service          | Backend Developer | 1 неделя | ⭐⭐      |
| File processing pipeline | Backend Developer | 1 неделя | ⭐⭐⭐    |

**Команда:** 1-2 Backend Developers **Итого:** 2-3 недели

#### Gateway & Proxy (2-3 недели)

| Компонент           | Роль                   | Время      | Сложность |
| ------------------- | ---------------------- | ---------- | --------- |
| Nginx configuration | DevOps Engineer        | 1.5 недели | ⭐⭐⭐⭐  |
| Auth service (Go)   | Backend Developer (Go) | 1.5 недели | ⭐⭐⭐    |
| Cloudflared tunnels | DevOps Engineer        | 1 неделя   | ⭐⭐      |

**Команда:** 1 DevOps Engineer, 1 Go Developer **Итого:** 2-3 недели

---

### 3.3 Observability & Monitoring (4-5 недель)

| Компонент                | Роль            | Время      | Сложность  |
| ------------------------ | --------------- | ---------- | ---------- |
| Prometheus setup         | DevOps Engineer | 1 неделя   | ⭐⭐⭐     |
| 27 Alert rules           | DevOps + SRE    | 1.5 недели | ⭐⭐⭐⭐   |
| 18 Grafana Dashboards    | DevOps Engineer | 2 недели   | ⭐⭐⭐⭐⭐ |
| Loki log aggregation     | DevOps Engineer | 1 неделя   | ⭐⭐⭐     |
| Fluent Bit configuration | DevOps Engineer | 0.5 недели | ⭐⭐       |
| Alertmanager setup       | SRE Engineer    | 1 неделя   | ⭐⭐⭐     |
| 8 Exporters deployment   | DevOps Engineer | 1 неделя   | ⭐⭐⭐     |
| Uptime Kuma              | DevOps Engineer | 0.5 недели | ⭐⭐       |

**Команда:** 1 Senior DevOps Engineer, 1 SRE Engineer **Итого:** 4-5 недель

---

### 3.4 Документация & Knowledge Base (6-8 недель)

| Задача                   | Роль              | Время      | Описание                                   |
| ------------------------ | ----------------- | ---------- | ------------------------------------------ |
| Техническая документация | Technical Writer  | 3 недели   | Architecture, operations, troubleshooting  |
| User Academy guides      | Technical Writer  | 2 недели   | Open WebUI basics, prompting, HowTo guides |
| API документация         | Backend Developer | 1 неделя   | REST API, MCP tools                        |
| Runbooks & operations    | SRE Engineer      | 1.5 недели | Incident response, maintenance procedures  |
| Переводы (DE, EN)        | Technical Writer  | 1.5 недели | Многоязычность (3 языка)                   |

**Команда:** 1 Technical Writer, 1 SRE Engineer, 1 Backend Developer **Итого:**
6-8 недель параллельной работы

---

### 3.5 Testing & QA (6-8 недель)

| Тип тестирования       | Роль                   | Время      | Описание                                      |
| ---------------------- | ---------------------- | ---------- | --------------------------------------------- |
| Unit tests             | Developers (все)       | 2 недели   | Go, Python, TypeScript тесты                  |
| Integration tests      | QA Engineer            | 2 недели   | API интеграции, service mesh                  |
| E2E tests (Playwright) | QA Automation Engineer | 2 недели   | UI flows, critical paths                      |
| Load testing           | Performance Engineer   | 1.5 недели | GPU utilization, API latency                  |
| Security testing       | Security Engineer      | 1.5 недели | Penetration testing, vulnerability assessment |
| UAT                    | Product Owner + Users  | 1 неделя   | User acceptance testing                       |

**Команда:** 2 QA Engineers, 1 QA Automation Engineer, 1 Performance Engineer, 1
Security Engineer **Итого:** 6-8 недель (некоторые параллельно с разработкой)

---

### 3.6 Deployment & Production Readiness (3-4 недели)

| Задача                 | Роль                 | Время      | Описание                            |
| ---------------------- | -------------------- | ---------- | ----------------------------------- |
| Production environment | DevOps + SysAdmin    | 1.5 недели | Hardware setup, GPU configuration   |
| Migration scripts      | Backend Developer    | 1 неделя   | Data migration, configuration       |
| Performance tuning     | Performance Engineer | 1 неделя   | GPU optimization, caching           |
| Disaster recovery      | SRE Engineer         | 1 неделя   | Backup testing, failover procedures |
| Production deployment  | DevOps Team          | 0.5 недели | Go-live, rollback plan              |

**Команда:** 1 DevOps, 1 SRE, 1 SysAdmin, 1 Performance Engineer, 1 Backend
Developer **Итого:** 3-4 недели

---

## 4. Оценка Команды

### Минимальная Команда (для MVP)

| Роль                       | Количество | Ставка/месяц      | Время на проекте |
| -------------------------- | ---------- | ----------------- | ---------------- |
| Solution Architect         | 1          | 12,000-18,000 CHF | 3 месяца         |
| Senior DevOps Engineer     | 1          | 10,000-14,000 CHF | 6 месяцев        |
| Backend Developer (Go)     | 1          | 8,000-12,000 CHF  | 4 месяца         |
| Backend Developer (Python) | 2          | 8,000-12,000 CHF  | 5 месяцев        |
| ML Engineer                | 1          | 10,000-15,000 CHF | 4 месяца         |
| Full-stack Developer       | 1          | 9,000-13,000 CHF  | 5 месяцев        |
| QA Engineer                | 1          | 7,000-10,000 CHF  | 3 месяца         |
| Technical Writer           | 1          | 6,000-9,000 CHF   | 2 месяца         |
| Project Manager            | 1          | 9,000-13,000 CHF  | 6 месяцев        |

**Минимальная команда:** 10 человек

### Оптимальная Команда (для Production-Ready)

| Роль                       | Количество | Ставка/месяц | Время на проекте |
| -------------------------- | ---------- | ------------ | ---------------- |
| Solution Architect         | 1          | 15,000 CHF   | 4 месяца         |
| Security Architect         | 1          | 14,000 CHF   | 3 месяца         |
| Senior DevOps Engineer     | 2          | 12,000 CHF   | 6 месяцев        |
| SRE Engineer               | 1          | 11,000 CHF   | 5 месяцев        |
| Backend Developer (Go)     | 2          | 10,000 CHF   | 5 месяцев        |
| Backend Developer (Python) | 3          | 10,000 CHF   | 5 месяцев        |
| ML Engineer                | 2          | 13,000 CHF   | 5 месяцев        |
| Full-stack Developer       | 2          | 11,000 CHF   | 5 месяцев        |
| Database Engineer          | 1          | 11,000 CHF   | 4 месяца         |
| QA Engineer                | 2          | 8,500 CHF    | 4 месяца         |
| QA Automation Engineer     | 1          | 10,000 CHF   | 4 месяца         |
| Performance Engineer       | 1          | 11,000 CHF   | 3 месяца         |
| Security Engineer          | 1          | 12,000 CHF   | 4 месяца         |
| Technical Writer           | 1          | 7,500 CHF    | 3 месяца         |
| Project Manager            | 1          | 11,000 CHF   | 6 месяцев        |
| Product Owner              | 1          | 10,000 CHF   | 6 месяцев        |

**Оптимальная команда:** 23 человека

---

## 5. Временная Оценка

### Сценарий 1: MVP (Минимальный жизнеспособный продукт)

**Время:** 5-6 месяцев **Команда:** 10 человек **Описание:** Базовая
функциональность, ограниченная документация, минимальный мониторинг

### Сценарий 2: Production-Ready (текущая версия v12.1)

**Время:** 8-10 месяцев **Команда:** 20-23 человека **Описание:** Полная
функциональность, enterprise security, всесторонняя документация, 32 сервиса

### Breakdown по фазам (Production-Ready):

| Фаза                         | Длительность | Команда (FTE)              |
| ---------------------------- | ------------ | -------------------------- |
| Проектирование и архитектура | 2-3 месяца   | 4-5                        |
| Core development             | 4-5 месяцев  | 12-15                      |
| Observability & monitoring   | 2-3 месяца   | 2-3 (параллельно)          |
| Документация                 | 3-4 месяца   | 1-2 (параллельно)          |
| Testing & QA                 | 2-3 месяца   | 4-5 (частично параллельно) |
| Deployment & stabilization   | 1-2 месяца   | 6-8                        |

**Общее время:** 8-10 месяцев с учетом параллельных работ

---

## 6. Бюджетная Оценка (CHF)

### 6.1 Затраты на Персонал

#### Сценарий MVP (5-6 месяцев)

| Роль               | Количество | Месяцы | Ставка | Итого   |
| ------------------ | ---------- | ------ | ------ | ------- |
| Solution Architect | 1          | 3      | 15,000 | 45,000  |
| Senior DevOps      | 1          | 6      | 12,000 | 72,000  |
| Backend (Go)       | 1          | 4      | 10,000 | 40,000  |
| Backend (Python)   | 2          | 5      | 10,000 | 100,000 |
| ML Engineer        | 1          | 4      | 13,000 | 52,000  |
| Full-stack Dev     | 1          | 5      | 11,000 | 55,000  |
| QA Engineer        | 1          | 3      | 8,500  | 25,500  |
| Technical Writer   | 1          | 2      | 7,500  | 15,000  |
| Project Manager    | 1          | 6      | 11,000 | 66,000  |

**Итого персонал MVP:** 470,500 CHF

#### Сценарий Production-Ready (8-10 месяцев)

| Роль               | Количество × Месяцы | Ставка | Итого   |
| ------------------ | ------------------- | ------ | ------- |
| Solution Architect | 1 × 4               | 15,000 | 60,000  |
| Security Architect | 1 × 3               | 14,000 | 42,000  |
| Senior DevOps      | 2 × 6               | 12,000 | 144,000 |
| SRE Engineer       | 1 × 5               | 11,000 | 55,000  |
| Backend (Go)       | 2 × 5               | 10,000 | 100,000 |
| Backend (Python)   | 3 × 5               | 10,000 | 150,000 |
| ML Engineer        | 2 × 5               | 13,000 | 130,000 |
| Full-stack Dev     | 2 × 5               | 11,000 | 110,000 |
| Database Engineer  | 1 × 4               | 11,000 | 44,000  |
| QA Engineer        | 2 × 4               | 8,500  | 68,000  |
| QA Automation      | 1 × 4               | 10,000 | 40,000  |
| Performance Eng    | 1 × 3               | 11,000 | 33,000  |
| Security Engineer  | 1 × 4               | 12,000 | 48,000  |
| Technical Writer   | 1 × 3               | 7,500  | 22,500  |
| Project Manager    | 1 × 8               | 11,000 | 88,000  |
| Product Owner      | 1 × 8               | 10,000 | 80,000  |

**Итого персонал Production:** 1,214,500 CHF

### 6.2 Инфраструктурные Затраты

#### GPU Server (On-Premise)

| Компонент              | Спецификация                          | Стоимость         |
| ---------------------- | ------------------------------------- | ----------------- |
| GPU Server             | NVIDIA RTX 5000 (16GB) или аналог     | 15,000-25,000 CHF |
| CPU/RAM/Storage        | High-end server (64GB+ RAM, NVMe SSD) | 8,000-12,000 CHF  |
| Резервное оборудование | Backup server                         | 10,000-15,000 CHF |

**Итого оборудование:** 33,000-52,000 CHF

#### Cloud Alternative (если используется облако)

| Сервис                | Конфигурация               | Стоимость/месяц |
| --------------------- | -------------------------- | --------------- |
| GPU Instance          | NVIDIA T4/A10 equivalent   | 1,500-3,000 CHF |
| Database (PostgreSQL) | Managed, High-availability | 500-800 CHF     |
| Object Storage        | Backups, models, data      | 200-400 CHF     |
| Network/Traffic       | CDN, bandwidth             | 300-500 CHF     |

**Итого облако:** 2,500-4,700 CHF/месяц × 12 месяцев = **30,000-56,400 CHF/год**

#### Лицензии и Подписки (годовая стоимость)

| Сервис                | Назначение                    | Стоимость/год   |
| --------------------- | ----------------------------- | --------------- |
| Cloudflare Zero Trust | External access, security     | 2,400-6,000 CHF |
| GitHub Enterprise     | CI/CD, code management        | 2,500-5,000 CHF |
| Snyk                  | Security scanning             | 1,200-3,000 CHF |
| Monitoring tools      | Uptime Kuma, additional tools | 500-1,500 CHF   |
| SSL Certificates      | Enterprise SSL/TLS            | 500-1,000 CHF   |
| AI API Keys           | OpenAI, PublicAI fallbacks    | 1,000-3,000 CHF |

**Итого лицензии:** 8,100-19,500 CHF/год

#### Разработка и DevOps Tooling

| Инструмент             | Назначение                | Стоимость     |
| ---------------------- | ------------------------- | ------------- |
| JetBrains All Products | IDE для команды (20 лиц.) | 7,000 CHF/год |
| Docker Hub Pro         | Container registry        | 500 CHF/год   |
| Confluence/Jira        | Documentation, PM         | 3,000 CHF/год |
| Slack Business+        | Team communication        | 1,500 CHF/год |

**Итого tooling:** 12,000 CHF/год

---

### 6.3 Прочие Затраты

| Категория              | Описание                            | Стоимость          |
| ---------------------- | ----------------------------------- | ------------------ |
| Консалтинг             | Security audit, compliance          | 15,000-30,000 CHF  |
| Обучение               | Team training (AI, security, tools) | 10,000-20,000 CHF  |
| Непредвиденные расходы | 10-15% от бюджета                   | 50,000-100,000 CHF |
| Legal & Compliance     | GDPR, data protection               | 5,000-15,000 CHF   |

**Итого прочие:** 80,000-165,000 CHF

---

## 7. Итоговый Бюджет

### MVP Сценарий (5-6 месяцев)

| Категория                   | Стоимость   |
| --------------------------- | ----------- |
| Персонал                    | 470,500 CHF |
| Инфраструктура (on-premise) | 40,000 CHF  |
| Лицензии (6 месяцев)        | 4,000 CHF   |
| Tooling (6 месяцев)         | 6,000 CHF   |
| Прочие                      | 50,000 CHF  |

**Итого MVP:** **570,500 CHF**

### Production-Ready Сценарий (8-10 месяцев)

| Категория                   | Стоимость     |
| --------------------------- | ------------- |
| Персонал                    | 1,214,500 CHF |
| Инфраструктура (on-premise) | 45,000 CHF    |
| Лицензии (12 месяцев)       | 14,000 CHF    |
| Tooling (12 месяцев)        | 12,000 CHF    |
| Прочие                      | 100,000 CHF   |

**Итого Production-Ready:** **1,385,500 CHF**

### Cloud Alternative (Production-Ready)

| Категория                         | Стоимость     |
| --------------------------------- | ------------- |
| Персонал                          | 1,214,500 CHF |
| Cloud инфраструктура (12 месяцев) | 42,000 CHF    |
| Лицензии (12 месяцев)             | 14,000 CHF    |
| Tooling (12 месяцев)              | 12,000 CHF    |
| Прочие                            | 100,000 CHF   |

**Итого Cloud:** **1,382,500 CHF** (первый год) **Последующие годы (OpEx):**
~50,000-70,000 CHF/год (облако + лицензии + поддержка)

---

## 8. Risk Factors & Contingency

### Риски, влияющие на бюджет:

| Риск                   | Вероятность | Влияние         | Mitigation                                    |
| ---------------------- | ----------- | --------------- | --------------------------------------------- |
| GPU shortage/delays    | Средняя     | +2-4 недели     | Заказать оборудование заранее, cloud fallback |
| Scope creep            | Высокая     | +20-30% бюджета | Жесткий scope control, change management      |
| Integration challenges | Средняя     | +3-6 недель     | Proof-of-concept для критичных интеграций     |
| Security compliance    | Средняя     | +15,000 CHF     | Ранний аудит, консультанты                    |
| Team availability      | Высокая     | +2-4 недели     | Резервные кандидаты, overlap periods          |

**Рекомендуемый contingency buffer:** 15-20% от общего бюджета

---

## 9. OpEx (Операционные Расходы)

### Ежегодные расходы после запуска (Production)

| Категория                          | Стоимость/год     |
| ---------------------------------- | ----------------- |
| DevOps/SRE команда (2 FTE)         | 288,000 CHF       |
| Cloud infrastructure (если облако) | 30,000-50,000 CHF |
| Лицензии и подписки                | 14,000 CHF        |
| Электроэнергия (on-premise GPU)    | 3,000-5,000 CHF   |
| Maintenance contracts              | 5,000-10,000 CHF  |
| Security updates/patches           | 10,000-15,000 CHF |
| Documentation updates              | 15,000-20,000 CHF |

**Итого OpEx (on-premise):** 335,000-352,000 CHF/год **Итого OpEx (cloud):**
362,000-397,000 CHF/год

---

## 10. Сравнение Build vs Buy

### Build (текущий проект ERNI-KI)

- **CapEx:** 1,385,500 CHF
- **OpEx:** 335,000 CHF/год
- **Total Cost of Ownership (3 года):** 2,390,500 CHF
- **Преимущества:** Полный контроль, customization, on-premise данные
- **Недостатки:** Высокий initial investment, требует команду

### Buy (Commercial AI Platform)

- **CapEx:** 0-50,000 CHF (setup)
- **OpEx:** 150,000-400,000 CHF/год (лицензии + support)
- **Total Cost of Ownership (3 года):** 500,000-1,250,000 CHF
- **Преимущества:** Быстрый запуск, vendor support
- **Недостатки:** Vendor lock-in, ограниченная кастомизация, данные в облаке

### Hybrid (Managed + Custom Components)

- **CapEx:** 400,000-600,000 CHF
- **OpEx:** 180,000-250,000 CHF/год
- **Total Cost of Ownership (3 года):** 940,000-1,350,000 CHF

---

## 11. ROI Analysis (Return on Investment)

### Предполагаемая ценность проекта

| Метрика                        | Значение/год                   |
| ------------------------------ | ------------------------------ |
| Developer productivity gain    | 20-30% эффективности           |
| Cost avoidance (cloud AI APIs) | 50,000-150,000 CHF/год         |
| Research acceleration          | 2-3x скорость прототипирования |
| Knowledge retention            | Centralized AI knowledge base  |
| Competitive advantage          | Proprietary AI platform        |

### Break-even Analysis (Build)

- **Initial investment:** 1,385,500 CHF
- **Annual savings vs cloud platforms:** ~100,000 CHF
- **Productivity gains:** ~200,000 CHF/year (estimated)
- **Break-even:** **~4-5 лет**

---

## 12. Рекомендации

### Для запуска проекта с нуля:

1. **Start with MVP (6 месяцев, 570K CHF)**
   - Доказать концепцию
   - Валидировать требования
   - Быстрый feedback loop

2. **Iterate to Production (дополнительно 4 месяца, +800K CHF)**
   - Масштабировать на основе real feedback
   - Добавить enterprise features поэтапно
   - Минимизировать риски

3. **Hybrid approach**
   - Используйте managed services где возможно (DB, monitoring)
   - Кастомизируйте только критичные компоненты
   - Cloud-first для dev/staging, on-premise для production

### Критические success factors:

✅ **Сильная архитектурная экспертиза** — Solution Architect критичен ✅
**DevOps automation** — CI/CD с первого дня ✅ **Security by design** — не
afterthought ✅ **Comprehensive documentation** — знания должны быть shared ✅
**Agile methodology** — iterative delivery, не waterfall ✅ **Stakeholder
buy-in** — executive support и clear ROI

---

## 13. Заключение

**Проект ERNI-KI** — это enterprise-grade AI platform с **32 микросервисами**,
требующий значительных инвестиций как в разработку, так и в операционную
поддержку.

### Ключевые цифры:

- **Время реализации:** 8-10 месяцев (production-ready)
- **Команда:** 20-23 специалиста (peak)
- **CapEx (Build):** 1,385,500 CHF
- **OpEx (Ежегодно):** 335,000-397,000 CHF
- **TCO (3 года):** 2,39M CHF

### Альтернативы:

- **MVP:** 6 месяцев, 570K CHF — доказать концепцию
- **Cloud-based:** Быстрее, но +27K/год OpEx
- **Buy commercial:** Дешевле short-term, но vendor lock-in

Проект оправдан для организаций с **высокими требованиями к безопасности
данных**, **compliance**, и **долгосрочной AI стратегией**.

---

**Подготовлено:** Antigravity AI Assistant **Дата:** 24 ноября 2025
