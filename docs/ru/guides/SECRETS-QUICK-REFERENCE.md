---
title: GitHub Secrets Quick Reference
language: ru
page_id: secrets-quick-ref
doc_version: '2025.11'
translation_status: complete
last_updated: '2025-12-06'
---

# GitHub Secrets Quick Reference

**Quick setup guide for GitHub Actions secrets in ERNI-KI project**

## Quick Setup (CLI)

```bash
# Install GitHub CLI
brew install gh  # macOS
# or visit https://cli.github.com/

# Authenticate
gh auth login

# Run interactive setup
./scripts/setup-github-secrets.sh
```

## Manual Setup (Web UI)

1. Go to: `https://github.com/YOUR_ORG/erni-ki/settings/secrets/actions`
2. Click "New repository secret"
3. Add secrets from the table below

## Required Secrets (main/develop)

| Secret Name             | Example Value                 | Get From                |
| ----------------------- | ----------------------------- | ----------------------- |
| `CONTRACT_BASE_URL`     | `https://api.staging.example` | Your staging API URL    |
| `CONTRACT_BEARER_TOKEN` | `Bearer eyJhbG...`            | Generate test JWT token |
| `SMOKE_BASE_URL`        | `https://api.staging.example` | Your staging API URL    |

## Optional Secrets

| Secret Name        | Example Value        | Default if Missing      |
| ------------------ | -------------------- | ----------------------- |
| `CODECOV_TOKEN`    | `a1b2c3d4-...`       | Coverage upload skipped |
| `SMOKE_AUTH_TOKEN` | `Bearer eyJhbG...`   | No auth used            |
| `SMOKE_AUTH_PATH`  | `/api/v1/auth/login` | Script default          |
| `SMOKE_RAG_PATH`   | `/api/v1/rag/query`  | Script default          |
| `SMOKE_VUS`        | `10`                 | Script default (5)      |
| `SMOKE_DURATION`   | `1m`                 | Script default (30s)    |

## One-Liner Setup (gh CLI)

```bash
# Required secrets
gh secret set CONTRACT_BASE_URL --body "https://api.staging.example.com"
gh secret set CONTRACT_BEARER_TOKEN --body "Bearer YOUR_TOKEN"
gh secret set SMOKE_BASE_URL --body "https://api.staging.example.com"

# Optional - Codecov
gh secret set CODECOV_TOKEN --body "YOUR_CODECOV_TOKEN"

# Optional - Smoke testing
gh secret set SMOKE_AUTH_TOKEN --body "Bearer YOUR_TOKEN"
gh secret set SMOKE_AUTH_PATH --body "/api/v1/auth/login"
gh secret set SMOKE_RAG_PATH --body "/api/v1/rag/query"
gh secret set SMOKE_VUS --body "10"
gh secret set SMOKE_DURATION --body "1m"

# Verify
gh secret list
```

## Testing Secrets

```bash
# Test on feature branch (secrets optional)
git checkout -b test/secrets-check
git push origin test/secrets-check

# Check CI logs for:
# - "CONTRACT_BASE_URL not set; skipping contract tests" (OK on feature branch)
# - "SMOKE_BASE_URL not set; skipping k6 smoke test" (OK on feature branch)
```

## Troubleshooting

### VS Code Warning: "Context access might be invalid"

**Fix**: Add the secret to GitHub (see Manual Setup above)

### CI Fails: "Secret required on main/develop"

**Fix**: Ensure required secrets are set before merging to main/develop

### Codecov Upload Fails

**Fix**: Get token from [codecov.io](https://codecov.io/) and add to GitHub

## Full Documentation

See [docs/guides/github-secrets-setup.md](./github-secrets-setup.md) for
detailed information.

---

**Last Updated**: 2025-12-06
