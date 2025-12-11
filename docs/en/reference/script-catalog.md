---
title: Script Catalog
description: Comprehensive inventory of all scripts in the ERNI-KI project
language: en
status: complete
translation_status: source
doc_version: '2025.12'
---

# Script Catalog

> **Generated**: 2025-12-11 **Status**: Cleanup Complete **Total Scripts**: 158
> (126 shell + 32 Python) - after cleanup

## Summary Statistics

| Metric               | Before | After |
| -------------------- | ------ | ----- |
| Total Shell Scripts  | 134    | 126   |
| Total Python Scripts | 33     | 32    |
| Shellcheck Warnings  | 385    | 385   |
| Shellcheck Errors    | 0      | 0     |
| MyPy Errors          | 2      | 2     |
| Orphan Files Removed | -      | 9     |

## Orphan Files (DELETED 2025-12-11)

The following 9 files were identified as orphan/legacy and have been removed:

| File                                                | Reason                       | Status  |
| --------------------------------------------------- | ---------------------------- | ------- |
| `scripts/lib/llm_client 2.py`                       | Duplicate with space in name | DELETED |
| `migrate_to_i18n.sh`                                | One-time migration script    | DELETED |
| `migrate_archive.sh`                                | One-time migration script    | DELETED |
| `migrate_deep_files.sh`                             | One-time migration script    | DELETED |
| `migrate_ru_files.sh`                               | One-time migration script    | DELETED |
| `cleanup_remaining.sh`                              | One-time cleanup utility     | DELETED |
| `resolve_conflicts.sh`                              | One-time conflict resolution | DELETED |
| `scripts/entrypoints/auth.sh`                       | Not mounted in compose       | DELETED |
| `scripts/entrypoints/redis-exporter-with-secret.sh` | Not mounted in compose       | DELETED |

## Scripts by Category

### Root-Level Scripts (1)

| Script              | Status | Lines | Purpose                                   |
| ------------------- | ------ | ----- | ----------------------------------------- |
| `docker-compose.sh` | ACTIVE | 430   | Main Docker Compose orchestration wrapper |

### Entrypoint Scripts (6 + 1 binary)

| Script                                           | Status  | Purpose                       |
| ------------------------------------------------ | ------- | ----------------------------- |
| `scripts/entrypoints/litellm.sh`                 | ACTIVE  | LiteLLM service entrypoint    |
| `scripts/entrypoints/openwebui.sh`               | ACTIVE  | OpenWebUI service entrypoint  |
| `scripts/entrypoints/searxng.sh`                 | ACTIVE  | SearXNG service entrypoint    |
| `scripts/entrypoints/mcposerver-with-secrets.sh` | ACTIVE  | MCPO server entrypoint        |
| `scripts/entrypoints/cloudflared-with-secret.sh` | ACTIVE  | Cloudflare tunnel entrypoint  |
| `scripts/entrypoints/watchtower.sh`              | ACTIVE  | Watchtower service entrypoint |
| `scripts/entrypoints/busybox`                    | UTILITY | Static binary for containers  |

### Library Scripts (3 shell + 3 Python)

| Script                         | Status | Purpose                                             |
| ------------------------------ | ------ | --------------------------------------------------- |
| `scripts/lib/common.sh`        | ACTIVE | Shared shell utilities (40+ scripts depend on this) |
| `scripts/lib/monitoring.sh`    | ACTIVE | Monitoring helpers                                  |
| `scripts/lib/env-validator.sh` | ACTIVE | Environment validation                              |
| `scripts/lib/llm_client.py`    | ACTIVE | LLM client API wrapper (2 mypy errors)              |
| `scripts/lib/logger.py`        | ACTIVE | Logging utility module                              |
| `scripts/lib/__init__.py`      | ACTIVE | Package marker                                      |

### Core Deployment Scripts (7)

| Script                                                      | Status | Lines | Purpose                     |
| ----------------------------------------------------------- | ------ | ----- | --------------------------- |
| `scripts/core/deployment/deploy-monitoring-system.sh`       | ACTIVE | 398   | Deploy monitoring stack     |
| `scripts/core/deployment/setup-backrest-integration.sh`     | ACTIVE | 371   | Backrest backup integration |
| `scripts/core/deployment/setup.sh`                          | ACTIVE | 369   | Main deployment setup       |
| `scripts/core/deployment/gpu-setup.sh`                      | ACTIVE | 327   | GPU initialization          |
| `scripts/core/deployment/setup-rate-limiting-monitoring.sh` | ACTIVE | 283   | Rate limiting setup         |
| `scripts/core/deployment/quick-start.sh`                    | ACTIVE | 276   | Quick start deployment      |
| `scripts/core/deployment/setup-log-rotation.sh`             | ACTIVE | 101   | Log rotation config         |

