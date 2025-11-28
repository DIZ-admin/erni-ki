---
language: en
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# Local Network DNS Setup for ERNI-KI

[TOC]

**Date**: 2025-10-27 **Goal**: Configure access to `ki.erni-gruppe.ch` for all
computers in local network 192.168.62.0/24 **Status**: ACTION REQUIRED

---

## CURRENT SITUATION

### Network Infrastructure

| Component      | IP Address      | Status    | Role                                    |
| -------------- | --------------- | --------- | --------------------------------------- |
| ERNI-KI Server | 192.168.62.153  | Working   | Web server (nginx 80/443)               |
| LANCOM Router  | 192.168.62.1    | Available | Gateway, DNS forwarder                  |
| DNS Server     | 192.168.62.32   | Working   | Primary DNS (not accessible for config) |
| Backup DNS     | 185.242.202.231 | Working   | External DNS                            |

### DNS Configuration

**Current DNS Servers** (from DHCP):

```
Primary DNS: 192.168.62.32
Secondary DNS: 185.242.202.231
Search domain: intern
```

**Problem**:

- DNS server 192.168.62.32 does NOT contain record for `ki.erni-gruppe.ch`
- SSH access to 192.168.62.32 unavailable (Connection refused)
- DNS Server Type: likely Windows Server DNS (TTL=128)

**Result**:

```bash
$ nslookup ki.erni-gruppe.ch 192.168.62.32
*** Can't find ki.erni-gruppe.ch: No answer
```

---

## SOLUTIONS

### OPTION 1: Request to IT Department (RECOMMENDED)

**Description**: Request IT department to add A record to corporate DNS server
192.168.62.32

**Pros**:

- Centralized DNS management
- Works for entire corporate network automatically
- No additional services required on ERNI-KI
- Standard approach for corporate environment

**Cons**:

- Requires IT department approval
- Waiting time: from hours to days

**Actions**:

#### 1.1 Prepare Request for IT Department

**Subject**: DNS Record Addition for ERNI-KI System

**Request Text**:

```
Hello!

Please add the following DNS record to the corporate DNS server (192.168.62.32):

Record Type: A
Name: ki.erni-gruppe.ch
IP Address: 192.168.62.153
TTL: 3600 (or standard for local zone)

Purpose: Access to ERNI-KI (Knowledge Intelligence) system for company employees

Additional Info:
- Server: 192.168.62.153 (Ubuntu 24.04, nginx)
- Ports: 80 (HTTP), 443 (HTTPS)
- SSL Certificate: Let's Encrypt (already configured)
- Access: only within corporate network 192.168.62.0/24

Contact: [YOUR EMAIL/PHONE]

Thank you!
```

#### 1.2 Verification After Record Addition

```bash
# Flush DNS cache (if required)
sudo systemd-resolve --flush-caches

# Check resolving
nslookup ki.erni-gruppe.ch

# Check access
curl -I https://ki.erni-gruppe.ch/
```

**Expected Result**:

```
Server: 192.168.62.32
Address: 192.168.62.32#53

Name: ki.erni-gruppe.ch
Address: 192.168.62.153
```

---

## OPTION 2: DNS Configuration on LANCOM Router

**Description**: Add local DNS record on LANCOM router (192.168.62.1)

**Pros**:

- Works for entire network automatically
- No additional services required
- Fast setup (5-10 minutes)

**Cons**:

- Requires LANCOM router access
- May require IT department approval

**Actions**:

### 2.1 Access Router WEBconfig

1. Open browser: `https://192.168.62.1/`
2. Enter admin credentials
3. Accept router SSL certificate

#### 2.2 Add Local DNS Record

**Possible Paths in LANCOM Menu**:

**Variant A**:

```
Configuration → IPv4 → DNS → Static Host Table
```

**Variant B**:

```
Setup → TCP-IP → DNS → Static Hosts
```

**Variant C**:

```
Advanced Settings → DNS → Local DNS Records
```

#### 2.3 Add Record

```
Hostname: ki.erni-gruppe.ch
IP Address: 192.168.62.153
Enabled: Yes
```

#### 2.4 Apply Changes

1. Click "Apply" or "Save & Activate"
2. Wait 10-30 seconds
3. Check access

---

### OPTION 3: Local DNS Server on ERNI-KI (QUICK SOLUTION)

**Description**: Run dnsmasq on ERNI-KI server for local DNS

**Pros**:

- Can be configured NOW (no access to other systems required)
- Full DNS control
- Fast setup (10-15 minutes)

**Cons**:

- Requires changing DNS settings on client computers
- Or changing DHCP settings on router
- Additional service on ERNI-KI

