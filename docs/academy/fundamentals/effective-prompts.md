---
title: 'Продвинутые техники промптинга'
category: fundamentals
difficulty: intermediate
duration: '20 min'
prerequisites: ['prompting-fundamentals.md']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Продвинутые техники промптинга

## Цель

Освоить продвинутые техники промптинга, которые позволяют получать более точные,
структурированные и качественные ответы от ИИ.

## Что вы узнаете

- **Chain-of-Thought** — пошаговое рассуждение
- **Few-Shot Learning** — обучение на примерах
- **Self-Consistency** — проверка через множественные подходы
- **Tree of Thoughts** — древовидное исследование решений
- **Prompt Chaining** — цепочки промптов для сложных задач

## ⏱ Время изучения

20 минут

---

## Техника 1: Chain-of-Thought (Цепочка рассуждений)

### Что это?

Просите ИИ "думать вслух", показывая промежуточные шаги рассуждения.

### Базовый подход

**Без Chain-of-Thought:**

```
Сколько будет 15% от 847?
```

**С Chain-of-Thought:**

```
Вычисли 15% от 847.

Покажи пошаговое решение:
1. Какую формулу использовать
2. Промежуточные вычисления
3. Финальный ответ
```

### Продвинутое применение

**Пример: Бизнес-решение**

```markdown
Проанализируй следующее бизнес-решение пошагово:

**Контекст:** Компания рассматривает переход на новую CRM систему. Стоимость:
€50,000 setup + €10,000/год Текущая система: €5,000/год, но теряем ~€30,000/год
из-за inefficiency

**Задача:** Стоит ли переходить?

**Твой анализ:**

1. Сначала вычисли годовые затраты каждого варианта
2. Потом вычисли ROI (return on investment)
3. Потом оцени payback period
4. Наконец, дай рекомендацию с обоснованием
```

**Результат:** ИИ покажет каждый шаг вычислений, вы увидите логику и сможете
проверить.

---

## Техника 2: Few-Shot Learning (Обучение на примерах)

### Что это?

Даёте ИИ несколько примеров желаемого формата/стиля, чтобы он продолжил в том же
духе.

### Zero-Shot (без примеров)

```
Классифицируй отзыв: "Отличный продукт, очень доволен!"
```

### One-Shot (один пример)

```
Классифицируй customer sentiment:

Пример:
Отзыв: "Ужасное качество, не рекомендую"
Sentiment: Negative

Теперь твой черёд:
Отзыв: "Отличный продукт, очень доволен!"
Sentiment: ?
```

### Few-Shot (несколько примеров)

```
Классифицируй customer sentiment и категорию:

Примеры:
Отзыв: "Долгая доставка, но товар хороший"
Sentiment: Mixed | Категория: Logistics

Отзыв: "Всё супер, быстро и качественно!"
Sentiment: Positive | Категория: Overall

Отзыв: "Цена завышена для такого качества"
Sentiment: Negative | Категория: Pricing

Теперь классифицируй:
Отзыв: "Поддержка не отвечает уже 3 дня"
Sentiment: ? | Категория: ?
```

**Результат:** Более точная классификация, потому что ИИ понял паттерн.

---

### Продвинутое Few-Shot: Стиль письма

**Пример: Адаптация под корпоративный стиль**

```markdown
Напиши email в стиле нашей компании.

Вот примеры наших писем:

**Пример 1:** Subject: Project Update — Phase 2 Complete Hi Team, Great news!
We've wrapped up Phase 2 ahead of schedule. Key wins: • All features deployed •
Zero critical bugs • Client feedback: excellent Next: Phase 3 kickoff on Monday.
Questions? Hit reply. Best, Maria

**Пример 2:** Subject: Quick Win — New Feature Live Hey folks, Just shipped the
dark mode you requested! Available now in Settings > Appearance. Try it out and
let us know what you think. Cheers, Dev Team

**Теперь твой черёд:** Напиши аналогичное письмо об успешном завершении security
audit.
```

**Результат:** Email в том же дружелюбном, кратком, bullet-point стиле.

---

## Техника 3: Self-Consistency (Самопроверка)

### Что это?

