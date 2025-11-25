---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Open WebUI basics

Open WebUI is the default interface for interacting with ERNI-KI. The summary
below mirrors the Russian canonical guide and gives the essentials so an
English-speaking operator can work without switching locales.

## Quick tour

- **Sidebar** – access chat history, file attachments, and the AG-UI event
  stream.
- **Prompt composer** – supports multi-line prompts, Markdown, and tool calls.
- **Status footer** – shows connected model, MCP tool availability, and GPU
  usage.

## Daily workflow

1. **Pick a workspace** (project/customer) before sending prompts; this keeps
   audits and costs separated.
2. **Attach context** – drag documents or screenshots into the panel so they are
   indexed for the current session.
3. **Use system prompts** – the `Templates` menu stores reusable prompts for
   emails, reports, or diagnostics.
4. **Track responses** – each reply exposes tokens, latency, and tool calls so
   you can assess quality or escalate issues.

## Attachments & tools

- Files up to 25 MB per upload, automatically routed through Docling/Tika.
- MCP tools—including Filesystem, PostgreSQL, and Time—are available via the
  “Tools” icon once Archon authorizes them.
- Use `@` mentions to call custom tools (e.g., `@diagnostics.start_check`).

## Troubleshooting

- If the chat area shows “Waiting for response” longer than 20 s, open the MCP
  Activity panel and copy the correlation ID when reporting an incident.
- Use `CTRL+SHIFT+L` to download raw logs for the last session.

## Further reading

- [System status](../../system/status.md) – check incidents before escalating.
- [Prompting 101](prompting-101.md) – high-level guidance for writing effective
  prompts.
- [HowTo guides](howto/index.md) – ready-made flows for customer emails, meeting
  summaries, and ticket creation.
