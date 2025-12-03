---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-29'
---

# Production Deployment Checklist

> **Document Version:** 1.0 **Last Updated:** 2025-11-29 **Deployment
> Approach:** Blue-Green with Rolling Updates **Rollback Time:** <5 minutes

Use this checklist before deploying ERNI-KI to production. Complete all sections
to ensure a safe, secure, and reliable deployment.

## Pre-Deployment Phase (1 week before)

### Code Quality Gate

- [ ] All tests passing (`npm run test` and `pytest tests/`)
- [ ] No critical security issues in security scan
- [ ] Code coverage >85% (check `coverage report`)
- [ ] All linting checks pass (`npm run lint` and `npm run lint:py`)
- [ ] TypeScript compilation successful (`npx tsc --noEmit`)
- [ ] Python type checking passes (`mypy .`)
- [ ] Zero CRITICAL or HIGH severity vulnerabilities

```bash
npm audit --audit-level=moderate
safety check

```

### Changelog & Documentation

- [ ] CHANGELOG.md updated with version and changes
- [ ] API documentation updated for new endpoints
- [ ] Migration guide written (if database changes)
- [ ] Security advisories documented (if security changes)
- [ ] README.md reflects current state
- [ ] Runbooks updated for operational changes

### Testing Validation

- [ ] Unit tests: 100% pass rate

```bash
pytest tests/unit/ -v --tb=short
npm run test -- tests/unit

```

- [ ] Integration tests: 100% pass rate on staging

```bash
pytest tests/integration/ -v
npm run test:integration

```

- [ ] E2E tests: 100% pass rate on staging environment

```bash
npm run test:e2e

```

- [ ] Performance tests: Baseline established

```bash
npm run test:performance

```

- [ ] Load testing completed (simulate expected traffic)

```bash
# Using k6 or similar
k6 run tests/load/main.js

```

### Security Pre-deployment

- [ ] Secrets rotated (>30 days old)
- [ ] API keys regenerated
- [ ] Database credentials updated
- [ ] Webhook secrets configured
- [ ] TLS certificates valid and updated
- [ ] Database encryption keys backed up
- [ ] No hardcoded secrets in code

```bash
# Scan for secrets
detect-secrets scan
git secrets --scan

```

- [ ] Environment variables documented
- [ ] Access control policies reviewed
- [ ] RBAC permissions tested

### Infrastructure Preparation

- [ ] Kubernetes manifests validated

```bash
kubectl apply --dry-run=client -f k8s/

```

- [ ] Docker images built and scanned

```bash
docker build -t erni-ki:vX.Y.Z .
trivy image erni-ki:vX.Y.Z

```

- [ ] Database backups tested (restore verification)

```bash
# Test backup/restore cycle
./scripts/backup-database.sh
./scripts/restore-database.sh

```

- [ ] DNS records updated (if domain changed)
- [ ] SSL/TLS certificates installed
- [ ] Load balancer configuration validated
- [ ] Monitoring dashboards created

## Staging Deployment (2-3 days before)

### Deploy to Staging

- [ ] Code deployed to staging environment
- [ ] Environment variables set correctly
- [ ] Database migrations applied
- [ ] Services reachable and healthy

```bash
curl -s https://staging.ki.erni-gruppe.ch/health | jq .

```

### Staging Validation

- [ ] All critical endpoints responding

```bash
curl -s https://staging.ki.erni-gruppe.ch/api/v1/chats
curl -s https://staging.ki.erni-gruppe.ch/api/v1/models
curl -s https://staging.ki.erni-gruppe.ch/webhook/health

```

- [ ] Webhook endpoints accepting alerts

```bash
# Test with webhook client
python docs/examples/webhook-client-python.py \
--url https://staging.ki.erni-gruppe.ch \
--endpoint critical \
--alert-name "StagingTest"

```

- [ ] Database queries performant
- [ ] Logging and monitoring operational
- [ ] Backup/restore procedures tested
- [ ] Alertmanager routing configured
- [ ] OAuth/authentication working
- [ ] Rate limiting functional

### Staging Smoke Tests

- [ ] Create chat and send message
- [ ] Upload document and run RAG search
- [ ] Pull and run AI model
- [ ] List all available models
- [ ] Monitor metrics in Grafana
- [ ] Check Prometheus scrape targets
- [ ] Verify alert generation and routing
- [ ] Test webhook signature verification

