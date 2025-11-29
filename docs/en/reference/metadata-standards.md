---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Documentation Metadata Standards (ERNI-KI)

## Required fields (all docs)

- `language` — `ru|de|en`
- `translation_status` — `complete|in_progress|pending|outdated`
- `doc_version` — `'2025.11'`

## Recommended fields

- `last_updated` — `'YYYY-MM-DD'`
- `system_version` — `'12.1'` (only for technical/architecture overviews)
- `system_status` — `'Production Ready'` (if it reflects system readiness)

## Optional fields when needed

- `title` — title (for news/blog)
- `description` — short description (news/blog)
- `tags` — tags (news/blog)
- `date` — publication date (news/blog)
- `page_id` — only for portals/special navigation

## Forbidden/deprecated fields

- `author`, `contributors`, `maintainer` — use git history instead
- `created`, `updated`, `created_date`, `last_modified` — use `last_updated`
- `version` — replace with `system_version`
- `status` — replace with `system_status` (system status) or `doc_status`
  (document status)

## Templates

### Basic

```yaml
---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---
```

### Technical (with system version)

```yaml
---
language: en
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
language: en
translation_status: complete
doc_version: '2025.11'
title: 'News title'
date: 2025-11-20
description: 'Short description'
tags: ['release', 'update']
---
```

### Minimal

```yaml
---
language: en
translation_status: complete
doc_version: '2025.11'
---
```

## Usage rules

1.**doc_version**is global and updated on docs
release. 2.**system_version/system_status**apply only where the production stack
status is described. 3.**last_updated**must be set for all active (non-archive)
docs. 4.**date**only for news/blog posts. 5. Do not add personal fields
(`author`, etc.); rely on git history/blame.
