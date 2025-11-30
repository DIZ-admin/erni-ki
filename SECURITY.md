# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.6.x   | :white_check_mark: |
| < 0.6.0 | :x:                |

## Reporting a Vulnerability

We take the security of **ERNI-KI** seriously. If you believe you have found a
security vulnerability, please report it to us as described below.

### How to Report

**Do not open a public GitHub issue.**

Please create a draft security advisory or email the security team at
`security@erni-ki.local`.

### What to Include

- Description of the vulnerability.
- Steps to reproduce.
- Potential impact.

### Response Timeline

- We will acknowledge your report within 48 hours.
- We will provide a timeline for the fix within 1 week.
- We will release a fix as soon as possible.

## Security Tools

This project uses the following tools to ensure security:

- **Trivy**: Container and filesystem vulnerability scanning.
- **Gosec**: Go security scanner.
- **Gitleaks**: Secret detection.
- **Dependabot**: Dependency updates.
- **CodeQL**: Static analysis (optional).

## Best Practices

- Do not commit secrets to the repository.
- Use `.env` files for local configuration (never commit `.env`).
- Run `pre-commit` hooks before pushing.
- Keep dependencies up to date.
