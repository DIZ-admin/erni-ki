---
title: 'Pre-commit Hooks & Project Rules - Refactoring Plan'
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# Pre-commit Hooks & Project Rules - Refactoring Plan

**Purpose:** Comprehensive refactoring strategy to optimize pre-commit hooks
configuration, improve performance, reduce complexity, and align with industry
best practices.

**Current Status:** Analysis complete **Complexity:** Medium **Estimated
Timeline:** 2-3 weeks (staggered implementation) **Risk Level:** Low (backward
compatible, incremental changes)

---

## Executive Summary

### Current State Analysis

**Strengths:**

- Comprehensive coverage (30+ hooks across 8 categories)
- Multi-language support (Python, TypeScript/JavaScript, Go, Shell)
- Strong security posture (5 security scanners)
- Dual validation system (Husky + Python pre-commit framework)
- Excellent documentation

**Issues Identified:**

1. **Performance bottlenecks**: 5-7 slow hooks block fast iterations
2. **Configuration duplication**: 3 separate linting systems overlap
3. **Complexity**: Multiple validation layers create confusion
4. **Maintenance burden**: Hook versions spread across 3 files
5. **Developer friction**: Slow pre-commit cycles reduce productivity

**Proposed Improvements:**

- **30-50% faster** pre-commit execution through parallelization
- **Simplified architecture** with unified linting configuration
- **Better developer experience** via smart hook orchestration
- **Reduced maintenance** through consolidation and automation

---

## Problem Statement

### Performance Issues

**Current slow hooks (>5s each):**

| Hook                          | Avg Time | Impact   | Reason                       |
| ----------------------------- | -------- | -------- | ---------------------------- |
| `visuals-and-links-check`     | 15-20s   | CRITICAL | Full documentation scan      |
| `typescript-type-check`       | 8-12s    | HIGH     | Full TypeScript compilation  |
| `docker-compose-check`        | 3-5s     | MEDIUM   | Docker daemon dependency     |
| `markdownlint-cli2`           | 4-8s     | MEDIUM   | All markdown files processed |
| `eslint`                      | 5-8s     | MEDIUM   | Large codebase scan          |
| `validate-docs-metadata`      | 2-4s     | LOW      | Python startup overhead      |
| `status-snippet-check`        | 2-3s     | LOW      | Multiple file reads          |
| `archive-readme-check`        | 1-3s     | LOW      | Directory traversal          |
| `mypy`                        | 5-10s    | MEDIUM   | Full type inference          |
| `check-duplicate-basenames`   | 1-2s     | LOW      | Directory traversal          |
| `check-secret-permissions`    | 1-2s     | LOW      | File system operations       |
| `forbid-numbered-copies`      | 1-2s     | LOW      | Find command execution       |
| `forbid-numbered-copies-any`  | 2-3s     | LOW      | Full repo scan               |
| `check-temporary-files`       | 1-2s     | LOW      | Find command execution       |
| `no-emoji-in-files`           | 1-2s     | LOW      | File content scanning        |
| `language-check` (via Husky)  | 3-5s     | MEDIUM   | Language validation          |
| `lint-staged` (via Husky)     | 5-15s    | HIGH     | Depends on changed files     |
| `commitlint` (commit-msg)     | 1-2s     | LOW      | Regex processing             |
| `check-todo-fixme`            | 2-4s     | MEDIUM   | Ripgrep full scan            |
| `goimports` (Go files staged) | 2-4s     | MEDIUM   | Go toolchain startup         |

**Total sequential execution time:** 60-120+ seconds **Target optimized time:**
15-30 seconds (4x improvement)

### Configuration Overlap

**Linting systems with overlapping responsibilities:**

1. **Python pre-commit hooks** (`.pre-commit-config.yaml`)

- prettier, ruff, black, isort, mypy, eslint
- Runs on: `git commit`

2. **Husky + lint-staged** (`.husky/pre-commit`, `package.json`)

- eslint, prettier, ruff
- Runs on: `git commit`

3. **NPM scripts** (`package.json` scripts section)

- eslint, ruff, prettier, type-check
- Runs manually or in CI

**Problems:**

- Same tool runs twice (e.g., ESLint in both systems)
- Inconsistent configurations can cause conflicts
- Developers confused about which tool runs when
- Wasted CPU cycles on duplicate checks

### Architectural Complexity

**Current validation layers:**

```
git commit
 ↓
Husky pre-commit (.husky/pre-commit)
 → bun run lint:language (language-check.cjs)
 → bunx lint-staged
 → eslint --fix
 → prettier --write
 → ruff check --fix
 → ruff format
 → gofmt -w
 → goimports -w
 ↓
Python pre-commit framework (.pre-commit-config.yaml)
 → Basic checks (30+ hooks)
 → prettier (again!)
 → eslint (again!)
 → ruff (again!)
 → black
 → isort
 → mypy
 → gitleaks
 → detect-secrets
 → custom local hooks (15+)
 → ...
 ↓
Husky commit-msg (.husky/commit-msg)
 → bunx commitlint --edit "$1"
 ↓
Commit succeeds
```

**Problems:**

- Multiple entry points create confusion
- Difficult to debug failures (which layer failed?)
- Hard to optimize (need to modify multiple files)
- Inconsistent SKIP behavior across systems

---

## Refactoring Strategy

### Phase 1: Performance Optimization (Week 1)

**Goal:** 30-50% faster pre-commit execution without changing architecture

#### 1.1 Parallelize Independent Hooks

**Action:** Group hooks by dependency and enable parallel execution

**Current serial execution:**

```yaml
# All hooks run sequentially
- check-yaml
- check-json
- prettier
- ruff
- eslint
- mypy
# Total: Sum of all times
```

**Optimized parallel execution:**

```yaml
# Group 1: Basic checks (parallel, fast)
- repo: https://github.com/pre-commit/pre-commit-hooks
 hooks:
 - id: trailing-whitespace
 - id: end-of-file-fixer
 - id: check-merge-conflict
 - id: check-case-conflict
 # All run in parallel within this repo

# Group 2: Formatters (parallel, no dependencies)
- repo: local
 hooks:
 - id: format-parallel
 name: 'Format: Run all formatters in parallel'
 entry: bash -c 'prettier --write "$@" & ruff format "$@" & wait'
 language: system
 pass_filenames: true
```