### Performance Baseline

- [ ] Response time <2s for API calls
- [ ] Webhook processing <1s per alert
- [ ] Database query response <500ms
- [ ] GPU utilization <80%
- [ ] Memory usage <70%
- [ ] CPU usage <60%

Document these baselines for comparison post-deployment:

```yaml
Baselines (Staging):
  api_latency_p95: 1.2s
  webhook_processing: 0.8s
  db_query_p95: 450ms
  gpu_utilization: 65%
  memory_usage: 55%
  cpu_usage: 45%
```

## Production Preparation (1 day before)

### Final Security Check

- [ ] API security headers configured

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000

```

- [ ] CORS policy appropriate
- [ ] Rate limiting configured:
- [ ] API: 100 requests/minute per IP
- [ ] Webhooks: 10 requests/minute per IP
- [ ] Authentication: 5 attempts/minute

- [ ] Webhook HMAC secrets configured

```bash
echo $ALERTMANAGER_WEBHOOK_SECRET | wc -c # Should be 32+ chars

```

- [ ] Database passwords strong (20+ chars, mixed case, numbers, symbols)
- [ ] SSH keys rotated
- [ ] API keys rotated
- [ ] Service account credentials verified

### Monitoring Configuration

- [ ] Prometheus targets added

```bash
curl -s http://prometheus:9090/api/v1/targets | jq .

```

- [ ] Grafana dashboards imported
- [ ] Alert rules configured and tested
- [ ] Log aggregation (Loki/ELK) configured
- [ ] Error tracking (Sentry) initialized
- [ ] APM (Application Performance Monitoring) enabled

### Rollback Plan

- [ ] Previous version deployed in staging

```bash
docker pull erni-ki:vX.Y.(Z-1)
docker-compose up -d --image erni-ki:vX.Y.(Z-1)

```

- [ ] Database rollback scripts tested
- [ ] DNS failover configured
- [ ] Rollback communication plan established
- [ ] Estimated rollback time documented: **<5 minutes**

### Team Preparation

- [ ] On-call team notified
- [ ] Deployment window scheduled
- [ ] Communications channel established (Slack/Teams)
- [ ] Runbooks distributed to team
- [ ] Post-incident review date scheduled
- [ ] Stakeholders informed of deployment

## Production Deployment (Execution)

### Pre-Deployment Window

```bash
# 30 minutes before deployment
[ ] Verify all services healthy
 docker-compose ps
 kubectl get pods
 curl https://ki.erni-gruppe.ch/health

[ ] Create database snapshot
 kubectl exec db -- pg_dump > backup.sql

[ ] Notify team in Slack
 @channel Deployment starting in 30 minutes

[ ] Do final staging verification
 curl https://staging.ki.erni-gruppe.ch/api/v1/chats


```

### Deployment Execution

**Approach: Rolling Update with Blue-Green Fallback**

```bash
# Blue-Green Deployment (if available)
1. Deploy to green environment (no traffic)
2. Run smoke tests on green
3. Switch traffic from blue to green
4. Keep blue ready for rollback

# Rolling Update (if using Kubernetes)
1. Update deployment
2. Kubernetes manages pod replacement
3. Monitors health and rolls back if needed


```

**Step-by-step:**

```bash
# 1. Pull latest image
docker pull erni-ki:vX.Y.Z

# 2. Verify image integrity
docker run --rm erni-ki:vX.Y.Z --version

# 3. Drain connections from load balancer (optional)
kubectl drain node --ignore-daemonsets --delete-emptydir-data

# 4. Update deployment
kubectl set image deployment/erni-ki \
 erni-ki=erni-ki:vX.Y.Z \
 --record

# 5. Watch rollout status
kubectl rollout status deployment/erni-ki

# 6. Verify new version deployed
kubectl get pods -l app=erni-ki
docker-compose ps erni-ki


```

### Immediate Post-Deployment

**Verify within 5 minutes:**

- [ ] All services running

```bash
docker-compose ps # All containers "Up"

```

- [ ] Core endpoints responding

```bash
curl -s https://ki.erni-gruppe.ch/health | jq '.status' # "healthy"
curl -s https://ki.erni-gruppe.ch/api/v1/chats | jq '.total'

```

- [ ] No errors in logs

```bash
docker-compose logs --tail=20 | grep -i error
kubectl logs -l app=erni-ki --tail=20 | grep -i error

