---
language: de
translation_status: in_progress
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Developer Guide (Kurzfassung)

## Setup & Installation

1.**Bun**

- Bun 1.3.3+ installieren
- `bun install` im Repo ausführen

  2.**Python-Tools**(für Lint/Docs)

- Optional: `python3 -m venv .venv && source .venv/bin/activate`
- `pip install pre-commit detect-secrets`

  3.**Hooks**

- `bun run pre-commit:install`

  4.**Environment**

- `.env.example` kopieren → `.env` / `env/*.env` ausfüllen
- Für lokale Tests meist ausreichend: `ENV=dev`, Dummy-Secrets

## Commands

-**Tests (Unit)**: `bun run test:unit` -**Lint (TS/JS)**:
`bun run lint` -**Format**: `bun run format` -**Pre-commit (alle Checks)**:
`bun run pre-commit:run` -**Docs Build**: `.venv/bin/mkdocs build`

## Projektstruktur (Auszug)

- `auth/` – Auth-Service (Go/TS Tests)
- `docs/` – Dokumentation (RU/DE/EN)
- `scripts/` – Hilfs-Skripte (Monitoring/Docs)
- `.github/workflows/` – CI/CD Pipelines

## Troubleshooting

-**npm ci schlägt fehl**→ Lockfile aktualisieren: `npm install` lokal, Lock
committen -**pre-commit meckert über Secrets**→ prüfen, ob echte Tokens im Repo;
ggf. baseline aktualisieren -**mkdocs Warnungen**→ fehlende Links/Dateien in
Docs prüfen (`mkdocs build --strict`)