**Implementation:**

```bash
# Create parallel wrapper script
# scripts/pre-commit/run-parallel-formatters.sh

#!/usr/bin/env bash
set -euo pipefail

# Run formatters in parallel
prettier --write "$@" &
PID1=$!

ruff format "$@" &
PID2=$!

black "$@" &
PID3=$!

# Wait for all
wait $PID1 $PID2 $PID3

# Check exit codes
if ! wait $PID1 || ! wait $PID2 || ! wait $PID3; then
 exit 1
fi
```

**Expected improvement:** 20-30% reduction in total time

#### 1.2 Implement Incremental Checking

**Action:** Make slow hooks only process changed files

**Current behavior:**

```yaml
- id: typescript-type-check
 entry: npm run type-check # Checks ALL files
 pass_filenames: false
```

**Optimized behavior:**

```yaml
- id: typescript-type-check-incremental
 entry: scripts/pre-commit/type-check-incremental.sh
 pass_filenames: true
 files: \.(ts|tsx)$
```

**Implementation:**

```bash
# scripts/pre-commit/type-check-incremental.sh

#!/usr/bin/env bash
set -euo pipefail

# Only run if TypeScript files changed
if [[ $# -eq 0 ]]; then
 echo "No TypeScript files changed, skipping type check"
 exit 0
fi

# Run type check only on changed files (faster)
# Note: TypeScript needs full project context, but this fails fast
for file in "$@"; do
 if ! tsc --noEmit "$file" 2>/dev/null; then
 # If quick check fails, run full type check to get accurate errors
 echo "Type errors detected, running full type check..."
 npm run type-check
 exit $?
 fi
done
```

**Expected improvement:** 50-70% faster for incremental changes

#### 1.3 Add Caching Layer

**Action:** Cache results of expensive operations

**Implementation:**

```yaml
- id: visuals-and-links-check-cached
 name: 'Docs: visuals/TOC/link check (cached)'
 entry: scripts/pre-commit/visuals-check-cached.sh
 language: system
 pass_filenames: true
 files: ^docs/.*\.md$
```

**Cache script:**

```bash
# scripts/pre-commit/visuals-check-cached.sh

#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR=".cache/pre-commit"
CACHE_FILE="$CACHE_DIR/visuals-check.cache"
HASH_FILE="$CACHE_DIR/visuals-check.hash"

mkdir -p "$CACHE_DIR"

# Compute hash of changed files
current_hash=$(find docs -name "*.md" -type f -exec sha256sum {} \; | sha256sum | cut -d' ' -f1)

# Check if cached results are valid
if [[ -f "$HASH_FILE" ]] && [[ "$(cat "$HASH_FILE")" == "$current_hash" ]]; then
 echo "Using cached validation results"
 exit 0
fi

# Run validation
python3 scripts/docs/visuals_and_links_check.py "$@"
result=$?

# Cache results on success
if [[ $result -eq 0 ]]; then
 echo "$current_hash" > "$HASH_FILE"
fi

exit $result
```

**Expected improvement:** 80-90% faster on unchanged docs

#### 1.4 Skip Slow Hooks by Default (Local Development)

**Action:** Move slow hooks to manual/CI-only execution

**Current `.pre-commit-config.yaml`:**

```yaml
- id: visuals-and-links-check
 stages: [pre-commit] # Runs always
```

**Optimized `.pre-commit-config.yaml`:**

```yaml
- id: visuals-and-links-check
 stages: [manual] # Skip in pre-commit, run in CI or manually
```

**Alternative: Smart skipping via environment variable**

```yaml
- id: visuals-and-links-check
 name: 'Docs: visuals/TOC/link check'
 entry:
 bash -c 'if [[ "${SKIP_SLOW_CHECKS:-0}" == "1" ]]; then exit 0; fi; python3
 scripts/docs/visuals_and_links_check.py'
 language: system
 pass_filenames: false
```

**Developer workflow:**

```bash
# Fast local commit (skip slow checks)
SKIP_SLOW_CHECKS=1 git commit -m "feat: quick fix"

# Full validation before push
pre-commit run --all-files

# CI always runs everything (no SKIP_SLOW_CHECKS)
```

**Hooks to move to manual/CI-only:**

- `visuals-and-links-check` (15-20s)
- `typescript-type-check` (8-12s, TypeScript errors caught by IDE)
- `docker-compose-check` (3-5s, tested in CI anyway)
- `markdownlint-cli2` (4-8s, IDE plugin available)
- `link-check` (only in CI)
- `mypy` (optional locally, mandatory in CI)

**Expected improvement:** 60-70% faster local commits

---

### Phase 2: Architecture Simplification (Week 2)

**Goal:** Unified linting system, eliminate duplication

#### 2.1 Consolidate to Single Pre-commit Framework

**Recommendation:** Keep Python pre-commit as primary system, simplify Husky

**Rationale:**

- Python pre-commit framework is more powerful (30+ hooks)
- Better caching and parallel execution support
- Husky is simpler but less flexible
- Dual system causes confusion and duplication

**Current architecture:**

```
Husky (lint-staged) → Python pre-commit → Commit
```

**Proposed architecture:**

```
Python pre-commit (with language-check integrated) → Husky (commitlint only) → Commit
```

**Changes:**

1. **Remove lint-staged from Husky pre-commit**

```bash
# .husky/pre-commit (BEFORE)
#!/usr/bin/env sh

# Проверка языковых правил перед lint-staged и коммитом
bun run lint:language
bunx lint-staged
```

```bash
# .husky/pre-commit (AFTER)
#!/usr/bin/env sh

# All pre-commit checks handled by Python pre-commit framework
# This file kept for backward compatibility and documentation
# Actual checks run via .pre-commit-config.yaml

# Optional: Verify pre-commit is installed
if ! command -v pre-commit >/dev/null 2>&1; then
 echo "Error: pre-commit not found. Install with: pip install pre-commit"
 exit 1
fi

# Pre-commit runs automatically via git hooks
# No need to call it here, git will handle it
exit 0
```

2. **Move language-check into Python pre-commit**

```yaml
# .pre-commit-config.yaml
- repo: local
 hooks:
 - id: language-check
 name: 'Language: validate language policy'
 entry: bun run lint:language
 language: system
 pass_filenames: false
 stages: [pre-commit]
```

