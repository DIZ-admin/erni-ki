#!/bin/bash
# Redis Performance Optimization for ERNI-KI
# Performance and monitoring tuning

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Redis Performance Optimization for ERNI-KI ===${NC}"

# Logging helpers
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Ensure we are in repo root
if [[ ! -f "compose.yml" ]]; then
    error "compose.yml not found. Run from ERNI-KI repo root."
    exit 1
fi

# Backup
log "Creating configuration backup..."
mkdir -p .config-backup/redis-performance-$(date +%Y%m%d-%H%M%S)
cp compose.yml .config-backup/redis-performance-$(date +%Y%m%d-%H%M%S)/
cp -r env/ .config-backup/redis-performance-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true

# 1. Optimize Redis Main settings
log "Optimizing Redis Main settings..."

# Add performance parameters if missing
if ! grep -q "tcp-keepalive" compose.yml; then
    sed -i '/redis:/,/command: >/{
        /--maxmemory 512mb/a\
      --tcp-keepalive 300\
      --timeout 0\
      --tcp-backlog 511\
      --databases 16
    }' compose.yml
fi

# 2. Create redis.conf
log "Creating optimized redis.conf..."
mkdir -p conf/redis

cat > conf/redis/redis.conf << 'EOF'
# Redis Configuration for ERNI-KI Production
# Optimized for caching and sessions

# === NETWORK ===
bind 0.0.0.0
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# === GENERAL ===
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile ""
databases 16

# === SNAPSHOTS (disabled for performance) ===
save ""

# === REPLICATION ===
# Master defaults

# === SECURITY ===
requirepass ErniKiRedisSecurePassword2024
# Disable dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""
rename-command CONFIG "CONFIG_b835c3f8a5d9e7f2a1b4c6d8e9f0a2b3"

# === CLIENT LIMITS ===
maxclients 10000

# === MEMORY MANAGEMENT ===
maxmemory 512mb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# === APPEND ONLY MODE ===
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes

# === LUA SCRIPTING ===
lua-time-limit 5000

# === SLOW LOGS ===
slowlog-log-slower-than 10000
slowlog-max-len 128

# === KEYSPACE EVENT NOTIFICATIONS ===
notify-keyspace-events ""

# === EXTRA SETTINGS ===
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
EOF

# 3. Update compose.yml to use redis.conf
log "Updating compose.yml to use redis.conf..."
if ! grep -q "conf/redis/redis.conf" compose.yml; then
    # Add volume for config
    sed -i '/redis:/,/volumes:/{
        /- \.\/data\/redis:\/data/a\
      - ./conf/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
    }' compose.yml

    # Update command to use config
    sed -i '/redis:/,/command: >/{
        /command: >/,/--databases 16/{
            s/redis-server.*/redis-server \/usr\/local\/etc\/redis\/redis.conf/
        }
    }' compose.yml
fi

# 4. Create performance monitoring script
log "Creating performance monitoring script..."
cat > scripts/redis-monitor.sh << 'EOF'
#!/bin/bash
# Redis Performance Monitor for ERNI-KI

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Redis Performance Monitor ===${NC}"
echo "Time: $(date)"
echo

# Metric helper
get_redis_metric() {
    local container=$1
    local password=$2
    local metric=$3

    if [[ -n "$password" ]]; then
        docker exec "$container" redis-cli -a "$password" info 2>/dev/null | grep "^$metric:" | cut -d: -f2 | tr -d '\r'
    else
        docker exec "$container" redis-cli info 2>/dev/null | grep "^$metric:" | cut -d: -f2 | tr -d '\r'
    fi
}

