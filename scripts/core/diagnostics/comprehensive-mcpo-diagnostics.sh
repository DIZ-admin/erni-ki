#!/bin/bash

# ERNI-KI MCPO Comprehensive Diagnostics Script
# Complete diagnostics for the MCPO service and OpenWebUI integration

set -euo pipefail

# Output color palette
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MCPO_URL="http://localhost:8000"
NGINX_PROXY_URL="http://localhost:8080/api/mcp"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
REPORT_FILE=".config-backup/mcpo-diagnostics-${TIMESTAMP}.txt"

echo -e "${BLUE}🔍 ERNI-KI MCPO Comprehensive Diagnostics${NC}"
echo -e "${CYAN}Date: $(date)${NC}"
echo "=============================================================="

# Ensure report directory exists
mkdir -p .config-backup

# Logging helper
log_result() {
    echo "$1" | tee -a "$REPORT_FILE"
}

# Detailed endpoint verification helper
test_endpoint_detailed() {
    local url=$1
    local description=$2
    local timeout=${3:-10}

    echo -n "Testing $description... "

    local start_time=$(date +%s%3N)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time $timeout "$url" 2>/dev/null || echo "000")
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ OK (${response_time}ms)${NC}"
        log_result "✅ $description: OK (${response_time}ms)"
        return 0
    elif [ "$http_code" = "404" ]; then
        echo -e "${YELLOW}⚠️ Not Found${NC}"
        log_result "⚠️ $description: Not Found"
        return 1
    else
        echo -e "${RED}❌ HTTP $http_code (${response_time}ms)${NC}"
        log_result "❌ $description: HTTP $http_code (${response_time}ms)"
        return 2
    fi
}

# MCP tool testing helper
test_mcp_tool() {
    local server=$1
    local endpoint=$2
    local payload=$3
    local description=$4

    echo -n "Testing $description... "

    local start_time=$(date +%s%3N)
    local response=$(curl -s -X POST "$MCPO_URL/$server/$endpoint" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --max-time 10 2>/dev/null || echo '{"error": "request_failed"}')
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))

    if echo "$response" | jq -e . >/dev/null 2>&1 && ! echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OK (${response_time}ms)${NC}"
        log_result "✅ $description: OK (${response_time}ms)"
        return 0
    else
        echo -e "${RED}❌ Failed (${response_time}ms)${NC}"
        log_result "❌ $description: Failed (${response_time}ms) - $response"
        return 1
    fi
}

total_tests=0
passed_tests=0

log_result "ERNI-KI MCPO Comprehensive Diagnostics Report"
log_result "Generated: $(date)"
log_result "=============================================================="

# 1. Container status checks
echo -e "\n${BLUE}🐳 Container Status Check${NC}"
echo "=========================="

echo "MCPO Server Status:"
docker-compose ps mcposerver | tee -a "$REPORT_FILE"

echo -e "\nOpenWebUI Status:"
docker-compose ps openwebui | tee -a "$REPORT_FILE"

echo -e "\nNginx Status:"
docker-compose ps nginx | tee -a "$REPORT_FILE"

# 2. Health check calls
echo -e "\n${BLUE}🏥 Health Checks${NC}"
echo "================"

((total_tests++))
if test_endpoint_detailed "$MCPO_URL/docs" "MCPO Swagger UI"; then
    ((passed_tests++))
fi

((total_tests++))
if test_endpoint_detailed "$MCPO_URL/openapi.json" "MCPO OpenAPI spec"; then
    ((passed_tests++))
fi

# 3. Individual MCP server checks
echo -e "\n${BLUE}⚙️ Individual MCP Servers${NC}"
echo "=========================="

# Fetch available MCP servers
echo "Available MCP servers:"
servers=$(curl -s "$MCPO_URL/openapi.json" 2>/dev/null | jq -r '.info.description' | grep -oE '\[([^]]+)\]' | tr -d '[]' | tr ',' '\n' | sed 's/^ *//' || echo "")

