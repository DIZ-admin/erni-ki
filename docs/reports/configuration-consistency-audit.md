---
title: Configuration Consistency Audit Report
language: ru
page_id: config-consistency-audit-2025-12-06
doc_version: '2025.11'
translation_status: original
last_updated: '2025-12-06'
---

# Configuration Consistency Audit Report

**Date**: 2025-12-06 **Auditor**: Claude Code **Scope**: Tool versions and
configuration consistency across the project

**Note**: This audit was performed during Phase 2.2 (pytest infrastructure) and
Phase 2.6 (TODO management) work. Configuration inconsistencies were identified
and resolved as blocking issues for CI stability and security.

## Executive Summary

Found **1 CRITICAL SECURITY** issue, **2 critical** configuration issues
(FIXED), and **2 warning** level inconsistencies.

### CRITICAL - Security Update Required

1. **Go 1.24.0 Has 13 Vulnerabilities**: Updated to `1.24.11` to patch
   crypto/x509, net/http, syscall vulnerabilities (includes DNS constraint
   bypass, DoS, panics)

### Critical Issues (FIXED)

1. **Bun Matrix Version Conflict**: `1.2.2` < minimum `1.3.0` from package.json
   → FIXED
2. **Deprecated Tools in pyproject.toml**: Black and isort configured but Ruff
   is used → FIXED

### Warnings

1. **Python Version Matrix**: Testing 3.12 but project requires ^3.11
   (acceptable)
2. **Prettier Version Mismatch**: FIXED in commit 81a3b18

---

## Detailed Findings

### 1. Go Version - SECURITY UPDATE REQUIRED

**Issue**: Using Go 1.24.0, but security patches available in 1.24.11

**Locations**:

- `auth/go.mod:3` → `go 1.24.11` (now updated)
- `.github/workflows/security.yml:212` → `go-version: "1.24"` (uses latest
  1.24.x)
- Most CI jobs use `go-version-file: auth/go.mod` (auto-updated)

**Problem**: Go 1.24.0 has 13 known vulnerabilities in standard library
(crypto/x509, net/http, syscall). All fixed in patch releases up to 1.24.11.

**Critical Vulnerabilities**:

- GO-2025-4175: Improper DNS name constraints (crypto/x509) → Fixed in 1.24.11
- GO-2025-4155: Resource exhaustion in x509 error strings → Fixed in 1.24.11
- GO-2025-4013: Panic with DSA public keys → Fixed in 1.24.8
- GO-2025-4012: Cookie memory exhaustion → Fixed in 1.24.8
- And 9 more vulnerabilities (see govulncheck output)

**Impact**: CRITICAL - Production auth service vulnerable to multiple attacks

**Resolution Applied**:

```go
// auth/go.mod (updated to latest patch)
go 1.24.11
```

```bash
# Update dependencies
cd auth && go mod tidy
```

---

### 2. Bun Version Matrix Conflict - CRITICAL

**Issue**: Matrix testing with version below minimum requirement

**Locations**:

- `package.json:39` → `"bun": ">=1.3.0"`
- `.github/workflows/ci.yml:243` → `bun: ["1.3.3", "1.2.2"]`

**Problem**: Testing with Bun 1.2.2 violates minimum requirement of 1.3.0

**Impact**: False sense of compatibility with older Bun versions

**Recommendation**:

```yaml
matrix:
  bun: ['1.3.3', '1.3.0'] # Test minimum and current
```

---

### 3. Deprecated Linting Tools - FIXED

**Issue**: Black and isort configured but not used (Ruff is the active linter)

**Status**: **RESOLVED** - Black and isort sections removed, Ruff configured

**Previous Locations**:

- `pyproject.toml:13-21` → `[tool.black]` and `[tool.isort]` sections (REMOVED)
- `.pre-commit-config.yaml` → Using Ruff exclusively
- `requirements-dev.txt` → Only Ruff installed

**Resolution Applied**:

- Removed `[tool.black]` section from pyproject.toml
- Removed `[tool.isort]` section from pyproject.toml
- Added comprehensive `[tool.ruff]` configuration
- Ruff handles both linting and formatting (replaces Black + isort)

**Current Configuration** (pyproject.toml):

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "S", "C4", "SIM"]
# "I" = isort functionality built into Ruff

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

**Impact**: Simplified tooling, faster linting, consistent formatting

---

### 4. Python Version Matrix - WARNING

**Issue**: Testing Python 3.12 but project specifies 3.11

**Locations**:

- `pyproject.toml:7` → `python = "^3.11"`
- `.github/workflows/ci.yml:166` → `python: ["3.12", "3.11"]`

**Problem**: Testing unrequired Python version

**Impact**: Low - forward compatibility is good, but may mask 3.11-specific
issues

**Recommendation**: This is acceptable for forward compatibility testing.
Consider updating pyproject.toml to `python = "^3.11,<3.13"` to explicitly
support both.

---

### 5. Prettier Version - FIXED

**Issue**: Pre-commit used Prettier 4.0.0-alpha.8, script used 3.6.2

