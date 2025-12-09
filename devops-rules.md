# devops-rules.md

This file provides DevOps guidance for the erni-ki AI Platform when working with
infrastructure, CI/CD, and containerized services.

## Beta Development Guidelines

**Local-only deployment** - each user runs their own instance of the AI
platform.

### Core Principles

- **No backwards compatibility; we follow a fix-forward approach** — remove
  deprecated code immediately
- **Detailed errors over graceful failures** - we want to identify and fix
  issues fast
- **Break things to improve them** - beta is for rapid iteration
- **Continuous improvement** - embrace change and learn from mistakes
- **KISS** - keep it simple
- **DRY** when appropriate
- **YAGNI** — don't implement features that are not needed

### Error Handling

**Core Principle**: In beta, we need to intelligently decide when to fail hard
and fast to quickly address issues, and when to allow processes to complete in
critical services despite failures.

#### When to Fail Fast and Loud (Let it Crash!)

These errors should stop execution and bubble up immediately:

- **Service startup failures** - If credentials, database, or any service can't
  initialize, the system should crash with a clear error
- **Missing configuration** - Missing environment variables or invalid settings
  should stop the system
- **Database connection failures** - Don't hide connection issues, expose them
- **Authentication/authorization failures** - Security errors must be visible
  and halt the operation
- **Data corruption or validation errors** - Never silently accept bad data
- **Critical dependencies unavailable** - If a required service is down, fail
  immediately
- **Invalid data that would corrupt state** - Never store corrupted data

#### When to Complete but Log Detailed Errors

These operations should continue but track and report failures clearly:

- **Batch processing** - When processing documents or crawling, complete what
  you can and report detailed failures for each item
- **Background tasks** - Async jobs should finish the queue but log failures
- **Optional features** - If optional services are disabled, log and skip rather
  than crash
- **External API calls** - Retry with exponential backoff, then fail with a
  clear message

#### Error Message Guidelines

- Include context about what was being attempted when the error occurred
- Preserve full stack traces with `exc_info=True` in Python logging
- Use specific exception types, not generic Exception catching
- Include relevant IDs, URLs, or data that helps debug the issue
- Never return None/null to indicate failure - raise an exception with details

---

## Docker Compose Architecture

### 5-Layer Modular Design

| Layer          | File                     | Services                                                               |
| -------------- | ------------------------ | ---------------------------------------------------------------------- |
| **base**       | `compose/base.yml`       | Networks, logging anchors, watchtower                                  |
| **data**       | `compose/data.yml`       | PostgreSQL 17 + pgvector, Redis 7.0.15                                 |
| **ai**         | `compose/ai.yml`         | Ollama, LiteLLM, OpenWebUI, Docling, Auth, SearXNG, EdgeTTS, Tika, MCP |
| **gateway**    | `compose/gateway.yml`    | Nginx, Cloudflared, Backrest                                           |
| **monitoring** | `compose/monitoring.yml` | Prometheus, Grafana, Loki, Alertmanager, Uptime-Kuma, exporters        |

### Network Segmentation (4-tier)

| Network        | Purpose                           | Services                               |
| -------------- | --------------------------------- | -------------------------------------- |
| **frontend**   | Public-facing                     | Nginx, Cloudflared                     |
| **backend**    | Application logic                 | OpenWebUI, LiteLLM, Auth, API services |
| **data**       | Stateful services (internal only) | PostgreSQL, Redis                      |
| **monitoring** | Observability stack               | Prometheus, Grafana, Loki, exporters   |

### Logging Strategy (4-tier)

| Tier           | Services                  | Retention       |
| -------------- | ------------------------- | --------------- |
| **Critical**   | PostgreSQL, Nginx         | 50MB x 10 files |
| **Important**  | Redis, LiteLLM, Auth      | 10MB x 5 files  |
| **Auxiliary**  | SearXNG, EdgeTTS, Docling | 10MB x 5 files  |
| **Monitoring** | Prometheus, Grafana       | 10MB x 5 files  |

### Commands

```bash
# Start all services
./docker-compose.sh up -d

# Check service status
./docker-compose.sh ps

# View logs (specific service)
./docker-compose.sh logs -f nginx
./docker-compose.sh logs -f litellm

# Restart a service
./docker-compose.sh restart nginx

# Stop all services
./docker-compose.sh down

# Stop and remove volumes (destructive!)
./docker-compose.sh down -v

# Validate compose configuration
docker compose config --quiet
```

### Quick Start

