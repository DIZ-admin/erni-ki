---
language: de
translation_status: in_progress
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Sicherheitsrichtlinie (ERNI-KI)

## Ziele

- Vertraulichkeit, Integrität, Verfügbarkeit der Plattform
- Schutz sensibler Daten (Kunden, Modelle, Logs)
- Klare Rollen und Verantwortlichkeiten

## Rollen

- **Owner / Security Lead** – Richtlinien, Freigaben, Ausnahmen
- **Ops / DevOps** – Betrieb, Patching, Secrets-Handling
- **Developer** – sicherer Code, Befolgung von Lint/Scan-Pflichten
- **Incident Commander** – Leitung bei Sicherheitsvorfällen

## Grundsätze

- **Least privilege**: Minimalrechte für Dienste und Nutzer
- **Segmentation**: Getrennte Netze für ingress/services/monitoring/data
- **Secrets**: Nie im Repo, nur über Environments/CI-Secrets; Rotation geplant
- **Logging & Audit**: sicherheitsrelevante Events aufbewahren, Zugriff
  beschränken
- **Patching**: reguläre Updates für OS, Images, Abhängigkeiten

## Authentifizierung & Autorisierung

- Starke Passwörter/Keys, MFA wo möglich
- Tokens zeitlich begrenzen; Refresh/Revocation-Prozess
- Rollenbasierte Zugriffe (RBAC) für Admin/Support/ReadOnly

## Daten- und Schlüsselmanagement

- TLS-Zertifikate verwalten (siehe ssl-tls-setup.md)
- Backups verschlüsseln, Zugriffe protokollieren
- Keine Secrets in Logs; Maskierung für sensible Felder

## CI/CD Sicherheit

- Geschützte Branches, Code Reviews obligatorisch
- Signierte Container (sofern möglich), Vulnerability-Scans (Trivy/Grype)
- Detect-Secrets / Pre-commit Pflicht

## Incident Response (Kurzablauf)

1. Erkennung und Einstufung
2. Eindämmung (Zugänge sperren, Secrets rotieren)
3. Forensik/Analyse (Logs sichern)
4. Behebung/Hotfix
5. Post-Mortem + Maßnahmenplan

## Schulung & Awareness

- Regelmäßige Security-Trainings
- Checklisten für neue Teammitglieder
