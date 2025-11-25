---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Refactoring-Plan v2 (2025-11-24)

> **Audits:**
>
> - [Erster Audit](../archive/audits/comprehensive-documentation-audit-2025-11-24.md)
> - [Refactoring-Fokus](../archive/audits/documentation-refactoring-audit-2025-11-24.md)  
>   [TOC]

## 🎯 Hauptprobleme

### Kritisch

1. 101 verwaiste Dokumente (54%) – keine eingehenden Links
2. 20 Stub-Dokumente (<50 Wörter) – Aktion nötig
3. EN-Coverage 18,2% – kritisch niedrig

### Wichtig

4. 39 Guides verstreut – konsolidieren
5. 4 Duplikate main/archive – prüfen
6. 4 Dokumente mit deprecation markers – aktualisieren

### Positiv

✅ Alle Docs <90 Tage alt, saubere Metadaten, kein veralteter Inhalt.

---

## 📋 Phasen

### Phase 1: Kritische Fixes (3 Tage) — Status: offen

**Tag 1: Stubs (20 Files)**

- EN Academy (7) – Redirects in mkdocs.yml, Stubs entfernen
- DE Academy (6) – analog
- Operations (4) erweitern:
  - de/operations/backup-guide.md
  - de/operations/troubleshooting.md
  - de/operations/database/database-production-optimizations.md
  - operations/database/database-production-optimizations.md
- Weitere (3) erweitern:
  - en/academy/openwebui-basics.md
  - en/academy/prompting-101.md
  - de/academy/openwebui-basics.md

**Tag 2: Duplikate + Deprecated**

- Check: operations/diagnostics/README.md vs archive/diagnostics/README.md
- Check: de/academy/prompting-101.md vs archive/training/prompting-101.md
- Check: de/academy/openwebui-basics.md vs archive/training/openwebui-basics.md
- Check: academy/howto/summarize-meeting-notes.md vs archive/howto/...
- Deprecation aktualisieren: architecture/architecture.md,
  reference/CHANGELOG.md, security/log-audit.md,
  operations/core/configuration-change-process.md

**Tag 3: Navigation README**

- Erstellen: operations/automation/README.md, operations/maintenance/README.md,
  operations/monitoring/README.md, operations/troubleshooting/README.md
- Aktualisieren: operations/core/README.md, operations/database/README.md,
  operations/diagnostics/README.md

**Ergebnis Phase 1:** 0 Stubs, 0 Duplikate, 0 deprecation markers, alle
operations-Unterordner mit README.

---

### Phase 2: Navigation & Connectivity (1 Woche) — Status: geplant

**Task 2.1: Hauptportale (2h)**

- docs/index.md strukturieren (Users/Admins/Developers/Správa), Links zu
  Academy, Getting Started, Operations, Monitoring, DB, Security, Architecture,
  API, Development, Glossary, Status.
- docs/de/index.md und docs/en/index.md angleichen.
