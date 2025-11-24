---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'ERNI-KI status page launch'
date: 2025-11-20
description: 'New user-friendly status view powered by Uptime Kuma'
tags:
---

# ERNI-KI status page launch

## Summary

A dedicated status page is now available for end-users to see whether ERNI-KI
services are operational. It is backed by Uptime Kuma and follows the same
monitoring network as other observability tools.

## What changed

- Added Uptime Kuma service to the ERNI-KI stack for visual status checks.
- Introduced a friendly status URL (configure via your reverse proxy). Default
  local port: `3001`.
- Documented how to access the status page and interpret states.

## Impact on users

- Non-technical users can quickly check if ERNI-KI is operational without
  reading dashboards.
- Helps reduce support tickets by pointing people to the status page first when
  something feels off.
- No action required; authentication and access follow existing reverse-proxy
  rules. Coordinate with the operations team if SSO is needed.

## How to get help

- Check the [status page guide](../operations/core/status-page.md) for the
  current URL and escalation path.
- If the status page is red, notify the on-call engineer via the usual incident
  channel.
- For documentation improvements, create an issue referencing this news item.
