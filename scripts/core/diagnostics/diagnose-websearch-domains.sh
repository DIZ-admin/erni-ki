#!/bin/bash

# Web Search Domain Diagnosis Script for ERNI-KI
# Script for diagnosing web search via different domains

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# Colors for output

# Check JSON function
check_json() {
    local response="$1"
    local domain="$2"

    if echo "$response" | jq . >/dev/null 2>&1; then
        local result_count=$(echo "$response" | jq '.results | length' 2>/dev/null || echo "0")
        log_success "$domain: Valid JSON, $result_count results"
        return 0
    else
        log_error "$domain: Invalid JSON"
        echo "First 200 characters of response:"
        echo "${response:0:200}"
        return 1
    fi
}

# Test API endpoint function
test_api_endpoint() {
    local domain="$1"
    local host_header="$2"

    log_info "Testing API endpoint for $domain..."

    local cmd=(curl -k -s -w "HTTP_CODE:%{http_code}" -X POST)
    if [ "$host_header" != "none" ]; then
        cmd+=(-H "Host: $host_header")
    fi
    cmd+=(-H "Content-Type: application/x-www-form-urlencoded")
    cmd+=(-d "q=test&format=json")
    cmd+=("https://localhost/api/searxng/search")

    local response
    if response=$("${cmd[@]}" 2>/dev/null); then
        local http_code="${response##*HTTP_CODE:}"
        local json_response="${response%HTTP_CODE:*}"

        echo "  HTTP code: $http_code"

        if [ "$http_code" = "200" ]; then
            check_json "$json_response" "$domain"
        else
            log_error "$domain: HTTP log_error $http_code"
            echo "  Response: ${json_response:0:200}"
            return 1
        fi
    else
        log_error "$domain: Failed to execute request"
        return 1
    fi
}

# Test main interface function
test_main_interface() {
    local domain="$1"
    local host_header="$2"

    log_info "Testing main interface for $domain..."

    local cmd=(curl -k -s -w "HTTP_CODE:%{http_code}")
    if [ "$host_header" != "none" ]; then
        cmd+=(-H "Host: $host_header")
    fi
    cmd+=("https://localhost/")

    local response
    if response=$("${cmd[@]}" 2>/dev/null); then
        local http_code="${response##*HTTP_CODE:}"

        echo "  HTTP code: $http_code"

        if [ "$http_code" = "200" ]; then
            log_success "$domain: Main interface available"
            return 0
        else
            log_warn "$domain: HTTP code $http_code"
            return 1
        fi
    else
        log_error "$domain: Main interface unavailable"
        return 1
    fi
}

# Check Nginx configuration function
check_nginx_config() {
    log_info "Checking Nginx configuration..."

    echo "=== Server Names ==="
    docker-compose exec nginx grep -A 2 "server_name" /etc/nginx/conf.d/default.conf || true

    echo ""
    echo "=== API Endpoint Configuration ==="
    docker-compose exec nginx grep -A 10 "location /api/searxng" /etc/nginx/conf.d/default.conf || true

    echo ""
    echo "=== Nginx Syntax Check ==="
    if docker-compose exec nginx nginx -t 2>/dev/null; then
        log_success "Nginx configuration is valid"
    else
        log_error "Error in Nginx configuration"
    fi
}

# Check environment variables function
check_environment() {
    log_info "Checking OpenWebUI environment variables..."

    echo "=== SEARXNG Configuration ==="
    grep -E "(SEARXNG|WEB_SEARCH)" env/openwebui.env || true

    echo ""
    echo "=== WEBUI_URL ==="
    grep "WEBUI_URL" env/openwebui.env || true
}

# Check service status function
check_services() {
    log_info "Checking service status..."

    echo "=== Docker Compose Status ==="
    docker-compose ps nginx openwebui searxng

    echo ""
    echo "=== Health Checks ==="
    local nginx_health=$(docker-compose ps nginx --format "table {{.Status}}" | tail -1)
    local openwebui_health=$(docker-compose ps openwebui --format "table {{.Status}}" | tail -1)
    local searxng_health=$(docker-compose ps searxng --format "table {{.Status}}" | tail -1)

    echo "Nginx: $nginx_health"
    echo "OpenWebUI: $openwebui_health"
    echo "SearXNG: $searxng_health"
}

