---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# Security Action Plan - ERNI-KI

**Created:**2025-12-03**Status:**ACTIVE**Priority:**CRITICAL **Basis:** ERNI-KI
Comprehensive Analysis 2025-12-02 (archived)

---

## Executive Summary

**Critical security vulnerabilities**(CVSS 6.5-10.0) have been identified and
require immediate remediation. This plan defines priority actions and
responsibilities.

**Production block status:**BLOCKED (until Phase 1 completion)

---

## Phase 1: Critical Fixes (1-3 days)

### Task 1.1: Remove Secrets from Git (CVSS 10.0)

**Priority:**P0 - CRITICAL**Timeline:**1 day**Responsible:**DevOps Lead
**Status:**TO DO

**Problem:**

```bash
secrets/
 postgres_password.txt # PLAIN TEXT IN GIT!
 litellm_api_key.txt # PLAIN TEXT IN GIT!
 openai_api_key.txt # PLAIN TEXT IN GIT!
 grafana_admin_password.txt # Weak: "admin"
```

**Actions:**

1.**Install git-filter-repo**

```bash
pip install git-filter-repo
```

2.**Remove secrets from Git history**

```bash
# Backup repository
cp -r .git .git.backup

# Remove secrets/ and env/ from history
git filter-repo --invert-paths \
 --path secrets/ \
 --path env/ \
 --force

# Verify result
git log --all --full-history -- secrets/
```

3.**Force push (COORDINATE WITH TEAM!)**

```bash
# Notify all developers
# Then:
git push --force --all
git push --force --tags
```

4.**Rotate ALL compromised secrets**

```bash
# PostgreSQL
psql -U postgres -c "ALTER USER postgres PASSWORD '$(openssl rand -base64 32)';"

# Redis
redis-cli CONFIG SET requirepass "$(openssl rand -base64 32)"

# LiteLLM, OpenAI - regenerate API keys in consoles
```

5.**Create .example files**

```bash
for file in secrets/*.txt; do
 echo "PLACEHOLDER_$(basename $file)" > "$file.example"
done

git add secrets/*.example
git commit -m "security: add secret templates"
```

6.**Update .gitignore**

```bash
echo "secrets/*.txt" >> .gitignore
echo "env/*.env" >> .gitignore
git add .gitignore
git commit -m "security: ignore secrets and env files"
```

**Completion Criteria:**

- [ ] Git history does not contain secrets/
- [ ] All secrets rotated
- [ ] .example files created
- [ ] .gitignore updated
- [ ] Team notified

---

### Task 1.2: Secure Uptime Kuma (CVSS 6.5)

**Priority:**P0 - CRITICAL**Timeline:**1 hour**Responsible:**DevOps Engineer
**Status:**TO DO

**Problem:**

```yaml
uptime-kuma:
  ports:
    - '3001:3001' # Open to entire network!
```

**Action:**

```yaml
uptime-kuma:
  ports:
    - '127.0.0.1:3001:3001' # Localhost only
```

**Steps:**

1. Edit compose.yml
2. `docker compose up -d uptime-kuma`
3. Verify accessible only from localhost

**Completion Criteria:**

- [ ] Port bound to 127.0.0.1
- [ ] `curl http://localhost:3001` - OK
- [ ] `curl http://192.168.x.x:3001` - FAIL

---

### Task 1.3: Fix Watchtower User (CVSS 7.8)

**Priority:**P0 - CRITICAL**Timeline:**1 hour**Responsible:**DevOps Engineer
**Status:**TO DO

**Problem:**

```yaml
watchtower:
  user: '0' # root UID
```

**Action:**

```yaml
watchtower:
  user: '${DOCKER_GID:-999}:${DOCKER_GID:-999}'
```

**Steps:**

1. Get docker group GID

```bash
getent group docker | cut -d: -f3
# Add to .env: DOCKER_GID=999
```

2. Update compose.yml
3. `docker compose up -d watchtower`
4. Verify Watchtower is working

**Completion Criteria:**

- [ ] User not root
- [ ] Watchtower successfully updates containers
- [ ] Logs contain no permission denied errors

---

### Task 1.4: Add ShellCheck to CI (P1)

