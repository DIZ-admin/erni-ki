#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LE_DIR="${ROOT_DIR}/secrets/letsencrypt"
SSL_DIR="${ROOT_DIR}/conf/nginx/ssl"
EMAIL="admin@ki.erni-gruppe.ch"
DOMAINS=(-d ki.erni-gruppe.ch -d www.ki.erni-gruppe.ch)

if [[ ! -f "${LE_DIR}/cloudflare.ini" ]]; then
  echo "❌ ${LE_DIR}/cloudflare.ini not found (Cloudflare token missing)" >&2
  exit 1
fi

mkdir -p "${LE_DIR}"
chmod 700 "${LE_DIR}"
chmod 600 "${LE_DIR}/cloudflare.ini"

echo "▶️ Running certbot via docker (dns-cloudflare)…"
docker run --rm \
  -v "${LE_DIR}:/etc/letsencrypt" \
  -v "${LE_DIR}:/var/lib/letsencrypt" \
  certbot/dns-cloudflare \
  certonly --non-interactive --agree-tos -m "${EMAIL}" \
  --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  "${DOMAINS[@]}"

LIVE_DIR="${LE_DIR}/live/ki.erni-gruppe.ch"
if [[ ! -f "${LIVE_DIR}/fullchain.pem" || ! -f "${LIVE_DIR}/privkey.pem" ]]; then
  echo "❌ Missing cert files in ${LIVE_DIR}" >&2
  exit 1
fi

echo "▶️ Deploying certs to ${SSL_DIR}…"
cp "${LIVE_DIR}/fullchain.pem" "${SSL_DIR}/nginx-fullchain.crt"
cp "${LIVE_DIR}/fullchain.pem" "${SSL_DIR}/nginx.crt"
cp "${LIVE_DIR}/privkey.pem" "${SSL_DIR}/nginx.key"
chmod 644 "${SSL_DIR}/nginx-fullchain.crt" "${SSL_DIR}/nginx.crt"
chmod 600 "${SSL_DIR}/nginx.key"

echo "▶️ Restarting nginx to pick up new certs…"
docker compose restart nginx

echo "✅ Renewal complete."
