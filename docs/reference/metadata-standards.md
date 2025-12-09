---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI Documentation Metadata Standards

## Required Fields (for all documents)

- `language` — `ru|de|en`
- `translation_status` — `complete|in_progress|pending|outdated`
- `doc_version` — `'2025.11'`

## Recommended Fields

- `last_updated` — `'YYYY-MM-DD'`
- `system_version` — `'12.1'` (only for technical/architectural overviews)
- `system_status` — `'Production Ready'` (if reflecting system readiness)

## Optional Fields As Needed

- `title` — title (for news/blog)
- `description` — brief description (news/blog)
- `tags` — tags (news/blog)
- `date` — publication date (used for news/blog)
- `page_id` — only for portals/specific navigation

## Deprecated/Forbidden Fields

- `author`, `contributors`, `maintainer` — use git history
- `created`, `updated`, `created_date`, `last_modified` — use `last_updated`
- `version` — replace with `system_version`
- `status` — replace with `system_status` (for system status) or `doc_status`
  (for document status)

## Templates

### Basic

```yaml
---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---
```

### Technical (with system version)

```yaml
---
language: ru
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
language: ru
translation_status: complete
doc_version: '2025.11'
title: 'News Title'
date: 2025-11-20
description: 'Brief description'
tags: ['release', 'update']
---
```

### Minimal

```yaml
---
language: ru
translation_status: complete
doc_version: '2025.11'
---
```

## Application Rules

1. **doc_version** is fixed globally and updated on documentation release.
2. **system_version/system_status** apply only where actual prod-stack status is
   described.
3. **last_updated** should be set for all active (non-archived) documents.
4. **date** use only for news/blog posts.
5. Do not add personal fields (`author` etc.); rely on git blame/history.
