---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-30'
title: 'Style Guide'
---

# Руководство по стилю ERNI-KI

Документ определяет правила оформления текстов, кода и визуальных элементов во
всех материалах ERNI-KI.

## 1. Frontmatter и метаданные

Каждый Markdown-файл обязан иметь YAML-блок с полями:

```yaml
---
language: ru|en|de
translation_status: original|complete|partial|pending
doc_version: 'YYYY.MM'
last_updated: 'YYYY-MM-DD'
title: 'Название'
---
```

Дополнительно:

- `system_version` и `system_status` для эксплуатационных документов.
- `category`/`tags` используются в архивах.

## 2. Структура и заголовки

- Один H1 на документ (`# Title`), далее иерархия H2/H3.
- Блоки `##` разделяются горизонтальной линией `---`, если необходимо визуально
  отделить разделы.
- Разделы «Purpose», «Audience», «Last updated» указываются в первых абзацах для
  операционных и SLA документов.

## 3. Язык и терминология

- Русский/английский/немецкий — в отдельных файлах и каталогах (`docs/en/...`).
- Термины (SLA, RAG, GPU) не переводим, если нет закреплённого перевода.
- Запрещены эмодзи и декоративные символы (см.
  `docs/reference/NO-EMOJI-POLICY.md`).
- Списки задач оформляем в формате Markdown checklist (`- [ ]`).

## 4. Ссылки и кодовые блоки

- Внутренние ссылки — относительные пути (например,
  `[Monitoring Guide](../operations/monitoring/monitoring-guide.md)`).
- Каждое оформление кода имеет подпись с языком:

```bash
docker compose ps
```

```yaml
prometheus:
  image: prom/prometheus:v3.0.1
```

- Фрагменты должны быть окружены пустыми строками (требование markdownlint).

## 5. Таблицы и списки

- Таблицы используют выравнивание по умолчанию, колонки подписаны.
- Даты в ISO (`2025-11-30`), числа формата `1 024` не допускаются — используем
  `1024` или `1,024`.

## 6. Оформление кода и конфигураций

- Кодовые примеры для Python, Go, TypeScript оформлены по правилам из
  `docs/quality/code-standards.md`.
- Bash-скрипты используют `#!/usr/bin/env bash`, отступы 2 пробела.
- Конфиги YAML выравниваются пробелами, ключи в `snake_case`.

## 7. Переводы

- Каждый RU-документ, обязанный иметь перевод, содержит поле
  `translation_status`. При обновлении русской версии создаём issue/PR для
  EN/DE.
- Файлы в `docs/en/` и `docs/de/` должны ссылаться на RU-оригинал через заметку
  «Russian version is source of truth».

## 8. Иллюстрации и диаграммы

- Диаграммы хранятся в `docs/architecture/diagrams/` с README описанием.
- Все изображения в Markdown сопровождаются `alt`-текстом.

## 9. Проверки качества

- Перед коммитом запускается `pre-commit` (prettier, markdownlint, lychee).
- Документы должны проходить `scripts/docs/validate_metadata.py`.
- Для статусных вставок используется `scripts/docs/update_status_snippet.py`.

Соблюдение данного руководства контролируется в CI (markdownlint, no-emoji,
link-check). Нарушения блокируют мердж.
