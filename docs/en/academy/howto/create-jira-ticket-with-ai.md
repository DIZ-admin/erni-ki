---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Create a JIRA ticket with AI

## Introduction

This guide explains how to generate JIRA tickets using AI assistance. It covers
required inputs, configuration steps, and example prompts to streamline ticket
creation.

## Inputs required

- Issue type (Bug/Story/Task) and priority.
- Environment or service affected.
- Observed behavior, expected behavior, and reproduction steps.
- Links to logs, screenshots, or dashboards.

## Prompt template

```
Create a Jira issue from the facts below.

Issue type: <type>
Priority: <priority>
Component/service: <component>
Summary hint: <concise sentence>

Observed behaviour: <text>
Expected behaviour: <text>
Steps to reproduce:
1. ...
2. ...

Acceptance criteria:
- ...

Respond with sections: Summary, Description, Steps to Reproduce, Acceptance
Criteria, Attachments, Tags.
```

## Review checklist

- Summary mentions component and impact.
- Description clearly separates observed vs. expected results.
- Acceptance criteria are testable and align with the definition of done.
- Attachments reference file names already uploaded to the chat.

## After generating the draft

Paste the content into the Jira Create dialog, assign the correct team, and add
the label `ai-draft` so reviewers know the origin. Update the ticket status once
manually verified.
