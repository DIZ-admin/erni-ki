---
title: 'ERNI-KI Rules & Workflow Flowchart'
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# ERNI-KI Rules & Workflow Flowchart

Visual representation of project rules and commit workflow

---

## Complete Commit Workflow

```

 START: New Task




 Create GitHub
 Issue #XXX




 Create Branch
 feature/xxx




 Write Code
 (NO TODO/FIXME!)




 Write Tests
 (mandatory)




 Update Docs
 (if needed)




 git add files




 git commit -m "feat: ..."
 (Conventional Commits!)




 HUSKY PRE-COMMIT


 Language Check (bun run lint:language)
 English code / Localized docs

 Lint-staged
 *.{js,ts} → ESLint + Prettier
 *.py → Ruff + format
 *.{json,yaml,md} → Prettier + language
 *.go → gofmt + goimports
 *.toml → language check



 PYTHON PRE-COMMIT FRAMEWORK


 Basic Checks
 Trailing whitespace
 EOF newline
 Large files (>500KB)
 Merge conflicts
 Case conflicts

 Validation
 YAML syntax
 JSON syntax
 TOML syntax

 Formatting
 Prettier (md/yaml/json/js/ts)
 Black (Python)
 isort (Python imports)
 gofmt (Go)

 Security
 Gitleaks (secrets)
 detect-secrets
 Secret permissions

 Code Quality
 ESLint (JS/TS)
 Ruff (Python)
 mypy (Python types)
 shellcheck (bash)
 TypeScript type-check

 CRITICAL CHECKS
 TODO/FIXME detector BLOCKS!
 Temporary files BLOCKS!
 Numbered copies BLOCKS!

 Documentation
 Metadata validation
 Status snippet sync
 Markdownlint
 Links/TOC check
 No emoji check
 Archive README coverage



 ALL HOOKS PASSED?


 YES → Continue

 NO → COMMIT BLOCKED
 Fix issues & retry



 HUSKY COMMIT-MSG HOOK


 Commitlint
 Conventional format?
 Valid type?
 Valid scope?
 Subject format?
 Max length (100)?



 COMMIT SUCCESS




 git push origin feature/xxx




 GITHUB CI/CD CHECKS


 Lint (ESLint/Ruff/Go)
 Test (Vitest/Playwright/Go test)
 Type check (TypeScript/mypy)
 Security (CodeQL/Trivy)
 Build validation
 Coverage check



 CREATE PULL REQUEST
 to develop branch




 CODE REVIEW


 Minimum 1 approval
 All comments resolved
 CI checks green
 No conflicts



 SQUASH MERGE TO DEVELOP




 DELETE FEATURE BRANCH




 TASK COMPLETE
 Close GitHub Issue #XXX

```

---

## Decision Trees

### Should I Create a TODO Comment?

```

 Need to track
 future work?




 YES NO



 Create GitHub Don't add
 Issue comment




 Reference in
 code comment:
 Issue #XXX


Example:
# Issue #123: refactor this function
def old_function():
 pass
```

### Should I Skip Pre-commit Hooks?

```

 Need to skip
 hooks?




 EMERGENCY? ROUTINE



 Production Fix issues
 down? Critical instead of
 security flaw? skipping




 YES NO



 --no-verify Fix issues
 OK (document properly
 in commit msg)

Example emergency:
git commit --no-verify -m "fix: critical production auth bypass (emergency hotfix)"
```

### Which Branch Should I Use?

```

 What type of
 work?




 NEW FEATURE BUG FIX PRODUCTION
 EMERGENCY


 feature/name fix/name
 hotfix/name
 Base: develop Base: develop
 PR → develop PR → develop Base: main
 PR → main
 Back-merge
 to develop

```

---

## Hook Priority Matrix

### Critical (Always Run, Fast)

```
Priority: CRITICAL | Speed: FAST | Can Skip: NO

check-todo-fixme → Blocks TODO/FIXME
gitleaks → Blocks secrets
detect-secrets → Blocks secrets (backup)
check-merge-conflict → Blocks merge markers
commitlint → Blocks bad commit messages
```

### Important (Always Run, Fast)

```
Priority: [WARNING] HIGH | Speed: FAST | Can Skip: NO

trailing-whitespace → Auto-fixes whitespace
end-of-file-fixer → Auto-fixes EOF
check-added-large-files → Blocks files >500KB
prettier → Auto-formats code
eslint → Auto-fixes lint issues
ruff → Auto-fixes Python issues
```

