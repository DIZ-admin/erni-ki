---
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-25'
category: archive
audit_type: service-version
---

# Service Version Audit Report

**Date**: November 25, 2025**Auditor**: Automated System Audit**Scope**: All 30
services in ERNI-KI infrastructure**Coverage**: 100% (30/30 services)

## Executive Summary

This report presents a comprehensive audit of all service versions across the
ERNI-KI platform, comparing current deployed versions with the latest stable
releases available. The audit identified 26 services with available updates,
including 6 critical priority updates and 1 recommended service migration.

### Key Findings

-**Total Services Audited**: 30 -**Services with Updates**: 26 (87%) -**Already
Current**: 5 services (Watchtower, Uptime Kuma, Nginx mainline, PostgreSQL, Go
toolchain) -**Critical Updates**: 6 services requiring immediate
attention -**Security Concerns**: 1 service (Fluent Bit - vulnerabilities fixed
in v4.1.1) -**Service Migrations**: 1 recommendation (NVIDIA GPU Exporter → DCGM
Exporter)

### Risk Assessment

-**High Priority**: 6 services (Ollama, Open WebUI, LiteLLM, Cloudflared,
Prometheus, NVIDIA GPU Exporter migration) -**Medium Priority**: 8 services
(monitoring exporters, infrastructure components) -**Low Priority**: 12 services
(minor version updates, maintenance releases)

## Detailed Findings

### Critical Services - Immediate Action Required

#### 1. LiteLLM Context Engineering Gateway

-**Current**: v1.80.0.rc.1 (Release Candidate) -**Latest**: v1.80.5-stable
(November 22, 2025) -**Recommendation**:**UPDATE IMMEDIATELY**-**Risk**: Very
Low - moving from RC to stable -**Details**: Currently running release
candidate; stable version available with Gemini 3.0 support and bug
fixes -**Breaking Changes**: None

#### 2. Open WebUI

-**Current**: v0.6.36 -**Latest**: v0.6.39 (November
25, 2025) -**Recommendation**:**UPDATE RECOMMENDED**-**Risk**: Very Low - patch
version -**Details**: Latest patch includes bug fixes and stability
improvements -**Breaking Changes**: None

#### 3. Ollama LLM Server

-**Current**: 0.12.11 -**Latest**: 0.13.0 (November
18, 2025) -**Recommendation**:**UPDATE AFTER TESTING**-**Risk**: Low - minor
version with GPU changes -**Details**: Vulkan API support, improved GPU
scheduling, enhanced model management, WebP support -**Breaking Changes**: None
reported -**Testing Required**: GPU acceleration, model loading

#### 4. Cloudflare Tunnel (cloudflared)

-**Current**: 2024.10.0 -**Latest**: 2025.11.1 (November
7, 2025) -**Recommendation**:**UPDATE RECOMMENDED**-**Risk**: Low-Medium - ~13
months of updates -**Details**: Over a year of security fixes and
improvements -**Action**: Review changelog for tunnel configuration changes

#### 5. Prometheus Monitoring

-**Current**: v3.0.0 -**Latest**: v3.7.3 (October 29, 2025) or v3.5.0 LTS (July
14, 2025) -**Recommendation**:**UPDATE TO LTS OR LATEST**-**Risk**: Low-Medium -
7 minor versions behind -**Details**: LTS preferred for stability; latest for
newest features -**Testing Required**: Alert rules, query syntax

#### 6. NVIDIA GPU Exporter

-**Current**: mindprince/nvidia_gpu_prometheus_exporter:0.1 -**Latest
Alternative**: NVIDIA DCGM Exporter 4.4.2-4.7.0 -**Recommendation**:**MIGRATE TO
DCGM EXPORTER**-**Risk**: Medium - requires service replacement -**Details**:
Current exporter unmaintained; DCGM is official NVIDIA tool -**Benefits**:
Official support, comprehensive metrics, MIG support, cloud
integration -**Action**: Plan migration with Prometheus configuration updates

---

### [WARNING] Monitoring Stack - Standard Updates

| Service           | Current | Latest    | Gap           | Priority |
| ----------------- | ------- | --------- | ------------- | -------- |
| Loki              | 3.0.0   | 3.6.1     | 6 minors      | Medium   |
| Grafana           | 11.3.0  | 11.6.8    | 3 minors      | Medium   |
| Alertmanager      | v0.27.0 | v0.29.0   | 2 minors      | Low      |
| Node Exporter     | v1.8.2  | v1.10.2   | 2 minors      | Low      |
| Postgres Exporter | v0.15.0 | v0.18.1   | 3 minors      | Low      |
| Redis Exporter    | v1.62.0 | v1.80.1   | **18 minors** | Medium   |
| Blackbox Exporter | v0.25.0 | v0.27.0   | 2 minors      | Low      |
| Nginx Exporter    | 1.1.0   | 1.5.1     | 4 minors      | Medium   |
| cAdvisor          | v0.52.1 | v0.53.0   | 1 minor       | Low      |
| Fluent Bit        | 3.1.0   | **4.2.0** | MAJOR         | Medium   |
| Uptime Kuma       | 2.0.2   | 2.0.2     | Current       | N/A      |

