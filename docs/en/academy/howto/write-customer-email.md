---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Write a customer email

Use this structure when drafting customer-facing emails with Open WebUI.

## Preparation checklist

1. Incident or request ID.
2. Customer name, account, and timezone.
3. Latest status (including blockers and ETA).
4. Required call-to-action or approval.
5. Tone preference (formal / neutral / friendly).

## Prompt template

```
You are writing an email to <customer_name>. Use a <tone> tone.

Context:
- Topic: <brief summary>
- Current status: <status/ETA>
- Needed action: <action items>
- Additional notes: <risks/escalations>

Draft a concise email with greeting, body, next steps, and signature.
```

## QA checklist

- Confirm the email references the correct incident/request ID.
- Verify that dates and times mention the customer’s timezone.
- Ensure there is a clear ask (or explicitly state “no action required”).
- Remove internal-only abbreviations before sending.

## Example output

```
Hello <Name>,

thanks for confirming access to workspace ACME-143. Our engineers applied the
fix at 14:30 CET and monitoring shows recovery.

Next steps
- Keep an eye on the dashboard for 1 hour.
- Let us know if new errors appear.

Regards,
ERNI Support
```

## Related materials

- [System status](../../system/status.md) – double-check for open incidents.
- [Prompting 101](../prompting-101.md) – best practices for structured prompts.
