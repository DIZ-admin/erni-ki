---
language: en
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# Port Forwarding Setup for ERNI-KI

[TOC]

**Date**: 2025-10-27 **Router**: LANCOM (192.168.62.1) **Purpose**: Configure
external access to ERNI-KI via direct connection

---

## REQUIRED CONFIGURATION

### Network Parameters

| Parameter          | Value                 |
| ------------------ | --------------------- |
| External IP        | 185.242.201.210       |
| Internal Server IP | 192.168.62.153        |
| Router/Gateway     | 192.168.62.1 (LANCOM) |
| Domain             | ki.erni-gruppe.ch     |

### Port Forwarding Rules

#### Rule 1: HTTP (port 80)

```
Name: ERNI-KI-HTTP
Description: ERNI-KI Web Interface HTTP
External Interface: WAN
External IP: 185.242.201.210 (or Any)
External Port: 80
Protocol: TCP
Internal IP: 192.168.62.153
Internal Port: 80
Enabled: Yes
```

#### Rule 2: HTTPS (port 443)

```
Name: ERNI-KI-HTTPS
Description: ERNI-KI Web Interface HTTPS
External Interface: WAN
External IP: 185.242.201.210 (or Any)
External Port: 443
Protocol: TCP
Internal IP: 192.168.62.153
Internal Port: 443
Enabled: Yes
```

---

## LANCOM ROUTER CONFIGURATION INSTRUCTIONS

### Step 1: Access WEBconfig

1. Open browser and go to: `https://192.168.62.1/`
2. Enter admin credentials
3. Accept router SSL certificate (if required)

### Step 2: Navigate to Port Forwarding

**Possible menu paths** (depends on LANCOM version):

**Variant A**:

```
Configuration → Firewall/QoS → Port Forwarding
```

**Variant B**:

```
IPv4 → Firewall → Port Forwarding Rules
```

**Variant C**:

```
Advanced Settings → NAT → Port Forwarding
```

### Step 3: Add Rules

#### For HTTP (port 80)

1. Click "Add" or "New Rule"
2. Fill fields:

- **Rule Name**: `ERNI-KI-HTTP`
- **External Interface**: `WAN` or `Internet`
- **Protocol**: `TCP`
- **External Port**: `80`
- **Internal IP Address**: `192.168.62.153`
- **Internal Port**: `80`
- **Enabled**: `Yes` or `On`

3. Click "Save" or "Apply"

#### For HTTPS (port 443)

1. Click "Add" or "New Rule"
2. Fill fields:

- **Rule Name**: `ERNI-KI-HTTPS`
- **External Interface**: `WAN` or `Internet`
- **Protocol**: `TCP`
- **External Port**: `443`
- **Internal IP Address**: `192.168.62.153`
- **Internal Port**: `443`
- **Enabled**: `Yes` or `On`

3. Click "Save" or "Apply"

### Step 4: Apply Changes

1. Click "Apply Changes" or "Save & Activate"
2. Wait 10-30 seconds for rules to apply
3. Check rule status (should be Active/Enabled)

### Step 5: Check Firewall

**Important**: Ensure router firewall does NOT block ports 80/443

1. Go to Firewall Rules section
2. Check that NO rules block:

- Incoming connections on port 80 TCP
- Incoming connections on port 443 TCP

3. If blocking rules exist - create exceptions for IP 192.168.62.153

---

## VERIFYING SETTINGS

### Test 1: Check from Server

```bash
# Check that ports are listening on all interfaces
netstat -tlnp | grep -E ":80 |:443 "

# Expected Result:
# tcp6 0 0 :::80 :::* LISTEN <pid>/docker-proxy
# tcp6 0 0 :::443 :::* LISTEN <pid>/docker-proxy
```

## Test 2: Check from Another Computer in Local Network

```bash
# From computer in same subnet (192.168.62.x)
curl -I -k https://192.168.62.153/

# Expected Result:
# HTTP/2 200
# server: nginx/1.28.0
```

