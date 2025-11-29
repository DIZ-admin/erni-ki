---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Port Forwarding Setup für ERNI-KI

[TOC]

**Datum**: 27.10.2025**Router**: LANCOM (192.168.62.1)**Zweck**: Einrichtung des
externen Zugriffs auf ERNI-KI über direkte Verbindung

---

## ERFORDERLICHE KONFIGURATION

### Netzwerkparameter

| Parameter         | Wert                  |
| ----------------- | --------------------- |
| Externe IP        | 185.242.201.210       |
| Interne Server-IP | 192.168.62.153        |
| Router/Gateway    | 192.168.62.1 (LANCOM) |
| Domain            | ki.erni-gruppe.ch     |

### Port Forwarding Regeln

#### Regel 1: HTTP (Port 80)

```
Name: ERNI-KI-HTTP
Description: ERNI-KI Web Interface HTTP
External Interface: WAN
External IP: 185.242.201.210 (oder Any)
External Port: 80
Protocol: TCP
Internal IP: 192.168.62.153
Internal Port: 80
Enabled: Yes
```

#### Regel 2: HTTPS (Port 443)

```
Name: ERNI-KI-HTTPS
Description: ERNI-KI Web Interface HTTPS
External Interface: WAN
External IP: 185.242.201.210 (oder Any)
External Port: 443
Protocol: TCP
Internal IP: 192.168.62.153
Internal Port: 443
Enabled: Yes
```

---

## ANLEITUNG ZUR KONFIGURATION DES LANCOM ROUTERS

### Schritt 1: Zugriff auf WEBconfig

1. Browser öffnen und Adresse aufrufen: `https://192.168.62.1/`
2. Administrator-Zugangsdaten eingeben
3. SSL-Zertifikat des Routers akzeptieren (falls erforderlich)

### Schritt 2: Navigation zu Port Forwarding

**Mögliche Pfade im Menü**(abhängig von LANCOM-Version):

**Variante A**:

```
Configuration → Firewall/QoS → Port Forwarding
```

**Variante B**:

```
IPv4 → Firewall → Port Forwarding Rules
```

**Variante C**:

```
Advanced Settings → NAT → Port Forwarding
```

### Schritt 3: Regeln hinzufügen

#### Für HTTP (Port 80)

1. "Add" oder "New Rule" klicken
2. Felder ausfüllen: -**Rule Name**: `ERNI-KI-HTTP` -**External Interface**:
   `WAN` oder `Internet` -**Protocol**: `TCP` -**External Port**:
   `80` -**Internal IP Address**: `192.168.62.153` -**Internal Port**:
   `80` -**Enabled**: `Yes` oder `On`
3. "Save" oder "Apply" klicken

#### Für HTTPS (Port 443)

1. "Add" oder "New Rule" klicken
2. Felder ausfüllen: -**Rule Name**: `ERNI-KI-HTTPS` -**External Interface**:
   `WAN` oder `Internet` -**Protocol**: `TCP` -**External Port**:
   `443` -**Internal IP Address**: `192.168.62.153` -**Internal Port**:
   `443` -**Enabled**: `Yes` oder `On`
3. "Save" oder "Apply" klicken

### Schritt 4: Änderungen anwenden

1. "Apply Changes" oder "Save & Activate" klicken
2. 10-30 Sekunden warten, bis Regeln angewendet sind
3. Status der Regeln prüfen (sollten Active/Enabled sein)

### Schritt 5: Firewall prüfen

**Wichtig**: Sicherstellen, dass die Router-Firewall die Ports 80/443 NICHT
blockiert

1. Zu Bereich Firewall Rules gehen
2. Prüfen, dass KEINE Regeln existieren, die blockieren:
   - Eingehende Verbindungen auf Port 80 TCP
   - Eingehende Verbindungen auf Port 443 TCP
3. Falls blockierende Regeln existieren - Ausnahmen für IP 192.168.62.153
   erstellen

---

## KONFIGURATIONSPRÜFUNG

### Test 1: Prüfung vom Server

```bash
# Prüfen, ob Ports auf allen Interfaces lauschen
netstat -tlnp | grep -E ":80 |:443 "

# Erwartetes Ergebnis:
# tcp6  0  0 :::80   :::*  LISTEN  <pid>/docker-proxy
# tcp6  0  0 :::443  :::*  LISTEN  <pid>/docker-proxy
```

### Test 2: Prüfung von anderem Computer im lokalen Netzwerk

```bash
# Von Computer im selben Subnetz (192.168.62.x)
curl -I -k https://192.168.62.153/

# Erwartetes Ergebnis:
# HTTP/2 200
# server: nginx/1.28.0
```

### Test 3: Prüfung des externen Zugriffs

```bash
# Von Computer außerhalb des lokalen Netzwerks oder via Mobilfunk
curl -I https://ki.erni-gruppe.ch/

# Erwartetes Ergebnis:
# HTTP/2 200
# server: nginx/1.28.0
```

