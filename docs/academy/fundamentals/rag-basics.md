---
title: 'Основы RAG (Retrieval-Augmented Generation)'
level: intermediate
duration: '20 min'
prerequisites: ['prompting-fundamentals.md', 'context-management.md']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Основы RAG (Retrieval-Augmented Generation)

## Что вы узнаете

- Что такое RAG и зачем он нужен
- Как работает RAG под капотом
- Как загружать и использовать документы
- Best practices для эффективного RAG
- Troubleshooting частых проблем

## ⏱ Требуемое время

20 минут

## Предварительные требования

- Прочитали [Prompting Fundamentals](prompting-fundamentals.md)
- Понимаете [Context Management](context-management.md)

---

## Что такое RAG?

**RAG (Retrieval-Augmented Generation)** — это техника, которая позволяет ИИ
работать с вашими документами.

### Простая аналогия

**Без RAG:**

```
Вы: Что говорится в нашем contract про payment terms?
ИИ: Я не имею доступа к вашему contract.
 Могу дать общую информацию про payment terms.
```

**С RAG:**

```
Вы: [загружаете contract.pdf]
Вы: Что говорится в этом contract про payment terms?
ИИ: [читает contract]
 Согласно Section 5.2, payment terms следующие: ...
 [точная информация из вашего документа]
```

---

## Как работает RAG?

### Процесс в 4 шага:

```
1. UPLOAD (Загрузка)
 Вы прикрепляете документ (PDF, DOCX, etc)

2. CHUNKING (Разбиение)
 Документ разбивается на небольшие части (chunks)
 Например: по параграфам или по 500 слов

3. EMBEDDING (Векторизация)
 Каждый chunk превращается в математический vector
 (набор чисел, представляющий смысл текста)

4. STORAGE (Хранение)
 Vectors сохраняются в vector database
```

### Когда вы задаёте вопрос:

```
1. QUERY (Запрос)
 Ваш вопрос тоже превращается в vector

2. SEARCH (Поиск)
 Система ищет chunks похожие на ваш вопрос
 (векторное сходство)

3. RETRIEVAL (Извлечение)
 Находит top 3-5 наиболее релевантных chunks

4. GENERATION (Генерация)
 ИИ читает найденные chunks и отвечает на вопрос
```

### Визуально:

```
Ваш документ:

 Introduction → Chunk 1 → [0.2, 0.8, ...]
 ...

 Section 1: Overview → Chunk 2 → [0.5, 0.3, ...]
 ...

 Section 2: Payment Terms → Chunk 3 → [0.1, 0.9, ...]
 - Net 30 days
 - Wire transfer preferred

Ваш вопрос: "payment terms"
 → Vector: [0.15, 0.85, ...]
 → Похож на Chunk 3!
 → ИИ читает Chunk 3 и отвечает
```

---

## Как использовать RAG в Open WebUI

### Шаг 1: Загрузка документа

**Способ 1: Прикрепление к сообщению**

```
1. Нажмите значок в поле ввода
2. Выберите файл (PDF, DOCX, TXT)
3. Дождитесь загрузки (иконка станет зелёной)
4. Задайте вопрос
```

**Способ 2: Через Knowledge Base (если настроена)**

```
1. Откройте Settings → Knowledge Base
2. Upload документы
3. Они будут доступны для всех чатов
```

### Шаг 2: Задайте вопрос о документе

**Базовый запрос:**

```
Что говорится в этом документе про [тема]?
```

**Лучше:**

```
Прочитай загруженный документ и ответь:
1. Что говорится про [тема]?
2. Приведи точные цитаты из документа
3. Укажи в каком разделе/на какой странице найдена информация
```

---

## Best Practices для эффективного RAG

### Practice 1: Специфичные вопросы

```
 ПЛОХО:
"Расскажи про этот документ"
[Слишком общее, ИИ не знает что искать]

 ХОРОШО:
"Какие три ключевые risk mitigation strategies упоминаются
в Section 4 этого документа?"
[Конкретный вопрос, ясная scope]
```

### Practice 2: Просите цитаты

```
Всегда добавляйте:
"Приведи точные цитаты из документа"
"Укажи номера страниц/разделов"

Почему: ИИ может "галлюцинировать" даже с RAG.
Цитаты позволяют проверить информацию.
```

### Practice 3: Разбивайте большие документы

```
 Загружать 200-страничный PDF целиком
 [Система может не обработать весь документ]

 Разбейте на части:
 - Part 1: Pages 1-50
 - Part 2: Pages 51-100
 - etc.

Или задавайте вопросы про конкретные разделы:
"Анализируй только Section 3 про financial projections"
```