Просите ИИ решить задачу несколькими способами и сравнить результаты.

### Базовый пример

```
Реши эту задачу тремя разными методами и сравни ответы:

Задача: У нас 120 users. Каждый месяц прирост 15%.
Сколько users будет через 6 месяцев?

Метод 1: Пошаговый (месяц за месяцем)
Метод 2: Формула сложного процента
Метод 3: Таблица с визуализацией

Потом сравни все три результата. Если есть расхождения — найди ошибку.
```

### Продвинутое применение: Код

```markdown
Напиши функцию для поиска duplicate элементов в массиве.

Задание:

1. Реализуй тремя разными подходами:

- Approach A: Nested loops
- Approach B: Hash map
- Approach C: Set data structure

2. Для каждого подхода укажи:

- Time complexity
- Space complexity
- Pros/Cons

3. Протестируй все три на примере: [1, 2, 3, 2, 4, 5, 3]

4. Проверь — дают ли одинаковый результат?

5. Порекомендуй лучший подход для production
```

**Результат:** Вы видите несколько решений и можете выбрать оптимальное.

---

## Техника 4: Tree of Thoughts (Дерево мыслей)

### Что это?

ИИ исследует несколько путей решения проблемы параллельно, как дерево вариантов.

### Пример: Архитектурное решение

```markdown
Нам нужно выбрать database для нового проекта.

Используй "Tree of Thoughts" approach:

**Level 1: Типы баз данных** Какие основные типы БД могут подойти?

- Relational (SQL)
- NoSQL (Document)
- NoSQL (Key-Value)
- Time-series
- Graph

**Level 2: Для каждого типа проанализируй:**

- Когда подходит?
- Pros/Cons
- Примеры (PostgreSQL, MongoDB, Redis...)

**Level 3: Наш use case:**

- E-commerce platform
- 100K products
- User reviews and ratings
- Real-time inventory
- Search functionality needed

**Level 4: Финальный выбор** Какой тип БД лучше всего подходит? Почему? Возможно
ли комбинирование (polyglot persistence)?
```

**Результат:** Comprehensive analysis с рассмотрением многих вариантов.

---

## Техника 5: Prompt Chaining (Цепочки промптов)

### Что это?

Разбиваете сложную задачу на несколько последовательных промптов, где выход
одного — вход другого.

### Пример: Анализ feedback

**Промпт 1: Сбор данных**

```
Вот 50 customer reviews (пример данных).

Задача: Извлеки все упоминания проблем и bugs.
Формат вывода: Список проблем с количеством упоминаний.
```

**Output:**

```
1. Slow loading (12 mentions)
2. Login issues (8 mentions)
3. UI confusing (5 mentions)
```

**Промпт 2: Категоризация**

```
Вот список проблем из reviews:
[вставить output из Промпт 1]

Задача: Категоризируй по severity и impact.
Severity: Critical/High/Medium/Low
Impact: Many users / Some users / Few users
```

**Output:**

```
Critical + Many users:
- Slow loading (12 mentions)

High + Some users:
- Login issues (8 mentions)

Medium + Few users:
- UI confusing (5 mentions)
```

**Промпт 3: Приоритизация**

```
Вот категоризированные проблемы:
[вставить output из Промпт 2]

Задача: Предложи roadmap для фиксов:
- Что фиксить сначала?
- Примерные effort estimates
- Quick wins vs long-term fixes
```

**Результат:** От сырых данных до actionable roadmap через 3 промпта.

---

## Техника 6: Constrained Generation (Генерация с ограничениями)

### Что это?

Строго ограничиваете формат/стиль/содержание ответа.

### Пример: JSON Output

```markdown
Проанализируй этот текст и выдай результат СТРОГО в JSON формате.

Текст: "John Smith ordered 3 laptops for €3,000 on December 1st. Shipping to
Berlin."

JSON Schema (обязательный!): { "customer": "string", "items": [ { "product":
"string", "quantity": number, "price": number } ], "date": "YYYY-MM-DD",
"shipping_city": "string" }

ВАЖНО: Ответ должен быть валидным JSON, без дополнительного текста!
```

**Результат:**

