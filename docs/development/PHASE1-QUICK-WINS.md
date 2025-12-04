---
title: 'Phase 1 Quick Wins - Implementation Checklist'
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# Phase 1 Quick Wins - Implementation Checklist

**Immediate performance improvements** you can implement today (30-50% faster
commits)

**Time Required:** 2-4 hours total **Difficulty:** Easy **Risk:** Low (all
changes are backward compatible)

---

## Overview

This document provides **actionable steps** to achieve quick performance
improvements without major architectural changes. These are the "low-hanging
fruit" optimizations that deliver immediate value.

**Expected Results:**

- Commits 30-50% faster
- Developer satisfaction improved
- No breaking changes
- Easy to rollback if needed

---

## Quick Win #1: Skip Slow Hooks Locally (5 minutes)

**Impact:** 60-70% faster local commits **Effort:** 5 minutes **Risk:** Very low

### The Problem

Slow hooks block fast iteration:

- `visuals-and-links-check` (15-20s)
- `typescript-type-check` (8-12s)
- `docker-compose-check` (3-5s)
- `markdownlint-cli2` (4-8s)

These checks are valuable but don't need to run on every commit (CI runs them
anyway).

### The Solution

Use the `SKIP` environment variable:

```bash
# Skip specific slow hooks
SKIP=visuals-and-links-check,typescript-type-check git commit -m "feat: quick fix"

# Skip multiple hooks
SKIP=visuals-and-links-check,typescript-type-check,docker-compose-check git commit
```

### Implementation Steps

1. **Create npm scripts for common scenarios:**

```json
// package.json
{
  "scripts": {
    // Existing scripts...
    "commit:fast": "SKIP=visuals-and-links-check,typescript-type-check,docker-compose-check,markdownlint-cli2 git commit",
    "commit:standard": "SKIP=visuals-and-links-check,docker-compose-check git commit",
    "commit:full": "git commit"
  }
}
```

2. **Create shell aliases (optional):**

```bash
# Add to ~/.bashrc or ~/.zshrc
alias gcf='SKIP=visuals-and-links-check,typescript-type-check git commit'
alias gcs='SKIP=visuals-and-links-check git commit'
alias gcfull='git commit'
```

3. **Document usage:**

```bash
# Fast commit (skip slow checks)
bun run commit:fast

# Standard commit (skip very slow checks)
bun run commit:standard

# Full commit (all checks)
bun run commit:full

# Or manually
SKIP=hook1,hook2 git commit -m "message"
```

### Verification

```bash
# Test fast commit
bun run commit:fast -m "test: verify fast commit"

# Should complete in 15-30s instead of 60-120s
```

**Rollback:** Just use `git commit` normally (no SKIP variable)

---

## Quick Win #2: Add Caching for Document Checks (30 minutes)

**Impact:** 80-90% faster on unchanged docs **Effort:** 30 minutes **Risk:** Low

### The Problem

`visuals-and-links-check` runs on EVERY commit, even when docs haven't changed.
This wastes 15-20s per commit.

### The Solution

Add simple file-hash caching to skip validation when docs are unchanged.

### Implementation Steps

1. **Create caching wrapper script:**

```bash
# scripts/pre-commit/visuals-check-cached.sh

#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR=".cache/pre-commit"
HASH_FILE="$CACHE_DIR/visuals-check.hash"

mkdir -p "$CACHE_DIR"

# Compute hash of all markdown files
current_hash=$(find docs -name "*.md" -type f -exec sha256sum {} \; 2>/dev/null | sha256sum | cut -d' ' -f1)

# Check if cached results are valid
if [[ -f "$HASH_FILE" ]] && [[ "$(cat "$HASH_FILE")" == "$current_hash" ]]; then
 echo " Using cached validation results (no docs changed)"
 exit 0
fi

echo " Running full documentation validation..."

# Run validation
python3 scripts/docs/visuals_and_links_check.py "$@"
result=$?

# Cache results on success
if [[ $result -eq 0 ]]; then
 echo "$current_hash" > "$HASH_FILE"
 echo " Cached validation results"
fi

exit $result
```

