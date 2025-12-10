---
title: YAML Style Guide
language: ru
page_id: yaml-style-guide
doc_version: '2025.11'
translation_status: original
last_updated: '2025-12-06'
---

# YAML Style Guide

**Version**: 1.0 **Last Updated**: 2025-12-06 **Status**: Active

## Overview

This document defines YAML formatting standards for the ERNI-KI project,
particularly for Docker Compose files, GitHub Actions workflows, and
configuration files.

## Formatting Rules

### 1. Indentation

- **Use 2 spaces** for indentation (no tabs)
- **Indent sequences** (lists) consistently
- **Align nested structures** properly

```yaml
# Good
services:
 nginx:
 image: nginx:alpine
 ports:
 - "80:80"

# Bad - tabs or 4 spaces
services:
 nginx:
 image: nginx:alpine
```

### 2. Quotes

**Rule**: Use **double quotes** for all string values

**Exceptions**: Unquoted values allowed for:

- Boolean values: `true`, `false`, `yes`, `no`
- Null values: `null`, `~`
- Numbers without quotes (except when semantic meaning requires string)

```yaml
# Good
image: "nginx:alpine"
environment:
 - "NODE_ENV=production"
cpus: "2.0" # String to preserve decimal precision
replicas: 3 # Integer without quotes

# Bad
image: 'nginx:alpine' # Single quotes
environment:
 - NODE_ENV=production # Missing quotes
cpus: 2.0 # Number instead of string (loses precision in some parsers)
```

### 3. Docker Compose Specific

#### CPU and Memory Values

**Always quote CPU values** to preserve decimal precision:

```yaml
deploy:
  resources:
  limits:
  cpus: '0.5' # Quoted to preserve 0.5
  memory: '512M' # Quoted for consistency
```

#### User and Group IDs

**Quote UID:GID format** to prevent interpretation as numbers:

```yaml
# Good
user: "1000:1000"
group_add:
 - "125"

# Bad
user: 1000:1000 # May be interpreted as number range
```

#### Ports

**Quote port mappings** with IP addresses:

```yaml
# Good
ports:
 - "127.0.0.1:8080:8080"
 - "3000:3000"

# Acceptable (simple port mapping)
ports:
 - 3000:3000
```

#### Environment Variables

**Quote environment variable definitions**:

```yaml
# Good
environment:
 - "NODE_ENV=production"
 - "PORT=3000"

# Also acceptable (YAML object syntax)
environment:
 NODE_ENV: "production"
 PORT: "3000"
```

### 4. Line Length

- **Maximum 120 characters** (warning level)
- Break long lines at logical points:

```yaml
# Good
command: >
 /bin/sh -c "nginx -g 'daemon off;' &&
 echo 'Server started'"

# Bad
command: "/bin/sh -c \"nginx -g 'daemon off;' && echo 'Server started' && tail -f /var/log/nginx/access.log\""
```

### 5. Comments

- **One space** after `#`
- **Align inline comments** when possible
- **Use comments** to explain non-obvious configurations

```yaml
# Good
services:
 nginx: # Web server
 image: "nginx:alpine"
 # Port mapping for HTTP
 ports:
 - "80:80"

# Bad
services:
 nginx: #Web server (no space)
 image: "nginx:alpine"
 #Port mapping (no space)
```

### 6. Key Ordering

**Recommended order for Docker Compose services**:

1. `image` or `build`
2. `container_name`
3. `restart`
4. `ports`
5. `environment` / `env_file`
6. `volumes`
7. `networks`
8. `depends_on`
9. `healthcheck`
10. `deploy` (resources, replicas)
11. Other configurations

### 7. Multi-line Strings

**Use literal block scalar (`|`) for multi-line commands**:

```yaml
# Good - preserves newlines
healthcheck:
 test: |
 curl -f http://localhost:8080/health ||
 exit 1

# Good - folds newlines into spaces
description: >
 This is a long description that spans multiple lines and will be folded into a
 single line.
```

## Validation

### Local Validation

Install yamllint:

```bash
pip install yamllint
```

Validate files:

```bash
# Validate all YAML files
yamllint .

# Validate specific directory
yamllint compose/

# Validate with custom config
yamllint -c .yamllint compose/
```

### CI Integration

YAML validation runs automatically in CI via pre-commit hooks:

```bash
# Run pre-commit hooks locally
pre-commit run --all-files
```

## Common Mistakes

### Inconsistent Quotes

```yaml
# Bad - mixing quote styles
image: 'nginx:alpine'
command: "nginx -g 'daemon off;'"
```

### Unquoted Numeric Strings

```yaml
# Bad - loses precision
cpus: 0.5 # Interpreted as float, may lose precision
user: 1000:1000 # Interpreted as number range

# Good
cpus: "0.5"
user: "1000:1000"
```

### Inconsistent Indentation

```yaml
# Bad
services:
  nginx:
  image: nginx # 4 spaces
  ports: # 2 spaces
    - '80:80'
```

## Tools and Automation

### Recommended Tools

1. **yamllint**: YAML linter (configured in `.yamllint`)
2. **Prettier**: Code formatter with YAML support
3. **pre-commit**: Git hooks for automatic validation

### Editor Configuration

#### VS Code

Install extensions:

- YAML (Red Hat)
- Prettier - Code formatter

Settings (`.vscode/settings.json`):

```json
{
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  }
}
```

#### Vim

Add to `.vimrc`:

```vim
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
```

## References

- [YAML Specification 1.2](https://yaml.org/spec/1.2/spec.html)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [yamllint Documentation](https://yamllint.readthedocs.io/)
- [Prettier YAML Plugin](https://prettier.io/docs/en/options.html#yaml)

## Version History

| Version | Date       | Changes                            |
| ------- | ---------- | ---------------------------------- |
| 1.0     | 2025-12-06 | Initial style guide with standards |

---

**Maintained by**: DevOps Team **Last Review**: 2025-12-06