```bash
# 1. Create environment files from examples
for f in env/*.example; do cp "$f" "${f%.example}.env"; done

# 2. (Optional) Download Docling models
./scripts/maintenance/download-docling-models.sh

# 3. Start services
./docker-compose.sh up -d

# 4. Verify health
./docker-compose.sh ps
```

---

## CI/CD Pipeline (GitHub Actions)

### Workflows Overview (15 total)

| Workflow                  | Trigger            | Purpose                                           |
| ------------------------- | ------------------ | ------------------------------------------------- |
| `ci.yml`                  | Push, PR           | Main CI pipeline (lint → test → security → build) |
| `security.yml`            | Push, PR, Schedule | Security scanning (CodeQL, Trivy, Bandit)         |
| `release.yml`             | Manual, Tags       | Semantic versioning and releases                  |
| `docs-deploy.yml`         | Push to main       | MkDocs deployment to GitHub Pages                 |
| `nightly-audit.yml`       | Schedule (daily)   | Security audits                                   |
| `deploy-environments.yml` | Push, Manual       | Environment-specific deployments                  |
| `archon-rag-ingest.yml`   | Manual             | RAG knowledge base ingestion                      |
| `archon-ci.yml`           | PR                 | Archon MCP integration checks                     |

### Pipeline Stages

```text
┌─────────────────────────────────────────────────────────────────┐
│                        CI Pipeline                               │
├─────────┬─────────┬─────────┬─────────┬─────────┬──────────────┤
│  Lint   │  Test   │ Security│  Build  │  Deploy │ Notification │
│         │         │         │         │         │              │
│ • Pre-  │ • Go    │ • CodeQL│ • Multi-│ • Env-  │ • Summary    │
│   commit│   (80%) │ • Trivy │   plat- │   spec- │ • Codecov    │
│ • Pret- │ • Python│ • Bandit│   form  │   ific  │              │
│   tier  │   (341) │ • Git-  │   Docker│         │              │
│ • Ruff  │ • TS/JS │   leaks │         │         │              │
│ • Edit- │ • E2E   │         │         │         │              │
│   orCfg │ • k6    │         │         │         │              │
└─────────┴─────────┴─────────┴─────────┴─────────┴──────────────┘
```

### Required Checks Before Merge

- All linting passes (ESLint, Ruff, Prettier, Yamllint)
- All tests pass (Go + Python + TS)
- Security scans clean (no critical/high vulnerabilities)
- Pre-commit hooks satisfied
- Documentation builds successfully

### Running CI Locally

```bash
# Run all pre-commit checks
pre-commit run --all-files

# Fast checks only (~2s)
pre-commit run --config .pre-commit/config-fast.yaml --all-files

# Full checks
pre-commit run --config .pre-commit/config-full.yaml --all-files

# Security checks only
pre-commit run --config .pre-commit/config-security.yaml --all-files
```

---

## Security Tools

### SAST (Static Analysis)

| Tool       | Target         | What it checks                        |
| ---------- | -------------- | ------------------------------------- |
| **CodeQL** | Go, JS, Python | Code vulnerabilities, injection flaws |
| **Bandit** | Python         | Security issues (B-codes)             |
| **Gosec**  | Go             | Security vulnerabilities              |
| **Ruff S** | Python         | Security rules subset                 |

### Container & Dependency Scanning

| Tool            | Target                     | Integration    |
| --------------- | -------------------------- | -------------- |
| **Trivy**       | Filesystem + Docker images | CI + pre-build |
| **Grype**       | Vulnerability database     | CI pipeline    |
| **govulncheck** | Go dependencies            | Go test stage  |
| **bun audit**   | npm dependencies           | Lint stage     |

### Secret Detection

| Tool               | Purpose              | When            |
| ------------------ | -------------------- | --------------- |
| **Gitleaks**       | Git history scanning | Pre-commit + CI |
| **TruffleHog**     | Secret patterns      | CI pipeline     |
| **Detect-Secrets** | Baseline validation  | Pre-commit      |

### DAST (Dynamic Analysis)

| Tool       | When               | Target                  |
| ---------- | ------------------ | ----------------------- |
| **ZAP**    | Scheduled / manual | Running services        |
| **Nuclei** | Scheduled / manual | Vulnerability templates |

### IaC Security

| Tool        | What it checks                               |
| ----------- | -------------------------------------------- |
| **Checkov** | Dockerfile, GitHub Actions, secrets, Compose |

### Running Security Scans Locally

```bash
# Trivy filesystem scan
trivy fs --severity HIGH,CRITICAL .

# Gitleaks scan
gitleaks detect --source . --verbose

# Detect-secrets baseline
detect-secrets scan --baseline .secrets.baseline

# Bandit Python scan
bandit -r scripts/ -ll

# Go security scan
cd auth && gosec ./...
```

