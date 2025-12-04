---
title: 'AI Agent Rules - ERNI-KI Project'
language: en
doc_version: '2025.12'
last_updated: '2025-12-03'
---

# AI Agent Rules - ERNI-KI Project

**MANDATORY READING FOR ALL AI ASSISTANTS WORKING ON THIS PROJECT**

This document defines absolute rules that ALL AI agents (Claude, GPT, Copilot,
etc.) MUST follow when working on the ERNI-KI project. Violation of these rules
will result in rejected commits and wasted time.

---

## CRITICAL RULES (ZERO TOLERANCE)

### Rule 1: NO TODO/FIXME in Code

**Status:** BLOCKED BY PRE-COMMIT HOOK

```python
# WRONG - Will be blocked by check-todo-fixme hook
# TODO: refactor this function
# FIXME: handle edge case

# CORRECT - Reference GitHub Issue
# Issue #123: refactor this function
# See: https://github.com/DIZ-admin/erni-ki/issues/123
```

**Rationale:** All tasks MUST be tracked in GitHub Issues, not in code comments.

**Exception:** Only with explicit pragma comment:

```python
# pragma: allowlist todo
# TODO: This is intentionally kept for exceptional reason
```

**Pre-commit Hook:** `check-todo-fixme` will BLOCK your commit if violated.

---

### Rule 2: NO Secrets in Code

**Status:** BLOCKED BY SECURITY SCANNERS

```python
# WRONG - Will be blocked by gitleaks + detect-secrets
API_KEY = "sk-EXAMPLE"  # pragma: allowlist secret
PASSWORD = "example-password"  # pragma: allowlist secret
JWT_SECRET = "example-jwt-secret"  # pragma: allowlist secret

# CORRECT - Use environment variables
import os
API_KEY = os.getenv("API_KEY")
PASSWORD = os.getenv("DATABASE_PASSWORD")
JWT_SECRET = os.getenv("JWT_SECRET")
```

**What is blocked:**

- API keys (OpenAI, AWS, Google, etc.)
- Passwords and credentials
- Private keys (SSH, GPG, SSL)
- JWT secrets
- Database connection strings with passwords
- OAuth tokens

**Where to store secrets:**

- Development: `.env` files (already in `.gitignore`)
- Production: Docker Secrets
- Never: Hardcoded in source code

**Pre-commit Hooks:** `gitleaks` + `detect-secrets` will BLOCK your commit.

---

### Rule 3: Conventional Commits REQUIRED

**Status:** BLOCKED BY COMMITLINT

**Format:**

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Valid Types:**

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `style` - Formatting changes
- `refactor` - Code refactoring
- `perf` - Performance improvement
- `test` - Adding tests
- `chore` - Maintenance tasks
- `ci` - CI/CD changes
- `build` - Build system changes
- `revert` - Revert previous commit

**Examples:**

```bash
# CORRECT
git commit -m "feat(auth): add JWT token validation"
git commit -m "fix(nginx): correct CORS headers for API"
git commit -m "docs: update installation guide"
git commit -m "chore(deps): update dependencies"

# WRONG - Will be rejected by commitlint
git commit -m "added stuff"
git commit -m "fix bug"
git commit -m "Update files"
git commit -m "WIP"
```

**Pre-commit Hook:** `commitlint` (Husky commit-msg hook) will BLOCK invalid
commits.

---

### Rule 4: All CI Checks Must Pass

**Status:** MERGE BLOCKED IF FAILING

Before merging to `main` or `develop`:

- All CI pipeline jobs green
- Security scans passed (CodeQL, Trivy, Gosec)
- Tests passed (Go, TypeScript, Python)
- Type checking passed (TypeScript, mypy)
- Linting passed (ESLint, Ruff, golangci-lint)
- Pre-commit hooks passed
- Code coverage ≥80%

**No exceptions.** If CI fails, fix the issues before requesting review.

---

## MANDATORY PRACTICES

### Language Policy

**Code & Technical Docs: ENGLISH ONLY**