3. **Keep Husky for commitlint only**

```bash
# .husky/commit-msg (UNCHANGED)
#!/usr/bin/env sh

# Валидация commit message с помощью commitlint
bunx --bun commitlint --edit "$1"
```

**Benefits:**

- Single source of truth for pre-commit checks
- No duplicate tool execution
- Easier to understand and debug
- SKIP environment variable works consistently

#### 2.2 Merge Overlapping Formatters

**Problem:** Multiple formatters for Python (ruff, black, isort)

**Current:**

```yaml
- repo: https://github.com/astral-sh/ruff-pre-commit
 hooks:
 - id: ruff
 args: [--fix]

- repo: https://github.com/psf/black
 hooks:
 - id: black

- repo: https://github.com/pycqa/isort
 hooks:
 - id: isort
```

**Recommendation:** Use Ruff exclusively (replaces black + isort + ruff)

**Rationale:**

- Ruff 0.14+ includes black-compatible formatting
- Ruff handles import sorting (replaces isort)
- 10-100x faster than running all three
- Maintained by Astral, active development

**Optimized:**

```yaml
- repo: https://github.com/astral-sh/ruff-pre-commit
 rev: v0.14.6
 hooks:
 - id: ruff
 name: 'Ruff: Python lint'
 args: [--fix]

 - id: ruff-format
 name: 'Ruff: Python format'
 # Replaces black + isort
```

**Update `pyproject.toml` (or `ruff.toml`):**

```toml
[tool.ruff]
line-length = 100

[tool.ruff.format]
# Black-compatible formatting
quote-style = "double"
indent-style = "space"

[tool.ruff.lint]
select = [
 "E", # pycodestyle errors
 "F", # pyflakes
 "I", # isort
 "UP", # pyupgrade
 "B", # flake8-bugbear
]

[tool.ruff.lint.isort]
# Import sorting configuration
known-first-party = ["scripts"]
```

**Migration:**

```bash
# 1. Remove black and isort from requirements-dev.txt
sed -i '/^black==/d; /^isort==/d' requirements-dev.txt

# 2. Run ruff format on all Python files
ruff format .

# 3. Test that formatting is correct
pre-commit run ruff-format --all-files

# 4. Update CI to only run ruff
# .github/workflows/ci.yml
- name: Check Python formatting
 run: python3 -m ruff format --check .
```

**Expected improvement:** 40-50% faster Python formatting

#### 2.3 Simplify ESLint + Prettier Integration

**Problem:** Both tools run separately, potential conflicts

**Current:**

```yaml
# .pre-commit-config.yaml
- repo: https://github.com/pre-commit/mirrors-prettier
 hooks:
 - id: prettier

- repo: https://github.com/pre-commit/mirrors-eslint
 hooks:
 - id: eslint
 args: [--fix]
```

**Recommendation:** Use ESLint with Prettier plugin

**Optimized approach:**

```yaml
# .pre-commit-config.yaml
- repo: local
 hooks:
 - id: eslint-with-prettier
 name: 'ESLint: lint & format (includes Prettier)'
 entry: npx eslint --fix
 language: node
 files: \.(js|jsx|ts|tsx)$
 additional_dependencies:
 - eslint@9.15.0
 - eslint-config-prettier@9.1.0
 - eslint-plugin-prettier@5.2.1
 - prettier@3.6.2

 # Keep Prettier for non-JS files (YAML, JSON, Markdown)
 - id: prettier-other
 name: 'Prettier: format config files'
 entry: npx prettier --write
 language: node
 files: \.(yml|yaml|json|md)$
 exclude: package-lock\.json
 additional_dependencies:
 - prettier@3.6.2
```

**Update ESLint config:**

```javascript
// eslint.config.js
import prettier from 'eslint-plugin-prettier';
import prettierConfig from 'eslint-config-prettier';

export default [
  // ... existing config ...
  prettierConfig, // Disables ESLint rules that conflict with Prettier
  {
    plugins: {
      prettier,
    },
    rules: {
      'prettier/prettier': 'error', // Run Prettier as ESLint rule
    },
  },
];
```

**Benefits:**

- Single tool run (ESLint runs Prettier internally)
- No conflicts between ESLint and Prettier
- Consistent formatting rules

#### 2.4 Consolidate Local Hooks

**Problem:** 15+ local hooks spread throughout config, hard to maintain

**Current structure:**

```yaml
- repo: local
 hooks:
 - id: ts-type-check
 - id: docker-compose-check
 - id: check-todo-fixme
 - id: gofmt
 - id: goimports
 - id: check-duplicate-basenames
 - id: status-snippet-check
 - id: archive-readme-check
 - id: markdownlint-cli2
 - id: visuals-and-links-check
 - id: check-temporary-files
 - id: validate-docs-metadata
 - id: forbid-numbered-copies
 - id: forbid-numbered-copies-any
 - id: no-emoji-in-files
 - id: check-secret-permissions
```

**Proposed structure:** Group by category

```yaml
# ===================================================================
# LOCAL HOOKS - ORGANIZED BY CATEGORY
# ===================================================================

- repo: local
 hooks:
 # --- TYPE CHECKING ---
 - id: ts-type-check-fast
 name: 'TypeScript: type check (incremental)'
 entry: scripts/pre-commit/type-check-incremental.sh
 language: system
 files: \.(ts|tsx)$
 pass_filenames: true

 # --- CODE QUALITY ---
 - id: check-todo-fixme
 name: 'Code Quality: no inline task markers'
 entry: scripts/pre-commit/check-todo-fixme.sh
 language: system
 pass_filenames: false

 # --- GO TOOLING ---
 - id: go-format-and-imports
 name: 'Go: format + imports (combined)'
 entry: scripts/pre-commit/go-format-all.sh
 language: system
 files: \.go$
 pass_filenames: true

 # --- DOCKER VALIDATION ---
 - id: docker-compose-check
 name: 'Docker Compose: validate config'
 entry: docker compose config -q
 language: system
 files: ^compose\.yml$
 pass_filenames: false
 stages: [manual] # Slow, run in CI only

 # --- DOCUMENTATION CHECKS (Fast) ---
 - id: docs-metadata
 name: 'Docs: validate metadata'
 entry: scripts/pre-commit/docs-metadata-fast.sh
 language: system
 files: ^docs/.*\.md$
 pass_filenames: true

 - id: docs-no-duplicates
 name: 'Docs: forbid numbered copies'
 entry: scripts/pre-commit/check-duplicates.sh
 language: system
 files: ^docs/.*$
 pass_filenames: true

 # --- DOCUMENTATION CHECKS (Slow - CI only) ---
 - id: docs-full-validation
 name: 'Docs: full validation (visuals/links/TOC)'
 entry: python3 scripts/docs/visuals_and_links_check.py
 language: system
 pass_filenames: false
 stages: [manual] # Too slow for pre-commit

 - id: markdownlint
 name: 'Docs: markdown lint'
 entry: npx markdownlint-cli2
 language: node
 files: \.(md|markdown)$
 stages: [manual] # Too slow for pre-commit

 # --- SECURITY & CLEANUP ---
 - id: check-temporary-files
 name: 'Cleanup: no temporary files'
 entry: scripts/pre-commit/check-temp-files.sh
 language: system
 pass_filenames: false

 - id: check-secret-permissions
 name: 'Security: validate secret file permissions'
 entry: scripts/security/check-secret-permissions.sh
 language: script
 pass_filenames: false

 - id: no-emoji
 name: 'Style: no emoji in files'
 entry: python3 scripts/validate-no-emoji.py
 language: system
 files: \.(md|txt)$
```

