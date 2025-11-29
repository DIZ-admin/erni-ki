---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Einrichtung des externen Zugriffs für das ERNI-KI System

[TOC]

**Datum**: 27.10.2025**Status**: HANDLUNG ERFORDERLICH**Priorität**: HOCH

---

## ZUSAMMENFASSUNG DES PROBLEMS

**Aktueller Status**:

- Lokaler Zugriff funktioniert: `https://192.168.62.153/` und
  `https://ki.erni-gruppe.ch/` (via /etc/hosts)
- SSL-Zertifikat ist gültig: Let's Encrypt E5, CN=ki.erni-gruppe.ch
- Ports 80/443 sind auf dem Server offen
- Cloudflare Tunnel funktioniert: `https://webui.diz.zone/` ist von außen
  erreichbar
- Domain `ki.erni-gruppe.ch` ist von außen NICHT erreichbar

**Ursache**:

1. DNS-Eintrag `ki.erni-gruppe.ch` existiert NUR in `/etc/hosts` auf dem Server
2. Öffentlicher DNS enthält KEINEN Eintrag für `ki.erni-gruppe.ch`
3. Cloudflare Tunnel ist NICHT für die Domain `ki.erni-gruppe.ch` konfiguriert
4. Port Forwarding ist auf dem LANCOM-Router (192.168.62.1) NICHT eingerichtet

---

## DIAGNOSE

### Netzwerkkonfiguration

| Parameter        | Wert                             |
| ---------------- | -------------------------------- |
| Lokale IP        | 192.168.62.153/24                |
| Externe IP       | 185.242.201.210                  |
| Gateway          | 192.168.62.1 (LANCOM Router)     |
| DNS (lokal)      | 192.168.62.153 ki.erni-gruppe.ch |
| DNS (öffentlich) | KEIN EINTRAG                     |

### Cloudflare Tunnel

**Status**: Läuft (Up 3 hours, healthy)

**Konfigurierte Domains**:

- `webui.diz.zone` → <http://openwebui:8080>
- `search.diz.zone` → <http://searxng:8080>
- `diz.zone` → <http://nginx:8080>
- `lite.diz.zone` → <http://nginx:8080>

**Fehlt**:

- `ki.erni-gruppe.ch` ist NICHT im Cloudflare Tunnel konfiguriert

### LANCOM Router

**Modell**: LANCOM (Unternehmensrouter)**IP**: 192.168.62.1**Web-Interface**:
<https://192.168.62.1/> (WEBconfig)**Zugriff**: Administrator-Zugangsdaten
erforderlich

**Port Forwarding**: NICHT GEPRÜFT (Zugriff auf Router erforderlich)

---

## LÖSUNGEN

### OPTION 1: Cloudflare Tunnel (EMPFOHLEN)

**Vorteile**:

- KEIN Port Forwarding auf dem Router erforderlich
- KEINE Firewall-Änderungen erforderlich
- Integrierter DDoS-Schutz
- Automatisches SSL von Cloudflare
- Funktioniert aus jedem Netzwerk (inkl. Mobilfunk)
- Zentrale Zugriffssteuerung
- Logging und Traffic-Analyse

**Nachteile**:

- Erfordert DNS-Konfiguration in Cloudflare
- Traffic läuft über Cloudflare (könnte für vertrauliche Daten ein Problem sein)

**Maßnahmen**:

#### 1.1 Domain zum Cloudflare Tunnel hinzufügen

**Variante A: Über Cloudflare Dashboard (empfohlen)**

1. In Cloudflare Dashboard einloggen: <https://dash.cloudflare.com/>
2. Account wählen und zu Zero Trust → Access → Tunnels gehen
3. Tunnel ID finden: `02a58963-3f79-4fc0-82ff-f79503366f86`
4. "Configure" → "Public Hostname" → "Add a public hostname" klicken
5. Formular ausfüllen:

-**Subdomain**: `ki` -**Domain**: `erni-gruppe.ch` -**Service Type**:
`HTTP` -**URL**: `nginx:8080`

