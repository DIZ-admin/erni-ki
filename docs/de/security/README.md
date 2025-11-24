---
language: de
translation_status: in_progress
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Sicherheit – Übersicht

Kurzer Überblick über die Sicherheitsprinzipien von ERNI-KI.

## Grundprinzipien

- **Least privilege**: minimal nötige Rechte für Dienste und Nutzer
- **Secrets nicht im Repo**: nur über `.env`/CI-Secrets
- **TLS überall**: interne/externe Pfade TLS-geschützt
- **Audits & Logging**: sicherheitsrelevante Events werden geloggt

## Kernbereiche

- [Security Policy](security-policy.md) – Rollen, Verantwortlichkeiten,
  Incident-Flow
- [Authentication](authentication.md) – AuthN/AuthZ, Token-Handling
- [Security Best Practices](security-best-practices.md) – Härtung, Prozesse
- [SSL/TLS Setup](ssl-tls-setup.md) – Zertifikate, CAs, HSTS
- [Log Audit](log-audit.md) – Prüf- und Review-Checklisten

## Betrieb

- Secrets rotieren (mind. vierteljährlich oder nach Incident)
- Regelmäßige Scans (Trivy, Grype, Detect Secrets, CodeQL)
- CI/CD: geschützte Branches, Environments mit Approvals

## Incident Response (Kurz)

1. Erkennen und isolieren
2. Geheimnisse rotieren, Zugänge entziehen
3. Forensik-Logs sichern, Ursache identifizieren
4. Fix deployen, Tests und Monitoring prüfen
