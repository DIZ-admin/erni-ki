---
title: 'Подготовка презентаций с помощью ИИ'
category: communication
difficulty: easy
duration: '15 min'
roles: ['general-user', 'manager', 'developer', 'product-owner']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Подготовка презентаций с помощью ИИ

## Цель

Использовать ИИ для быстрого создания структуры презентации, слайдов, speaker
notes, и визуального контента для эффективных presentations.

## Для кого

- **Managers** — team updates, stakeholder presentations
- **Developers** — technical demos, architecture reviews
- **Product Owners** — roadmap presentations
- **Anyone** — conference talks, training sessions

## ⏱ Время выполнения

15-30 минут на подготовку структуры

## Что вам понадобится

- Доступ к Open WebUI
- Тема и цель презентации
- **Рекомендуемая модель:** GPT-4o или Claude 3.5
- PowerPoint/Keynote/Google Slides для финальной версии

---

## Базовый шаблон промпта

```markdown
Помоги подготовить презентацию:

**Тема:** [название презентации] **Аудитория:** [кто будет слушать] **Длина:**
[время в минутах] **Цель:** [что должны вынести слушатели]

**Контекст:**

- [важная background информация]
- [что аудитория уже знает]
- [что нового вы хотите рассказать]

**Требования:**

- Количество слайдов: [примерно]
- Формат: [formal / casual / technical]
- Нужны ли speaker notes: [да/нет]
```

---

## Типы презентаций

### 1. Project Status Update

**Промпт:**

```markdown
Создай outline для project status presentation:

**Проект:** E-commerce Platform Redesign **Аудитория:** C-level executives +
project sponsors **Длина:** 15 минут **Цель:** Update на progress, получить
approval для Phase 2

**Ключевая информация:**

- Phase 1: 85% complete (планировали 100% к этой дате)
- Delay: 2 недели из-за API integration issues
- Budget: On track (€45K of €50K spent)
- Client feedback: Very positive
- Phase 2: Ready to start, budget request €60K

**Настроение:** Позитивное но honest про delay

**Структура которую хочу:**

1. Opening (1 slide)
2. Progress overview (2-3 slides)
3. Achievements/wins (2 slides)
4. Challenges (1 slide, brief)
5. Phase 2 plan (2 slides)
6. Budget request (1 slide)
7. Q&A (1 slide)

Для каждого слайда дай:

- Заголовок
- Key points (3-5 bullets)
- Visual suggestion (chart/icon/screenshot)
- Speaker notes (что сказать)
```

**Ожидаемый результат:** Детальная структура 10-12 слайдов с content и speaker
notes.

---

### 2. Technical Architecture Presentation

**Промпт:**

```markdown
Помоги создать technical presentation:

**Тема:** "Microservices Architecture for Our Platform" **Аудитория:**
Development team (12 developers) + CTO **Длина:** 30 минут + 15 min Q&A
**Цель:** Объяснить proposed architecture, получить team buy-in

**Technical details:**

- Переход от monolith к microservices
- 6 planned services (Auth, User, Product, Order, Payment, Notifications)
- Tech stack: Node.js, Docker, Kubernetes, PostgreSQL, Redis
- Communication: REST + Event-driven (RabbitMQ)

**Challenges to address:**

- Learning curve для команды
- Increased complexity в начале
- DevOps overhead

**Tone:** Technical но accessible, collaborative

**Требования:**

- Визуализация architecture (текстовое описание для diagram)
- Code examples где relevant
- Comparison slайд: Monolith vs Microservices
- Migration roadmap
- Speaker notes с anticipation на вопросы
```

---

### 3. Product Roadmap Presentation

**Промпт:**

```markdown
Создай product roadmap presentation:

**Продукт:** SaaS Analytics Platform **Аудитория:** Internal stakeholders
(Product, Eng, Sales) **Длина:** 20 минут **Цель:** Align на Q1 priorities

**Roadmap highlights:** Q1 2025:

- Real-time dashboards (high priority)
- Custom report builder (high)
- Mobile app beta (medium)

Q2 2025:

- Advanced filtering (medium)
- API для third-party integrations (high)
- White-label option (low)

**Также включи:**

- Why эти priorities (user requests, competitive analysis)
- Resource allocation (2 teams)
- Dependencies и risks
- Success metrics

**Формат:**

- Визуальный roadmap (timeline)
- Feature details
- "What's NOT on roadmap" слайд (manage expectations)
```

---

### 4. Training / Educational Presentation

**Промпт:**

```markdown
Создай training presentation:

**Тема:** "Introduction to Git for Beginners" **Аудитория:** Junior developers
(новички в Git) **Длина:** 45 минут (с hands-on) **Цель:** Научить basic Git
workflow

**Что должны уметь после:**

- Clone repository
- Create branch
- Make commits
- Push changes
- Create pull request

**Структура:**

1. Why Git? (5 min)
2. Core concepts (10 min)
3. Hands-on demo (20 min)
4. Common issues & solutions (5 min)
5. Resources & next steps (5 min)

**Требования:**

- Много visuals (diagrams объясняющие concepts)
- Step-by-step commands
- "Try it yourself" слайды
- Common mistakes to avoid
- Cheat sheet на финальном слайде
```

