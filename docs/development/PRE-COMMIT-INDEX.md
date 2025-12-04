---
title: 'Pre-commit Documentation - Index'
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# Pre-commit Documentation - Navigation Index

**Central index** for all pre-commit related documentation

---

## Quick Access

### For New Contributors

**Start here:**

1. [Project Rules Summary](./PROJECT-RULES-SUMMARY.md) - **MUST READ** -
   Critical rules (10 min)
2. [Pre-commit Guide](./pre-commit-guide.md) - Complete technical guide (30 min)
3. [Rules Flowchart](./RULES-FLOWCHART.md) - Visual workflows and decision trees

### For Existing Developers

**Daily reference:**

- [Project Rules Summary](./PROJECT-RULES-SUMMARY.md) - Quick reference for
  common tasks
- [Pre-commit Guide](./pre-commit-guide.md) - Troubleshooting and advanced usage

### For Maintainers

**Planning and optimization:**

- [Refactoring Plan](./PRE-COMMIT-REFACTORING-PLAN.md) - Comprehensive 3-phase
  optimization plan
- [Refactoring Summary](./REFACTORING-SUMMARY.md) - Executive summary for
  decision-makers

---

## Document Descriptions

### [PROJECT-RULES-SUMMARY.md](./PROJECT-RULES-SUMMARY.md)

**Audience:** All developers **Reading Time:** 10 minutes **Purpose:** Quick
reference for critical project rules

**Contains:**

- Zero-tolerance rules (TODO/FIXME, secrets, conventional commits)
- Branch strategy and code review requirements
- Quick commands for common tasks
- Emergency procedures
- Commit workflow checklist

**When to read:**

- First day as contributor
- Before creating first commit
- When confused about project rules
- As refresher (bookmark it!)

---

### [pre-commit-guide.md](./pre-commit-guide.md)

**Audience:** All developers **Reading Time:** 30 minutes (reference document)
**Purpose:** Complete technical guide to pre-commit system

**Contains:**

- Installation and setup instructions
- All 30+ hooks explained in detail
- Lint-staged configuration
- Commitlint rules
- Troubleshooting guide
- Performance optimization tips
- SKIP environment variable usage

**When to read:**

- During onboarding
- When hook fails and you need to understand why
- When adding new hooks
- When optimizing pre-commit performance

---

### [RULES-FLOWCHART.md](./RULES-FLOWCHART.md)

**Audience:** All developers **Reading Time:** 15 minutes **Purpose:** Visual
workflows and decision trees

**Contains:**

- Complete commit workflow diagram
- Pre-commit execution flow
- Decision tree: "Can I commit this?"
- Hook priority matrix
- Security threat model
- Branch strategy flowchart

**When to read:**

- When learning commit workflow
- When unsure if commit will pass
- When debugging hook failures
- As visual reference

---

### [PRE-COMMIT-REFACTORING-PLAN.md](./PRE-COMMIT-REFACTORING-PLAN.md)

**Audience:** Tech leads, senior developers, maintainers **Reading Time:** 60
minutes **Purpose:** Comprehensive optimization and refactoring plan

**Contains:**

- Performance analysis (current vs. optimized)
- 3-phase refactoring strategy
- Implementation roadmap (3 weeks)
- Migration guide
- Risk assessment and mitigation
- Success metrics and monitoring
- Complete technical specifications

**When to read:**

- Before planning pre-commit improvements
- When evaluating optimization proposals
- Before implementing changes
- For architecture decisions

---

### [REFACTORING-SUMMARY.md](./REFACTORING-SUMMARY.md)

**Audience:** Decision-makers, team leads, stakeholders **Reading Time:** 10
minutes **Purpose:** Executive summary of refactoring plan

**Contains:**

- Problem statement (why refactor?)
- Proposed solution (3 phases)
- Benefits and ROI
- Investment required
- Success metrics
- Risk analysis
- Approval process

**When to read:**

- Before approving refactoring work
- For high-level overview
- When presenting to stakeholders
- For decision-making

---

## Document Relationships

```
PROJECT-RULES-SUMMARY.md

 → Daily Reference

pre-commit-guide.md

 → Technical Details

RULES-FLOWCHART.md

PRE-COMMIT-REFACTORING-PLAN.md

 → Planning & Optimization

REFACTORING-SUMMARY.md
```