6. Änderungen speichern

**Variante B: Über Konfigurationsdatei**

Tunnel-Konfiguration im Cloudflare Dashboard aktualisieren, hinzufügen:

```yaml
ingress:
 - hostname: ki.erni-gruppe.ch
 service: http://nginx:8080
 - hostname: webui.diz.zone
 service: http://openwebui:8080
 - hostname: search.diz.zone
 service: http://searxng:8080
 - hostname: diz.zone
 service: http://nginx:8080
 - hostname: lite.diz.zone
 service: http://nginx:8080
 - service: http_status:404
```

#### 1.2 DNS in Cloudflare konfigurieren

1. Zu Cloudflare Dashboard → DNS → Records gehen
2. CNAME-Eintrag hinzufügen:

-**Type**: CNAME -**Name**: `ki` -**Target**:
`02a58963-3f79-4fc0-82ff-f79503366f86.cfargotunnel.com` -**Proxy status**:
Proxied (orange Wolke) -**TTL**: Auto

#### 1.3 Überprüfung

```bash
# 1-2 Minuten warten für DNS-Verbreitung
sleep 120

# DNS prüfen
nslookup ki.erni-gruppe.ch

# Zugriff prüfen
curl -I https://ki.erni-gruppe.ch/

# SSL prüfen
openssl s_client -connect ki.erni-gruppe.ch:443 -servername ki.erni-gruppe.ch
```

**Erwartetes Ergebnis**:

- DNS löst auf Cloudflare IP auf (z.B. 104.21.x.x oder 172.67.x.x)
- HTTP/2 200 OK
- SSL-Zertifikat von Cloudflare

---

## OPTION 2: Port Forwarding auf LANCOM Router

**Vorteile**:

- Direkte Verbindung (ohne Vermittler)
- Geringere Latenz
- Volle Kontrolle über den Traffic

**Nachteile**:

- Erfordert Zugriff auf LANCOM Router
- Erfordert Konfiguration des öffentlichen DNS
- Erfordert Abstimmung mit IT-Abteilung
- Kein DDoS-Schutz
- Komplexer einzurichten

**Maßnahmen**:

### 2.1 Zugriff auf LANCOM Router erhalten

**Erforderlich**:

- Administrator-Zugangsdaten für Router
- Abstimmung mit ERNI IT-Abteilung

**Kontakt IT-Abteilung**: [BEIM BENUTZER ERFRAGEN]

#### 2.2 Port Forwarding konfigurieren

1. In WEBconfig einloggen: <https://192.168.62.1/>
2. Zu Bereich "Firewall" → "Port Forwarding" (oder ähnlich) gehen
3. Regeln hinzufügen:

| Externer Port | Interne IP     | Interner Port | Protokoll | Beschreibung  |
| ------------- | -------------- | ------------- | --------- | ------------- |
| 80            | 192.168.62.153 | 80            | TCP       | ERNI-KI HTTP  |
| 443           | 192.168.62.153 | 443           | TCP       | ERNI-KI HTTPS |

4. Speichern und Änderungen anwenden

#### 2.3 Öffentlichen DNS konfigurieren

**Variante A: Über Registrar der Domain erni-gruppe.ch**

1. In Control Panel des Registrars einloggen
2. A-Record hinzufügen:

-**Name**: `ki` -**Type**: A -**Value**: `185.242.201.210` -**TTL**: 3600

**Variante B: Über Cloudflare (ohne Tunnel)**

1. Domain `erni-gruppe.ch` zu Cloudflare hinzufügen
2. NS-Einträge beim Registrar aktualisieren
3. A-Record in Cloudflare hinzufügen:

-**Name**: `ki` -**Type**: A -**Value**: `185.242.201.210` -**Proxy status**:
DNS only (graue Wolke)

#### 2.4 Überprüfung