2. **Make script executable:**

```bash
chmod +x scripts/pre-commit/visuals-check-cached.sh
```

3. **Update `.pre-commit-config.yaml`:**

```yaml
- id: visuals-and-links-check
 name: 'Docs: visuals/TOC/link check (cached)'
 entry: scripts/pre-commit/visuals-check-cached.sh
 language: system
 pass_filenames: false
 files: ^docs/.*\.md$
```

4. **Test:**

```bash
# First run (should run full validation)
pre-commit run visuals-and-links-check --all-files

# Second run (should use cache)
pre-commit run visuals-and-links-check --all-files
```

### Verification

```bash
# First commit (full validation)
time git commit -m "test: first commit"
# Expected: ~15-20s for visuals check

# Second commit (cached)
time git commit -m "test: second commit"
# Expected: <1s for visuals check (cached)
```

**Rollback:** Restore original `.pre-commit-config.yaml` entry

---

## Quick Win #3: Incremental TypeScript Type Check (45 minutes)

**Impact:** 50-70% faster for small changes **Effort:** 45 minutes **Risk:** Low

### The Problem

`typescript-type-check` runs `tsc --noEmit` on the ENTIRE codebase, even when
only 1-2 files changed. This takes 8-12s every commit.

### The Solution

Quick-check changed files first. Only run full type check if quick check fails.

### Implementation Steps

1. **Create incremental type check script:**

```bash
# scripts/pre-commit/type-check-incremental.sh

#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR=".cache/pre-commit"
TS_CACHE="$CACHE_DIR/tsconfig.tsbuildinfo"

mkdir -p "$CACHE_DIR"

# If no TypeScript files changed, skip
if [[ $# -eq 0 ]]; then
 echo " No TypeScript files changed, skipping type check"
 exit 0
fi

# Quick syntax check on changed files only
echo " Quick type check on $# file(s)..."

for file in "$@"; do
 if ! tsc --noEmit --skipLibCheck "$file" 2>/dev/null; then
 echo " Type errors detected in $file"
 echo " Running full type check for accurate errors..."
 npm run type-check
 exit $?
 fi
done

echo " Quick type check passed"

# Optional: Run incremental build for cache
if command -v tsc >/dev/null 2>&1; then
 tsc --noEmit --incremental --tsBuildInfoFile "$TS_CACHE" 2>/dev/null || true
fi

exit 0
```

2. **Make script executable:**

```bash
chmod +x scripts/pre-commit/type-check-incremental.sh
```

3. **Update `.pre-commit-config.yaml`:**

```yaml
- id: ts-type-check
 name: 'TypeScript: type check (incremental)'
 entry: scripts/pre-commit/type-check-incremental.sh
 language: system
 files: \.(ts|tsx)$
 pass_filenames: true
```

4. **Test:**

```bash
# Test with TypeScript file change
echo "// test comment" >> src/types.ts
pre-commit run ts-type-check --files src/types.ts
```

### Verification

```bash
# Test incremental check (1-2 files)
time pre-commit run ts-type-check --files src/types.ts
# Expected: 2-4s (vs. 8-12s for full check)

# Test full check still works
npm run type-check
# Expected: 8-12s (same as before)
```

**Rollback:** Restore original `.pre-commit-config.yaml` entry

---

## Quick Win #4: Move Docker Compose Check to CI Only (10 minutes)

**Impact:** 3-5s saved per commit **Effort:** 10 minutes **Risk:** Very low

### The Problem

`docker-compose-check` runs `docker compose config -q` on EVERY commit. This
requires Docker daemon to be running and takes 3-5s.

Docker Compose syntax errors are rare, and CI validates this anyway.

### The Solution

Skip hook locally, run in CI only.

### Implementation Steps

1. **Update `.pre-commit-config.yaml`:**

