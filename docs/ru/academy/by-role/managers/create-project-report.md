---
title: 'Создание отчётов по проекту с ИИ'
category: management
difficulty: easy
duration: '10 min'
roles: ['manager', 'project-manager', 'tech-lead']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Создание отчётов по проекту с ИИ

## Цель

Использовать ИИ для быстрого создания профессиональных project reports, status
updates, и executive summaries.

## Для кого

- **Project Managers** — регулярные статус-отчёты
- **Tech Leads** — technical progress reports
- **Team Leads** — sprint summaries

## ⏱ Время выполнения

10-15 минут на отчёт

## Что вам понадобится

- Доступ к Open WebUI
- Project data (progress, metrics, issues)
- **Рекомендуемая модель:** GPT-4o или Claude 3.5

---

## Базовый шаблон промпта

```markdown
Создай project status report:

**Project:** [название] **Period:** [даты] **Audience:** [stakeholders]
**Format:** [Executive Summary / Detailed / Dashboard]

**Current Status:**

- Progress: [X%]
- On track: [Yes/No/At risk]
- Budget: [status]

**Completed:**

- [пункт 1]
- [пункт 2]

**In Progress:**

- [пункт 1]
- [пункт 2]

**Blockers/Risks:**

- [issue 1]
- [issue 2]

**Next Steps:**

- [action 1]
- [action 2]

Тон: [Professional/Executive/Technical]
```

---

## Типы отчётов

### 1. Executive Summary (для management)

**Промпт:**

```
Создай Executive Summary для project status:

Project: E-commerce Platform Redesign
Period: November 2024
Status: 75% complete, ON TRACK

Completed this month:
- New checkout flow deployed (increased conversion by 15%)
- Mobile responsive design completed
- Payment gateway integration tested

In progress:
- Admin dashboard (80% done)
- Performance optimization
- User acceptance testing

Risks:
- 3rd party API delays affecting admin panel
- Need 1 additional week for UAT

Budget: On track (€45K of €50K spent)
Timeline: Dec 15 launch still achievable with mitigation plan

Next milestone: Dec 1 - Complete admin dashboard

Audience: C-level executives
Tone: Confident but honest about risks
Length: 1 page max
Format: Bullet points, bolded key metrics
```

**Результат:** Краткий, impactful summary для executives

---

### 2. Detailed Status Report (для stakeholders)

**Промпт:**

```
Создай detailed project status report:

Project: Customer Portal Migration
Sprint: Sprint 12 (Nov 18 - Dec 1)

Completed (Story points: 45/50):
- User authentication module (8 pts)
- Dashboard redesign (13 pts)
- API endpoints v2 (12 pts)
- Unit tests coverage 85% (8 pts)
- Documentation updated (4 pts)

In Progress (carry over to Sprint 13):
- Email notification service (5 pts) - 80% done
 Blocker: SMTP configuration pending from IT

Metrics:
- Velocity: 45 pts (target: 50)
- Bug count: 3 minor (down from 7)
- Test coverage: 85% (target: 90%)
- Tech debt: 2 items added, 3 resolved

Team health: Green (no leaves, high morale)

Risks:
1. SMTP config delay - Medium risk
 Mitigation: Using temporary workaround
2. Database migration complexity - Low risk
 Mitigation: Extra testing planned

Next Sprint Goals:
- Complete email service
- Start payment integration
- Conduct security audit

Format: Structured sections with metrics
Audience: Product Owner + Tech Stakeholders
```

---

### 3. Sprint Retrospective Summary

**Промпт:**

```
Создай sprint retrospective summary:

Sprint: Sprint 15
Team: Frontend team (5 developers)

What went well:
- Pair programming reduced bugs by 40%
- New code review process working great
- Team collaboration improved
- All critical features delivered

What didn't go well:
- Too many meetings (team feedback)
- Unclear requirements on Feature X
- Testing environment downtime (2 days)

Action items for next sprint:
- Reduce meeting time by 30%
- Requirements review before sprint start
- Backup testing environment setup

Team morale: 8/10 (good)
Key insight: "Pair programming pays off"

Format: Concise, actionable
Tone: Constructive, forward-looking
```

---

### 4. Risk & Issue Report

**Промпт:**

```
Создай focused risk report:

Project: Mobile App Launch
Current phase: UAT

Identified risks:

Risk 1: 3rd party payment gateway instability
- Impact: HIGH (blocks production launch)
- Probability: MEDIUM
- Status: Active issue
- Mitigation: Testing alternative provider
- Owner: Tech Lead
- Timeline: Decision needed by Dec 5

Risk 2: iOS app review delay
- Impact: MEDIUM (delays launch 1-2 weeks)
- Probability: LOW
- Mitigation: Submitted early, pre-launch PR ready
- Status: Monitoring

Risk 3: Performance on older devices
- Impact: MEDIUM (affects 15% users)
- Probability: HIGH
- Mitigation: Optimization sprint planned
- Status: In progress

Format: RAG (Red/Amber/Green) dashboard style
Для каждого риска: Impact, Probability, Mitigation, Owner
Приоритет: показать топ 3 критичных
```

---

## Продвинутые техники

### Техника 1: Data Visualization Description

```
"Создай project dashboard description который можно воссоздать:

Metrics:
- Progress: 75% (green)
- Budget: 90% used (amber)
- Timeline: On track (green)
- Quality: 12 open bugs (amber)

Опиши:
1. Какие widgets показать
2. Какие цвета использовать
3. Как расположить визуально
4. Key insights to highlight

Формат: Spec для dashboard creation"
```