---

## By Use Case

### I'm new to the project

**Read in order:**

1. [PROJECT-RULES-SUMMARY.md](./PROJECT-RULES-SUMMARY.md) - Learn critical rules
   (10 min)
2. [RULES-FLOWCHART.md](./RULES-FLOWCHART.md) - Understand workflows (15 min)
3. [pre-commit-guide.md](./pre-commit-guide.md) - Setup and detailed guide (30
   min)

**Total time:** 55 minutes (one-time investment)

### I need to commit code

**Quick reference:**

1. Check: [PROJECT-RULES-SUMMARY.md](./PROJECT-RULES-SUMMARY.md) → "QUICK
   COMMANDS" section
2. If hook fails: [pre-commit-guide.md](./pre-commit-guide.md) →
   "Troubleshooting" section
3. If unsure: [RULES-FLOWCHART.md](./RULES-FLOWCHART.md) → "Can I commit this?"
   decision tree

### Pre-commit is too slow

**Steps:**

1. Read: [pre-commit-guide.md](./pre-commit-guide.md) → "Performance Tips"
   section
2. Review: [PRE-COMMIT-REFACTORING-PLAN.md](./PRE-COMMIT-REFACTORING-PLAN.md) →
   "Phase 1: Performance Optimization"
3. Quick wins: Use `SKIP` environment variable for slow hooks

**Example:**

```bash
SKIP=visuals-and-links-check,typescript-type-check git commit
```

### I'm planning improvements

**Read in order:**

1. [PRE-COMMIT-REFACTORING-PLAN.md](./PRE-COMMIT-REFACTORING-PLAN.md) - Full
   technical plan (60 min)
2. [REFACTORING-SUMMARY.md](./REFACTORING-SUMMARY.md) - Executive summary (10
   min)
3. Current state: [pre-commit-guide.md](./pre-commit-guide.md) - Understand
   existing system

### I need to approve refactoring work

**Quick path:**

1. [REFACTORING-SUMMARY.md](./REFACTORING-SUMMARY.md) - Executive overview (10
   min)
2. [PRE-COMMIT-REFACTORING-PLAN.md](./PRE-COMMIT-REFACTORING-PLAN.md) → "Risk
   Analysis" section (5 min)
3. Review timeline and resources

---

## External References

### Official Documentation