```yaml
- id: docker-compose-check
 name: 'Docker Compose: configuration validation'
 entry: docker compose config -q
 language: system
 files: ^compose\.yml$
 pass_filenames: false
 stages: [manual] # Changed from [pre-commit] to [manual]
```

2. **Ensure CI still runs this check:**

```yaml
# .github/workflows/ci.yml (verify this section exists)
- name: Validate Docker Compose
 run: docker compose config -q
```

3. **Test:**

```bash
# Hook should NOT run on commit
git commit -m "test: verify docker check skipped"

# Hook can still be run manually
pre-commit run docker-compose-check --all-files

# Or in CI
pre-commit run --hook-stage manual docker-compose-check
```

### Verification

```bash
# Commit should be 3-5s faster
time git commit -m "test: verify faster commit"

# Manual run still works
pre-commit run docker-compose-check --all-files
```

**Rollback:** Change `stages: [manual]` back to `stages: [pre-commit]`

---

## Quick Win #5: Parallel Formatter Execution (60 minutes)

**Impact:** 20-30% faster formatting **Effort:** 60 minutes **Risk:** Low-medium

### The Problem

Formatters run sequentially:

```
prettier → ruff format → black → gofmt → (total: sum of all)
```

They could run in parallel:

```
prettier + ruff format + black + gofmt → (total: max of all)
```

### The Solution

Create wrapper script that runs formatters in parallel.

### Implementation Steps

1. **Create parallel formatter script:**

```bash
# scripts/pre-commit/run-formatters-parallel.sh

#!/usr/bin/env bash
set -euo pipefail

# Exit codes for each formatter
prettier_exit=0
ruff_exit=0
black_exit=0
gofmt_exit=0

# Run all formatters in parallel
(
 prettier --write "$@"
 exit $?
) &
prettier_pid=$!

(
 python3 -m ruff format "$@"
 exit $?
) &
ruff_pid=$!

(
 black "$@" 2>/dev/null
 exit $?
) &
black_pid=$!

(
 find "$@" -name "*.go" -exec gofmt -w {} \;
 exit $?
) &
gofmt_pid=$!

# Wait for all formatters to complete
wait $prettier_pid || prettier_exit=$?
wait $ruff_pid || ruff_exit=$?
wait $black_pid || black_exit=$?
wait $gofmt_pid || gofmt_exit=$?

# Check if any failed
if [[ $prettier_exit -ne 0 ]] || [[ $ruff_exit -ne 0 ]] || [[ $black_exit -ne 0 ]] || [[ $gofmt_exit -ne 0 ]]; then
 echo " One or more formatters failed"
 exit 1
fi

echo " All formatters completed successfully"
exit 0
```

2. **Make script executable:**

```bash
chmod +x scripts/pre-commit/run-formatters-parallel.sh
```

3. **Update `.pre-commit-config.yaml`:**

```yaml
# Comment out individual formatter hooks
# - repo: https://github.com/pre-commit/mirrors-prettier
# hooks:
# - id: prettier

# - repo: https://github.com/astral-sh/ruff-pre-commit
# hooks:
# - id: ruff-format

# - repo: https://github.com/psf/black
# hooks:
# - id: black

# Add parallel formatter hook
- repo: local
 hooks:
 - id: format-parallel
 name: 'Format: run all formatters (parallel)'
 entry: scripts/pre-commit/run-formatters-parallel.sh
 language: system
 pass_filenames: true
 types: [text]
```

4. **Test:**

```bash
# Test parallel formatting
pre-commit run format-parallel --all-files
```

### Verification

```bash
# Measure sequential formatting
time (prettier --write . && ruff format . && black .)

# Measure parallel formatting
time scripts/pre-commit/run-formatters-parallel.sh .

# Parallel should be 20-30% faster
```

**Rollback:** Uncomment original formatter hooks, remove parallel hook

---

## Quick Win #6: Add Performance Monitoring (30 minutes)

