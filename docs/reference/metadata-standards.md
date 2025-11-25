---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Стандарты метаданных документации ERNI-KI

## Обязательные поля (для всех документов)

- `language` — `ru|de|en`
- `translation_status` — `complete|in_progress|pending|outdated`
- `doc_version` — `'2025.11'`

## Рекомендуемые поля

- `last_updated` — `'YYYY-MM-DD'`
- `system_version` — `'12.1'` (только для технических/архитектурных обзоров)
- `system_status` — `'Production Ready'` (если отражает готовность системы)

## Допустимые поля по необходимости

- `title` — заголовок (для новостей/блога)
- `description` — краткое описание (новости/блог)
- `tags` — теги (новости/блог)
- `date` — дата публикации (используется для новостей/блога)
- `page_id` — только для порталов/специфичной навигации

## Запрещённые/устаревшие поля

- `author`, `contributors`, `maintainer` — используйте git history
- `created`, `updated`, `created_date`, `last_modified` — используйте
  `last_updated`
- `version` — заменять на `system_version`
- `status` — заменять на `system_status` (для статуса системы) или `doc_status`
  (для статуса документа)

## Шаблоны

### Базовый

```yaml
---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---
```

### Технический (с версией системы)

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

### Новости/Блог

```yaml
---
language: ru
translation_status: complete
doc_version: '2025.11'
title: 'Заголовок новости'
date: 2025-11-20
description: 'Краткое описание'
tags: ['release', 'update']
---
```

### Минимальный

```yaml
---
language: ru
translation_status: complete
doc_version: '2025.11'
---
```

## Правила применения

1. **doc_version** фиксируется глобально и обновляется при релизе документации.
2. **system_version/system_status** применять только там, где описан реальный
   статус прод-стека.
3. **last_updated** задавать для всех активных (не архивных) документов.
4. **date** использовать только для новостей/блог-постов.
5. Не добавлять персональные поля (`author` и т.п.); rely on git blame/history.
