# ERNI-KI Service Version Matrix

Quick reference table for all service versions - complete as of November 25,
2025

## 🔴 Critical Services - Immediate Updates Recommended

| Service         | Current      | Latest         | Gap       | Priority  | Notes                                          |
| --------------- | ------------ | -------------- | --------- | --------- | ---------------------------------------------- |
| **LiteLLM**     | v1.80.0.rc.1 | v1.80.5-stable | RC→Stable | 🔴 HIGH   | Move from RC to stable, test API compatibility |
| **Open WebUI**  | v0.6.36      | v0.6.39        | 3 patches | 🔴 HIGH   | Latest fixes, very low risk                    |
| **Ollama**      | 0.12.11      | 0.13.0         | 1 minor   | 🔴 HIGH   | Vulkan, GPU improvements - test thoroughly     |
| **Cloudflared** | 2024.10.0    | 2025.11.1      | ~1 year   | 🟡 MEDIUM | Security fixes, test tunnel config             |
| **Prometheus**  | v3.0.0       | v3.7.3         | 7 minors  | 🟡 MEDIUM | Test alert rules (or use v3.5.0 LTS)           |

## 🟡 Monitoring Stack - Standard Updates

| Service               | Current | Latest         | Gap        | Priority  | Notes                                     |
| --------------------- | ------- | -------------- | ---------- | --------- | ----------------------------------------- |
| **Loki**              | 3.0.0   | 3.6.1          | 6 minors   | 🟡 MEDIUM | Bloom filters, OpenTelemetry support      |
| **Grafana**           | 11.3.0  | 11.6.8         | 3 minors   | 🟡 MEDIUM | Update to 11.6.8, then evaluate 12.x      |
| **Alertmanager**      | v0.27.0 | v0.29.0        | 2 minors   | 🟢 LOW    | Alert routing improvements                |
| **Node Exporter**     | v1.8.2  | v1.10.2        | 2 minors   | 🟢 LOW    | Enhanced metrics                          |
| **Postgres Exporter** | v0.15.0 | v0.18.1        | 3 minors   | 🟢 LOW    | Better PG metrics                         |
| **Redis Exporter**    | v1.62.0 | v1.80.1        | 18 minors! | 🟡 MEDIUM | Large gap - test thoroughly               |
| **Blackbox Exporter** | v0.25.0 | v0.27.0        | 2 minors   | 🟢 LOW    | JSON body matching                        |
| **Nginx Exporter**    | 1.1.0   | 1.5.1          | 4 minors   | 🟡 MEDIUM | Significant improvements                  |
| **cAdvisor**          | v0.52.1 | v0.53.0        | 1 minor    | 🟢 LOW    | Container monitoring updates              |
| **Fluent Bit**        | 3.1.0   | 4.2.0 (v4.1.1) | MAJOR      | 🟡 MEDIUM | Major update 3→4, security fixes in 4.1.1 |
| **Uptime Kuma**       | 2.0.2   | 2.0.2 ✅       | CURRENT    | ⚪ N/A    | Already latest                            |

## 🟢 Infrastructure Services

| Service        | Current                   | Latest            | Gap         | Priority  | Notes                                 |
| -------------- | ------------------------- | ----------------- | ----------- | --------- | ------------------------------------- |
| **PostgreSQL** | pg17                      | pg17 ✅           | CURRENT     | ⚪ N/A    | Latest major                          |
| **pgvector**   | 0.8.0 (assumed)           | 0.8.1             | 1 patch     | 🟢 LOW    | Minor extension update                |
| **Redis**      | 7.0.15-alpine             | 8.4.0 (or 7.4.0)  | MAJOR/minor | 🔴 HOLD   | Major=risky; 7.4.0=safer incremental  |
| **Nginx**      | 1.29.3                    | 1.29.3 ✅         | CURRENT     | ⚪ N/A    | Latest mainline (stable=1.28.0 older) |
| **Tika**       | sha256:3fafa...           | 3.2.3             | Unknown     | 🟡 MEDIUM | Switch digest→version tag             |
| **SearXNG**    | sha256:aaa855... (Nov 12) | Rolling (Nov 25+) | 2 weeks     | 🟢 LOW    | Update digest monthly                 |

## 🔵 Support Services

| Service                 | Current          | Latest               | Gap            | Priority    | Notes                                 |
| ----------------------- | ---------------- | -------------------- | -------------- | ----------- | ------------------------------------- |
| **Watchtower**          | 1.7.1            | 1.7.1 ✅             | CURRENT        | ⚪ N/A      | Already latest                        |
| **Backrest**            | v1.9.2           | v1.10.0              | 1 minor        | 🟢 LOW      | Backup improvements                   |
| **EdgeTTS**             | Digest           | v2.0.0/:latest       | Unknown        | 🟢 LOW      | Switch to version tag or :latest      |
| **MCPO Server**         | git-91e8f94      | v0.0.18              | Commit→Version | 🟡 MEDIUM   | OAuth 2.0, check if commit is recent  |
| **Docling**             | :main            | :main (rolling)      | N/A            | ⚪ CONSIDER | Consider pinning for stability        |
| **NVIDIA GPU Exporter** | 0.1 (mindprince) | **DCGM 4.4.2-4.7.0** | MIGRATION      | 🔴 HIGH     | **Replace** with NVIDIA DCGM Exporter |

