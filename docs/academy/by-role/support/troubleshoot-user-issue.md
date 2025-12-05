---
title: 'Диагностика проблем пользователей с ИИ'
category: support
difficulty: medium
duration: '10 min'
roles: ['support', 'helpdesk', 'customer-success']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Диагностика проблем пользователей с ИИ

## Цель

Использовать ИИ для быстрой диагностики технических проблем, создания
troubleshooting guides, и улучшения first-call resolution.

## Для кого

- **Support Engineers** — L1/L2 support
- **Helpdesk** — первая линия поддержки
- **Customer Success** — proactive support

## ⏱ Время выполнения

5-15 минут на тикет

## Что вам понадобится

- Доступ к Open WebUI
- Описание проблемы от пользователя
- Logs/error messages (если есть)
- **Рекомендуемая модель:** Claude 3.5 (точнее для диагностики) или GPT-4o

---

## Базовый workflow диагностики

### Шаг 1: Структурируйте проблему

**Промпт:**

```markdown
Помоги диагностировать user issue:

**Reported Problem:** [описание от пользователя своими словами]

**System:**

- Product: [название]
- Version: [если известна]
- Environment: [browser/OS/device]

**Steps to reproduce:** [если известны]

**Expected behavior:** [что должно быть] **Actual behavior:** [что происходит]

**Error messages:** [если есть]

Предложи:

1. Вероятные причины (упорядочи по вероятности)
2. Diagnostic questions для пользователя
3. Troubleshooting steps
```

---

## Типы проблем и подходы

### Тип 1: "Не работает" (vague problem)

**Пользователь:** "Приложение не работает"

**Промпт для уточнения:**

```
User сообщает: "The application doesn't work"

Это слишком vague. Создай:

1. **Clarifying questions** (5-7 вопросов):
 - Что конкретно не работает?
 - Когда началась проблема?
 - Что вы пытались сделать?
 - Видите ли вы error message?
 - etc.

2. **Email template** для отправки пользователю:
 Тон: helpful, professional
 Цель: получить больше информации

Format questions с checkboxes/numbering для легкости ответа.
```

**Результат:** Structured questionnaire для пользователя

---

### Тип 2: Error Message

**Пользователь:** "Вижу ошибку: Connection timeout"

**Промпт:**

```
User получает error: "Connection timeout after 30 seconds"

Context:
- Web application
- Happens when uploading large files
- Started yesterday

Проанализируй:

1. **Possible causes** (technical):
 - Network issues
 - Server capacity
 - File size limits
 - etc.

2. **User-facing explanations**:
 (Non-technical language for each cause)

3. **Troubleshooting steps**:
 - Quick fixes to try
 - Workarounds
 - Escalation criteria

4. **Prevention tips**:
 Как избежать в будущем
```

---

### Тип 3: Performance Issue

**Пользователь:** "Система очень медленная"

**Промпт:**

```
User complains: "System is very slow"

Details:
- Started this morning
- Affects dashboard loading
- Other features work fine

Create diagnostic workflow:

**Phase 1: Information gathering**
- Questions to ask user
- Data to collect (browser console, network tab)

**Phase 2: Initial checks**
- Common causes of slow dashboard
- Quick tests to isolate issue

**Phase 3: Solutions** по категориям:
- Client-side fixes
- Cache clearing
- Browser optimization
- When to escalate

Format: Step-by-step troubleshooting guide
```

---

## Продвинутые техники

### Техника 1: Root Cause Analysis

```
User issue pattern:

Last week: 3 tickets про "login fails"
This week: 5 tickets про "login fails"
All users: Chrome browser
All times: между 9-10am

Проведи root cause analysis:

1. Pattern recognition:
 - Что общего у всех cases?
 - Timing correlation?
 - Environment factors?

2. Hypotheses:
 (упорядочи по вероятности)

3. Tests для каждой hypothesis:
 Как проверить?

4. Recommended escalation:
 К какой команде? С какой информацией?
```

### Техника 2: Knowledge Base Search

```
У нас есть эти KB articles:

Article 1: "How to reset password"
Article 2: "Browser compatibility issues"
Article 3: "File upload size limits"
Article 4: "Network troubleshooting"

User problem: "Can't upload my document, says file too large"

Какие KB articles relevant?
Составь response используя info из relevant articles.
Добавь troubleshooting steps не покрытые в KB.
```

### Техника 3: Multi-user Issue Correlation

```
Analyzing multiple tickets:

Ticket #123: User A - "Can't access dashboard" - 10:15am
Ticket #124: User B - "Dashboard blank screen" - 10:17am
Ticket #125: User C - "Dashboard not loading" - 10:20am

Это isolated issues или system-wide problem?

Если system-wide:
- Suggest checking service status
- Draft incident notification
- Escalation to ops team

Если isolated:
- Common factors among affected users?
- Troubleshooting for individual cases
```

---

## Response Templates

### Template 1: Диагностика в процессе

```
Создай response email:

Статус: investigating
User problem: [описание]

Include:
1. Acknowledge issue
2. We're investigating
3. Info we collected so far
4. Workaround (если есть)
5. Timeline for update
6. Ticket number

Tone: Empathetic, professional
Length: Brief, scannable
```

### Template 2: Решение найдено