```json
{
  "customer": "John Smith",
  "items": [
    {
      "product": "laptop",
      "quantity": 3,
      "price": 3000
    }
  ],
  "date": "2025-12-01",
  "shipping_city": "Berlin"
}
```

---

### Пример: Length Constraint

```
Объясни квантовые компьютеры.

Ограничения:
- Ровно 3 предложения
- Максимум 50 слов
- Без технического жаргона
- Для аудитории: школьники 14 лет
```

---

## Техника 7: Role + Perspective Prompting

### Что это?

Комбинируете роль с определённой перспективой для более rich answers.

### Базовый пример

```
Ты — senior software architect с 15 годами опыта.

Проанализируй этот код с точки зрения:
1. Maintainability
2. Scalability
3. Security
4. Performance

Для каждого аспекта:
- Оценка 1-10
- Главные concerns
- Top 3 recommendations
```

### Продвинутый: Multiple Perspectives

```markdown
Проанализируй решение внедрить microservices architecture с трёх точек зрения:

**Perspective 1: CTO**

- Strategic fit
- Budget implications
- Timeline реалистичен?

**Perspective 2: Senior Developer**

- Technical complexity
- Team skills gap
- Migration risks

**Perspective 3: DevOps Engineer**

- Infrastructure requirements
- Monitoring challenges
- Deployment complexity

Каждая perspective должна дать:

- Главные concerns (3-5)
- Recommendation (Go/No-Go/Proceed with caution)
```

**Результат:** Holistic view с разных углов.

---

## Техника 8: Iterative Refinement (Итеративное улучшение)

### Workflow

1. **Первый промпт:** Базовая задача
2. **Анализ ответа:** Что не так?
3. **Уточняющий промпт:** Конкретные улучшения
4. **Повтор** до идеального результата

### Пример

**Iteration 1:**

```
Напиши функцию для валидации email.
```

**Output:** Базовая regex, работает но неполная.

**Iteration 2:**

```
Улучши функцию:
- Поддержка internationalized domains
- Проверка на disposable email providers
- Возврат детальных error messages
```

**Output:** Лучше, но без тестов.

**Iteration 3:**

```
Добавь:
- Unit tests (минимум 10 cases)
- JSDoc documentation
- TypeScript types
```

**Output:** Production-ready код!

---

## Техника 9: Structured Reasoning (Структурированное рассуждение)

### Шаблон: PEEL Framework

**P**oint — Главный тезис **E**vidence — Доказательства **E**xplanation —
Объяснение **L**ink — Связь с выводом

**Пример промпта:**

```markdown
Используй PEEL framework для анализа:

Вопрос: Стоит ли нашей компании инвестировать в AI automation?

Структура ответа: **Point:** Твоя главная рекомендация (1 предложение)

**Evidence:** Данные/факты поддерживающие это (3-5 пунктов)

**Explanation:** Почему эти данные важны для нашего контекста (2-3 параграфа)

**Link:** Как это влияет на финальное решение (вывод)

Контекст: E-commerce компания, 50 сотрудников, €5M годовой revenue
```

---

## Техника 10: Metacognitive Prompting

### Что это?

Просите ИИ "думать о своём мышлении" — объяснять уверенность, assumptions,
limitations.

### Пример

```markdown
Проанализируй этот customer churn и предскажи вероятность.

НО ТАКЖЕ:

1. **Confidence Level:** Насколько ты уверен в своём предсказании? (%)
2. **Assumptions:** Какие допущения ты делаешь?
3. **Missing Data:** Какие данные помогли бы улучшить точность?
4. **Limitations:** Какие факторы ты НЕ можешь учесть?
5. **Alternative Interpretations:** Есть ли другие ways читать эти данные?

Data: User logged in 2 times last month (was 20 times before), no purchases in
60 days (was weekly buyer), support tickets: 3
```

**Результат:** Не просто предсказание, а transparent reasoning process.

---

## Комбинирование техник

### Мощная комбинация: Chain-of-Thought + Few-Shot + Self-Consistency

