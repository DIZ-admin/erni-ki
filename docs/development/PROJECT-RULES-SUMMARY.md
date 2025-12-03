---
title: 'ERNI-KI Project Rules - Quick Reference'
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# ERNI-KI Project Rules - Quick Reference

**Для разработчиков:** Обязательные к прочтению правила проекта

---

## КРИТИЧЕСКИЕ ПРАВИЛА (Zero Tolerance)

### 1. NO TODO/FIXME в коде

**Правило:** `check-todo-fixme` hook **БЛОКИРУЕТ** коммиты с TODO/FIXME

**Почему:** Все задачи должны быть в GitHub Issues, не в комментариях

**Что делать:**

```python
# БЛОКИРУЕТСЯ
# TODO: refactor this function

# ПРАВИЛЬНО
# Issue #123: refactor this function
```

**Исключение:** `# pragma: allowlist todo` (только для exceptional cases)

---

### 2. NO Secrets в коде

**Правило:** `gitleaks` + `detect-secrets` **БЛОКИРУЮТ** коммиты с секретами

**Что ищется:**

- API keys
- Passwords
- Private keys
- AWS credentials
- GitHub tokens
- JWT secrets

**Где хранить:**

- Development: `.env` файлы (в `.gitignore`)
- Production: Docker Secrets
- Never: hardcoded в коде

---

### 3. Conventional Commits (обязательно)

**Правило:** `commitlint` валидирует каждое commit message

**Формат:**

```
<type>(<scope>): <subject>
```

**Type (обязательно):**

- `feat` - новая функция
- `fix` - исправление бага
- `docs` - документация
- `chore` - maintenance
- `ci` - CI/CD
- `test` - тесты

**Примеры:**

```bash
 feat(auth): add JWT validation
 fix(nginx): correct CORS headers
 docs: update API reference
 added stuff
 fixed bug
```

---

### 4. All CI Checks Green

**Правило:** Merge в `main`/`develop` только после зелёных checks

**Обязательные проверки:**

- CI pipeline (lint, test, build)
- Security checks (CodeQL, Trivy)
- Type checking (TypeScript, mypy)
- Code coverage (target ≥80%)
- Pre-commit hooks passed

---

## ОБЯЗАТЕЛЬНЫЕ ПРАКТИКИ

### Branch Strategy

**Основные ветки:**

- `main` - production (protected)
- `develop` - integration (protected)

**Feature branches:**

```bash
feature/<name> # новая функциональность
fix/<name> # исправления
docs/<name> # документация
ci/<name> # CI/CD изменения
hotfix/<name> # emergency fixes (from main)
```

**Правила:**

- Все работы через Pull Requests
- Base: `develop` (кроме hotfix)
- Merge type: squash (чистая история)
- Delete branch после merge
- Не держать branches >4 недель

---

### Code Review Requirements

**Перед merge:**

1. All CI checks green
2. Минимум 1 approval от maintainer
3. Все комментарии resolved
4. Ветка синхронизирована с базовой
5. Нет конфликтов

**Что проверяется:**

- Соответствие стандартам проекта
- Тесты проходят
- Документация обновлена
- Нет breaking changes без major bump
- Безопасность кода

---

### Testing Requirements

**Обязательно:**

- Unit tests для новой функциональности
- Integration tests для API endpoints
- E2E tests для UI changes

**Команды:**

```bash
bun test # full suite
bun run test:unit # unit tests
bun run test:e2e # E2E tests
go test ./auth/... # Go tests
```

---

## ИНСТРУМЕНТЫ И НАСТРОЙКА

### Минимальные версии

```yaml
Node.js: 22.14.0
Python: 3.11
Go: 1.24.11 (или из auth/go.mod)
pre-commit: ≥3.5.0
Docker: 28.5.2+
Docker Compose: 2.40.3+
Bun: 1.3.3
```

### Установка окружения

```bash
# 1. Node.js dependencies
bun install

# 2. Python venv + pre-commit
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pre-commit install
pre-commit install --hook-type commit-msg

# 3. Go tools (если работаете с auth/)
go install golang.org/x/tools/cmd/goimports@latest

# 4. Проверка
pre-commit --version
bun --version
python --version
go version
```

