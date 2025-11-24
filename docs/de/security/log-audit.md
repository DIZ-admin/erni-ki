---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# Log Audit & Review

## Zweck

- Sicherstellen, dass sicherheitsrelevante Logs vollständig, zugänglich und
  geprüft sind.

## Was prüfen

- **Vollständigkeit**: zentrale Aggregation (Loki/Fluent Bit) aktiv?
- **Zugriff**: Logs nur für berechtigte Rollen
- **Maskierung**: keine Secrets/API-Keys/PII in Logs
- **Retention**: Aufbewahrungsfristen und Rotation definiert

## Checkliste (monatlich)

- Error/Warning-Spitzen und wiederkehrende Alerts
- Auth-Fehler, verdächtige IPs, Rate-Limits
- Änderungen an Rollen/Policies, fehlgeschlagene Deploys
- Backup- und Health-Monitor-Logs vorhanden

## Aktionen bei Findings

- Incident-Flow starten (Containment, Analyse, Fix)
- Falls Secrets geleakt: Rotation und Token-Revoke
- Post-Mortem dokumentieren, Regeln/Alerts anpassen

## Tools/Quellen

- Loki/Grafana Explore
- Alertmanager (Security/Access-Alerts)
- Health-Monitor-Skripte, Backrest-Logs
