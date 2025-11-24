---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# SSL/TLS Setup

## Ziele

- TLS für externe und interne Endpunkte
- Gültige Zertifikate, HSTS, sichere Ciphers

## Zertifikate

- Bevorzugt öffentliche CAs (Let's Encrypt) für externe Domains
- Interne Self-Signed/CAs nur mit sauberem CA-Store
- Schlüssel/Zertifikate nicht im Repo speichern

## Nginx/Proxy (Beispiel)

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
add_header Strict-Transport-Security "max-age=31536000" always;
```

## Cloudflare/Zero Trust

- TLS end-to-end sicherstellen (Origin Pull mit gültigem Zertifikat)
- Keine gemischten Inhalte (HTTPS erzwingen)

## Prüfung

- `openssl s_client -connect host:443 -servername host`
- `curl -Iv https://host`
- SSL Labs Test für öffentliche Domains

## Erneuerung/Rotation

- Automatisieren (z.B. certbot) und Reminder setzen
- Downtime vermeiden: Renew vor Ablauf + Reload statt Restart
