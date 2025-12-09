# ERNI-KI SSL Setup - Quick Start

## Quick Let's Encrypt Installation

### 1. Get Cloudflare API Token

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. **My Profile** → **API Tokens** → **Create Token**
3. **Custom token** with permissions:

- `Zone:Zone:Read`
- `Zone:DNS:Edit`
- Zone: `erni-gruppe.ch`

### 2. Install Certificate

```bash
# Set API token
export CF_Token="your_cloudflare_api_token_here"

# Run installation
./scripts/ssl/setup-letsencrypt.sh
```

### 3. Verify Result

```bash
# Test configuration
./scripts/ssl/test-nginx-config.sh

# Check certificate
curl -I https://ki.erni-gruppe.ch/
```

## Available Scripts

| Script                    | Description                          |
| ------------------------- | ------------------------------------ |
| `setup-letsencrypt.sh`    | Automatic Let's Encrypt installation |
| `monitor-certificates.sh` | Monitor and renew certificates       |
| `test-nginx-config.sh`    | Test SSL configuration               |
| `setup-ssl-monitoring.sh` | Set up auto-monitoring               |
| `check-ssl-now.sh`        | Quick certificate check              |

## Monitoring Commands

```bash
# Check certificate
./scripts/ssl/monitor-certificates.sh check

# Force renewal
./scripts/ssl/monitor-certificates.sh renew

# Generate report
./scripts/ssl/monitor-certificates.sh report

# Test HTTPS availability
./scripts/ssl/monitor-certificates.sh test
```

## Auto-Monitoring Status

```bash
# Check systemd timer status
systemctl --user status erni-ki-ssl-monitor.timer

# View logs
journalctl --user -u erni-ki-ssl-monitor.service

# Manual check
./scripts/ssl/check-ssl-now.sh
```

## Troubleshooting

### Problem: Cloudflare API Error

```bash
# Verify token
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
 -H "Authorization: Bearer $CF_Token"
```

### Problem: Nginx Error

```bash
# Check configuration
docker compose exec nginx nginx -t

# Restart nginx
docker compose restart nginx
```

### Problem: DNS Propagation

```bash
# Check DNS records
dig TXT _acme-challenge.ki.erni-gruppe.ch

# Wait 2-5 minutes and retry
```

## Documentation

- **Full guide**:
  [docs/ssl-letsencrypt-setup.md](../docs/ssl-letsencrypt-setup.md)
- **Final report**: [docs/ssl-setup-complete.md](../docs/ssl-setup-complete.md)
- **Configuration**: [conf/ssl/monitoring.conf](../conf/ssl/monitoring.conf)

## Emergency Recovery

```bash
# Rollback to previous certificates
BACKUP_DIR=".config-backup/ssl-setup-20250811-134107"
cp "$BACKUP_DIR/nginx.crt" conf/nginx/ssl/
cp "$BACKUP_DIR/nginx.key" conf/nginx/ssl/
docker compose restart nginx
```

## Expected Results

After successful installation:

- Valid SSL certificate from Let's Encrypt
- A+ rating on SSL Labs
- Automatic renewal every 60 days
- HTTP/2 and TLS 1.3 support
- All 25+ ERNI-KI services working via HTTPS
