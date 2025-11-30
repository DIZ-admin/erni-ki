---
language: en
translation_status: complete
doc_version: '2025.11'
title: 'Pre-Deployment Checklist'
system_version: '0.6.3'
last_updated: '2025-11-30'
system_status: 'Production Ready'
---

# Pre-Deployment Checklist for ERNI-KI

**Purpose:** Ensure system stability and safety before every production deployment.

**Used by:** DevOps team, Release Manager, On-call Engineer
**Frequency:** Before every deploy to main branch
**Time estimate:** 15-30 minutes
**Runbook:** See [Emergency Procedures](#emergency-procedures)

---

## Phase 1: Code Quality & Security ✅

**Responsible:** CI/CD Pipeline (automatic) + Manual verification

### Automated Checks (Must Pass)
- [ ] **CI Pipeline green** — All GitHub Actions passing
  - ✅ Linting (ESLint + Ruff)
  - ✅ Type checking (TypeScript)
  - ✅ Unit tests (81/81 passing)
  - ✅ E2E tests (playwright mock)
  - ✅ Security scans (CodeQL + Trivy)
  - ✅ Gitleaks (no secrets detected)

### Manual Verification
- [ ] **Code review completed**
  - Minimum 1 approval from CODEOWNERS
  - No "blocked" reviews
  - Comments resolved

- [ ] **Commit history clean**
  - Semantic commit messages (feat/fix/docs/chore)
  - Squashed trivial commits (if applicable)
  - No merge conflicts

- [ ] **CHANGELOG.md updated**
  - New version entry added
  - All changes documented
  - Format follows Semantic Versioning

---

## Phase 2: Pre-Deployment Backup & Snapshots ⚠️

**Responsible:** DevOps / SRE
**Critical:** These must complete BEFORE deployment

### Database Backups
- [ ] **PostgreSQL backup created**
  ```bash
  # Command should succeed
  docker compose exec db pg_dump -U postgres erni_ki | gzip > backups/erni_ki_$(date +%Y%m%d_%H%M%S).sql.gz

  # Verify
  ls -lh backups/erni_ki_*.sql.gz | tail -1
  ```
  - Backup size > 1MB (sanity check)
  - Timestamp is recent (within last 2 minutes)

- [ ] **Redis snapshot created**
  ```bash
  # Trigger Redis BGSAVE
  docker compose exec redis redis-cli BGSAVE

  # Verify snapshot exists
  docker volume inspect erni-ki_redis_data
  ```
  - Snapshot in `/data/dump.rdb`
  - File size > 100KB

- [ ] **Backrest backup completed** (if configured)
  ```bash
  docker compose logs backrest | grep -i "backup completed" | tail -1
  ```

### System Snapshots
- [ ] **Docker volume snapshots** (optional, for critical systems)
  ```bash
  # For PostgreSQL
  docker run --rm -v erni-ki_postgres_data:/data alpine tar czf - /data > postgres_snapshot.tar.gz
  ```

---

## Phase 3: Staging Environment Validation 🧪

**Responsible:** QA / Release Manager
**Environment:** Staging (compose-staging.yml or equivalent)

### Smoke Tests
- [ ] **Health checks pass on staging**
  ```bash
  ./scripts/health-monitor.sh --report
  # Expected output: All 34/34 services healthy
  ```

- [ ] **Critical API endpoints respond**
  - [ ] OpenWebUI `/health` → 200 OK
  - [ ] LiteLLM `/health` → 200 OK
  - [ ] PostgreSQL is reachable
  - [ ] Redis is reachable
  - [ ] Ollama `/api/tags` → 200 OK (models loaded)

- [ ] **Chat functionality works**
  ```bash
  # Send test message via OpenWebUI
  curl -X POST http://localhost:8080/api/chat \
    -H "Content-Type: application/json" \
    -d '{"message":"Test message","model":"ollama"}'
  # Should receive response, not error
  ```

### Monitoring & Alerting
- [ ] **Prometheus scrapes all targets**
  ```bash
  curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
  # Expected: 32 (or verify all critical services are UP)
  ```

- [ ] **Grafana dashboards load**
  - [ ] GPU/LLM dashboard loads without errors
  - [ ] Infrastructure metrics visible
  - [ ] Alerts not firing (unless expected)

- [ ] **AlertManager rules are correct**
  ```bash
  curl -s http://localhost:9093/api/v1/alerts | jq '.data | length'
  # Should be 0 (no active alerts in staging)
  ```

### Data Integrity
- [ ] **Database connects and responds**
  ```bash
  docker compose exec db psql -U postgres -d erni_ki -c "SELECT version();"
  ```

- [ ] **No pending migrations**
  ```bash
  # If applicable to your stack
  docker compose exec openwebui curl http://localhost:8080/api/migrations/pending
  # Should return empty list
  ```

---

## Phase 4: Production Environment Pre-flight 🚀

**Responsible:** DevOps / SRE
**Timing:** 5-10 minutes before deployment

### System Resources
- [ ] **Disk space sufficient**
  ```bash
  # On production server
  df -h / | grep -v "^Filesystem"
  # Expected: >20GB available
  ```

- [ ] **Memory available**
  ```bash
  # Expected: >4GB free
  free -h | grep Mem | awk '{print $7}'
  ```

- [ ] **CPU not overloaded**
  ```bash
  # Load average should be <2.0
  uptime
  ```

### Connectivity
- [ ] **Internet connectivity stable**
  ```bash
  ping -c 3 8.8.8.8
  # All packets should succeed
  ```

- [ ] **Docker registry accessible**
  ```bash
  docker pull ghcr.io/open-webui/open-webui:latest --dry-run
  # Should not timeout
  ```

- [ ] **GPU drivers initialized** (if GPU enabled)
  ```bash
  nvidia-smi
  # GPU should be visible and ready
  ```

### Logs & Monitoring
- [ ] **No critical errors in recent logs**
  ```bash
  docker compose logs --tail 100 | grep -i error | grep -v "expected" | wc -l
  # Should be 0 or minimal
  ```

- [ ] **Monitoring is collecting metrics**
  ```bash
  curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result | length'
  # Should be > 20
  ```

---

## Phase 5: Deployment Execution 🔄

**Responsible:** DevOps / Release Manager
**Duration:** 5-15 minutes (depending on image size)

### Pre-execution
- [ ] **Slack notification sent**
  ```
  🚀 Starting deployment of ERNI-KI v0.6.3 to production
  Expected downtime: <2 minutes
  Rollback plan: Available (v0.6.2 snapshot ready)
  ```

- [ ] **Team is available for rollback**
  - DevOps team on-call
  - Incident response plan activated
  - Communication channel open

### Deployment Steps
- [ ] **Pull latest images**
  ```bash
  docker compose pull
  ```

- [ ] **Apply database migrations** (if any)
  ```bash
  # Custom migration script, if needed
  ```

- [ ] **Perform rolling update**
  ```bash
  # Option 1: Full restart (2-5 min downtime)
  docker compose down
  docker compose up -d

  # Option 2: Service-by-service (0 downtime)
  for service in litellm openwebui nginx; do
    docker compose up -d $service
    sleep 10
    ./scripts/health-monitor.sh --service $service
  done
  ```

- [ ] **Wait for services to stabilize**
  ```bash
  # Give services 30 seconds to reach steady state
  sleep 30
  ```

---

## Phase 6: Post-Deployment Validation ✔️

**Responsible:** DevOps + On-call Engineer
**Duration:** 10-15 minutes
**Critical:** All items must pass before declaring success

### Immediate Health Checks (0-2 min)
- [ ] **All services are running**
  ```bash
  docker compose ps
  # Expected: All services "Up" status
  ```

- [ ] **Health check passes**
  ```bash
  ./scripts/health-monitor.sh --report
  # Expected output: 34/34 services healthy
  ```

- [ ] **No error spikes in logs**
  ```bash
  docker compose logs --tail 50 | grep -i "error\|exception\|panic"
  # Should be 0 or expected errors only
  ```

### System Stability Checks (2-5 min)
- [ ] **Prometheus targets healthy**
  ```bash
  curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
  # Expected: 32-34 UP targets
  ```

- [ ] **No alerts firing** (unexpected)
  ```bash
  curl -s http://localhost:9093/api/v1/alerts | jq '.data | length'
  # Expected: 0 (or only expected alerts)
  ```

- [ ] **Response times normal**
  ```bash
  # Check OpenWebUI response
  time curl -s http://localhost:8080/health > /dev/null
  # Expected: <500ms
  ```

### Functional Validation (5-15 min)
- [ ] **Chat works end-to-end**
  ```bash
  # Send test message
  curl -X POST http://localhost:8080/api/chat \
    -H "Content-Type: application/json" \
    -d '{"message":"Deploy validation test","model":"ollama"}' \
    -m 30
  # Should receive response within 30s
  ```

- [ ] **RAG search works**
  ```bash
  # Test SearXNG integration
  curl -s 'http://localhost:8888/api/v1/search?q=test'
  # Should return results
  ```

- [ ] **Document processing works** (if available)
  ```bash
  # Test Docling endpoint
  curl -s http://localhost:7860/health
  # Expected: 200 OK
  ```

### Monitoring Validation
- [ ] **Grafana dashboards load**
  - Visit: http://ki.erni-gruppe.ch/grafana
  - Check: GPU/LLM metrics visible
  - Check: No missing data points

- [ ] **AlertManager active routes correct**
  - Visit: http://ki.erni-gruppe.ch/alertmanager
  - Verify: Slack/Email integrations configured
  - Verify: Correct team is on-call

---

## Phase 7: Post-Deployment Communication 📢

**Responsible:** Release Manager / Product

### Internal Team
- [ ] **Slack notification sent**
  ```
  ✅ ERNI-KI v0.6.3 successfully deployed to production
  - All services healthy (34/34)
  - Zero errors in first 5 minutes
  - Chat functionality verified
  - Deployment time: 12 minutes
  - Monitoring: All green
  ```

- [ ] **Team acknowledged deployment**
  - Comments in Slack
  - Status page updated

### External Users
- [ ] **Status page updated** (if public)
  - Deployment completed
  - No service degradation
  - Normal SLA maintained

- [ ] **Release notes published** (if applicable)
  - What's new
  - Bug fixes
  - Known issues

---

## Emergency Procedures 🆘

### Rollback (if issues detected)

**Trigger conditions:**
- Error rate > 1%
- Response time p99 > 10s
- Any service unhealthy for >5 minutes
- Critical functionality not working

**Rollback steps (2-5 minutes):**

```bash
# 1. Stop current deployment
docker compose down

# 2. Restore from backup
# Option A: Previous compose config
git checkout HEAD~1 -- compose.yml
docker compose pull

# Option B: Database rollback (if needed)
docker volume rm erni-ki_postgres_data
docker run -v erni-ki_postgres_data:/var/lib/postgresql/data -v $PWD/backups:/backups alpine sh -c 'cd /var/lib/postgresql/data && tar xzf /backups/postgres_snapshot.tar.gz --strip-components=1'

# 3. Start services
docker compose up -d

# 4. Verify rollback
./scripts/health-monitor.sh --report

# 5. Notify team
# Send Slack alert with rollback details
```

**Notification template:**
```
🚨 ROLLBACK EXECUTED
- Rolled back to: v0.6.2
- Reason: [reason]
- Timestamp: [ISO 8601]
- Estimated impact: [N services affected for M minutes]
- Next steps: [post-mortem / fix plan]
```

---

## SLA Impact Tracking

**During deployment:**
- Expected downtime: <2 minutes (if rolling update used)
- Services affected: All (potential, but monitoring continues)
- SLA impact: <0.003% (30 sec / 1440 min per day)

**Post-deployment:**
- Monitor SLA metrics for 24 hours
- If SLA violated, document in incident report
- Alert if: uptime < 99.95%

---

## Checklist Validation

**Before deploying, fill in:**

```markdown
**Deployment Details**
- Version: 0.6.3
- Branch: main
- Commit SHA: abc1234567
- Deployer: [Name]
- Deployment start time: 2025-11-30 14:00:00 UTC

**Sign-off**
- [ ] Code quality: PASSED
- [ ] Staging validation: PASSED
- [ ] Pre-flight checks: PASSED
- [ ] Backups created: CONFIRMED
- [ ] Team available: CONFIRMED
- [ ] Post-deployment validation: PASSED
- [ ] Communication sent: CONFIRMED

**Approval**
- DevOps Lead: _________________ Date: _______
- Release Manager: _________________ Date: _______
```

---

## Quick Reference

| Phase | Duration | Owner | Critical? |
|-------|----------|-------|-----------|
| Code Quality | 5 min | CI/CD | ✅ YES |
| Backups | 10 min | DevOps | ✅ YES |
| Staging Tests | 10 min | QA | ✅ YES |
| Pre-flight | 5 min | SRE | ✅ YES |
| Deployment | 5-15 min | DevOps | ✅ YES |
| Post-deployment | 10-15 min | DevOps | ✅ YES |
| Communication | 5 min | Release Mgr | ⚠️ IMPORTANT |

**Total time:** 50-65 minutes

---

## See Also

- [SLA Definitions](./sla-definitions.md)
- [Operations Handbook](./operations-handbook.md)
- [Admin Guide](./admin-guide.md)
- [Runbooks Summary](./runbooks-summary.md)
