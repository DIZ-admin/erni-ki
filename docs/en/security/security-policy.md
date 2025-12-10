---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Security Policy'
---

# Security Policy for the erni-ki project

## Security policy

### Supported versions

We ship security updates for the following versions:

| Version | Support |
| ------- | ------- |
| 1.x.x   | Yes     |
| 0.x.x   | No      |

### Reporting vulnerabilities

If you discover a vulnerability in erni-ki, please:

1.**Do NOT open a public GitHub issue**2. Send a report to:
<security@erni-ki.local> 3. Include:

- Vulnerability description
- Reproduction steps
- Potential impact
- Proposed fix or mitigation (if any)

### Response time

-**Acknowledgement:**within 24 hours -**Initial assessment:**within 72
hours -**Critical fix:**within 7 days -**Non-critical fix:**within 30 days

### Severity classes

#### Critical

- Remote code execution
- Authentication bypass
- Leakage of secrets or credentials
- Full system compromise

#### High

- Privilege escalation
- SQL/NoSQL injections
- Cross-site scripting (XSS)
- Cross-site request forgery (CSRF)

#### Medium

- Information disclosure
- Denial of service (DoS)
- Weak security settings

#### Low

- Informational disclosures
- Minor configuration issues

### Remediation process

1.**Analyze and confirm**the vulnerability 2.**Develop the fix**in a private
branch 3.**Test**the fix 4.**Coordinate disclosure**with the
reporter 5.**Publish the security update**6.**Public disclosure**after 90 days

### Security recommendations

#### For administrators

1.**Keep all components updated**2.**Use strong passwords**and secret
keys 3.**Enable security monitoring**4.**Restrict network access**to
services 5.**Back up regularly**

#### For developers

1.**Follow secure coding practices**2.**Run code reviews**on every
change 3.**Use static analysis**tools 4.**Security-test before releases**5.**Do
not store secrets**in the codebase

### Security configuration

#### Mandatory settings

```yaml
# Strong secret keys
WEBUI_SECRET_KEY: '<generated-256-bit-key>'
JWT_SECRET: '<generated-256-bit-key>'

# Secure database passwords
POSTGRES_PASSWORD: '<complex-password-16+ chars>'
REDIS_PASSWORD: '<complex-password-16+ chars>'
```

## Recommended Nginx settings

```nginx
# Hide server version
server_tokens off;

# Security headers
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

# Request limits
client_max_body_size 20M;
client_body_timeout 10s;
client_header_timeout 10s;

# Rate limiting
limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/m;
limit_req zone=auth burst=5 nodelay;
```

## Docker hardening

```yaml
# Run as non-root
user: '1001:1001'

# Drop capabilities
cap_drop:
  - ALL
cap_add:
  - CHOWN
  - SETGID
  - SETUID

# Read-only filesystem
read_only: true
tmpfs:
  - /tmp
  - /var/tmp

# Resource limits
deploy:
  resources:
  limits:
  memory: 512M
  cpus: '0.5'
```

## Security monitoring

### Logs to monitor

1.**Failed authentication attempts**2.**Suspicious HTTP requests**3.**File
access errors**4.**Unusual network activity**5.**Configuration changes**

#### Security alerts

```yaml
# Prometheus rules
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

## Contacts

-**Security Team:**<security@erni-ki.local> -**Emergency
Contact:**+7-XXX-XXX-XXXX -**PGP Key:**[Public key link]

### Acknowledgements

We thank security researchers who report vulnerabilities responsibly:

- [Researcher list will be updated]

---
