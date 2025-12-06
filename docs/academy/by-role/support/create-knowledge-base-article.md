---
title: 'Создание статей для Knowledge Base с ИИ'
category: support
difficulty: easy
duration: '10 min'
roles: ['support', 'technical-writer', 'qa']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Создание статей для Knowledge Base с ИИ

## Цель

Использовать ИИ для быстрого создания чётких, структурированных, и полезных
статей для внутренней или external knowledge base.

## Для кого

- **Support Engineers** — создание KB articles из tickets
- **Technical Writers** — documentation
- **QA** — troubleshooting guides
- **Developers** — technical how-to guides

## ⏱ Время выполнения

10-15 минут на статью

## Что вам понадобится

- Доступ к Open WebUI
- Информация для статьи (ticket details, процесс, или technical knowledge)
- **Рекомендуемая модель:** GPT-4o или Claude 3.5

---

## Базовый шаблон промпта

```markdown
Создай Knowledge Base article:

**Тема:** [о чём статья] **Аудитория:** [who will read: end users / internal
team / admins] **Формат:** [How-To / Troubleshooting / FAQ / Concept
explanation]

**Ключевая информация:**

- [пункт 1]
- [пункт 2]
- [пункт 3]

**Тон:** [friendly / professional / technical] **Длина:** [brief / detailed]

Структура должна включать:

- Краткое intro (что и зачем)
- Step-by-step инструкции (если applicable)
- Troubleshooting tips
- Related articles (если есть)
```

---

## Типы Knowledge Base статей

### 1. How-To Article (Пошаговая инструкция)

**Промпт:**

```markdown
Создай How-To article для Knowledge Base:

**Тема:** Как сбросить пароль в системе **Аудитория:** End users (не technical)
**Формат:** Step-by-step guide

**Информация:**

- Можно сбросить через email или SMS
- Email reset занимает ~5 минут
- SMS reset моментальный но требует verified phone number
- Временный пароль действителен 24 часа
- После первого входа система попросит сменить пароль

**Требования:**

- Ясные шаги с номерами
- Screenshots placeholders (где нужны)
- Warning о частых ошибках
- Estimated time: ~5 min
- Difficulty: Easy

Тон: Дружелюбный, простой язык
```

**Ожидаемый результат:**

```markdown
# Как сбросить пароль

**Время:** ~5 минут | **Сложность:** Лёгкая

## Когда использовать

Если вы забыли пароль или вам нужно его сменить.

## Шаги

### Вариант 1: Сброс через Email (рекомендуется)

1. Откройте страницу входа
2. Нажмите "Забыли пароль?" [Screenshot placeholder: Login page with "Forgot
   password" link]
3. Введите ваш email address
4. Нажмите "Отправить ссылку для сброса"
5. Проверьте inbox (письмо придёт в течение 5 минут)
6. Откройте письмо и кликните на ссылку
7. Введите новый пароль (минимум 8 символов)
8. Подтвердите новый пароль

⏱ **Время выполнения:** ~5 минут

### Вариант 2: Сброс через SMS (быстрый)

1. На странице "Забыли пароль?" выберите "SMS"
2. Введите verified phone number
3. Получите код (моментально)
4. Введите код
5. Создайте новый пароль

⏱ **Время выполнения:** ~1 минута

**Важно:** SMS доступен только если phone number verified.

## Частые проблемы

**Не получаю email?**

- Проверьте spam folder
- Подождите до 10 минут
- Убедитесь что email правильный

**Ссылка не работает?**

- Ссылка действительна 24 часа
- Попробуйте запросить новую ссылку

**SMS не приходит?**

- Проверьте что номер verified
- Используйте email вариант

## Требования к паролю

- Минимум 8 символов
- Минимум 1 заглавная буква
- Минимум 1 цифра
- Не должен совпадать с последними 5 паролями

## Нужна помощь?

Если проблемы сохраняются, обратитесь в support: support@company.com

## Связанные статьи

- [Как создать аккаунт]
- [Настройки безопасности]
- [Two-factor authentication setup]
```

---

### 2. Troubleshooting Guide

**Промпт:**

```markdown
Создай Troubleshooting guide:

**Проблема:** "Error 500 при загрузке файла" **Аудитория:** End users + Support
team

**Известные причины:**

1. Файл слишком большой (limit: 50MB)
2. Неподдерживаемый формат (только PDF, DOC, JPG, PNG)
3. Специальные символы в имени файла
4. Browser cache issues
5. Temporary server issues

**Решения:**

- Для причины 1: Compress файл или разделить на части
- Для причины 2: Convert в supported формат
- Для причины 3: Rename файл (только A-Z, 0-9, дефис, underscore)
- Для причины 4: Clear cache
- Для причины 5: Retry через 5 минут

**Структура:**

- Problem description
- Diagnostic steps
- Solutions ordered по вероятности
- Escalation path (когда обращаться в support)

Тон: Helpful, не patronizing
```

