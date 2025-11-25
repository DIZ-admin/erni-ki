#!/bin/bash
# SSL certificate generation script for ERNI-KI
# Creates self-signed certificates for local use

set -e

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging helpers
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
SSL_DIR="$(dirname "$0")"
DOMAIN_NAME="${1:-erni-ki.local}"
COUNTRY="DE"
STATE="Baden-Württemberg"
CITY="Stuttgart"
ORGANIZATION="ERNI-KI"
ORGANIZATIONAL_UNIT="AI Infrastructure"
EMAIL="admin@erni-ki.local"

# Create SSL directory
mkdir -p "$SSL_DIR"
cd "$SSL_DIR"

log "Generating SSL certificates for domain: $DOMAIN_NAME"

# Create OpenSSL config
cat > openssl.conf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=$COUNTRY
ST=$STATE
L=$CITY
O=$ORGANIZATION
OU=$ORGANIZATIONAL_UNIT
CN=$DOMAIN_NAME
emailAddress=$EMAIL

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN_NAME
DNS.2 = *.$DOMAIN_NAME
DNS.3 = localhost
DNS.4 = *.localhost
DNS.5 = diz.zone
DNS.6 = *.diz.zone
IP.1 = 127.0.0.1
IP.2 = ::1
IP.3 = 192.168.1.100
EOF

# Generate private key
log "Generating private key..."
openssl genrsa -out nginx.key 4096

# Generate CSR
log "Generating certificate signing request..."
openssl req -new -key nginx.key -out nginx.csr -config openssl.conf

# Generate self-signed certificate
log "Generating self-signed certificate..."
openssl x509 -req -in nginx.csr -signkey nginx.key -out nginx.crt -days 365 -extensions v3_req -extfile openssl.conf

# Create combined PEM file (if needed)
log "Creating combined certificate file..."
cat nginx.crt nginx.key > nginx.pem

# Generate DH params for stronger security
log "Generating DH params (this may take a few minutes)..."
openssl dhparam -out dhparam.pem 2048

# Set proper permissions
chmod 600 nginx.key nginx.pem
chmod 644 nginx.crt nginx.csr dhparam.pem
chmod 644 openssl.conf

# Create Nginx SSL config
cat > nginx-ssl.conf << 'EOF'
# SSL configuration for ERNI-KI
# Add to nginx server block

# SSL certificates
ssl_certificate /etc/nginx/ssl/nginx.crt;
ssl_certificate_key /etc/nginx/ssl/nginx.key;
ssl_dhparam /etc/nginx/ssl/dhparam.pem;

# SSL protocols and ciphers
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_prefer_server_ciphers on;

# SSL sessions
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;

# Security headers
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
EOF

# Verify certificate
log "Verifying generated certificate..."
openssl x509 -in nginx.crt -text -noout | grep -E "(Subject:|DNS:|IP Address:|Not After)"

# Output info
success "SSL certificates created successfully!"
echo ""
echo "Created files:"
echo "  - nginx.key: Private key"
echo "  - nginx.crt: Certificate"
echo "  - nginx.csr: CSR"
echo "  - nginx.pem: Combined file"
echo "  - dhparam.pem: DH params"
echo "  - openssl.conf: OpenSSL config"
echo "  - nginx-ssl.conf: Nginx config example"
echo ""
echo "Domains in certificate:"
echo "  - $DOMAIN_NAME"
echo "  - *.$DOMAIN_NAME"
echo "  - localhost"
echo "  - *.localhost"
echo "  - diz.zone"
echo "  - *.diz.zone"
echo ""
warning "WARNING: This is a self-signed certificate!"
warning "Browsers will show a security warning."
warning "For production, use certificates from a trusted CA (e.g., Let's Encrypt)."
echo ""
log "For Docker Compose usage ensure the volume is mounted:"
log "  volumes:"
log "    - ./conf/nginx/ssl:/etc/nginx/ssl"

# Cleanup temporary files
rm -f nginx.csr openssl.conf

success "SSL certificate generation completed!"
