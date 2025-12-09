# Docker Secrets for ERNI-KI

This directory contains sensitive data (passwords, API keys) for Docker Compose
secrets.

## Structure

```
secrets/
 postgres_password.txt        # PostgreSQL password
 litellm_db_password.txt      # LiteLLM database password
 litellm_api_key.txt          # LiteLLM API key
 publicai_api_key.txt         # PublicAI key for external LiteLLM models
 context7_api_key.txt         # Context7 API key
 watchtower_api_token.txt     # Watchtower HTTP API access token
 grafana_admin_password.txt   # Grafana admin password
 postgres_exporter_dsn.txt    # DSN for postgres-exporter
 redis_exporter_url.txt       # JSON map host→password for redis-exporter
 openwebui_secret_key.txt     # FastAPI SECRET_KEY for OpenWebUI
 litellm_master_key.txt       # LiteLLM MASTER KEY
 litellm_salt_key.txt         # LiteLLM SALT KEY
 litellm_ui_password.txt      # LiteLLM UI password
 *.example                    # Example files
 README.md                    # This file
```

## Quick Start

### 1. Create secrets from examples

```bash
# Copy examples
cp secrets/postgres_password.txt.example secrets/postgres_password.txt
cp secrets/litellm_db_password.txt.example secrets/litellm_db_password.txt
cp secrets/litellm_api_key.txt.example secrets/litellm_api_key.txt
cp secrets/publicai_api_key.txt.example secrets/publicai_api_key.txt
cp secrets/context7_api_key.txt.example secrets/context7_api_key.txt
cp secrets/watchtower_api_token.txt.example secrets/watchtower_api_token.txt
cp secrets/grafana_admin_password.txt.example secrets/grafana_admin_password.txt
cp secrets/postgres_exporter_dsn.txt.example secrets/postgres_exporter_dsn.txt
cp secrets/redis_exporter_url.txt.example secrets/redis_exporter_url.txt
cp secrets/openwebui_secret_key.txt.example secrets/openwebui_secret_key.txt
cp secrets/litellm_master_key.txt.example secrets/litellm_master_key.txt
cp secrets/litellm_salt_key.txt.example secrets/litellm_salt_key.txt
cp secrets/litellm_ui_password.txt.example secrets/litellm_ui_password.txt

# Set file permissions
chmod 600 secrets/*.txt
```

### 2. Populate secrets

Edit each file and replace placeholder values with real ones:

```bash
# PostgreSQL password
echo "your-strong-password-here" > secrets/postgres_password.txt

# LiteLLM DB password
echo "your-litellm-db-password" > secrets/litellm_db_password.txt

# LiteLLM API key
echo "sk-your-api-key" > secrets/litellm_api_key.txt

# PublicAI API key (used by custom LiteLLM provider)
echo "zpka_your_publicai_key" > secrets/publicai_api_key.txt

# Context7 API key
echo "ctx7sk-your-key" > secrets/context7_api_key.txt

# Watchtower HTTP API token
echo "long-random-token" > secrets/watchtower_api_token.txt

# Grafana admin password
echo "your-very-strong-password" > secrets/grafana_admin_password.txt

# Postgres exporter DSN
echo "postgresql://postgres:your-password@db:5432/openwebui?sslmode=disable" > secrets/postgres_exporter_dsn.txt

# Redis exporter password map (JSON)
echo '{"redis://redis:6379":"your-redis-password"}' > secrets/redis_exporter_url.txt
# If authentication is disabled, leave value empty: {"redis://redis:6379":""}

# OpenWebUI secret key (64 hex chars)
openssl rand -hex 32 > secrets/openwebui_secret_key.txt

# LiteLLM master/salt keys and UI password
openssl rand -base64 48 | tr -d '=+/ ' | cut -c1-48 > secrets/litellm_master_key.txt
openssl rand -hex 32 > secrets/litellm_salt_key.txt
openssl rand -base64 48 | tr -d '=+/ ' | cut -c1-32 > secrets/litellm_ui_password.txt

# Set file permissions
chmod 600 secrets/*.txt
```

## Security

### Important!

- `*.txt` files **MUST NOT** be in git (added to `.gitignore`)
- Permissions should be `600` (only owner can read/write)
- `*.example` files **MUST** be in git (for documentation)
- **NEVER** commit real secrets to git!

### Security Check

```bash
# Check file permissions
ls -l secrets/*.txt

# Should be: -rw------- (600)
# If not, fix:
chmod 600 secrets/*.txt

# Check that secrets are not in git
git status secrets/

# Should show only *.example files
```

## Usage in Docker Compose

Secrets are automatically mounted into containers via `compose.yml`:

```yaml
secrets:
 postgres_password:
 file: ./secrets/postgres_password.txt
 litellm_api_key:
 file: ./secrets/litellm_api_key.txt

services:
 db:
 secrets:
 - postgres_password
 environment:
 POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
```

Inside the container, secrets are available at `/run/secrets/`:

```bash
# Example of reading secret in container
cat /run/secrets/postgres_password
```

## Secret Rotation

When changing passwords/keys:

1. Update files in `secrets/`
2. Restart services:

```bash
docker compose down
docker compose up -d
```

## Generating Secure Passwords

```bash
# Generate random password (32 characters)
openssl rand -base64 32

# Generate password with special characters
openssl rand -base64 32 | tr -d "=+/" | cut -c1-32

# Generate UUID (for API keys)
uuidgen
```

## Troubleshooting

### Problem: Service cannot read secret

```bash
# Check file permissions
ls -l secrets/*.txt

# Check contents (without outputting to console!)
wc -l secrets/*.txt

# Check that file is not empty
[ -s secrets/postgres_password.txt ] && echo "OK" || echo "EMPTY"
```

### Problem: Docker Compose doesn't see secrets

```bash
# Check configuration
docker compose config | grep -A 5 secrets

# Check that files exist
ls -l secrets/*.txt
```

## Additional Information

- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [Best Practices for Secrets Management](https://docs.docker.com/compose/use-secrets/)
- [ERNI-KI Security Guide](../docs/security-guide.md)

---

**Created:** 2025-10-30 **Updated:** 2025-10-30 **Version:** 1.0