**Priority:**P1 - HIGH**Timeline:**1 day**Responsible:**DevOps Engineer
**Status:**TO DO

**Problem:**110 shell scripts without static analysis

**Actions:**

1.**Add to .pre-commit-config.yaml**

```yaml
- repo: https://github.com/koalaman/shellcheck-precommit
 rev: v0.9.0
 hooks:
 - id: shellcheck
 args: ['--severity=warning']
```

2.**Add to CI**

```yaml
# .github/workflows/ci.yml
- name: ShellCheck
 run: |
 find . -name "*.sh" -not -path "./node_modules/*" | xargs shellcheck
```

3.**Fix critical issues**

```bash
shellcheck scripts/**/*.sh conf/**/*.sh | grep "error:"
```

**Completion Criteria:**

- [ ] ShellCheck in pre-commit
- [ ] ShellCheck in CI
- [ ] 0 critical issues

---

## Phase 2: High Priority (1-2 weeks)

### Task 2.1: Network Segmentation (P1)

**Priority:**P1 - HIGH**Timeline:**1 week**Responsible:**DevOps Lead
**Status:**TO DO

**Goal:**Isolate services by functional layers

**Design:**

```yaml
networks:
 frontend:
 driver: bridge
 ipam:
 config:
 - subnet: 172.20.0.0/24
 backend:
 driver: bridge
 internal: true
 ipam:
 config:
 - subnet: 172.21.0.0/24
 data:
 driver: bridge
 internal: true
 ipam:
 config:
 - subnet: 172.22.0.0/24
 monitoring:
 driver: bridge
 ipam:
 config:
 - subnet: 172.23.0.0/24
```

**Service Mapping:**

```yaml
# Frontend (public-facing)
- nginx: [frontend]
- cloudflared: [frontend]

# AI Layer
- openwebui: [frontend, backend]
- litellm: [backend]
- ollama: [backend]

# Data Layer
- postgres: [data]
- redis: [data]
- backrest: [data]

# Monitoring
- prometheus: [monitoring, backend]
- grafana: [monitoring]
- exporters: [monitoring, backend/data]
```

**Completion Criteria:**

- [ ] 4 networks created
- [ ] All services assigned
- [ ] internal: true for backend/data
- [ ] Connectivity testing

---

### Task 2.2: Modularize compose.yml (P1)

**Priority:**P1 - HIGH**Timeline:**2 weeks**Responsible:**DevOps Engineer
**Status:**TO DO

**Goal:**Split 1276-line monolith

**Structure:**

```
compose/
 base.yml # Networks, volumes, logging anchors
 ai-services.yml # OpenWebUI, Ollama, LiteLLM, Docling
 data-services.yml # PostgreSQL, Redis, Backrest
 monitoring.yml # Prometheus, Grafana, Loki, exporters
 infrastructure.yml # Nginx, Cloudflared, Auth, Watchtower
 production.yml # Production overrides
```

**Migration:**

```bash
# Create directory
mkdir compose

# Split file
# 1. base.yml - first 50 lines + x-logging
# 2. ai-services.yml - openwebui, ollama, litellm, docling
# ...

# Test
docker compose -f compose/base.yml \
 -f compose/ai-services.yml \
 -f compose/data-services.yml \
 -f compose/monitoring.yml \
 -f compose/infrastructure.yml \
 -f compose/production.yml \
 config > test-compose.yml

# Compare with original
diff <(yq eval-all 'sort_keys(..)' compose.yml) \
 <(yq eval-all 'sort_keys(..)' test-compose.yml)
```

**Completion Criteria:**

- [ ] 6 modules created
- [ ] `docker compose config` works
- [ ] No differences from original
- [ ] README updated

---

### Task 2.3: Integration Tests (P2)

**Priority:**P2 - MEDIUM**Timeline:**2 weeks**Responsible:**QA Engineer
**Status:**TO DO

**Goal:**Cover critical integration flows

**Test cases:**

1.**OpenWebUI → LiteLLM → Ollama flow**

