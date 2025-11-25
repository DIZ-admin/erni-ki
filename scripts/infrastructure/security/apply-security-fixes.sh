#!/bin/bash

# ERNI-KI Security Fixes Application Script
# Apply nginx security fixes without full system restart

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
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

# Permissions check
if [[ $EUID -eq 0 ]]; then
   error "This script must not be run as root"
   exit 1
fi

# docker-compose check
if ! command -v docker-compose &> /dev/null; then
    error "docker-compose not found"
    exit 1
fi

log "🔧 Applying ERNI-KI nginx security fixes..."

# Backup current configuration
BACKUP_DIR=".config-backup/nginx-security-$(date +%Y%m%d-%H%M%S)"
log "📦 Creating backup in $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r conf/nginx/ "$BACKUP_DIR/"
success "Backup created"

# Validate nginx config syntax
log "🔍 Checking nginx configuration syntax..."
if docker-compose exec -T nginx nginx -t; then
    success "Configuration syntax is valid"
else
    error "nginx configuration syntax error"
    log "Restoring from backup..."
    cp -r "$BACKUP_DIR/nginx/" conf/
    exit 1
fi

# Apply changes with graceful reload
log "🔄 Applying nginx reload..."
if docker-compose exec -T nginx nginx -s reload; then
    success "nginx configuration reloaded"
else
    error "Error reloading nginx"
    log "Restoring from backup..."
    cp -r "$BACKUP_DIR/nginx/" conf/
    docker-compose exec -T nginx nginx -s reload
    exit 1
fi

# Check service status
log "🏥 Checking service status..."
UNHEALTHY_SERVICES=$(docker-compose ps --format "table {{.Service}}\t{{.Status}}" | grep -v "Up.*healthy" | grep -v "SERVICE" | wc -l)

if [ "$UNHEALTHY_SERVICES" -gt 0 ]; then
    warning "Unhealthy services detected:"
    docker-compose ps --format "table {{.Service}}\t{{.Status}}" | grep -v "Up.*healthy" | grep -v "SERVICE"
else
    success "All services are healthy"
fi

# Test HTTPS
log "🔐 Testing HTTPS..."
if curl -s -I -k https://localhost >/dev/null 2>&1; then
    success "HTTPS is reachable"
else
    warning "HTTPS access has issues"
fi

# Security headers check
log "🛡️ Checking security headers..."
SECURITY_HEADERS=$(curl -s -I -k https://localhost | grep -E "(strict-transport-security|content-security-policy|x-frame-options)" | wc -l)
if [ "$SECURITY_HEADERS" -ge 3 ]; then
    success "Security headers are present"
else
    warning "Some security headers are missing"
fi

# Rate limiting check
log "⚡ Checking rate limiting..."
if docker-compose exec -T nginx test -f /var/log/nginx/rate_limit.log; then
    success "Rate limiting logging is configured"
else
    warning "Rate limiting logging is not configured"
fi

# Final check
log "✅ Final system check..."
TOTAL_SERVICES=$(docker-compose ps --format "table {{.Service}}" | grep -v "SERVICE" | wc -l)
HEALTHY_SERVICES=$(docker-compose ps --format "table {{.Service}}\t{{.Status}}" | grep "Up.*healthy" | wc -l)

echo
echo "📊 System stats:"
echo "   Total services: $TOTAL_SERVICES"
echo "   Healthy services: $HEALTHY_SERVICES"
echo "   Backup: $BACKUP_DIR"
echo

if [ "$HEALTHY_SERVICES" -eq "$TOTAL_SERVICES" ]; then
    success "🎉 Security fixes applied successfully!"
    success "All $TOTAL_SERVICES services are healthy"
else
    warning "⚠️ Fixes applied, but some services have issues"
    echo "Check logs of problematic services: docker-compose logs [service_name]"
fi

log "🔍 For security monitoring:"
echo "   - Rate limiting logs: docker-compose exec nginx tail -f /var/log/nginx/rate_limit.log"
echo "   - Nginx status: curl -s http://localhost:8080/nginx_status"
echo "   - Header check: curl -I -k https://localhost"

echo
success "Security fixes application completed!"