---

### 3. FAQ Article

**Промпт:**

```markdown
Создай FAQ article на основе частых вопросов:

**Тема:** Billing и Subscriptions **Аудитория:** Customers

**Частые вопросы из tickets:**

1. Как изменить plan? (45 tickets last month)
2. Можно ли отменить в любой момент? (38 tickets)
3. Что происходит после cancellation? (29 tickets)
4. Как получить invoice? (24 tickets)
5. Принимаете ли вы PayPal? (18 tickets)
6. Есть ли student discount? (15 tickets)
7. Автоматически ли продлевается subscription? (12 tickets)

**Ответы:** [для каждого вопроса краткая информация]

**Формат:**

- Вопросы sorted по частоте
- Краткие ясные ответы
- Links на детальные статьи где нужно
- Related questions в конце

Тон: Friendly, transparent
```

---

### 4. Concept Explanation (Technical)

**Промпт:**

```markdown
Создай technical explanation article:

**Концепт:** "Что такое API Rate Limiting и как это работает" **Аудитория:**
Developers using our API

**Информация:**

- Rate limit: 1,000 requests per hour per API key
- Limit resets каждый час (top of the hour)
- HTTP 429 error when exceeded
- Headers показывают remaining quota
- Different limits для different plan tiers

**Структура:**

1. Что такое rate limiting (simple explanation)
2. Почему мы используем это
3. Наши limits (по tier)
4. Как проверить current usage
5. Что делать если hit limit
6. Best practices для avoiding limit
7. Code examples (curl + Python)

Тон: Technical но accessible
```

---

## Создание статьи из Support Ticket

### Workflow: Ticket → KB Article

**Промпт:**

```markdown
Создай KB article на основе этого resolved ticket:

**Ticket #12345** **Problem:** User не может export данных в Excel, получает
corrupted файл **Reporter:** Customer (non-technical)

**Troubleshooting история:**

1. User пытался export большой dataset (50,000 rows)
2. Браузер: Chrome 120
3. Попробовали Firefox — та же проблема
4. Обнаружили что при export <10,000 rows работает нормально

**Root cause:** Excel format имеет performance issues с large datasets. CSV
работает лучше.

**Solution:**

- Для больших datasets используй CSV вместо Excel
- Или разбей export на smaller chunks
- CSV можно потом открыть в Excel

**Задача:** Создай "How to export large datasets" KB article чтобы другие users
не сталкивались с этой проблемой.

Включи:

- Problem description
- Recommended approach (CSV для больших данных)
- Step-by-step для обоих методов
- Когда использовать какой формат
```

---

## Продвинутые техники

### Техника 1: Creating Article Series

**Промпт:**

```markdown
Создай серию из 3 связанных articles:

**Topic:** Getting Started with our API

**Article 1: "API Authentication — Quick Start"**

- Для новичков
- Как получить API key
- First request example
- 5 минут reading

**Article 2: "Common API Endpoints"**

- Top 10 most-used endpoints
- Examples для каждого
- 10 минут reading

**Article 3: "API Best Practices"**

- Rate limiting
- Error handling
- Pagination
- Security
- 15 минут reading

Для каждой статьи создай:

- Intro с ссылками на другие в серии
- "Next steps" секция
- Consistent formatting

Цель: Progressive learning path
```

---

### Техника 2: Video Script → Article

**Промпт:**

```markdown
У нас есть video tutorial (5 минут). Создай written KB article covering то же
самое.

**Video summary:**

- Shows how to create custom dashboard
- Demonstrates drag-and-drop widgets
- Explains filtering options
- Shows saving and sharing

**Требования для article:**

- Screenshots placeholders в key points
- Same info как video но text format
- Может быть более detailed (text searchable!)
- Add troubleshooting раздел (которого нет в video)
- Link to video для тех кто предпочитает watch

Audience: All user levels
```

---

### Техника 3: Multi-Language KB

**Промпт:**

```markdown
Создай KB article на русском, потом адаптируй для English version:

**Topic:** [ваша тема]

**Русская версия:** [article content]

**Задачи для English версии:**

1. Translate
2. Адаптируй примеры если нужно (currency, date formats, etc)
3. Сохрани структуру и formatting
4. Verify technical terms правильно переведены
5. Add locale-specific notes if needed (e.g., "This feature available in EU
   regions only")

Include metadata:

- language: ru / en
- last_updated
- version_sync: [both versions aligned]
```

---

## Структурные шаблоны

### Шаблон 1: Problem-Solution Format

```markdown
# [Problem Title]

## Симптомы

[Как user узнаёт что у него эта проблема]

## Причина

[Почему это происходит — простым языком]

## Решение

[Step-by-step fix]

## Предотвращение

[Как избежать в будущем]

## Если проблема сохраняется

[Escalation path]
```

