---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# Local DNS Setup for ERNI-KI System (DNSMasq)

[TOC]

**Date**: 2025-10-27**Status**: COMPLETED**Goal**: Configure local DNS server
for resolving ki.erni-gruppe.ch in corporate network

---

## SUMMARY

**Problem**: After changing server IP from 192.168.62.140 to 192.168.62.153,
ERNI-KI system became inaccessible at `ki.erni-gruppe.ch` from other computers
in local network.

**Solution**: Installed and configured DNSMasq on ERNI-KI server to resolve
`ki.erni-gruppe.ch → 192.168.62.153` in local network.

**Result**:

- DNS server running on 192.168.62.153:53
- Resolving ki.erni-gruppe.ch → 192.168.62.153 works
- Forwarding other domains to corporate DNS works
- HTTPS access to system works

---

## WHAT WAS DONE

### 1. Disabled DNS stub listener in systemd-resolved

Created configuration file `/etc/systemd/resolved.conf.d/dnsmasq.conf`:

```ini
[Resolve]
# Disable DNS stub listener (free up port 53)
DNSStubListener=no

# Use dnsmasq as local DNS
DNS=192.168.62.153

# Fallback DNS servers
FallbackDNS=192.168.62.32 185.242.202.231
```

## 2. Installed DNSMasq on host

```bash
sudo apt-get update
sudo apt-get install -y dnsmasq
```

### 3. Configured DNSMasq

Configuration copied from `conf/dnsmasq/dnsmasq.conf` to `/etc/dnsmasq.conf`:

**Key Settings**:

- Listen only on interface eno1 (192.168.62.153)
- Local record: `ki.erni-gruppe.ch → 192.168.62.153`
- Upstream DNS: 192.168.62.32, 185.242.202.231, 8.8.8.8
- Cache: 1000 records
- Query logging enabled

### 4. Verified Operation

```bash
# Port 53 listened by dnsmasq
$ sudo netstat -tulnp | grep :53
tcp 0 0 192.168.62.153:53 0.0.0.0:* LISTEN 729392/dnsmasq

# DNS resolving works
$ nslookup ki.erni-gruppe.ch 192.168.62.153
Name: ki.erni-gruppe.ch
Address: 192.168.62.153

# HTTPS access works
$ curl -I https://ki.erni-gruppe.ch/
HTTP/2 200
server: nginx/1.28.0
```

---

## NEXT STEPS - CLIENT CONFIGURATION

**IMPORTANT**: DNS server is now running on 192.168.62.153, but network clients
don't know about it yet. Need to configure client computers or DHCP server to
use new DNS.

### Option A: Configure DHCP on LANCOM Router (RECOMMENDED)

**Pros**: Automatic configuration for all clients, centralized management

**Steps**:

1. Log in to Router WEBconfig: `https://192.168.62.1/`
2. Find DHCP server settings
3. Change Primary DNS from `192.168.62.32` to `192.168.62.153`
4. Save changes
5. Clients will automatically receive new DNS on next DHCP lease (usually 24
   hours)

**For immediate application on clients**:

- Linux: `sudo dhclient -r && sudo dhclient`
- Windows: `ipconfig /release && ipconfig /renew`
- macOS: System Preferences → Network → Renew DHCP Lease

### Option B: Manual Configuration on Client Computers

**Pros**: Quick testing, no router access required

**Linux (NetworkManager)**:

```bash
# Get connection name
nmcli connection show

# Configure DNS
sudo nmcli connection modify <connection-name> ipv4.dns "192.168.62.153 192.168.62.32"
sudo nmcli connection up <connection-name>

# Verify
nslookup ki.erni-gruppe.ch
```

**Windows**:

1. Control Panel → Network and Internet → Network Connections
2. Right click adapter → Properties
3. IPv4 → Properties → Use the following DNS server addresses
4. Preferred DNS: `192.168.62.153`
5. Alternate DNS: `192.168.62.32`
6. OK → OK

**macOS**:

1. System Preferences → Network
2. Select active connection → Advanced
3. DNS → Add `192.168.62.153`
4. Apply

## Option C: Configure Corporate DNS Server (192.168.62.32)

**Pros**: Professional solution, integration with existing infrastructure

**Required**: Access to corporate DNS server (likely Windows Server)

**Steps**:

1. Connect to DNS server 192.168.62.32
2. Open DNS Manager
3. Create new Forward Lookup Zone for `erni-gruppe.ch` (if not exists)
4. Add A-record: `ki.erni-gruppe.ch → 192.168.62.153`
5. Flush DNS cache on clients: `ipconfig /flushdns` (Windows) or
   `sudo systemd-resolve --flush-caches` (Linux)

---

## VERIFYING OPERATION ON CLIENTS

After configuring DNS on clients, verify access:

```bash
# 1. Check DNS resolving
nslookup ki.erni-gruppe.ch
# Expected: Address: 192.168.62.153

# 2. Check HTTPS access
curl -I https://ki.erni-gruppe.ch/
# Expected: HTTP/2 200

# 3. Open in browser
# https://ki.erni-gruppe.ch/
# Expected: OpenWebUI interface
```

---

## TECHNICAL DOCUMENTATION

### DNS Architecture

```
Client in network 192.168.62.0/24
 ↓
 DNS query ki.erni-gruppe.ch
 ↓
DNSMasq on 192.168.62.153:53
 ↓
 Local record: ki.erni-gruppe.ch → 192.168.62.153
 ↓
Nginx on 192.168.62.153:443
 ↓
OpenWebUI
```

