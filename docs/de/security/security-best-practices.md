---
language: de
translation_status: in_progress
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Security Best Practices

## Härtung

- Nur benötigte Ports veröffentlichen; bevorzugt intern (localhost/bridge)
- Container ohne root laufen lassen, wo möglich
- Regelmäßige Updates von Basisimages und Dependencies

## Secrets

- Keine Secrets im Repo; nur via Environments/CI-Secrets
- Rotation (mind. vierteljährlich oder nach Incident)
- Zugriff auf Secrets strikt einschränken und auditieren

## Netzwerk & Zugriffe

- Segmentierung: ingress / services / monitoring / data
- Firewall/Ingress-Regeln minimal halten
- SSH nur mit Keys, Fail2ban/Rate-Limits für Admin-Zugänge

## Monitoring & Logs

- Zentrale Logaggregation (Loki/Fluent Bit), sensible Daten maskieren
- Alerts für Auth-Fehler, ungewöhnliche Ports, hohe Fehlerraten
- Healthchecks für alle kritischen Services

## CI/CD

- Geschützte Branches, Code Reviews pflicht
- Scans: Trivy/Grype, Detect-Secrets, CodeQL
- Signierte Artefakte/Images sofern möglich

## Daten & Backups

- Backups verschlüsseln und testen (Restore-Drills)
- Zugriff auf Backup-Speicher minimieren und auditieren
- TLS für Datenwege, Zertifikate regelmäßig erneuern

## Incident Readiness

- Runbooks für Secret-Rotation, User-Sperrung, Recovery
- Kontaktwege/On-Call festlegen
- Post-Mortem-Prozess etabliert
