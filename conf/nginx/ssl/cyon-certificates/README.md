# SSL-сертификаты Cyon для ki.erni-gruppe.ch

**Дата скачивания:** 11 ноября 2025  
**Источник:** Cyon сервер (149.126.4.96)

---

## Информация о сертификате

### ki.erni-gruppe.ch-fullchain.crt

**Тип:** Let's Encrypt SSL Certificate (Full Chain)

**Детали:**

```
Subject: CN = ki.erni-gruppe.ch
Issuer: C = US, O = Let's Encrypt, CN = R12
Valid From: Nov 11 06:44:54 2025 GMT
Valid Until: Feb  9 06:44:53 2026 GMT (90 дней)
```

**Subject Alternative Names (SAN):**
- DNS:ki.erni-gruppe.ch
- DNS:www.ki.erni-gruppe.ch

**Размер файла:** 3.6K

---

## Проверка сертификата

### Просмотр деталей сертификата:

```bash
openssl x509 -in ki.erni-gruppe.ch-fullchain.crt -noout -text
```

### Проверка срока действия:

```bash
openssl x509 -in ki.erni-gruppe.ch-fullchain.crt -noout -dates
```

### Проверка SAN (Subject Alternative Names):

```bash
openssl x509 -in ki.erni-gruppe.ch-fullchain.crt -noout -ext subjectAltName
```

---

## Примечания

1. **Этот сертификат используется на Cyon сервере** (149.126.4.96)
2. **Автоматическое обновление:** Cyon автоматически обновляет сертификат каждые 60 дней
3. **Следующее обновление:** ~9 января 2026 (за 30 дней до истечения)
4. **Сертификат включает оба домена:**
   - ki.erni-gruppe.ch
   - www.ki.erni-gruppe.ch

---

## Обновление сертификата

Для скачивания обновленного сертификата с Cyon сервера:

```bash
echo | openssl s_client -connect 149.126.4.96:443 -servername ki.erni-gruppe.ch -showcerts 2>/dev/null | \
  sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > ki.erni-gruppe.ch-fullchain.crt
```

---

## Важно

- **НЕ используйте этот сертификат на ERNI-KI сервере** - он предназначен только для Cyon сервера
- **Приватный ключ НЕ доступен** - он хранится только на Cyon сервере
- **Для ERNI-KI используйте Cloudflare Origin Certificate** или Let's Encrypt с HTTP-01 challenge
