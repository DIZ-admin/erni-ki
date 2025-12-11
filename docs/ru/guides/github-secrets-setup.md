---
title: GitHub Secrets Configuration Guide
language: ru
page_id: github-secrets-setup
doc_version: '2025.11'
translation_status: complete
last_updated: '2025-12-07'
---

# GitHub Secrets Configuration Guide

**Version**: 1.1 **Last Updated**: 2025-12-07 **Status**: Active

## Overview

This guide documents all GitHub Secrets required for CI workflows in the ERNI-KI
project. Secrets are used for code coverage reporting, contract testing, and
smoke testing.

## Required Secrets

### 1. Code Coverage

#### `CODECOV_TOKEN`

**Purpose**: Upload test coverage reports to Codecov.io

**Used by**:

- `test-go` job (Go coverage)
- `test-bun` job (TypeScript/JavaScript coverage)
- `test-python` job (Python coverage)

**How to get**:

1. Go to [codecov.io](https://codecov.io/)
2. Link your GitHub repository
3. Navigate to Settings → Repository Upload Token
4. Copy the token

**Required on branches**: All branches (optional on feature branches, required
on main/develop)

**Format**: UUID string (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

**Setup path**: Repository Settings → Secrets and variables → Actions → New
repository secret

---

### 2. Contract Testing

#### `CONTRACT_BASE_URL`

**Purpose**: Base URL for contract testing API endpoint

**Used by**: `test-contracts` job

**Example value**: `https://api.staging.example.com` or `http://localhost:3000`

**Required on branches**:

- **main/develop**: REQUIRED (CI will fail if missing)
- **Feature branches**: Optional (tests skipped if not set)

#### `CONTRACT_BEARER_TOKEN`

**Purpose**: Bearer token for authenticated contract testing

**Used by**: `test-contracts` job

**Example value**: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**Required on branches**:

- **main/develop**: REQUIRED (CI will fail if missing)
- **Feature branches**: Optional (tests skipped if not set)

**Security note**: Use a dedicated testing token with minimal permissions

---

### 3. Load/Smoke Testing (k6)

#### `SMOKE_BASE_URL`

**Purpose**: Base URL for k6 smoke tests

**Used by**: `load-smoke` job

**Example value**: `https://api.staging.example.com`

**Required on branches**:

- **main/develop**: REQUIRED (CI will fail if missing)
- **Feature branches**: Optional (tests skipped if not set)

#### `SMOKE_AUTH_TOKEN`

**Purpose**: Authentication token for smoke tests

**Used by**: `load-smoke` job

**Example value**: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**Required**: Optional (depends on API authentication requirements)

#### `SMOKE_AUTH_PATH`

**Purpose**: API path for authentication endpoint

**Used by**: `load-smoke` job

**Example value**: `/api/v1/auth/login` or `/auth/token`

**Required**: Optional (depends on test scenario)

#### `SMOKE_RAG_PATH`

**Purpose**: API path for RAG (Retrieval-Augmented Generation) endpoint testing

**Used by**: `load-smoke` job

**Example value**: `/api/v1/rag/query` or `/search`

**Required**: Optional (depends on test scenario)

#### `SMOKE_VUS`

**Purpose**: Number of virtual users for k6 load testing

**Used by**: `load-smoke` job

**Example value**: `10` (integer)

**Default**: If not set, k6 script default is used

**Recommended values**:

- Smoke test: `1-5`
- Light load: `10-50`
- Medium load: `100-500`

#### `SMOKE_DURATION`

**Purpose**: Duration of k6 smoke test

**Used by**: `load-smoke` job

**Example value**: `30s`, `1m`, `5m`

**Default**: If not set, k6 script default is used

**Recommended values**:

- Quick smoke: `30s`
- Standard smoke: `1m`
- Extended smoke: `5m`

---

### 4. Archon API (RAG ingest, MCP integrations)

#### `ARCHON_API_URL`

**Purpose**: Base URL for Archon API used by RAG ingest workflow and MCP
integrations

**Example value**: `http://localhost:8181` (local) or
`https://archon.internal:8181` (prod)

**Required**: Yes (for archon-rag-ingest workflow)

#### `ARCHON_API_KEY`

**Purpose**: API key generated in Archon UI (Settings → API Key)

**Required**: Yes (for archon-rag-ingest workflow)

**Security note**: Keep this secret; do not pass via workflow inputs.

---

## Setup Instructions

### Option 1: Repository-Level Secrets (Recommended)

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the name and value from the table below

### Option 2: Environment-Level Secrets

For different values per environment (staging, production):

1. Navigate to your GitHub repository
2. Go to **Settings** → **Environments**
3. Create environments: `staging`, `production`
4. For each environment:
   - Click **Add secret**
   - Add secrets with different values per environment

### Option 3: Organization-Level Secrets

For secrets shared across multiple repositories:

1. Navigate to your GitHub organization
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New organization secret**
4. Select which repositories can access the secret

---

## Secrets Summary Table

| Secret Name             | Category | Required on main/develop | Format      | Example Value                 |
| ----------------------- | -------- | ------------------------ | ----------- | ----------------------------- |
| `CODECOV_TOKEN`         | Coverage | Optional\*               | UUID        | `a1b2c3d4-...`                |
| `CONTRACT_BASE_URL`     | Contract | **Required**             | URL         | `https://api.staging.example` |
| `CONTRACT_BEARER_TOKEN` | Contract | **Required**             | Bearer JWT  | `Bearer eyJhbG...`            |
| `SMOKE_BASE_URL`        | Smoke    | **Required**             | URL         | `https://api.staging.example` |
| `ARCHON_API_URL`        | Archon   | **Required**             | URL         | `http://localhost:8181`       |
| `ARCHON_API_KEY`        | Archon   | **Required**             | Token       | `sk-archon-api-key`           |
| `SMOKE_AUTH_TOKEN`      | Smoke    | Optional                 | Bearer JWT  | `Bearer eyJhbG...`            |
| `SMOKE_AUTH_PATH`       | Smoke    | Optional                 | API Path    | `/api/v1/auth/login`          |
| `SMOKE_RAG_PATH`        | Smoke    | Optional                 | API Path    | `/api/v1/rag/query`           |
| `SMOKE_VUS`             | Smoke    | Optional                 | Integer     | `10`                          |
| `SMOKE_DURATION`        | Smoke    | Optional                 | Time string | `1m`                          |

\* CODECOV_TOKEN: Optional for public repositories if Codecov integration is
configured

---

## CI Behavior Without Secrets

### Code Coverage (CODECOV_TOKEN missing)

- **Behavior**: Coverage upload step will fail silently or be skipped
- **Impact**: Coverage reports won't appear in Codecov.io
- **Solution**: Add CODECOV_TOKEN or disable codecov upload steps

### Contract Testing (CONTRACT_BASE_URL/TOKEN missing)

- **main/develop branches**: CI will **FAIL** with error message
- **Feature branches**: Tests are **SKIPPED** with informational message
- **Workaround**: Set at least CONTRACT_BASE_URL to enable tests

### Smoke Testing (SMOKE_BASE_URL missing)

- **main/develop branches**: CI will **FAIL** with error message
- **Feature branches**: Tests are **SKIPPED** with informational message
- **Workaround**: Set at least SMOKE_BASE_URL to enable tests

---

## Security Best Practices

### Token Generation

1. **Use dedicated testing tokens**: Never use production credentials
2. **Minimal permissions**: Grant only necessary API access
3. **Token rotation**: Rotate tokens regularly (every 90 days)
4. **Expiration**: Set token expiration dates where possible

### Access Control

1. **Limit repository access**: Use organization secrets only when necessary
2. **Environment protection**: Use environment secrets for production
3. **Review access logs**: Regularly audit secret usage in Actions logs
4. **Branch protection**: Require approval for workflows on protected branches

### Token Storage

1. **Never commit secrets**: Use GitHub Secrets, never hardcode
2. **Mask in logs**: GitHub Actions automatically masks secret values
3. **Avoid echoing**: Don't use `echo $SECRET` in workflow scripts
4. **Use temporary tokens**: Prefer short-lived tokens when possible

---

## Troubleshooting

### "Context access might be invalid" Warning

**Symptom**: VS Code GitHub Actions extension shows warning

**Cause**: Secret is referenced in workflow but not defined in GitHub

**Solution**: Add the secret to GitHub Settings → Secrets

### CI Fails with "Secret not found"

**Symptom**: Workflow fails with error about missing secret

**Cause**: Secret name mismatch or not configured

**Solution**:

1. Verify secret name spelling (case-sensitive)
2. Check if secret is added at correct level (repo/org/environment)
3. Ensure workflow has access to environment secrets

### Coverage Upload Fails

**Symptom**: codecov/codecov-action step fails

**Cause**: CODECOV_TOKEN missing or invalid

**Solution**:

1. Get fresh token from codecov.io
2. Update GitHub secret
3. Re-run workflow

---

## Validation Checklist

Before pushing to main/develop, verify:

- [ ] `CODECOV_TOKEN` is set (if using Codecov)
- [ ] `CONTRACT_BASE_URL` points to valid staging API
- [ ] `CONTRACT_BEARER_TOKEN` is valid and not expired
- [ ] `SMOKE_BASE_URL` points to valid staging API
- [ ] All optional smoke testing secrets are set (if needed)
- [ ] Tokens have minimal required permissions
- [ ] Tokens are not production credentials

---

## Related Documentation

- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Codecov Documentation](https://docs.codecov.com/docs)
- [k6 Documentation](https://k6.io/docs/)

---

## Version History

| Version | Date       | Changes                     |
| ------- | ---------- | --------------------------- |
| 1.0     | 2025-12-06 | Initial secrets setup guide |

---

**Maintained by**: DevOps Team **Last Review**: 2025-12-06