### DNSMasq Configuration

**File**: `/etc/dnsmasq.conf`

**Key Parameters**:

```conf
# Interface
interface=eno1
bind-interfaces
except-interface=lo

# Upstream DNS
server=192.168.62.32
server=185.242.202.231
server=8.8.8.8

# Local record
address=/ki.erni-gruppe.ch/192.168.62.153

# Cache
cache-size=1000
```

## systemd-resolved Configuration

**File**: `/etc/systemd/resolved.conf.d/dnsmasq.conf`

```ini
[Resolve]
DNSStubListener=no
DNS=192.168.62.153
FallbackDNS=192.168.62.32 185.242.202.231
```

---

## MONITORING AND MAINTENANCE

### Check DNSMasq Status

```bash
# Service status
sudo systemctl status dnsmasq

# Logs
sudo journalctl -u dnsmasq -f

# Query statistics
sudo kill -USR1 $(pidof dnsmasq)
sudo journalctl -u dnsmasq | tail -20
```

## Restart After Changes

```bash
# Check configuration
sudo dnsmasq --test

# Restart service
sudo systemctl restart dnsmasq

# Verify operation
nslookup ki.erni-gruppe.ch 192.168.62.153
```

## Rollback

If something goes wrong:

```bash
# 1. Stop dnsmasq
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq

# 2. Restore systemd-resolved
sudo rm /etc/systemd/resolved.conf.d/dnsmasq.conf
sudo systemctl restart systemd-resolved

# 3. Restore original dnsmasq configuration
sudo cp /etc/dnsmasq.conf.backup /etc/dnsmasq.conf
```

---

## APPENDIX: FULL SETUP PROCEDURE

For reference, full procedure for setting up DNSMasq on ERNI-KI server:

### Step 1: Disable systemd-resolved DNS stub listener

```bash
# Create configuration file
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/dnsmasq.conf << 'EOF'
[Resolve]
# Disable DNS stub listener (free up port 53)
DNSStubListener=no

# Use dnsmasq as local DNS
DNS=192.168.62.153

# Fallback DNS servers
FallbackDNS=192.168.62.32 185.242.202.231
EOF

# Restart systemd-resolved
sudo systemctl restart systemd-resolved

# Check status
sudo systemctl status systemd-resolved
resolvectl status
```

## Step 2: Update /etc/resolv.conf

```bash
# Create new resolv.conf
sudo rm /etc/resolv.conf
sudo tee /etc/resolv.conf << 'EOF'
# DNS configuration for ERNI-KI with local DNSMasq
nameserver 192.168.62.153
nameserver 192.168.62.32
nameserver 185.242.202.231
search intern
EOF

# Make file immutable (so systemd doesn't overwrite)
sudo chattr +i /etc/resolv.conf
```

## Step 3: Restart DNSMasq Container

```bash
cd /home/konstantin/Documents/augment-projects/erni-ki

# Restart container
docker restart erni-ki-dnsmasq

# Check status
docker ps --filter name=dnsmasq

# Check logs
docker logs --tail 20 erni-ki-dnsmasq
```

## Step 4: Verify DNS Operation

```bash
# Check that port 53 is listened by dnsmasq
sudo netstat -tulnp | grep :53

# Verify resolving ki.erni-gruppe.ch
nslookup ki.erni-gruppe.ch 192.168.62.153

# Verify resolving other domains
nslookup google.com 192.168.62.153

# Verify access to ERNI-KI
curl -I https://ki.erni-gruppe.ch/
```

---

## EXPECTED RESULTS

### Port 53

```bash
$ sudo netstat -tulnp | grep :53
udp 0 0 192.168.62.153:53 0.0.0.0:* <pid>/dnsmasq
tcp 0 0 192.168.62.153:53 0.0.0.0:* <pid>/dnsmasq
```

### DNS Resolving

```bash
$ nslookup ki.erni-gruppe.ch 192.168.62.153
Server: 192.168.62.153
Address: 192.168.62.153#53

Name: ki.erni-gruppe.ch
Address: 192.168.62.153
```

### HTTPS Access

```bash
$ curl -I https://ki.erni-gruppe.ch/
HTTP/2 200
server: nginx/1.28.0
```

---

## ROLLBACK (if something goes wrong)

```bash
# Remove systemd-resolved configuration
sudo rm /etc/systemd/resolved.conf.d/dnsmasq.conf
sudo systemctl restart systemd-resolved

# Restore resolv.conf
sudo chattr -i /etc/resolv.conf
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Stop dnsmasq
docker stop erni-ki-dnsmasq
```

---

## NEXT STEPS

After successful DNSMasq setup on server:

### Option A: Configure DHCP on LANCOM Router (RECOMMENDED)

1. Log in to Router WEBconfig: <https://192.168.62.1/`>
2. Change Primary DNS from 192.168.62.32 to 192.168.62.153
3. Clients automatically receive new DNS on next DHCP lease

### Option B: Manual Configuration on Clients

**Linux**:

```bash
sudo nmcli connection modify <connection-name> ipv4.dns "192.168.62.153"
sudo nmcli connection up <connection-name>
```

**Windows**:

1. Control Panel → Network and Internet → Network Connections
2. Right click adapter → Properties
3. IPv4 → Properties → Use the following DNS server addresses
4. Preferred DNS: 192.168.62.153
5. Alternate DNS: 192.168.62.32

**macOS**:

1. System Preferences → Network
2. Select active connection → Advanced
3. DNS → Add 192.168.62.153

---

**Author**: Augment Agent**Date**: 2025-10-27