```markdown
Классифицируй сложность этой задачи разработки.

**Примеры (Few-Shot):**

Task: Add button to form Complexity: Simple (1-2 hours) Reasoning: UI change
only, no backend

Task: Integrate payment gateway Complexity: Complex (2-3 weeks) Reasoning:
Security, testing, compliance, multiple systems

**Теперь твоя задача (Chain-of-Thought):** Task: "Add real-time chat to the
application"

Проанализируй пошагово:

1. Какие компоненты затронуты?
2. Какие технологии нужны?
3. Какие риски?
4. Оценка времени

**Финал (Self-Consistency):** Дай 3 разные оценки
(optimistic/realistic/pessimistic) и объясни range.
```

---

## Практические упражнения

### Упражнение 1: Chain-of-Thought

```
Попробуй решить задачу:
"Проект должен был занять 4 месяца.
Прошло 6 недель, выполнено 20%.
Успеем ли в срок?"

Используй Chain-of-Thought для анализа.
```

### Упражнение 2: Few-Shot Learning

```
Создай 3 примера customer feedback (positive, negative, mixed).
Потом попроси ИИ классифицировать 4-й в том же стиле.
```

### Упражнение 3: Prompt Chaining

```
Цепочка из 3 промптов:
1. Анализ проблемы
2. Brainstorm решений
3. Детальный план лучшего решения
```

---

## Чек-лист выбора техники

**Используй Chain-of-Thought когда:**

- [ ] Задача требует логических шагов
- [ ] Нужна transparency рассуждений
- [ ] Важна проверяемость ответа

**Используй Few-Shot когда:**

- [ ] Нужен специфический формат
- [ ] Уникальный стиль/tone
- [ ] Классификация/категоризация

**Используй Self-Consistency когда:**

- [ ] Критически важная точность
- [ ] Математика/вычисления
- [ ] Несколько valid подходов

**Используй Tree of Thoughts когда:**

- [ ] Много возможных решений
- [ ] Нужен comprehensive analysis
- [ ] Exploration важнее чем speed

**Используй Prompt Chaining когда:**

- [ ] Очень сложная задача
- [ ] Нужна многоступенчатая обработка
- [ ] Output одного шага → input другого

---

## Распространённые ошибки

### Ошибка 1: Слишком сложный промпт

```
ПЛОХО: Использовать все 10 техник одновременно
```

### Правильно:

```
Выберите 1-2 техники, подходящие для конкретной задачи
```

### Ошибка 2: Few-Shot с inconsistent примерами

```
ПЛОХО: Примеры в разных форматах
Пример 1: JSON
Пример 2: Plain text
Пример 3: Markdown table
```

### Правильно:

```
Все примеры в одинаковом формате
```

---

## Pro Tips

### Tip 1: Комбинируйте техники постепенно

Начните с базовых (Chain-of-Thought), потом добавляйте сложные.

### Tip 2: Сохраняйте успешные промпты

Создайте личную библиотеку эффективных промптов.

### Tip 3: A/B тестирование

Пробуйте разные техники на одной задаче — сравнивайте результаты.

### Tip 4: Clarity > Complexity

Иногда простой прямой промпт работает лучше чем сложная техника.

---

## Дальнейшее изучение

- [Prompting Fundamentals](prompting-fundamentals.md) — Базовые основы
- [Context Management](context-management.md) — Управление контекстом
- [RAG Basics](rag-basics.md) — Работа с документами

---

## Дополнительные ресурсы

**Академические paper:**

- "Chain-of-Thought Prompting Elicits Reasoning in LLMs" (Google, 2022)
- "Tree of Thoughts: Deliberate Problem Solving with LLMs"
  (Princeton/Google, 2023)

**Практические guides:**

- OpenAI Prompt Engineering Guide
- Anthropic Claude Prompting Guide

---

## Выводы

**Вы научились:**

- 10 продвинутых техник промптинга
- Когда какую технику применять
- Как комбинировать техники
- Практические примеры и templates

**Следующий шаг:** Применяйте эти техники в реальных задачах. Начните с
Chain-of-Thought и Few-Shot — они дают максимальный эффект при минимальной
сложности.

---

**Время прочтения:** ~20 минут **Следующий материал:**
[HowTo Scenarios →](../by-role/index.md)
