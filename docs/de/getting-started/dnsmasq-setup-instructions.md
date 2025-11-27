---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Einrichtung des lokalen DNS für das ERNI-KI System

[TOC]

**Datum**: 27.10.2025 **Status**: ABGESCHLOSSEN **Ziel**: Einrichtung eines
lokalen DNS-Servers zur Auflösung von ki.erni-gruppe.ch im Unternehmensnetzwerk

---

## ZUSAMMENFASSUNG

**Problem**: Nach der Änderung der Server-IP von 192.168.62.140 auf
192.168.62.153 war das ERNI-KI System unter der Adresse `ki.erni-gruppe.ch` von
anderen Computern im lokalen Netzwerk nicht mehr erreichbar.

**Lösung**: Installation und Konfiguration von DNSMasq auf dem ERNI-KI Server
zur Auflösung von `ki.erni-gruppe.ch → 192.168.62.153` im lokalen Netzwerk.

**Ergebnis**:

- DNS-Server läuft auf 192.168.62.153:53
- Auflösung von ki.erni-gruppe.ch → 192.168.62.153 funktioniert
- Weiterleitung anderer Domains an Unternehmens-DNS funktioniert
- HTTPS-Zugriff auf das System funktioniert

---

## WAS WURDE GEMACHT

### 1. DNS Stub Listener in systemd-resolved deaktiviert

Erstellung der Konfigurationsdatei `/etc/systemd/resolved.conf.d/dnsmasq.conf`:

```ini
[Resolve]
# DNS Stub Listener deaktivieren (Port 53 freigeben)
DNSStubListener=no

# dnsmasq als lokalen DNS verwenden
DNS=192.168.62.153

# Fallback DNS-Server
FallbackDNS=192.168.62.32 185.242.202.231
```

### 2. DNSMasq auf dem Host installiert

```bash
sudo apt-get update
sudo apt-get install -y dnsmasq
```

### 3. DNSMasq konfiguriert

Konfiguration wurde von `conf/dnsmasq/dnsmasq.conf` nach `/etc/dnsmasq.conf`
kopiert:

**Wichtige Einstellungen**:

- Lauscht nur auf Interface eno1 (192.168.62.153)
- Lokaler Eintrag: `ki.erni-gruppe.ch → 192.168.62.153`
- Upstream DNS: 192.168.62.32, 185.242.202.231, 8.8.8.8
- Cache: 1000 Einträge
- Query-Logging aktiviert

### 4. Funktion überprüft

```bash
# Port 53 wird von dnsmasq abgehört
$ sudo netstat -tulnp | grep :53
tcp 0 0 192.168.62.153:53 0.0.0.0:* LISTEN 729392/dnsmasq

# DNS-Auflösung funktioniert
$ nslookup ki.erni-gruppe.ch 192.168.62.153
Name: ki.erni-gruppe.ch
Address: 192.168.62.153

# HTTPS-Zugriff funktioniert
$ curl -I https://ki.erni-gruppe.ch/
HTTP/2 200
server: nginx/1.28.0
```

---

## NÄCHSTE SCHRITTE - CLIENT-KONFIGURATION

**WICHTIG**: Der DNS-Server läuft jetzt auf 192.168.62.153, aber die Clients im
Netzwerk wissen noch nichts davon. Die Client-Computer oder der DHCP-Server
müssen konfiguriert werden, um den neuen DNS zu verwenden.

### Option A: DHCP auf dem LANCOM-Router konfigurieren (EMPFOHLEN)

**Vorteile**: Automatische Konfiguration aller Clients, zentrale Verwaltung

**Schritte**:

1. In WEBconfig des Routers einloggen: `https://192.168.62.1/`
2. DHCP-Server-Einstellungen finden
3. Primary DNS von `192.168.62.32` auf `192.168.62.153` ändern
4. Änderungen speichern
5. Clients erhalten den neuen DNS automatisch beim nächsten DHCP-Lease
   (normalerweise 24 Stunden)

**Für sofortige Anwendung auf Clients**:

- Linux: `sudo dhclient -r && sudo dhclient`
- Windows: `ipconfig /release && ipconfig /renew`
- macOS: Systemeinstellungen → Netzwerk → DHCP-Lease erneuern

### Option B: Manuelle Konfiguration auf Client-Computern

**Vorteile**: Schnelles Testen, kein Router-Zugriff erforderlich

**Linux (NetworkManager)**:

```bash
# Verbindungsnamen herausfinden
nmcli connection show

# DNS konfigurieren
sudo nmcli connection modify <connection-name> ipv4.dns "192.168.62.153 192.168.62.32"
sudo nmcli connection up <connection-name>

# Überprüfen
nslookup ki.erni-gruppe.ch
```

**Windows**:

1. Systemsteuerung → Netzwerk und Internet → Netzwerkverbindungen
2. Rechtsklick auf Adapter → Eigenschaften
3. IPv4 → Eigenschaften → Folgende DNS-Serveradressen verwenden
4. Bevorzugter DNS: `192.168.62.153`
5. Alternativer DNS: `192.168.62.32`
6. OK → OK

**macOS**:

1. Systemeinstellungen → Netzwerk
2. Aktive Verbindung wählen → Weitere Optionen
3. DNS → `192.168.62.153` hinzufügen
4. Anwenden

### Option C: Unternehmens-DNS-Server konfigurieren (192.168.62.32)

**Vorteile**: Professionelle Lösung, Integration in bestehende Infrastruktur

**Erforderlich**: Zugriff auf Unternehmens-DNS-Server (wahrscheinlich Windows
Server)

**Schritte**:

1. Mit DNS-Server 192.168.62.32 verbinden
2. DNS Manager öffnen
3. Neue Forward-Lookup-Zone für `erni-gruppe.ch` erstellen (falls nicht
   vorhanden)
4. A-Record hinzufügen: `ki.erni-gruppe.ch → 192.168.62.153`
5. DNS-Cache auf Clients aktualisieren: `ipconfig /flushdns` (Windows) oder
   `sudo systemd-resolve --flush-caches` (Linux)

---

## FUNKTIONSPRÜFUNG AUF CLIENTS

Nach der DNS-Konfiguration auf den Clients den Zugriff prüfen:

```bash
# 1. DNS-Auflösung prüfen
nslookup ki.erni-gruppe.ch
# Erwartet: Address: 192.168.62.153

# 2. HTTPS-Zugriff prüfen
curl -I https://ki.erni-gruppe.ch/
# Erwartet: HTTP/2 200

# 3. Im Browser öffnen
# https://ki.erni-gruppe.ch/
# Erwartet: OpenWebUI Oberfläche
```

---

## TECHNISCHE DOKUMENTATION

### DNS-Architektur

```
Client im Netzwerk 192.168.62.0/24
 ↓
 DNS-Anfrage ki.erni-gruppe.ch
 ↓
DNSMasq auf 192.168.62.153:53
 ↓
 Lokaler Eintrag: ki.erni-gruppe.ch → 192.168.62.153
 ↓
Nginx auf 192.168.62.153:443
 ↓
OpenWebUI
```

### DNSMasq Konfiguration

**Datei**: `/etc/dnsmasq.conf`

**Wichtige Parameter**:

```conf
# Interface
interface=eno1
bind-interfaces
except-interface=lo

# Upstream DNS
server=192.168.62.32
server=185.242.202.231
server=8.8.8.8

# Lokaler Eintrag
address=/ki.erni-gruppe.ch/192.168.62.153

# Cache
cache-size=1000
```

### systemd-resolved Konfiguration

**Datei**: `/etc/systemd/resolved.conf.d/dnsmasq.conf`

```ini
[Resolve]
DNSStubListener=no
DNS=192.168.62.153
FallbackDNS=192.168.62.32 185.242.202.231
```

---

## MONITORING UND WARTUNG

### DNSMasq Status prüfen

```bash
# Service-Status
sudo systemctl status dnsmasq

# Logs
sudo journalctl -u dnsmasq -f

# Abfragestatistik
sudo kill -USR1 $(pidof dnsmasq)
sudo journalctl -u dnsmasq | tail -20
```

### Neustart nach Änderungen

```bash
# Konfiguration prüfen
sudo dnsmasq --test

# Service neu starten
sudo systemctl restart dnsmasq

# Funktion prüfen
nslookup ki.erni-gruppe.ch 192.168.62.153
```

### Änderungen rückgängig machen

Falls etwas schief geht:

```bash
# 1. dnsmasq stoppen
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq

# 2. systemd-resolved wiederherstellen
sudo rm /etc/systemd/resolved.conf.d/dnsmasq.conf
sudo systemctl restart systemd-resolved

# 3. Original-Konfiguration von dnsmasq wiederherstellen
sudo cp /etc/dnsmasq.conf.backup /etc/dnsmasq.conf
```

---

## ANHANG: VOLLSTÄNDIGE EINRICHTUNGSPROZEDUR

