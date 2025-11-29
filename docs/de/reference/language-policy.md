---
language: de
translation_status: complete
doc_version: '2025.11'
title: 'Sprachrichtlinie für Inhalte'
system_version: '12.1'
last_updated: '2025-11-25'
system_status: 'Production Ready'
audience: 'contributors'
summary: 'Regeln für Sprache in Code und Dokumentation von ERNI-KI'
---

# Sprachrichtlinie

1.**Code, Configs und Skripte immer auf Englisch**: Kommentare, Log-Messages,
Fehler und CLI-Ausgaben dürfen keine kyrillischen oder deutschen Zeichen
enthalten. 2.**Dokumentation nur ru/de/en**: `docs/` = RU, `docs/de/` = DE,
`docs/en/` = EN. Neue Dateien müssen `language: <locale>` im Frontmatter
enthalten. 3.**Lokalisierte Inhalte**(z. B. Status-Snippet) liegen in `docs/*`
oder separaten JSON/YAML-Dateien – nicht im Quellcode.

# Automatische Prüfung

- Lokal: `npm run lint:language` für staged Files.
- Vollständig: `node scripts/language-check.cjs --all`.
- CI (`.github/workflows/ci.yml`) blockiert PRs bei Verstößen.

# Baseline

`language-policy.config.json` listet historische Dateien mit Rest-Kyrillisch.
Sie erscheinen als `Language policy baseline`, damit sie schrittweise bereinigt
werden. Nur hinzufügen wenn:

- abgestimmter Plan zur schrittweisen Bereinigung existiert, und
- der PR den Übersetzungsplan erwähnt.

Nach Übersetzung den Eintrag entfernen und
`node scripts/language-check.cjs --all` ausführen.

# PR-Checkliste

1. Alle Kommentare/Meldungen in `.ts/.js/.sh/.py/.yml` auf Englisch.
2. Lokalisierte Texte in `docs/` oder JSON/YAML ausgelagert.
3. `npm run lint:language -- --all` erfolgreich.