### Техника 2: Trend Analysis

```
"Вот metrics последние 4 спринта:

Sprint 12: Velocity 45, Bugs 12
Sprint 13: Velocity 48, Bugs 8
Sprint 14: Velocity 52, Bugs 5
Sprint 15: Velocity 50, Bugs 3

Проанализируй trends:
- Что улучшается?
- Что ухудшается?
- Insights и recommendations

Добавь в project report как 'Trends & Insights' section"
```

### Техника 3: Comparative Reports

```
"Сравни progress двух проектов:

Project A:
- 80% complete
- 2 weeks ahead
- Budget: on track
- Team: 5 people

Project B:
- 60% complete
- 1 week behind
- Budget: 10% over
- Team: 3 people

Создай comparative summary для management:
- Highlight differences
- Explain factors
- Recommendations"
```

---

## Шаблоны для быстрого старта

### Шаблон 1: Weekly Status

```
Создай weekly status update:

Week of [dates]
Project: [name]

Highlights:
- [achievement 1]
- [achievement 2]

Completed:
- [task 1]
- [task 2]

Next week focus:
- [priority 1]
- [priority 2]

Blockers: [if any]

Length: 5-7 bullet points
Tone: Brief and actionable
```

### Шаблон 2: Milestone Report

```
Project milestone [name] reached!

Milestone: [title]
Date: [date]
Significance: [why important]

Delivered:
- [deliverable 1]
- [deliverable 2]

Key achievements:
- [metric or achievement]

Team shoutout: [recognize contributors]

Next milestone: [name] on [date]

Format: Celebration + forward look
Tone: Positive, motivating
```

### Шаблон 3: Crisis Report

```
URGENT: Project issue report

Issue: [brief description]
Severity: [Critical/High/Medium]
Impact: [what's affected]
Discovered: [when]

Current status: [detailed]

Immediate actions taken:
- [action 1]
- [action 2]

Mitigation plan:
- [step 1] - Owner: [name] - ETA: [date]
- [step 2] - Owner: [name] - ETA: [date]

Customer impact: [yes/no + details]

Next update: [when]

Format: Clear, actionable, honest
Tone: Urgent but controlled
```

---

## Специализированные отчёты

### Для Agile/Scrum

```
Создай sprint report:

Sprint [number]: [dates]
Team: [name]
Capacity: [points]

Commitment vs Delivery:
- Committed: [X] points
- Delivered: [Y] points
- Carry over: [Z] points

User stories completed: [list]
Sprint goal achieved: [Yes/Partially/No]

Velocity chart data:
- Last 5 sprints: [45, 48, 52, 50, 47]
- Average: [48.4]
- Trend: [stable/improving/declining]

Definition of Done met: [Yes/No + details]

Retrospective highlights: [key points]
```

### Для Waterfall Projects

```
Создай phase completion report:

Project: [name]
Phase: [Design/Development/Testing/etc]
Planned duration: [X weeks]
Actual duration: [Y weeks]

Phase deliverables:
- [deliverable 1]: Complete
- [deliverable 2]: Complete
- [deliverable 3]: Partial (details)

Quality gates passed: [X/Y]

Lessons learned:
- [insight 1]
- [insight 2]

Handoff to next phase:
- Ready: [date]
- Prerequisites: [list]

Sign-off: Pending approval from [stakeholder]
```

---

## Важные правила

### Data Anonymization

```
 ПЛОХО:
"Project Phoenix (€2.5M) for Siemens is behind schedule
due to John Smith's team performance issues"

 ХОРОШО:
"Project X (large enterprise) experiencing delays
due to resource constraints in Team B"
```

### Honest But Constructive

```
 ХОРОШО:
"Challenge: Database migration taking longer than planned
Impact: 1 week delay to testing phase
Mitigation: Added 2 specialists, working overtime if needed
Confidence: Can recover timeline"

 ПЛОХО:
"Everything's fine" [when it's not]
```

---

## Чек-лист отчёта

Перед отправкой проверьте:

### Содержание:

- [ ] Ясный статус (on track/at risk/delayed)
- [ ] Конкретные achievements
- [ ] Честная оценка рисков
- [ ] Actionable next steps
- [ ] Metrics где applicable

### Формат:

- [ ] Подходящий для аудитории
- [ ] Правильный уровень детализации
- [ ] Нет конфиденциальных данных
- [ ] Визуально читаемый (bullets, headers)

### Качество:

- [ ] Без опечаток
- [ ] Даты корректны
- [ ] Цифры проверены
- [ ] Тон подходящий

---

## Pro Tips

### Tip 1: Version Control

Сохраняйте шаблоны промптов для повторного использования:

```
"Используй формат из прошлого weekly report (от [date])
но обнови данными за текущую неделю: [новые данные]"
```

### Tip 2: Consistency

```
"Сохраняй consistent формат и структуру со всеми предыдущими
monthly reports. Используй те же section headers и metrics."
```

### Tip 3: Audience Adaptation

```
"У меня один report, нужно три версии:
1. Executive (1 page, high-level)
2. Stakeholders (2-3 pages, detailed)
3. Team (technical, full details)

Адаптируй tone и detail level для каждой аудитории."
```

---

## Дальнейшее изучение

- [Write Professional Email](../general-users/write-professional-email.md)
- [Analyze Metrics](analyze-metrics.md)
- [Prompting Fundamentals](../../fundamentals/prompting-fundamentals.md)

---

**Следующий сценарий:** [Analyze Metrics →](analyze-metrics.md)
