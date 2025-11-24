---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Pre-commit Hooks für ERNI-KI

## Überblick

Pre-commit-Hooks prüfen den Code automatisch vor jedem Commit und verhindern,
dass Fehler in das Repository und die CI/CD-Pipeline gelangen.

## Installation

### Automatische Installation

```bash
npm run pre-commit:install
```

### Manuelle Installation

```bash
# Virtuelle Python-Umgebung erstellen
python3 -m venv .venv

# Umgebung aktivieren
source .venv/bin/activate

# pre-commit installieren
pip install pre-commit detect-secrets

# Hooks installieren
pre-commit install
pre-commit install --hook-type commit-msg
```

## Eingestellte Checks

### 🔍 Basis-Dateiprüfungen

- **Trailing whitespace** – entfernt überflüssige Leerzeichen am Zeilenende
- **End-of-file** – fügt einen Zeilenumbruch am Dateiende hinzu
- **Large files** – verhindert Commits von Dateien >500KB
- **Merge conflicts** – prüft auf ungelöste Konflikte
- **Case conflicts** – prüft Konflikte durch Groß-/Kleinschreibung von
  Dateinamen

### 📝 Formatvalidierung

- **YAML** – Syntax-Check
- **JSON** – Syntax-Check
- **TOML** – Syntax-Check

### 🎨 Code-Formatierung

- **Prettier** – automatisches Formatieren von:
  - Markdown-Dateien
  - YAML/JSON-Konfigurationen
  - JavaScript/TypeScript-Code

### 🔧 Code-Prüfungen

- **ESLint** – Prüfung von JavaScript/TypeScript:
  - Codequalität
  - Sicherheit (Security-Plugin)
  - Node.js Best Practices
  - Promise-Handling

### 🔐 Sicherheit

- **Detect Secrets** – Suche nach Secrets:
  - API-Keys
  - Passwörter
  - Tokens
  - Zertifikate

### 📋 Commits

- **Commitlint** – prüft Commit-Nachrichten:
  - Standard: Conventional Commits
  - Korrekte Struktur der Messages

### 🐹 Go-Code

- **gofmt** – Formatierung von Go-Code
- **goimports** – Organisation der Imports

### 🐳 Docker

- **Docker Compose** – Validierung von compose.yml

### 🧹 Cleanup & Dokumentation

- **Temporary files check** – verhindert Commits von temporären Dateien:
  - `.tmp`-Dateien
  - Backup-Dateien (`*~`, `*.bak`)
  - Systemdateien (`.DS_Store`)
- **Status snippets** – prüft Aktualität der Status-Snippets in der Doku
- **Archive README** – prüft README-Präsenz in Archiv-Verzeichnissen

## Ausgeschlossene Dateien

Folgende Dateien sind aus Sicherheitsgründen ausgeschlossen:

```
.env*                    # Umgebungsvariablen
conf/litellm/config.yaml # API-Schlüssel
conf/**/*.conf           # Service-Konfigurationen
*.key, *.pem, *.crt      # SSL-Zertifikate
secrets/                 # Verzeichnis mit Secrets
data/                    # Servicedaten
logs/                    # Logs
.config-backup/          # Backup-Dateien
```

## Verwendung

### Automatischer Start

Pre-commit-Hooks laufen automatisch bei `git commit`.

### Manueller Start

```bash
# Alle Checks
npm run pre-commit:run

# Oder über die virtuelle Umgebung
source .venv/bin/activate
pre-commit run --all-files

# Einzelnen Check starten
pre-commit run prettier --all-files
pre-commit run eslint --all-files
```

### Hooks aktualisieren

```bash
npm run pre-commit:update

# Oder
source .venv/bin/activate
pre-commit autoupdate
```

### Checks überspringen (nicht empfohlen)

```bash
git commit --no-verify -m "Commit-Nachricht"
```

## Integration mit bestehenden Tools

Pre-commit-Hooks sind integriert mit:

- **ESLint** – nutzt `eslint.config.js`
- **Ruff** – nutzt `ruff.toml` (Installation über `requirements-dev.txt`)
- **Prettier** – nutzt `.prettierrc`
- **Commitlint** – nutzt `commitlint.config.cjs`
- **Husky** – arbeitet parallel zu bestehenden Hooks

## Problembehebung

### Formatierungsfehler

```bash
# Automatische Korrekturen
npm run format
npm run format:py
npm run lint:fix
```

### Secret-Warnungen

```bash
# Baseline aktualisieren
source .venv/bin/activate
detect-secrets scan --baseline .secrets.baseline
```

### Temporäre Dateien gefunden

```bash
# Alle temporären Dateien finden
find . -type f \( -name "*.tmp" -o -name "*~" -o -name "*.bak" \) ! -path "*/node_modules/*" ! -path "*/.git/*"

# Alle temporären Dateien löschen
find . -type f \( -name "*.tmp" -o -name "*~" -o -name "*.bak" \) ! -path "*/node_modules/*" ! -path "*/.git/*" -delete

# .DS_Store-Dateien entfernen (macOS)
find . -name ".DS_Store" -delete
```

### Cache leeren

```bash
source .venv/bin/activate
pre-commit clean
```
