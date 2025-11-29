---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Metadaten-Standards für die ERNI-KI-Dokumentation

## Pflichtfelder (für alle Dokumente)

- `language` — `ru|de|en`
- `translation_status` — `complete|in_progress|pending|outdated`
- `doc_version` — `'2025.11'`

## Empfohlene Felder

- `last_updated` — `'YYYY-MM-DD'`
- `system_version` — `'12.1'` (nur für technische/architektonische Übersichten)
- `system_status` — `'Production Ready'` (wenn der Systemstatus beschrieben
  wird)

## Optionale Felder bei Bedarf

- `title` — Titel (für News/Blog)
- `description` — Kurzbeschreibung (News/Blog)
- `tags` — Tags (News/Blog)
- `date` — Veröffentlichungsdatum (News/Blog)
- `page_id` — nur für Portale/spezielle Navigation

## Verbotene/obsolet Felder

- `author`, `contributors`, `maintainer` — stattdessen git history nutzen
- `created`, `updated`, `created_date`, `last_modified` — `last_updated`
  verwenden
- `version` — durch `system_version` ersetzen
- `status` — durch `system_status` (Systemstatus) oder `doc_status`
  (Dokumentenstatus) ersetzen

## Vorlagen

### Basis

```yaml
---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---
```

### Technisch (mit Systemversion)

```yaml
---
language: de
translation_status: complete
doc_version: '2025.11'
system_version: '12.1'
system_status: 'Production Ready'
last_updated: '2025-11-23'
---
```

### News/Blog

```yaml
---
language: de
translation_status: complete
doc_version: '2025.11'
title: 'News-Titel'
date: 2025-11-20
description: 'Kurze Beschreibung'
tags: ['release', 'update']
---
```

### Minimal

```yaml
---
language: de
translation_status: complete
doc_version: '2025.11'
---
```

## Anwendungsregeln

1.**doc_version**ist global und wird beim Docs-Release
aktualisiert. 2.**system_version/system_status**nur dort setzen, wo der Zustand
des Produktions-Stacks beschrieben wird. 3.**last_updated**für alle aktiven
(nicht archivierten) Dokumente setzen. 4.**date**nur für News/Blog-Beiträge. 5.
Keine personenbezogenen Felder (`author` usw.) hinzufügen; git history/blame
verwenden.
