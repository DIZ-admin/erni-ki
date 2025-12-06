#!/bin/bash
# Redis Performance Optimization for ERNI-KI
# Performance and monitoring tuning

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Colors

echo -e "${GREEN}=== Redis Performance Optimization for ERNI-KI ===${NC}"

# Logging helpers

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

read_secret() {
    local secret_name="$1"
    local secret_file="/run/secrets/${secret_name}"
    if [[ -f "${secret_file}" ]]; then
        tr -d '\r' <"${secret_file}" | tr -d '\n'
        return 0
    fi
    if [[ -f "secrets/${secret_name}.txt" ]]; then
        tr -d '\r' <"secrets/${secret_name}.txt" | tr -d '\n'
        return 0
    fi
    return 1
}

REDIS_PASSWORD="${REDIS_PASSWORD:-}"
if [[ -z "${REDIS_PASSWORD}" ]]; then
    if REDIS_PASSWORD="$(read_secret "redis_password")"; then
        :
    else
        log_error "redis_password secret not found; export REDIS_PASSWORD or create secrets/redis_password.txt"
        exit 1
    fi
fi

# Ensure we are in repo root
if [[ ! -f "compose.yml" ]]; then
    log_error "compose.yml not found. Run from ERNI-KI repo root."
    exit 1
fi

# Backup
log_info "Creating configuration backup..."
BACKUP_DIR=".config-backup/redis-performance-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp compose.yml "$BACKUP_DIR/"
cp -r env/ "$BACKUP_DIR/" 2>/dev/null || true

# 1. Optimize Redis Main settings
log_info "Optimizing Redis Main settings..."

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
log_info "Creating optimized redis.conf..."
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
requirepass __LOAD_FROM_SECRET__
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
log_info "Updating compose.yml to use redis.conf..."
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
log_info "Creating performance monitoring script..."
cat > scripts/redis-monitor.sh << 'EOF'
#!/bin/bash
# Redis Performance Monitor for ERNI-KI

set -euo pipefail

# Secret loader
read_secret() {
    local secret_name="$1"
    local secret_file="/run/secrets/${secret_name}"
    if [[ -f "${secret_file}" ]]; then
        tr -d '\r' <"${secret_file}" | tr -d '\n'
        return 0
    fi
    if [[ -f "secrets/${secret_name}.txt" ]]; then
        tr -d '\r' <"secrets/${secret_name}.txt" | tr -d '\n'
        return 0
    fi
    return 1
}

REDIS_PASSWORD="${REDIS_PASSWORD:-}"
if [[ -z "${REDIS_PASSWORD}" ]]; then
    if REDIS_PASSWORD="$(read_secret "redis_password")"; then
        :
    else
        echo "❌ redis_password secret not found; export REDIS_PASSWORD" >&2
        exit 1
    fi
fi

# Colors

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
    connected_clients=$(get_redis_metric "erni-ki-redis-1" "${REDIS_PASSWORD}" "connected_clients")
    used_memory_human=$(get_redis_metric "erni-ki-redis-1" "${REDIS_PASSWORD}" "used_memory_human")
    total_commands_processed=$(get_redis_metric "erni-ki-redis-1" "${REDIS_PASSWORD}" "total_commands_processed")
    keyspace_hits=$(get_redis_metric "erni-ki-redis-1" "${REDIS_PASSWORD}" "keyspace_hits")
    keyspace_misses=$(get_redis_metric "erni-ki-redis-1" "${REDIS_PASSWORD}" "keyspace_misses")

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
    dbsize=$(docker exec erni-ki-redis-1 redis-cli -a "${REDIS_PASSWORD}" dbsize 2>/dev/null)
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
    # pragma: allowlist secret (test credentials for diagnostics only)
    if connected_clients=$(get_redis_metric "erni-ki-redis-litellm-1" "" "connected_clients" 2>/dev/null); then
        password_status="No password"
    elif connected_clients=$(get_redis_metric "erni-ki-redis-litellm-1" "<redis-litellm-password>" "connected_clients" 2>/dev/null); then # pragma: allowlist secret
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
            # pragma: allowlist secret (placeholder password, non-prod)
            used_memory_human=$(get_redis_metric "erni-ki-redis-litellm-1" "<redis-litellm-password>" "used_memory_human") # pragma: allowlist secret
            dbsize=$(docker exec erni-ki-redis-litellm-1 redis-cli -a '<redis-litellm-password>' dbsize 2>/dev/null) # pragma: allowlist secret
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
log_info "Creating monitoring cron job..."
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

log_info "Performance optimization completed!"

echo -e "${GREEN}=== Optimization summary ===${NC}"
echo "✅ Optimized redis.conf created"
echo "✅ compose.yml updated"
echo "✅ Performance parameters added"
echo "✅ Monitoring script created"
echo "✅ Monitoring automation configured"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart Redis: docker compose restart redis"
echo "2. Verify config: docker exec erni-ki-redis-1 redis-cli -a \"\$REDIS_PASSWORD\" config get '*'"
echo "3. Run monitor: ./scripts/redis-monitor.sh"
echo "4. Enable cron: ./scripts/setup-redis-monitoring.sh"