---

## DOCUMENTATION RULES

### Языковая политика

**English:**

- Код (all code, comments)
- Конфигурация (config files)
- Commit messages
- PR descriptions
- Code comments

**Localized (RU/DE/EN):**

- User documentation (`docs/ru/`, `docs/de/`, `docs/en/`)
- README files
- User guides
- Training materials

**Проверка:**

```bash
bun run lint:language
```

---

### Documentation Metadata

**Обязательный frontmatter для всех `docs/**/\*.md`:\*\*

```yaml
---
title: 'Document Title'
language: ru
doc_version: '2025.12'
last_updated: '2025-12-03'
---
```

**Проверка:**

```bash
python3 scripts/docs/validate_metadata.py
```

---

### Status Snippets

**Source of Truth:** `docs/reference/status.yml`

**Синхронизируемые файлы:**

- `README.md`
- `docs/index.md`
- `docs/overview.md`
- `docs/reference/status-snippet.md`
- `docs/de/reference/status-snippet.md`

**Update:**

```bash
python3 scripts/docs/update_status_snippet.py
```

---

## SECURITY RULES

### Secret Management

**Development:**

```bash
# Create .env from example
cp .env.example .env

# Edit with real values
# NEVER commit .env files
```

**Production:**

```bash
# Use Docker Secrets
docker secret create my_secret secret.txt

# Reference in compose.yml
secrets:
 - my_secret
```

### Secret Files Permissions

**Required:**

```bash
chmod 600 secrets/*
chmod 600 .env*

# Verify
ls -la secrets/ # должно быть -rw-------
```

---

## COMMIT WORKFLOW

### Perfect Commit Flow

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes
# ... edit files ...

# 3. Stage changes
git add path/to/file

# 4. Run pre-commit (automatic on commit)
# OR manually:
pre-commit run

# 5. Commit with conventional message
git commit -m "feat(scope): add amazing feature"

# 6. Push
git push origin feature/my-feature

# 7. Create PR to develop
# 8. Wait for CI + code review
# 9. Squash merge when approved
```

---

## QUICK COMMANDS

### Pre-commit

```bash
# Run for staged files
pre-commit run

# Run for all files
pre-commit run --all-files

# Run specific hook
pre-commit run prettier --all-files
pre-commit run eslint --all-files

# Update hooks
pre-commit autoupdate
```

### Testing

```bash
bun test # full test suite
bun run test:unit # unit tests only
bun run test:e2e # E2E tests
bun run test:watch # watch mode
bun run test:ui # Vitest UI
```

### Linting

```bash
bun run lint # all linters
bun run lint:js # ESLint
bun run lint:py # Ruff
bun run lint:fix # auto-fix
bun run format # Prettier
```

### Type Checking

```bash
bun run type-check # TypeScript
source .venv/bin/activate
mypy . # Python
```

### Docker

```bash
docker compose up -d # start all services
docker compose ps # check status
docker compose logs -f # follow logs
docker compose down # stop all
```

---

## WHAT NOT TO DO

### Never:

1. `git commit --no-verify` (except emergency)
2. Hardcode secrets в коде
3. Commit TODO/FIXME без GitHub Issue
4. Force push to `main`/`develop`
5. Merge без code review
6. Commit без тестов для новой функциональности
7. Commit large files (>500KB) без approval
8. Commit `.env` files
9. Commit временные файлы (`.tmp`, `*.bak`, `.DS_Store`)
10. Commit Finder duplicates (`file 2.md`)

---

## HOOK CATEGORIES

### Always Run (Fast)

`trailing-whitespace` - удаляет trailing whitespace `end-of-file-fixer` -
добавляет EOF newline `check-merge-conflict` - проверяет merge markers
`check-yaml` - валидирует YAML `check-json` - валидирует JSON `gitleaks` - ищет
secrets `check-todo-fixme` - блокирует TODO/FIXME

### Sometimes Slow (Can Skip Locally)

`visuals-and-links-check` - проверяет ссылки в docs `typescript-type-check` -
TypeScript типы `docker-compose-check` - валидирует compose.yml
`markdownlint-cli2` - Markdown linting

**Skip slow hooks:**

```bash
SKIP="visuals-and-links-check,typescript-type-check" \
 pre-commit run --files my-file.md