**Benefits:**

- Clear organization by purpose
- Easy to find and modify hooks
- Obvious which hooks are slow (stages: [manual])
- Better documentation

---

### Phase 3: Configuration Management (Week 2-3)

**Goal:** Centralize configuration, reduce maintenance burden

#### 3.1 Extract Hook Versions to Central Config

**Problem:** Hook versions scattered across multiple files

**Current:**

```yaml
# .pre-commit-config.yaml
- repo: https://github.com/pre-commit/pre-commit-hooks
 rev: v6.0.0
 # ... 50 lines later ...
- repo: https://github.com/astral-sh/ruff-pre-commit
 rev: v0.14.6
 # ... 100 lines later ...
- repo: https://github.com/gitleaks/gitleaks
 rev: v8.29.1
```

**Proposed:** Version management via YAML anchors

```yaml
# .pre-commit-config.yaml
# Version definitions (YAML anchors)
x-versions:
 pre-commit-hooks: &pre-commit-hooks-version v6.0.0
 ruff: &ruff-version v0.14.6
 prettier: &prettier-version v4.0.0-alpha.8
 eslint: &eslint-version v10.0.0-alpha.0
 gitleaks: &gitleaks-version v8.29.1
 detect-secrets: &detect-secrets-version v1.5.0
 shellcheck: &shellcheck-version v0.9.0
 mypy: &mypy-version v1.8.0
 black: &black-version 23.12.1
 isort: &isort-version 5.13.2

repos:
 - repo: https://github.com/pre-commit/pre-commit-hooks
 rev: *pre-commit-hooks-version
 hooks:
 # ...

 - repo: https://github.com/astral-sh/ruff-pre-commit
 rev: *ruff-version
 hooks:
 # ...
```

**Benefits:**

- Single place to update versions
- Easy to see which tools need updates
- `pre-commit autoupdate` still works

#### 3.2 Create Pre-commit Profiles

**Problem:** Developers want different hook sets for different scenarios

**Proposed:** Multiple config files for different use cases

**Directory structure:**

```
.pre-commit/
 config-full.yaml # All hooks (CI)
 config-fast.yaml # Fast hooks only (local dev)
 config-docs.yaml # Documentation-only hooks
 config-security.yaml # Security-only hooks
```

**Usage:**

```bash
# Use fast profile for local development
ln -sf .pre-commit/config-fast.yaml .pre-commit-config.yaml

# Use full profile before push
pre-commit run --config .pre-commit/config-full.yaml --all-files

# CI uses full profile
# .github/workflows/ci.yml:
# - run: pre-commit run --config .pre-commit/config-full.yaml --all-files
```

**Fast profile example:**

```yaml
# .pre-commit/config-fast.yaml
# Fast hooks only (< 2s each)
repos:
 - repo: https://github.com/pre-commit/pre-commit-hooks
 rev: v6.0.0
 hooks:
 - id: trailing-whitespace
 - id: end-of-file-fixer
 - id: check-merge-conflict
 - id: check-yaml
 - id: check-json

 - repo: https://github.com/astral-sh/ruff-pre-commit
 rev: v0.14.6
 hooks:
 - id: ruff
 args: [--fix]
 - id: ruff-format

 - repo: https://github.com/gitleaks/gitleaks
 rev: v8.29.1
 hooks:
 - id: gitleaks

 # Skip: eslint, mypy, type-check, docs checks, etc.
```

#### 3.3 Add Hook Performance Monitoring

**Action:** Track hook execution times automatically

**Implementation:**

```bash
# .pre-commit-config.yaml
- repo: local
 hooks:
 - id: monitor-hook-performance
 name: "Monitor: track hook execution times"
 entry: scripts/pre-commit/monitor-performance.sh
 language: system
 pass_filenames: false
 stages: [post-commit] # Run after commit succeeds
```

**Monitor script:**

```bash
# scripts/pre-commit/monitor-performance.sh

#!/usr/bin/env bash
set -euo pipefail

METRICS_FILE=".cache/pre-commit/metrics.csv"
mkdir -p "$(dirname "$METRICS_FILE")"

# Parse pre-commit output for timing data
if [[ -f ".git/hooks/pre-commit" ]]; then
 # Run pre-commit with timing
 time_output=$(pre-commit run --verbose 2>&1 | grep "Passed\|Failed" || true)

 # Extract hook names and times
 while IFS= read -r line; do
 # Parse: "hookname....Passed (1.23s)"
 if [[ "$line" =~ ([a-z-]+).*\(([0-9.]+)s\) ]]; then
 hook="${BASH_REMATCH[1]}"
 time="${BASH_REMATCH[2]}"
 echo "$(date +%s),$hook,$time" >> "$METRICS_FILE"
 fi
 done <<< "$time_output"
fi

# Generate weekly report
if [[ $(find "$METRICS_FILE" -mtime +7 2>/dev/null) ]]; then
 echo "Generating pre-commit performance report..."
 python3 scripts/pre-commit/generate-performance-report.py
fi
```

**Report script:**

