---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Summarize meeting notes

## Preparation

1. Collect raw notes or transcript (clean obvious typos if possible).
2. Highlight decisions, owners, and due dates.
3. Determine audience (internal core team vs. customer-friendly recap).

## Prompt template

```
Summarize the following meeting transcript for <audience>.

- Group decisions separately from open risks.
- Output a table of action items: owner, task, deadline.
- Keep the summary under 8 bullet points.

Transcript:
<paste transcript>
```

## Output checklist

- Decisions vs. follow-ups are clearly separated.
- Every action item has an explicit owner and date.
- Sensitive information is redacted before sharing externally.

## Troubleshooting

- If the transcript is noisy, run a “clean-up” prompt first to remove filler
  sentences.
- For multilingual meetings, remind the model to respond in the target language.