---

## Итеративная разработка слайдов

### Шаг 1: Создайте outline

```markdown
"Создай high-level outline для 20-minute presentation о AI in Healthcare.

Аудитория: Hospital administrators (не technical) Цель: Показать ROI и
real-world applications

Дай просто структуру — названия разделов и количество слайдов."
```

**Output:**

```
1. Opening: The AI Revolution in Healthcare (1 slide)
2. Current Challenges (2 slides)
3. AI Solutions (4 slides)
4. Case Studies (3 slides)
5. ROI Analysis (2 slides)
6. Implementation Roadmap (2 slides)
7. Conclusion & Q&A (1 slide)

Total: ~15 slides для 20 min
```

---

### Шаг 2: Детализируйте каждый раздел

```markdown
"Теперь detailed content для Section 3: AI Solutions (4 slides).

Для каждого слайда:

- Title
- Main points (3-4 bullets)
- Visual suggestion
- Example/statistic to include"
```

**Output:** Подробный контент для этих 4 слайдов.

---

### Шаг 3: Создайте speaker notes

```markdown
"Для слайда 'AI for Diagnostics' создай speaker notes:

Слайд content:

- AI analyzes medical images 50x faster
- 95% accuracy in early cancer detection
- Reduces radiologist workload by 30%

Speaker notes должны:

- Expand на каждый bullet
- Include transition от предыдущего слайда
- Anticipate questions
- ~2 минуты speaking time"
```

---

## Продвинутые техники

### Техника 1: Storytelling Structure

**Промпт:**

```markdown
Преобразуй эти сухие facts в compelling story:

**Facts:**

- Наш process занимал 5 days
- Внедрили automation
- Теперь занимает 2 hours
- Сэкономили €50K в год

**Задача:** Создай narrative arc для презентации:

1. Setup (the problem we had)
2. Conflict (challenges we faced)
3. Journey (what we tried)
4. Resolution (the solution)
5. Transformation (results)

Используй storytelling elements:

- Real example (Jane из Support team)
- Specific moment ("That Tuesday morning when...")
- Before/after contrast
- Emotion (frustration → relief → pride)

Длина: 3-4 слайда
```

---

### Техника 2: Data Visualization

**Промпт:**

```markdown
У меня есть эти данные для слайда:

Q1: Revenue €120K, Costs €95K Q2: Revenue €145K, Costs €98K Q3: Revenue €180K,
Costs €102K Q4: Revenue €210K, Costs €105K

**Задачи:**

1. Какой тип chart лучше? (line / bar / combo?)
2. Что highlight? (growth trend / profit margin / both?)
3. Какой insight вынести в title слайда?
4. Что сказать в speaker notes об этих данных?
5. Если нужен второй слайд для deeper dive — какие доп. данные показать?

Цель: Впечатлить investors ростом при контроле costs
```

---

### Техника 3: Handling Q&A

**Промпт:**

```markdown
Подготовь меня к Q&A после презентации о новой pricing strategy.

**Презентация summary:**

- Повышаем цены на 20%
- Adding new Premium tier
- Grandfather существующих customers (6 months)

**Anticipate вопросы:**

1. Создай список 10 most likely questions
2. Для каждого: concise answer (30 seconds)
3. Особо для tough questions — несколько variants ответа
4. "Pivot" phrases если не знаю ответа

**Tough questions to prepare:**

- "Why so expensive?"
- "What if customers churn?"
- "How does this compare to competitors?"
```

---

### Техника 4: Tailoring for Audience

**Промпт:**

```markdown
У меня одна презентация, но три разные аудитории. Помоги адаптировать.

**Original:** Technical architecture presentation (30 slides)

**Audience 1:** Developers (technical) Keep: Technical details, code examples,
architecture diagrams Remove: Business justification (они уже convinced) Add:
Implementation tips, gotchas, tools

**Audience 2:** Management (non-technical) Keep: High-level architecture
overview, benefits, timeline Remove: Code, technical jargon, deep dives Add:
Cost/benefit, risk analysis, competitor comparison

**Audience 3:** Mixed (tech + business) Balance: Technical enough для
credibility, simple enough для all Focus: Architecture + business value + Q&A

Для каждой аудитории дай:

- Adjusted slide count
- What to emphasize
- What to skip/simplify
- Tone adjustment
```

---

## Визуальные элементы

### Описание diagrams для дизайнера

**Промпт:**

```markdown
Опиши diagram который нужно создать:

**Тема:** User authentication flow

**Diagram type:** Flowchart

**Elements:**

1. User enters credentials (start)
2. System validates (decision point)
3. If invalid → Error message → back to step 1
4. If valid → Generate session token
5. Redirect to dashboard (end)

**Visual style:**

- Clean, modern
- Color code: Green для success path, Red для error
- Icons для User, Server, Database
- Arrows показывают flow direction

**Output format:** Text description детальный enough для designer создать
diagram в Lucidchart/Draw.io
```

