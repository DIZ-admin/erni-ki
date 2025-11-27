---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Einrichtung des lokalen DNS für ERNI-KI im Unternehmensnetzwerk

[TOC]

**Datum**: 27.10.2025 **Ziel**: Zugriff auf `ki.erni-gruppe.ch` für alle
Computer im lokalen Netzwerk 192.168.62.0/24 einrichten **Status**: HANDLUNG
ERFORDERLICH

---

## AKTUELLE SITUATION

### Netzwerkinfrastruktur

| Komponente     | IP-Adresse      | Status    | Rolle                               |
| -------------- | --------------- | --------- | ----------------------------------- |
| ERNI-KI Server | 192.168.62.153  | Läuft     | Web-Server (nginx 80/443)           |
| LANCOM Router  | 192.168.62.1    | Verfügbar | Gateway, DNS Forwarder              |
| DNS Server     | 192.168.62.32   | Läuft     | Primärer DNS (nicht konfigurierbar) |
| Backup DNS     | 185.242.202.231 | Läuft     | Externer DNS                        |

### DNS-Konfiguration

**Aktuelle DNS-Server** (aus DHCP):

```
Primary DNS: 192.168.62.32
Secondary DNS: 185.242.202.231
Search domain: intern
```

**Problem**:

- DNS-Server 192.168.62.32 enthält KEINEN Eintrag für `ki.erni-gruppe.ch`
- SSH-Zugriff auf 192.168.62.32 nicht möglich (Connection refused)
- Typ des DNS-Servers: wahrscheinlich Windows Server DNS (TTL=128)

**Ergebnis**:

```bash
$ nslookup ki.erni-gruppe.ch 192.168.62.32
*** Can't find ki.erni-gruppe.ch: No answer
```

---

## LÖSUNGEN

### OPTION 1: Anfrage an IT-Abteilung (EMPFOHLEN)

**Beschreibung**: IT-Abteilung bitten, einen A-Record auf dem
Unternehmens-DNS-Server 192.168.62.32 hinzuzufügen.

**Vorteile**:

- Zentrale DNS-Verwaltung
- Funktioniert automatisch für das gesamte Unternehmensnetzwerk
- Erfordert keine zusätzlichen Dienste auf ERNI-KI
- Standardansatz für Unternehmensumgebungen

**Nachteile**:

- Erfordert Abstimmung mit IT-Abteilung
- Wartezeit: von einigen Stunden bis zu einigen Tagen

**Maßnahmen**:

#### 1.1 Anfrage für IT-Abteilung vorbereiten

**Betreff**: Hinzufügen eines DNS-Eintrags für das ERNI-KI System

**Anfragetext**:

```
Guten Tag!

Bitte fügen Sie folgenden DNS-Eintrag auf dem Unternehmens-DNS-Server (192.168.62.32) hinzu:

Typ: A
Name: ki.erni-gruppe.ch
IP-Adresse: 192.168.62.153
TTL: 3600 (oder Standard für lokale Zone)

Zweck: Zugriff auf das ERNI-KI (Knowledge Intelligence) System für Mitarbeiter

Zusätzliche Informationen:
- Server: 192.168.62.153 (Ubuntu 24.04, nginx)
- Ports: 80 (HTTP), 443 (HTTPS)
- SSL-Zertifikat: Let's Encrypt (bereits konfiguriert)
- Zugriff: nur innerhalb des Unternehmensnetzwerks 192.168.62.0/24

Kontakt für Rückfragen: [IHRE EMAIL/TELEFON]

Vielen Dank!
```

#### 1.2 Überprüfung nach Hinzufügen des Eintrags

```bash
# DNS-Cache leeren (falls erforderlich)
sudo systemd-resolve --flush-caches

# Auflösung prüfen
nslookup ki.erni-gruppe.ch

# Zugriff prüfen
curl -I https://ki.erni-gruppe.ch/
```

**Erwartetes Ergebnis**:

```
Server: 192.168.62.32
Address: 192.168.62.32#53

Name: ki.erni-gruppe.ch
Address: 192.168.62.153
```

---

### OPTION 2: DNS-Konfiguration auf LANCOM Router

