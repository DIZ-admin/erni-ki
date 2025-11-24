---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Security Documentation

This directory contains security-related documentation, policies, and procedures
for the ERNI-KI platform.

## Contents

### Security Guides

- **[authentication.md](authentication.md)** - Authentication and authorization
  - JWT token management
  - User authentication flow
  - API key management
  - Rate limiting

- **[ssl-tls-setup.md](ssl-tls-setup.md)** - SSL/TLS configuration
  - Certificate management
  - Cloudflare integration
  - Zero Trust setup

### Security Policies

- **[security-best-practices.md](security-best-practices.md)** - Security
  guidelines
  - Secure configuration
  - Network security
  - Data protection
  - Access control

## Quick Reference

**For Administrators:**

- Set up authentication: [authentication.md](authentication.md)
- Configure SSL: [ssl-tls-setup.md](ssl-tls-setup.md)

**For Developers:**

- Review best practices:
  [security-best-practices.md](security-best-practices.md)

## Security Architecture

ERNI-KI implements multiple security layers:

- **JWT Authentication** - Secure user sessions
- **SSL/TLS** - Encrypted communications
- **Cloudflare Zero Trust** - DDoS protection and secure tunnels
- **Rate Limiting** - Abuse prevention
- **Local Data Storage** - Data sovereignty

## Reporting Security Issues

**DO NOT** create public GitHub issues for security vulnerabilities. Contact:
<security@erni-gruppe.ch>

## Related Documentation

- [Architecture](../architecture/README.md)
- [Operations](../operations/README.md)
- [Getting Started](../getting-started/README.md)

## Version

Documentation version: **12.1** Last updated: **2025-11-22**
