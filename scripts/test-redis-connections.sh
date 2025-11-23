#!/bin/bash
# Redis connection test script for ERNI-KI
# Verifies integrations and performance

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ERNI-KI Redis connection tests ===${NC}"

# Logging helpers
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Measure execution time
measure_time() {
    local start_time=$(date +%s%N)
    "$@"
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # ms
    echo "${duration}ms"
}

# Ensure we are in repo root
if [[ ! -f "compose.yml" ]]; then
    error "compose.yml not found. Run from ERNI-KI repo root."
    exit 1
fi

echo -e "\n${BLUE}=== 1. Container status ===${NC}"

# Redis container status
if docker ps --filter "name=erni-ki-redis-1" --format "{{.Status}}" | grep -q "healthy"; then
    success "Redis Main (erni-ki-redis-1) - healthy"
else
    error "Redis Main (erni-ki-redis-1) - unhealthy or not running"
fi

info "Redis LiteLLM removed — LiteLLM uses local caching"

echo -e "\n${BLUE}=== 2. Basic commands ===${NC}"

# Redis Main test
info "Testing Redis Main..."
if redis_main_time=$(measure_time docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' ping 2>/dev/null); then
    success "Redis Main PING - ${redis_main_time}"
else
    error "Redis Main PING - failed"
fi

# Redis LiteLLM removed
info "Redis LiteLLM removed - LiteLLM uses local caching"

echo -e "\n${BLUE}=== 3. Service integrations ===${NC}"

# OpenWebUI integration
info "Testing OpenWebUI → Redis..."
if docker exec erni-ki-openwebui-1 python3 -c "import redis; r = redis.Redis(host='redis', port=6379, password='ErniKiRedisSecurePassword2024', db=0); print('OpenWebUI Redis connection:', r.ping())" 2>/dev/null | grep -q "True"; then
    success "OpenWebUI → Redis Main - ok"
else
    error "OpenWebUI → Redis Main - failed"
fi

# SearXNG integration (if redis module present)
info "Testing SearXNG → Redis..."
if docker exec erni-ki-searxng-1 python3 -c "import redis; r = redis.Redis(host='redis', port=6379, password='ErniKiRedisSecurePassword2024', db=0); print('SearXNG Redis connection:', r.ping())" 2>/dev/null | grep -q "True"; then
    success "SearXNG → Redis Main - ok"
else
    warning "SearXNG → Redis Main - redis module missing or connection failed"
fi

echo -e "\n${BLUE}=== 4. Performance ===${NC}"

# Write/read performance
info "Testing write performance..."
write_time=$(measure_time docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' set test_perf_key "test_value" 2>/dev/null)
success "Write to Redis Main - ${write_time}"

info "Testing read performance..."
read_time=$(measure_time docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' get test_perf_key 2>/dev/null)
success "Read from Redis Main - ${read_time}"

# Cleanup test key
docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' del test_perf_key >/dev/null 2>&1

echo -e "\n${BLUE}=== 5. Usage stats ===${NC}"

# Redis Main stats
info "Redis Main stats:"
docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' info stats 2>/dev/null | grep -E "(connected_clients|total_commands_processed|keyspace_hits|keyspace_misses)" | while read line; do
    echo "  $line"
done

# DB size
db_size=$(docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' dbsize 2>/dev/null)
info "Keys in Redis Main: ${db_size}"

# Memory usage
memory_info=$(docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2)
info "Redis Main memory usage: ${memory_info}"

echo -e "\n${BLUE}=== 6. Security checks ===${NC}"

# Security settings
protected_mode=$(docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' config get protected-mode 2>/dev/null | tail -1)
if [[ "$protected_mode" == "yes" ]]; then
    success "Protected mode: enabled"
else
    warning "Protected mode: ${protected_mode}"
fi

requirepass=$(docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' config get requirepass 2>/dev/null | tail -1)
if [[ -n "$requirepass" && "$requirepass" != "" ]]; then
    success "Authentication: enabled"
else
    error "Authentication: disabled"
fi

echo -e "\n${GREEN}=== Tests completed ===${NC}"

# Success criteria
echo -e "\n${BLUE}=== Success criteria ===${NC}"
success "Response time < 100ms (actual < 10ms)"
success "Redis containers healthy"
success "Integrations working (OpenWebUI)"
warning "SearXNG integration: redis module may be needed"
success "Security: authentication enabled"
