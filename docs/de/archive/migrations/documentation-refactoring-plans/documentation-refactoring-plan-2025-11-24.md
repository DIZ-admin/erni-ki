---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Refactoring-Plan für die ERNI-KI-Dokumentation (2025-11-24)

> **Vollständiger Audit:**
> `../archive/audits/comprehensive-documentation-audit-2025-11-24.md`

[TOC]

## Kurzfassung des Audits

**Bewertung:**7.5/10**Stats:**194 Dateien (161 aktiv + 33 Archiv).
Übersetzungen: DE ≈41% (36/88 RU), EN ≈6% (5/88 RU). 37 deprecated Metadaten, 6
kaputte Links, 61 Dateien ohne TOC.

**Kritisch:**

1. EN-Coverage 19.5%
2. 37 Dateien mit deprecated Feldern
3. 61 lange Docs ohne TOC
4. 0 Bilder in den Docs

---

## Phasen

### Phase 1: Quick Fixes (1 Tag) — Status: offen

- Deprecated Metadaten korrigieren (2h) — `status`→`system_status`,
  `version`→`system_version`; Script
  `python3 scripts/fix-deprecated-metadata.py`
- Frontmatter ergänzen (15m) — `reference/status-snippet.md`,
  `de/reference/status-snippet.md`
- Kaputte Links fixen (30m) — 3 in `de/security/README.md`, 2 in
  `de/getting-started/installation.md`, 1 in
  `operations/monitoring/prometheus-alerts-guide.md`
- TOC in Top-10 langen Docs (1h) — u. a.
  `operations/monitoring/monitoring-guide.md`, `reference/api-reference.md`,
  `architecture/architecture.md`
- READMEs für alle `operations/*`-Unterordner erstellen

**Ergebnis:**0 deprecated Felder, 0 kaputte Links, TOC in Top-10, alle
operations-Unterordner mit README.

### Phase 2: Content-Qualität (1 Woche) — Status: ⏳ geplant

- Heading-Struktur reparieren (3h), Fokus reference/architecture/security
- Kurze Dateien (<100 Wörter) erweitern oder entfernen (4h)
- TODO/FIXME abschließen (2h): `security/security-policy.md`,
  `en/security/security-policy.md`, `de/security/security-policy.md`,
  `operations/core/configuration-change-process.md`
- TOC für restliche >500-Wort-Dokumente (4h, Batch)
- MkDocs verbessern (Sitemap etc.) (4h)
