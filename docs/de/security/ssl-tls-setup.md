---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'SSL/TLS Setup'
---

# SSL/TLS-Konfiguration

- Für öffentliche Domains Cloudflare Managed Certificates oder Let’s Encrypt
  einsetzen; interner Traffic idealerweise via mTLS.
- Nur TLS 1.2/1.3 erlauben, veraltete Cipher verbieten und HSTS am Front-Proxy
  aktivieren.
- Zertifikate automatisch erneuern (certbot/Cloudflare-API) und Laufzeiten
  monitoren.
- Private Keys außerhalb des Repos speichern (`secrets/`, Docker-Secrets) und
  Zugriffe beschränken.
- Konfigurationen regelmäßig mit `openssl s_client` und externen Scannern (z.B.
  Mozilla Observatory, Qualys SSL Labs) testen.

Weitere Richtlinien siehe [security-policy.md](security-policy.md); Netzwerk-
und Proxy-Details stehen in `compose.yml` und `conf/nginx/`.