- [Pre-commit Framework](https://pre-commit.com/) - Official pre-commit docs
- [Conventional Commits](https://www.conventionalcommits.org/) - Commit message
  format
- [Commitlint](https://commitlint.js.org/) - Commit message linting
- lint-staged (removed) - Husky now runs `pre-commit` directly files

### Tool Documentation

- [Ruff](https://docs.astral.sh/ruff/) - Python linter and formatter
- [ESLint](https://eslint.org/) - JavaScript/TypeScript linter
- [Prettier](https://prettier.io/) - Code formatter
- [Gitleaks](https://github.com/gitleaks/gitleaks) - Secret detection
- [ShellCheck](https://www.shellcheck.net/) - Shell script linting

### Best Practices

- [Git Hooks Best Practices](https://www.atlassian.com/git/tutorials/git-hooks) -
  Atlassian guide
- [GitFlow Branching Model](https://nvie.com/posts/a-successful-git-branching-model/) -
  Branch strategy
- [Semantic Versioning](https://semver.org/) - Version numbering

---

## Quick Commands Reference

### Setup

```bash
# Install pre-commit hooks
source .venv/bin/activate
pre-commit install
pre-commit install --hook-type commit-msg

# Verify installation
pre-commit --version
```

### Daily Usage

```bash
# Run pre-commit on staged files
pre-commit run

# Run all hooks on all files
pre-commit run --all-files

# Skip specific hooks
SKIP=hook1,hook2 git commit

# Fast commit (skip slow hooks)
SKIP=visuals-and-links-check,typescript-type-check git commit
```

### Troubleshooting

```bash
# Update hooks to latest versions
pre-commit autoupdate

# Clear cache and retry
pre-commit clean
pre-commit run --all-files

# Run specific hook only
pre-commit run <hook-id>

# Run hook on specific files
pre-commit run <hook-id> --files path/to/file
```

### Maintenance

```bash
# Check hook versions
pre-commit run --show-diff-on-failure

# Validate configuration
pre-commit validate-config

# Uninstall and reinstall
pre-commit uninstall
pre-commit install
```

---

## File Locations

### Configuration Files

| File                      | Purpose                             | Language |
| ------------------------- | ----------------------------------- | -------- |
| `.pre-commit-config.yaml` | Python pre-commit hooks             | YAML     |
| `.husky/pre-commit`       | Husky pre-commit script             | Shell    |
| `.husky/commit-msg`       | Husky commit-msg script             | Shell    |
| `commitlint.config.cjs`   | Commit message validation           | JS       |
| `package.json`            | pre-commit scripts (fast/full/perf) | JSON     |
| `eslint.config.js`        | ESLint configuration                | JS       |
| `ruff.toml`               | Ruff configuration (Python)         | TOML     |
| `mypy.ini`                | mypy configuration (Python)         | INI      |
| `.secrets.baseline`       | detect-secrets baseline             | JSON     |
| `.gitleaksignore`         | Gitleaks ignore patterns            | Text     |

### Scripts

| Script                                             | Purpose                    |
| -------------------------------------------------- | -------------------------- |
| `scripts/language-check.cjs`                       | Language policy validation |
| `scripts/maintenance/check_duplicate_basenames.py` | Duplicate filename check   |
| `scripts/docs/update_status_snippet.py`            | Status snippet validation  |
| `scripts/docs/check_archive_readmes.py`            | Archive README coverage    |
| `scripts/docs/visuals_and_links_check.py`          | Docs validation (slow)     |
| `scripts/docs/validate_metadata.py`                | Docs metadata validation   |
| `scripts/validate-no-emoji.py`                     | Emoji detection            |
| `scripts/security/check-secret-permissions.sh`     | Secret file permissions    |

---

## Contribution Guidelines

### Adding New Hooks

1. **Determine category** (Basic checks, Python, Go, Security, etc.)
2. **Add to `.pre-commit-config.yaml`** in appropriate section
3. **Test locally:**

```bash
pre-commit run <hook-id> --all-files
```

4. **Update documentation:**

- Add to [pre-commit-guide.md](./pre-commit-guide.md)
- Add to [PROJECT-RULES-SUMMARY.md](./PROJECT-RULES-SUMMARY.md) if critical

5. **Create PR** with description and rationale

### Modifying Existing Hooks

1. **Understand current behavior** (read
   [pre-commit-guide.md](./pre-commit-guide.md))
2. **Make changes** to `.pre-commit-config.yaml`
3. **Test thoroughly:**

```bash
pre-commit run --all-files
```

4. **Update documentation** if behavior changed
5. **Create PR** with clear explanation of changes

### Optimizing Performance

1. **Measure baseline:**

```bash
time git commit -m "test: benchmark"
```

2. **Implement optimization** (see
   [PRE-COMMIT-REFACTORING-PLAN.md](./PRE-COMMIT-REFACTORING-PLAN.md))
3. **Measure improvement:**

```bash
time git commit -m "test: benchmark"
```

4. **Document results** in PR description

---

## Getting Help

### Common Issues

**Issue:** Pre-commit hooks not running

```bash
# Solution: Reinstall hooks
pre-commit uninstall
pre-commit install
pre-commit install --hook-type commit-msg
```

**Issue:** Hook fails with unclear error

```bash
# Solution: Run with verbose output
pre-commit run <hook-id> --verbose --all-files
```

**Issue:** Pre-commit is too slow

```bash
# Solution: Skip slow hooks temporarily
SKIP=visuals-and-links-check,typescript-type-check git commit
```

**Issue:** Hook conflicts after update

```bash
# Solution: Clear cache and retry
pre-commit clean
pre-commit autoupdate
pre-commit run --all-files
```

### Support Channels

- **Documentation:** This index and linked documents
- **GitHub Issues:** https://github.com/DIZ-admin/erni-ki/issues
- **Team Chat:** Slack/Discord/Teams channel
- **Code Review:** PR comments and discussions

---

## Version History

| Version | Date       | Changes                             |
| ------- | ---------- | ----------------------------------- |
| 1.0     | 2025-12-03 | Initial index with 5 core documents |

---

**Last Updated:** 2025-12-03 **Maintained By:** ERNI-KI Team **Status:**
OFFICIAL PROJECT DOCUMENTATION
