---
language: ru
---

# Prompting 101

Learn the simplest structure to get reliable answers from Open WebUI. This
cheat-sheet is part of the Academy KI track for офисных пользователей и отражает
тон ERNI Gruppe: уважительно, по делу, с акцентом на клиентскую ценность.

## What is a prompt?

A prompt is the instruction you give to the AI. Clear prompts lead to better
answers and less rework.

## The simple pattern: ROLE + TASK + CONTEXT + FORMAT

- **ROLE:** who the AI should act as (e.g., "project assistant").
- **TASK:** what you need (e.g., "summarize these notes").
- **CONTEXT:** background info the AI must know (team, product, deadlines).
- **FORMAT:** how the output should look (bullets, table, steps, or JSON).
- **TONE (optional):** if клиент-facing, remind the AI to match ERNI style:
  concise, factual, respectful.

### Examples

1. **Customer reply draft (ERNI tone)** "Role: customer support agent at ERNI.
   Task: draft a polite reply. Context: customer asks about delivery delay;
   order ID is <ID>. Constraints: under 120 words, clear next steps, ERNI-style
   factual tone. Format: short paragraphs."
2. **Meeting summary** "You are an executive assistant. Summarize this meeting
   transcript into sections: Summary, Decisions, Actions (owner + due date).
   Keep it under 200 words. Transcript: <paste text>."
3. **JIRA story for delivery** "Role: product owner. Task: create a user story.
   Context: need SSO for web app, users want one-click access. Format: User
   Story + Acceptance Criteria (Given/When/Then) + Non-functional notes. Mention
   data sensitivity if any."
4. **Policy-safe check** "Act as a compliance assistant. Review this draft
   message for sensitive data. Highlight anything that may violate
   <INSERT INTERNAL POLICY HERE>. Output: bullet list of risks + suggested
   rewrites."
5. **Proposal teaser** "Role: ERNI consulting pre-sales. Task: draft a
   3-sentence teaser for a proposal about <TOPIC>. Tone: concise,
   engineering-led, respectful. Format: bullets with client value and next
   action."
6. **Data cleanup** "You are a data assistant. Normalize this contact list into
   a table with Name, Company, Email. Remove duplicates."

## Quick checklist before you send

- State the **role** and **audience** (e.g., customer, manager, vendor).
- Add deadlines and word limits to control the length.
- Paste only the minimum context required; avoid sensitive data
  (<INSERT INTERNAL POLICY HERE>).
- Ask for concise output first, then iterate.
- If the AI drifts, repeat the context and remind the format.
- For клиент-facing текст, добавляйте напоминание об «ERNI tone: concise,
  respectful, engineering-led».

## Ready-to-use starters for офисных задач

- **Ответ клиенту:** "Role: customer support. Task: reply politely. Context:
  delivery delayed by 2 days; offer updated ETA. Format: 3 short paragraphs.
  Constraints: avoid technical jargon, keep under 120 words. Tone: ERNI — факты,
  уважительность."
- **Резюме встречи:** "You are an executive assistant. Summarize the meeting.
  Format: Summary, Decisions, Action items (owner + due date). Keep it under 200
  words."
- **Описание вакансии:** "Role: HR recruiter. Task: draft a job post for
  <POSITION>. Context: team size <N>, main tech <STACK>. Format: sections: About
  the team, Responsibilities, Must-have, Nice-to-have. Constraints: adapt to our
  tone of voice (<INSERT INTERNAL STYLE GUIDE>)."
- **Фактчекинг:** "Act as compliance assistant. Review this draft and point to
  anything that may conflict with <INSERT INTERNAL POLICY HERE>. Output: bullets
  with risks + suggested rewrites."
- **Анонс новости:** "Role: marketing editor. Task: draft an intranet news item
  about <UPDATE>. Tone: ERNI (engineering плюс эмпатия), 120–150 words. Format:
  title + summary + why it matters for clients/teams."

## Tips for non-technical users

- Be specific about the outcome and format.
- Mention deadlines, audience, and any banned topics
  (<INSERT INTERNAL POLICY HERE>).
- Ask for shorter answers first; request more detail only if needed.
- If the AI seems off-topic, restate the context and constraints.
- For клиент-facing текст, просите «ERNI tone» и указывайте ссылку на
  [erni-gruppe.ch](https://www.erni-gruppe.ch/) при необходимости.

## Safety reminders

- Do not paste confidential data unless you are sure the model is approved for
  it.
- Avoid sharing passwords, keys, or personal identifiers.
- When unsure, check the [status page](../../operations/status-page.md) and
  reach out to the support channel.