Zur Referenz, die vollständige Prozedur zur Einrichtung von DNSMasq auf dem
ERNI-KI Server:

### Schritt 1: systemd-resolved DNS Stub Listener deaktivieren

```bash
# Konfigurationsdatei erstellen
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/dnsmasq.conf << 'EOF'
[Resolve]
# DNS Stub Listener deaktivieren (Port 53 freigeben)
DNSStubListener=no

# dnsmasq als lokalen DNS verwenden
DNS=192.168.62.153

# Fallback DNS-Server
FallbackDNS=192.168.62.32 185.242.202.231
EOF

# systemd-resolved neu starten
sudo systemctl restart systemd-resolved

# Status prüfen
sudo systemctl status systemd-resolved
resolvectl status
```

### Schritt 2: /etc/resolv.conf aktualisieren

```bash
# Neue resolv.conf erstellen
sudo rm /etc/resolv.conf
sudo tee /etc/resolv.conf << 'EOF'
# DNS Konfiguration für ERNI-KI mit lokalem DNSMasq
nameserver 192.168.62.153
nameserver 192.168.62.32
nameserver 185.242.202.231
search intern
EOF

# Datei unveränderlich machen (damit systemd sie nicht überschreibt)
sudo chattr +i /etc/resolv.conf
```

### Schritt 3: DNSMasq Container neu starten

```bash
cd /home/konstantin/Documents/augment-projects/erni-ki

# Container neu starten
docker restart erni-ki-dnsmasq

# Status prüfen
docker ps --filter name=dnsmasq

# Logs prüfen
docker logs --tail 20 erni-ki-dnsmasq
```

### Schritt 4: DNS-Funktion prüfen

```bash
# Prüfen ob Port 53 von dnsmasq abgehört wird
sudo netstat -tulnp | grep :53

# Auflösung von ki.erni-gruppe.ch prüfen
nslookup ki.erni-gruppe.ch 192.168.62.153

# Auflösung anderer Domains prüfen
nslookup google.com 192.168.62.153

# Zugriff auf ERNI-KI prüfen
curl -I https://ki.erni-gruppe.ch/
```

---

## ERWARTETE ERGEBNISSE

### Port 53

```bash
$ sudo netstat -tulnp | grep :53
udp 0 0 192.168.62.153:53 0.0.0.0:* <pid>/dnsmasq
tcp 0 0 192.168.62.153:53 0.0.0.0:* <pid>/dnsmasq
```

### DNS-Auflösung

```bash
$ nslookup ki.erni-gruppe.ch 192.168.62.153
Server: 192.168.62.153
Address: 192.168.62.153#53

Name: ki.erni-gruppe.ch
Address: 192.168.62.153
```

### HTTPS-Zugriff

```bash
$ curl -I https://ki.erni-gruppe.ch/
HTTP/2 200
server: nginx/1.28.0
```

---

## RÜCKGÄNGIG MACHEN (falls erforderlich)

```bash
# systemd-resolved Konfiguration entfernen
sudo rm /etc/systemd/resolved.conf.d/dnsmasq.conf
sudo systemctl restart systemd-resolved

# resolv.conf wiederherstellen
sudo chattr -i /etc/resolv.conf
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# dnsmasq stoppen
docker stop erni-ki-dnsmasq
```

---

## NÄCHSTE SCHRITTE

Nach erfolgreicher Einrichtung von DNSMasq auf dem Server:

### Option A: DHCP auf LANCOM-Router konfigurieren (EMPFOHLEN)

1. In WEBconfig des Routers einloggen: <https://192.168.62.1/>
2. Primary DNS von 192.168.62.32 auf 192.168.62.153 ändern
3. Clients erhalten neuen DNS beim nächsten DHCP-Lease

### Option B: Manuelle Konfiguration auf Clients

**Linux**:

```bash
sudo nmcli connection modify <connection-name> ipv4.dns "192.168.62.153"
sudo nmcli connection up <connection-name>
```

**Windows**:

1. Systemsteuerung → Netzwerk und Internet → Netzwerkverbindungen
2. Rechtsklick auf Adapter → Eigenschaften
3. IPv4 → Eigenschaften → Folgende DNS-Serveradressen verwenden
4. Bevorzugter DNS: 192.168.62.153
5. Alternativer DNS: 192.168.62.32

**macOS**:

1. Systemeinstellungen → Netzwerk
2. Aktive Verbindung wählen → Weitere Optionen
3. DNS → 192.168.62.153 hinzufügen

---

**Autor**: Augment Agent **Datum**: 27.10.2025