```

---

## EMERGENCY PROCEDURES

### Hotfix Production Issue

```bash
# 1. Create hotfix from main
git checkout main
git checkout -b hotfix/critical-bug

# 2. Fix the issue
# ... make changes ...

# 3. Commit (можно --no-verify если emergency)
git commit -m "fix: critical production bug"

# 4. Push
git push origin hotfix/critical-bug

# 5. PR to main (fast-track review)
# 6. After merge to main, back-merge to develop
git checkout develop
git merge main
```

### Revert Bad Commit

```bash
# Revert specific commit
git revert <commit-hash>

# Revert last commit
git revert HEAD

# Revert range
git revert <older-commit>..<newer-commit>
```

---

## GET HELP

### Documentation

- **Full Pre-commit Guide:** `docs/development/pre-commit-guide.md`
- **Contributing Guide:** `CONTRIBUTING.md`
- **Security Policy:** `SECURITY.md`
- **API Reference:** `docs/reference/api-reference.md`

### Commands

```bash
# Pre-commit help
pre-commit --help
pre-commit run <hook-id> --help

# NPM scripts
bun run --help

# Commitlint
bunx commitlint --help
```

### Issues

- **GitHub Issues:** https://github.com/DIZ-admin/erni-ki/issues
- **Discussions:** https://github.com/DIZ-admin/erni-ki/discussions

---

## CHECKLIST: Ready to Contribute?

**Before your first commit:**

- [ ] Окружение настроено (Node, Python, Go)
- [ ] Pre-commit hooks установлены
- [ ] Прочитан CONTRIBUTING.md
- [ ] Прочитан этот document (PROJECT-RULES-SUMMARY.md)
- [ ] Понимаю conventional commits формат
- [ ] Понимаю языковую политику (English code, localized docs)
- [ ] Знаю что TODO/FIXME блокируются
- [ ] Знаю что делать с secrets
- [ ] Знаю branch strategy

**Before each commit:**

- [ ] Код отформатирован (`bun run format`)
- [ ] Тесты проходят (`bun test`)
- [ ] Pre-commit hooks green (`pre-commit run`)
- [ ] Нет TODO/FIXME в коде
- [ ] Нет secrets в коде
- [ ] Commit message conventional format
- [ ] Documentation обновлена (если нужно)

**Before creating PR:**

- [ ] All CI checks green
- [ ] Ветка синхронизирована с базовой
- [ ] PR description заполнен
- [ ] Related issues linked
- [ ] Breaking changes documented

---

## LEARNING RESOURCES

### Must Read

1. **CONTRIBUTING.md** - полное руководство по участию
2. **docs/development/pre-commit-guide.md** - детали всех хуков
3. **docs/reference/language-policy.md** - языковая политика
4. **docs/reference/metadata-standards.md** - стандарты документации

### External

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Pre-commit framework](https://pre-commit.com/)
- [Semantic Versioning](https://semver.org/)
- [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)

---

## TL;DR

**3 Golden Rules:**

1. **Conventional Commits** - всегда
2. **No TODO/FIXME** - используйте GitHub Issues
3. **No Secrets** - используйте `.env` или Docker Secrets

**Quick Start:**

```bash
# Setup
bun install && source .venv/bin/activate && pip install -r requirements-dev.txt
pre-commit install && pre-commit install --hook-type commit-msg

# Work
git checkout -b feature/my-feature
# ... code ...
git commit -m "feat(scope): description"
git push origin feature/my-feature
# Create PR → Review → Merge
```

**When in doubt:**

```bash
# Check everything
pre-commit run --all-files

# Read docs
cat CONTRIBUTING.md
cat docs/development/pre-commit-guide.md
```

---

**Version:** 1.0 **Last Updated:** 2025-12-03 **Status:** OFFICIAL PROJECT RULES