### Core Diagnostics Scripts (9)

| Script                                                       | Status | Lines | Purpose                 |
| ------------------------------------------------------------ | ------ | ----- | ----------------------- |
| `scripts/core/diagnostics/dependency-checker.sh`             | ACTIVE | 489   | Check dependencies      |
| `scripts/core/diagnostics/container-compatibility-test.sh`   | ACTIVE | 461   | Container compatibility |
| `scripts/core/diagnostics/automated-recovery.sh`             | ACTIVE | 448   | Automated recovery      |
| `scripts/core/diagnostics/diagnose-websearch-issue.sh`       | ACTIVE | 294   | Web search diagnostics  |
| `scripts/core/diagnostics/diagnose-websearch-domains.sh`     | ACTIVE | 289   | Domain diagnostics      |
| `scripts/core/diagnostics/comprehensive-mcpo-diagnostics.sh` | ACTIVE | 292   | MCPO diagnostics        |
| `scripts/core/diagnostics/quick-mcpo-check.sh`               | ACTIVE | 222   | Quick MCPO check        |
| `scripts/core/diagnostics/network-diagnostics.sh`            | ACTIVE | 155   | Network diagnostics     |
| `scripts/core/diagnostics/health-check.sh`                   | ACTIVE | 16    | Basic health check      |

### Infrastructure Security Scripts (23)

| Script                                | Status | Purpose                     |
| ------------------------------------- | ------ | --------------------------- |
| `security-hardening.sh`               | ACTIVE | Security hardening          |
| `setup-ssl-monitoring.sh`             | ACTIVE | SSL monitoring              |
| `setup-letsencrypt-cloudflare.sh`     | ACTIVE | LetsEncrypt with Cloudflare |
| `rotate-secrets.sh`                   | ACTIVE | Secret rotation             |
| `monitor-certificates.sh`             | ACTIVE | Certificate monitoring      |
| `configure-environment-protection.sh` | ACTIVE | Environment protection      |
| `renew-self-signed.sh`                | ACTIVE | Self-signed cert renewal    |
| `validate-environment-secrets.sh`     | ACTIVE | Secret validation           |
| ...                                   | ...    | ...                         |

### Python Documentation Scripts (15)

| Script                                     | Status | Purpose                |
| ------------------------------------------ | ------ | ---------------------- |
| `scripts/docs/ai_content_validator.py`     | ACTIVE | AI content validation  |
| `scripts/docs/cleanup-documentation.py`    | ACTIVE | Doc cleanup            |
| `scripts/docs/update_status_snippet_v2.py` | ACTIVE | Status snippet updates |
| `scripts/docs/docs_metrics.py`             | ACTIVE | Documentation metrics  |
| `scripts/docs/fix-broken-links.py`         | ACTIVE | Fix broken links       |
| `scripts/docs/audit-documentation.py`      | ACTIVE | Doc audit              |
| ...                                        | ...    | ...                    |

## Top Scripts with Shellcheck Warnings

| Script                              | Warnings | Primary Issues |
| ----------------------------------- | -------- | -------------- |
| `hardware-analysis.sh`              | 36       | SC2155, SC2034 |
| `gpu-monitor.sh`                    | 36       | SC2155, SC2034 |
| `watchtower-performance-monitor.sh` | 21       | SC2155         |
| `system-health-monitor.sh`          | 21       | SC2155         |
| `container-compatibility-test.sh`   | 19       | SC2155, SC2162 |

## Common Shellcheck Issues

| Code   | Count | Description                     |
| ------ | ----- | ------------------------------- |
| SC2155 | ~200  | Declare and assign separately   |
| SC2034 | ~50   | Unused variables                |
| SC2086 | ~30   | Quote to prevent globbing       |
| SC1091 | ~40   | Not following source (expected) |

## Recommendations

### Immediate Actions (High Priority)

1. **Delete orphan files**:
   - `scripts/lib/llm_client 2.py` - duplicate with space

2. **Archive one-time scripts**:
   - Move migration scripts to `scripts/archive/` or delete

3. **Integrate or remove**:
   - `scripts/entrypoints/auth.sh`
   - `scripts/entrypoints/redis-exporter-with-secret.sh`

### Quality Improvements (Medium Priority)

1. Fix top 5 scripts with most shellcheck warnings
2. Fix 2 mypy errors in `llm_client.py`
3. Ensure all scripts use `common.sh` library

### Future Considerations

1. Consolidate duplicate monitoring scripts
2. Standardize error handling patterns
3. Add unit tests for critical scripts