### Practice 4: Указывайте формат ответа

```
"Найди в документе информацию про pricing и представь в виде таблицы:
| Service | Price | Terms |"

"Извлеки все упоминания dates и deadlines, список в хронологическом порядке"
```

### Practice 5: Проверяйте источники

```
После получения ответа:
"Покажи мне точные цитаты из документа, которые ты использовал"
"На какой странице находится эта информация?"

Затем проверьте в оригинале!
```

---

## Продвинутые техники RAG

### Техника 1: Multi-document Analysis

Загрузите несколько связанных документов:

```
[Загружаете: contract_v1.pdf, contract_v2.pdf]

Вопрос:
"Сравни эти два contract versions:
1. Что изменилось в payment terms?
2. Какие новые clauses добавлены?
3. Что удалено?

Приведи конкретные примеры из обоих документов."
```

### Техника 2: Structured Extraction

```
"Извлеки из этого legal document все entities следующих типов:

Parties involved:
- [список]

Key dates:
- [список]

Financial terms:
- [список]

Obligations:
- Party A: [список]
- Party B: [список]

Для каждого пункта указывай page reference."
```

### Техника 3: Summarization with RAG

```
"Прочитай этот 50-страничный report и создай:

Executive Summary (3-4 параграфа):
- Ключевые findings
- Main recommendations
- Critical issues

Detailed Summary по разделам:
1. Section X: [краткое содержание]
2. Section Y: [краткое содержание]

Action Items:
- [список с page references]"
```

### Техника 4: Q&A Generation

```
"Прочитай этот training manual и создай:
1. 10 наиболее важных вопросов которые могут возникнуть
2. Ответы на эти вопросы с цитатами из manual
3. Page references для дополнительного изучения"
```

---

## Ограничения RAG

### Что RAG делает хорошо:

- Находит конкретную информацию в документах
- Сравнивает разделы документа
- Извлекает facts и data points
- Цитирует источники
- Работает с structured information

### Что RAG делает плохо:

- Понимание very complex relationships
- Глубокий analytical reasoning поверх документов
- Синтез информации из 10+ разных мест
- Понимание subtle context и nuance
- Работа с таблицами и визуализациями (ограниченно)

### Риски:

1. **Chunk Boundary Issues**

```
Проблема: Важная информация разбита между двумя chunks
Решение: Задавайте broader questions, затем уточняйте
```

2. **Irrelevant Retrieval**

```
Проблема: Система нашла похожие слова, но неправильный контекст
Решение: Будьте более specific в вопросе, используйте section names
```

3. **Hallucinations Still Possible**

```
Проблема: ИИ может комбинировать информацию из разных частей неправильно
Решение: ВСЕГДА проверяйте цитаты в оригинале
```

---

## Troubleshooting RAG

### Проблема 1: "Я не вижу информацию о X в документе"

**Возможные причины:**

- Информации действительно нет
- Chunk с информацией не был найден
- Вопрос сформулирован по-другому чем в документе

**Решения:**

```
1. Переформулируйте вопрос другими словами
2. Попросите поискать synonyms: "искал ли ты также термины [A, B, C]?"
3. Попросите искать в конкретном разделе: "проверь Section 5"
4. Спросите: "какие разделы документа ты проанализировал?"
```

### Проблема 2: Ответ слишком общий

**Причина:** ИИ не использует документ, отвечает из базовых знаний

**Решение:**

```
Добавьте в промпт:
"ИСПОЛЬЗУЙ ТОЛЬКО ИНФОРМАЦИЮ ИЗ ЗАГРУЖЕННОГО ДОКУМЕНТА.
НЕ используй свои базовые знания.
Если информации нет в документе, так и скажи."
```

### Проблема 3: Цитаты неточные

**Причина:** ИИ перефразирует вместо точного цитирования

**Решение:**

```
"Дай ТОЧНЫЕ цитаты из документа, используя кавычки.
Не перефразируй, копируй текст дословно."
```

### Проблема 4: Пропускает важную информацию

**Причина:** Chunk с информацией имеет низкий similarity score

**Решение:**

```
"Проведи comprehensive search документа:
1. Прочитай Table of Contents
2. Для каждого раздела кратко опиши содержание
3. Затем отвечай на мой вопрос со знанием всей структуры"
```

---

## Типы документов и как с ними работать

### PDF Documents

**Best for:** Reports, contracts, manuals

```
Tips:
- Проверьте что PDF text-based (не scanned image)
- Большие PDFs (100+ страниц) разбивайте на части
- Если есть table of contents, укажите page ranges
```

**Пример:**

