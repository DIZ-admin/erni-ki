#!/bin/bash

# ERNI-KI Quick MCPO Health Check Script
# Rapid MCPO service and integration health check

set -euo pipefail

# Output color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 ERNI-KI Quick MCPO Health Check${NC}"
echo "=========================================="

# Function to check an endpoint
check_endpoint() {
    local url=$1
    local description=$2
    local timeout=${3:-5}

    echo -n "Checking $description... "

    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

# Function to test an MCP tool
test_tool() {
    local url=$1
    local payload=$2
    local description=$3

    echo -n "Testing $description... "

    local response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --max-time 10 2>/dev/null || echo '{"error": "failed"}')

    if echo "$response" | jq -e . >/dev/null 2>&1 && ! echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

total_checks=0
passed_checks=0

# 1. Container status check
echo -e "\n${BLUE}🐳 Container Status${NC}"
echo "==================="

if docker-compose ps mcposerver | grep -q "healthy"; then
    echo -e "MCPO Server: ${GREEN}✅ Healthy${NC}"
    ((passed_checks++))
else
    echo -e "MCPO Server: ${RED}❌ Unhealthy${NC}"
fi
((total_checks++))

# 2. Core endpoint checks
echo -e "\n${BLUE}🌐 API Endpoints${NC}"
echo "================"

((total_checks++))
if check_endpoint "http://localhost:8000/docs" "MCPO Swagger UI"; then
    ((passed_checks++))
fi

((total_checks++))
if check_endpoint "http://localhost:8000/openapi.json" "MCPO OpenAPI spec"; then
    ((passed_checks++))
fi

# 3. MCP server checks
echo -e "\n${BLUE}⚙️ MCP Servers${NC}"
echo "==============="

for server in time postgres filesystem memory searxng; do
    ((total_checks++))
    if check_endpoint "http://localhost:8000/$server/docs" "$server server"; then
        ((passed_checks++))
    fi
done

# 4. Functional tests
echo -e "\n${BLUE}🔧 Functional Tests${NC}"
echo "==================="

((total_checks++))
if test_tool "http://localhost:8000/time/get_current_time" '{"timezone": "Europe/Berlin"}' "Time server functionality"; then
    ((passed_checks++))
fi

((total_checks++))
if test_tool "http://localhost:8000/postgres/query" '{"sql": "SELECT 1;"}' "PostgreSQL server functionality"; then
    ((passed_checks++))
fi

((total_checks++))
if test_tool "http://localhost:8000/memory/read_graph" '{}' "Memory server functionality"; then
    ((passed_checks++))
fi

# 5. Nginx proxy check
echo -e "\n${BLUE}🌐 Nginx Proxy${NC}"
echo "==============="

((total_checks++))
if check_endpoint "http://localhost:8080/api/mcp/time/docs" "Nginx proxy to Time server"; then
    ((passed_checks++))
fi

# 6. Performance verification
echo -e "\n${BLUE}⚡ Performance${NC}"
echo "=============="

echo -n "Testing API response time... "
start_time=$(date +%s%3N)
curl -s "http://localhost:8000/docs" > /dev/null 2>&1
end_time=$(date +%s%3N)
response_time=$((end_time - start_time))

if [ $response_time -lt 2000 ]; then
    echo -e "${GREEN}✅ ${response_time}ms${NC}"
    ((passed_checks++))
else
    echo -e "${YELLOW}⚠️ ${response_time}ms (slow)${NC}"
fi
((total_checks++))

# 7. Error log scan
echo -e "\n${BLUE}📋 Error Check${NC}"
echo "==============="

echo -n "Checking for errors in logs... "
error_count=$(docker logs erni-ki-mcposerver-1 --tail=50 2>/dev/null | grep -c -E "(ERROR|error|Error|FATAL|fatal|Exception)" || echo "0")

if [ "$error_count" -eq 0 ]; then
    echo -e "${GREEN}✅ No errors${NC}"
    ((passed_checks++))
else
    echo -e "${YELLOW}⚠️ $error_count errors found${NC}"
fi
((total_checks++))

# 8. Final summary
echo -e "\n${BLUE}📊 Summary${NC}"
echo "=========="

success_rate=$((passed_checks * 100 / total_checks))

echo "Total checks: $total_checks"
echo "Passed: $passed_checks"
echo "Failed: $((total_checks - passed_checks))"
echo "Success rate: $success_rate%"

echo -e "\n${BLUE}🎯 MCPO Status${NC}"
echo "=============="

if [ $success_rate -ge 90 ]; then
    echo -e "${GREEN}🎉 MCPO System: EXCELLENT${NC}"
    echo "✅ All systems operational"
    echo "✅ Ready for production use"
elif [ $success_rate -ge 75 ]; then
    echo -e "${YELLOW}⚠️ MCPO System: GOOD${NC}"
    echo "✅ Core functionality working"
    echo "⚠️ Some minor issues detected"
elif [ $success_rate -ge 50 ]; then
    echo -e "${YELLOW}⚠️ MCPO System: NEEDS ATTENTION${NC}"
    echo "⚠️ Multiple issues detected"
    echo "🔧 Troubleshooting recommended"
else
    echo -e "${RED}❌ MCPO System: CRITICAL${NC}"
    echo "❌ Major issues detected"
    echo "🚨 Immediate attention required"
fi

echo -e "\n${BLUE}🔧 Quick Actions${NC}"
echo "================"

if [ $success_rate -lt 90 ]; then
    echo "1. Check detailed logs: docker-compose logs mcposerver"
    echo "2. Restart MCPO server: docker-compose restart mcposerver"
    echo "3. Run full diagnostics: ./scripts/mcp/comprehensive-mcpo-diagnostics.sh"
    echo "4. Check configuration: cat conf/mcposerver/config.json"
fi

echo -e "\n${BLUE}📚 Documentation${NC}"
echo "=================="
echo "📖 Full integration guide: docs/reference/mcpo-integration-guide.md"
echo "🌐 MCPO Swagger UI: http://localhost:8000/docs"
echo "🔧 Test individual tools: http://localhost:8000/{server}/docs"

# Return error code if issues persist
if [ $success_rate -lt 75 ]; then
    exit 1
else
    exit 0
fi
