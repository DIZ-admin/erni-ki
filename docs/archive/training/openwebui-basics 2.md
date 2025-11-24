---
language: ru
translation_status: archived
doc_version: '2025.11'
---

# Open WebUI basics

This quickstart is for non-technical colleagues who want to use Open WebUI
safely in day-to-day work. Use it together with the Academy KI portal for a
guided start and the ERNI Gruppe tone-of-voice guidelines.

## Before you start

- Check the [status page](../../operations/status-page.md). If the platform is
  not **Operational**, wait or follow the incident channel.
- Confirm you are using company-approved networks/VPN if required.
- Keep handy the list of allowed models and data types:
  `<INSERT APPROVED MODELS LIST>` / `<INSERT DATA CLASSIFICATION GUIDE>`.
- If you prepare client-facing texts, keep the ERNI style guide at hand
  (`<INSERT INTERNAL STYLE GUIDE>`).

## Sign in and access

- Open the Open WebUI URL provided by your team. If unsure, ask your admin or
  check the [status page](../../operations/status-page.md) for the current
  endpoint.
- Sign in with your company account if Single Sign-On is enabled. Otherwise, use
  the credentials shared by your administrator.
- If you cannot log in, verify the status page first, then contact support.

## Choose a model

- Pick the **company-approved** model from the model selector. Default choices
  usually include a general-purpose model and a faster draft model.
- For tasks with personal data, confirm the model is approved by policy
  (<INSERT INTERNAL POLICY HERE>).
- If unsure, start with the default chat model listed in the Academy KI portal
  and escalate before changing it.
- For customer communication, choose the model recommended by your delivery or
  sales lead to align with ERNI quality expectations.

## Send a request

1. Create a new chat or open an existing thread.
2. Describe your task in plain language (see the Prompting 101 pattern below).
3. Press send and wait for the response. If it is slow, check connectivity or
   the status page.

## Use history and folders

- Use chat history to keep related tasks together.
- Organize important conversations into folders or workspaces if available, so
  your team can reuse them.
- Tag or pin important threads that should be reused by colleagues (where
  supported by your deployment).
- Link key threads in your department’s Academy KI space so others can reuse
  approved prompts.

## Use prepared prompts

- Check for shared prompts or templates provided by your team (e.g., “customer
  email”, “meeting summary”).
- Duplicate a prompt and adapt it instead of writing everything from scratch.
- For recurring tasks, save the improved prompt in your team’s shared folder and
  link it from the Academy KI page for your department.
- When working on ERNI-branded materials, keep the tone concise, factual, and
  solution-oriented; include client value instead of marketing fluff.

## Basic safety

- Do not share confidential data unless approved
  (<INSERT INTERNAL POLICY HERE>).
- Avoid sending passwords or secrets.
- If a response looks incorrect or unsafe, stop and escalate to the support
  channel.
- For regulated data (PII/финансовые данные), double-check masking/anonymizing
  before pasting it into chat.
- Mark client names or project codes as placeholders (e.g., `<CLIENT>`) if the
  model is not cleared for that data class.

## Troubleshooting

- Slow or failing responses: check the
  [status page](../../operations/status-page.md), then retry.
- Access issues: confirm your account is active and verify VPN/SSO requirements.
- If problems persist, contact the platform owners with the timestamp and
  screenshot.
- For account or permission issues, mention your team/department and the model
  you were trying to use to speed up triage.
- For client work, mention whether the request was client-facing so reviewers
  can prioritize.