**Beschreibung**: Lokalen DNS-Eintrag auf dem LANCOM Router (192.168.62.1)
hinzufügen.

**Vorteile**:

- Funktioniert automatisch für das gesamte Netzwerk
- Erfordert keine zusätzlichen Dienste
- Schnelle Einrichtung (5-10 Minuten)

**Nachteile**:

- Erfordert Zugriff auf LANCOM Router
- Könnte Abstimmung mit IT-Abteilung erfordern

**Maßnahmen**:

#### 2.1 Zugriff auf Router-WEBconfig

1. Browser öffnen: `https://192.168.62.1/`
2. Administrator-Zugangsdaten eingeben
3. SSL-Zertifikat des Routers akzeptieren

#### 2.2 Lokalen DNS-Eintrag hinzufügen

**Mögliche Pfade im LANCOM-Menü**:

**Variante A**:

```
Configuration → IPv4 → DNS → Static Host Table
```

**Variante B**:

```
Setup → TCP-IP → DNS → Static Hosts
```

**Variante C**:

```
Advanced Settings → DNS → Local DNS Records
```

#### 2.3 Eintrag hinzufügen

```
Hostname: ki.erni-gruppe.ch
IP Address: 192.168.62.153
Enabled: Yes
```

#### 2.4 Änderungen anwenden

1. "Apply" oder "Save & Activate" klicken
2. 10-30 Sekunden warten
3. Zugriff prüfen

---

### OPTION 3: Lokaler DNS-Server auf ERNI-KI (SCHNELLE LÖSUNG)

**Beschreibung**: dnsmasq auf dem ERNI-KI Server für lokales DNS einrichten.

**Vorteile**:

- Kann SOFORT eingerichtet werden (kein Zugriff auf andere Systeme erforderlich)
- Volle Kontrolle über DNS
- Schnelle Einrichtung (10-15 Minuten)

**Nachteile**:

- Erfordert Änderung der DNS-Einstellungen auf Client-Computern
- Oder Änderung der DHCP-Einstellungen auf dem Router
- Zusätzlicher Dienst auf ERNI-KI

**Maßnahmen**:

#### 3.1 Installation und Konfiguration von dnsmasq

Erstelle Docker-Container mit dnsmasq für lokales DNS.

**Datei**: `conf/dnsmasq/dnsmasq.conf`

```conf
# Nur auf lokalem Interface lauschen
interface=eno1
bind-interfaces

# /etc/resolv.conf nicht lesen
no-resolv

# Upstream DNS Server
server=192.168.62.32
server=185.242.202.231

# Lokale Zone
domain=intern
local=/intern/

# Lokale Einträge
address=/ki.erni-gruppe.ch/192.168.62.153

# Caching
cache-size=1000

# Logging
log-queries
log-facility=/var/log/dnsmasq.log
```

### 3.2 Docker Compose Konfiguration

Zu `compose.yml` hinzufügen:

```yaml
dnsmasq:
  image: jpillora/dnsmasq:1.3.1
  container_name: erni-ki-dnsmasq
  restart: unless-stopped
  ports:
    - '53:53/udp'
    - '53:53/tcp'
  volumes:
    - ./conf/dnsmasq/dnsmasq.conf:/etc/dnsmasq.conf:ro
    - ./logs/dnsmasq:/var/log:rw
  networks:
    - erni-ki-network
  cap_add:
    - NET_ADMIN
  logging:
  driver: 'json-file'
  options:
  max-size: '10m'
  max-file: '3'
```

### 3.3 Starten

```bash
# Verzeichnisse erstellen
mkdir -p conf/dnsmasq logs/dnsmasq

# Konfiguration erstellen (siehe oben)

# Container starten
docker compose up -d dnsmasq

# Status prüfen
docker ps --filter name=dnsmasq

# Logs prüfen
docker logs erni-ki-dnsmasq
```

### 3.4 Client-Konfiguration

**Variante A: DHCP auf Router ändern** (empfohlen)

1. In LANCOM WEBconfig einloggen
2. Primary DNS von 192.168.62.32 auf 192.168.62.153 ändern
3. Clients erhalten neuen DNS beim nächsten DHCP-Lease

**Variante B: Manuelle Konfiguration auf Clients**

