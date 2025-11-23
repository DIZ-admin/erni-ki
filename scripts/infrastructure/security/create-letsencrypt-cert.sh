#!/bin/bash

# ============================================================================
# Script creation Let's Encrypt certificates for ERNI-KI
# ============================================================================
# Description: Automatic obtaining SSL certificates via certbot
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
WEBROOT_DIR="$PROJECT_ROOT/data/nginx/webroot"
LETSENCRYPT_DIR="$PROJECT_ROOT/data/letsencrypt"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/ssl-$(date +%Y%m%d-%H%M%S)"

# Domains
DOMAINS="ki.erni-gruppe.ch,www.ki.erni-gruppe.ch"
EMAIL="diginnz1@gmail.com"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Creating Let's Encrypt certificates for ERNI-KI${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Check зависимостей
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}⚠️  certbot not installed. Installing...${NC}"
    sudo apt-get update
    sudo apt-get install -y certbot
    echo -e "${GREEN}✅ certbot installed${NC}"
fi

# Creating необходимых директорий
echo -e "${YELLOW}📁 Creating директорий...${NC}"
mkdir -p "$WEBROOT_DIR"
mkdir -p "$LETSENCRYPT_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$SSL_DIR"
echo -e "${GREEN}✅ Directories созданы${NC}"
echo ""

# Backup существующих certificates
echo -e "${YELLOW}📦 Creating backup of current certificates...${NC}"
if [[ -f "$SSL_DIR/nginx.crt" ]]; then
    cp "$SSL_DIR/nginx.crt" "$BACKUP_DIR/nginx.crt.backup"
    echo -e "${GREEN}✅ Saved: nginx.crt${NC}"
fi

if [[ -f "$SSL_DIR/nginx.key" ]]; then
    cp "$SSL_DIR/nginx.key" "$BACKUP_DIR/nginx.key.backup"
    echo -e "${GREEN}✅ Saved: nginx.key${NC}"
fi

if [[ -f "$SSL_DIR/nginx-fullchain.crt" ]]; then
    cp "$SSL_DIR/nginx-fullchain.crt" "$BACKUP_DIR/nginx-fullchain.crt.backup"
    echo -e "${GREEN}✅ Saved: nginx-fullchain.crt${NC}"
fi
echo ""

# Check DNS
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Check DNS записей${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

echo -e "${YELLOW}Check ki.erni-gruppe.ch...${NC}"
KI_IP=$(dig +short ki.erni-gruppe.ch @8.8.8.8 | tail -1)
echo -e "DNS: ${GREEN}$KI_IP${NC}"

echo -e "${YELLOW}Check www.ki.erni-gruppe.ch...${NC}"
WWW_IP=$(dig +short www.ki.erni-gruppe.ch @8.8.8.8 | tail -1)
echo -e "DNS: ${GREEN}$WWW_IP${NC}"

# Obtaining текущего IP сервера
SERVER_IP=$(curl -s https://ipinfo.io/ip)
echo -e "${YELLOW}IP сервера:${NC} ${GREEN}$SERVER_IP${NC}"
echo ""

if [[ "$KI_IP" != "$SERVER_IP" ]]; then
    echo -e "${RED}⚠️  ATTENTION: DNS еще не распространился полностью${NC}"
    echo -e "${YELLOW}ki.erni-gruppe.ch указывает на $KI_IP, но сервер имеет IP $SERVER_IP${NC}"
    echo -e "${YELLOW}Продолжить? (y/n)${NC}"
    read -r CONTINUE
    if [[ "$CONTINUE" != "y" ]]; then
        echo -e "${RED}Отменено пользователем${NC}"
        exit 1
    fi
fi

# Check доступности порта 80
echo -e "${YELLOW}🔍 Check доступности порта 80...${NC}"
if curl -I -s -m 5 http://ki.erni-gruppe.ch/.well-known/acme-challenge/test 2>&1 | grep -q "404"; then
    echo -e "${GREEN}✅ Port 80 доступен${NC}"
else
    echo -e "${YELLOW}⚠️  Port 80 может быть недоступен извне${NC}"
fi
echo ""

# Obtaining certificate
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Obtaining Let's Encrypt certificate${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

echo -e "${YELLOW}Domains:${NC} $DOMAINS"
echo -e "${YELLOW}Email:${NC} $EMAIL"
echo -e "${YELLOW}Webroot:${NC} $WEBROOT_DIR"
echo ""

# Starting certbot
echo -e "${YELLOW}🔐 Starting certbot...${NC}"
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

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Certificate successfully obtained!${NC}"
else
    echo -e "${RED}❌ Error when obtaining certificate${NC}"
    echo -e "${YELLOW}Check logs certbot: sudo journalctl -u certbot${NC}"
    exit 1
fi
echo ""

# Копирование certificates в nginx директорию
echo -e "${YELLOW}📋 Копирование certificates в nginx директорию...${NC}"

CERT_PATH="/etc/letsencrypt/live/ki.erni-gruppe.ch"

if [[ ! -d "$CERT_PATH" ]]; then
    echo -e "${RED}❌ Error: Certificates не найдены в $CERT_PATH${NC}"
    exit 1
fi

sudo cp "$CERT_PATH/fullchain.pem" "$SSL_DIR/letsencrypt-fullchain.crt"
sudo cp "$CERT_PATH/privkey.pem" "$SSL_DIR/letsencrypt-privkey.key"
sudo cp "$CERT_PATH/cert.pem" "$SSL_DIR/letsencrypt-cert.crt"
sudo cp "$CERT_PATH/chain.pem" "$SSL_DIR/letsencrypt-chain.crt"

# Installation correct access permissions
sudo chown $(whoami):$(whoami) "$SSL_DIR/letsencrypt-"*
chmod 644 "$SSL_DIR/letsencrypt-fullchain.crt"
chmod 600 "$SSL_DIR/letsencrypt-privkey.key"
chmod 644 "$SSL_DIR/letsencrypt-cert.crt"
chmod 644 "$SSL_DIR/letsencrypt-chain.crt"

echo -e "${GREEN}✅ Certificates скопированы${NC}"
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
echo -e "${GREEN}✅ Let's Encrypt certificates successfully created и installedы!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}Backup сохранен в:${NC} $BACKUP_DIR"
echo -e "${YELLOW}Certificates:${NC} $SSL_DIR"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo -e "1. Перезагрузите nginx: ${GREEN}docker compose restart nginx${NC}"
echo -e "2. Проверьте HTTPS: ${GREEN}curl -I https://ki.erni-gruppe.ch${NC}"
echo ""
