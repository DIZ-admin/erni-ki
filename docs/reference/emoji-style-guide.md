---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Emoji Style Guide'
---

# Руководство по использованию emoji в документации ERNI-KI

## Стандартные emoji по категориям

### Безопасность и аутентификация

- Основной emoji для security
- Для reliability/защиты
- Для критических проблем безопасности

### Мониторинг и метрики

- Основной emoji для monitoring
- Для performance/графиков
- Для degradation/проблем

### Базы данных

- Общие БД
- PostgreSQL
- Redis
- Storage/диски

### Сетевые сервисы и API

- API endpoints
- Network/web
- Gateway/proxy

### Статус-индикаторы

- Success/Healthy/Complete
- Warning/Needs attention
- Error/Failed
- Critical/High priority

### Обновления и новости

- Updates/новые фичи
- Improvements/улучшения
- New components
- Configuration/setup

### Документация

- Lists/overviews
- Guides/руководства
- Notes/примечания
- Documents/файлы

## Примеры использования

### ПРАВИЛЬНО

```markdown
## Безопасность системы

### Мониторинг Redis

#### PostgreSQL конфигурация
```

### НЕПРАВИЛЬНО

```markdown
## Безопасность системы # Используйте

### Мониторинг Redis # Используйте

#### PostgreSQL конфигурация # Используйте
```