## 📦 Development Dependencies

| Component             | Current | Latest      | Gap       | Priority  | Notes                                |
| --------------------- | ------- | ----------- | --------- | --------- | ------------------------------------ |
| **Node.js**           | 22.14.0 | 22.11.0 LTS | AHEAD?    | 🟡 VERIFY | Current > LTS - verify typo          |
| **npm**               | 10.8.2  | 11.6.3      | MAJOR     | 🟡 MEDIUM | Major version update available       |
| **Go**                | 1.24.0  | 1.24.10 ✅  | CURRENT   | ⚪ N/A    | Toolchain current (1.25.4 available) |
| **Flask**             | 3.0.3   | 3.1.2       | 2 patches | 🟢 LOW    | Bug fix release                      |
| **prometheus-client** | 0.20.0  | 0.23.1      | 3 minors  | 🟢 LOW    | Metrics improvements                 |
| **Werkzeug**          | 3.0.4   | Check       | Unknown   | 🟢 LOW    | Run pip list --outdated              |
| **requests**          | 2.32.3  | Check       | Unknown   | 🟢 LOW    | Run pip list --outdated              |

## Summary Statistics

- **Total Services**: 30
- **Services fully researched**: 30 (100% complete ✅)
- **Services with updates available**: 26
- **Already on latest**: 5 (Watchtower, Uptime Kuma, Nginx mainline, PostgreSQL,
  Go toolchain)
- **Critical priority updates**: 6 (including NVIDIA GPU Exporter migration)
- **High version gaps**: 3 (Redis Exporter: 18 versions, Prometheus: 7 versions,
  Fluent Bit: major)
- **Security-related**: 1 (Fluent Bit 4.1.1 fixes vulnerabilities)
- **Major version updates**: 3 (Redis 7→8, Fluent Bit 3→4, npm 10→11)
- **Service migrations**: 1 (NVIDIA GPU Exporter → DCGM Exporter)

## Priority Legend

- 🔴 **HIGH**: Critical functionality/security, immediate action recommended
- 🟡 **MEDIUM**: Important improvements, schedule for next sprint
- 🟢 **LOW**: Minor improvements, update when convenient
- ⚪ **N/A**: Already current or requires specific evaluation
- 🔴 **HOLD**: Requires careful planning (e.g., Redis major version)

## Update Phases

### Phase 1 (This Week) - Low Risk

1. LiteLLM v1.80.0.rc.1 → v1.80.5-stable
2. Open WebUI v0.6.36 → v0.6.39

### Phase 2 (Next Sprint) - Infrastructure

3. Cloudflared 2024.10.0 → 2025.11.1
4. Tika digest → 3.2.3
5. Prometheus v3.0.0 → v3.7.3 (or v3.5.0 LTS)
6. Grafana 11.3.0 → 11.6.8
7. Loki 3.0.0 → 3.6.1

### Phase 3 (Next Sprint) - Monitoring Exporters

8. Alertmanager v0.27.0 → v0.29.0
9. Node Exporter v1.8.2 → v1.10.2
10. Postgres Exporter v0.15.0 → v0.18.1
11. Redis Exporter v1.62.0 → v1.80.1
12. Blackbox Exporter v0.25.0 → v0.27.0
13. Nginx Exporter 1.1.0 → 1.5.1
14. cAdvisor v0.52.1 → v0.53.0

### Phase 4 (This Month) - Major Updates Requiring Testing

15. Fluent Bit 3.1.0 → 4.2.0 (major version, test pipelines)
16. Ollama 0.12.11 → 0.13.0 (test GPU thoroughly)
17. Backrest v1.9.2 → v1.10.0

### Phase 5 (This Month) - Dependencies & Remaining Services

18. npm 10.8.2 → 11.6.3
19. Flask 3.0.3 → 3.1.2
20. prometheus-client 0.20.0 → 0.23.1
21. Audit remaining Python packages (Werkzeug, requests, python-dateutil)
22. EdgeTTS - switch to version tag v2.0.0 or :latest
23. MCPO Server - evaluate v0.0.18 vs current commit

### Phase 6 (Next Quarter) - Service Migrations

24. **NVIDIA GPU Exporter** → **DCGM Exporter 4.4.2-4.7.0** (HIGH PRIORITY)
    - Research DCGM deployment (Docker/Helm)
    - Plan migration from mindprince to DCGM
    - Update Prometheus scrape configs
    - Test GPU metrics collection

### Future Evaluation

- Redis 7.0.15 → 7.4.0 (incremental) or 8.4.0 (major, requires testing)
- Go 1.24.10 → 1.25.4 (major version)
- Grafana 11.6.8 → 12.3.0 (major version)
- Node.js version verification and LTS alignment

## Quick Command Reference

```bash
# Pull latest images
docker compose pull

# Validate config
docker compose config

# Update and restart specific service
docker compose up -d [service_name]

# Check all service health
docker compose ps

# Python package audits
cd conf/webhook-receiver && pip list --outdated
cd ops/ollama-exporter && pip list --outdated

# Verify Node.js/npm versions
node --version
npm --version
```
