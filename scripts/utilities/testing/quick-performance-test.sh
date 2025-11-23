#!/bin/bash
# Quick performance test for ERNI-KI
# Author: Alteon Schultz (Tech Lead)

set -e

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging helpers
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
section() { echo -e "${PURPLE}🔍 $1${NC}"; }

declare -a COMPOSE_BIN
if docker compose version &> /dev/null; then
    COMPOSE_BIN=(docker compose)
elif command -v docker-compose &> /dev/null; then
    COMPOSE_BIN=(docker-compose)
else
    error "Docker Compose not found"
    exit 1
fi

compose() {
    "${COMPOSE_BIN[@]}" "$@"
}

# Quick API endpoints test
quick_api_test() {
    section "Quick API performance test"

    local endpoints=(
        "http://localhost:80:Nginx"
        "http://localhost:9090/health:Auth"
        "http://localhost:11434/api/version:Ollama"
        "http://localhost:8080/api/searxng/search?q=quick-check&format=json:SearXNG"
        "http://localhost:9998/tika:Tika"
    )

    for endpoint_info in "${endpoints[@]}"; do
        local endpoint=$(echo "$endpoint_info" | cut -d: -f1-2)
        local name=$(echo "$endpoint_info" | cut -d: -f3)

        log "Testing $name..."

        local start_time=$(date +%s.%N)
        local response=$(timeout 5 curl -s -w "%{http_code}" "$endpoint" 2>/dev/null || echo "timeout")
        local end_time=$(date +%s.%N)

        if [[ "$response" == *"200"* ]]; then
            local response_time=$(echo "scale=0; ($end_time - $start_time) * 1000" | bc 2>/dev/null || echo "N/A")
            success "$name: ${response_time}ms"
        elif [[ "$response" == "timeout" ]]; then
            warning "$name: timeout (>5s)"
        else
            warning "$name: unavailable"
        fi
    done
    echo ""
}

# Database test
quick_db_test() {
    section "Quick PostgreSQL test"

    if compose exec -T db pg_isready -U postgres &> /dev/null; then
        success "PostgreSQL: reachable"

        # Simple performance test
        local start_time=$(date +%s.%N)
        compose exec -T db psql -U postgres -d openwebui -c "SELECT count(*) FROM information_schema.tables;" &> /dev/null
        local end_time=$(date +%s.%N)
        local query_time=$(echo "scale=0; ($end_time - $start_time) * 1000" | bc 2>/dev/null || echo "N/A")

        success "DB query time: ${query_time}ms"

        # DB size
        local db_size=$(compose exec -T db psql -U postgres -d openwebui -t -c "SELECT pg_size_pretty(pg_database_size('openwebui'));" 2>/dev/null | tr -d ' ' || echo "N/A")
        success "DB size: $db_size"
    else
        error "PostgreSQL is unavailable"
    fi
    echo ""
}

