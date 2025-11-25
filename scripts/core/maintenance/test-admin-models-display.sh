#!/bin/bash

# ERNI-KI Admin Models Display Test Script
# Tests model visibility in the OpenWebUI admin panel

set -euo pipefail

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ADMIN_URL="https://192.168.62.140/admin/settings/models"
LOCAL_URL="http://localhost:8080"

echo -e "${BLUE}🔍 ERNI-KI Admin Models Display Test${NC}"
echo "=================================================="

# Check a single API endpoint
test_api_endpoint() {
    local endpoint=$1
    local description=$2

    echo -n "Testing $description... "

    local response=$(curl -s --max-time 10 "$LOCAL_URL$endpoint" 2>/dev/null || echo "ERROR")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$LOCAL_URL$endpoint" 2>/dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ OK (HTTP $http_code)${NC}"
        return 0
    elif [ "$http_code" = "403" ]; then
        echo -e "${YELLOW}⚠️ Authentication required (HTTP $http_code)${NC}"
        return 1
    else
        echo -e "${RED}❌ Failed (HTTP $http_code)${NC}"
        return 2
    fi
}

# Core tests
echo -e "\n${BLUE}📊 API Endpoints Tests${NC}"
echo "----------------------"

total_tests=0
passed_tests=0

# Main page test
((total_tests++))
if test_api_endpoint "/" "Main page"; then
    ((passed_tests++))
fi

# Health endpoint test
((total_tests++))
if test_api_endpoint "/health" "Health check"; then
    ((passed_tests++))
fi

# Ollama config test
((total_tests++))
if test_api_endpoint "/ollama/config" "Ollama config"; then
    if [ $? -eq 1 ]; then ((passed_tests++)); fi  # 403 is expected without auth
fi

# Models API test
((total_tests++))
if test_api_endpoint "/api/models" "Models API"; then
    if [ $? -eq 1 ]; then ((passed_tests++)); fi  # 403 is expected without auth
fi

# Provider checks
echo -e "\n${BLUE}🔗 Provider Integration Tests${NC}"
echo "------------------------------"

# Ollama check via container
((total_tests++))
echo -n "Testing Ollama integration... "
if docker exec erni-ki-openwebui-1 curl -s --max-time 5 "http://ollama:11434/api/tags" | grep -q "models"; then
    echo -e "${GREEN}✅ OK${NC}"
    ((passed_tests++))
else
    echo -e "${RED}❌ Failed${NC}"
fi

# LiteLLM check via container
((total_tests++))
echo -n "Testing LiteLLM integration... "
if docker exec erni-ki-openwebui-1 curl -s --max-time 5 -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" "http://litellm:4000/v1/models" | grep -q "data"; then
    echo -e "${GREEN}✅ OK${NC}"
    ((passed_tests++))
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Database checks
echo -e "\n${BLUE}💾 Database Tests${NC}"
echo "------------------"

# Models in DB test
((total_tests++))
echo -n "Testing models in database... "
model_count=$(docker exec erni-ki-openwebui-1 python -c "
import os, psycopg2
try:
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM model')
    count = cursor.fetchone()[0]
    conn.close()
    print(count)
except: print(0)
" 2>/dev/null)

if [ "$model_count" -gt 0 ]; then
    echo -e "${GREEN}✅ OK ($model_count models)${NC}"
    ((passed_tests++))
else
    echo -e "${RED}❌ No models found${NC}"
fi

# Config in DB test
((total_tests++))
echo -n "Testing config in database... "
config_check=$(docker exec erni-ki-openwebui-1 python -c "
import os, psycopg2, json
try:
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    cursor = conn.cursor()
    cursor.execute('SELECT data FROM config WHERE id = 1')
    result = cursor.fetchone()
    if result:
        data = result[0]
        ollama_enabled = data.get('ollama', {}).get('enable', False)
        openai_enabled = data.get('openai', {}).get('enable', False)
        print(f'ollama:{ollama_enabled},openai:{openai_enabled}')
    else:
        print('no_config')
    conn.close()
except Exception as e: print(f'error:{e}')
" 2>/dev/null)

if [[ "$config_check" == *"ollama:True"* ]] && [[ "$config_check" == *"openai:True"* ]]; then
    echo -e "${GREEN}✅ OK (Providers enabled)${NC}"
    ((passed_tests++))
else
    echo -e "${RED}❌ Config issues: $config_check${NC}"
fi

# Admin panel availability
echo -e "\n${BLUE}🔒 Admin Panel Access${NC}"
echo "---------------------"

((total_tests++))
echo -n "Testing admin panel access... "
admin_status=$(curl -s -o /dev/null -w "%{http_code}" "$ADMIN_URL" --connect-timeout 10 -k 2>/dev/null || echo "000")

if [ "$admin_status" = "200" ]; then
    echo -e "${GREEN}✅ OK (HTTP $admin_status)${NC}"
    ((passed_tests++))
elif [ "$admin_status" = "302" ] || [ "$admin_status" = "401" ]; then
    echo -e "${YELLOW}⚠️ Authentication required (HTTP $admin_status)${NC}"
    ((passed_tests++))
else
    echo -e "${RED}❌ Failed (HTTP $admin_status)${NC}"
fi

# Summary
echo -e "\n${BLUE}📋 Test Summary${NC}"
echo "==============="
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $((total_tests - passed_tests))"

success_rate=$((passed_tests * 100 / total_tests))
echo "Success rate: $success_rate%"

echo -e "\n${BLUE}📝 Instructions for Admin Panel${NC}"
echo "================================="
echo "1. Open a browser and go to:"
echo "   ${ADMIN_URL}"
echo ""
echo "2. Sign in as administrator:"
echo "   Email: diz-admin@proton.me"
echo "   Password: [your password]"
echo ""
echo "3. In Admin > Settings > Models you should see:"
echo "   - 5 Ollama models (qwen2.5:0.5b, phi4-mini-reasoning:3.8b, etc.)"
echo "   - 3 LiteLLM models (local-phi4-mini, local-deepseek-r1, local-gemma3n)"
echo ""
echo "4. If models are missing, check:"
echo "   - Connections in Admin > Settings > Connections"
echo "   - Ollama connection: http://ollama:11434"
echo "   - OpenAI connection: http://litellm:4000/v1"

if [ $success_rate -ge 90 ]; then
    echo -e "\n${GREEN}🎉 Admin models setup: EXCELLENT${NC}"
    exit 0
elif [ $success_rate -ge 75 ]; then
    echo -e "\n${YELLOW}⚠️ Admin models setup: GOOD${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Admin models setup: NEEDS ATTENTION${NC}"
    exit 1
fi