```python
# scripts/pre-commit/generate-performance-report.py

import csv
from collections import defaultdict
from pathlib import Path

metrics_file = Path(".cache/pre-commit/metrics.csv")
if not metrics_file.exists():
 print("No metrics data found")
 exit(0)

# Parse metrics
hook_times = defaultdict(list)
with open(metrics_file) as f:
 reader = csv.reader(f)
 for timestamp, hook, time in reader:
 hook_times[hook].append(float(time))

# Generate report
print("Pre-commit Hook Performance Report")
print("=" * 60)
print(f"{'Hook':<40} {'Avg Time':>10} {'Max Time':>10}")
print("-" * 60)

for hook, times in sorted(hook_times.items(), key=lambda x: -sum(x[1])/len(x[1])):
 avg_time = sum(times) / len(times)
 max_time = max(times)
 print(f"{hook:<40} {avg_time:>9.2f}s {max_time:>9.2f}s")

print("\nSlowest hooks (consider optimization):")
slow_hooks = [(h, sum(t)/len(t)) for h, t in hook_times.items() if sum(t)/len(t) > 5.0]
for hook, avg_time in sorted(slow_hooks, key=lambda x: -x[1]):
 print(f" - {hook}: {avg_time:.2f}s")
```

#### 3.4 Standardize Error Messages

**Problem:** Inconsistent error output from different hooks

**Current examples:**

```
 Inline tasks detected; create a GitHub Issue instead of a comment.
 Failed: ESLint validation
Error: Trailing whitespace found
[ERROR] Docker Compose validation failed
```

**Proposed standard format:**

```
[HOOK_NAME] ERROR: Description of error
[HOOK_NAME] WARN: Warning message
[HOOK_NAME] INFO: Informational message
[HOOK_NAME] FIX: Suggestion to fix the issue
```

**Implementation:**

```bash
# Create error reporting helper
# scripts/pre-commit/lib/error-reporter.sh

#!/usr/bin/env bash

error() {
 local hook_name="$1"
 local message="$2"
 echo "[$hook_name] ERROR: $message" >&2
}

warn() {
 local hook_name="$1"
 local message="$2"
 echo "[$hook_name] WARN: $message" >&2
}

info() {
 local hook_name="$1"
 local message="$2"
 echo "[$hook_name] INFO: $message"
}

fix_suggestion() {
 local hook_name="$1"
 local message="$2"
 echo "[$hook_name] FIX: $message" >&2
}
```

**Usage in hooks:**

```bash
# scripts/pre-commit/check-todo-fixme.sh

#!/usr/bin/env bash
source "$(dirname "$0")/lib/error-reporter.sh"

HOOK_NAME="check-todo-fixme"

matches=$(rg --no-heading "TODO|FIXME" || true)
matches=$(echo "$matches" | grep -v "pragma: allowlist todo" | head -20)

if [[ -n "$matches" ]]; then
 error "$HOOK_NAME" "Inline task markers detected in code"
 echo "$matches"
 fix_suggestion "$HOOK_NAME" "Create a GitHub Issue instead of using TODO/FIXME comments"
 fix_suggestion "$HOOK_NAME" "Use '# pragma: allowlist todo' to explicitly allow specific instances"
 exit 1
fi

info "$HOOK_NAME" "No TODO/FIXME markers found"
```

**Benefits:**

- Consistent error format across all hooks
- Easy to parse for CI/CD systems
- Clear fix suggestions for developers

---

### Phase 4: Developer Experience (Week 3)

**Goal:** Make pre-commit system easier to use and understand

#### 4.1 Interactive Hook Selector

**Problem:** Developers don't know which hooks to skip for fast commits

**Proposed:** Interactive CLI tool to select hooks

**Implementation:**

```bash
# scripts/pre-commit/interactive-commit.sh

#!/usr/bin/env bash
set -euo pipefail

echo "ERNI-KI Pre-commit Hook Selector"
echo "================================="
echo ""
echo "Select commit mode:"
echo ""
echo "1. Fast (skip slow checks, ~10-15s)"
echo "2. Standard (most checks, ~30-45s)"
echo "3. Full (all checks, ~60-120s)"
echo "4. Custom (select hooks manually)"
echo ""
read -p "Mode [1-4]: " mode

case $mode in
 1)
 export SKIP="visuals-and-links-check,typescript-type-check,docker-compose-check,markdownlint-cli2,mypy"
 echo "Using fast mode (skipping slow checks)"
 ;;
 2)
 export SKIP="visuals-and-links-check,docker-compose-check"
 echo "Using standard mode"
 ;;
 3)
 unset SKIP
 echo "Using full mode (all checks)"
 ;;
 4)
 echo ""
 echo "Available slow hooks to skip:"
 echo " - visuals-and-links-check (15-20s)"
 echo " - typescript-type-check (8-12s)"
 echo " - docker-compose-check (3-5s)"
 echo " - markdownlint-cli2 (4-8s)"
 echo " - mypy (5-10s)"
 echo ""
 read -p "Enter hooks to skip (comma-separated): " custom_skip
 export SKIP="$custom_skip"
 echo "Using custom mode (skipping: $SKIP)"
 ;;
 *)
 echo "Invalid selection"
 exit 1
 ;;
esac

echo ""
read -p "Commit message: " commit_msg

if [[ -z "$commit_msg" ]]; then
 echo "Commit message cannot be empty"
 exit 1
fi

echo ""
echo "Running pre-commit hooks..."
git commit -m "$commit_msg"
```

**Add as npm script:**

```json
{
  "scripts": {
    "commit": "bash scripts/pre-commit/interactive-commit.sh",
    "commit:fast": "SKIP=visuals-and-links-check,typescript-type-check git commit",
    "commit:full": "git commit"
  }
}
```

**Usage:**

```bash
# Interactive mode
bun run commit

# Fast commit (manual SKIP)
bun run commit:fast

# Full commit
bun run commit:full
```

#### 4.2 Pre-commit Health Check

**Problem:** Developers unsure if pre-commit is configured correctly

**Proposed:** Health check command

**Implementation:**