**Notable Items**:

-**Redis Exporter**: 18 versions behind - extensive gap requires careful
testing -**Fluent Bit**: Major version update 3→4 with**security fixes**in
v4.1.1 (released Nov 24, 2025)

---

### [OK] Infrastructure Services

| Service     | Current         | Latest        | Status          | Notes                                             |
| ----------- | --------------- | ------------- | --------------- | ------------------------------------------------- |
| PostgreSQL  | pg17            | pg17          | Current         | Latest major version                              |
| pgvector    | 0.8.0 (est.)    | 0.8.1         | Patch available | Minor extension update                            |
| Redis       | 7.0.15-alpine   | 8.4.0 / 7.4.0 | Major/Minor     | Pinned intentionally (RDB format incompatibility) |
| Nginx       | 1.29.3          | 1.29.3        | Current         | Latest mainline (stable=1.28.0 older)             |
| Apache Tika | Digest          | 3.2.3         | Version switch  | Replace digest with semantic version              |
| SearXNG     | Digest (Nov 12) | Rolling       | Update digest   | Rolling release, update monthly                   |

**Redis Note**: Currently pinned to 7.0.15 due to RDB format incompatibility
with 8.x. Alternative: incremental update to 7.4.0.

---

### Support Services

| Service     | Current     | Latest           | Recommendation                                 |
| ----------- | ----------- | ---------------- | ---------------------------------------------- |
| Watchtower  | 1.7.1       | 1.7.1            | No action - current                            |
| Backrest    | v1.9.2      | v1.10.0          | Update - backup improvements                   |
| EdgeTTS     | Digest      | v2.0.0 / :latest | Switch to version tag                          |
| MCPO Server | git-91e8f94 | v0.0.18          | Evaluate versioned release (OAuth 2.0 support) |
| Docling     | :main       | :main            | Consider pinning for stability                 |

---

### Development Dependencies

| Component         | Current                    | Latest           | Gap           | Action                                       |
| ----------------- | -------------------------- | ---------------- | ------------- | -------------------------------------------- |
| Node.js           | 22.14.0                    | 22.11.0 LTS      | Ahead?        | Verify version (may be typo in package.json) |
| npm               | 10.8.2                     | 11.6.3           | Major         | Update available                             |
| Go                | 1.24.0 + toolchain 1.24.10 | 1.24.10 / 1.25.4 | Current/Major | Toolchain current; 1.25.x available          |
| Flask             | 3.0.3                      | 3.1.2            | 2 patches     | Update - bug fix release                     |
| prometheus-client | 0.20.0                     | 0.23.1           | 3 minors      | Update - metrics improvements                |

**Node.js Anomaly**: package.json specifies 22.14.0, which is newer than latest
LTS (22.11.0). Requires verification.

---

## Implementation Plan

### Phase 1: Low-Risk Updates (This Week)

**Priority**: IMMEDIATE

1.**LiteLLM**: v1.80.0.rc.1 → v1.80.5-stable

- File: `compose.yml` line 151
- Risk: Very Low
- Testing: API compatibility check

  2.**Open WebUI**: v0.6.36 → v0.6.39

- File: `compose.yml` line 470
- Risk: Very Low
- Testing: Web interface validation

### Phase 2: Infrastructure Updates (Next Sprint)

**Priority**: [WARNING] MEDIUM

3.**Cloudflared**: 2024.10.0 → 2025.11.1 4.**Apache Tika**: Digest → 3.2.3
(semantic version) 5.**Prometheus**: v3.0.0 → v3.7.3 (or v3.5.0
LTS) 6.**Grafana**: 11.3.0 → 11.6.8 7.**Loki**: 3.0.0 → 3.6.1

### Phase 3: Monitoring Exporters (Next Sprint)

**Priority**: [OK] LOW-MEDIUM

8. Alertmanager v0.27.0 → v0.29.0
9. Node Exporter v1.8.2 → v1.10.2
10. Postgres Exporter v0.15.0 → v0.18.1
11. Redis Exporter v1.62.0 → v1.80.1 (test thoroughly - 18 version gap)
12. Blackbox Exporter v0.25.0 → v0.27.0
13. Nginx Exporter 1.1.0 → 1.5.1
14. cAdvisor v0.52.1 → v0.53.0

### Phase 4: Major Updates (This Month)

**Priority**: [WARNING] MEDIUM - Requires Testing

15.**Fluent Bit**: 3.1.0 → 4.2.0

- Major version update 3→4
- Security fixes in v4.1.1 (Nov 24, 2025)
- Review migration guide for breaking changes
- Test log pipelines thoroughly

  16.**Ollama**: 0.12.11 → 0.13.0

- Test GPU acceleration extensively
- Verify model loading and performance

  17.**Backrest**: v1.9.2 → v1.10.0

### Phase 5: Dependencies & Remaining Services (This Month)

18. npm 10.8.2 → 11.6.3
19. Flask 3.0.3 → 3.1.2
20. prometheus-client 0.20.0 → 0.23.1
21. EdgeTTS - switch to v2.0.0 or :latest tag
22. MCPO Server - evaluate v0.0.18
23. Python packages audit (Werkzeug, requests, python-dateutil)