if [ -n "$servers" ]; then
    echo "$servers" | tee -a "$REPORT_FILE"

# Testing each MCP server
    for server in time postgres filesystem memory searxng; do
        echo -e "\n--- $server server ---"

        ((total_tests++))
        if test_endpoint_detailed "$MCPO_URL/$server/docs" "$server server docs"; then
            ((passed_tests++))
        fi

        ((total_tests++))
        if test_endpoint_detailed "$MCPO_URL/$server/openapi.json" "$server server OpenAPI"; then
            ((passed_tests++))
        fi

# Counting available tools
        tools_count=$(curl -s "$MCPO_URL/$server/openapi.json" 2>/dev/null | jq '.paths | keys | length' 2>/dev/null || echo "0")
        echo "Available tools: $tools_count" | tee -a "$REPORT_FILE"
    done
else
    echo -e "${YELLOW}⚠️ No servers information available${NC}"
fi

# 4. Functional tool testing
echo -e "\n${BLUE}🔧 Functional Tool Testing${NC}"
echo "==========================="

# Time server test
((total_tests++))
if test_mcp_tool "time" "get_current_time" '{"timezone": "Europe/Berlin"}' "Time server functionality"; then
    ((passed_tests++))
fi

# Postgres server test
((total_tests++))
if test_mcp_tool "postgres" "query" '{"sql": "SELECT version();"}' "Postgres server functionality"; then
    ((passed_tests++))
fi

# Memory server test
((total_tests++))
if test_mcp_tool "memory" "read_graph" '{}' "Memory server functionality"; then
    ((passed_tests++))
fi

# 5. Nginx proxy integration
echo -e "\n${BLUE}🌐 Nginx Proxy Integration${NC}"
echo "=========================="

for server in time postgres filesystem memory; do
    ((total_tests++))
    if test_endpoint_detailed "$NGINX_PROXY_URL/$server/docs" "Nginx proxy to $server"; then
        ((passed_tests++))
    fi
done

# 6. Log analysis
echo -e "\n${BLUE}📋 Log Analysis${NC}"
echo "================"

echo "MCPO Server logs (last 20 lines):" | tee -a "$REPORT_FILE"
docker-compose logs --tail=20 mcposerver | tee -a "$REPORT_FILE"

echo -e "\nChecking for errors in MCPO logs..."
error_count=$(docker logs erni-ki-mcposerver-1 --tail=100 2>/dev/null | grep -c -E "(ERROR|error|Error|FATAL|fatal|Exception)" || echo "0")
if [ "$error_count" -eq 0 ]; then
    echo -e "${GREEN}✅ No errors found${NC}"
    log_result "✅ MCPO logs: No errors found"
    ((passed_tests++))
else
    echo -e "${YELLOW}⚠️ $error_count errors found${NC}"
    log_result "⚠️ MCPO logs: $error_count errors found"
fi
((total_tests++))

# 7. Performance Analysis
echo -e "\n${BLUE}⚡ Performance Analysis${NC}"
echo "======================"

echo "Testing API response times..."
for endpoint in "docs" "openapi.json" "time/docs" "postgres/docs"; do
    start_time=$(date +%s%3N)
    curl -s "$MCPO_URL/$endpoint" > /dev/null 2>&1
    end_time=$(date +%s%3N)
    response_time=$((end_time - start_time))

    if [ $response_time -lt 2000 ]; then
        echo -e "  $endpoint: ${GREEN}${response_time}ms${NC}"
        log_result "✅ $endpoint response time: ${response_time}ms"
    else
        echo -e "  $endpoint: ${YELLOW}${response_time}ms (slow)${NC}"
        log_result "⚠️ $endpoint response time: ${response_time}ms (slow)"
    fi
done

# 8. OpenWebUI Integration Check
echo -e "\n${BLUE}🔗 OpenWebUI Integration${NC}"
echo "========================"