### Шаблон 2: Task-Based Format

```markdown
# Как [выполнить задачу]

**Время:** [estimate] **Сложность:** [Easy/Medium/Hard] **Требования:** [что
нужно before starting]

## Зачем это нужно

[Brief context]

## Шаги

1. [Step]
2. [Step]
3. [Step]

## Проверка успешности

[Как понять что всё сработало]

## Что дальше

[Next steps or related tasks]
```

### Шаблон 3: Reference Guide Format

```markdown
# [Feature Name] — Reference Guide

## Обзор

[Что это и зачем]

## Основные функции

### Функция 1

- Что делает
- Как использовать
- Пример

### Функция 2

[аналогично]

## Параметры и настройки

[Таблица или список с descriptions]

## Примеры использования

[Real-world scenarios]

## Ограничения

[Что НЕ делает]

## FAQ

[Частые вопросы про эту feature]
```

---

## Важные правила качества

### Правило 1: Testability

```markdown
ХОРОШО: "1. Нажмите кнопку 'Save' 2. Вы увидите зелёное сообщение 'Saved
successfully' 3. Изменения отобразятся в таблице немедленно"

ПЛОХО: "Сохраните изменения и они применятся"
```

**Почему:** User должен знать что success выглядит как.

---

### Правило 2: Screenshots Are Essential

```markdown
Добавь placeholders для screenshots:

"[Screenshot: Main dashboard with 'Export' button highlighted]" "[Screenshot:
Export dialog with CSV option selected]"

Потом кто-то создаст real screenshots на основе placeholders.
```

---

### Правило 3: Keep It Updated

```markdown
Включи в article metadata:

---

created: 2025-12-04 last_updated: 2025-12-04 applies_to_version: v2.5+
review_frequency: quarterly owner: support-team

---

Это помогает track когда article needs refresh.
```

---

### Правило 4: Searchability

```markdown
Включи keywords которые users могут искать:

Плохой title: "Issue with Files" Хороший title: "Error 500 When Uploading Files
— Troubleshooting"

Включи synonyms: "Also known as: file upload error, can't upload, upload fails"
```

---

## Чек-лист перед публикацией

- [ ] Title ясный и descriptive
- [ ] Аудитория указана (for whom)
- [ ] Estimated reading time
- [ ] Steps numbered и testable
- [ ] Screenshots placeholders added
- [ ] Common problems addressed
- [ ] Related articles linked
- [ ] Contact info для escalation
- [ ] Metadata complete (date, version, owner)
- [ ] Кто-то проверил technical accuracy
- [ ] Language simple (или appropriate для audience)

---

## Pro Tips

### Tip 1: Start with User's Words

```markdown
"Вместо technical terminology в title:

'HTTP 429 Response Code Handling' 'Fix: Too Many Requests Error'

Users ищут в своих словах, не в tech terms."
```

### Tip 2: Add "Related Questions"

```markdown
В конце article:

## Вас также может интересовать:

- [How to delete account]
- [Privacy settings explained]
- [Data export options]

Это снижает follow-up tickets.
```

### Tip 3: Version History

```markdown
Для important articles, track changes:

## Version History

- v1.2 (2025-12-04): Added SMS reset option
- v1.1 (2025-11-15): Updated password requirements
- v1.0 (2025-10-01): Initial version
```

---

## Metrics для KB статьи

**Промпт для анализа:**

```markdown
Проанализируй эти metrics для KB article:

Article: "How to Reset Password" Views last month: 450 Avg time on page: 2:30
"Was this helpful?": 85% yes, 15% no Comments: 8 (mostly positive, 2 requests
for video version)

Compare to other popular articles:

- Top article: 1,200 views, 3:15 time, 92% helpful
- Avg article: 180 views, 1:45 time, 78% helpful

Questions:

1. Performing well или нужны improvements?
2. Почему time on page ниже чем top article?
3. Стоит ли создавать video version (based на comments)?
4. Recommendations для improving helpfulness score?
```

---

## Дальнейшее изучение

- [Troubleshoot User Issue](troubleshoot-user-issue.md)
- [Write Professional Email](../general-users/write-professional-email.md)
- [Prompting Fundamentals](../../fundamentals/prompting-fundamentals.md)

---

## Практическое задание

Попробуйте создать KB article:

**Сценарий:** У вас есть ticket: "User can't find export button"

**Root cause:** Export moved в dropdown menu (не кнопка), users ищут кнопку.

**Задача:** Создайте KB article "Where is the Export button?" чтобы users смогли
self-serve.

**Требования:**

- Clear title
- Quick answer upfront
- Step-by-step с screenshot placeholders
- Note про недавнее изменение UI
- 2-3 минуты reading time

---

**Время прочтения:** ~10 минут **Следующий сценарий:**
[Troubleshoot User Issue →](troubleshoot-user-issue.md)