---

## Pre-Commit Hooks

### Configuration Profiles

| Profile      | File                               | Use Case          |
| ------------ | ---------------------------------- | ----------------- |
| **Default**  | `.pre-commit-config.yaml`          | Production (full) |
| **Fast**     | `.pre-commit/config-fast.yaml`     | Local dev (<2s)   |
| **Full**     | `.pre-commit/config-full.yaml`     | Comprehensive     |
| **Security** | `.pre-commit/config-security.yaml` | Security focus    |
| **Docs**     | `.pre-commit/config-docs.yaml`     | Documentation     |

### Enabled Hooks

**File Validation:**

- Trailing whitespace, end-of-file fixing
- Large files check (>500KB)
- YAML, JSON, TOML validation
- Merge/case conflicts detection

**Linting & Formatting:**

- Yamllint (v1.35.1)
- Prettier (v3.6.2) - MD, YAML, JSON, JS/TS
- Ruff (v0.14.7) - Python lint + format
- Mypy (v1.13.0) - Python type checking
- ESLint (v9.14.0) - JS/TS
- Shellcheck (v0.9.0) - Bash scripts

**Security:**

- Gitleaks (v8.29.1) - Secret detection
- Detect-Secrets (v1.5.0) - Baseline validation

**Custom Hooks:**

- Docker Compose validation
- Go formatting (gofmt, goimports)
- Markdownlint
- Emoji validation (no emoji policy)
- Pytest integration

### Hook Commands

```bash
# Install hooks
pre-commit install

# Run all hooks
pre-commit run --all-files

# Run specific hook
pre-commit run ruff --all-files

# Update hook versions
pre-commit autoupdate

# Skip hooks (emergency only!)
git commit --no-verify -m "message"
```

---

## Testing Frameworks

| Language     | Framework  | Command                                    | Coverage Target |
| ------------ | ---------- | ------------------------------------------ | --------------- |
| **Python**   | Pytest     | `.venv/bin/python -m pytest tests/python/` | 341 tests       |
| **Go**       | Go test    | `cd auth && go test ./... -race`           | 80%             |
| **TS/JS**    | Vitest     | `bun run test:unit`                        | -               |
| **E2E**      | Playwright | `bun run test:e2e:mock`                    | -               |
| **Load**     | k6         | `bun run test:load`                        | -               |
| **Contract** | Custom     | Requires `CONTRACT_BASE_URL`               | -               |

### Running Tests

```bash
# Python tests
source .venv/bin/activate
python -m pytest tests/python/ -v

# Go tests with coverage
cd auth && go test ./... -race -cover

# TypeScript unit tests
bun run test:unit

# E2E tests (mock mode)
bun run test:e2e:mock

# All tests
bun test
```

---

## Linting & Formatting

| Tool              | Version | Language | Purpose          | Command                          |
| ----------------- | ------- | -------- | ---------------- | -------------------------------- |
| **Ruff**          | v0.14.7 | Python   | Lint + format    | `ruff check .` / `ruff format .` |
| **Mypy**          | v1.13.0 | Python   | Type checking    | `mypy src/`                      |
| **ESLint**        | v9.14.0 | JS/TS    | Code linting     | `eslint .`                       |
| **Prettier**      | v3.6.2  | Multi    | Formatting       | `prettier --check .`             |
| **Shellcheck**    | v0.9.0  | Bash     | Shell validation | `shellcheck scripts/*.sh`        |
| **Yamllint**      | v1.35.1 | YAML     | YAML validation  | `yamllint .`                     |
| **Golangci-lint** | v1.64.5 | Go       | Go linting       | `golangci-lint run`              |
| **Markdownlint**  | v0.19.1 | Markdown | MD validation    | `markdownlint docs/`             |

### Quick Lint Commands

```bash
# Python
ruff check . --fix
ruff format .
mypy src/

# JavaScript/TypeScript
bun run lint
bun run format

# All languages
pre-commit run --all-files
```

---

## Monitoring Stack

### Components

| Service          | Version | Purpose            | Port |
| ---------------- | ------- | ------------------ | ---- |
| **Prometheus**   | v3.0.0  | Metrics collection | 9090 |
| **Grafana**      | v11.3.0 | Dashboards         | 3000 |
| **Loki**         | v3.0.0  | Log aggregation    | 3100 |
| **Alertmanager** | v0.27.0 | Alert routing      | 9093 |
| **Promtail**     | v3.0.0  | Log shipping       | -    |
| **Fluent Bit**   | v3.1.0  | Log collection     | -    |
| **Uptime Kuma**  | latest  | Uptime monitoring  | 3001 |

