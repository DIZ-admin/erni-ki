#!/bin/bash

# ERNI-KI Domain Monitoring Script
# Monitoring script for ki.erni-gruppe.ch availability

set -euo pipefail

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="ki.erni-gruppe.ch"
LOCAL_HTTPS="https://localhost"
LOCAL_HTTP="http://localhost:8080"
TIMEOUT=10
LOG_FILE=".config-backup/monitoring/ki-erni-gruppe-ch-$(date +%Y%m%d).log"

# Logging helpers
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[$timestamp] [SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[$timestamp] [WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[$timestamp] [ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log "🔍 Starting availability checks for $DOMAIN..."

# HTTP status helper
check_http_status() {
    local url=$1
    local name=$2
    local expected_status=${3:-200}

    log "Checking $name ($url)..."

    local start_time=$(date +%s.%N)
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT "$url" 2>/dev/null || echo "000")
    local end_time=$(date +%s.%N)
    local response_time=$(echo "$end_time - $start_time" | bc -l)

    if [ "$status_code" = "$expected_status" ]; then
            success "$name: HTTP $status_code (${response_time}s)"
        return 0
    else
        error "$name: HTTP $status_code (expected $expected_status) (${response_time}s)"
        return 1
    fi
}

# Service status helper
check_service_health() {
    local service=$1
    log "Checking service $service..."

    local status=$(docker-compose ps --format "table {{.Service}}\t{{.Status}}" | grep "^$service" | awk '{print $2}')

    if echo "$status" | grep -q "healthy"; then
        success "Service $service: $status"
        return 0
    else
        warning "Service $service: $status"
        return 1
    fi
}

# Core checks
TOTAL_CHECKS=0
FAILED_CHECKS=0

# 1. Local HTTPS access
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if ! check_http_status "$LOCAL_HTTPS" "Local HTTPS"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 2. Local HTTP (port 8080)
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if ! check_http_status "$LOCAL_HTTP" "Local HTTP (8080)"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 3. Cloudflare tunnel
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if ! check_http_status "https://$DOMAIN" "Cloudflare tunnel ($DOMAIN)"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 4. Health endpoint
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
log "Checking OpenWebUI health endpoint..."
if curl -s "https://$DOMAIN/api/health" | jq -e '.status == true' >/dev/null 2>&1; then
    success "OpenWebUI health endpoint: OK"
else
    error "OpenWebUI health endpoint: FAILED"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 5. Critical services
for service in nginx openwebui db ollama searxng cloudflared; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if ! check_service_health "$service"; then
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
done

# 6. Response time measurement
log "Measuring response time..."
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" --connect-timeout $TIMEOUT "https://$DOMAIN" 2>/dev/null || echo "999")

if (( $(echo "$RESPONSE_TIME < 3.0" | bc -l) )); then
    success "Response time: ${RESPONSE_TIME}s (target <3s)"
else
    warning "Response time: ${RESPONSE_TIME}s (exceeds 3s target)"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 7. Nginx HTTP 500 log scan
log "Scanning nginx logs for HTTP 500 errors (last hour)..."
ERROR_500_COUNT=$(docker-compose logs nginx --since 1h | grep -c " 500 " || echo "0")

if [ "$ERROR_500_COUNT" -eq 0 ]; then
    success "HTTP 500 errors: none detected"
else
    warning "HTTP 500 errors: $ERROR_500_COUNT in the last hour"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Final summary
echo
log "📊 Monitoring summary:"
echo "   Total checks: $TOTAL_CHECKS"
echo "   Successful: $((TOTAL_CHECKS - FAILED_CHECKS))"
echo "   Failed: $FAILED_CHECKS"
echo "   Response time: ${RESPONSE_TIME}s"
echo "   Log file: $LOG_FILE"

if [ "$FAILED_CHECKS" -eq 0 ]; then
    success "🎉 All checks passed! Domain $DOMAIN is fully available."
    exit 0
elif [ "$FAILED_CHECKS" -le 2 ]; then
    warning "⚠️ Minor issues detected ($FAILED_CHECKS of $TOTAL_CHECKS)"
    exit 1
else
    error "❌ Major issues detected ($FAILED_CHECKS of $TOTAL_CHECKS)"
    exit 2
fi