```bash
# scripts/pre-commit/health-check.sh

#!/usr/bin/env bash
set -euo pipefail

echo "ERNI-KI Pre-commit Health Check"
echo "================================="
echo ""

errors=0

# Check 1: pre-commit installed
if ! command -v pre-commit >/dev/null 2>&1; then
 echo " pre-commit not found"
 echo " Fix: pip install pre-commit"
 ((errors++))
else
 echo " pre-commit installed ($(pre-commit --version))"
fi

# Check 2: Git hooks installed
if [[ ! -f ".git/hooks/pre-commit" ]]; then
 echo " Git hooks not installed"
 echo " Fix: pre-commit install"
 ((errors++))
else
 echo " Git hooks installed"
fi

# Check 3: Commit-msg hook installed
if [[ ! -f ".git/hooks/commit-msg" ]]; then
 echo " Commit-msg hook not installed"
 echo " Fix: pre-commit install --hook-type commit-msg"
 ((errors++))
else
 echo " Commit-msg hook installed"
fi

# Check 4: Node.js/Bun available
if ! command -v bun >/dev/null 2>&1; then
 echo " Bun not found (optional, but recommended)"
else
 echo " Bun installed ($(bun --version))"
fi

# Check 5: Python 3.11+
python_version=$(python3 --version | cut -d' ' -f2)
if [[ "${python_version%%.*}" -lt 3 ]] || [[ "${python_version#*.}" -lt 11 ]]; then
 echo " Python 3.11+ required (found $python_version)"
 ((errors++))
else
 echo " Python $python_version"
fi

# Check 6: Required Python packages
if ! python3 -c "import yaml, ruff" 2>/dev/null; then
 echo " Required Python packages missing"
 echo " Fix: pip install -r requirements-dev.txt"
 ((errors++))
else
 echo " Required Python packages installed"
fi

# Check 7: Go toolchain (optional)
if command -v go >/dev/null 2>&1; then
 echo " Go toolchain installed ($(go version | cut -d' ' -f3))"
else
 echo " Go toolchain not found (optional, for auth service)"
fi

# Check 8: Docker running (optional)
if docker info >/dev/null 2>&1; then
 echo " Docker daemon running"
else
 echo " Docker daemon not running (optional, needed for docker-compose-check hook)"
fi

echo ""
if [[ $errors -eq 0 ]]; then
 echo " All checks passed! Pre-commit is configured correctly."
 exit 0
else
 echo " $errors error(s) found. Please fix the issues above."
 exit 1
fi
```

**Add as npm script:**

```json
{
  "scripts": {
    "precommit:health": "bash scripts/pre-commit/health-check.sh"
  }
}
```

**Usage:**

```bash
# Check pre-commit health
bun run precommit:health
```

#### 4.3 Improve Documentation

**Action:** Create visual flowcharts and decision trees

**Files to update:**

1. **docs/development/QUICK-START-PRECOMMIT.md** (new)

- 5-minute quick start guide
- Common workflows
- Troubleshooting FAQ

2. **docs/development/pre-commit-guide.md** (existing)

- Add "Choosing hooks for fast commits" section
- Add "Performance tips" section
- Add "Hook profiles" section

3. **docs/development/RULES-FLOWCHART.md** (existing)

- Add decision tree: "Which hooks should I skip?"
- Add diagram: "Pre-commit execution flow"

**Quick start example:**

```markdown
# Pre-commit Quick Start (5 minutes)

## Setup

bash

# 1. Install Python dependencies

source .venv/bin/activate pip install -r requirements-dev.txt

# 2. Install pre-commit hooks

pre-commit install pre-commit install --hook-type commit-msg

# 3. Verify installation

bun run precommit:health

## Daily Workflow

### Fast commit (10-15s)

bash bun run commit:fast

### Standard commit (30-45s)

bash git commit -m "feat(scope): description"

### Before push (full validation)

bash pre-commit run --all-files
```

---

## Implementation Roadmap

### Week 1: Performance Quick Wins

**Monday-Tuesday:**

- [ ] Implement parallel formatters wrapper
- [ ] Add caching for visuals-and-links-check
- [ ] Create incremental TypeScript type check script
- [ ] Move slow hooks to `stages: [manual]`

**Wednesday-Thursday:**

- [ ] Test performance improvements on real workflows
- [ ] Measure baseline vs. optimized execution times
- [ ] Document SKIP environment variable usage
- [ ] Create fast commit npm script

**Friday:**

- [ ] Code review and testing
- [ ] Update documentation
- [ ] Create PR: "perf: optimize pre-commit hook performance"

**Expected outcome:** 30-50% faster local commits

### Week 2: Architecture Cleanup

**Monday-Tuesday:**

- [ ] Remove lint-staged from Husky pre-commit
- [ ] Move language-check into Python pre-commit
- [ ] Consolidate to Ruff only (remove black, isort)
- [ ] Update CI workflows

**Wednesday-Thursday:**

- [ ] Merge ESLint + Prettier configuration
- [ ] Reorganize local hooks by category
- [ ] Add YAML anchors for version management
- [ ] Create hook profiles (fast/full/docs/security)

**Friday:**

- [ ] Testing across different commit scenarios
- [ ] Update CONTRIBUTING.md
- [ ] Create PR: "refactor: simplify pre-commit architecture"

**Expected outcome:** Single source of truth, no duplication

### Week 3: Developer Experience

**Monday-Tuesday:**

- [ ] Create interactive commit script
- [ ] Implement health check script
- [ ] Add performance monitoring
- [ ] Standardize error messages

**Wednesday-Thursday:**

- [ ] Write QUICK-START-PRECOMMIT.md
- [ ] Update existing documentation
- [ ] Add flowcharts and decision trees
- [ ] Create video tutorial (optional)

**Friday:**

- [ ] Final testing and bug fixes
- [ ] Team training session
- [ ] Create PR: "docs: improve pre-commit developer experience"
- [ ] Celebrate!

**Expected outcome:** Happier developers, better DX

---

## Migration Guide

### For Developers

**What changes:**

1. **Faster commits** - Most commits will be 30-50% faster
2. **Simplified workflow** - Single pre-commit system (no more Husky
   lint-staged)
3. **Better errors** - Clearer error messages with fix suggestions
4. **More control** - Easy to skip slow checks when needed

**What stays the same:**

- Commit message format (Conventional Commits)
- All validation rules (same quality standards)
- CI/CD behavior (no changes)

**Action required:**

