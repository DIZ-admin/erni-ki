---
language: en
translation_status: partial
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Documentation Refactoring Plan (2025-11-24)

> Target: unify production docs, remove duplicates, close outdated sections, and
> give DevOps/ML/SRE a clear structure. [TOC]

## Snapshot (audit)

- Duplicated status blocks across README/index/overview/architecture; dates
  drift.
- Operations/Runbooks and reports are not consistently linked in MkDocs.
- Data & Storage docs are hard to find from top-level pages.
- API/MCPO not updated for Nov 2025 (LiteLLM 1.80.0.rc.1, new Context7
  endpoints).
- Some cron/alert docs live only in `archive/config-backup/`.

## Target structure (high level)

- Executive: overview (SLA, health, latest updates)
- Architecture: architecture/service-inventory, services-overview, nginx config
- Operations: operations handbook, monitoring guide, runbooks tied to scripts
- Data & Storage: Postgres/Redis/vLLM guides
- Security: policies, log audit, WAF/Zero Trust
- API & Integrations: api-reference, mcpo-integration-guide
- Reports & Audits: archive/reports with short summaries in operations
- Locales: translated guides (DE/EN)

## Phases (abridged)

- Wave 1: status unification via status.yml + include-markdown; doc health page.
- Wave 2: operations & API refresh (monitoring cron/alerts, runbooks,
  api-reference rewrite).
- Wave 3: archive restructuring, locales fill, data docs links and updates.

## Deliverables (abridged)

- status.yml + update script, archive restructure, DE locales fill,
  README/index/handbook links to data docs, refreshed operations guides, CI plan
  for localization/data docs.