### Validation (Always Run, Medium Speed)

```
Priority: [OK] MEDIUM | Speed: MEDIUM | Can Skip: MAYBE

check-yaml → Validates YAML syntax
check-json → Validates JSON syntax
mypy → Python type checking
typescript-type-check → TS type checking
shellcheck → Bash validation
```

### Documentation (Slow, Can Skip Locally)

```
Priority: LOW | Speed: SLOW | Can Skip: YES (locally)

visuals-and-links-check → Checks doc links/TOC
markdownlint-cli2 → Markdown linting
validate-docs-metadata → Frontmatter validation
status-snippet-check → Status sync check

Skip with:
SKIP="visuals-and-links-check,markdownlint-cli2" pre-commit run
```

---

## Security Threat Model

```

 SECURITY LAYERS

Layer 1: Pre-commit (Local)
 gitleaks → API keys, passwords, tokens
 detect-secrets → Backup secret detection
 check-secret-perm → File permissions (600)

 BLOCKS commit if secrets found
 Prevents accidental exposure

Layer 2: Git (Version Control)
 .gitignore → Excludes .env, secrets/
 .secrets.baseline → Allowlist for false positives

 Prevents secrets from entering repo

Layer 3: CI/CD (GitHub Actions)
 CodeQL → Security vulnerabilities
 Trivy → Container scanning
 Dependency audit → Vulnerable packages

 Catches issues before merge

Layer 4: Runtime (Docker)
 Docker Secrets → Encrypted secret storage
 .env files → Development secrets
 Vault (planned) → Production secret management

 Secure secret access at runtime

Layer 5: Infrastructure
 Cloudflare Zero Trust → Network security
 Nginx WAF → Web application firewall
 TLS 1.2/1.3 → Encrypted communication
```

---

## Language Policy Diagram

```

 FILE TYPE → LANGUAGE MAPPING

Source Code (.py, .ts, .js, .go)
 English ONLY
 Variable names: English
 Function names: English
 Comments: English
 Docstrings: English

Configuration (.yaml, .toml, .json, .env)
 English ONLY
 Keys: English
 Comments: English
 Documentation strings: English

Commit Messages
 English ONLY
 Type: English (feat, fix, docs)
 Scope: English
 Subject: English

Pull Requests
 English ONLY
 Title: English
 Description: English
 Comments: English

Documentation (docs/*.md)
 Localized by Folder
 docs/ru/ → Russian
 docs/de/ → German
 docs/en/ → English
 Root docs/ → Russian (primary)

README Files
 Localized
 README.md → Russian
 README.en.md → English
 README.de.md → German

Validation:
 bun run lint:language
 Checks all files
 Blocks commit if violations
```

---

## Conventional Commits Decision Tree

```
What did you change?

 New feature
 feat: add user authentication

 Bug fix
 fix: correct JWT token validation

 Documentation
 docs: update API reference

 Code style/formatting
 style: fix indentation in auth.go

 Refactoring
 refactor: simplify token validation logic

 Performance improvement
 perf: optimize database queries

 Test addition
 test: add JWT validation tests

 Build/tooling
 chore: update pre-commit hooks

 CI/CD
 ci: add CodeQL security scanning

 Dependency update
 deps: upgrade eslint to 9.15.0

 Configuration
 config: update Docker Compose limits

 Security fix
 security: patch auth bypass vulnerability

 Deployment
 deploy: add production environment config

Format: <type>(<scope>): <description>
Example: feat(auth): add JWT token refresh endpoint
```

---

## Status Snippet Update Flow

```

 STATUS SNIPPET UPDATE WORKFLOW

Source of Truth: docs/reference/status.yml

 Edit version numbers
 Edit service counts
 Edit dashboard counts
 Edit alert counts


Run: python3 scripts/docs/update_status_snippet.py

 Reads status.yml
 Generates snippets
 Updates files:

 README.md
 docs/index.md
 docs/overview.md
 docs/reference/status-snippet.md
 docs/de/reference/status-snippet.md


Pre-commit hook: status-snippet-check

 Validates all snippets are synced

 YES → Commit allowed
 NO → Commit blocked
 Run update script again
```

---

## Version

**Document Version:** 1.0 **Last Updated:** 2025-12-03 **Author:** ERNI-KI
Technical Team **Status:** FINAL
