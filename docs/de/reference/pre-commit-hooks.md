---
language: de
translation_status: partial
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Pre-commit Hooks für ERNI-KI

**Cleaning-Tipp:** Lokale Artefakte (z. B. `.DS_Store`, Backup-Dateien) kannst
du mit `scripts/utilities/git-clean-safe.sh` entfernen. Das Script ruft
`git clean -fdX` auf und schont `.git/hooks`, damit pre-commit installiert
bleibt. Für eine Vorschau `CLEAN_DRY_RUN=1 scripts/utilities/git-clean-safe.sh`.

_Restliche Hook-Beschreibung wird aus der RU-Fassung übernommen; Status =
partial._
