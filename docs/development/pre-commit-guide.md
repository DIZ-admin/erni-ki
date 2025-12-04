---
title: 'Pre-commit Hooks Guide - ERNI-KI'
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-12-03'
---

# Pre-commit Hooks Guide - ERNI-KI

**Версия:** 2025.11 | **Дата обновления:** 2025-12-03

---

## Оглавление

- [Введение](#введение)
- [Архитектура pre-commit системы](#архитектура-pre-commit-системы)
- [Установка и настройка](#установка-и-настройка)
- [Все хуки проекта](#все-хуки-проекта)
- [Commitlint правила](#commitlint-правила)
- [Быстрые команды](#быстрые-команды)
- [Пропуск хуков](#пропуск-хуков)
- [Troubleshooting](#troubleshooting)

---

## Введение

ERNI-KI использует **многоуровневую систему pre-commit хуков** для обеспечения
качества кода:

1. **Python pre-commit framework** - основной механизм валидации
2. **Husky** - Git hooks менеджер для Node.js окружения (теперь вызывает только
   pre-commit)
3. **Commitlint** - валидация commit messages

### Философия проекта

**Цель:** Автоматически выявлять проблемы **до коммита**, а не после push в CI.

**Принципы:**

1. **Fail Fast** - ошибки блокируют коммит
2. **Comprehensive Validation** - покрытие всех типов файлов
3. **Security First** - обязательная проверка секретов
4. **Zero TODO/FIXME** - все задачи трекаются в GitHub Issues

> Примечание: lint-staged удалён; Husky вызывает pre-commit, профили доступны
> через `--config` (например, `.pre-commit/config-fast.yaml`).

---

## Архитектура pre-commit системы

### Двойная система валидации

```

GIT COMMIT

  Husky pre-commit hook
    - exec pre-commit run (profiles via --config)

  Python pre-commit (.pre-commit-config.yaml)
    - Basic checks (whitespace, EOF, large files)
    - YAML/JSON/TOML validation
    - Prettier formatting
    - Python (ruff lint/format, mypy)
    - Security (gitleaks, detect-secrets, secret perms)
    - Shellcheck
    - ESLint
    - Local hooks (TS type-check, Docker compose validate, docs checks, no emoji, etc.)

  Husky commit-msg hook
    - bunx commitlint (validate message format)

COMMIT SUCCESS

```

---

## Установка и настройка

### 1. Полная установка (первый раз)

```bash
# 1. Node.js зависимости (включая Husky)
bun install

# 2. Python окружение
python3 -m venv .venv
source .venv/bin/activate # macOS/Linux
# .venv\Scripts\activate # Windows

# 3. Python зависимости (pre-commit framework)
pip install -r requirements-dev.txt

# 4. Установка pre-commit хуков
pre-commit install
pre-commit install --hook-type commit-msg

# 5. Go инструменты (если работаете с auth/)
go install golang.org/x/tools/cmd/goimports@latest

# 6. Проверка установки
pre-commit --version # должно быть >= 3.5.0
```

### 2. Быстрая переустановка хуков

```bash
# Если хуки сломались или не работают
rm -rf .git/hooks
source .venv/bin/activate
pre-commit install
pre-commit install --hook-type commit-msg
```

### 3. Обновление хуков

```bash
# Обновить все pre-commit хуки до последних версий
source .venv/bin/activate
pre-commit autoupdate

# Или через npm script
bun run pre-commit:update
```

---

## Все хуки проекта

### Категория 1: Basic File Checks

**Источник:** `pre-commit-hooks` (official)

#### 1.1 `trailing-whitespace`

**Что делает:** Удаляет trailing whitespace в конце строк

**Исключения:**

- `.env.*` файлы
- `conf/litellm/config.yaml`
- `conf/*.conf`, `conf/*.ini`
- `*.key`, `*.pem`, `*.crt` (сертификаты)
- `secrets/*`, `data/*`, `logs/*`

**Аргументы:** `--markdown-linebreak-ext=md` (сохраняет markdown line breaks)

#### 1.2 `end-of-file-fixer`

**Что делает:** Добавляет пустую строку в конец файла (POSIX standard)

**Исключения:** Те же, что у `trailing-whitespace`

#### 1.3 `check-added-large-files`

**Что делает:** Блокирует коммит файлов > 500KB

**Исключения:**

- `data/*`, `logs/*` (runtime данные)
- `*.pdf`, `*.zip`, `*.tar.gz` (архивы)
- `node_modules/*` (dependencies)

**Bypass:** Если нужно закоммитить большой файл:

```bash
git commit --no-verify -m "docs: add large dataset"
```

#### 1.4 `check-merge-conflict`

**Что делает:** Проверяет наличие merge conflict markers (`<<<<<<<`, `=======`,
`>>>>>>>`)

**Критично:** Предотвращает случайный коммит unresolved conflicts

#### 1.5 `check-case-conflict`

**Что делает:** Проверяет конфликты имён файлов (Windows/macOS)

**Пример:** `readme.md` vs `README.md` - один файл на case-insensitive FS

#### 1.6 `check-executables-have-shebangs`

**Что делает:** Проверяет что executable файлы имеют shebang (`#!/bin/bash`)

**Исключения:** `node_modules/*`, `.git/*`

#### 1.7 `check-shebang-scripts-are-executable`

**Что делает:** Проверяет что скрипты с shebang имеют execute permission

**Fix:**

```bash
chmod +x scripts/my-script.sh
```

---

### Категория 2: YAML/JSON/TOML Validation

**Источник:** `pre-commit-hooks` (official)

#### 2.1 `check-yaml`

**Что делает:** Валидирует синтаксис YAML файлов

**Аргументы:** `--allow-multiple-documents` (для multi-doc YAML)

**Исключения:**

- `.env.*` (не YAML)
- `mkdocs.yml` (обрабатывается отдельно)
- `conf/litellm/config.yaml` (может иметь специфичный синтаксис)
- `conf/*.yml`, `conf/*.yaml` (сервисные конфиги)

#### 2.2 `check-json`

**Что делает:** Валидирует синтаксис JSON файлов

**Исключения:**

- `conf/*.json` (сервисные конфиги)
- `.vscode/*` (IDE settings)
- `data/*`, `logs/*`

#### 2.3 `check-toml`

**Что делает:** Валидирует синтаксис TOML файлов

**Примеры:** `pyproject.toml`, `ruff.toml`, `Cargo.toml`

---

### Категория 3: Code Formatting

#### 3.1 `prettier`

**Источник:** `mirrors-prettier` (pre-commit mirror)

**Что делает:** Автоматически форматирует код

**Поддерживаемые типы:**

- Markdown (`.md`)
- YAML (`.yml`, `.yaml`)
- JSON (`.json`)
- JavaScript/TypeScript (`.js`, `.jsx`, `.ts`, `.tsx`)

**Конфигурация:** `.prettierrc` + `.prettierrc.json`

**Версия:** 3.6.2

**Ignore:** `.prettierignore`

---

### Категория 4: Python Linting/Formatting

#### 4.1 `ruff` (lint)

**Источник:** `astral-sh/ruff-pre-commit`

**Что делает:** Быстрый Python linter (замена Flake8, pylint, isort)

**Аргументы:** `--fix` (автоматически исправляет проблемы)

**Конфигурация:** `ruff.toml`

**Что проверяет:**

- Стиль кода (PEP 8)
- Import порядок
- Неиспользуемые импорты
- Security issues
- Code complexity

#### 4.2 `black`

**Источник:** `psf/black`

**Что делает:** Opinionated Python formatter

**Версия:** Python 3.11

**Конфигурация:** `pyproject.toml`

**Параметры:**

- Line length: 100
- Target version: py311

#### 4.3 `isort`

**Источник:** `pycqa/isort`

**Что делает:** Организация Python imports

**Профиль:** `black` (совместимость)

**Конфигурация:** `pyproject.toml`

#### 4.4 `mypy`

**Источник:** `pre-commit/mirrors-mypy`

**Что делает:** Static type checking для Python

**Аргументы:**

- `--config-file mypy.ini`
- `--ignore-missing-imports`

**Дополнительные зависимости:**

- `types-requests`
- `types-PyYAML`

**Исключения:**

- `webhook_handler.py`
- `webhook-receiver`
- `ops/ollama-exporter/app.py`
- `docs/examples/webhook-client-python.py`

---

### Категория 5: Security

#### 5.1 `gitleaks`

**Источник:** `gitleaks/gitleaks`

**Что делает:** Обнаружение секретов в коде

**Версия:** v8.29.1

**Конфигурация:** `.gitleaks.toml`

**Что ищет:**

- API keys
- Passwords
- Private keys
- AWS credentials
- GitHub tokens
- JWT secrets

**Критично:** Блокирует коммит если найдены секреты!

#### 5.2 `detect-secrets`

**Источник:** `Yelp/detect-secrets`

**Что делает:** Дополнительная проверка секретов

**Аргументы:**

- `--baseline .secrets.baseline` (baseline для false positives)
- `--exclude-files` (паттерны исключений)

**Исключения:**

- `.env.*` (expected secrets location)
- `conf/litellm/config.yaml`
- `*.key`, `*.pem`, `*.crt`
- `secrets/*`
- `node_modules/*`
- `package-lock.json`
- `.secrets.baseline`

**Update baseline:**

```bash
detect-secrets scan > .secrets.baseline
```

---

### Категория 6: Shell Scripts

#### 6.1 `shellcheck`

**Источник:** `koalaman/shellcheck-precommit`

**Что делает:** Статический анализ shell scripts

**Аргументы:**

- `--severity=error` (только errors, не warnings)
- `-e SC1091` (ignore source file not found)

**Файлы:** `*.sh`

**Проверяет:**

- Синтаксис
- Опасные паттерны
- Quoting issues
- Portable issues

---

### Категория 7: JavaScript/TypeScript

#### 7.1 `eslint`

**Источник:** `pre-commit/mirrors-eslint`

**Что делает:** JavaScript/TypeScript linting

**Файлы:** `.js`, `.jsx`, `.ts`, `.tsx`

**Исключения:**

- `node_modules/*`
- `dist/*`, `build/*`
- `*.min.js`
- `*.pb.js`, `*.pb.ts` (protobuf generated)

**Плагины:**

- `@typescript-eslint/*` (TypeScript support)
- `eslint-plugin-security` (security rules)
- `eslint-plugin-n` (Node.js rules)
- `eslint-plugin-promise` (Promise best practices)

**Аргументы:** `--fix` (автоисправление)

**Конфигурация:** `eslint.config.js`

---

### Категория 8: Additional Checks

#### 8.1 `python-check-blanket-noqa`

**Источник:** `pre-commit/pygrep-hooks`

**Что делает:** Проверяет что `# noqa` комментарии специфичны (не blanket)

**Пример:**

```python
# Bad
import unused_module # noqa

# Good
import unused_module # noqa: F401
```

---

### Категория 9: Local Hooks (Custom)

**Источник:** `repo: local` (custom scripts)

#### 9.1 `ts-type-check`

**Команда:** `npm run type-check`

**Что делает:** TypeScript type checking без emit

**Файлы:** `.ts`, `.tsx`

**Stage:** `pre-commit`

**Зависит от:** `tsconfig.json`

**Bypass:** `--no-verify` (не рекомендуется)

#### 9.2 `docker-compose-check`

**Команда:** `docker compose config -q`

**Что делает:** Валидация `compose.yml` конфигурации

**Файлы:** `compose.yml`

**Проверяет:**

- YAML синтаксис
- Docker Compose schema
- Service dependencies
- Network configuration

**Fix:** Исправьте ошибки в `compose.yml`

#### 9.3 `check-todo-fixme` **КРИТИЧЕСКИЙ**

**Команда:** Bash script с `rg` (ripgrep) или `find` fallback

**Что делает:** **БЛОКИРУЕТ коммит если найдены TODO/FIXME в коде**

**Философия:** Все задачи должны быть в GitHub Issues, не в комментариях

**Что ищет:**

- `TODO` в коде
- `FIXME` в коде

**Где ищет:**

- `*.py`, `*.js`, `*.ts`, `*.go`, `*.yml`, `*.yaml`
- Исключает: `node_modules/`, `.venv/`, `site/`, `.pre-commit-config.yaml`

**Исключение:** Добавьте `pragma: allowlist todo` в строку

```python
# TODO: refactor this function # pragma: allowlist todo
```

**Рекомендация:** Создайте GitHub Issue вместо TODO:

```python
# Issue #123: refactor this function
```

**Bypass:** `git commit --no-verify` (только для emergency)

#### 9.4 `gofmt`

**Команда:** `gofmt -w`

**Что делает:** Go code formatting (official Go formatter)

**Файлы:** `*.go`

**Автоисправление:** Да (in-place)

#### 9.5 `goimports`

**Команда:** Bash wrapper для `goimports`

**Что делает:** Go imports organization

**Установка:** `go install golang.org/x/tools/cmd/goimports@latest`

**Path handling:**

```bash
export PATH="$PATH:$HOME/go/bin:/Users/kostas/go/bin"
```

**Fallback:** `go run golang.org/x/tools/cmd/goimports@latest`

#### 9.6 `check-duplicate-basenames`

**Команда:** `python3 scripts/maintenance/check_duplicate_basenames.py`

**Что делает:** Проверяет дубликаты basenames в `scripts/` и `conf/`

**Пример проблемы:**

```
scripts/backup.sh
conf/backup.sh
```

**Решение:** Переименуйте один из файлов

#### 9.7 `status-snippet-check`

**Команда:** `python3 scripts/docs/update_status_snippet.py --check`

**Что делает:** Проверяет что status snippets синхронизированы

**Файлы:**

- `docs/reference/status.yml` (source of truth)
- `docs/reference/status-snippet.md`
- `docs/de/reference/status-snippet.md`
- `docs/de/index.md`
- `docs/index.md`, `docs/overview.md`
- `README.md`

**Fix:** Запустите без `--check`:

```bash
python3 scripts/docs/update_status_snippet.py
```

#### 9.8 `archive-readme-check`

**Команда:** `python3 scripts/docs/check_archive_readmes.py`

**Что делает:** Проверяет что все папки в `docs/archive/` имеют README

**Fix:** Создайте `README.md` в папке без него

#### 9.9 `markdownlint-cli2`

**Команда:** `npx markdownlint-cli2`

**Что делает:** Markdown linting

**Файлы:** `.md`, `.markdown`

**Конфигурация:** `.markdownlint-cli2.jsonc`

**Зависимости:** `markdownlint-cli2@0.19.1`

**Что проверяет:**

- Heading styles
- List formatting
- Code blocks
- Links
- Line length

#### 9.10 `visuals-and-links-check`

**Команда:** `python3 scripts/docs/visuals_and_links_check.py`

**Что делает:** Проверяет визуальные элементы и ссылки в документации

**Проверки:**

- TOC (table of contents) корректность
- Internal links validity
- Image references
- Broken links

#### 9.11 `check-temporary-files`

**Команда:** Bash script с `find`

**Что делает:** Блокирует коммит временных файлов

**Что ищет:**

- `*.tmp`
- `*~` (editor backups)
- `*.bak`
- `.DS_Store` (macOS)

**Исключает:**

- `.git/`, `node_modules/`, `.venv/`, `site/`, `coverage/`

**Fix:** Удалите временные файлы:

```bash
find . -name "*.tmp" -delete
find . -name ".DS_Store" -delete
```

#### 9.12 `validate-docs-metadata`

**Команда:** `python3 scripts/docs/validate_metadata.py`

**Что делает:** Валидирует YAML frontmatter в документации

**Файлы:** `docs/**/*.md`

**Обязательные поля:**

- `title`
- `language`
- `doc_version`
- `last_updated`

**Пример валидного frontmatter:**

```yaml
---
title: 'My Document'
language: ru
doc_version: '2025.12'
last_updated: '2025-12-03'
---
```

#### 9.13 `forbid-numbered-copies` (docs only)

**Команда:** Bash script (regex check)

**Что делает:** Блокирует файлы с Finder-style дубликатами

**Файлы:** `docs/**/*`

**Примеры проблемных имён:**

- `document 2.md`
- `image 3.png`
- `README 4.md`

**Причина:** Finder/Windows создают такие файлы при копировании

**Fix:** Переименуйте файл:

```bash
mv "document 2.md" "document-v2.md"
```

#### 9.14 `forbid-numbered-copies-any` (repo-wide)

**Команда:** Bash script с `find -E`

**Что делает:** То же, но для всего репозитория

**Исключает:** `.git/`, `node_modules/`, `.venv/`, `site/`

#### 9.15 `no-emoji-in-files`

**Команда:** `python3 scripts/validate-no-emoji.py`

**Что делает:** Блокирует emoji в файлах проекта

**Файлы:** `.md`, `.txt`

**Исключения:** `node_modules/`, `.venv/`, `site/`, `data/`

**Философия:** Профессиональная документация без emoji

**Исключение:** User-facing docs могут иметь emoji с approval

#### 9.16 `check-secret-permissions`

**Команда:** `scripts/security/check-secret-permissions.sh`

**Что делает:** Проверяет permissions на secret файлы

**Требования:**

- `secrets/*` должны иметь `600` (rw-------)
- `.env*` должны иметь `600`

**Fix:**

```bash
chmod 600 secrets/*
chmod 600 .env*
```

---

## Lint-staged конфигурация

Lint-staged более не используется. Husky вызывает `pre-commit` напрямую. Для
быстрых сценариев используйте профили:

- `.pre-commit/config-fast.yaml` — быстрые проверки
- `.pre-commit/config-docs.yaml` — документация
- `.pre-commit/config-security.yaml` — безопасность

Команды:

```bash
bun run pre-commit:fast   # быстрый профиль
bun run pre-commit:full   # полный профиль
bun run pre-commit:perf   # измерить время хуков
```

---

## Commitlint правила

**Источник:** `commitlint.config.cjs`

**Framework:** `@commitlint/config-conventional`

### Формат commit message

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Обязательные элементы

**Type (обязательно):**

- `feat` - новая функциональность
- `fix` - исправление бага
- `docs` - изменения в документации
- `style` - форматирование (не влияет на код)
- `refactor` - рефакторинг кода
- `perf` - улучшение производительности
- `test` - добавление тестов
- `chore` - обновление build или общие задачи
- `ci` - изменения в CI/CD
- `build` - изменения в build системе
- `revert` - откат изменений
- `security` - security fixes
- `deps` - обновление зависимостей
- `config` - изменения конфигурации
- `docker` - Docker изменения
- `deploy` - deployment изменения

**Scope (опционально, но рекомендуется):**

- `auth` - authentication service
- `nginx` - nginx configuration
- `docker`, `compose` - Docker/Compose
- `ci` - CI/CD pipeline
- `docs` - документация
- `config` - конфигурация
- `monitoring` - мониторинг
- `security` - безопасность
- `ollama`, `openwebui` - AI сервисы
- `postgres`, `redis` - базы данных
- `searxng`, `cloudflare`, `tika`, `edgetts` - вспомогательные сервисы
- `mcposerver`, `watchtower` - инфраструктура
- `deps`, `tests`, `lint`, `format` - разработка

**Subject (обязательно):**

- Не более 100 символов
- Нижний регистр для type/scope
- Без точки в конце
- Не Sentence case, не PascalCase, не UPPERCASE

### Правила длины

- Header (type + scope + subject): max 100 символов
- Body line: max 100 символов
- Footer line: max 100 символов

### Примеры правильных commit messages

```bash
# Simple feature
feat: add user authentication

# Feature with scope
feat(auth): implement JWT token validation

# Bug fix
fix(nginx): correct CORS headers configuration

# Documentation
docs: update API reference for v0.6.3

# Security fix
security(auth): patch JWT expiration validation

# Dependency update
deps(npm): upgrade eslint to 9.15.0

# Breaking change
feat(api)!: change authentication endpoint

BREAKING CHANGE: /auth endpoint moved to /v2/auth
```

### Примеры неправильных commit messages

```bash
# Missing type
add new feature

# Wrong case (uppercase type)
FEAT: add feature

# Subject with period
feat: add feature.

# Too long header
feat: this is a very long commit message that exceeds one hundred characters and will be rejected by commitlint

# Sentence case subject
feat: Add new feature

# Invalid type
feature: add something
```

### Игнорируемые commits

- Merge commits (`Merge branch 'feature'`)
- Renovate commits
- Dependabot commits

### Interactive commit helper

```bash
# Использовать git-cz (commitizen) для интерактивного создания commit
npm run commit

# Или через git-cz
git-cz
```

---

## Быстрые команды

### Основные команды

```bash
# Запустить все хуки для staged файлов
pre-commit run

# Запустить все хуки для всех файлов (медленно!)
pre-commit run --all-files

# Запустить конкретный хук
pre-commit run prettier --all-files
pre-commit run eslint --all-files
pre-commit run check-todo-fixme

# Запустить хук для конкретных файлов
pre-commit run --files path/to/file1.md path/to/file2.py

# Обновить хуки до последних версий
pre-commit autoupdate
```

### Через npm scripts

```bash
# Запустить все хуки (включая Python pre-commit)
bun run pre-commit:run

# Переустановить хуки
bun run pre-commit:install

# Обновить хуки
bun run pre-commit:update
```

### Проверка конкретных типов

```bash
# Только Python проверки
pre-commit run ruff --all-files
pre-commit run black --all-files
pre-commit run mypy --all-files

# Только JavaScript/TypeScript
pre-commit run eslint --all-files
pre-commit run ts-type-check

# Только форматирование
pre-commit run prettier --all-files

# Только security
pre-commit run gitleaks --all-files
pre-commit run detect-secrets --all-files

# Только документация
pre-commit run markdownlint-cli2 --all-files
pre-commit run visuals-and-links-check
pre-commit run validate-docs-metadata --all-files
```

---

## Пропуск хуков

### ВНИМАНИЕ

**Пропуск хуков рекомендуется только в emergency случаях!**

Все хуки есть по причине - они предотвращают проблемы в production.

### Пропустить все хуки

```bash
git commit --no-verify -m "emergency: hotfix production issue"
# или
git commit -n -m "emergency: hotfix"
```

### Пропустить конкретные хуки

```bash
# Пропустить тяжёлые хуки при локальной работе
SKIP="visuals-and-links-check,typescript-type-check,eslint,docker-compose-check" \
 pre-commit run --files path/to/file.md

# Пропустить проверку документации
SKIP="docs-validate-metadata,markdownlint-cli2" \
 git commit -m "wip: draft documentation"

# Пропустить TODO check (только для testing)
SKIP="check-todo-fixme" \
 git commit -m "test: temporary TODO for debugging"
```

### Отключить хуки временно

```bash
# Отключить Husky хуки
export HUSKY=0
git commit -m "commit message"
unset HUSKY

# Отключить pre-commit framework
export PRE_COMMIT_ALLOW_NO_CONFIG=1
git commit -m "commit message"
unset PRE_COMMIT_ALLOW_NO_CONFIG
```

### Когда можно пропускать

**Допустимые случаи:**

- Emergency hotfix в production
- Revert проблемного коммита
- Work-in-progress на feature ветке (не в main/develop)
- Temporary debugging (будет удалено в следующем коммите)

**Недопустимые случаи:**

- "Хуки медленные" - оптимизируйте хуки, не пропускайте
- "Я знаю что делаю" - code review может найти проблемы позже
- "Это только draft" - draft должен быть на отдельной ветке
- "CI проверит" - CI медленнее и дороже чем локальные хуки

---

## Troubleshooting

### Проблема 1: "command not found: pre-commit"

**Причина:** pre-commit не установлен или не в PATH

**Решение:**

```bash
# Активируйте venv
source .venv/bin/activate # macOS/Linux
.venv\Scripts\activate # Windows

# Переустановите pre-commit
pip install --upgrade pre-commit

# Проверьте
pre-commit --version
```

### Проблема 2: "goimports: command not found"

**Причина:** goimports не установлен

**Решение:**

```bash
# Установить goimports
go install golang.org/x/tools/cmd/goimports@latest

# Добавить в PATH (bash/zsh)
export PATH="$PATH:$HOME/go/bin"

# Или для fish
set -Ux PATH $PATH $HOME/go/bin

# Проверить
goimports --help
```

### Проблема 3: "Hook failed: check-todo-fixme"

**Причина:** В коде найдены TODO/FIXME комментарии

**Решение:**

```bash
# Найти все TODO/FIXME
rg "TODO|FIXME" --glob '*.{py,js,ts,go,yml}'

# Вариант 1: Создать GitHub Issue и заменить
# TODO: refactor this
# Issue #123: refactor this

# Вариант 2: Добавить pragma allowlist (только если действительно нужно)
# TODO: temporary debugging # pragma: allowlist todo

# Вариант 3: Emergency bypass (не рекомендуется)
git commit --no-verify -m "fix: critical bug"
```

### Проблема 4: "Hook failed: validate-docs-metadata"

**Причина:** Отсутствует или неправильный frontmatter в документе

**Решение:**

```bash
# Добавить правильный frontmatter в начало .md файла
---
title: 'Document Title'
language: ru
doc_version: '2025.12'
last_updated: '2025-12-03'
---
```

### Проблема 5: "Hook failed: status-snippet-check"

**Причина:** Status snippets несинхронизированы

**Решение:**

```bash
# Автоматически обновить все snippets
python3 scripts/docs/update_status_snippet.py

# Добавить изменения
git add docs/reference/status-snippet.md \
 docs/de/reference/status-snippet.md \
 README.md \
 docs/index.md \
 docs/overview.md

# Закоммитить
git commit -m "docs: sync status snippets"
```

### Проблема 6: "Hook failed: check-secret-permissions"

**Причина:** Неправильные permissions на secret файлах

**Решение:**

```bash
# Исправить permissions
chmod 600 secrets/*
chmod 600 .env*

# Проверить
ls -la secrets/
ls -la .env*

# Должно быть: -rw------- (600)
```

### Проблема 7: "mypy failed"

**Причина:** Type errors в Python коде

**Решение:**

```bash
# Запустить mypy отдельно для детального вывода
source .venv/bin/activate
mypy --config-file mypy.ini path/to/file.py

# Исправить type hints
# Или добавить type: ignore с комментарием
result = unsafe_function() # type: ignore # external library without types
```

### Проблема 8: "ESLint failed"

**Причина:** Linting errors в JS/TS коде

**Решение:**

```bash
# Запустить ESLint с подробным выводом
npx eslint path/to/file.ts

# Автоисправление
npx eslint path/to/file.ts --fix

# Если не исправляется автоматически - исправить вручную
```

### Проблема 9: "docker-compose-check failed"

**Причина:** Ошибки в compose.yml

**Решение:**

```bash
# Проверить синтаксис
docker compose config

# Типичные ошибки:
# - Неправильные отступы YAML
# - Несуществующие environment variables
# - Неправильные volume paths
# - Invalid service dependencies

# Исправить compose.yml и повторить
```

### Проблема 10: "Prettier failed"

**Причина:** Файлы не соответствуют Prettier formatting

**Решение:**

```bash
# Автоматически отформатировать
npx prettier --write path/to/file.md

# Или для всех файлов
npm run format

# Проверить без изменений
npm run format:check
```

---

## Performance Tips

### 1. Используйте ripgrep (rg)

```bash
# Установить ripgrep (macOS)
brew install ripgrep

# Проверить
rg --version

# Хук check-todo-fixme использует rg если доступен
# В 10-100 раз быстрее чем grep/find
```

### 2. Пропускайте тяжёлые хуки при локальной работе

```bash
# Для быстрой итерации
SKIP="visuals-and-links-check,typescript-type-check" \
 pre-commit run --files docs/my-file.md
```

### 3. Профили pre-commit (fast/docs/security)

```bash
# Быстрый профиль
bun run pre-commit:fast

# Полный профиль
bun run pre-commit:full

# Только документация
pre-commit run --config .pre-commit/config-docs.yaml --all-files

# Только безопасность
pre-commit run --config .pre-commit/config-security.yaml --all-files

# Измерение времени хуков
bun run pre-commit:perf
```

### 4. Кэш pre-commit

```bash
# Pre-commit кэширует результаты
# Повторные запуски намного быстрее

# Очистить кэш если проблемы
pre-commit clean
```

---

## Best Practices

### 1. Commit часто, маленькими порциями

```bash
# Good: маленькие атомарные commits
git commit -m "feat(auth): add JWT validation"
git commit -m "test(auth): add JWT validation tests"
git commit -m "docs(auth): document JWT validation"

# Bad: огромный commit
git commit -m "feat: implement entire authentication system"
```

### 2. Исправляйте проблемы, не обходите хуки

```bash
# Bad
git commit --no-verify -m "feat: quick fix"

# Good
# Исправить все проблемы найденные хуками
# Затем commit без --no-verify
git commit -m "feat: properly validated feature"
```

### 3. Используйте conventional commits

```bash
# Good
feat(api): add user registration endpoint
fix(auth): correct token expiration check
docs: update API documentation for v0.6.3

# Bad
added stuff
fixed bug
update
```

### 4. Регулярно обновляйте хуки

```bash
# Каждую неделю или при изменении конфигурации
pre-commit autoupdate

# Проверить что всё работает
pre-commit run --all-files
```

### 5. Не коммитьте TODO/FIXME

```bash
# Bad
# TODO: refactor this later
def messy_function():
 pass

# Good
# Issue #123: refactor messy_function
def messy_function():
 pass
```

---

## Заключение

**Pre-commit хуки в ERNI-KI** - это **первая линия защиты** качества кода.

**Ключевые принципы:**

1. **Все хуки обязательны** - не пропускайте без веской причины
2. **TODO/FIXME блокируются** - используйте GitHub Issues
3. **Security-first** - secrets detection обязателен
4. **Fail fast** - находите проблемы локально, не в CI
5. **Conventional commits** - автоматизация changelog и versioning

**Помните:**

- Хуки экономят время team - проблемы находятся до code review
- CI проверки медленнее и дороже - исправляйте проблемы локально
- Качество кода - ответственность каждого разработчика

**Полезные ссылки:**

- [Pre-commit framework docs](https://pre-commit.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Husky docs](https://typicode.github.io/husky/)

---

**Версия документа:** 1.0 **Последнее обновление:** 2025-12-03 **Автор:**
ERNI-KI Technical Team **Статус:** FINAL
