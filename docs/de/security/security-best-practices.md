---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Security Best Practices'
---

# Security Best Practices

- Geheimnisse nicht in `compose.yml` ablegen: Docker-Secrets oder ENV nutzen und
  keine Klartextwerte einchecken.
- Datenbanken und Cache mit eigenen Accounts/RLS betreiben, keine geteilten
  Passwörter.
- Regelmäßig `npm audit --omit=dev` und `gosec` ausführen (siehe
  `security.yml`-Workflow).
- Container-Images via Watchtower/GitHub Actions aktuell halten und Changelogs
  kritischer Abhängigkeiten prüfen.
- Authentifizierungsversuche loggen und zentral in Loki/Fluent Bit sammeln.

Weitere Rollen/Policies: [security-policy.md](security-policy.md) – TLS und
Proxy-Konfigurationen: [ssl-tls-setup.md](ssl-tls-setup.md).