```bash
# Linux
sudo nmcli connection modify <connection-name> ipv4.dns "192.168.62.153"
sudo nmcli connection up <connection-name>

# Windows
# Systemsteuerung → Netzwerk → Adaptereigenschaften → IPv4 → DNS: 192.168.62.153

# macOS
# Systemeinstellungen → Netzwerk → Weitere Optionen → DNS → 192.168.62.153
```

---

### OPTION 4: Temporäre Lösung via /etc/hosts

**Beschreibung**: /etc/hosts auf jedem Computer manuell aktualisieren.

**Vorteile**:

- Funktioniert sofort
- Erfordert keinen Serverzugriff

**Nachteile**:

- Nicht skalierbar (jeder Computer muss aktualisiert werden)
- Erfordert Admin-Rechte auf jedem Computer
- Schwer zu warten

**Maßnahmen**:

Auf jedem Computer zu `/etc/hosts` (Linux/macOS) oder
`C:\Windows\System32\drivers\etc\hosts` (Windows) hinzufügen:

```
192.168.62.153 ki.erni-gruppe.ch
```

**Nur zum Testen oder für sehr wenige Computer!**

---

## EMPFEHLUNG

**Für die ERNI-Unternehmensumgebung wird OPTION 1 (Anfrage an IT-Abteilung)
empfohlen**

**Begründung**:

1. Standardansatz für Unternehmensnetzwerke
2. Zentrale DNS-Verwaltung
3. Erfordert keine zusätzlichen Dienste
4. Funktioniert automatisch für alle Computer
5. Entspricht Sicherheitsrichtlinien

**Wenn eine DRINGENDE Lösung erforderlich ist** (während wir auf IT warten):

- **OPTION 3** (lokaler DNS auf ERNI-KI) verwenden
- Nach Erhalt des Zugriffs von IT-Abteilung auf OPTION 1 wechseln

---

## LÖSUNGSPRÜFUNG

### Test 1: DNS-Auflösung

```bash
# Cache leeren
sudo systemd-resolve --flush-caches

# Auflösung prüfen
nslookup ki.erni-gruppe.ch

# Erwartetes Ergebnis:
# Name: ki.erni-gruppe.ch
# Address: 192.168.62.153
```

### Test 2: HTTP-Zugriff

```bash
curl -I http://ki.erni-gruppe.ch/

# Erwartetes Ergebnis:
# HTTP/1.1 301 Moved Permanently
# Location: https://ki.erni-gruppe.ch/
```

### Test 3: HTTPS-Zugriff

```bash
curl -I https://ki.erni-gruppe.ch/

# Erwartetes Ergebnis:
# HTTP/2 200
# server: nginx/1.28.0
```

### Test 4: SSL-Zertifikat

```bash
openssl s_client -connect ki.erni-gruppe.ch:443 -servername ki.erni-gruppe.ch 2>&1 | grep -E "subject=|issuer=|Verify"

# Erwartetes Ergebnis:
# subject=CN = ki.erni-gruppe.ch
# issuer=C = US, O = Let's Encrypt, CN = E5
# Verify return code: 0 (ok)
```

### Test 5: Web-Interface

Im Browser öffnen: `https://ki.erni-gruppe.ch/`

**Erwartetes Ergebnis**:

- Seite lädt
- SSL-Zertifikat gültig (grünes Schloss)
- OpenWebUI Oberfläche verfügbar

---

## ERFOLGSKRITERIEN

Nach Anwendung der Lösung:

- DNS-Eintrag `ki.erni-gruppe.ch` löst auf 192.168.62.153 auf
- Zugriff funktioniert von jedem Computer im Netzwerk 192.168.62.0/24
- HTTPS funktioniert mit gültigem SSL-Zertifikat
- OpenWebUI Oberfläche lädt korrekt
- Lösung ist dokumentiert

---

## KONTAKTE

**ERNI IT-Abteilung**: [BEIM BENUTZER ERFRAGEN]

**DNS-Verantwortlicher**: [BEIM BENUTZER ERFRAGEN]

**ERNI-KI Verantwortlicher**: [BEIM BENUTZER ERFRAGEN]

---

**Autor**: Augment Agent **Datum**: 27.10.2025 **Version**: 1.0
