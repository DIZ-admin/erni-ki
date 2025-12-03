# Bun Migration - Execution Checklist

**Total Time:** 2-3 hours | **Date:** 2025-12-03

**Full Details:**
[.claude/plans/bun-migration-plan.md](.claude/plans/bun-migration-plan.md)

---

## Pre-Flight Checks

```bash
# Create backup
git checkout -b backup/pre-bun-migration && git push -u origin backup/pre-bun-migration
git checkout experiment/bun-evaluation
cp package-lock.json package-lock.json.backup
tar -czf .husky-backup.tar.gz .husky/

# Verify Bun
bun --version # Should show 1.3.3+

# Clean working directory
git status
```

**Checklist:**

- [ ] Backup branch created
- [ ] Bun version ≥ 1.3.3
- [ ] Working directory clean

---

## Phase 1: Core Migration (15-20 min)

```bash
# Remove npm artifacts
rm package-lock.json .nvmrc
```

**Edit `package.json`:**

- [ ] **Line 38-41:** Change `engines` to `{"bun": ">=1.3.0"}`
- [ ] **Line 166:** Change `packageManager` to `"bun@1.3.3"`
- [ ] **Line 162-165:** DELETE `volta` section

**Edit `bunfig.toml`** - Add:

```toml
[install]
lockfileFormat = "binary"
autoInstallPeers = true
frozenLockfile = false

[run]
shell = "bun"
autoInstall = false
```

```bash
# Install with Bun
bun install

# Verify
bun run type-check
```

- [ ] `bun install` completed (633 packages ~1.88s)
- [ ] `bun.lock` created
- [ ] Type check passes

---

## Phase 2: Script Updates (25-30 min)

**Edit `package.json` scripts section (lines 42-81):**

Replace these lines:

- [ ] **Line 44:** `"test": "bun run test:unit && bun run test:e2e:mock"`
- [ ] **Line 52:** `"lint": "bun run lint:js && bun run lint:py"`
- [ ] **Line 57:** `"lint:fix": "bun run lint:js:fix && bun run lint:py:fix"`
- [ ] **Line 62:** `"lint:language": "bun run scripts/language-check.cjs"`
- [ ] **Line 63:**
      `"lint:language:all": "bun run scripts/language-check.cjs --all"`
- [ ] **Line 70:** `"security:scan": "bun audit && docker run..."`
- [ ] **Line 78:** `"postinstall": "bun run prepare"`

**Edit lint-staged (line 121):**

- [ ] Change `npm run lint:language` → `bun run lint:language`

**Edit `scripts/prettier-run.sh` (line 55):**

```bash
# Change from:
xargs -0 npx "${CMD_ARGS[@]}" <"$tmpfile"

# To:
xargs -0 bunx "${CMD_ARGS[@]}" <"$tmpfile"
```

**Edit `scripts/run-playwright-mock.sh`:**

- [ ] **Line 18:** `node` → `bun run`
- [ ] **Line 31:** `npx` → `bunx`

```bash
# Verify
bun run lint:language
bun run format:check
```

- [ ] Scripts execute successfully

---

## Phase 3: Git Hooks 🪝 (15-20 min)

**Edit `.husky/pre-commit`:**

```bash
#!/usr/bin/env sh

# Проверка языковых правил перед lint-staged и коммитом
bun run lint:language
bunx lint-staged
```

**Edit `.husky/commit-msg`:**

```bash
#!/usr/bin/env sh

# Валидация commit message с помощью commitlint
bunx --bun commitlint --edit "$1"
```

```bash
# Make executable and reinstall
chmod +x .husky/pre-commit .husky/commit-msg
bun run prepare

# Test
echo "test: sample commit" | bunx commitlint
```

- [ ] Hooks updated
- [ ] Hooks executable
- [ ] Commitlint test passes

---

## Phase 4: Testing & Validation (30-40 min)