```

- [ ] Database accessible

```bash
docker-compose exec db psql -U openwebui_user -d openwebui -c "SELECT 1;"

```

- [ ] Monitoring data flowing

```bash
curl -s http://prometheus:9090/api/v1/targets | jq '.data.activeTargets | length'

```

- [ ] No increase in error rates

```bash
# Check Prometheus for error metrics
curl "http://prometheus:9090/api/v1/query?query=rate(errors_total[5m])"

```

### Smoke Tests

**Run within 10 minutes of deployment:**

```bash
# Create test chat
curl -X POST https://ki.erni-gruppe.ch/api/v1/chats \
 -H "Authorization: Bearer $TOKEN" \
 -H "Content-Type: application/json" \
 -d '{"title":"Deploy Test","model":"llama3.2:3b"}'

# Send message
curl -X POST https://ki.erni-gruppe.ch/api/v1/chats/{chat_id}/messages \
 -H "Authorization: Bearer $TOKEN" \
 -d '{"content":"test"}'

# Test webhook
python docs/examples/webhook-client-python.py \
 --endpoint critical \
 --alert-name "DeploymentTest"

# List models
curl -s https://ki.erni-gruppe.ch/api/v1/models | jq '.models | length'


```

## Post-Deployment Monitoring (24 hours)

### Continuous Monitoring

**Every 15 minutes for 2 hours:**

- [ ] Error rate stable
- [ ] Response times normal
- [ ] CPU usage normal (<70%)
- [ ] Memory usage normal (<75%)
- [ ] Disk usage normal (<85%)
- [ ] Database connections healthy
- [ ] GPU utilization normal (<80%)

**Every hour for 24 hours:**

- [ ] All alert rules firing correctly
- [ ] No cascading failures
- [ ] Webhook processing latency normal
- [ ] Database query performance normal
- [ ] No security alerts
- [ ] User reports/complaints: 0

### Performance Comparison

Compare against baselines established in staging:

| Metric             | Staging | Production | Status |
| ------------------ | ------- | ---------- | ------ |
| API Latency (p95)  | 1.2s    | 1.1s       | PASS   |
| Webhook Processing | 0.8s    | 0.75s      | PASS   |
| DB Query (p95)     | 450ms   | 440ms      | PASS   |
| GPU Utilization    | 65%     | 62%        | PASS   |
| Memory Usage       | 55%     | 56%        | PASS   |
| CPU Usage          | 45%     | 43%        | PASS   |

**If any metric degrades >10% from staging baseline:**

1. Check for resource constraints
2. Review recent deployments
3. Investigate slow queries
4. Consider rollback if critical

### Log Review

```bash
# Check logs for errors
docker-compose logs --since 1h | grep -i error

# Check specific service logs
kubectl logs -l app=erni-ki --since=1h | grep ERROR

# Check webhook receiver logs
docker-compose logs webhook-receiver --tail=100 | grep -i error

# Search for specific alert patterns
docker-compose logs | grep "OllamaServiceDown"


```

## Production Validation Checklist

### Functional Testing

- [ ] All documented features working
- [ ] API endpoints responding correctly
- [ ] Webhooks processing correctly
- [ ] Authentication/authorization working
- [ ] Rate limiting enforced
- [ ] Database writes/reads successful
- [ ] Search functionality operational
- [ ] Export features working
- [ ] Admin panel accessible
- [ ] User management functional

### Security Validation

- [ ] HTTPS only (no HTTP)
- [ ] HSTS header present
- [ ] CSP header configured
- [ ] X-Frame-Options set
- [ ] X-Content-Type-Options set
- [ ] Secure cookies (httpOnly, Secure flags)
- [ ] No sensitive data in logs
- [ ] Secrets not exposed in responses
- [ ] Rate limiting preventing abuse
- [ ] CORS properly restricted

### Operational Validation

- [ ] Monitoring data flowing correctly
- [ ] Alerts configured and firing
- [ ] Logs aggregated and searchable
- [ ] Backups running automatically
- [ ] Health checks passing
- [ ] Scaling policies active
- [ ] Auto-recovery working
- [ ] Failover procedures validated

## Post-Deployment Sign-Off

### Engineering Sign-Off

- [ ] QA Engineer: All tests passed \***\*\_\*\*** (name, date)
- [ ] DevOps Engineer: Infrastructure stable \***\*\_\*\*** (name, date)
- [ ] Tech Lead: Code review approved \***\*\_\*\*** (name, date)

### Production Verification

- [ ] Deployment completed successfully
- [ ] All smoke tests passed
- [ ] 24-hour monitoring period started
- [ ] Performance baselines met
- [ ] No critical issues identified
- [ ] Rollback plan validated

### Communication

- [ ] Team notified of successful deployment
- [ ] Customers notified (if relevant)
- [ ] Status page updated
- [ ] Release notes published
- [ ] Changelog updated

## Incident Response (if issues occur)

### Immediate Actions

```bash
# Check service health
docker-compose ps
kubectl get pods -l app=erni-ki

