#!/bin/bash
# ERNI-KI Network Diagnostics Script
# Automatic diagnostics of network issues between nginx and backend services

set -e

echo "🔍 ERNI-KI Network Diagnostics - $(date)"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service availability
check_service() {
    local service_name=$1
    local service_ip=$2
    local service_port=$3
    local endpoint=${4:-"/"}

    echo -n "Testing $service_name ($service_ip:$service_port)... "

    if docker exec erni-ki-nginx-1 curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$service_ip:$service_port$endpoint" | grep -q "200\|302\|404\|401"; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Function to check DNS resolution
check_dns() {
    local hostname=$1
    echo -n "DNS resolution for $hostname... "

    if docker exec erni-ki-nginx-1 curl -s -o /dev/null --connect-timeout 2 "http://$hostname:8080/" 2>/dev/null; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# 1. Check container status
echo "1. Container Status Check"
echo "------------------------"
healthy_count=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "healthy" | wc -l)
total_count=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v "NAMES" | wc -l)
echo "Healthy containers: $healthy_count/$total_count"

if [ "$healthy_count" -lt 20 ]; then
    echo -e "${YELLOW}⚠ Warning: Some containers are not healthy${NC}"
fi

# 2. Get current IP addresses
echo -e "\n2. Current IP Addresses"
echo "----------------------"
nginx_ip=$(docker inspect erni-ki-nginx-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
openwebui_ip=$(docker inspect erni-ki-openwebui-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
searxng_ip=$(docker inspect erni-ki-searxng-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
auth_ip=$(docker inspect erni-ki-auth-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
redis_ip=$(docker inspect erni-ki-redis-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
litellm_ip=$(docker inspect erni-ki-litellm --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

echo "nginx: $nginx_ip"
echo "openwebui: $openwebui_ip"
echo "searxng: $searxng_ip"
echo "auth: $auth_ip"
echo "redis: $redis_ip"
echo "litellm: $litellm_ip"

# 3. Check inter-container connectivity
echo -e "\n3. Inter-container Connectivity"
echo "------------------------------"
failed_services=0

check_service "OpenWebUI" "$openwebui_ip" "8080" "/health" || ((failed_services++))
check_service "SearXNG" "$searxng_ip" "8080" "/" || ((failed_services++))
check_service "Auth" "$auth_ip" "9090" "/" || ((failed_services++))
check_service "Redis" "$redis_ip" "8001" "/" || ((failed_services++))
check_service "LiteLLM" "$litellm_ip" "4000" "/health" || ((failed_services++))

# 4. Check DNS resolution
echo -e "\n4. DNS Resolution Check"
echo "----------------------"
check_dns "openwebui" || ((failed_services++))
check_dns "searxng" || ((failed_services++))
check_dns "auth" || ((failed_services++))
check_dns "redis" || ((failed_services++))
check_dns "litellm" || ((failed_services++))

# 5. Check HTTPS endpoints
echo -e "\n5. HTTPS Endpoints Check"
echo "-----------------------"
echo -n "HTTPS Health Check... "
if curl -s -k -o /dev/null -w "%{http_code}" --connect-timeout 5 https://localhost/api/health | grep -q "200"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    ((failed_services++))
fi

echo -n "HTTPS Main Page... "
if curl -s -k -o /dev/null -w "%{http_code}" --connect-timeout 5 https://localhost/ | grep -q "200"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    ((failed_services++))
fi

# 6. Check Cloudflare tunnel
echo -e "\n6. Cloudflare Tunnel Check"
echo "-------------------------"
echo -n "Port 8080 Access... "
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:8080/ | grep -q "200"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    ((failed_services++))
fi

# 7. Check nginx logs for errors
echo -e "\n7. Recent Nginx Errors"
echo "---------------------"
recent_errors=$(docker logs erni-ki-nginx-1 --since="5m" 2>/dev/null | grep -E "(error|timeout|upstream)" | wc -l)
if [ "$recent_errors" -eq 0 ]; then
    echo -e "${GREEN}✓ No recent errors found${NC}"
else
    echo -e "${YELLOW}⚠ Found $recent_errors recent errors${NC}"
    docker logs erni-ki-nginx-1 --since="5m" 2>/dev/null | grep -E "(error|timeout|upstream)" | tail -3
fi

# Final report
echo -e "\n📊 SUMMARY"
echo "=========="
if [ "$failed_services" -eq 0 ]; then
    echo -e "${GREEN}✅ All systems operational${NC}"
    echo "ERNI-KI network is healthy and all services are accessible."
else
    echo -e "${RED}❌ $failed_services service(s) failed${NC}"
    echo "Network issues detected. Check the failed services above."
fi

echo -e "\n🔧 TROUBLESHOOTING TIPS"
echo "======================"
echo "1. If DNS resolution fails: restart affected containers"
echo "2. If IP connectivity fails: check Docker network configuration"
echo "3. If HTTPS fails: check nginx upstream configuration"
echo "4. If all fails: run 'docker-compose restart nginx'"

exit $failed_services