```python
# CORRECT
def calculate_total_price(items: list) -> float:
 """Calculate the total price of items."""
 return sum(item.price for item in items)

# WRONG - Russian/German in code
def вычислить_цену(товары: list) -> float:
 """Вычисляет общую цену."""
 return sum(товар.цена for товар in товары)
```

**User-Facing Docs: Localized (RU/DE/EN)**

User documentation in `docs/` must be localized:

- `docs/ru/` - Russian
- `docs/de/` - German
- `docs/en/` - English

**Pre-commit Hook:** `language-check` validates this policy.

---

### Documentation Metadata

**ALL markdown files in `docs/` MUST have frontmatter:**

```yaml
---
title: 'Document Title'
language: ru # or: en, de
doc_version: '2025.12'
last_updated: '2025-12-03'
---
```

**Optional but recommended:**

```yaml
translation_status: original # or: complete, partial, draft, pending, in_progress
```

**Pre-commit Hook:** `validate-docs-metadata` will BLOCK commits without
metadata.

---

### Branch Strategy

**Branch Naming Convention:**

```bash
# CORRECT
feature/user-authentication
fix/nginx-cors-headers
docs/update-api-reference
ci/improve-build-performance
hotfix/critical-security-issue

# WRONG
my-branch
test
update
fix123
```

**Branch Flow:**

```
main (production, protected)
 ↑
 hotfix/* (emergency fixes from main)

develop (integration, protected)
 ↑
 feature/* (new features)
 fix/* (bug fixes)
 docs/* (documentation)
 ci/* (CI/CD changes)
 refactor/* (code refactoring)
```

**Rules:**

- Base: `develop` (except hotfix which bases on `main`)
- Merge type: Squash merge (clean history)
- Delete branch after merge
- PR required for all merges
- Minimum 1 approval from maintainer
- No direct commits to `main`/`develop`

---

### File and Directory Rules

**NEVER commit these files:**

```bash
# Temporary files
*.tmp
*.bak
*~
.DS_Store
Thumbs.db

# Finder duplicates
"file 2.md"
"image copy.png"
*\ [0-9].* # "file 1.txt", "doc 2.md"

# Environment files
.env
.env.local
.env.production

# Logs
*.log
logs/*

# Cache
.cache/*
*.cache

# IDE files
.vscode/settings.json (user-specific)
.idea/workspace.xml
```

**Pre-commit Hooks:**

- `check-temporary-files` - Blocks temporary files
- `forbid-numbered-copies` - Blocks Finder duplicates
- `check-added-large-files` - Blocks files >500KB

---

### Code Quality Standards

#### Python Code

```python
# Use type hints
def process_data(items: list[dict], threshold: float = 0.5) -> list[str]:
 """Process data items above threshold."""
 return [item["name"] for item in items if item["score"] > threshold]

# Use docstrings
def complex_function(param1: str, param2: int) -> bool:
 """
 Brief description of function.

 Args:
 param1: Description of param1
 param2: Description of param2

 Returns:
 Description of return value
 """
 pass

# Follow Ruff rules
from typing import Optional # Explicit imports

def get_user(user_id: int) -> Optional[User]:
 """Get user by ID."""
 return db.query(User).filter(User.id == user_id).first()
```

**Tools:**

- Linter: `ruff` (replaces flake8, black, isort)
- Type checker: `mypy`
- Formatter: `ruff format` (black-compatible)

#### TypeScript/JavaScript Code

```typescript
// Use TypeScript types
interface User {
  id: number;
  name: string;
  email: string;
}

function getUser(id: number): Promise<User | null> {
  return db.users.findById(id);
}

// Use ESLint rules
const items: Item[] = []; // Explicit typing

// Avoid any
function process(data: any) {} // Bad

// Use proper types
function process(data: unknown) {
  if (isValidData(data)) {
    // Type guard
    // Now TypeScript knows the type
  }
}
```

**Tools:**

- Linter: `eslint` with TypeScript plugin
- Type checker: `tsc --noEmit`
- Formatter: `prettier`

#### Go Code

