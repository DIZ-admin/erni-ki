---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
title: 'Start der ERNI-KI Statusseite'
date: 2025-11-20
description: 'Neue benutzerfreundliche Statusansicht powered by Uptime Kuma'
tags:
---

# Start der ERNI-KI Statusseite

## Zusammenfassung

Eine dedizierte Statusseite ist jetzt für Endbenutzer verfügbar, um zu sehen, ob
ERNI-KI-Dienste betriebsbereit sind. Sie wird von Uptime Kuma unterstützt und
folgt demselben Überwachungsnetzwerk wie andere Observability-Tools.

## Was sich geändert hat

- Uptime Kuma Service zum ERNI-KI Stack für visuelle Statusprüfungen
  hinzugefügt.
- Einführung einer benutzerfreundlichen Status-URL (konfigurierbar über Ihren
  Reverse Proxy). Standardmäßiger lokaler Port: `3001`.
- Dokumentiert, wie auf die Statusseite zugegriffen wird und wie Zustände zu
  interpretieren sind.

## Auswirkungen auf Benutzer

- Nicht-technische Benutzer können schnell prüfen, ob ERNI-KI betriebsbereit
  ist, ohne Dashboards lesen zu müssen.
- Hilft, Support-Tickets zu reduzieren, indem Benutzer zuerst auf die
  Statusseite verwiesen werden, wenn etwas nicht stimmt.
- Keine Aktion erforderlich; Authentifizierung und Zugriff folgen bestehenden
  Reverse-Proxy-Regeln. Stimmen Sie sich mit dem Operations-Team ab, wenn SSO
  benötigt wird.

## Wie man Hilfe bekommt

- Prüfen Sie den [Leitfaden zur Statusseite](../operations/core/status-page.md)
  für die aktuelle URL und den Eskalationspfad.
- Wenn die Statusseite rot ist, benachrichtigen Sie den Bereitschaftsingenieur
  über den üblichen Incident-Kanal.
- Für Dokumentationsverbesserungen erstellen Sie ein Issue mit Bezug auf diese
  Nachricht.