---

### Icon и image suggestions

**Промпт:**

```markdown
Для каждого слайда предложи relevant icon или image:

**Слайд 1:** "Security First" **Слайд 2:** "Scalable Architecture" **Слайд 3:**
"User-Friendly Interface" **Слайд 4:** "24/7 Support" **Слайд 5:** "Global
Reach"

Для каждого:

- Icon suggestion (Font Awesome / Material Icons названия)
- Alternative: Stock photo idea
- Color scheme suggestion
- Placement (left / right / center / background)
```

---

## Чек-лист презентации

### Контент:

- [ ] Opening hook (захватывает attention)
- [ ] Clear agenda (аудитория знает что ожидать)
- [ ] Логический flow (каждый слайд ведёт к следующему)
- [ ] Key message на каждом слайде
- [ ] Data visualization эффективная
- [ ] No text overload (rule: 6 bullets max)
- [ ] Call to action (что делать дальше)
- [ ] Conclusion summarizes key points

### Дизайн:

- [ ] Consistent theme и fonts
- [ ] High contrast (читаемость)
- [ ] Images high quality
- [ ] Animations minimal (не отвлекают)
- [ ] Slide numbers (для Q&A reference)

### Delivery:

- [ ] Speaker notes готовы
- [ ] Timing проверен (~2 min per slide)
- [ ] Transitions smooth
- [ ] Backup слайды (для anticipated questions)
- [ ] Contact info на финальном слайде

---

## Pro Tips

### Tip 1: The 10/20/30 Rule (Guy Kawasaki)

```markdown
"Создай презентацию следуя 10/20/30 rule:

- 10 slides maximum
- 20 minutes maximum
- 30pt font minimum

Тема: [ваша тема] Аудитория: [ваша аудитория]

Challenge: fit всё самое важное в эти constraints."
```

### Tip 2: Start with End

```markdown
"Начнём с конца — что аудитория должна СДЕЛАТЬ после презентации?

Call to action: [ваш CTA]

Теперь работай backwards:

- Что нужно знать для этого CTA?
- Какие objections нужно address?
- Какие facts нужны для убеждения?

Построй презентацию от финала к началу."
```

### Tip 3: The 'So What?' Test

```markdown
"Для каждого слайда answer 'So what?'

Пример: Слайд: 'We have 10,000 users' So what? 'This shows product-market fit'
So what? 'We're ready to scale to enterprise' So what? 'We need Series A funding
for that'

Ensure каждый слайд leads somewhere."
```

---

## Распространённые ошибки

### Ошибка 1: Слишком много текста

```markdown
ПЛОХО: Слайд полон paragraph text

ХОРОШО: Краткие bullets Speaker notes для details Visual занимает 50% слайда
```

### Ошибка 2: Death by PowerPoint

```markdown
ПЛОХО:

- Читаете слайды verbatim
- Bullet points на каждом слайде
- No visuals
- Monotone delivery

ХОРОШО:

- Слайды = visual support
- You tell the story
- Engaging delivery
- Mix: text + visuals + data
```

---

## Дальнейшее изучение

- [Write Professional Email](write-professional-email.md)
- [Create Project Report](../managers/create-project-report.md)
- [Prompting Fundamentals](../../fundamentals/prompting-fundamentals.md)

---

## Практическое задание

**Задание 1: Quick Pitch**

```
Создай 5-минутную презентацию:
- Тема: Ваш pet project
- Аудитория: Potential investors
- Цель: Get meeting для detailed discussion

3-5 слайдов maximum
```

**Задание 2: Technical Deep Dive**

```
Создай tech presentation:
- Explain microservices к junior developers
- 15 минут
- Include diagrams description и code examples
```

**Задание 3: Executive Update**

```
Quarterly update для C-level:
- 10 минут
- Focus на impact, не details
- Data-driven
```

---

## Шаблоны презентаций

### Шаблон: Problem-Solution Presentation

```markdown
Slide 1: Title + Hook Slide 2-3: The Problem (pain points) Slide 4: Why Now?
(urgency) Slide 5-7: Our Solution (how it works) Slide 8: Results/Proof (case
studies, data) Slide 9: Implementation (next steps) Slide 10: Call to Action

Speaker notes для каждого слайда
```

### Шаблон: Technical Architecture Review

```markdown
Slide 1: Overview + Goals Slide 2: Current State (before) Slide 3-4: Proposed
Architecture (diagrams) Slide 5: Technology Stack Slide 6-7: Key Components
(deep dive) Slide 8: Data Flow Slide 9: Security & Performance Slide 10:
Migration Plan Slide 11: Risks & Mitigation Slide 12: Timeline & Resources Slide
13: Q&A
```

---

**Время прочтения:** ~15 минут **Совет:** Practice презентацию вслух — это
reveals timing issues и слайды которые не work.