```go
// Use gofmt formatting
func ProcessData(items []Item, threshold float64) []string {
 result := make([]string, 0)
 for _, item := range items {
 if item.Score > threshold {
 result = append(result, item.Name)
 }
 }
 return result
}

// Use proper error handling
func GetUser(id int) (*User, error) {
 user, err := db.Query(id)
 if err != nil {
 return nil, fmt.Errorf("failed to get user %d: %w", id, err)
 }
 return user, nil
}

// Add comments for exported functions
// ProcessPayment processes a payment transaction and returns the transaction ID.
// It returns an error if the payment fails or if the user has insufficient funds.
func ProcessPayment(userID int, amount float64) (string, error) {
 // Implementation
}
```

**Tools:**

- Formatter: `gofmt` + `goimports`
- Linter: `golangci-lint`
- Security: `gosec`

---

## TOOL-SPECIFIC RULES

### Pre-commit Hooks

**Fast vs Slow Hooks:**

```bash
# Fast local commit (skip slow checks)
SKIP=visuals-and-links-check,typescript-type-check,docker-compose-check git commit

# Or use npm script
bun run commit:fast

# Full validation (all checks)
pre-commit run --all-files

# Or use npm script
bun run commit:full
```

**When to skip slow hooks:**

- During rapid iteration
- For small changes (1-2 files)
- When you know CI will catch issues

**Never skip:**

- Security hooks (gitleaks, detect-secrets)
- TODO/FIXME check
- Basic file checks

**CI always runs ALL hooks** - no skipping in CI.

---

### Testing Requirements

**Unit Tests:**

```typescript
// Test all new functions
describe('calculateTotal', () => {
  it('should sum item prices', () => {
    const items = [{ price: 10 }, { price: 20 }];
    expect(calculateTotal(items)).toBe(30);
  });

  it('should handle empty array', () => {
    expect(calculateTotal([])).toBe(0);
  });

  it('should handle negative prices', () => {
    const items = [{ price: -10 }];
    expect(calculateTotal(items)).toBe(0);
  });
});
```

**Coverage Requirements:**

- Minimum: 80% overall coverage
- New code: 100% coverage for critical paths
- Exceptions: UI components, config files

**Test Commands:**

```bash
# Run all tests
bun test

# Run specific test suites
bun run test:unit
bun run test:e2e
go test ./auth/...

# With coverage
bun run test:unit --coverage
go test -coverprofile=coverage.out ./...
```

---

## AI AGENT SPECIFIC INSTRUCTIONS

### When Writing Code

1. **ALWAYS check for existing patterns first**

```bash
# Search for similar implementations
grep -r "similar_function" .
```

2. **NEVER introduce new dependencies without approval**

- Ask user before adding to `package.json`, `requirements.txt`, `go.mod`
- Explain why the dependency is needed
- Consider alternatives already in the project

3. **FOLLOW the project's code style**

- Read existing code in the same directory
- Match indentation, naming conventions, structure
- Don't introduce new patterns without discussion

4. **WRITE tests for new code**

- Unit tests for all new functions
- Integration tests for API endpoints
- E2E tests for UI changes

5. **UPDATE documentation when changing APIs**

- Update relevant `.md` files in `docs/`
- Update API reference if applicable
- Add/update JSDoc/docstring comments

### When Committing Code

1. **RUN pre-commit checks before committing**

```bash
pre-commit run --all-files
```

2. **WRITE proper commit messages**

- Use conventional commits format
- Be specific about what changed and why
- Reference issue numbers when applicable

3. **SQUASH related commits in PRs**

- Multiple small commits are fine during development
- Will be squashed on merge to main/develop

### When Creating PRs

1. **FILL OUT the PR template completely**

- Describe what changed
- Explain why it changed
- List testing performed
- Note any breaking changes

2. **ENSURE CI is green before requesting review**

- All tests passing
- No linting errors
- No security vulnerabilities

3. **RESPOND to review comments**

- Address all feedback
- Mark conversations as resolved
- Re-request review after changes

### When Reviewing Documentation

1. **CHECK metadata is present**

```yaml
---
title: 'Page Title'
language: en
doc_version: '2025.12'
last_updated: '2025-12-03'
---
```

2. **VERIFY links are valid**

