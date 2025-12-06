---
title: 'Анализ метрик и данных с ИИ'
category: management
difficulty: medium
duration: '15 min'
roles: ['manager', 'project-manager', 'product-owner', 'analyst']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Анализ метрик и данных с ИИ

## Цель

Использовать ИИ для быстрого анализа business metrics, выявления trends, и
получения actionable insights из данных.

## Для кого

- **Managers** — анализ team performance
- **Product Owners** — product metrics
- **Analysts** — data exploration
- **Tech Leads** — technical metrics

## ⏱ Время выполнения

10-20 минут на один анализ

## Что вам понадобится

- Доступ к Open WebUI
- Metrics data (CSV, таблицы, или текстовый формат)
- **Рекомендуемая модель:** GPT-4o или Claude 3.5

---

## Базовый шаблон промпта

```markdown
Проанализируй эти metrics:

**Данные:** [ваши данные — таблица, CSV, или список]

**Период:** [временной период]

**Контекст:** [что это за metrics, какой проект/продукт]

**Что нужно:**

- Основные trends
- Anomalies (аномалии)
- Insights и recommendations

**Формат:** [таблица/bullets/dashboard description]
```

---

## Типы метрик для анализа

### 1. Product Metrics (Метрики продукта)

**Промпт:**

```markdown
Проанализируй product usage metrics за последние 3 месяца:

**Данные:** | Month | Active Users | New Signups | Churn Rate | Avg Session
(min) | |-------|-------------|-------------|------------|------------------| |
Oct | 12,500 | 850 | 3.2% | 18 | | Nov | 13,200 | 920 | 2.8% | 22 | | Dec |
14,100 | 1,100 | 2.1% | 25 |

**Задачи:**

1. Какие trends ты видишь?
2. Что работает хорошо?
3. Где есть concerns?
4. Top 3 recommendations для роста

Добавь:

- MoM (month-over-month) growth rates
- Проекцию на следующий месяц
- Key insights в bullet points
```

**Результат:** Comprehensive analysis с выявленными patterns и actionable
рекомендациями.

---

### 2. Team Performance Metrics

**Промпт:**

```markdown
Проанализируй team velocity за последние 6 sprints:

**Данные:** Sprint 10: Committed: 50 pts | Completed: 45 pts | Bugs: 8 Sprint
11: Committed: 50 pts | Completed: 48 pts | Bugs: 5 Sprint 12: Committed: 52 pts
| Completed: 52 pts | Bugs: 3 Sprint 13: Committed: 55 pts | Completed: 50 pts |
Bugs: 7 Sprint 14: Committed: 55 pts | Completed: 54 pts | Bugs: 2 Sprint 15:
Committed: 58 pts | Completed: 58 pts | Bugs: 1

**Контекст:**

- Team размер: 6 developers
- Sprint length: 2 weeks
- Definition of Done включает code review + testing

**Анализ:**

1. Velocity trend (improving/stable/declining)?
2. Commitment accuracy trend
3. Bug count pattern — что изменилось?
4. Можем ли увеличить capacity?
5. Recommendations для следующих sprints
```

---

### 3. Financial Metrics

**Промпт:**

```markdown
Проанализируй project budget performance:

**Плановый budget:** €120,000 **Продолжительность:** 6 месяцев **Сейчас:** Конец
месяца 4

**Фактические расходы по месяцам:** Month 1: €18,000 (plan: €20,000) Month 2:
€22,000 (plan: €20,000) Month 3: €25,000 (plan: €20,000) Month 4: €28,000 (plan:
€20,000)

**Также:**

- Scope creep: добавлено 15% новых фич
- Team overtime: 120 часов total

**Задачи:**

1. Burn rate analysis
2. Forecast для оставшихся 2 месяцев
3. Risk assessment (over budget вероятность?)
4. Recommendations для corrective action

Формат: Executive summary + detailed breakdown
```

---

### 4. Customer Metrics (Support/Satisfaction)

**Промпт:**

```markdown
Проанализируй customer support metrics:

**Last Quarter Data:** | Metric | Q3 2024 | Q4 2024 | Change |
|------------------------|---------|---------|--------| | Tickets received | 450
| 520 | +15.6% | | Avg response time (h) | 4.2 | 3.1 | -26% | | Avg resolution
time (h)| 18 | 14 | -22% | | CSAT score (1-5) | 4.1 | 4.4 | +7.3% | |
First-contact resolved | 62% | 71% | +14.5% |

**Контекст:**

- Внедрили новую knowledge base в начале Q4
- Провели training для support team
- Добавили chatbot для tier-1 questions

**Анализ:**

1. Что сработало хорошо?
2. Корреляции между metrics
3. Влияние новых initiatives
4. Где ещё есть room for improvement?
5. Quantify ROI от KB и chatbot (если можно)
```

---