# Redis test
quick_redis_test() {
    section "Quick Redis test"

    if compose exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        success "Redis: reachable"

        # Performance test
        local start_time=$(date +%s.%N)
        compose exec -T redis redis-cli set test_key test_value &> /dev/null
        compose exec -T redis redis-cli get test_key &> /dev/null
        compose exec -T redis redis-cli del test_key &> /dev/null
        local end_time=$(date +%s.%N)
        local redis_time=$(echo "scale=0; ($end_time - $start_time) * 1000" | bc 2>/dev/null || echo "N/A")

        success "SET/GET/DEL time: ${redis_time}ms"

        # Memory usage
        local memory_usage=$(compose exec -T redis redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r' || echo "N/A")
        success "Memory usage: $memory_usage"
    else
        error "Redis is unavailable"
    fi
    echo ""
}

# Ollama test (simplified)
quick_ollama_test() {
    section "Quick Ollama test"

    if curl -sf http://localhost:11434/api/version &> /dev/null; then
        success "Ollama API: reachable"

        # Check models
        local models=$(compose exec -T ollama ollama list 2>/dev/null | tail -n +2 | wc -l || echo "0")
        success "Loaded models: $models"

        if [ "$models" -gt 0 ]; then
            # Simple generation test (with timeout)
            log "Testing text generation (timeout 30s)..."
            local start_time=$(date +%s.%N)

            local response=$(timeout 30 curl -s -X POST http://localhost:11434/api/generate \
                -H "Content-Type: application/json" \
                -d '{"model":"llama3.2:3b","prompt":"Hi","stream":false}' 2>/dev/null || echo "timeout")

            local end_time=$(date +%s.%N)

            if [[ "$response" != "timeout" ]] && [[ "$response" == *"response"* ]]; then
                local generation_time=$(echo "scale=1; $end_time - $start_time" | bc 2>/dev/null || echo "N/A")
                success "Generation time: ${generation_time}s"
            else
                warning "Text generation: timeout or error"
            fi
        else
            warning "No models loaded"
        fi
    else
        error "Ollama API is unavailable"
    fi
    echo ""
}

# Resource monitoring
quick_resource_check() {
    section "System resource monitoring"

    # CPU
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    success "CPU load: $cpu_load"

    # Memory
    local memory_info=$(free -h | grep "Mem:")
    local used_mem=$(echo "$memory_info" | awk '{print $3}')
    local total_mem=$(echo "$memory_info" | awk '{print $2}')
    local mem_percent=$(free | grep "Mem:" | awk '{printf "%.0f", $3/$2 * 100.0}')
    success "Memory: $used_mem/$total_mem (${mem_percent}%)"

    # Disk
    local disk_info=$(df -h / | tail -1)
    local disk_used=$(echo "$disk_info" | awk '{print $5}')
    local disk_avail=$(echo "$disk_info" | awk '{print $4}')
    success "Disk: $disk_used used, $disk_avail available"

    # Docker containers
    local running_containers=$(docker ps -q | wc -l)
    success "Running containers: $running_containers"

    # Top 5 containers by CPU
    log "Top containers by CPU:"
    docker stats --no-stream --format "{{.Container}}: {{.CPUPerc}}" | head -5 | while read line; do
        echo "  $line"
    done

    echo ""
}

# Generate final report
generate_quick_report() {
    section "Performance summary"

    local score=0
    local max_score=6
    local issues=()
    local recommendations=()

    # Check core services
    if curl -sf http://localhost &> /dev/null; then
        score=$((score + 1))
        success "Web interface: OK"
    else
        issues+=("Web interface is unavailable")
    fi

    if curl -sf http://localhost:9090/health &> /dev/null; then
        score=$((score + 1))
        success "Auth API: OK"
    else
        issues+=("Auth API is unavailable")
    fi

    if curl -sf http://localhost:11434/api/version &> /dev/null; then
        score=$((score + 1))
        success "Ollama API: OK"
    else
        issues+=("Ollama API is unavailable")
    fi

    if compose exec -T db pg_isready -U postgres &> /dev/null; then
        score=$((score + 1))
        success "PostgreSQL: OK"
    else
        issues+=("PostgreSQL is unavailable")
    fi

    if compose exec -T redis redis-cli ping &> /dev/null; then
        score=$((score + 1))
        success "Redis: OK"
    else
        issues+=("Redis is unavailable")
    fi

    # System load check
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_load_num=$(echo "$cpu_load" | cut -d. -f1)

    if [ "$cpu_load_num" -lt 4 ]; then
        score=$((score + 1))
        success "System load: Normal"
    else
        warning "System load: High ($cpu_load)"
        recommendations+=("Monitor CPU load")
    fi

    # Final score
    local percentage=$((score * 100 / max_score))
    echo ""

    if [ "$percentage" -ge 90 ]; then
        success "FINAL SCORE: ${percentage}% - Excellent performance"
    elif [ "$percentage" -ge 75 ]; then
        info "FINAL SCORE: ${percentage}% - Good performance"
    elif [ "$percentage" -ge 50 ]; then
        warning "FINAL SCORE: ${percentage}% - Acceptable performance"
    else
        error "FINAL SCORE: ${percentage}% - Performance issues"
    fi

    # Issues
    if [ ${#issues[@]} -gt 0 ]; then
        echo ""
        error "Issues found:"
        for issue in "${issues[@]}"; do
            echo "  • $issue"
        done
    fi

    # Recommendations
    if [ ${#recommendations[@]} -gt 0 ]; then
        echo ""
        warning "Recommendations:"
        for rec in "${recommendations[@]}"; do
            echo "  • $rec"
        done
    fi

    # General guidance
    echo ""
    info "General optimization tips:"
    echo "  • Monitor resource usage regularly"
    echo "  • Enable GPU support for Ollama if available"
    echo "  • Consider container resource limits"
    echo "  • Create regular database backups"
}

# Main
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                Quick Performance Test                        ║"
    echo "║                     Performance sanity                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    quick_api_test
    quick_db_test
    quick_redis_test
    quick_ollama_test
    quick_resource_check
    generate_quick_report

    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Quick performance test finished                 ║"
    echo "║        Results saved to quick_performance.txt               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Entrypoint
main "$@" | tee quick_performance.txt