### Test 4: Prüfung der Ports von extern

```bash
# Von externem Computer
nc -zv 185.242.201.210 80
nc -zv 185.242.201.210 443

# Erwartetes Ergebnis:
# Connection to 185.242.201.210 80 port [tcp/http] succeeded!
# Connection to 185.242.201.210 443 port [tcp/https] succeeded!
```

---

## FEHLERBEHEBUNG

### Problem 1: Connection Refused

**Symptome**:

```bash
$ nc -zv 185.242.201.210 80
nc: connect to 185.242.201.210 port 80 (tcp) failed: Connection refused
```

**Mögliche Ursachen**:

1. Port Forwarding nicht konfiguriert
2. Firewall blockiert Ports
3. Nginx lauscht nicht auf dem Port

**Lösung**:

1. Port Forwarding Regeln im Router prüfen
2. Firewall-Regeln prüfen
3. Nginx-Status prüfen: `docker ps --filter name=nginx`

### Problem 2: Connection Timeout

**Symptome**:

```bash
$ curl -I https://ki.erni-gruppe.ch/
curl: (28) Connection timed out after 30000 milliseconds
```

**Mögliche Ursachen**:

1. Firewall blockiert Verbindungen
2. ISP blockiert Ports 80/443
3. DNS löst nicht auf

**Lösung**:

1. Firewall auf Router prüfen
2. ISP kontaktieren wegen Blockierungen
3. DNS prüfen: `nslookup ki.erni-gruppe.ch`

### Problem 3: SSL Certificate Error

**Symptome**:

```
SSL certificate problem: unable to get local issuer certificate
```

**Mögliche Ursachen**:

1. SSL-Zertifikat nicht gültig für Domain
2. Zertifikat ist selbstsigniert

**Lösung**:

1. Zertifikat prüfen: `openssl s_client -connect ki.erni-gruppe.ch:443`
2. Let's Encrypt Zertifikat erneuern (falls abgelaufen)
3. `-k` Flag für curl verwenden (nur zum Testen)

---

## DNS EINSTELLUNGEN

Nach der Einrichtung von Port Forwarding muss DNS konfiguriert werden.

### Variante A: Über Domain-Registrar

1. In Control Panel des Registrars `erni-gruppe.ch` einloggen
2. Zu DNS Management gehen
3. A-Record hinzufügen:

   ```
   Type: A
   Name: ki
   Value: 185.242.201.210
   TTL: 3600
   ```

4. Änderungen speichern
5. 5-60 Minuten warten für DNS-Verbreitung

### Variante B: Über Cloudflare (ohne Tunnel)

1. Domain `erni-gruppe.ch` zu Cloudflare hinzufügen
2. NS-Einträge beim Registrar auf Cloudflare NS aktualisieren
3. In Cloudflare Dashboard → DNS → Records:

   ```
   Type: A
   Name: ki
   IPv4 address: 185.242.201.210
   Proxy status: DNS only (graue Wolke)
   TTL: Auto
   ```

4. Speichern

### DNS Prüfung

```bash
# Mit öffentlichem DNS prüfen
nslookup ki.erni-gruppe.ch 8.8.8.8

# Erwartetes Ergebnis:
# Server:  8.8.8.8
# Address: 8.8.8.8#53
#
# Non-authoritative answer:
# Name: ki.erni-gruppe.ch
# Address: 185.242.201.210
```

---

## SICHERHEIT

### Empfehlungen

1.**IP-Zugriff beschränken**(wenn möglich):

- Zugriff nur von ERNI-Büro-IPs erlauben
- Whitelist in Router-Firewall verwenden

  2.**Rate Limiting aktivieren**:

- Anzahl der Verbindungen pro IP begrenzen
- Schutz vor DDoS-Attacken

  3.**Monitoring**:

- Verbindungs-Logging auf Router konfigurieren
- Logs regelmäßig auf verdächtige Aktivitäten prüfen

  4.**Updates**:

- LANCOM Router Firmware regelmäßig aktualisieren
- SSL-Zertifikate aktualisieren

### Alternative: VPN

Für erhöhte Sicherheit VPN statt direktem Zugriff in Betracht ziehen:

- VPN-Server auf LANCOM Router einrichten
- Benutzer verbinden sich via VPN
- Zugriff auf ERNI-KI nur durch VPN-Tunnel

---

## KONTAKTE

**ERNI IT-Abteilung**: [BEIM BENUTZER ERFRAGEN]

**ERNI-KI Verantwortlicher**: [BEIM BENUTZER ERFRAGEN]

**LANCOM Dokumentation**: <https://www.lancom-systems.com/support/>

---

**Autor**: Augment Agent**Datum**: 27.10.2025**Version**: 1.0
