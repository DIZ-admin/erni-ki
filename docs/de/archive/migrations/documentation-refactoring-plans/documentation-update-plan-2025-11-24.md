---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Aktualisierungsplan Dokumentation ERNI-KI (2025-11-24)

**Basis:** `../../archive/audits/code-audit-2025-11-24.md` **Status:** Ready for
implementation

## Kurzfassung

10 Abweichungen zwischen Docs und realem Zustand; Übereinstimmung 95%.

- High: 3 Aufgaben
- [WARNING] Medium: 5 Aufgaben
- [OK] Low: 2 Aufgaben

Aufwand: 12–16 Stunden.

## Phase 1: Kritische Updates (High)

### Task 1.1 Auth Service – API-Doku hinzufügen

**Priorität:** · **Zeit:** 2–3h · **Datei:**
`docs/ru/reference/api/auth-service.md`

Inhalt (Auszug):

- Base URL: `http://auth:9090`, Version 1.0.0
- Endpoints: `/` (Status), `/health`, `/validate` (JWT aus Cookie)
- Responses 200/401 beschrieben
- Authentication Flow (Mermaid-Sequenzdiagramm)
