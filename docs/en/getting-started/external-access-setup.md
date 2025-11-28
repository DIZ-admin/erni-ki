---
language: en
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# External Access Setup for ERNI-KI System

[TOC]

**Date**: 2025-10-27 **Status**: ACTION REQUIRED **Priority**: HIGH

---

## ISSUE SUMMARY

**Current State**:

- Local access works: `https://192.168.62.153/` and `https://ki.erni-gruppe.ch/`
  (via /etc/hosts)
- SSL certificate valid: Let's Encrypt E5, CN=ki.erni-gruppe.ch
- Ports 80/443 open on server
- Cloudflare Tunnel works: `https://webui.diz.zone/` accessible externally
- Domain `ki.erni-gruppe.ch` NOT accessible externally

**Root Cause**:

1. DNS record `ki.erni-gruppe.ch` exists ONLY in `/etc/hosts` on server
2. Public DNS does NOT contain record for `ki.erni-gruppe.ch`
3. Cloudflare Tunnel NOT configured for domain `ki.erni-gruppe.ch`
4. Port forwarding NOT configured on LANCOM router (192.168.62.1)

---

## DIAGNOSTICS

### Network Configuration

| Parameter    | Value                            |
| ------------ | -------------------------------- |
| Local IP     | 192.168.62.153/24                |
| External IP  | 185.242.201.210                  |
| Gateway      | 192.168.62.1 (LANCOM router)     |
| DNS (local)  | 192.168.62.153 ki.erni-gruppe.ch |
| DNS (public) | NO RECORD                        |

### Cloudflare Tunnel

**Status**: Working (Up 3 hours, healthy)

**Configured Domains**:

- `webui.diz.zone` → <http://openwebui:8080>
- `search.diz.zone` → <http://searxng:8080>
- `diz.zone` → <http://nginx:8080>
- `lite.diz.zone` → <http://nginx:8080>

**Missing**:

- `ki.erni-gruppe.ch` NOT configured in Cloudflare Tunnel

### LANCOM Router

**Model**: LANCOM (corporate router) **IP**: 192.168.62.1 **Web Interface**:
<https://192.168.62.1/> (WEBconfig) **Access**: Admin credentials required

**Port Forwarding**: NOT VERIFIED (router access required)

---

## SOLUTIONS

### OPTION 1: Cloudflare Tunnel (RECOMMENDED)

**Pros**:

- NO port forwarding required on router
- NO firewall changes required
- Built-in DDoS protection
- Automatic SSL from Cloudflare
- Works from any network (including mobile)
- Centralized access management
- Traffic logging and analytics

**Cons**:

- Requires DNS configuration in Cloudflare
- Traffic passes through Cloudflare (may be issue for confidential data)

**Actions**:

#### 1.1 Add Domain to Cloudflare Tunnel

**Variant A: Via Cloudflare Dashboard (Recommended)**

1. Log in to Cloudflare Dashboard: <https://dash.cloudflare.com/>
2. Select account and go to Zero Trust → Access → Tunnels
3. Find tunnel ID: `02a58963-3f79-4fc0-82ff-f79503366f86`
4. Click "Configure" → "Public Hostname" → "Add a public hostname"
5. Fill form:

- **Subdomain**: `ki`
- **Domain**: `erni-gruppe.ch`
- **Service Type**: `HTTP`
- **URL**: `nginx:8080`

6. Save changes

**Variant B: Via Configuration File**

Update tunnel configuration in Cloudflare Dashboard, adding:

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

#### 1.2 Configure DNS in Cloudflare

1. Go to Cloudflare Dashboard → DNS → Records
2. Add CNAME record:

- **Type**: CNAME
- **Name**: `ki`
- **Target**: `02a58963-3f79-4fc0-82ff-f79503366f86.cfargotunnel.com`
- **Proxy status**: Proxied (orange cloud)
- **TTL**: Auto

#### 1.3 Verification

```bash
# Wait 1-2 minutes for DNS propagation
sleep 120

# Check DNS
nslookup ki.erni-gruppe.ch

# Check access
curl -I https://ki.erni-gruppe.ch/

# Check SSL
openssl s_client -connect ki.erni-gruppe.ch:443 -servername ki.erni-gruppe.ch
```

**Expected Result**:

- DNS resolves to Cloudflare IP (e.g., 104.21.x.x or 172.67.x.x)
- HTTP/2 200 OK
- SSL certificate from Cloudflare