## Test 3: Check External Access

```bash
# From computer outside local network or via mobile internet
curl -I https://ki.erni-gruppe.ch/

# Expected Result:
# HTTP/2 200
# server: nginx/1.28.0
```

## Test 4: Check Ports Externally

```bash
# From external computer
nc -zv 185.242.201.210 80
nc -zv 185.242.201.210 443

# Expected Result:
# Connection to 185.242.201.210 80 port [tcp/http] succeeded!
# Connection to 185.242.201.210 443 port [tcp/https] succeeded!
```

---

## TROUBLESHOOTING

### Problem 1: Connection Refused

**Symptoms**:

```bash
$ nc -zv 185.242.201.210 80
nc: connect to 185.242.201.210 port 80 (tcp) failed: Connection refused
```

**Possible Causes**:

1. Port forwarding not configured
2. Firewall blocks ports
3. Nginx not listening on port

**Solution**:

1. Check port forwarding rules in router
2. Check firewall rules
3. Check nginx status: `docker ps --filter name=nginx`

### Problem 2: Connection Timeout

**Symptoms**:

```bash
$ curl -I https://ki.erni-gruppe.ch/
curl: (28) Connection timed out after 30000 milliseconds
```

**Possible Causes**:

1. Firewall blocks connections
2. ISP blocks ports 80/443
3. DNS not resolving

**Solution**:

1. Check firewall on router
2. Contact ISP to check blocks
3. Check DNS: `nslookup ki.erni-gruppe.ch`

### Problem 3: SSL Certificate Error

**Symptoms**:

```
SSL certificate problem: unable to get local issuer certificate
```

**Possible Causes**:

1. SSL certificate not valid for domain
2. Certificate is self-signed

**Solution**:

1. Check certificate: `openssl s_client -connect ki.erni-gruppe.ch:443`
2. Update Let's Encrypt certificate (if expired)
3. Use `-k` flag for curl (testing only)

---

## DNS SETTINGS

After configuring port forwarding, DNS must be configured.

### Option A: Via Domain Registrar

1. Log in to `erni-gruppe.ch` registrar control panel
2. Go to DNS Management section
3. Add A record:

```
Type: A
Name: ki
Value: 185.242.201.210
TTL: 3600
```

4. Save changes
5. Wait 5-60 minutes for DNS propagation

### Option B: Via Cloudflare (without Tunnel)

1. Add `erni-gruppe.ch` domain to Cloudflare
2. Update NS records at registrar to Cloudflare NS
3. In Cloudflare Dashboard → DNS → Records:

```
Type: A
Name: ki
IPv4 address: 185.242.201.210
Proxy status: DNS only (grey cloud)
TTL: Auto
```

4. Save

### DNS Verification

```bash
# Check from public DNS
nslookup ki.erni-gruppe.ch 8.8.8.8

# Expected Result:
# Server: 8.8.8.8
# Address: 8.8.8.8#53
#
# Non-authoritative answer:
# Name: ki.erni-gruppe.ch
# Address: 185.242.201.210
```

---

## SECURITY

### Recommendations

1. **Restrict IP Access** (if possible):

- Allow access only from ERNI office IPs
- Use whitelist in router firewall

2. **Enable Rate Limiting**:

- Limit number of connections from single IP
- DDoS protection

3. **Monitoring**:

- Configure connection logging on router
- Regularly check logs for suspicious activity

4. **Updates**:

- Regularly update LANCOM router firmware
- Update SSL certificates

### Alternative: VPN

For increased security consider using VPN instead of direct access:

- Configure VPN server on LANCOM router
- Users connect via VPN
- Access to ERNI-KI only via VPN tunnel

---

## CONTACTS

**ERNI IT Department**: [TO BE CONFIRMED]

**ERNI-KI Responsible**: [TO BE CONFIRMED]

**LANCOM Documentation**: <https://www.lancom-systems.com/support/>

---

**Author**: Augment Agent **Date**: 2025-10-27 **Version**: 1.0
