---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# System status

## Introduction

This document provides an overview of the system status dashboard and how to
interpret its indicators.

Status dashboard:**https://status.ki.erni-gruppe.ch**(Uptime Kuma).

## How to use it

1. Open the dashboard before filing incidents or tickets.
2. If a component is**Partial**or**Major Outage**, check maintenance windows and
   follow the communication channel listed on the status page.
3. For problems not shown as incidents, collect timestamp, URL, model name, and
   screenshot before escalating (see `docs/operations/core/status-page.md`).

## Components tracked

- Open WebUI front-end and API gateway
- MCP servers (filesystem, PostgreSQL, memory)
- Ollama/LiteLLM stack
- Docling/Tika ingestion pipeline
- Monitoring plane (Prometheus, Grafana, Alertmanager)

Each component shows latency, uptime, and last check timestamp. Click the tile
to view raw probe logs when debugging.

## Escalation checklist

1. Confirm the dashboard status and note the incident ID if one exists.
2. Gather request ID (`X-Request-ID`) from the failing client.
3. Capture token usage or latency spikes from the Open WebUI footer.
4. Attach the screenshots/logs when creating a ticket or pinging on-call.

## When to raise an incident

-**Major Outage**tile visible: immediately notify the on-call engineer and
create a communication post. -**Partial Outage**but affecting your customer:
open a Jira Ops issue with impact statement and link to status page entry. -**No
incident visible**yet reproducible issue: create a draft post in Uptime Kuma and
contact the status-page owners listed in `operations/core/status-page.md`.

## Related documentation

- Operations runbook and escalation:
  [operations/core/status-page.md](../operations/core/status-page.md)
- User basics for Open WebUI:
  [academy/openwebui-basics.md](../academy/openwebui-basics.md)
- Prompting checklist:
  [academy/prompting-101.md](../academy/prompting-101.md)