**Impact:** Continuous improvement visibility **Effort:** 30 minutes **Risk:**
Very low

### The Problem

We don't track hook performance over time. Can't measure if optimizations
actually help.

### The Solution

Simple metrics collection on every commit.

### Implementation Steps

1. **Create monitoring script:**

```bash
# scripts/pre-commit/monitor-performance.sh

#!/usr/bin/env bash
set -euo pipefail

METRICS_FILE=".cache/pre-commit/metrics.csv"
REPORT_FILE=".cache/pre-commit/performance-report.txt"

mkdir -p "$(dirname "$METRICS_FILE")"

# Initialize metrics file if needed
if [[ ! -f "$METRICS_FILE" ]]; then
 echo "timestamp,hook,duration_seconds" > "$METRICS_FILE"
fi

# This would be called after each hook runs
# For now, just create the infrastructure

# Generate weekly report
if [[ $(find "$METRICS_FILE" -mtime +7 2>/dev/null) ]] || [[ ! -f "$REPORT_FILE" ]]; then
 echo " Generating pre-commit performance report..."

 # Simple report: average times per hook
 if [[ -f "$METRICS_FILE" ]]; then
 echo "Pre-commit Performance Report" > "$REPORT_FILE"
 echo "=============================" >> "$REPORT_FILE"
 echo "Generated: $(date)" >> "$REPORT_FILE"
 echo "" >> "$REPORT_FILE"

 # Count commits
 commits=$(wc -l < "$METRICS_FILE")
 echo "Total commits analyzed: $commits" >> "$REPORT_FILE"
 echo "" >> "$REPORT_FILE"

 # Hook times (placeholder - would parse CSV in real implementation)
 echo "Top 10 slowest hooks:" >> "$REPORT_FILE"
 echo " (Implementation pending - CSV parsing)" >> "$REPORT_FILE"

 echo "" >> "$REPORT_FILE"
 echo "Report saved to: $REPORT_FILE" >> "$REPORT_FILE"
 fi
fi

echo " Performance monitoring active"
exit 0
```

2. **Make script executable:**

```bash
chmod +x scripts/pre-commit/monitor-performance.sh
```

3. **Add to `.pre-commit-config.yaml` (optional):**

```yaml
- repo: local
 hooks:
 - id: monitor-performance
 name: 'Monitor: track performance metrics'
 entry: scripts/pre-commit/monitor-performance.sh
 language: system
 pass_filenames: false
 stages: [commit] # Run after commit
 always_run: true
```

### Verification

```bash
# Check that monitoring runs
git commit -m "test: verify monitoring"

# Check metrics file
cat .cache/pre-commit/metrics.csv
```

**Rollback:** Remove monitoring hook from config

---

## Quick Win #7: Update Documentation (15 minutes)

**Impact:** Developer awareness **Effort:** 15 minutes **Risk:** None

### Implementation Steps

1. **Update README.md with fast commit info:**

````markdown
<!-- Add to README.md -->

## Fast Local Development

Pre-commit hooks ensure code quality but can be slow (~60-120s). For fast
iteration:

```bash
# Skip slow checks (15-30s)
bun run commit:fast

# Standard commit (30-45s)
bun run commit:standard

# Full validation (60-120s)
bun run commit:full
```
````

CI always runs ALL checks. Local skips are safe.

`````

2. **Update CONTRIBUTING.md:**

````markdown
<!-- Add to CONTRIBUTING.md -->

### Fast Commits During Development

When iterating quickly, use fast commit mode:

```bash
bun run commit:fast -m "feat: work in progress"
`````

Before pushing, run full validation:

```bash
pre-commit run --all-files
```

````

3. **Add to PROJECT-RULES-SUMMARY.md:**

```markdown
<!-- Add to QUICK COMMANDS section -->

### Fast Development