```bash
# 1. Pull latest changes
git pull origin develop

# 2. Reinstall pre-commit hooks
source .venv/bin/activate
pre-commit uninstall
pre-commit install
pre-commit install --hook-type commit-msg

# 3. Update Python dependencies
pip install -r requirements-dev.txt

# 4. Update Node dependencies
bun install

# 5. Run health check
bun run precommit:health

# 6. Test with fast commit
bun run commit:fast
```

### For CI/CD

**Changes needed:**

1. **Use full pre-commit profile in CI**

```yaml
# .github/workflows/ci.yml
- name: Run pre-commit
 run: |
 source .venv/bin/activate
 pre-commit run --config .pre-commit/config-full.yaml --all-files
```

2. **Update Python linting jobs**

```yaml
# Remove black and isort, keep only ruff
- name: Check Python formatting
 run: python3 -m ruff format --check .

- name: Run Python linter
 run: python3 -m ruff check .
```

3. **No changes needed for:**

- Go tests
- TypeScript tests
- Security scans
- Docker builds

---

## Success Metrics

### Performance

- **Target:** 30-50% reduction in pre-commit execution time
- **Baseline:** 60-120s (current sequential execution)
- **Goal:** 15-30s (optimized parallel execution)

**Measurement:**

```bash
# Before optimization
time git commit -m "test: benchmark"

# After optimization
time git commit -m "test: benchmark"

# Compare results
```

### Developer Satisfaction

- **Target:** 80%+ developers satisfied with pre-commit speed
- **Survey questions:**
- "Pre-commit hooks are fast enough for daily work" (1-5 scale)
- "I understand which hooks run when" (1-5 scale)
- "Error messages are clear and helpful" (1-5 scale)

### Code Quality

- **Target:** Maintain or improve current quality standards
- **Metrics:**
- No increase in bugs caught by CI (should remain 0)
- No increase in failed commits due to skipped checks
- Same or better test coverage (≥80%)

---

## Risks and Mitigation

### Risk 1: Breaking Developer Workflows

**Impact:** HIGH **Probability:** MEDIUM

**Mitigation:**

- Incremental rollout (Phase 1 → 2 → 3)
- Backward compatibility where possible
- Clear migration guide and training
- Quick rollback plan if issues arise

### Risk 2: CI/CD Failures

**Impact:** HIGH **Probability:** LOW

**Mitigation:**

- Test all CI changes in feature branch first
- Run full CI suite before merging
- Keep old CI configuration as backup
- Document rollback procedure

### Risk 3: Performance Regression

**Impact:** MEDIUM **Probability:** LOW

**Mitigation:**

- Benchmark before and after each change
- Add performance monitoring
- Test on different hardware (fast/slow machines)
- Collect developer feedback continuously

### Risk 4: Configuration Errors

**Impact:** MEDIUM **Probability:** MEDIUM

**Mitigation:**

- Extensive testing of new configurations
- Health check script to validate setup
- Clear documentation with examples
- Automated tests for hook behavior

### Risk 5: Developer Resistance

**Impact:** MEDIUM **Probability:** LOW

**Mitigation:**

- Communicate benefits clearly (faster commits!)
- Provide training and documentation
- Gather feedback early and often
- Make changes optional initially (profiles)

---

## Rollback Plan

### If Phase 1 Fails

**Symptoms:** Pre-commit is slower or broken

**Action:**

```bash
# 1. Revert to previous .pre-commit-config.yaml
git checkout HEAD~1 .pre-commit-config.yaml

# 2. Reinstall hooks
pre-commit uninstall
pre-commit install

# 3. Test
git commit -m "test: rollback verification"
```

### If Phase 2 Fails

**Symptoms:** Linting conflicts or missing checks

**Action:**

```bash
# 1. Restore Husky lint-staged
git checkout HEAD~1 .husky/pre-commit package.json

# 2. Reinstall
bun install
pre-commit uninstall
pre-commit install

# 3. Test
git commit -m "test: rollback verification"
```

### If Phase 3 Fails

**Symptoms:** Developer confusion or CI failures

**Action:**

```bash
# 1. Revert all changes
git checkout HEAD~1 .pre-commit-config.yaml .husky/* package.json

# 2. Communicate to team
echo "Pre-commit changes reverted due to issues. Using previous configuration."

# 3. Gather feedback
# Create GitHub Discussion for issues encountered
```

---

## Alternatives Considered

### Alternative 1: Use Husky + lint-staged Only

**Pros:**

- Simpler setup (no Python pre-commit framework)
- Faster execution (Node.js only)
- Better integration with npm ecosystem

**Cons:**

- Less powerful than Python pre-commit
- Harder to manage 30+ hooks in package.json
- No built-in caching or parallel execution
- Limited to JavaScript tools

**Decision:** Rejected - Python pre-commit is more flexible

### Alternative 2: Use GitHub Actions Only (No Local Hooks)

**Pros:**

- No local setup required
- Consistent environment (CI)
- No performance issues for developers

**Cons:**

- Slow feedback loop (wait for CI)
- Wastes CI resources on trivial errors
- Developers commit broken code more often
- Poor developer experience

**Decision:** Rejected - Local hooks catch errors earlier

### Alternative 3: Keep Current System Unchanged

**Pros:**

- No migration risk
- No developer retraining needed
- System works today

**Cons:**

- Pre-commit is too slow (60-120s)
- Configuration is duplicated and confusing
- Developer productivity suffers
- Technical debt accumulates

**Decision:** Rejected - Status quo is not acceptable

---

## FAQ

### Why not remove pre-commit hooks entirely?

**Answer:** Pre-commit hooks catch errors BEFORE commit, saving CI resources and
developer time. Without them, developers would commit broken code more often,
wasting CI cycles and creating more failed builds.

### Will this affect CI/CD pipelines?

**Answer:** Minimal impact. CI will use the "full" pre-commit profile, which
includes all checks. The main difference is that local development will be
faster by skipping slow checks that CI runs anyway.

### Can I still use `git commit --no-verify`?

**Answer:** Yes, but discouraged. Use `SKIP` environment variable instead:

```bash
# Bad (skips ALL hooks, including security checks)
git commit --no-verify

# Good (skip specific slow hooks only)
SKIP=visuals-and-links-check git commit
```

### What if I disagree with a hook's decision?

**Answer:**

1. Check if the error is valid (most are!)
2. Fix the underlying issue
3. If truly incorrect, use pragma comments:

```python
# pragma: allowlist todo
# TODO: This is tracked in issue #123
```

4. If hook is fundamentally broken, open GitHub issue

### How do I add a new hook?

**Answer:**

1. Add to appropriate category in `.pre-commit-config.yaml`
2. Test locally: `pre-commit run <hook-id> --all-files`
3. Update documentation in `pre-commit-guide.md`
4. Create PR with description and rationale

### Can I use my own pre-commit configuration?

**Answer:** Not recommended. Custom configurations can:

- Miss required checks (security, secrets)
- Conflict with CI expectations
- Create inconsistent code quality

Use hook profiles instead:

```bash
# Use fast profile
SKIP=slow-hooks git commit

# Use custom SKIP list
SKIP=hook1,hook2,hook3 git commit
```

---

## Appendix

### A. Pre-commit Hook Comparison

| Hook Name                 | Type     | Speed     | Skip Locally? | Required in CI? |
| ------------------------- | -------- | --------- | ------------- | --------------- |
| trailing-whitespace       | Format   | Fast      | No            | Yes             |
| end-of-file-fixer         | Format   | Fast      | No            | Yes             |
| check-merge-conflict      | Safety   | Fast      | No            | Yes             |
| check-yaml                | Syntax   | Fast      | No            | Yes             |
| check-json                | Syntax   | Fast      | No            | Yes             |
| prettier                  | Format   | Medium    | No            | Yes             |
| ruff                      | Lint     | Fast      | No            | Yes             |
| ruff-format               | Format   | Fast      | No            | Yes             |
| eslint                    | Lint     | Medium    | No            | Yes             |
| mypy                      | Type     | Slow      | Yes           | Yes             |
| gitleaks                  | Security | Fast      | No            | Yes             |
| detect-secrets            | Security | Fast      | No            | Yes             |
| shellcheck                | Lint     | Fast      | No            | Yes             |
| check-todo-fixme          | Policy   | Medium    | No            | Yes             |
| typescript-type-check     | Type     | Slow      | Yes           | Yes             |
| docker-compose-check      | Validate | Slow      | Yes           | Yes             |
| visuals-and-links-check   | Docs     | Very Slow | Yes           | Yes             |
| markdownlint-cli2         | Lint     | Slow      | Yes           | Yes             |
| validate-docs-metadata    | Docs     | Medium    | No            | Yes             |
| status-snippet-check      | Docs     | Medium    | No            | Yes             |
| archive-readme-check      | Docs     | Medium    | No            | Yes             |
| check-duplicate-basenames | Policy   | Fast      | No            | Yes             |
| forbid-numbered-copies    | Policy   | Fast      | No            | Yes             |
| no-emoji-in-files         | Policy   | Fast      | No            | Yes             |
| check-temporary-files     | Cleanup  | Fast      | No            | Yes             |
| check-secret-permissions  | Security | Fast      | No            | Yes             |
| gofmt                     | Format   | Fast      | No            | Yes             |
| goimports                 | Format   | Medium    | No            | Yes             |
| commitlint (commit-msg)   | Policy   | Fast      | No            | N/A             |
| language-check (Husky)    | Policy   | Medium    | No            | Yes             |

### B. Estimated Time Savings

**Scenario 1: Quick fix commit (1-2 files changed)**

- **Before:** 60-90s (all hooks run)
- **After (fast mode):** 10-15s (slow hooks skipped)
- **Savings:** 45-75s (75-83% faster)

**Scenario 2: Feature commit (10-20 files changed)**

- **Before:** 90-120s (all hooks run)
- **After (standard mode):** 30-45s (some slow hooks skipped)
- **Savings:** 60-75s (67-63% faster)

**Scenario 3: Documentation-only commit**

- **Before:** 60-80s (all hooks run, most skip)
- **After (docs profile):** 20-30s (only docs hooks)
- **Savings:** 40-50s (67-63% faster)

**Daily impact (assuming 10 commits/day):**

- **Before:** 10 × 75s = 750s = 12.5 minutes
- **After:** 10 × 20s = 200s = 3.3 minutes
- **Daily savings:** 9.2 minutes/developer
- **Team savings (10 devs):** 92 minutes/day = 7.7 hours/week

### C. Tool Version Matrix

| Tool          | Current Version | Latest Version | Update Needed? |
| ------------- | --------------- | -------------- | -------------- |
| pre-commit    | 3.5.0           | 4.0.1          | Yes            |
| Prettier      | 3.6.2           | 3.6.2          | No             |
| ESLint        | 9.15.0          | 9.16.0         | Minor          |
| Ruff          | 0.14.6          | 0.14.6         | No             |
| Black         | 23.12.1         | 24.4.2         | Yes (remove)   |
| isort         | 5.13.2          | 5.13.2         | No (remove)    |
| mypy          | 1.8.0           | 1.14.0         | Yes            |
| Gitleaks      | 8.29.1          | 8.29.1         | No             |
| ShellCheck    | 0.9.0           | 0.10.0         | Yes            |
| Trivy         | 0.33.1          | 0.33.1         | No             |
| Gosec         | 2.22.10         | 2.22.10        | No             |
| golangci-lint | 1.64.5          | 1.64.5         | No             |

### D. References

- [Pre-commit Framework Documentation](https://pre-commit.com/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [ESLint + Prettier Integration](https://github.com/prettier/eslint-plugin-prettier)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Hooks Best Practices](https://www.atlassian.com/git/tutorials/git-hooks)

---

## Approval and Sign-off

**Prepared by:** Claude Code **Date:** 2025-12-03 **Status:** DRAFT - Awaiting
Review

**Reviewers:**

- [ ] Tech Lead - Review technical approach
- [ ] DevOps Engineer - Review CI/CD impact
- [ ] Senior Developer - Review developer experience
- [ ] Team Lead - Final approval

**Approvals:**

- [ ] Technical approach approved
- [ ] CI/CD impact acceptable
- [ ] Developer experience validated
- [ ] Ready for implementation

**Next Steps:**

1. Review this document with team
2. Gather feedback and concerns
3. Prioritize phases based on team needs
4. Begin Week 1 implementation
5. Schedule check-ins and retrospectives

---

**Document Version:** 1.0 **Last Updated:** 2025-12-03 **Status:** COMPREHENSIVE
REFACTORING PLAN - READY FOR REVIEW