## Продвинутые техники анализа

### Техника 1: Cohort Analysis

**Промпт:**

```markdown
Проведи cohort analysis для user retention:

**Data:** Users signed up in:

- January 2024: 1,000 users
- Still active in Feb: 850 (85%)
- Still active in Mar: 720 (72%)
- Still active in Apr: 650 (65%)

- February 2024: 1,200 users
- Still active in Mar: 1,050 (87.5%)
- Still active in Apr: 950 (79%)

- March 2024: 1,500 users
- Still active in Apr: 1,350 (90%)

**Вопросы:**

1. Какой cohort имеет лучший retention?
2. Есть ли improving trend между cohorts?
3. Когда происходит biggest drop-off?
4. Что может объяснять differences между cohorts?
5. Recommendations для улучшения retention

Визуализируй как cohort table с color coding (если можешь описать)
```

---

### Техника 2: Anomaly Detection

**Промпт:**

```markdown
Найди anomalies в этих daily metrics:

**API Response Times (ms) — Last 30 days:** Days 1-5: 120, 118, 125, 122, 119
Days 6-10: 121, 450, 128, 124, 126 ← Day 7 spike! Days 11-15: 123, 122, 125,
121, 124 Days 16-20: 320, 340, 310, 330, 325 ← Sustained increase Days 21-25:
122, 118, 121, 125, 119 ← Back to normal Days 26-30: 124, 122, 870, 125, 121 ←
Day 28 spike!

**Задачи:**

1. Определи все anomalies (критерий: >2x от baseline)
2. Классифицируй: spike vs sustained change
3. Возможные причины каждой anomaly
4. Какие требуют investigation?
5. Recommended alerting thresholds

Добавь baseline calculation и std deviation analysis
```

---

### Техника 3: Correlation Analysis

**Промпт:**

```markdown
Проанализируй корреляции между метриками:

**Данные за 12 недель:** | Week | Marketing Spend (€) | Website Traffic |
Signups | Conversion Rate |
|------|--------------------|-----------------|---------|----| | 1 | 5,000 |
12,000 | 240 | 2.0% | | 2 | 5,500 | 13,500 | 280 | 2.1% | | 3 | 8,000 | 18,000 |
450 | 2.5% | | 4 | 7,500 | 17,200 | 430 | 2.5% | | 5 | 5,000 | 13,000 | 260 |
2.0% | ...

**Вопросы:**

1. Correlation между marketing spend и traffic?
2. Correlation между traffic и signups?
3. Есть ли diminishing returns?
4. Оптимальный marketing spend level?
5. Другие patterns которые ты видишь?

Включи:

- Correlation coefficients (если можешь estimate)
- Cost per signup analysis
- Recommendations для budget allocation
```

---

### Техника 4: Comparative Analysis

**Промпт:**

```markdown
Сравни performance двух команд:

**Team A (Backend):**

- Velocity: 52 pts/sprint (avg last 5 sprints)
- Bug rate: 2.5 bugs per sprint
- Code review time: 8 hours avg
- Tech debt: 15 items

**Team B (Frontend):**

- Velocity: 48 pts/sprint (avg last 5 sprints)
- Bug rate: 4.2 bugs per sprint
- Code review time: 12 hours avg
- Tech debt: 8 items

**Context:**

- Team A: 6 people
- Team B: 5 people
- Оба используют same sprint length (2 weeks)

**Анализ:**

1. Normalize metrics (per person)
2. Где каждая team excels?
3. Где нужен improvement?
4. Факторы влияющие на differences
5. Cross-team learning opportunities
6. Recommendations для каждой команды

НЕ делай это competition — фокус на improvement!
```

---

## Специализированные анализы

### A/B Test Results Analysis

**Промпт:**

```markdown
Проанализируй A/B test результаты:

**Test:** New checkout flow vs Old checkout flow **Duration:** 2 weeks **Traffic
split:** 50/50

**Results:** Variant A (Old):

- Users: 5,000
- Started checkout: 1,250 (25%)
- Completed purchase: 875 (70% of started = 17.5% overall)
- Avg order value: €85

Variant B (New):

- Users: 5,000
- Started checkout: 1,400 (28%)
- Completed purchase: 1,120 (80% of started = 22.4% overall)
- Avg order value: €82

**Вопросы:**

1. Statistical significance (можешь ли estimate)?
2. Winner? По каким metrics?
3. Revenue impact projection
4. Trade-offs (conversion vs AOV)
5. Recommendation: ship или test longer?
6. Какие follow-up questions задать?
```

---

### Trend Projection

**Промпт:**

