---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# GitHub Governance Checkliste

_Aktualisiert: 2025-11-17_

## 1. Branch-Struktur

- **Haupt-Branch:** `main`
- **Arbeits-Branch:** `develop` (früher `dev`). Remote-Branch umbenennen und
  Branch Protection via GitHub UI/CLI neu konfigurieren:

```bash
git push origin develop:develop
git push origin :dev
gh api repos/:owner/:repo/branches/develop/protection -X PUT --input protect-develop.json
```

## 2. Branch Protection (empfohlene Einstellungen)

| Branch    | Anforderungen                                                                                                                                                               |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `main`    | Required Pull Request Reviews ≥ 1, Dismiss Stale Reviews, Blockierung direkter Pushes, Merge-Verbot bei failing Checks (`lint`, `test-go`, `test-js`, `security`, `deploy`) |
| `develop` | Required Pull Request Reviews ≥ 1, Verbot direkter Pushes, obligatorische Checks `lint`, `test-go`, `test-js`                                                               |

> Konfigurieren via GitHub UI oder
> `gh api repos/:owner/:repo/branches/<branch>/protection`.
> Konfigurations-Snapshot der Dokumentation beifügen.

## 3. GitHub Actions

- Workflows: `ci.yml`, `security.yml`, `deploy-environments.yml`
- Permissions bereits minimal (`contents:read`, `security-events:write`,
  `packages:write`)
- Sicherstellen, dass `develop` in Branch-Listen jedes Workflows vorhanden ist
  (im Code aktualisiert)

## 4. Secrets & Environments

Siehe `docs/reference/github-environments-setup.md`. Skripte ausführen:

```bash
./scripts/infrastructure/security/setup-github-environments.sh
./scripts/infrastructure/security/configure-environment-protection.sh
./scripts/infrastructure/security/setup-environment-secrets.sh
./scripts/infrastructure/security/validate-environment-secrets.sh
```

Validierungsergebnisse im Journal festhalten.

## 5. Templates und Verantwortlichkeit

- CODEOWNERS für CI/Sicherheit konfiguriert.
- Issue/PR-Templates und Dependabot aktiviert (siehe `.github/`).

## 6. Offene Aktionen

1. Remote-Branch `dev` → `develop` umbenennen und Protection Rules
   aktualisieren.
2. GitHub Environments und Secrets-Status bestätigen, Journal ausfüllen.
3. Required Status Checks für `main`/`develop` gemäß Liste in
   `docs/archive/audits/ci-health.md` hinzufügen.