```typescript
// tests/integration/ai-pipeline.test.ts
describe('AI Pipeline Integration', () => {
  it('should handle chat request end-to-end', async () => {
    const response = await fetch('http://openwebui:8080/api/chat', {
      method: 'POST',
      body: JSON.stringify({
        model: 'llama3',
        messages: [{ role: 'user', content: 'test' }],
      }),
    });
    expect(response.ok).toBe(true);
    expect(await response.json()).toMatchObject({
      message: { content: expect.any(String) },
    });
  });
});
```

2.**Auth service JWT validation**3.**Prometheus scraping all targets**4.**Fluent
Bit → Loki log ingestion**

**Completion Criteria:**

- [ ] 10+ integration tests
- [ ] CI pipeline integration
- [ ] Coverage report

---

## Phase 3: Medium Priority (1 month)

### Task 3.1: SOPS for Secrets (P2) {: #task-31-sops-for-secrets-p2 }

**Priority:**P2 - MEDIUM**Timeline:**1 month**Responsible:**DevOps Lead
**Status:**TO DO

**Goal:**Encryption of secrets at rest

**Implementation:**

1.**Install SOPS**

```bash
brew install sops # or apt-get install sops
```

2.**Create GPG key for team**

```bash
gpg --batch --generate-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: ERNI-KI DevOps
Name-Email: devops@erni-gruppe.ch
Expire-Date: 2y
EOF

# Export public key
gpg --export --armor "ERNI-KI DevOps" > .sops.pub
```

3.**Configure SOPS**

```yaml
# .sops.yaml
creation_rules:
 - path_regex: secrets/.*\.txt$
 pgp: >-
 FBC7B9E2A4F9289AC0C1D4843D16CEE4A27381B4
```

4.**Encrypt secrets**

```bash
for file in secrets/*.txt; do
 sops -e "$file" > "$file.enc"
 rm "$file"
done

git add secrets/*.enc
git commit -m "security: encrypt secrets with SOPS"
```

5.**Entrypoint wrapper**

```bash
# !/usr/bin/env bash
# scripts/entrypoints/sops-wrapper.sh
for secret_file in /run/secrets-encrypted/*; do
 secret_name=$(basename "$secret_file" .enc)
 sops -d "$secret_file" > "/run/secrets/$secret_name"
done

exec "$@"
```

**Completion Criteria:**

- [ ] SOPS configured
- [ ] All secrets encrypted
- [ ] Entrypoint working
- [ ] Documentation updated

---

### Task 3.2: JWT Rotation (P2)

**Priority:**P2 - MEDIUM**Timeline:**1 month**Responsible:**Backend
Developer**Status:**TO DO

**Goal:**Automatic JWT signing key rotation

**Design:**

```go
// pkg/jwt/rotation.go
type KeyRotator struct {
 current []byte
 previous []byte
 next []byte
 mutex sync.RWMutex
}

func (r *KeyRotator) Rotate() error {
 r.mutex.Lock()
 defer r.mutex.Unlock()

 r.previous = r.current
 r.current = r.next
 r.next = generateSecureKey()

 return r.persistKeys()
}

func (r *KeyRotator) Verify(token string) (Claims, error) {
 // Try verification with current key
 claims, err := jwt.Parse(token, r.current)
 if err == nil {
 return claims, nil
 }

 // Fallback to previous key
 return jwt.Parse(token, r.previous)
}
```

**Completion Criteria:**

- [ ] KeyRotator implemented
- [ ] Rotation every 7 days
- [ ] Support for 2 valid keys
- [ ] Unit tests
- [ ] Documentation

---

### Task 3.3: Load Tests (P2)

**Priority:**P2 - MEDIUM**Timeline:**1 month**Responsible:**QA Engineer
**Status:**TO DO

**Goal:**Determine capacity and bottlenecks

**Scenarios:**

1.**Chat completions load**

```javascript
// tests/load/chat.k6.js
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 }, // Warm-up
    { duration: '5m', target: 50 }, // Load
    { duration: '2m', target: 100 }, // Stress
    { duration: '5m', target: 0 }, // Cool-down
  ],
  thresholds: {
    http_req_duration: ['p(99)<2000'], // 99% < 2s
    http_req_failed: ['rate<0.01'], // Error rate < 1%
  },
};

export default function () {
  const res = http.post(
    'https://ki.erni-gruppe.ch/api/chat',
    JSON.stringify({
      model: 'llama3',
      messages: [{ role: 'user', content: 'Hello' }],
    }),
    {
      headers: { 'Content-Type': 'application/json' },
    },
  );

  check(res, {
    'status is 200': r => r.status === 200,
    'response time < 2s': r => r.timings.duration < 2000,
  });
}
```