```markdown
Сделай projection на основе historical trends:

**Monthly Active Users (MAU) — Last 12 months:** Jan: 10,000 Feb: 10,500 (+5%)
Mar: 11,200 (+6.7%) Apr: 11,500 (+2.7%) May: 12,100 (+5.2%) Jun: 12,800 (+5.8%)
Jul: 13,200 (+3.1%) Aug: 13,800 (+4.5%) Sep: 14,500 (+5.1%) Oct: 15,200 (+4.8%)
Nov: 16,100 (+5.9%) Dec: 17,000 (+5.6%)

**Задачи:**

1. Вычисли average growth rate
2. Определи trend (linear/exponential/slowing?)
3. Project next 6 months
4. Confidence intervals (optimistic/realistic/pessimistic)
5. Когда достигнем 25,000 MAU?
6. Факторы риска для projection

Включи assumptions и caveats!
```

---

## Форматы вывода

### Dashboard Description Format

**Промпт:**

```markdown
Опиши ideal dashboard для мониторинга этих metrics:

**Metrics to track:**

- User growth (daily/weekly/monthly)
- Engagement (session time, frequency)
- Revenue (MRR, ARR, churn)
- Product health (uptime, errors, performance)

**Задачи:**

1. Предложи layout (какие widgets куда)
2. Какие visualizations (line chart, bar, gauge, etc)
3. Color coding и alerts
4. Top 3 KPIs для hero section
5. Drill-down paths для investigation

Формат: Detailed spec который можно дать designer
```

---

### Executive Summary Format

**Промпт:**

```markdown
Создай executive summary этих metrics для C-level:

[данные]

Формат (СТРОГО):

1. **One-liner:** Главный takeaway (1 предложение)
2. **Key Numbers:** 3-4 самых важных metrics с context
3. **Trends:** Что улучшается / ухудшается (bullets)
4. **Actions Needed:** Top 2-3 recommendations
5. **Next Review:** Что отслеживать

Длина: Максимум 1 страница Тон: Confident но honest Focus: Actionable insights,
не просто цифры
```

---

## Важные правила

### Data Privacy

```markdown
ПЛОХО: "Analyze user data: User john.doe@company.com spent €5,240 last month..."

ХОРОШО: "Analyze user segments: User segment A (20 users) avg spend:
€262/month..."
```

**Правило:** Anonymize данные, aggregate где можно.

---

### Не принимайте ИИ выводы как факт

```markdown
ХОРОШО: "ИИ предложил correlation между X и Y. Проверю это deeper analysis в
Excel/BI tool."

ПЛОХО: "ИИ сказал correlation — значит это 100% правда"
```

**Правило:** ИИ для exploration и hypotheses, не для final conclusions.

---

## Чек-лист анализа

Перед финализацией анализа:

- [ ] Данные anonymized (если нужно)
- [ ] Context предоставлен (ИИ понимает что это за metrics)
- [ ] Temporary anomalies учтены (holidays, campaigns)
- [ ] Trends подтверждены визуально (если возможно)
- [ ] Recommendations actionable и realistic
- [ ] Указаны limitations анализа
- [ ] Проверены calculations spot-check

---

## Pro Tips

### Tip 1: Start Broad, Then Narrow

```markdown
Сначала: "Общий overview этих metrics — что бросается в глаза?"

Потом: "Deep dive в anomaly на Week 7 — возможные причины?"
```

### Tip 2: Ask "Why" Chain

```markdown
Observation: "Churn вырос на 15% в November" Ask: "Почему?" → Answer: "Много
churned users из October cohort" Ask: "Почему October cohort особенный?" →
Answer: "Были привлечены через Promo X" Ask: "Что отличает Promo X users?"
```

### Tip 3: Combine Quantitative + Qualitative

```markdown
"Вот quantitative metrics: [data]

Также вот 5 customer quotes: [feedback]

Как qualitative insights соотносятся с numbers?"
```

---

## Дальнейшее изучение

- [Create Project Report](create-project-report.md)
- [Prompting Fundamentals](../../fundamentals/prompting-fundamentals.md)
- [Effective Prompts](../../fundamentals/effective-prompts.md)

---

## Пример: Полный анализ

**Complete workflow example:**

```markdown
**Phase 1: Data Overview** "Вот sales metrics за Q4. Дай quick summary — главные
trends?"

**Phase 2: Anomaly Detection** "Week 48 показывает spike. Investigate — что
могло вызвать?"

**Phase 3: Comparative Analysis** "Сравни Week 48 с same week прошлого года.
Differences?"

**Phase 4: Projection** "На основе Q4 trends, project Q1.
Optimistic/realistic/pessimistic scenarios."

**Phase 5: Recommendations** "Исходя из analysis, top 5 actions для Q1?"

**Phase 6: Executive Summary** "Summarize весь анализ для CEO — 1 страница,
bullet points."
```

**Результат:** Comprehensive insights из сырых данных до actionable plan.

---

**Время прочтения:** ~15 минут **Следующий сценарий:**
[Create Project Report →](create-project-report.md)