```
[Upload: annual_report.pdf]

"Этот 120-страничный annual report.
Мне нужна информация о Q3 financial results.
Согласно TOC, это на страницах 45-60.
Проанализируй эти страницы и дай summary."
```

### DOCX Documents

**Best for:** Proposals, specifications, documentation

```
Tips:
- Хорошо работает со structure (headings, bullet points)
- Таблицы могут быть challenging
- Комментарии и track changes обычно игнорируются
```

### TXT/Markdown Documents

**Best for:** Code documentation, technical specs, notes

```
Tips:
- Fastest processing
- Best accuracy
- Хорошо с code snippets
```

### CSV/Spreadsheet Data

**Limited support:** Лучше конвертировать в structured text

```
Вместо загрузки CSV:
1. Конвертируйте в Markdown table
2. Или вставьте как text с описанием структуры
```

---

## Практические сценарии

### Сценарий 1: Contract Analysis

```
[Upload: service_agreement.pdf]

"Проанализируй этот service agreement:

1. Key parties и их roles
2. Scope of services (краткое описание)
3. Payment terms:
 - Amount
 - Schedule
 - Payment method
4. Duration и termination clauses
5. Liability limitations
6. Any red flags или unusual clauses

Для каждого пункта приводи page reference."
```

### Сценарий 2: Technical Documentation Q&A

```
[Upload: api_documentation.pdf]

"Я разработчик интегрирующий ваш API.
Найди ответы на вопросы:

1. Какой authentication method используется?
2. Что такое rate limits?
3. Какие error codes возможны?
4. Есть ли sandbox environment для testing?
5. Какой base URL для production?

Приведи code examples из документации если есть."
```

### Сценарий 3: Research Paper Summary

```
[Upload: research_paper.pdf]

"Создай structured summary этого research paper:

**Abstract Summary:** (2-3 предложения)

**Methodology:** (what they did)

**Key Findings:** (bullet points)

**Conclusions:** (main takeaways)

**Limitations:** (что авторы упоминают)

**My Questions:** (3-5 вопросов для deeper understanding)

Используй academic terminology, но объясни сложные концепции."
```

### Сценарий 4: Compliance Check

```
[Upload: company_policy.pdf, employee_action.pdf]

"Проверь compliance:

1. Прочитай company policy про [topic]
2. Прочитай описание employee действий
3. Определи:
 - Соответствуют ли действия policy?
 - Какие specific clauses relevant?
 - Есть ли violations?
 - Какие recommendations?

Будь objective, приводи exact policy text."
```

---

## Pro Tips

### Tip 1: Pre-process Documents

Перед загрузкой:

- Удалите cover pages, disclaimers
- Оставьте Table of Contents
- Убедитесь в читаемости (не scanned image)

### Tip 2: Use Document Metadata

```
"Загруженный документ: 'Q3 Financial Report, dated Sept 30, 2024'
При ответах учитывай date context.
Все figures относятся к Q3 2024."
```

### Tip 3: Iterate on Questions

```
Question 1: "Есть ли в документе информация про pricing?"
→ ИИ: "Да, в Section 5"

Question 2: "Дай detailed breakdown pricing из Section 5"
→ ИИ: [детальный ответ]
```

### Tip 4: Combine RAG with Base Knowledge

```
"Прочитай описание их technical architecture из документа.
Затем, используя свои знания, оцени:
1. Что хорошо (based on industry best practices)
2. Potential risks
3. Recommendations

Четко разделяй: что из документа vs твой analysis."
```

---

## Чек-лист использования RAG

### Перед загрузкой:

- [ ] Документ содержит нужную информацию
- [ ] Файл в поддерживаемом формате
- [ ] Размер файла в пределах лимита
- [ ] Нет конфиденциальной информации (или анонимизирована)

### При формулировании вопроса:

- [ ] Вопрос конкретный и чёткий
- [ ] Указал нужный формат ответа
- [ ] Попросил цитаты и references
- [ ] Ограничил scope если документ большой

### После получения ответа:

- [ ] Проверил цитаты в оригинале
- [ ] Убедился что ответ из документа, не hallucination
- [ ] При сомнениях — переспросил другими словами
- [ ] Сохранил полезные промпты для будущего

---

## Дальнейшее изучение

- [Context Management](context-management.md) — работа с длинными документами
- [Effective Prompts](effective-prompts.md) — продвинутые техники запросов
- [Practical Examples](../howto/index.md) — готовые сценарии

---

**Следующий шаг:** [Model Selection Guide →](model-selection-guide.md)

**Практика:** Попробуйте загрузить документ и задать 5 вопросов!