**Status**: **RESOLVED** in commit `81a3b18`

**Solution Applied**:

- Synchronized both to Prettier 3.6.2
- Removed duplicate .prettierrc
- Consolidated configuration in .prettierrc.json

---

## Configuration Summary

### Consistent Configurations

| Tool          | Version       | Locations                                 |
| ------------- | ------------- | ----------------------------------------- |
| **Python**    | 3.11          | CI (default), pyproject.toml              |
| **Go**        | 1.24.11       | auth/go.mod, security.yml (via go.mod)    |
| **Ruff**      | 0.14.6-0.14.7 | requirements-dev.txt, pre-commit          |
| **Prettier**  | 3.6.2         | pre-commit, prettier-run.sh, package.json |
| **Bun**       | 1.3.3         | CI (default), workflows                   |
| **pytest**    | >=9.0,<9.1    | requirements-dev.txt                      |
| **mypy**      | 1.13.0        | pre-commit                                |
| **ESLint**    | 9.14.0-9.15.0 | pre-commit, npm dependencies              |
| **Gitleaks**  | 8.29.1        | pre-commit, security.yml                  |
| **Trivy**     | 0.33.1        | security.yml                              |
| **Node**      | 22.x          | Inferred from Bun compatibility           |
| **markdownl** | 0.19.1        | pre-commit                                |

---

## Recommendations Priority

### P0 - CRITICAL SECURITY (COMPLETED)

1. ~~**Update Go to 1.24.11** to patch 13 standard library vulnerabilities~~ -
   DONE

### P0 - Critical Configuration (ALL COMPLETED)

1. ~~**Fix Go version** to `1.24`~~ - DONE (now 1.24.11)
2. ~~**Remove Bun 1.2.2** from CI matrix~~ - DONE
3. ~~**Clean up pyproject.toml** - remove Black/isort configs~~ - DONE

### P1 - Important (COMPLETED)

1. ~~Add Ruff configuration to pyproject.toml~~ - DONE
2. Document Python 3.12 support in README if intentional (OPTIONAL)

### P2 - Nice to Have

1. Create version consistency validation script
2. Add pre-commit hook to validate version consistency

---

## Action Items

- [x] **SECURITY**: Update Go to 1.24.11 (patches 13 vulnerabilities)
- [x] Update Go version in security.yml and auth/go.mod
- [x] Update Bun matrix in ci.yml
- [x] Clean pyproject.toml (remove Black/isort)
- [x] Add Ruff config to pyproject.toml
- [ ] Update Python dependency spec if supporting 3.12 (optional)
- [ ] Create version validation script (future enhancement)

---

## Appendix: Version Reference

### Current Production Versions (as of 2025-12-06)

- **Go**: 1.24.11 (used in project - SECURITY UPDATE), 1.23.4, 1.22.9
- **Python**: 3.12.7, 3.11.10
- **Bun**: 1.3.3
- **Node.js**: 22.11.0 LTS, 20.11.0 LTS
- **Ruff**: 0.14.7
- **Prettier**: 3.6.2 (latest stable 3.x)

### Go 1.24 Security Timeline

- **1.24.0**: Initial release (December 2024)
- **1.24.2**: Fixed chunked request smuggling (GO-2025-3563)
- **1.24.4**: Fixed header leaks, x509 policy issues (GO-2025-3751,
  GO-2025-3749)
- **1.24.8**: Fixed cookie DoS, DSA panic (GO-2025-4012, GO-2025-4013)
- **1.24.9**: Additional x509 fixes (GO-2025-3959)
- **1.24.11**: Latest - DNS constraints, x509 resource exhaustion (GO-2025-4175,
  GO-2025-4155)

---

**Report Generated**: 2025-12-06 **Next Review**: Quarterly or on major
dependency updates

---

## Verification Notes

### Environment Variable Syntax (compose/data.yml)

**Verified**: Docker Compose environment variable expansion syntax is correct

- `REDIS_PASSWORD: "${REDIS_PASSWORD:-}"` - Correct syntax for optional env var
- Double quotes preserve shell variable expansion
- `:-` operator provides empty default if unset
- Used consistently in entrypoint scripts (lines 86-88)

**Validation**: Syntax tested with `docker compose config` - no errors

### Ruff Configuration Verification

**Confirmed**: Black and isort completely replaced by Ruff

- pyproject.toml: No `[tool.black]` or `[tool.isort]` sections
- pyproject.toml: `[tool.ruff]` section present with full config
- .pre-commit-config.yaml: Only Ruff hooks active
- requirements-dev.txt: Only `ruff>=0.14.6,<0.15.0` (no black/isort)

**Note**: Ruff select includes "I" (isort) for import sorting

### Prettier Version Clarification

**Context**: mirrors-prettier rev != npm prettier version

- `rev: v3.1.0` - pre-commit mirror wrapper version
- `prettier@3.6.2` - actual Prettier npm package version
- This is normal and expected behavior for pre-commit mirrors
- The npm version (3.6.2) is what actually formats files

**Documentation**: Added explanatory comment in .pre-commit-config.yaml