- Internal links use relative paths
- External links are accessible
- No broken references

3. **ENSURE proper language**

- Code docs in English
- User docs localized appropriately

---

## PERFORMANCE OPTIMIZATION RULES

### Pre-commit Performance

**Current optimizations in place:**

1. **Slow hooks are CI-only** (skip locally):

- `visuals-and-links-check` (15-20s)
- `docker-compose-check` (3-5s)
- `markdownlint-cli2` (4-8s)

2. **Use npm scripts for fast commits**:

```bash
bun run commit:fast # Skip slow hooks
bun run commit:full # All hooks
```

3. **Understand hook stages**:

- `pre-commit` - Runs on `git commit`
- `commit-msg` - Validates commit message
- `manual` - Only runs when explicitly called

**When to use which:**

```bash
# Quick iteration (1-2 file changes)
bun run commit:fast

# Medium changes (3-10 files)
git commit # Standard flow

# Before push (full validation)
pre-commit run --all-files

# In CI (always)
pre-commit run --all-files # No skipping
```

---

## SECURITY RULES

### Secret Management

**Development:**

```bash
# 1. Copy example file
cp .env.example .env

# 2. Edit with real values
nano .env

# 3. NEVER commit .env
# (already in .gitignore)
```

**Production:**

```bash
# Use Docker Secrets
docker secret create db_password db_password.txt

# Reference in compose.yml
secrets:
 - db_password
```

**In Code:**

```python
# CORRECT
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("API_KEY")

# WRONG
API_KEY = "sk-EXAMPLE"  # pragma: allowlist secret
```

### File Permissions

**Secret files MUST have 600 permissions:**

```bash
# Set correct permissions
chmod 600 secrets/*
chmod 600 .env*

# Verify
ls -la secrets/
# Should show: -rw------- (600)
```

**Pre-commit Hook:** `check-secret-permissions` validates this.

---

## MONITORING AND METRICS

### CI/CD Metrics

**Current status:**

- 7 CI/CD workflows
- 5 security scanners
- 34 microservices
- 330+ documentation pages

**Success Criteria:**

- All CI jobs pass: GREEN
- Code coverage: ≥80%
- Security vulnerabilities: 0 high/critical
- Build time: <15 minutes

### Pre-commit Metrics

**Current performance:**

- Fast commit: 10-15s (with SKIP)
- Standard commit: 30-45s
- Full validation: 60-120s

**Target after optimization (Phase 1):**

- Fast commit: <10s
- Standard commit: 15-30s
- Full validation: 30-60s

---

## QUICK REFERENCE

### Essential Commands

```bash
# Development
bun install # Install dependencies
bun test # Run tests
bun run lint # Run linters
bun run type-check # TypeScript check

# Pre-commit
pre-commit run # Run on staged files
pre-commit run --all-files # Run on all files
bun run commit:fast # Fast commit (skip slow hooks)

# Git
git checkout -b feature/my-feature # Create feature branch
git commit -m "feat: add feature" # Commit with conventional message
git push origin feature/my-feature # Push to remote

# Docker
docker compose up -d # Start all services
docker compose ps # Check status
docker compose logs -f # View logs
docker compose down # Stop all services
```

### Quick Checks Before Committing

```bash
# 1. Run linters
bun run lint

# 2. Run tests
bun test

# 3. Check types
bun run type-check

# 4. Run pre-commit (fast)
bun run commit:fast

# 5. Commit
git commit -m "feat(scope): description"
```

---

## TROUBLESHOOTING

### Pre-commit Hook Fails

```bash
# 1. Check what failed
git commit -v

# 2. Fix the issue
# (address the error message)

# 3. Re-stage fixed files
git add <fixed-files>

# 4. Try again
git commit
```

### CI Pipeline Fails

```bash
# 1. Check CI logs
gh pr checks # View PR checks

# 2. Run locally
bun run lint
bun test
pre-commit run --all-files

# 3. Fix and push
git add .
git commit -m "fix: address CI failures"
git push
```

### Merge Conflicts

