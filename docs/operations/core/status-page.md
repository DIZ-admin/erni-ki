---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI status page (Uptime Kuma)

A friendly status page shows whether ERNI-KI services are up, degraded, or under
maintenance. It is powered by Uptime Kuma and kept on the same internal network
as other observability tools.

## Where to find it

- Default local URL: `http://localhost:3001` (bound to localhost only).
- Production URL: configure via your reverse proxy (e.g., `/status` or a
  dedicated subdomain). Document the chosen URL here: `<STATUS_PAGE_URL>`.
- If SSO is required, reuse the existing reverse-proxy auth configuration.

## What the statuses mean

-**Operational:**all monitored checks are healthy. -**Degraded:**at least one
check is failing or slow; basic functions may still
work. -**Maintenance:**planned work is in progress; expect
interruptions. -**Unknown:**the status page cannot reach its checks—verify
network or container health.

## How to use it

1. Open the status page before raising an incident ticket.
2. If something is red or degraded, share the status link in your support
   request.
3. For scheduled maintenance, check the news posts in `News`.

## Operations notes

- The service runs via Docker Compose as `uptime-kuma` with data stored in
  `./data/uptime-kuma`.
- Adjust the exposed port or base path through the reverse proxy; avoid exposing
  the container directly to the internet.
- Back up the `data/uptime-kuma` folder with other monitoring data.
- If the container is down, restart with `docker compose up -d uptime-kuma` and
  verify healthchecks.

## Who to contact

- Platform on-call engineer for outages.
- Security or compliance for access and policy questions.
- Documentation maintainers for updates to this page.
