---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Pre-commit Hooks für ERNI-KI

[TOC]

## Überblick

Pre-commit Hooks prüfen Codequalität vor jedem Commit und verhindern попадание
ошибок в репозиторий/CI.

## Installation

### Automatisch

```bash
npm run pre-commit:install
```

### Manuell

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pre-commit detect-secrets
pre-commit install
pre-commit install --hook-type commit-msg
```

## Eingestellte Checks

### 🔍 Basis-Dateiprüfungen

- Trailing whitespace, End-of-file newline, große Dateien (>500KB), merge/case
  conflicts

### 📝 Formate

- YAML/JSON/TOML Syntax

### 🎨 Formatierung

- Prettier für MD/YAML/JSON/JS/TS

### 🔧 Code

- ESLint (JS/TS)

### 🔐 Security

- Detect Secrets (API Keys, Passwörter, Tokens)

### 📋 Commits

- Commitlint (Conventional Commits)

### 🐹 Go

- gofmt, goimports

### 🐳 Docker

- Docker Compose Validation

### 🧹 Cleanup & Docs

- Temporäre Dateien (`.tmp`, `*~`, `*.bak`, `.DS_Store`)
- Status Snippets aktuell
- Archive README vorhanden

**Working-Tree Cleanup:** `scripts/utilities/git-clean-safe.sh` entfernt
ignorierte/unstaged Artefakte via `git clean -fdX`, schont aber `.git/hooks`.
Vorschau: `CLEAN_DRY_RUN=1 scripts/utilities/git-clean-safe.sh`.

## Ausgeschlossene Dateien

```
.env*, conf/litellm/config.yaml, conf/**/*.conf, *.key, *.pem, *.crt, secrets/, data/, logs/, .config-backup/
```

## Nutzung

### Automatisch

- Läuft bei `git commit`.

### Manuell

```bash
npm run pre-commit:run
# oder
source .venv/bin/activate
pre-commit run --all-files

pre-commit run prettier --all-files
pre-commit run eslint --all-files
```

## Update

```bash
npm run pre-commit:update
# oder
source .venv/bin/activate
pre-commit autoupdate
```

## Skip (nicht empfohlen)

```bash
git commit --no-verify -m "commit message"
```

## Integration

Hooks sind eingebunden in bestehende Tools; beachten Sie die Ausnahmen oben.
