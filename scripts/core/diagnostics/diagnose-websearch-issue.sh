#!/bin/bash

# Web Search Issue Diagnosis Script for ERNI-KI
# OpenWebUI web search issue diagnosis script

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# Colors for output

# Check service availability
check_services() {
    log_info "Checking service status..."

    echo "=== Docker Compose Services ==="
    docker-compose ps openwebui searxng nginx cloudflared auth
    echo ""
}

# Test SearXNG directly
test_searxng_direct() {
    log_info "Testing SearXNG directly..."

    echo "=== Direct connection to SearXNG ==="

    # Test via localhost:8081
    if curl -s -f http://localhost:8081/ >/dev/null; then
        log_success "SearXNG available via localhost:8081"
    else
        log_error "SearXNG unavailable via localhost:8081"
    fi

    # Test search via localhost
    echo "Testing search via localhost..."
    local search_response
    search_response=$(curl -s -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "q=test&category_general=1&format=json" \
        http://localhost:8081/search)

    if echo "$search_response" | jq . >/dev/null 2>&1; then
        log_success "Search via localhost returns valid JSON"
        echo "Number of results: $(echo "$search_response" | jq '.results | length')"
    else
        log_warn "Search via localhost does not return valid JSON"
        echo "Response: ${search_response:0:200}..."
    fi
    echo ""
}

# Test via Nginx proxy
test_nginx_proxy() {
    log_info "Testing via Nginx proxy..."

    echo "=== Test via Nginx (localhost) ==="

    # Test availability via Nginx
    if curl -s -f -H "Host: localhost" http://localhost/searxng/ >/dev/null 2>&1; then
        log_success "SearXNG available via Nginx proxy (localhost)"
    else
        log_warn "SearXNG unavailable via Nginx proxy (localhost) - authentication might be required"
    fi

    echo "=== Test via Nginx (diz.zone) ==="

    # Test via diz.zone (if available)
    if curl -s -f -k https://diz.zone/searxng/ >/dev/null 2>&1; then
        log_success "SearXNG available via diz.zone"
    else
        log_warn "SearXNG unavailable via diz.zone - authentication might be required"
    fi
    echo ""
}

# Analyze OpenWebUI configuration
analyze_openwebui_config() {
    log_info "Analyzing OpenWebUI configuration..."

    echo "=== OpenWebUI Environment Variables ==="
    docker-compose exec -T openwebui env | grep -E "(SEARXNG|WEB_SEARCH|WEBUI_URL)" || echo "Variables not found"

    echo ""
    echo "=== Checking connection OpenWebUI -> SearXNG ==="

    # Test connection from inside OpenWebUI container
    if docker-compose exec -T openwebui curl -s -f http://searxng:8080/ >/dev/null; then
        log_success "OpenWebUI can connect to SearXNG directly"
    else
        log_error "OpenWebUI cannot connect to SearXNG"
    fi

    # Test search from inside OpenWebUI
    echo "Testing search from inside OpenWebUI..."
    local internal_search
    internal_search=$(docker-compose exec -T openwebui curl -s -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "q=test&category_general=1&format=json" \
        http://searxng:8080/search)

    if echo "$internal_search" | jq . >/dev/null 2>&1; then
        log_success "Internal search OpenWebUI -> SearXNG works"
    else
        log_warn "Internal search OpenWebUI -> SearXNG failed"
        echo "Response: ${internal_search:0:200}..."
    fi
    echo ""
}

# Check Nginx configuration
check_nginx_config() {
    log_info "Checking Nginx configuration..."

    echo "=== Nginx Configuration Test ==="
    if docker-compose exec -T nginx nginx -t; then
        log_success "Nginx configuration is valid"
    else
        log_error "Error in Nginx configuration"
    fi

    echo ""
    echo "=== Nginx Route Analysis ==="
    echo "Checking /searxng route in configuration:"
    docker-compose exec -T nginx grep -A 10 -B 5 "searxng" /etc/nginx/conf.d/default.conf || echo "Route not found"
    echo ""
}

# Check logs
check_logs() {
    log_info "Analyzing service logs..."

    echo "=== OpenWebUI Logs (last 20 lines) ==="
    docker-compose logs --tail=20 openwebui | grep -E "(search|searxng|error)" || echo "No relevant entries found"

    echo ""
    echo "=== SearXNG Logs (last 20 lines) ==="
    docker-compose logs --tail=20 searxng | grep -E "(error|warning|search)" || echo "No relevant entries found"

    echo ""
    echo "=== Nginx Logs (last 20 lines) ==="
    docker-compose logs --tail=20 nginx | grep -E "(searxng|error|upstream)" || echo "No relevant entries found"

    echo ""
    echo "=== Cloudflared Logs (last 10 lines) ==="
    docker-compose logs --tail=10 cloudflared | grep -E "(error|tunnel)" || echo "No relevant entries found"
    echo ""
}

# Test HTTP headers
test_http_headers() {
    log_info "Analyzing HTTP headers..."

    echo "=== Headers localhost:8081 (direct connection) ==="
    curl -s -I http://localhost:8081/ | head -10

    echo ""
    echo "=== Headers via Nginx (localhost) ==="
    curl -s -I -H "Host: localhost" http://localhost/searxng/ | head -10 || echo "Unavailable"

    echo ""
    echo "=== Headers via diz.zone ==="
    curl -s -I -k https://diz.zone/searxng/ | head -10 || echo "Unavailable"
    echo ""
}

# Simulate web search request
simulate_websearch() {
    log_info "Simulating web search request..."

    echo "=== Simulating request via localhost ==="
    local localhost_result
    localhost_result=$(curl -s -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "q=test search&category_general=1&format=json" \
        http://localhost:8081/search)

    echo "Response size: $(echo "$localhost_result" | wc -c) bytes"
    echo "First 200 chars: ${localhost_result:0:200}"

    if echo "$localhost_result" | jq . >/dev/null 2>&1; then
        log_success "Localhost returns valid JSON"
    else
        log_warn "Localhost does not return valid JSON"
    fi

    echo ""
    echo "=== Simulating request via diz.zone (if available) ==="
    # This test might not work without authentication
    echo "Note: Test via diz.zone requires authentication"
    echo ""
}

# Check network connections
check_network() {
    log_info "Checking network connections..."

    echo "=== Docker Networks ==="
    docker network ls | grep erni-ki || echo "Networks not found"

    echo ""
    echo "=== Container Connections ==="
    echo "OpenWebUI -> SearXNG:"
    docker-compose exec -T openwebui nslookup searxng || echo "DNS not working"

    echo ""
    echo ""
    echo "Nginx -> SearXNG:"
    docker-compose exec -T nginx nslookup searxng || echo "DNS not working"
    echo ""
}

# Generate report
generate_report() {
    log_info "Generating diagnosis report..."

    local report_file="websearch_diagnosis_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "Web Search Issue Diagnosis Report"
        echo "Generated: $(date)"
        echo "================================="
        echo ""

        echo "PROBLEM DESCRIPTION:"
        echo "- Web search works via localhost/local IPs"
        echo "- Web search fails via diz.zone domain"
        echo "- Error: SyntaxError: JSON.parse: unexpected character"
        echo ""

        echo "CURRENT CONFIGURATION:"
        echo "- SEARXNG_QUERY_URL: $(docker-compose exec -T openwebui env | grep SEARXNG_QUERY_URL || echo 'Not set')"
        echo "- WEBUI_URL: $(docker-compose exec -T openwebui env | grep WEBUI_URL || echo 'Not set')"
        echo "- WEB_SEARCH_ENGINE: $(docker-compose exec -T openwebui env | grep WEB_SEARCH_ENGINE || echo 'Not set')"
        echo ""

        echo "SERVICE STATUS:"
        docker-compose ps openwebui searxng nginx cloudflared auth
        echo ""

        echo "NGINX SEARXNG ROUTE:"
        docker-compose exec -T nginx grep -A 15 -B 5 "searxng" /etc/nginx/conf.d/default.conf || echo "Route not found"
        echo ""

        echo "RECENT ERRORS:"
        echo "OpenWebUI errors:"
        docker-compose logs --tail=50 openwebui | grep -i error | tail -10 || echo "No errors found"
        echo ""
        echo "SearXNG errors:"
        docker-compose logs --tail=50 searxng | grep -i error | tail -10 || echo "No errors found"
        echo ""
        echo "Nginx errors:"
        docker-compose logs --tail=50 nginx | grep -i error | tail -10 || echo "No errors found"

    } > "$report_file"

    log_success "Report saved to: $report_file"
}

# Main function
main() {
    log_info "Starting web search issue diagnosis..."

    # Check if we are in project root
    if [ ! -f "compose.yml" ] && [ ! -f "docker-compose.yml" ]; then
        log_error "compose.yml not found. Run script from project root."
        exit 1
    fi

    check_services
    test_searxng_direct
    test_nginx_proxy
    analyze_openwebui_config
    check_nginx_config
    check_logs
    test_http_headers
    simulate_websearch
    check_network
    generate_report

    echo ""
    echo ""
    log_info "Diagnosis completed. Main issues:"
    echo "1. /searxng route in Nginx requires authentication"
    echo "2. OpenWebUI makes internal API requests that are blocked"
    echo "3. Need to create a separate route for API without authentication"
    echo ""
    log_warn "Recommendation: Run ./scripts/fix-websearch-issue.sh to fix"
}

# Run script
main "$@"
