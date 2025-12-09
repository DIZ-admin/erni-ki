# SSL Certificates from Cyon for ki.erni-gruppe.ch

**Download Date:** November 11, 2025
**Source:** Cyon server (149.126.4.96)

---

## Certificate Information

### ki.erni-gruppe.ch-fullchain.crt

**Type:** Let's Encrypt SSL Certificate (Full Chain)

**Details:**

```
Subject: CN = ki.erni-gruppe.ch
Issuer: C = US, O = Let's Encrypt, CN = R12
Valid From: Nov 11 06:44:54 2025 GMT
Valid Until: Feb  9 06:44:53 2026 GMT (90 days)
```

**Subject Alternative Names (SAN):**
- DNS:ki.erni-gruppe.ch
- DNS:www.ki.erni-gruppe.ch

**File Size:** 3.6K

---

## Certificate Verification

### View certificate details:

```bash
openssl x509 -in ki.erni-gruppe.ch-fullchain.crt -noout -text
```

### Check validity period:

```bash
openssl x509 -in ki.erni-gruppe.ch-fullchain.crt -noout -dates
```

### Check SAN (Subject Alternative Names):

```bash
openssl x509 -in ki.erni-gruppe.ch-fullchain.crt -noout -ext subjectAltName
```

---

## Notes

1. **This certificate is used on Cyon server** (149.126.4.96)
2. **Automatic renewal:** Cyon automatically renews the certificate every 60 days
3. **Next renewal:** ~January 9, 2026 (30 days before expiration)
4. **Certificate includes both domains:**
   - ki.erni-gruppe.ch
   - www.ki.erni-gruppe.ch

---

## Certificate Update

To download an updated certificate from Cyon server:

```bash
echo | openssl s_client -connect 149.126.4.96:443 -servername ki.erni-gruppe.ch -showcerts 2>/dev/null | \
  sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > ki.erni-gruppe.ch-fullchain.crt
```

---

## Important

- **DO NOT use this certificate on ERNI-KI server** - it is intended only for Cyon server
- **Private key is NOT available** - it is stored only on Cyon server
- **For ERNI-KI use Cloudflare Origin Certificate** or Let's Encrypt with HTTP-01 challenge