# Monitor Redis Main
echo -e "${GREEN}=== Redis Main (erni-ki-redis-1) ===${NC}"
if docker ps --filter "name=erni-ki-redis-1" --format "{{.Status}}" | grep -q "healthy"; then
    echo "Status: ✅ Healthy"

    # Key metrics
    connected_clients=$(get_redis_metric "erni-ki-redis-1" "ErniKiRedisSecurePassword2024" "connected_clients")
    used_memory_human=$(get_redis_metric "erni-ki-redis-1" "ErniKiRedisSecurePassword2024" "used_memory_human")
    total_commands_processed=$(get_redis_metric "erni-ki-redis-1" "ErniKiRedisSecurePassword2024" "total_commands_processed")
    keyspace_hits=$(get_redis_metric "erni-ki-redis-1" "ErniKiRedisSecurePassword2024" "keyspace_hits")
    keyspace_misses=$(get_redis_metric "erni-ki-redis-1" "ErniKiRedisSecurePassword2024" "keyspace_misses")

    echo "Connected clients: $connected_clients"
    echo "Memory usage: $used_memory_human"
    echo "Total commands processed: $total_commands_processed"
    echo "Cache hits: $keyspace_hits"
    echo "Cache misses: $keyspace_misses"

    # Hit ratio
    if [[ $keyspace_hits -gt 0 || $keyspace_misses -gt 0 ]]; then
        hit_ratio=$(echo "scale=2; $keyspace_hits * 100 / ($keyspace_hits + $keyspace_misses)" | bc -l 2>/dev/null || echo "0")
        echo "Hit Ratio: ${hit_ratio}%"
    fi

    # Keys count
    dbsize=$(docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' dbsize 2>/dev/null)
    echo "Keys count: $dbsize"

else
    echo "Status: ❌ Unhealthy"
fi

echo

# Monitor Redis LiteLLM
echo -e "${GREEN}=== Redis LiteLLM (erni-ki-redis-litellm-1) ===${NC}"
if docker ps --filter "name=erni-ki-redis-litellm-1" --format "{{.Status}}" | grep -q "healthy"; then
    echo "Status: ✅ Healthy"

    # Try without password, then with password
    if connected_clients=$(get_redis_metric "erni-ki-redis-litellm-1" "" "connected_clients" 2>/dev/null); then
        password_status="No password"
    elif connected_clients=$(get_redis_metric "erni-ki-redis-litellm-1" "ErniKiRedisLiteLLMPassword2024" "connected_clients" 2>/dev/null); then
        password_status="With password"
    else
        echo "❌ Unable to connect"
        connected_clients="N/A"
        password_status="Unknown"
    fi

    echo "Authentication: $password_status"
    echo "Connected clients: $connected_clients"

    if [[ "$connected_clients" != "N/A" ]]; then
        if [[ "$password_status" == "With password" ]]; then
            used_memory_human=$(get_redis_metric "erni-ki-redis-litellm-1" "ErniKiRedisLiteLLMPassword2024" "used_memory_human")
            dbsize=$(docker exec erni-ki-redis-litellm-1 redis-cli -a 'ErniKiRedisLiteLLMPassword2024' dbsize 2>/dev/null)
        else
            used_memory_human=$(get_redis_metric "erni-ki-redis-litellm-1" "" "used_memory_human")
            dbsize=$(docker exec erni-ki-redis-litellm-1 redis-cli dbsize 2>/dev/null)
        fi
        echo "Memory usage: $used_memory_human"
        echo "Keys count: $dbsize"
    fi
else
    echo "Status: ❌ Unhealthy"
fi

echo

# System resources
echo -e "${GREEN}=== System resources ===${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}" | grep redis

echo
echo -e "${BLUE}Monitoring finished: $(date)${NC}"
EOF

chmod +x scripts/redis-monitor.sh

# 5. Create cron job for monitoring
log "Creating monitoring cron job..."
cat > scripts/setup-redis-monitoring.sh << 'EOF'
#!/bin/bash
# Configure automatic Redis monitoring

# Create directory for monitoring logs
mkdir -p logs/redis-monitoring

# Add cron job (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * cd $(pwd) && ./scripts/redis-monitor.sh >> logs/redis-monitoring/redis-monitor-$(date +\%Y\%m\%d).log 2>&1") | crontab -

echo "✅ Redis monitoring configured (every 5 minutes)"
echo "📊 Logs: logs/redis-monitoring/"
echo "🔍 Manual run: ./scripts/redis-monitor.sh"
EOF

chmod +x scripts/setup-redis-monitoring.sh

log "Performance optimization completed!"

echo -e "${GREEN}=== Optimization summary ===${NC}"
echo "✅ Optimized redis.conf created"
echo "✅ compose.yml updated"
echo "✅ Performance parameters added"
echo "✅ Monitoring script created"
echo "✅ Monitoring automation configured"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart Redis: docker compose restart redis"
echo "2. Verify config: docker exec erni-ki-redis-1 redis-cli -a 'ErniKiRedisSecurePassword2024' config get '*'"
echo "3. Run monitor: ./scripts/redis-monitor.sh"
echo "4. Enable cron: ./scripts/setup-redis-monitoring.sh"