**Actions**:

#### 3.1 Install and Configure dnsmasq

Create Docker container with dnsmasq for local DNS.

**File**: `conf/dnsmasq/dnsmasq.conf`

```conf
# Listen only on local interface
interface=eno1
bind-interfaces

# Do not read /etc/resolv.conf
no-resolv

# Upstream DNS servers
server=192.168.62.32
server=185.242.202.231

# Local zone
domain=intern
local=/intern/

# Local records
address=/ki.erni-gruppe.ch/192.168.62.153

# Caching
cache-size=1000

# Logging
log-queries
log-facility=/var/log/dnsmasq.log
```

## 3.2 Docker Compose Configuration

Add to `compose.yml`:

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

### 3.3 Start

```bash
# Create directories
mkdir -p conf/dnsmasq logs/dnsmasq

# Create configuration (see above)

# Start container
docker compose up -d dnsmasq

# Check status
docker ps --filter name=dnsmasq

# Check logs
docker logs erni-ki-dnsmasq
```

## 3.4 Client Configuration

**Variant A: Change DHCP on Router** (Recommended)

1. Log in to LANCOM WEBconfig
2. Change Primary DNS from 192.168.62.32 to 192.168.62.153
3. Clients will get new DNS on next DHCP lease

**Variant B: Manual Configuration on Clients**

```bash
# Linux
sudo nmcli connection modify <connection-name> ipv4.dns "192.168.62.153"
sudo nmcli connection up <connection-name>

# Windows
# Control Panel → Network → Adapter Properties → IPv4 → DNS: 192.168.62.153

# macOS
# System Preferences → Network → Advanced → DNS → 192.168.62.153
```

---

## OPTION 4: Temporary Solution via /etc/hosts

**Description**: Update /etc/hosts on each computer manually

**Pros**:

- Works immediately
- No server access required

**Cons**:

- Not scalable (need to update every computer)
- Requires admin rights on every computer
- Hard to maintain

**Actions**:

On each computer add to `/etc/hosts` (Linux/macOS) or
`C:\Windows\System32\drivers\etc\hosts` (Windows):

```
192.168.62.153 ki.erni-gruppe.ch
```

**Only for testing or very small number of computers!**

---

## RECOMMENDATION

**For ERNI corporate environment, OPTION 1 (Request to IT Department) is
RECOMMENDED**

**Justification**:

1. Standard approach for corporate network
2. Centralized DNS management
3. No additional services required
4. Works automatically for all computers
5. Compliant with security policies

**If URGENT solution required** (while waiting for IT):

- Use **OPTION 3** (local DNS on ERNI-KI)
- After getting access from IT - switch to OPTION 1

---

## SOLUTION VERIFICATION

### Test 1: DNS Resolving

```bash
# Flush cache
sudo systemd-resolve --flush-caches

# Check resolving
nslookup ki.erni-gruppe.ch

# Expected Result:
# Name: ki.erni-gruppe.ch
# Address: 192.168.62.153
```

## Test 2: HTTP Access

```bash
curl -I http://ki.erni-gruppe.ch/

# Expected Result:
# HTTP/1.1 301 Moved Permanently
# Location: https://ki.erni-gruppe.ch/
```

## Test 3: HTTPS Access

```bash
curl -I https://ki.erni-gruppe.ch/

# Expected Result:
# HTTP/2 200
# server: nginx/1.28.0
```

## Test 4: SSL Certificate

```bash
openssl s_client -connect ki.erni-gruppe.ch:443 -servername ki.erni-gruppe.ch 2>&1 | grep -E "subject=|issuer=|Verify"

# Expected Result:
# subject=CN = ki.erni-gruppe.ch
# issuer=C = US, O = Let's Encrypt, CN = E5
# Verify return code: 0 (ok)
```

## Test 5: Web Interface

Open in browser: `https://ki.erni-gruppe.ch/`

**Expected Result**:

- Page loads
- SSL certificate valid (green lock)
- OpenWebUI interface accessible

---

## SUCCESS CRITERIA

After applying solution:

- DNS record `ki.erni-gruppe.ch` resolves to 192.168.62.153
- Access works from any computer in network 192.168.62.0/24
- HTTPS works with valid SSL certificate
- OpenWebUI interface loads correctly
- Solution documented

---

## CONTACTS

**ERNI IT Department**: [TO BE CONFIRMED]

**DNS Responsible**: [TO BE CONFIRMED]

**ERNI-KI Responsible**: [TO BE CONFIRMED]

---

**Author**: Augment Agent **Date**: 2025-10-27 **Version**: 1.0