```
Создай solution email:

Problem: [описание]
Root cause: [техническое объяснение]
Solution: [что сделали]

For user:
1. Non-technical explanation причины
2. Step-by-step что мы сделали
3. How to verify it's fixed
4. Prevention tips
5. Apology если applicable

Tone: Helpful, clear
Include: Ticket closed, but contact us if issues persist
```

### Template 3: Escalation к разработке

```
Создай internal escalation:

User ticket: #[number]
Summary: [brief]
Severity: [High/Medium/Low]

Technical details:
- Error logs: [paste]
- Reproduction steps: [detailed]
- Affected users: [count/scope]
- Frequency: [how often]

Tried troubleshooting:
- [step 1]: [result]
- [step 2]: [result]

Needs:
- Dev investigation
- Code fix / Config change
- ETA for fix

For dev team tone: Technical, complete info
```

---

## Специфичные сценарии

### Сценарий 1: Login Issues

**Prompt:**

```
User can't login. Error: "Invalid credentials"

Diagnostic tree:

1. Check: Password correct?
 Yes → Go to 2
 No → Password reset flow

2. Check: Account active?
 Yes → Go to 3
 No → Account activation needed

3. Check: Browser issues?
 Test: Incognito mode
 Test: Different browser

4. Check: Cookies/cache?
 Clear and retry

5. Still failing?
 Escalate with: [specific data]

Create this as user-friendly troubleshooting guide.
```

### Сценарий 2: Integration Problem

**Prompt:**

```
User: "Integration with [3rd party system] stopped working"

Diagnostic approach:

1. **Isolate the problem:**
 - Was it working before?
 - When did it stop?
 - What changed?

2. **Check integration points:**
 - API credentials valid?
 - Network connectivity?
 - 3rd party system status?

3. **Test scenarios:**
 - Simple test request
 - Check logs both sides

4. **Resolution paths:**
 By cause category

Формат: Decision tree для support agent
```

### Сценарий 3: Data Discrepancy

**Prompt:**

```
User reports: "Numbers in report don't match my calculations"

Troubleshooting:

1. **Understand the discrepancy:**
 Questions to ask:
 - Which numbers specifically?
 - What's your calculation?
 - What time period?

2. **Common causes:**
 - Timezone differences
 - Filtered data
 - Calculation methodology
 - Data sync delay

3. **Verification steps:**
 For each cause, how to check

4. **Explanation for user:**
 Non-technical reasons why numbers might differ

Create FAQ-style explanation.
```

---

## Creating Knowledge Base Articles

### От ticket к KB article

**Prompt:**

```
Вот resolved ticket который повторяется:

Problem: [описание]
Solution: [что помогло]
Frequency: 5 tickets this month

Создай KB article:

**Title:** [clear, searchable]

**Problem description:**
(Как users описывают проблему)

**Symptoms:**
- [что видит user]

**Causes:**
[объяснение non-technical]

**Solution:**
[step-by-step с screenshots placeholders]

**Prevention:**
[как избежать]

**Related articles:**
[links to similar issues]

Format: User-friendly, numbered steps, clear headers
```

---

## Важные правила

### Security Awareness

```
 НИКОГДА не просите в ИИ:
- User passwords
- API keys
- Personal identifiable information
- Payment details

 Используйте placeholders:
"User ID: [User123]"
"Account: [Account_XYZ]"
```

### Response Time Expectations

```
При создании response укажите realistic timeline:

"Investigating this issue. Will update within:
- Critical: 2 hours
- High: 4 hours
- Medium: 24 hours
- Low: 48 hours"

ИИ может помочь categorize severity.
```

---

## Чек-лист Support Ticket

### При получении ticket:

- [ ] Собрал все доступные детали
- [ ] Severity правильно оценен
- [ ] User acknowledged (received confirmation)
- [ ] Начал diagnostic process

### При диагностике:

- [ ] Проверил known issues
- [ ] Проверил KB articles
- [ ] Воспроизвёл problem (если possible)
- [ ] Определил scope (one user vs many)

### Перед response:

- [ ] Solution tested (если applicable)
- [ ] Response ясный и actionable
- [ ] No technical jargon (unless technical user)
- [ ] Next steps определены

### После resolution:

- [ ] User confirmed fix
- [ ] Ticket documented properly
- [ ] KB updated (если новое issue)
- [ ] Escalated если нужно

---

## Pro Tips

### Tip 1: Build Problem Library

```
Сохраняйте successful diagnostic prompts:

"Эта проблема похожа на ticket #456 которое мы решили.
Используй тот же diagnostic approach но адаптируй для: [details]"
```

### Tip 2: Batch Similar Issues

```
"У меня 5 tickets про похожую проблему:
[краткое описание каждого]

Это одна root cause или разные?
Какой unified troubleshooting guide создать?"
```

### Tip 3: Improve Over Time

```
"Вот мой response на similar issue last month:
[старый response]

User feedback: [что можно улучшить]

Создай improved version учитывая feedback."
```

---

## Дальнейшее изучение

- [Create Knowledge Base Articles](create-knowledge-base-article.md)
- [Write Professional Email](../general-users/write-professional-email.md)
- [Prompting Fundamentals](../../fundamentals/prompting-fundamentals.md)

---

**Следующий сценарий:**
[Create Knowledge Base Article →](create-knowledge-base-article.md)