echo "Checking TOOL_SERVER_CONNECTIONS configuration..."
if docker-compose exec -T openwebui env | grep -q "TOOL_SERVER_CONNECTIONS"; then
    echo -e "${GREEN}✅ TOOL_SERVER_CONNECTIONS configured${NC}"
    log_result "✅ TOOL_SERVER_CONNECTIONS: Configured"
    ((passed_tests++))
else
    echo -e "${RED}❌ TOOL_SERVER_CONNECTIONS not found${NC}"
    log_result "❌ TOOL_SERVER_CONNECTIONS: Not found"
fi
((total_tests++))

# 9. Final report summary
echo -e "\n${BLUE}📊 Diagnostic Summary${NC}"
echo "====================="

success_rate=$((passed_tests * 100 / total_tests))

echo "Total tests: $total_tests" | tee -a "$REPORT_FILE"
echo "Passed: $passed_tests" | tee -a "$REPORT_FILE"
echo "Failed: $((total_tests - passed_tests))" | tee -a "$REPORT_FILE"
echo "Success rate: $success_rate%" | tee -a "$REPORT_FILE"

echo -e "\n${BLUE}🎯 MCPO System Status${NC}" | tee -a "$REPORT_FILE"
echo "=====================" | tee -a "$REPORT_FILE"

if [ $success_rate -ge 90 ]; then
    echo -e "${GREEN}🎉 MCPO System: EXCELLENT${NC}" | tee -a "$REPORT_FILE"
    echo "✅ MCPO server is healthy and responsive" | tee -a "$REPORT_FILE"
    echo "✅ All MCP tools are functional" | tee -a "$REPORT_FILE"
    echo "✅ Nginx proxy integration working" | tee -a "$REPORT_FILE"
    echo "✅ OpenWebUI integration configured" | tee -a "$REPORT_FILE"
elif [ $success_rate -ge 75 ]; then
    echo -e "${YELLOW}⚠️ MCPO System: GOOD${NC}" | tee -a "$REPORT_FILE"
    echo "✅ MCPO server is running" | tee -a "$REPORT_FILE"
    echo "⚠️ Some MCP tools may need attention" | tee -a "$REPORT_FILE"
    echo "✅ Basic integration working" | tee -a "$REPORT_FILE"
elif [ $success_rate -ge 50 ]; then
    echo -e "${YELLOW}⚠️ MCPO System: NEEDS ATTENTION${NC}" | tee -a "$REPORT_FILE"
    echo "⚠️ MCPO server has issues" | tee -a "$REPORT_FILE"
    echo "⚠️ Multiple MCP tools failing" | tee -a "$REPORT_FILE"
    echo "⚠️ Integration partially working" | tee -a "$REPORT_FILE"
else
    echo -e "${RED}❌ MCPO System: CRITICAL${NC}" | tee -a "$REPORT_FILE"
    echo "❌ Major issues detected" | tee -a "$REPORT_FILE"
    echo "❌ System requires immediate attention" | tee -a "$REPORT_FILE"
fi

echo -e "\n${BLUE}📝 Recommendations${NC}" | tee -a "$REPORT_FILE"
echo "==================" | tee -a "$REPORT_FILE"

if [ $success_rate -lt 90 ]; then
    echo "1. Check MCPO server logs for detailed error information" | tee -a "$REPORT_FILE"
    echo "2. Verify MCP server configurations in conf/mcposerver/config.json" | tee -a "$REPORT_FILE"
    echo "3. Test individual MCP tools manually" | tee -a "$REPORT_FILE"
    echo "4. Restart MCPO server if necessary: docker-compose restart mcposerver" | tee -a "$REPORT_FILE"
fi

echo -e "\n${BLUE}📄 Full report saved to: ${REPORT_FILE}${NC}"

exit $((total_tests - passed_tests))
