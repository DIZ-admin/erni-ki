---
language: en
doc_version: '2025.11'
translation_status: pending
---

# Security Guide

## Overview

This page aggregates the core security materials for the ERNI-KI platform:
policies, operational hardening, scanning pipelines, and incident reporting. Use
it as an entrypoint before enabling production access or sharing builds.

### Security pillars

- **Policies:** disclosure & reporting, severity classes, SLAs for fixes
- **Hardening:** Nginx headers/limits, Docker/Compose least-privilege
- **Scanning:** CodeQL, Trivy, Gosec, Gitleaks, Bun audit
- **Monitoring:** Prometheus rules and log/watch items
- **Process:** secure releases, backups, secrets hygiene

### Quick checklist

- Secrets stored in env/secret managers (no plaintext in repo)
- Bun audit + Trivy + CodeQL + Gosec run in CI
- Nginx: security headers, rate limits, size limits
- Containers: non-root user, dropped capabilities, read-only FS where possible
- Alerts: auth failures, high 4xx/5xx rates, config changes
- Backups: periodic, restore tested

## Key Documents

- **Security Policy:** [`security-policy.md`](./security-policy.md) — reporting,
  SLAs, severity classes, remediation steps.
- **Infrastructure Hardening:**
  - Nginx recommendations inside `security-policy.md`
    (headers/limits/rate-limits).
  - Docker hardening snippet (non-root, cap_drop, read-only FS).
- **Scanners in CI:** `.github/workflows/ci.yml` (CodeQL/Trivy/Gosec/Bun audit)
  and `security.yml` (if enabled).
- **Monitoring & Alerts:** Prometheus rules examples in `security-policy.md` and
  logging guidelines in ops docs.

## Incident Reporting

Send private reports to **security@erni-ki.local** (PGP if available). Provide
description, repro steps, impact, and suggested mitigation. Avoid public issues
until coordinated disclosure is agreed.

## Contacts

- Security Team: `security@erni-ki.local`
- Emergency contact: +7-XXX-XXX-XXXX

## Status & Maintenance

- Doc version: 2025.11 (EN). Keep aligned with RU/DE pages when updating.
- Update this landing page when scanners/policies change or new hardening
  guidance appears in infra configs.