---

## OPTION 2: Port Forwarding on LANCOM Router

**Pros**:

- Direct connection (no intermediaries)
- Lower latency
- Full traffic control

**Cons**:

- Requires LANCOM router access
- Requires public DNS configuration
- Requires IT department approval
- No DDoS protection
- More complex setup

**Actions**:

### 2.1 Get Access to LANCOM Router

**Required**:

- Router admin credentials
- ERNI IT department approval

**IT Contact**: [TO BE CONFIRMED BY USER]

#### 2.2 Configure Port Forwarding

1. Log in to WEBconfig: <https://192.168.62.1/>
2. Go to "Firewall" → "Port Forwarding" (or similar)
3. Add rules:

| External Port | Internal IP    | Internal Port | Protocol | Description   |
| ------------- | -------------- | ------------- | -------- | ------------- |
| 80            | 192.168.62.153 | 80            | TCP      | ERNI-KI HTTP  |
| 443           | 192.168.62.153 | 443           | TCP      | ERNI-KI HTTPS |

4. Save and apply changes

#### 2.3 Configure Public DNS

**Variant A: Via erni-gruppe.ch Domain Registrar**

1. Log in to registrar control panel
2. Add A record:

- **Name**: `ki`
- **Type**: A
- **Value**: `185.242.201.210`
- **TTL**: 3600

**Variant B: Via Cloudflare (without Tunnel)**

1. Add `erni-gruppe.ch` domain to Cloudflare
2. Update NS records at registrar
3. Add A record in Cloudflare:

- **Name**: `ki`
- **Type**: A
- **Value**: `185.242.201.210`
- **Proxy status**: DNS only (grey cloud)

#### 2.4 Verification

```bash
# Wait 5-10 minutes for DNS propagation
sleep 600

# Check DNS
nslookup ki.erni-gruppe.ch

# Check external access
curl -I https://ki.erni-gruppe.ch/

# Check ports
nc -zv 185.242.201.210 80
nc -zv 185.242.201.210 443
```

---

## OPTION 3: Hybrid Solution (Cloudflare + Port Forwarding)

**Description**: Use Cloudflare as proxy before direct connection

**Pros**:

- Cloudflare DDoS protection
- Cloudflare SSL
- Static caching
- Traffic analytics

**Cons**:

- Requires both port forwarding and Cloudflare setup
- More complex configuration

**Actions**: Combination of Option 1 (step 1.2) + Option 2 (steps 2.1-2.2)

---

## RECOMMENDATION

**For ERNI corporate environment, OPTION 1 (Cloudflare Tunnel) is RECOMMENDED**

**Justification**:

1. Cloudflare Tunnel already configured and working for other domains
2. NO IT department approval required (no network infrastructure changes)
3. Built-in security and DDoS protection
4. Easy setup (5-10 minutes)
5. Centralized management of all ERNI-KI domains

**Implementation Time**: 10-15 minutes **Required Rights**: Cloudflare Dashboard
Access

---

## INSTRUCTION FOR IT DEPARTMENT

If **Option 2 (Port Forwarding)** is selected, provide IT department with:

### Required LANCOM Router Settings (192.168.62.1)

**Port Forwarding Rules**:

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

**Firewall Rules** (if required):

- Allow incoming connections on ports 80/443 for IP 192.168.62.153

**DNS Settings** (if managed by IT):

- Add A record: `ki.erni-gruppe.ch` → `185.242.201.210`

---

## CURRENT STATUS

| Component             | Status         | Comment                   |
| --------------------- | -------------- | ------------------------- |
| Local Access          | Working        | <https://192.168.62.153/> |
| SSL Certificate       | Valid          | Let's Encrypt E5          |
| Nginx                 | Working        | Ports 80/443 open         |
| Cloudflare Tunnel     | Working        | webui.diz.zone accessible |
| DNS ki.erni-gruppe.ch | Not Configured | Only /etc/hosts           |
| Port Forwarding       | Unknown        | Verification required     |
| External Access       | Not Working    | Configuration required    |

---

## NEXT STEPS

1. **Select solution option** (Option 1 recommended)
2. **Get Cloudflare Dashboard access** (for Option 1)

- OR -

3. **Contact IT department** (for Option 2)
4. **Apply settings** according to selected option
5. **Test access** from external computer
6. **Update documentation** with results

---

**Author**: Augment Agent **Date**: 2025-10-27 **Version**: 1.0
