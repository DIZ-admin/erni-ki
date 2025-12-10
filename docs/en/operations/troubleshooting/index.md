---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Troubleshooting

Collection of guides for incident analysis and service recovery.

## Sections

- [Troubleshooting Guide](../../../ru/operations/troubleshooting/troubleshooting-guide.md)
  — general methodology for finding root causes, checklists for network, GPU and
  service issues (RU).
- Supplement README with links to thematic runbooks from `operations/core` and
  `operations/diagnostics` if new scenarios appear.

## Standard Approach

1. Check status page and active alerts.
2. Collect artifacts: `docker compose ps`, service logs, metrics.
3. Classify issue (LLM, network, DB, UI) and open appropriate runbook.

## Documentation

- After resolving an incident, add brief note to troubleshooting-guide.
- Mark runbooks with tags (`llm`, `network`, `db`) for quick search.
- Update this index and audit trail with links to new scenarios.
