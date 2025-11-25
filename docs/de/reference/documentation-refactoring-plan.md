---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# 📘 ERNI-KI Professional Documentation & Refactoring Plan (Nov 2025)

> **Ziel:** Produktive Doku vereinheitlichen, Duplikate entfernen, veraltete
> Bereiche schließen, klare Struktur für DevOps/ML/SRE schaffen. [TOC]

## 1. Ist-Zustand (Audit 82 Markdown-Dateien)

| Bereich             | Abdeckung                                                                                                   | Stand      |
| ------------------- | ----------------------------------------------------------------------------------------------------------- | ---------- |
| **Summaries**       | `README.md`, `docs/index.md`, `docs/overview.md` beschreiben denselben Status (30/30 Container).            | 07–11.2025 |
| **Architektur**     | `docs/architecture/*.md`, `service-inventory.md`, `services-overview.md`, `nginx-configuration.md`.         | 07.11.2025 |
| **Operations**      | `docs/operations/*` + Runbooks (backup, docling, service restart, troubleshooting).                         | 10–11.2025 |
| **Observability**   | `monitoring-guide.md`, `prometheus-alerts-guide.md`, `grafana-dashboards-guide.md`, `log-audit-2025-11-14`. | 14.11.2025 |
| **Data & Storage**  | `operations/database/*.md` (Monitoring/Optimierungen Postgres, Redis, vLLM).                                | 09–10.2025 |
| **Security**        | `security/security-policy.md`, `log-audit.md`, punktuelle Reports.                                          | 09–11.2025 |
| **Reference/API**   | `reference/api-reference.md` (19.09.2025), `mcpo-integration-guide.md`, `development.md`.                   | 09–10.2025 |
| **Archive/Reports** | 15+ Reports in `archive/reports/` (Audits, Diagnostics, Remediation).                                       | 10–11.2025 |
| **Locales (DE)**    | 11 Dateien in `docs/locales/de` (Basisguides, ohne Runbooks).                                               | 09.2025    |

**Beobachtungen**

- Status/Metadaten dupliziert in `README.md`, `docs/index.md`,
  `docs/overview.md`, `architecture/architecture.md` (Daten driften).
- Runbooks/Reports nicht konsistent in MkDocs verlinkt.
- Data & Storage kaum verlinkt in README/index → schlechte Auffindbarkeit.
- API-Referenz/MCPO nicht auf Stand Nov 2025 (LiteLLM 1.80.0.rc.1, neue Context7
  Endpoints).
- Cron/Alert-Dokus leben teils nur in `archive/config-backup`, sollten in
  operations.

## 2. Zielstruktur

| Ebene                   | Dokument/Abschnitt                                              | Inhalt                                                             |
| ----------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------ |
| Executive               | `docs/overview.md`                                              | SLA, 30/30 Gesundheit, letzte Updates, Links zu Reports            |
| Architecture            | `architecture/architecture.md`, `service-inventory.md`          | L3-Diagramme, Abhängigkeiten, Compose-Profile, Ingress/Security    |
| Operations              | `operations/core/operations-handbook.md`, `monitoring-guide.md` | Rollen, On-Call, Alerts, Response-Prozeduren                       |
| Runbooks                | `operations/*`                                                  | Purpose → Preconditions → Steps → Validation, Links zu `scripts/*` |
| Data & Storage          | `operations/database/*.md`                                      | Postgres/Redis Pläne, pgvector, Retention, Watchdogs               |
| Security                | `security/security-policy.md`, `log-audit.md`                   | Policies, Log-Audit, WAF, Zero Trust                               |
| API & Integrations      | `reference/api-reference.md`, `mcpo-integration-guide.md`       | JWT, LiteLLM, MCP, Context7, RAG, Payload-Beispiele                |
| Reports & Audits        | `archive/reports/*.md`                                          | Historie, Kurzfassungen in operations                              |
| Locales / Consumer Docs | `locales/de/*`, User-Guides                                     | Übersetzte Guides (install, user, admin)                           |

## 3. Gap-Analyse und Prioritäten

1. Status-Summaries vereinheitlichen (README/index/overview) via YAML + include.
2. API & Integration auf Nov 2025 bringen (LiteLLM 1.80.0.rc.1, Context7, RAG).
3. Wichtige Reports aus archive in operations referenzieren.
4. Runbooks mit `scripts/maintenance/*` abgleichen (Automatisierung vs. Text).
5. Lokalisierungs-Schulden (DE) abbauen, v12.1 einpflegen.
6. Data & Storage in README/Handbook verlinken.
7. MkDocs `nav` an Zielstruktur anpassen.

## 4. Plan (3 Wellen)

### Welle 1 – Inventar & Status (2–3 Tage) — Status: offen

- `docs/reference/status.yml` + include in README/index/overview (kein
  Manual-Edit).
- Kurzbericht in Archon (dieser Plan).
- Seite «Documentation Health» hinzufügen.

### Welle 2 – Operations & API (3–4 Tage) — Status: geplant

- `operations/core/operations-handbook.md`, `monitoring-guide.md`,
  `automated-maintenance-guide.md` mit neuen Cron/Alert-Skripten verlinken.
- Findings aus `log-audit-2025-11-14.md` in Runbook übernehmen.
- `reference/api-reference.md` neu schreiben (LiteLLM 1.80.0.rc.1, Context7,
  `/lite/api/v1/think`, neue RAG-Endpoints, JWT-Beispiele).

### Welle 3 – Archive, Locales, Data (4–5 Tage) — Status: geplant

- Kurzkonzept für Archive-Reports erstellen und in operations verlinken.
- `archive/` aufteilen (`audits`, `diagnostics`, `incidents`), `mkdocs.yml`
  anpassen.
- `locales/de/*` auffüllen (Monitoring/Runbooks).
- Data-Docs verlinken in README/Handbook, pgvector/Redis-Settings prüfen.

## 5. Deliverables

- `docs/reference/status.yml` + Workflow `scripts/docs/update_status_snippet.py`
  (README/index/overview + locales/de).
- `docs/archive/` restrukturiert, README-Navigatoren, aktualisiertes
  `mkdocs.yml`.
- `docs/locales/de/` mit Status-Block, Monitoring/Runbooks-Übersichten.
- README/index/operations-handbook verweisen auf `operations/database/*.md` und
  wichtige Archive-Reports.
- Aktualisierte Operations-Guides mit `scripts/*` Verknüpfungen.
- Abschnitt «Documentation Health & Refactoring Plan» (dieser Plan) +
  Archon-Eintrag.
- CI-Plan für Lokalisierung/Data-Docs (z. B. Datums-Checks).
