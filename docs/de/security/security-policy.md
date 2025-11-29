---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Sicherheitsrichtlinie (ERNI-KI)

## Sicherheitsrichtlinie

### Unterstützte Versionen

| Version | Support |
| ------- | ------- |
| 1.x.x   | Ja      |
| 0.x.x   | Nein    |

### Schwachstellen melden

1.**Kein**öffentliches GitHub-Issue erstellen. 2. Bericht an
<security@erni-ki.local> senden. 3. Bitte folgende Angaben ergänzen:

- Beschreibung der Schwachstelle
- Schritte zur Reproduktion
- Potenzieller Impact
- Vorschlag zur Behebung (optional)

### Reaktionszeiten

-**Eingangsbestätigung**: innerhalb von 24 Stunden -**Erste Bewertung**:
innerhalb von 72 Stunden -**Fix für kritische Bugs**: innerhalb von
7 Tagen -**Fix für nicht-kritische Bugs**: innerhalb von 30 Tagen

### Einstufung

#### Kritisch

- Remote Code Execution
- Authentifizierungs-Bypass
- Abfluss sensibler Daten
- Vollständiger Systemkompromiss

#### Hoch

- Privilegienausweitung
- SQL/NoSQL-Injektionen
- XSS
- CSRF

#### Mittel

- Informationsabfluss
- DoS
- Schwache Sicherheitseinstellungen

#### Niedrig

- Kleine Informationslecks
- Konfigurationsprobleme

### Prozess zur Behebung

1. Analyse und Bestätigung
2. Fix in privatem Branch entwickeln
3. Fix testen
4. Koordiniertes Disclosure mit dem/der Researcher:in
5. Security-Update veröffentlichen
6. Nach 90 Tagen öffentlich dokumentieren

### Empfehlungen

#### Für Administrator:innen

1. Komponenten regelmäßig aktualisieren
2. Starke Passwörter und Secrets verwenden
3. Security-Monitoring aktivieren
4. Netzwerkzugriffe einschränken
5. Regelmäßig Backups erstellen

#### Für Entwickler:innen

1. Secure-Coding-Prinzipien befolgen
2. Code Reviews für alle Changes
3. Statischen Code-Scan nutzen
4. Vor Releases Penetration-/Vuln-Tests durchführen
5. Keine Secrets im Code ablegen

### Sicherheitskonfiguration

#### Pflicht-Parameter

```yaml
# Starke Secret-Keys
WEBUI_SECRET_KEY: 'generierter 256-Bit-Schlüssel' # pragma: allowlist secret
JWT_SECRET: 'generierter 256-Bit-Schlüssel' # pragma: allowlist secret

# Sichere Datenbank-Passwörter
POSTGRES_PASSWORD: 'komplexes Passwort (>=16 Zeichen)' # pragma: allowlist secret
REDIS_PASSWORD: 'komplexes Passwort (>=16 Zeichen)' # pragma: allowlist secret
```

## Empfohlene Nginx-Settings

```nginx
# Server-Version verstecken
server_tokens off;

# Sicherheits-Header
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

# Request-Limits
client_max_body_size 20M;
client_body_timeout 10s;
client_header_timeout 10s;

# Rate Limiting
limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/m;
limit_req zone=auth burst=5 nodelay;
```

## Docker-Sicherheit

```yaml
# Nicht privilegierter User
user: '1001:1001'

# Capabilities minimieren
cap_drop:
  - ALL
cap_add:
  - CHOWN
  - SETGID
  - SETUID

# Read-only-Dateisystem
read_only: true
tmpfs:
  - /tmp
  - /var/tmp

# Ressourcenlimit
deploy:
  resources:
  limits:
  memory: 512M
  cpus: '0.5'
```

## Sicherheitsmonitoring

### Zu überwachende Logs

1. Fehlgeschlagene Anmeldeversuche
2. Verdächtige HTTP-Anfragen
3. Zugriffsfehler auf Dateien
4. Ungewöhnlicher Netzwerktraffic
5. Konfigurationsänderungen

#### Sicherheits-Alerts

```yaml
# Prometheus-Regeln
- alert: SuspiciousAuthActivity
 expr: rate(auth_requests_total{status="401"}[1m]) > 10
 for: 1m
 labels:
 severity: critical
 category: security

- alert: HighErrorRate
 expr: rate(nginx_http_requests_total{status=~"4.."}[5m]) > 50
 for: 2m
 labels:
 severity: warning
 category: security
```

## Kontakte

-**Security Team**: <security@erni-ki.local> -**Notfall**:
+7-XXX-XXX-XXXX -**PGP-Key**: siehe veröffentlichter Public Key

### Dank an Researcher

Wir danken Sicherheitsforscher:innen, die verantwortungsvoll melden:

- (Liste wird fortlaufend ergänzt)

---

**Letzte Aktualisierung**: 2024-12-30 —**Policy-Version**: 1.0
