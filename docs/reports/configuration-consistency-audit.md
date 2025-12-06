---
title: Configuration Consistency Audit Report
language: ru
page_id: config-consistency-audit-2025-12-06
doc_version: '2025.11'
translation_status: original
---

# Configuration Consistency Audit Report

**Date**: 2025-12-06 **Auditor**: Claude Code **Scope**: Tool versions and
configuration consistency across the project

## Executive Summary

Found **3 critical** and **2 warning** level inconsistencies in tool
configurations.

### Critical Issues

1. **INVALID Go Version**: `1.24.11` (Go has never had version 1.24)
2. **Bun Matrix Version Conflict**: `1.2.2` < minimum `1.3.0` from package.json
3. **Deprecated Tools in pyproject.toml**: Black and isort configured but Ruff
   is used

### Warnings

1. **Python Version Matrix**: Testing 3.12 but project requires ^3.11
2. **Prettier Version Mismatch**: FIXED in commit 81a3b18

---

## Detailed Findings

### 1. Go Version - CRITICAL

**Issue**: Invalid Go version specified

**Locations**:

- `.github/workflows/security.yml:212` → `go-version: "1.24.11"`
- `auth/go.mod:3` → `go 1.24.11`

**Problem**: Go versioning scheme is 1.XX.Y (e.g., 1.23.4, 1.22.8). Version 1.24
does not exist yet.

**Impact**: CI job may fail or use incorrect Go version

**Recommendation**:

```yaml
# Use latest stable Go 1.23.x
go-version: '1.23'
```

```go
// auth/go.mod
go 1.23
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

### 3. Deprecated Linting Tools - CRITICAL

**Issue**: Black and isort configured but not used (Ruff is the active linter)

**Locations**:

- `pyproject.toml:13-21` → `[tool.black]` and `[tool.isort]` sections
- `.pre-commit-config.yaml:146` → Using Ruff instead
- `requirements-dev.txt` → Only Ruff installed

**Problem**: Confusing configuration, dead code in pyproject.toml

**Impact**: Developer confusion, outdated configuration

**Recommendation**: Remove Black and isort sections from pyproject.toml, add
Ruff configuration instead

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

### P0 - Critical (Fix Immediately)

1. **Fix Go version** to `1.23` or `1.22`
2. **Remove Bun 1.2.2** from CI matrix
3. **Clean up pyproject.toml** - remove Black/isort configs

### P1 - Important (Fix Soon)

1. Add Ruff configuration to pyproject.toml
2. Document Python 3.12 support in README if intentional

### P2 - Nice to Have

1. Create version consistency validation script
2. Add pre-commit hook to validate version consistency

---

## Action Items

- [ ] Update Go version in security.yml and auth/go.mod
- [ ] Update Bun matrix in ci.yml
- [ ] Clean pyproject.toml (remove Black/isort)
- [ ] Add Ruff config to pyproject.toml
- [ ] Update Python dependency spec if supporting 3.12
- [ ] Create version validation script (optional)

---

## Appendix: Version Reference

### Current Production Versions (as of 2025-12-06)

- **Go**: 1.23.4 (latest), 1.22.9 (stable)
- **Python**: 3.12.7, 3.11.10
- **Bun**: 1.3.3
- **Node.js**: 22.11.0 LTS, 20.11.0 LTS
- **Ruff**: 0.14.7
- **Prettier**: 3.6.2 (latest stable 3.x)

---

**Report Generated**: 2025-12-06 **Next Review**: Quarterly or on major
dependency updates