# Check recent errors
docker-compose logs --tail=50 | grep ERROR

# Check resource usage
docker stats
kubectl top pods

# Check database
docker-compose exec db psql -U openwebui_user -d openwebui -c "SELECT 1;"


```

### Decision to Rollback

**Rollback if:**

- [ ] Error rate >5% (was <1% in staging)
- [ ] Response time >5s (was <2s in staging)
- [ ] Service unavailability >30 seconds
- [ ] Data corruption detected
- [ ] Security vulnerability discovered
- [ ] Database migration failure

### Rollback Procedure

```bash
# 1. Announce rollback
echo "@channel Rolling back to previous version" > /slack/deployments

# 2. Switch traffic to previous version
kubectl set image deployment/erni-ki \
 erni-ki=erni-ki:vX.Y.(Z-1) \
 --record

# 3. Monitor rollback
kubectl rollout status deployment/erni-ki

# 4. Verify previous version working
curl -s https://ki.erni-gruppe.ch/health

# 5. Document incident
# Create incident report with timeline and root cause


```

**Expected Rollback Time:** <5 minutes

## Post-Deployment Review (within 24 hours)

### Incident Review

- [ ] No incidents occurred (skip to "Success Review")
- [ ] Incident occurred - schedule post-mortem

### Success Review

- [ ] What went well
- [ ] What could be improved
- [ ] Lessons learned documented
- [ ] Process improvements identified

### Metrics Review

- [ ] Performance metrics meet expectations
- [ ] Error rates acceptable
- [ ] User feedback positive
- [ ] System stable

## Environment Variables Checklist

**Ensure these are set before deployment:**

```bash
# Core Settings
[ ] ENVIRONMENT=production
[ ] LOG_LEVEL=INFO
[ ] PROJECT_ROOT=/app

# Database
[ ] OPENWEBUI_DB_HOST=db
[ ] OPENWEBUI_DB_PORT=5432
[ ] POSTGRES_USER=<set>
[ ] POSTGRES_PASSWORD=<strong>

# Security
[ ] ALERTMANAGER_WEBHOOK_SECRET=<strong>
[ ] JWT_SECRET=<strong>
[ ] API_KEY=<strong>

# Services
[ ] OLLAMA_URL=http://ollama:11434
[ ] LITELLM_API_KEY=<set>
[ ] DISCORD_WEBHOOK_URL=<set or empty>
[ ] SLACK_WEBHOOK_URL=<set or empty>

# Monitoring
[ ] PROMETHEUS_ENABLED=true
[ ] ALERTMANAGER_ENABLED=true
[ ] LOKI_ENABLED=true

# TLS/HTTPS
[ ] TLS_CERT_PATH=/etc/ssl/certs/server.crt
[ ] TLS_KEY_PATH=/etc/ssl/private/server.key


```

## Related Documentation

- [Development Setup Guide](../development/setup-guide.md)
- [Testing Guide](../development/testing-guide.md)
- [Security Policy](../security/security-policy.md)
- [Monitoring Guide](../operations/monitoring/monitoring-guide.md)
- [Backup & Recovery](../operations/backup-guide.md)

## Support

For deployment questions or issues:

1. Check [Troubleshooting Guide](../troubleshooting/common-issues.md)
2. Review deployment logs
3. Check GitHub issues: https://github.com/erni-gruppe/erni-ki/issues
4. Contact: deployments@erni-gruppe.ch

---

**Deployment completed successfully!**

Document deployment time: \***\*\_\_\_\_\*\*** Deployed by: \***\*\_\_\_\_\*\***
Approved by: \***\*\_\_\_\_\*\***
