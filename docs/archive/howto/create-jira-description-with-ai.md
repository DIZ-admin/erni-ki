---
language: ru
---

# Create a JIRA description with AI

## When to use this

Use this when you need a clear issue description or user story faster. If Open
WebUI reports errors, check the [status page](../../operations/status-page.md)
and retry later.

## Step-by-step

1. Gather the problem statement, expected outcome, and any screenshots or logs.
2. Open Open WebUI and select the model recommended for ticket writing.
3. Provide the context (team, system, environment) and ask for a JIRA-friendly
   format.
4. Review acceptance criteria and add missing links or attachments.
5. Paste the draft into JIRA and assign the issue.

## Example prompts

- **Good:** "Role: tech lead. Task: draft a JIRA bug ticket. Context: login page
  shows 500 error on staging. Constraints: include steps to reproduce, expected
  vs actual, logs reference, and impact. Format: Markdown with headings. Extra:
  include a checklist for mitigation."
- **Good:** "You are a product owner. Create a user story for adding SSO.
  Context: users want one-click access. Constraints: include business value,
  story, acceptance criteria (Given/When/Then), and non-functional notes."
- **Avoid:** Submitting auto-generated text without verifying logs, or sharing
  sensitive data without checking <INSERT INTERNAL POLICY HERE>.
