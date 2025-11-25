---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
title: 'ERNI-KI Status Page Launch'
date: 2025-11-20
description: 'Neue Status-Seite (Uptime Kuma) für Nutzerfreundlichkeit'
tags:
---

# ERNI-KI Status Page Launch

## Zusammenfassung

Eine dedizierte Status-Seite zeigt jetzt, ob ERNI-KI Dienste verfügbar sind.
Basis: Uptime Kuma, gleicher Monitoring-Pfad wie andere Observability-Tools.

## Änderungen

- Uptime Kuma in den Stack aufgenommen (visuelle Status-Checks).
- Freundliche Status-URL (per Reverse Proxy konfigurierbar). Standard-Lokalport:
  `3001`.
- Zugang und Interpretation dokumentiert.

## Auswirkungen auf Nutzer

- Nicht-technische Nutzer sehen schnell, ob ERNI-KI läuft, ohne Dashboards.
- Weniger Support-Tickets: zuerst Status-Seite prüfen.
- Keine Aktion erforderlich; Auth/Access folgen bestehenden Proxy-Regeln. Bei
  Bedarf SSO mit Operations abstimmen.

## Hilfe & Eskalation

- Siehe [Status Page Guide](../operations/core/status-page.md) für URL und
  Eskalationspfad.
- Bei rotem Status: On-Call über den üblichen Incident-Kanal informieren.
- Für Doku-Verbesserungen ein Issue mit Verweis auf diese News anlegen.