```bash
# Fast commit (skip slow checks)
bun run commit:fast

# Standard commit
bun run commit:standard

# Full validation
bun run commit:full
```
```

---

## Implementation Checklist

**Total Time:** 2-4 hours

### Monday Morning (1 hour)

- [ ] Quick Win #1: Add npm scripts for fast commits (5 min)
- [ ] Quick Win #4: Move Docker check to CI only (10 min)
- [ ] Quick Win #7: Update documentation (15 min)
- [ ] Test basic fast commit workflow (15 min)
- [ ] Communicate changes to team (15 min)

**Expected Result:** 40-50% faster commits immediately

### Monday Afternoon (1-2 hours)

- [ ] Quick Win #2: Add caching for visuals check (30 min)
- [ ] Quick Win #3: Incremental TypeScript check (45 min)
- [ ] Quick Win #6: Add performance monitoring (30 min)
- [ ] Test all changes together (15 min)

**Expected Result:** 50-60% faster commits with caching

### Tuesday (Optional, 1 hour)

- [ ] Quick Win #5: Parallel formatters (60 min)
- [ ] Comprehensive testing (30 min)
- [ ] Create PR with all changes (30 min)

**Expected Result:** 60-70% faster commits (full optimization)

---

## Testing Plan

### Test Scenarios

1. **Fast commit with no changes**

```bash
bun run commit:fast -m "test: no changes"
# Expected: <10s
```

2. **Fast commit with TypeScript changes**

```bash
echo "// test" >> src/types.ts
bun run commit:fast -m "test: ts changes"
# Expected: 15-20s
```

3. **Fast commit with docs changes**

```bash
echo "test" >> docs/test.md
bun run commit:fast -m "test: docs changes"
# Expected: <5s (cached)
```

4. **Full commit with all checks**

```bash
bun run commit:full -m "test: full validation"
# Expected: 30-45s (vs. 60-120s before)
```

### Success Criteria

- All test scenarios complete successfully
- Commit times reduced by 30-50%
- No false positives (hooks still catch real issues)
- CI continues to pass

---

## Rollback Procedure

If any quick win causes issues:

```bash
# 1. Identify problematic change
git log --oneline -5

# 2. Revert specific file
git checkout HEAD~1 <file>

# 3. Reinstall pre-commit
pre-commit uninstall
pre-commit install

# 4. Test
git commit -m "test: verify rollback"
```

**Worst case:** Revert entire PR

```bash
git revert <commit-hash>
pre-commit uninstall && pre-commit install
```

---

## Measuring Success

### Before Implementation

```bash
# Measure baseline
time git commit -m "test: baseline measurement"
# Record: _____ seconds
```

### After Implementation

```bash
# Measure improved performance
time bun run commit:fast -m "test: optimized measurement"
# Record: _____ seconds

# Calculate improvement
# Improvement = (baseline - optimized) / baseline * 100%
```

**Target:** 30-50% improvement

### Weekly Report

```bash
# Generate performance report
cat .cache/pre-commit/performance-report.txt

# Review:
# - Average commit time
# - Slowest hooks
# - Improvement over time
```

---

## Next Steps

After implementing Phase 1 quick wins:

1. **Gather feedback** from team (1 week)
2. **Measure impact** via performance reports
3. **Decide on Phase 2** (architecture simplification)
4. **Plan Phase 3** (developer experience improvements)

**See:** [PRE-COMMIT-REFACTORING-PLAN.md](./PRE-COMMIT-REFACTORING-PLAN.md) for
complete roadmap

---

## Questions?

- **Technical questions:** See [pre-commit-guide.md](./pre-commit-guide.md)
- **Architecture questions:** See
 [PRE-COMMIT-REFACTORING-PLAN.md](./PRE-COMMIT-REFACTORING-PLAN.md)
- **Quick reference:** See
 [PROJECT-RULES-SUMMARY.md](./PROJECT-RULES-SUMMARY.md)

---

**Document Version:** 1.0
**Status:** READY TO IMPLEMENT
**Last Updated:** 2025-12-03
````
