#!/bin/bash

# RAG Health Monitor Script
# Checks ERNI-KI RAG system health and performance
# Author: Augment Agent
# Date: 2025-10-24

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Colors

# Thresholds (milliseconds)
SEARXNG_THRESHOLD=2000  # 2 seconds
PGVECTOR_THRESHOLD=100  # 100 ms

mkdir -p logs

# Service status check
check_status() {
    local service=$1
    local status
    status=$(docker ps --filter "name=$service" --format "{{.Status}}" 2>/dev/null || echo "not found")

    if echo "$status" | grep -q "healthy"; then
        echo -e "${GREEN}✅ healthy${NC}"
        return 0
    elif echo "$status" | grep -q "Up"; then
        echo -e "${YELLOW}⚠️  up (no healthcheck)${NC}"
        return 1
    else
        echo -e "${RED}❌ unhealthy${NC}"
        return 2
    fi
}

# Response time measurement
measure_response_time() {
    local url=$1
    local start end response duration
    start=$(date +%s%3N)
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    end=$(date +%s%3N)
    duration=$((end - start))

    echo "$duration|$response"
}

# Header
echo ""
echo "========================================="
echo "   RAG HEALTH MONITOR - ERNI-KI"
echo "========================================="
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

log_info "=== RAG Health Check Started ==="

# 1. Service status
echo -e "${BLUE}1. RAG SERVICES STATUS${NC}"
echo "-----------------------------------"

services=("erni-ki-openwebui-1" "erni-ki-searxng-1" "erni-ki-db-1" "erni-ki-ollama-1" "erni-ki-nginx-1")
all_healthy=true

for service in "${services[@]}"; do
    service_name=$(echo "$service" | sed 's/erni-ki-//;s/-1//')
    printf "%-15s: " "$service_name"
    if ! check_status "$service"; then
        all_healthy=false
    fi
done

echo ""

# 2. SearXNG performance
echo -e "${BLUE}2. SEARXNG PERFORMANCE${NC}"
echo "-----------------------------------"

result=$(measure_response_time "http://localhost:8080/api/searxng/search?q=test&format=json")
duration=$(echo "$result" | cut -d'|' -f1)
http_code=$(echo "$result" | cut -d'|' -f2)

printf "Response Time: %d ms " "$duration"
if [ "$duration" -lt "$SEARXNG_THRESHOLD" ]; then
    echo -e "${GREEN}✅ (< ${SEARXNG_THRESHOLD}ms)${NC}"
    log_info "SearXNG: ${duration}ms - OK"
else
    echo -e "${RED}❌ (>= ${SEARXNG_THRESHOLD}ms)${NC}"
    log_info "SearXNG: ${duration}ms - SLOW"
    all_healthy=false
fi

printf "HTTP Status:   %s " "$http_code"
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    all_healthy=false
fi

echo ""

# 3. pgvector performance
echo -e "${BLUE}3. PGVECTOR PERFORMANCE${NC}"
echo "-----------------------------------"

pg_result=$(docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "\timing on" -c "SELECT COUNT(*) FROM document_chunk;" 2>&1 | grep "Time:" | awk '{print $2}' | sed 's/ ms//')

if [ -n "$pg_result" ]; then
    pg_duration=$(echo "$pg_result" | awk '{printf "%.0f", $1}')
    printf "Query Time:    %d ms " "$pg_duration"

    if [ "$pg_duration" -lt "$PGVECTOR_THRESHOLD" ]; then
        echo -e "${GREEN}✅ (< ${PGVECTOR_THRESHOLD}ms)${NC}"
        log_info "pgvector: ${pg_duration}ms - OK"
    else
        echo -e "${RED}❌ (>= ${PGVECTOR_THRESHOLD}ms)${NC}"
        log_info "pgvector: ${pg_duration}ms - SLOW"
        all_healthy=false
    fi
else
    echo -e "${RED}❌ Failed to query${NC}"
    all_healthy=false
fi

# Vector stats
chunk_count=$(docker exec erni-ki-db-1 psql -U postgres -d openwebui -t -c "SELECT COUNT(*) FROM document_chunk;" 2>/dev/null | tr -d ' ')
collection_count=$(docker exec erni-ki-db-1 psql -U postgres -d openwebui -t -c "SELECT COUNT(DISTINCT collection_name) FROM document_chunk;" 2>/dev/null | tr -d ' ')

echo "Total Chunks:  $chunk_count"
echo "Collections:   $collection_count"

echo ""

# 4. Ollama
echo -e "${BLUE}4. OLLAMA EMBEDDING MODEL${NC}"
echo "-----------------------------------"

ollama_models=$(docker exec erni-ki-ollama-1 ollama list 2>/dev/null | grep "nomic-embed" || echo "")
if [ -n "$ollama_models" ]; then
    echo -e "${GREEN}✅ nomic-embed-text:latest available${NC}"
    log_info "Ollama: nomic-embed model available"
else
    echo -e "${RED}❌ nomic-embed-text:latest not found${NC}"
    log_info "Ollama: nomic-embed model missing"
    all_healthy=false
fi

echo ""

# 5. Nginx caching
echo -e "${BLUE}5. NGINX CACHING${NC}"
echo "-----------------------------------"

# First request (cold)
CACHE_QUERY="cache-test-query"
result1=$(measure_response_time "http://localhost:8080/api/searxng/search?q=${CACHE_QUERY}&format=json")
duration1=$(echo "$result1" | cut -d'|' -f1)

# Second request (should be cached - same query)
sleep 1
result2=$(measure_response_time "http://localhost:8080/api/searxng/search?q=${CACHE_QUERY}&format=json")
duration2=$(echo "$result2" | cut -d'|' -f1)

echo "First Request:  ${duration1}ms"
echo "Second Request: ${duration2}ms"

if [ "$duration2" -lt "$duration1" ]; then
    speedup=$((duration1 / duration2))
    echo -e "${GREEN}✅ Caching works (${speedup}x faster)${NC}"
    log_info "Nginx caching: ${speedup}x speedup"
else
    echo -e "${YELLOW}⚠️  Caching may not be working${NC}"
    log_info "Nginx caching: No speedup detected"
fi

echo ""

# 7. Final status
echo "========================================="
if $all_healthy; then
    echo -e "${GREEN}✅ RAG SYSTEM HEALTHY${NC}"
    log_info "=== RAG Health Check: PASSED ==="
    exit 0
else
    echo -e "${RED}❌ RAG SYSTEM HAS ISSUES${NC}"
    log_info "=== RAG Health Check: FAILED ==="
    exit 1
fi
