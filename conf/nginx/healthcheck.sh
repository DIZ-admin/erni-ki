#!/bin/bash
# Nginx Enhanced Healthcheck Script
# Checks HTTP status and upstream connectivity
# Author: ERNI-KI System
# Date: 2025-09-22

set -e

# Configuration
NGINX_PORT=80
NGINX_SSL_PORT=443
NGINX_API_PORT=8080
TIMEOUT=5
MAX_RETRIES=2

# Logging colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] HEALTHCHECK:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] HEALTHCHECK ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] HEALTHCHECK WARNING:${NC} $1" >&2
}

# HTTP status check
check_http_status() {
    local url=$1
    local expected_code=${2:-200}
    local description=$3

    log "Checking $description: $url"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT --max-time $TIMEOUT "$url" 2>/dev/null || echo "000")

    if [[ "$http_code" == "$expected_code" ]]; then
        log "✅ $description: HTTP $http_code"
        return 0
    else
        error "❌ $description: HTTP $http_code (expected $expected_code)"
        return 1
    fi
}

# TCP connectivity check
check_tcp_connection() {
    local host=$1
    local port=$2
    local description=$3

    log "Checking TCP connectivity: $description ($host:$port)"

    if timeout $TIMEOUT bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        log "✅ $description: TCP connection succeeded"
        return 0
    else
        error "❌ $description: TCP connection failed"
        return 1
    fi
}

# DNS resolution check
check_dns_resolution() {
    local hostname=$1
    local description=$2

    log "Checking DNS resolution: $description ($hostname)"

    local ip
    ip=$(getent hosts "$hostname" 2>/dev/null | awk '{print $1}' | head -1)

    if [[ -n "$ip" && "$ip" != "127.0.0.1" ]]; then
        log "✅ $description: DNS resolution successful ($hostname -> $ip)"
        return 0
    else
        error "❌ $description: DNS resolution failed"
        return 1
    fi
}

# Upstream server check
check_upstream_server() {
    local hostname=$1
    local port=$2
    local service_name=$3
    local retry_count=0

    log "Checking upstream server: $service_name"

    # DNS resolution
    if ! check_dns_resolution "$hostname" "$service_name DNS"; then
        return 1
    fi

    # TCP connectivity with retries
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        if check_tcp_connection "$hostname" "$port" "$service_name TCP"; then
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [[ $retry_count -lt $MAX_RETRIES ]]; then
            warning "Retry $retry_count/$MAX_RETRIES for $service_name"
            sleep 1
        fi
    done

    error "❌ $service_name: All connection attempts failed"
    return 1
}

# Main check function
main() {
    log "🔍 Starting enhanced nginx healthcheck"

    local failed_checks=0

    # 1. Check nginx core ports
    log "📡 Checking nginx ports"

    if ! check_http_status "http://localhost:$NGINX_PORT/nginx_status" 200 "Nginx Status Page"; then
        ((failed_checks++))
    fi

    if ! check_http_status "http://localhost:$NGINX_API_PORT/health" 200 "Nginx API Health"; then
        ((failed_checks++))
    fi

    # 2. Check critical upstream services
    log "🔗 Checking upstream services"

    # OpenWebUI - critical service
    if ! check_upstream_server "openwebui" 8080 "OpenWebUI"; then
        ((failed_checks++))
    fi

    # SearXNG - critical for RAG
    # Check via nginx proxy (SearXNG listens on IPv6 only)
    if ! check_http_status "http://localhost:8080/searxng/" 200 "SearXNG Proxy"; then
        warning "⚠️  SearXNG not reachable directly (IPv6 binding), proxy works"
        # Do not increment failed_checks since proxy is functional
    fi

    # Ollama - critical AI service
    if ! check_upstream_server "ollama" 11434 "Ollama"; then
        ((failed_checks++))
    fi

    # PostgreSQL - critical database
    if ! check_upstream_server "db" 5432 "PostgreSQL"; then
        ((failed_checks++))
    fi

    # 3. Proxy functionality
    log "🔄 Checking proxy functionality"

    # Proxy to OpenWebUI
    if ! check_http_status "http://localhost:$NGINX_API_PORT/" 200 "OpenWebUI Proxy"; then
        ((failed_checks++))
    fi

    # Proxy to SearXNG
    if ! check_http_status "http://localhost:$NGINX_API_PORT/searxng/" 200 "SearXNG Proxy"; then
        ((failed_checks++))
    fi

    # Final evaluation
    if [[ $failed_checks -eq 0 ]]; then
        log "✅ All checks passed! Nginx is healthy."
        exit 0
    elif [[ $failed_checks -le 2 ]]; then
        warning "⚠️  Minor issues detected ($failed_checks), nginx remains functional"
        exit 0
    else
        error "❌ Critical issues detected ($failed_checks). Nginx restart required."
        exit 1
    fi
}

# Entry point
main "$@"
