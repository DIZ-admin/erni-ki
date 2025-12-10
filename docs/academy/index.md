---
language: en
translation_status: partial
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Academy KI

Learning portal for ERNI colleagues who use Open WebUI and related KI services.
Russian pages stay canonical; this version mirrors the structure so users can
navigate in English.

-**Audience:**product owners, business analysts, support engineers, and anyone
using Open WebUI. -**Modules:**-**Open WebUI basics**— where to find the
service, how to pick a model, how to send the first request, how to use
templates. -**Prompting 101**— role → task → context → format, checklists, and
office scenarios. -**HowTo**— step-by-step guides for emails, meeting summaries,
Jira tickets, with good/bad prompt examples. -**News**— product changes, impact
on users, and what to do after updates. -**System → Status**— link to the Uptime
Kuma dashboard to verify service health first. -**Freshness:**Russian content is
the source of truth; translation status is tracked per page as
`translation_status`.

## Recommended learning path

1.**Week 1 – Interface**: finish Open WebUI basics, submit two prompts using the
template gallery, and test MCP tool calls. 2.**Week 2 – Prompt craft**: apply
the Prompting 101 checklist to an existing customer communication; compare AI
vs. human draft. 3.**Week 3 – Automation**: run through each HowTo and
contribute feedback or new prompts.

## Contribution guidelines

- Keep the Russian version authoritative; submit English/German updates only
  after RU content is merged.
- Add screenshots (PNG, max 1920×1080) to `docs/images/academy/` and reference
  them using Markdown with alt text.
- For new modules, create an index file with learning objectives and expected
  duration.

> Always start with the health check:
> **[System status](https://status.erni-ki.ch)**.
