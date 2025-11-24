---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# Authentifizierung & Autorisierung

## Überblick

- OpenWebUI/LiteLLM nutzen Token-basierte Authentifizierung
- Admin- und Nutzerrollen klar trennen (RBAC)
- MFA empfehlen, wo verfügbar

## Token-Handling

- Access Tokens kurzlebig halten
- Refresh Tokens sicher speichern, Rotation ermöglichen
- Keine Tokens in Logs; Maskierung aktivieren

## Service-Zugänge

- Interne Services (Prometheus, Grafana, Alertmanager) hinter Auth/Reverse-Proxy
- MCP/AI-APIs mit API-Key/Token absichern
- SSH/Zugänge nur per Key, kein Passwort-Login

## Best Practices

- Starke Passwortrichtlinien, keine Wiederverwendung
- Rate-Limiting und Captcha bei Login-Formularen, falls öffentlich
- Session-Invalidierung nach Logout oder Rollenänderung
- Regelmäßige Audit-Checks: wer hat Admin, wer hat Tokens

## Fehlerbehebung

- „401/403“: Token abgelaufen oder Rollen fehlen
- „CSRF/Origin Fehler“: CORS/CSRF-Header prüfen
- „Login-Loop“: Cookies/SameSite/Domain-Einstellungen prüfen