# Check logs function
check_logs() {
    log_info "Checking service logs..."

    echo "=== Nginx Logs (last 5 lines) ==="
    docker-compose logs --tail=5 nginx 2>/dev/null || echo "Failed to get Nginx logs"

    echo ""
    echo "=== OpenWebUI Logs (last 5 lines) ==="
    docker-compose logs --tail=5 openwebui 2>/dev/null || echo "Failed to get OpenWebUI logs"

    echo ""
    echo "=== SearXNG Logs (last 5 lines) ==="
    docker-compose logs --tail=5 searxng 2>/dev/null || echo "Failed to get SearXNG logs"
}

# Simulate problem function
simulate_problem() {
    log_info "Simulating problem with JSON.parse..."

    # Test what happens if API returns HTML instead of JSON
    echo "=== Test: what if API returns HTML? ==="

    local html_response='<!DOCTYPE html><html><head><title>Error</title></head><body><h1>Authentication Required</h1></body></html>'

    echo "HTML response:"
    echo "$html_response"

    echo ""
    echo "Parsing attempt as JSON:"
    if echo "$html_response" | jq . >/dev/null 2>&1; then
        echo "✅ JSON valid"
    else
        echo "❌ JSON invalid - this will cause SyntaxError: JSON.parse"
    fi
}

# Main diagnosis function
main() {
    echo "=================================================="
    echo "🔍 WEB SEARCH DIAGNOSIS VIA DIFFERENT DOMAINS"
    echo "=================================================="
    echo "Time: $(date)"
    echo ""

    # Check dependencies
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq not installed. Install: sudo apt-get install jq"
        exit 1
    fi

    # 1. Check configuration
    check_nginx_config
    echo ""

    # 2. Check environment variables
    check_environment
    echo ""

    # 3. Check service status
    check_services
    echo ""

    # 4. API endpoint testing
    echo "=================================================="
    echo "🧪 API ENDPOINT TESTING"
    echo "=================================================="

    test_api_endpoint "localhost" "none"
    echo ""

    test_api_endpoint "diz.zone" "diz.zone"
    echo ""

    test_api_endpoint "webui.diz.zone" "webui.diz.zone"
    echo ""

    # 5. Primary interface testing
    echo "=================================================="
    echo "🌐 MAIN INTERFACE TESTING"
    echo "=================================================="

    test_main_interface "localhost" "none"
    echo ""

    test_main_interface "diz.zone" "diz.zone"
    echo ""

    test_main_interface "webui.diz.zone" "webui.diz.zone"
    echo ""

    # 6. Check logs
    check_logs
    echo ""

    # 7. Simulate problem
    simulate_problem
    echo ""

    # 8. Recommendations
    echo "=================================================="
    echo "💡 RECOMMENDATIONS"
    echo "=================================================="

    echo "1. If all API endpoints work, the problem might be:"
    echo "   - In the browser (cache, cookies)"
    echo "   - In Cloudflare settings"
    echo "   - In web interface authentication"
    echo ""

    echo "2. For further diagnosis:"
    echo "   - Check Network tab in browser"
    echo "   - Clear browser cache"
    echo "   - Check Cloudflare logs"
    echo ""

    echo "3. If the problem persists:"
    echo "   - Save the exact HTTP request from the browser"
    echo "   - Check authentication headers"
    echo "   - Compare with working requests"

    # Save report
    local report_file="websearch_diagnosis_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "Web Search Domain Diagnosis Report"
        echo "Generated: $(date)"
        echo "======================================"
        echo ""
        echo "SUMMARY:"
        echo "- API endpoints tested: localhost, diz.zone, webui.diz.zone"
        echo "- Configuration checked: Nginx, OpenWebUI environment"
        echo "- Services status verified"
        echo ""
        echo "For detailed results, see terminal output above."
    } > "$report_file"

    log_info "Report saved to: $report_file"
}

# Run diagnosis
main "$@"