### Exporters

| Exporter            | Metrics                            |
| ------------------- | ---------------------------------- |
| Node Exporter       | System metrics (CPU, memory, disk) |
| PostgreSQL Exporter | Database metrics                   |
| Nginx Exporter      | Request metrics, connections       |
| Redis Exporter      | Cache metrics                      |
| Ollama Exporter     | LLM metrics                        |
| RAG Exporter        | RAG pipeline metrics               |

### Dashboards (Auto-provisioned)

- Infrastructure Overview
- PostgreSQL Performance
- Nginx Traffic
- LiteLLM/Ollama Metrics
- Container Health

### Accessing Monitoring

```bash
# Prometheus (metrics)
http://localhost:9090

# Grafana (dashboards)
http://localhost:3000

# Alertmanager (alerts)
http://localhost:9093

# Uptime Kuma
http://localhost:3001
```

---

## Environment Configuration

### Environment Files

```text
env/
├── db.env.example         # PostgreSQL configuration
├── redis.env.example      # Redis configuration
├── litellm.env.example    # LiteLLM API keys
├── openwebui.env.example  # OpenWebUI settings
├── auth.env.example       # JWT auth configuration
├── cloudflare.env.example # Cloudflare tunnel
└── ...
```

### Secrets Directory

```text
secrets/
├── db_password            # PostgreSQL password
├── redis_password         # Redis password
├── jwt_secret             # JWT signing key
├── litellm_master_key     # LiteLLM API key
└── ...
```

### Service Configurations

```text
conf/
├── nginx/                 # Reverse proxy config
├── prometheus/            # Metrics rules & targets
├── grafana/               # Dashboards & provisioning
├── loki/                  # Log aggregation config
├── alertmanager/          # Alert routing
├── postgres-enhanced/     # PostgreSQL tuning
├── redis/                 # Redis config
└── ...
```

---

## Common DevOps Tasks

### Adding a New Docker Service

1. Add service definition to appropriate compose file (`compose/ai.yml`, etc.)
2. Create configuration in `conf/<service>/`
3. Add environment template in `env/<service>.env.example`
4. Update network assignments as needed
5. Add health check to service definition
6. Update monitoring (Prometheus targets, Grafana dashboard)
7. Document in `compose/README.md`

### Modifying CI/CD Workflows

1. Edit workflow in `.github/workflows/`
2. Test locally with `act` or push to branch
3. Verify all jobs pass
4. Update documentation if adding new checks

### Adding Pre-Commit Hooks

1. Add hook to `.pre-commit-config.yaml`
2. Run `pre-commit autoupdate`
3. Test with `pre-commit run --all-files`
4. Add to appropriate profile(s) if needed

### Managing Secrets

```bash
# Generate new secret
openssl rand -base64 32 > secrets/new_secret

# Update Docker secret
docker secret rm old_secret
docker secret create new_secret secrets/new_secret

# Rotate secrets (restart required)
./docker-compose.sh down
./docker-compose.sh up -d
```

### Backup & Restore

```bash
# Backrest (configured in compose/gateway.yml)
# See: conf/backrest/ for backup schedules and retention policies
docker exec backrest backrest backup     # Manual backup
docker exec backrest backrest list       # List backups

# PostgreSQL direct backup (if needed)
docker exec -it compose-db-1 pg_dump -U postgres openwebui > backup.sql
docker exec -i compose-db-1 psql -U postgres openwebui < backup.sql
```

### Troubleshooting

```bash
# Check service health
./docker-compose.sh ps

# View logs
./docker-compose.sh logs -f <service>

# Check resource usage
docker stats

# Inspect container
docker inspect <container_name>

# Enter container shell
docker exec -it <container_name> /bin/sh

# Validate compose config
docker compose config --quiet
```

---

## Important Notes

- **30+ containerized services** - full AI platform stack
- **Modular compose** - 5-layer architecture for flexibility
- **4-tier networking** - security through segmentation
- **Multi-platform builds** - Linux AMD64 & ARM64 support
- **Distroless containers** - security-hardened auth service
- **Semantic versioning** - conventional commits auto-versioning
- **i18n documentation** - English, German, Russian support
- **AI-friendly docs** - llms.txt generation for LLM consumption

See also:

- `compose/README.md` - Compose architecture details
- `docs/operations/` - Operational runbooks
- `docs/security/` - Security policies
- `docs/architecture/` - System design diagrams