### Phase 6: Service Migration (Next Quarter)

**Priority**: HIGH

24.**NVIDIA GPU Exporter Migration**

- Current: mindprince 0.1 (unmaintained)
- Target: NVIDIA DCGM Exporter 4.4.2-4.7.0
- Steps:

1.  Research DCGM deployment (Docker/Helm)
2.  Plan migration from mindprince to DCGM
3.  Update Prometheus scrape configurations
4.  Test GPU metrics collection
5.  Validate dashboard compatibility

---

## Risk Analysis

### High-Risk Changes

1.**Fluent Bit 3→4**: Major version upgrade with potential breaking changes

- Mitigation: Review migration guide, test log pipelines in staging
- Timeline: Allocate 2-3 days for testing

  2.**NVIDIA GPU Exporter Migration**: Service replacement

- Mitigation: Parallel deployment, gradual transition
- Timeline: 1-2 weeks planning + implementation

  3.**Redis 7→8**: Major version with data format incompatibility

- Current Status: Intentionally pinned
- Recommendation: Consider incremental update to 7.4.0 first
- Alternative: Plan data migration strategy for 8.4.0

### Medium-Risk Changes

1.**Prometheus 7 versions gap**: Potential query language changes 2.**Redis
Exporter 18 versions gap**: Extensive changes require testing 3.**npm 10→11**:
Major version may affect build scripts

### Low-Risk Changes

All patch and minor version updates for exporters and monitoring tools.

---

## Verification Procedures

### Pre-Update Checklist

- [ ] Review service changelog for breaking changes
- [ ] Document current configuration
- [ ] Create backup of critical data (databases)
- [ ] Prepare rollback procedure

### Post-Update Validation

1.**Health Checks**

```bash
docker compose ps
docker compose logs [service_name]
```

2.**Service Connectivity**

```bash
curl http://localhost:4000/health/liveliness # LiteLLM
curl http://localhost:8080/health # Open WebUI
curl http://localhost:9091/-/healthy # Prometheus
curl http://localhost:3000/api/health # Grafana
```

3.**Functional Testing**

- Open WebUI: Access interface, test AI model interactions
- LiteLLM: Verify API endpoints, test model routing
- Prometheus: Check targets, verify metrics collection
- Grafana: Validate dashboards render correctly

  4.**Performance Baseline**

- Compare response times before/after
- Monitor GPU utilization (Ollama)
- Check memory usage patterns

---

## Recommendations

### Immediate Actions

1.**Update LiteLLM and Open WebUI**(Phase 1) - Low risk, high value 2.**Plan
Fluent Bit upgrade**- Security vulnerabilities addressed in
4.1.1 3.**Investigate Node.js version discrepancy**- Verify 22.14.0 vs LTS
22.11.0

### Strategic Initiatives

1.**Establish Version Monitoring**

- Implement Renovate or Dependabot for automated PR creation
- Configure Watchtower notifications for new image availability
- Create dashboard tracking version lag

  2.**Standardize Image Tagging**

- Migrate digest-based images to semantic versions (Tika, SearXNG, EdgeTTS)
- Avoid `:latest` and `:main` tags in production
- Document pinning strategy

  3.**NVIDIA GPU Monitoring Modernization**

- Priority migration to DCGM Exporter
- Official NVIDIA support ensures long-term reliability
- Enhanced metrics for ML workloads

### Long-Term Considerations

1.**Redis Upgrade Path**

- Evaluate 7.4.0 as incremental step
- Plan 8.x migration with data compatibility testing
- Timeline: Q1 2026

  2.**Major Version Tracking**

- Grafana 12.x evaluation after 11.6.8 stabilization
- Go 1.25.x assessment for auth service
- npm 11.x testing for build pipeline

---

## Conclusion

This comprehensive audit identified 26 services (87%) with available updates
across the ERNI-KI platform. The recommended phased approach prioritizes:

1.**Immediate**(This Week): Stable updates for LiteLLM and Open
WebUI 2.**Short-term**(Next Sprint): Infrastructure and monitoring stack
modernization 3.**Medium-term**(This Month): Major version updates with testing
requirements 4.**Strategic**(Next Quarter): Service migrations and architectural
improvements

All recommendations include risk assessments, testing procedures, and rollback
strategies to ensure platform stability during the update process.

---

## Appendices

### A. Complete Version Matrix

Refer to the version matrix in the audit bundle (see repository
docs/data/version-matrix) for quick reference.

### B. Detailed Implementation Plan

Refer to the implementation plan in docs/archive/audits/implementation-plan.md
for step-by-step update procedures with file locations and code diffs.

### C. References

- Docker Compose: `compose.yml` (repo root)
- Node.js Dependencies: `package.json` (repo root)
- Go Dependencies: `auth/go.mod`
- Python Dependencies: `conf/webhook-receiver/requirements.txt`

---

**Report Generated**: November 25, 2025**Next Audit Recommended**: February 2026
(Quarterly)