2.**RAG pipeline load**3.**Prometheus query load**

**Completion Criteria:**

- [ ] 3 k6 scenarios
- [ ] Baseline metrics collected
- [ ] Bottlenecks identified
- [ ] Performance report

---

## Phase 4: Long-term (3-6 months)

### Task 4.1: SLI/SLO Definition (P3)

**Priority:**P3 - LOW**Timeline:**1 month**Responsible:**SRE**Status:**BACKLOG

**Goal:**Formalize service level objectives

**SLI Definition:**

```yaml
# docs/operations/sli-slo.yml
slos:
 - name: API Availability
 sli: ratio of successful requests to total requests
 formula:
 (count(http_requests_total{code=~"2.."}) / count(http_requests_total)) *
 100
 target: 99.9%
 window: 30d
 error_budget: 43m per month

 - name: API Latency
 sli: p99 response time
 formula: histogram_quantile(0.99, http_request_duration_seconds_bucket)
 target: <1000ms
 window: 30d

 - name: Error Rate
 sli: ratio of 5xx responses
 formula:
 (sum(rate(http_requests_total{code=~"5.."}[5m])) /
 sum(rate(http_requests_total[5m]))) * 100
 target: <0.1%
 window: 30d
```

**Completion Criteria:**

- [ ] SLI defined for all critical services
- [ ] Prometheus rules created
- [ ] Grafana dashboard
- [ ] Runbooks

---

### Task 4.2: Kubernetes Migration (P4)

**Priority:**P4 - BACKLOG**Timeline:**6 months**Responsible:**DevOps Lead
**Status:**BACKLOG

**Goal:**Migration from Docker Compose to Kubernetes

**Benefits:**

- Network Policies for isolation
- HPA for autoscaling
- Rolling updates with zero downtime
- External Secrets Operator
- Service mesh (Istio)

**Phases:**

1.**Proof of Concept (1 month)**2.**Helm charts development (2
months)**3.**Staging migration (1 month)**4.**Production migration (2 months)**

**Completion Criteria:**

- [ ] POC successful
- [ ] Helm charts ready
- [ ] Staging working
- [ ] Production migrated

---

## Tracking

### Overall Progress

- Phase 1: 0/4 (0%)
- Phase 2: 0/3 (0%)
- Phase 3: 0/3 (0%)
- Phase 4: 0/2 (0%)

**TOTAL: 0/12 (0%)**

### Milestones

- [ ]**Milestone 1:**Critical fixes (Week 1)
- [ ]**Milestone 2:**Production unblocked (Week 2)
- [ ]**Milestone 3:**Network segmentation (Week 4)
- [ ]**Milestone 4:**SOPS + JWT rotation (Month 2)
- [ ]**Milestone 5:**Load tests + SLI/SLO (Month 3)

---

## Responsibilities

| Role              | Name | Tasks              |
| ----------------- | ---- | ------------------ |
| DevOps Lead       | TBD  | 1.1, 2.1, 3.1      |
| DevOps Engineer   | TBD  | 1.2, 1.3, 1.4, 2.2 |
| Backend Developer | TBD  | 3.2                |
| QA Engineer       | TBD  | 2.3, 3.3           |
| SRE               | TBD  | 4.1                |

---

## Communication

### Weekly Status Updates

- Every Monday at 10:00
- Slack: #erni-ki-security
- Format: Task ID, Status, Blockers

### Escalation Path

- P0 issues: Immediately to Slack + email DevOps Lead
- P1 issues: Daily standup
- P2+ issues: Weekly status update

---

## Links

- ERNI-KI Comprehensive Analysis 2025-12-02 (archived)
- [Security Policy](../security/security-policy.md)
- [Runbooks](core/runbooks-summary.md)

---

**Status:**ACTIVE**Next review:**2025-12-04
