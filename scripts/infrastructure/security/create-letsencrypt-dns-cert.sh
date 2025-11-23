#!/bin/bash

# ============================================================================
# Script creation Let's Encrypt certificates via DNS-01 challenge
# ============================================================================
# Description: Obtaining SSL certificates via Cloudflare DNS API
# Author: Augment Agent
# Date: 11.11.2025
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SSL_DIR="$PROJECT_ROOT/conf/nginx/ssl"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/ssl-$(date +%Y%m%d-%H%M%S)"
ACME_HOME="$HOME/.acme.sh"

# Domains
DOMAIN="ki.erni-gruppe.ch"
DOMAIN_WWW="www.ki.erni-gruppe.ch"
EMAIL="diginnz1@gmail.com"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Creating Let's Encrypt certificates via Cloudflare DNS${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Check/installation acme.sh
if [[ ! -f "$ACME_HOME/acme.sh" ]]; then
    echo -e "${YELLOW}⚠️  acme.sh not installed. Installing...${NC}"
    curl https://get.acme.sh | sh -s email=$EMAIL
    echo -e "${GREEN}✅ acme.sh installed${NC}"
    # Reload environment variables
    source "$HOME/.acme.sh/acme.sh.env"
else
    echo -e "${GREEN}✅ acme.sh already installed${NC}"
fi
echo ""

# Request Cloudflare API Token
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Setup Cloudflare API${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}To obtain certificate via DNS-01 challenge needed Cloudflare API Token${NC}"
echo ""
echo -e "${YELLOW}How to obtain API Token:${NC}"
echo -e "1. Open: ${GREEN}https://dash.cloudflare.com/profile/api-tokens${NC}"
echo -e "2. Press: ${GREEN}Create Token${NC}"
echo -e "3. Select template: ${GREEN}Edit zone DNS${NC}"
echo -e "4. Configure permissions:"
echo -e "   - Zone: ${GREEN}DNS${NC} - ${GREEN}Edit${NC}"
echo -e "   - Zone Resources: ${GREEN}Include${NC} - ${GREEN}Specific zone${NC} - ${GREEN}erni-gruppe.ch${NC}"
echo -e "5. Press: ${GREEN}Continue to summary${NC} → ${GREEN}Create Token${NC}"
echo -e "6. Copy token"
echo ""
echo -e "${GREEN}Paste Cloudflare API Token:${NC}"
read -s CF_Token
echo ""

if [[ -z "$CF_Token" ]]; then
    echo -e "${RED}❌ Error: API Token cannot be empty${NC}"
    exit 1
fi

# Export variables for acme.sh
export CF_Token="$CF_Token"
export CF_Account_ID=""  # Not required for DNS-01

# Creating backup
echo -e "${YELLOW}📦 Creating backup of current certificates...${NC}"
mkdir -p "$BACKUP_DIR"

if [[ -f "$SSL_DIR/nginx.crt" ]]; then
    cp "$SSL_DIR/nginx.crt" "$BACKUP_DIR/nginx.crt.backup"
    echo -e "${GREEN}✅ Saved: nginx.crt${NC}"
fi

if [[ -f "$SSL_DIR/nginx.key" ]]; then
    cp "$SSL_DIR/nginx.key" "$BACKUP_DIR/nginx.key.backup"
    echo -e "${GREEN}✅ Saved: nginx.key${NC}"
fi
echo ""

# Obtaining certificate
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Obtaining Let's Encrypt certificate${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

echo -e "${YELLOW}Domains:${NC} $DOMAIN, $DOMAIN_WWW"
echo -e "${YELLOW}Email:${NC} $EMAIL"
echo -e "${YELLOW}DNS Provider:${NC} Cloudflare"
echo ""

echo -e "${YELLOW}🔐 Starting acme.sh...${NC}"
"$ACME_HOME/acme.sh" --issue \
  --dns dns_cf \
  -d "$DOMAIN" \
  -d "$DOMAIN_WWW" \
  --keylength 2048 \
  --server letsencrypt

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Certificate successfully obtained!${NC}"
else
    echo -e "${RED}❌ Error when obtaining certificate${NC}"
    echo -e "${YELLOW}Check logs: cat $ACME_HOME/acme.sh.log${NC}"
    exit 1
fi
echo ""

# Installation certificates
echo -e "${YELLOW}📋 Installation certificates...${NC}"

"$ACME_HOME/acme.sh" --install-cert \
  -d "$DOMAIN" \
  --key-file "$SSL_DIR/letsencrypt-privkey.key" \
  --fullchain-file "$SSL_DIR/letsencrypt-fullchain.crt" \
  --cert-file "$SSL_DIR/letsencrypt-cert.crt" \
  --ca-file "$SSL_DIR/letsencrypt-chain.crt" \
  --reloadcmd "cd $PROJECT_ROOT && docker compose restart nginx"

# Installation correct access permissions
chmod 644 "$SSL_DIR/letsencrypt-fullchain.crt"
chmod 600 "$SSL_DIR/letsencrypt-privkey.key"
chmod 644 "$SSL_DIR/letsencrypt-cert.crt"
chmod 644 "$SSL_DIR/letsencrypt-chain.crt"

echo -e "${GREEN}✅ Certificates installedы${NC}"
echo ""

# Creating symbolic links
echo -e "${YELLOW}🔗 Creating symbolic links...${NC}"
cd "$SSL_DIR"
ln -sf letsencrypt-fullchain.crt nginx-fullchain.crt
ln -sf letsencrypt-fullchain.crt nginx.crt
ln -sf letsencrypt-privkey.key nginx.key
echo -e "${GREEN}✅ Symbolic links created${NC}"
echo ""

# Check certificate
echo -e "${YELLOW}🔍 Check certificate...${NC}"
openssl x509 -in "$SSL_DIR/nginx-fullchain.crt" -noout -subject -issuer -dates -ext subjectAltName
echo ""

echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}✅ Let's Encrypt certificates successfully created!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}Info:${NC}"
echo -e "  - Certificate: Let's Encrypt (R3)"
echo -e "  - Validity period: 90 days"
echo -e "  - Auto-renewal: configured via acme.sh cron"
echo -e "  - Backup: $BACKUP_DIR"
echo ""
echo -e "${YELLOW}Check HTTPS:${NC}"
echo -e "  curl -I https://ki.erni-gruppe.ch"
echo -e "  curl -I https://www.ki.erni-gruppe.ch"
echo ""
