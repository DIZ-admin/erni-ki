---
language: ru
---

# Summarize meeting notes

## When to use this

Use when you have raw notes or chat logs and need a concise summary with next
steps. If Open WebUI is slow, see the
[status page](../../operations/status-page.md) before retrying.

## Step-by-step

1. Collect the meeting notes (chat export or bullet list).
2. Open Open WebUI and select a summarization-friendly model.
3. Prompt the model with the notes and ask for a structured summary.
4. Request bullet points for decisions, risks, and owners for each action.
5. Copy the output into the meeting record and adjust names or dates.

## Example prompts

- **Good:** "Role: project coordinator. Task: summarize the meeting notes.
  Context: product launch sync, attendees: marketing + engineering. Constraints:
  highlight risks and owners. Format: sections for Summary, Decisions, Actions
  with owners and due dates. Notes: <paste notes>."
- **Good:** "You are an executive assistant. Summarize this transcript into 5
  bullets and 3 action items. Include who owns each action and the due date if
  mentioned. Transcript: <paste transcript>."
- **Avoid:** "Make it short" without context, or omitting ownership and
  deadlines.
