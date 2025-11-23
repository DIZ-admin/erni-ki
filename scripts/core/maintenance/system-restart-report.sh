#!/bin/bash

# ERNI-KI System Restart Report
# Author: Alteon Schultz (ERNI-KI Tech Lead)
# Date: $(date '+%Y-%m-%d %H:%M:%S')

set -euo pipefail

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check status of all services
check_all_services() {
    log "Checking status of all services..."

    local services=(
        "auth"
        "backrest"
        "db"
        "edgetts"
        "litellm"
        "mcposerver"
        "nginx"
        "ollama"
        "openwebui"
        "redis"
        "searxng"
        "tika"
        "watchtower"
        "cloudflared"
    )

    local healthy_count=0
    local total_count=${#services[@]}

    echo ""
    echo "=== SERVICE STATUS ==="
    printf "%-15s %-10s %-20s\n" "SERVICE" "STATUS" "HEALTH"
    echo "----------------------------------------"

    for service in "${services[@]}"; do
        local status=$(docker-compose ps "$service" --format "{{.Status}}" 2>/dev/null || echo "Not found")

        if [[ "$status" == *"healthy"* ]]; then
            printf "%-15s %-10s %-20s\n" "$service" "✅ UP" "🟢 HEALTHY"
            ((healthy_count++))
        elif [[ "$status" == *"Up"* ]]; then
            printf "%-15s %-10s %-20s\n" "$service" "✅ UP" "🟡 NO HEALTH"
            ((healthy_count++))
        elif [[ "$status" == "Not found" ]]; then
            printf "%-15s %-10s %-20s\n" "$service" "❌ DOWN" "🔴 NOT FOUND"
        else
            printf "%-15s %-10s %-20s\n" "$service" "❌ DOWN" "🔴 UNHEALTHY"
        fi
    done

    echo "----------------------------------------"
    echo "Running services: $healthy_count/$total_count"

    if [ $healthy_count -eq $total_count ]; then
        success "All services are running correctly!"
        return 0
    else
        warning "Some services require attention"
        return 1
    fi
}

# Check web interface availability
check_web_access() {
    log "Checking web interface availability..."

    local url="https://diz.zone"
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

    if [ "$response" = "200" ]; then
        success "Web interface available: $url (HTTP $response)"
        return 0
    else
        error "Web interface unavailable: $url (HTTP $response)"
        return 1
    fi
}

# Check key integrations
check_integrations() {
    log "Checking key integrations..."

    echo ""
    echo "=== INTEGRATION TEST ==="

    # TTS integration
    log "Testing EdgeTTS..."
    if curl -s -H "Authorization: Bearer your_api_key_here" \
        http://localhost:5050/v1/audio/voices >/dev/null 2>&1; then
        success "EdgeTTS API is working"
    else
        error "EdgeTTS API is not working"
    fi

    # Ollama integration
    log "Testing Ollama..."
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        success "Ollama API is working"

        # Check models
        local models=$(curl -s http://localhost:11434/api/tags | jq -r '.models | length' 2>/dev/null || echo "0")
        if [ "$models" -gt 0 ]; then
            success "Available models: $models"
        else
            warning "No models found"
        fi
    else
        error "Ollama API is not working"
    fi

    # PostgreSQL integration
    log "Testing PostgreSQL..."
    if docker-compose exec -T db pg_isready >/dev/null 2>&1; then
        success "PostgreSQL is working"
    else
        error "PostgreSQL is not working"
    fi

    # SearXNG integration
    log "Testing SearXNG..."
    if curl -s http://localhost:8080/search?q=test >/dev/null 2>&1; then
        success "SearXNG is working"
    else
        error "SearXNG is not working"
    fi
}

# Check system resources
check_system_resources() {
    log "Checking system resources..."

    echo ""
    echo "=== SYSTEM RESOURCES ==="

    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "CPU Usage: ${cpu_usage}%"

    # Memory
    local mem_info=$(free -h | grep "Mem:")
    echo "Memory: $mem_info"

    # Disk
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    echo "Disk Usage: $disk_usage"

    # Docker
    local containers=$(docker ps | wc -l)
    echo "Running Containers: $((containers-1))"
}

# Main function
main() {
    echo "=================================================="
    echo "🔄 ERNI-KI SYSTEM RESTART REPORT"
    echo "=================================================="
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Host: $(hostname)"
    echo ""

    # Run checks
    local all_good=true

    if ! check_all_services; then
        all_good=false
    fi
    echo ""

    if ! check_web_access; then
        all_good=false
    fi
    echo ""

    check_integrations
    echo ""

    check_system_resources
    echo ""

    echo "=================================================="
    if [ "$all_good" = true ]; then
        success "🎉 SYSTEM IS FULLY READY!"
        echo ""
        echo "📋 Available services:"
        echo "• OpenWebUI: https://diz.zone"
        echo "• Grafana: http://localhost:3000"
        echo "• Backrest: http://localhost:9898"
        echo "• LiteLLM: http://localhost:4000"
        echo ""
        echo "🔑 Credentials:"
        echo "• Email: diz-admin@proton.me"
        echo "• Password: testpass"
    else
        warning "⚠️ SYSTEM STARTED WITH WARNINGS"
        echo ""
        echo "Check logs of problematic services:"
        echo "docker-compose logs [service-name]"
    fi
    echo "=================================================="
}

# Run
main "$@"