```bash
# 5-10 Minuten warten für DNS-Verbreitung
sleep 600

# DNS prüfen
nslookup ki.erni-gruppe.ch

# Zugriff von extern prüfen
curl -I https://ki.erni-gruppe.ch/

# Ports prüfen
nc -zv 185.242.201.210 80
nc -zv 185.242.201.210 443
```

---

## OPTION 3: Hybride Lösung (Cloudflare + Port Forwarding)

**Beschreibung**: Cloudflare als Proxy vor direkter Verbindung nutzen

**Vorteile**:

- DDoS-Schutz von Cloudflare
- SSL von Cloudflare
- Caching statischer Inhalte
- Traffic-Analyse

**Nachteile**:

- Erfordert Konfiguration von Port Forwarding UND Cloudflare
- Komplexere Konfiguration

**Maßnahmen**: Kombination aus Option 1 (Schritt 1.2) + Option 2 (Schritte
2.1-2.2)

---

## EMPFEHLUNG

**Für die ERNI-Unternehmensumgebung wird OPTION 1 (Cloudflare Tunnel)
empfohlen**

**Begründung**:

1. Cloudflare Tunnel ist bereits für andere Domains eingerichtet und
   funktioniert
2. Erfordert KEINE Abstimmung mit IT-Abteilung (keine Änderungen an
   Netzwerkinfrastruktur)
3. Integrierte Sicherheit und DDoS-Schutz
4. Einfache Einrichtung (5-10 Minuten)
5. Zentrale Verwaltung aller ERNI-KI Domains

**Realisierungszeit**: 10-15 Minuten**Erforderliche Rechte**: Zugriff auf
Cloudflare Dashboard

---

## ANWEISUNG FÜR IT-ABTEILUNG

Falls**Option 2 (Port Forwarding)**gewählt wird, stellen Sie der IT-Abteilung
folgende Informationen bereit:

### Erforderliche Einstellungen LANCOM Router (192.168.62.1)

**Port Forwarding Regeln**:

```
External IP: 185.242.201.210
Internal IP: 192.168.62.153

Rule 1:
 Name: ERNI-KI-HTTP
 External Port: 80
 Internal IP: 192.168.62.153
 Internal Port: 80
 Protocol: TCP
 Enabled: Yes

Rule 2:
 Name: ERNI-KI-HTTPS
 External Port: 443
 Internal IP: 192.168.62.153
 Internal Port: 443
 Protocol: TCP
 Enabled: Yes
```

**Firewall Regeln**(falls erforderlich):

- Eingehende Verbindungen auf Ports 80/443 für IP 192.168.62.153 erlauben

**DNS Einstellungen**(falls von IT verwaltet):

- A-Record hinzufügen: `ki.erni-gruppe.ch` → `185.242.201.210`

---

## AKTUELLER STATUS

| Komponente            | Status             | Kommentar                  |
| --------------------- | ------------------ | -------------------------- |
| Lokaler Zugriff       | Funktioniert       | <https://192.168.62.153/>  |
| SSL-Zertifikat        | Gültig             | Let's Encrypt E5           |
| Nginx                 | Funktioniert       | Ports 80/443 offen         |
| Cloudflare Tunnel     | Funktioniert       | webui.diz.zone erreichbar  |
| DNS ki.erni-gruppe.ch | Nicht konfiguriert | Nur /etc/hosts             |
| Port Forwarding       | Unbekannt          | Prüfung erforderlich       |
| Externer Zugriff      | Funktioniert nicht | Konfiguration erforderlich |

---

## NÄCHSTE SCHRITTE

1.**Lösungsvariante wählen**(Option 1 empfohlen) 2.**Zugriff auf Cloudflare
Dashboard erhalten**(für Option 1)

- ODER -

  3.**IT-Abteilung kontaktieren**(für Option 2) 4.**Einstellungen
  anwenden**gemäß gewählter Variante 5.**Zugriff testen**von externem
  Computer 6.**Dokumentation aktualisieren**mit Ergebnissen

---

**Autor**: Augment Agent**Datum**: 27.10.2025**Version**: 1.0