```bash
# 1. Update your branch
git fetch origin
git merge origin/develop

# 2. Resolve conflicts
# (edit conflicted files)

# 3. Mark resolved
git add <resolved-files>

# 4. Complete merge
git commit
```

---

## DOCUMENTATION REFERENCES

**Must Read:**

- [PROJECT-RULES-SUMMARY.md](docs/development/PROJECT-RULES-SUMMARY.md) - Quick
  reference
- [pre-commit-guide.md](docs/development/pre-commit-guide.md) - Pre-commit
  details
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

**Refactoring Plans:**

- [PRE-COMMIT-REFACTORING-PLAN.md](docs/development/PRE-COMMIT-REFACTORING-PLAN.md) -
  Full plan
- [PHASE1-QUICK-WINS.md](docs/development/PHASE1-QUICK-WINS.md) - Quick wins

**Navigation:**

- [PRE-COMMIT-INDEX.md](docs/development/PRE-COMMIT-INDEX.md) - Documentation
  index
- [PRE-COMMIT-REFACTORING-INDEX.md](PRE-COMMIT-REFACTORING-INDEX.md) -
  Refactoring index

---

## CHECKLIST FOR AI AGENTS

Before submitting code, verify:

### Code Quality

- [ ] No TODO/FIXME in code (use Issue references)
- [ ] No hardcoded secrets
- [ ] Code follows project style
- [ ] Tests written for new code
- [ ] Documentation updated

### Commits

- [ ] Conventional commit message
- [ ] Pre-commit hooks passed
- [ ] Meaningful commit description
- [ ] Related commits squashed

### Testing

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass (if applicable)
- [ ] Code coverage ≥80%

### Documentation

- [ ] Frontmatter metadata present
- [ ] Links are valid
- [ ] Language policy followed
- [ ] API docs updated (if applicable)

### CI/CD

- [ ] All CI checks green
- [ ] No security vulnerabilities
- [ ] No linting errors
- [ ] Build succeeds

---

## LEARNING RESOURCES

### Internal

- [Project Rules Summary](docs/development/PROJECT-RULES-SUMMARY.md)
- [Pre-commit Guide](docs/development/pre-commit-guide.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)

### External

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Pre-commit Framework](https://pre-commit.com/)
- [Semantic Versioning](https://semver.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)

---

## GETTING HELP

**Questions about:**

- Rules: Read
  [PROJECT-RULES-SUMMARY.md](docs/development/PROJECT-RULES-SUMMARY.md)
- Pre-commit: Read [pre-commit-guide.md](docs/development/pre-commit-guide.md)
- Contributing: Read [CONTRIBUTING.md](CONTRIBUTING.md)
- Security: Read [SECURITY.md](SECURITY.md)

**Still need help:**

- GitHub Issues: https://github.com/DIZ-admin/erni-ki/issues
- GitHub Discussions: https://github.com/DIZ-admin/erni-ki/discussions

---

## RULE ENFORCEMENT

**Enforcement Level:**

| Rule                 | Enforcement       | Blocker |
| -------------------- | ----------------- | ------- |
| NO TODO/FIXME        | Pre-commit hook   | YES     |
| NO Secrets           | Pre-commit hook   | YES     |
| Conventional Commits | Commit-msg hook   | YES     |
| All CI Green         | Branch protection | YES     |
| Code Coverage ≥80%   | CI check          | WARNING |
| Documentation        | CI check          | WARNING |
| Language Policy      | Pre-commit hook   | YES     |

**Legend:**

- YES - Hard blocker, cannot proceed
- WARNING - Soft blocker, should fix but can proceed
- ℹ INFO - Informational, best practice

---

## VERSION HISTORY

| Version | Date       | Changes                         |
| ------- | ---------- | ------------------------------- |
| 1.0     | 2025-12-03 | Initial AI Agent Rules document |

---

**Document Version:** 1.0 **Status:** MANDATORY FOR ALL AI AGENTS **Last
Updated:** 2025-12-03 **Maintained By:** ERNI-KI Team

---

**IMPORTANT: This document supersedes general AI assistant behavior. When
working on ERNI-KI, these rules MUST be followed without exception.**
