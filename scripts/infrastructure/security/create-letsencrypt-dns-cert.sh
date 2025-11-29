#!/bin/bash

# ============================================================================
# Issue Let's Encrypt certificates using the DNS-01 challenge (Cloudflare)
# ============================================================================
# Description: Requests wildcard-ready certificates through acme.sh + Cloudflare
# Author: Augment Agent
# Date: 11.11.2025
# ============================================================================

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SSL_DIR="$PROJECT_ROOT/conf/nginx/ssl"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/ssl-$(date +%Y%m%d-%H%M%S)"
ACME_HOME="$HOME/.acme.sh"

DOMAIN="ki.erni-gruppe.ch"
DOMAIN_WWW="www.ki.erni-gruppe.ch"
EMAIL="diginnz1@gmail.com"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Issuing Let's Encrypt certificates via Cloudflare DNS${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo -e "${YELLOW}Checking acme.sh installation...${NC}"
if [[ ! -f "$ACME_HOME/acme.sh" ]]; then
    echo -e "${YELLOW}Installing acme.sh...${NC}"
    curl https://get.acme.sh | sh -s email=$EMAIL
    source "$HOME/.acme.sh/acme.sh.env"
    echo -e "${GREEN}acme.sh installed${NC}"
else
    source "$HOME/.acme.sh/acme.sh.env"
    echo -e "${GREEN}acme.sh already available${NC}"
fi

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Configure Cloudflare API token${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo -e "${YELLOW}Generate an API token with DNS:Edit rights for erni-gruppe.ch.${NC}"
echo -e "See https://dash.cloudflare.com/profile/api-tokens → Create Token (Edit zone DNS)."

echo -e "${GREEN}Paste Cloudflare API Token:${NC}"
read -s CF_Token
if [[ -z "$CF_Token" ]]; then
    echo -e "${RED}API token cannot be empty${NC}"
    exit 1
fi

declare -x CF_Token="$CF_Token"
export CF_Account_ID=""

mkdir -p "$BACKUP_DIR" "$SSL_DIR"

echo -e "${YELLOW}Backing up current nginx certificates...${NC}"
for file in nginx.crt nginx.key; do
    if [[ -f "$SSL_DIR/$file" ]]; then
        cp "$SSL_DIR/$file" "$BACKUP_DIR/$file.backup"
        echo -e "${GREEN}Saved $file${NC}"
    fi
done

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Requesting certificate (DNS-01)${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo -e "Domains: ${DOMAIN}, ${DOMAIN_WWW}"
echo -e "Email:   ${EMAIL}"
echo -e "Provider: Cloudflare"

"$ACME_HOME/acme.sh" --issue \
  --dns dns_cf \
  -d "$DOMAIN" \
  -d "$DOMAIN_WWW" \
  --keylength 2048 \
  --server letsencrypt

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Certificate issuance failed. Inspect $ACME_HOME/acme.sh.log${NC}"
    exit 1
fi

echo -e "${GREEN}Certificate issued successfully${NC}"

echo -e "${YELLOW}Installing certificate into nginx SSL directory...${NC}"
"$ACME_HOME/acme.sh" --install-cert \
  -d "$DOMAIN" \
  --key-file "$SSL_DIR/letsencrypt-privkey.key" \
  --fullchain-file "$SSL_DIR/letsencrypt-fullchain.crt" \
  --cert-file "$SSL_DIR/letsencrypt-cert.crt" \
  --ca-file "$SSL_DIR/letsencrypt-chain.crt" \
  --reloadcmd "cd $PROJECT_ROOT && docker compose restart nginx"

chmod 644 "$SSL_DIR/letsencrypt-fullchain.crt" "$SSL_DIR/letsencrypt-cert.crt" "$SSL_DIR/letsencrypt-chain.crt"
chmod 600 "$SSL_DIR/letsencrypt-privkey.key"

echo -e "${GREEN}Certificate files copied${NC}"

cd "$SSL_DIR"
ln -sf letsencrypt-fullchain.crt nginx-fullchain.crt
ln -sf letsencrypt-fullchain.crt nginx.crt
ln -sf letsencrypt-privkey.key nginx.key

echo -e "${GREEN}Symlinks refreshed${NC}"

echo -e "${YELLOW}Inspecting resulting certificate...${NC}"
openssl x509 -in "$SSL_DIR/nginx-fullchain.crt" -noout -subject -issuer -dates -ext subjectAltName

echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}DNS-01 certificates deployed successfully!${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo -e "Certificate validity: 90 days (auto-renewed by acme.sh cron)."
echo -e "Backup directory: $BACKUP_DIR"
echo -e "Validate HTTPS with: curl -I https://ki.erni-gruppe.ch"
