---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Authentifizierung und Autorisierung'
---

# Authentifizierung & Autorisierung

- JWT werden vom Auth-Service (`auth/main.go`) ausgegeben; der geheime Schlüssel
  `WEBUI_SECRET_KEY` kommt aus Docker-Secrets bzw. `.env`.
- Für externen Zugriff empfiehlt sich Cloudflare Zero Trust mit mTLS oder SSO,
  damit keine offenen Ports exponiert werden.
- Token-Lebensdauer so kurz wie möglich halten und jeder Anfrage eine
  `X-Request-ID` hinzufügen, um Traceability sicherzustellen.
- Bei**jedem**API- und Frontend-Request Token validieren und ein dediziertes
  `/validate`-Healthcheck implementieren, damit Automatisierungen Tokens testen
  können.

Siehe außerdem [security-policy.md](security-policy.md) für Rollen und Prozesse
sowie [ssl-tls-setup.md](ssl-tls-setup.md) für TLS-Konfiguration.