```bash
# Unit tests
bun run test:unit
# Expected: 81 tests passed

# E2E tests
bun run test:e2e:mock

# Linting
bun run lint:js
bun run format:check
bun run type-check
bun run lint:language

# Test git hooks
git add bunfig.toml
git commit -m "test(config): verify hooks" --dry-run

# Clean install test
rm -rf node_modules/ bun.lock
bun install
bun run test:unit
```

**Checklist:**

- [ ] 81/81 unit tests pass
- [ ] E2E tests pass
- [ ] Linting passes
- [ ] Formatting OK
- [ ] Type check passes
- [ ] Git hooks work
- [ ] Clean install works

---

## Phase 5: Cleanup (15-20 min)

```bash
# Remove backups (only after all tests pass!)
rm package-lock.json.backup .husky-backup.tar.gz
```

**Edit `.gitignore` - add after line 43:**

```gitignore
# Bun
bun.lockb
.bun/
package-lock.json
```

**Edit `.prettierignore` - add after line 46:**

```
bun.lock
bun.lockb
```

**Update `docs/development/setup-guide.md`:**

- [ ] Replace Node.js/npm installation with Bun
- [ ] Update "Install Dependencies" section
- [ ] Update verification steps

**Create `docs/development/bun-migration.md`:**

- [ ] Copy template from migration plan
- [ ] Add project-specific notes

```bash
# Verify
bun run format:check
```

- [ ] Documentation updated
- [ ] Format check passes

---

## Phase 6: Final Validation & Commit (20-25 min)

```bash
# Complete test suite
bun run test

# Full lint check
bun run lint
bun run format:check
bun run type-check

# Final clean install
rm -rf node_modules/ bun.lock
bun install
bun run test:unit

# Commit migration
git add .
git commit -m "chore(deps): migrate from npm to bun

- Replace npm with Bun as primary package manager
- Update all scripts to use bun/bunx
- Migrate Husky git hooks to Bun
- Update prettier-run.sh and run-playwright-mock.sh
- Update documentation for Bun usage
- Remove npm-specific config (volta, .nvmrc)

BREAKING CHANGE: Requires Bun 1.3.0+

Performance improvements:
- 3.5-4.4x faster package installation
- Native TypeScript execution
- Lower memory usage"

# Verify commit
git log -1 --stat
git diff HEAD~1 --name-status
```

**Expected files changed:**

```
M .gitignore
M .husky/commit-msg
M .husky/pre-commit
M .prettierignore
D .nvmrc
M bunfig.toml
A bun.lock
D package-lock.json
M package.json
M scripts/prettier-run.sh
M scripts/run-playwright-mock.sh
M docs/development/setup-guide.md
A docs/development/bun-migration.md
```

- [ ] All tests pass
- [ ] Clean install works
- [ ] Commit created
- [ ] Expected files changed

---

## Migration Complete!

**Success Criteria:**

- All 81 unit tests pass
- All E2E tests pass
- No linting errors
- Git hooks functional
- 3-4x faster installs
- Documentation updated

---

## Rollback (if needed) ⏪

**Quick Rollback:**

```bash
git restore package-lock.json.backup
mv package-lock.json.backup package-lock.json
npm ci
tar -xzf .husky-backup.tar.gz
npm run test:unit
```

**Full Rollback:**

```bash
git reset --hard HEAD
npm ci
npm run test
```

---

## Post-Migration Tasks

**Week 1:**

- [ ] Monitor Bun performance
- [ ] Team training session (30 min)
- [ ] Update team communication
- [ ] Collect feedback

**Month 1:**

- [ ] Review team experience
- [ ] Update troubleshooting docs
- [ ] Evaluate CI/CD migration readiness

**Q1 2026:**

- [ ] Plan CI/CD migration to Bun
- [ ] Consider converting .cjs to .ts
- [ ] Explore Bun-native features

---

**Ready to execute?** Start with Phase 1!

**Need help?** See
[.claude/plans/bun-migration-plan.md](.claude/plans/bun-migration-plan.md)
