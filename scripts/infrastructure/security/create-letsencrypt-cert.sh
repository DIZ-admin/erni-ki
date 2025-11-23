#!/bin/bash

# ============================================================================
# Issue Let's Encrypt certificates for ERNI-KI via webroot validation
# ============================================================================
# Description: Automates certificate issuance using certbot (HTTP-01)
# Author: Augment Agent
# Date: 11.11.2025
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SSL_DIR="$PROJECT_ROOT/conf/nginx/ssl"
WEBROOT_DIR="$PROJECT_ROOT/data/nginx/webroot"
LETSENCRYPT_DIR="$PROJECT_ROOT/data/letsencrypt"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/ssl-$(date +%Y%m%d-%H%M%S)"

DOMAINS="ki.erni-gruppe.ch,www.ki.erni-gruppe.ch"
EMAIL="diginnz1@gmail.com"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Issuing Let's Encrypt certificates for ERNI-KI${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command -v certbot >/dev/null 2>&1; then
    echo -e "${YELLOW}certbot is missing, installing via apt...${NC}"
    sudo apt-get update
    sudo apt-get install -y certbot
    echo -e "${GREEN}certbot installed${NC}"
fi

mkdir -p "$WEBROOT_DIR" "$LETSENCRYPT_DIR" "$BACKUP_DIR" "$SSL_DIR"
echo -e "${GREEN}Directories ready${NC}"

echo -e "${YELLOW}Backing up existing certificates (if present)...${NC}"
for file in nginx.crt nginx.key nginx-fullchain.crt; do
    if [[ -f "$SSL_DIR/$file" ]]; then
        cp "$SSL_DIR/$file" "$BACKUP_DIR/$file.backup"
        echo -e "${GREEN}Saved $file to backup${NC}"
    fi
done

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Validating DNS records${NC}"
echo -e "${BLUE}============================================================================${NC}"

KI_IP=$(dig +short ki.erni-gruppe.ch @8.8.8.8 | tail -1)
WWW_IP=$(dig +short www.ki.erni-gruppe.ch @8.8.8.8 | tail -1)
SERVER_IP=$(curl -s https://ipinfo.io/ip)

echo -e "ki.erni-gruppe.ch -> ${GREEN}${KI_IP:-unknown}${NC}"
echo -e "www.ki.erni-gruppe.ch -> ${GREEN}${WWW_IP:-unknown}${NC}"
echo -e "Current server IP -> ${GREEN}${SERVER_IP:-unknown}${NC}"

if [[ "$KI_IP" != "$SERVER_IP" ]]; then
    echo -e "${RED}DNS does not point to this server yet.${NC}"
    echo -e "${YELLOW}Continue anyway? (y/n) ${NC}"
    read -r CONTINUE
    if [[ "$CONTINUE" != "y" ]]; then
        echo -e "${RED}Aborted by operator${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Checking port 80 reachability...${NC}"
if curl -I -s -m 5 http://ki.erni-gruppe.ch/.well-known/acme-challenge/test 2>&1 | grep -q "404"; then
    echo -e "${GREEN}Port 80 reachable${NC}"
else
    echo -e "${YELLOW}Port 80 might be blocked externally${NC}"
fi

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Requesting certificate via certbot${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo -e "Domains: ${DOMAINS}"
echo -e "Email:   ${EMAIL}"
echo -e "Webroot: ${WEBROOT_DIR}"

sudo certbot certonly \
  --webroot \
  --webroot-path="$WEBROOT_DIR" \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  --non-interactive \
  --expand \
  -d ki.erni-gruppe.ch \
  -d www.ki.erni-gruppe.ch

echo -e "${GREEN}Certificate request completed${NC}"

CERT_PATH="/etc/letsencrypt/live/ki.erni-gruppe.ch"
if [[ ! -d "$CERT_PATH" ]]; then
    echo -e "${RED}Certificate path $CERT_PATH not found${NC}"
    exit 1
fi

sudo cp "$CERT_PATH/fullchain.pem" "$SSL_DIR/letsencrypt-fullchain.crt"
sudo cp "$CERT_PATH/privkey.pem" "$SSL_DIR/letsencrypt-privkey.key"
sudo cp "$CERT_PATH/cert.pem" "$SSL_DIR/letsencrypt-cert.crt"
sudo cp "$CERT_PATH/chain.pem" "$SSL_DIR/letsencrypt-chain.crt"

sudo chown $(whoami):$(whoami) "$SSL_DIR"/letsencrypt-*
chmod 644 "$SSL_DIR/letsencrypt-fullchain.crt" "$SSL_DIR/letsencrypt-cert.crt" "$SSL_DIR/letsencrypt-chain.crt"
chmod 600 "$SSL_DIR/letsencrypt-privkey.key"

echo -e "${GREEN}Copied certificates into $SSL_DIR${NC}"

echo -e "${YELLOW}Creating nginx symlinks...${NC}"
cd "$SSL_DIR"
ln -sf letsencrypt-fullchain.crt nginx-fullchain.crt
ln -sf letsencrypt-fullchain.crt nginx.crt
ln -sf letsencrypt-privkey.key nginx.key
echo -e "${GREEN}Symlinks updated${NC}"

echo -e "${YELLOW}Inspecting resulting certificate...${NC}"
openssl x509 -in "$SSL_DIR/nginx-fullchain.crt" -noout -subject -issuer -dates -ext subjectAltName

echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}Certificates created and deployed successfully!${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo -e "Backup directory: ${BACKUP_DIR}"
echo -e "Certificates stored in: ${SSL_DIR}"

echo -e "Next steps:"
echo -e "  1. Restart nginx -> ${GREEN}docker compose restart nginx${NC}"
echo -e "  2. Validate HTTPS -> ${GREEN}curl -I https://ki.erni-gruppe.ch${NC}"
