#!/bin/bash

# Comprehensive ERNI-KI monitoring system check
# Author: Alteon Schultz (ERNI-KI Tech Lead)

set -euo pipefail

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
LOKI_TENANT_HEADER="X-Scope-OrgID: erni-ki"

# Logging helper
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

header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

# Core monitoring components check
check_monitoring_services() {
    header "Checking monitoring components..."

    local services=(
        "prometheus:9091:Prometheus"
        "grafana:3000:Grafana"
        "alertmanager:9093:Alertmanager"
        "node-exporter:9101:Node Exporter"
        "postgres-exporter:9187:PostgreSQL Exporter"
        "redis-exporter:9121:Redis Exporter"
        "nvidia-exporter:9445:NVIDIA GPU Exporter"
        "webhook-receiver:9095:Webhook Receiver"
        "cadvisor:8081:cAdvisor"
        "blackbox-exporter:9115:Blackbox Exporter"
    )

    local healthy_count=0
    local total_count=${#services[@]}

    echo ""
    printf "%-20s %-10s %-15s %-30s\n" "SERVICE" "PORT" "STATUS" "DESCRIPTION"
    echo "------------------------------------------------------------------------"

    for service_info in "${services[@]}"; do
        IFS=':' read -r service port description <<< "$service_info"

        if curl -s -f "http://localhost:$port" >/dev/null 2>&1 || \
           curl -s -f "http://localhost:$port/health" >/dev/null 2>&1 || \
           curl -s -f "http://localhost:$port/metrics" >/dev/null 2>&1; then
            printf "%-20s %-10s %-15s %-30s\n" "$service" "$port" "✅ HEALTHY" "$description"
            ((healthy_count++))
        else
            printf "%-20s %-10s %-15s %-30s\n" "$service" "$port" "❌ DOWN" "$description"
        fi
    done

    echo "------------------------------------------------------------------------"
    echo "Healthy monitoring services: $healthy_count/$total_count"

    if [ $healthy_count -eq $total_count ]; then
        success "All monitoring components are healthy!"
        return 0
    else
        warning "Some monitoring components need attention"
        return 1
    fi
}

# Metrics validation
check_metrics() {
    header "Validating metric collection..."

    echo ""
    echo "=== KEY METRICS ==="

    # Prometheus availability
    if ! curl -s http://localhost:9091/api/v1/status/config >/dev/null; then
        error "Prometheus unavailable"
        return 1
    fi

    # System metrics
    log "System metrics (Node Exporter)..."
    local node_metrics=$(curl -s "http://localhost:9091/api/v1/query?query=up{job=\"node-exporter\"}" | jq -r '.data.result | length')
    if [ "$node_metrics" -gt 0 ]; then
        success "Node Exporter metrics targets: $node_metrics"
    else
        error "Node Exporter metrics unavailable"
    fi

    # GPU metrics
    log "GPU metrics (NVIDIA exporter)..."
    local gpu_metrics=$(curl -s http://localhost:9445/metrics | grep -c "nvidia_gpu" || echo "0")
    if [ "$gpu_metrics" -gt 0 ]; then
        success "GPU metrics: $gpu_metrics samples"

        # Display current GPU load
        local gpu_usage=$(curl -s http://localhost:9445/metrics | grep "nvidia_gpu_duty_cycle" | awk '{print $2}' | head -1)
        if [ -n "$gpu_usage" ]; then
            echo "  └─ Current GPU load: ${gpu_usage}%"
        fi
    else
        warning "GPU metrics unavailable"
    fi

    # Container metrics
    log "Container metrics (cAdvisor)..."
    local container_metrics=$(curl -s "http://localhost:9091/api/v1/query?query=container_last_seen" | jq -r '.data.result | length')
    if [ "$container_metrics" -gt 0 ]; then
        success "Container metrics available: $container_metrics containers"
    else
        warning "Container metrics unavailable"
    fi

    # Database metrics
    log "PostgreSQL metrics..."
    local db_metrics=$(curl -s "http://localhost:9091/api/v1/query?query=pg_up" | jq -r '.data.result | length')
    if [ "$db_metrics" -gt 0 ]; then
        success "PostgreSQL metrics accessible"
    else
        warning "PostgreSQL metrics unavailable"
    fi
}

# Grafana dashboard checks
check_grafana_dashboards() {
    header "Validating Grafana dashboards..."

    # Grafana API availability
    if ! curl -s http://localhost:3000/api/health >/dev/null; then
        error "Grafana unavailable"
        return 1
    fi

    success "Grafana reachable at http://localhost:3000"

    # Datasources
    log "Checking datasources..."
    echo "  ├─ Prometheus: http://localhost:9091"
    echo "  ├─ Alertmanager: http://localhost:9093"
    echo "  └─ Loki: http://localhost:3100 (requires header X-Scope-OrgID)"

    if curl -s -H "$LOKI_TENANT_HEADER" http://localhost:3100/ready >/dev/null; then
        success "Loki ready (endpoint /ready)"
    else
        warning "Loki (/ready) unavailable"
    fi

    # Dashboard info
    log "Preconfigured dashboards:"
    echo "  ├─ ERNI-KI System Overview"
    echo "  ├─ Infrastructure Monitoring"
    echo "  ├─ AI Services Monitoring"
    echo "  └─ Critical Alerts Dashboard"
}

# Alerting checks
check_alerts() {
    header "Validating alerting stack..."

    # Alertmanager status
    if ! curl -s http://localhost:9093/api/v1/status >/dev/null; then
        error "Alertmanager unavailable"
        return 1
    fi

    success "Alertmanager running at http://localhost:9093"

    # Active alerts
    log "Checking active alerts..."
    local active_alerts=$(curl -s http://localhost:9093/api/v1/alerts | jq -r '.data[] | select(.state == "active") | .labels.alertname' | wc -l)

    if [ "$active_alerts" -eq 0 ]; then
        success "No active alerts"
    else
        warning "Active alerts: $active_alerts"
        curl -s http://localhost:9093/api/v1/alerts | jq -r '.data[] | select(.state == "active") | "  ├─ \(.labels.alertname): \(.labels.severity)"'
    fi

    # Webhook receiver
    log "Checking webhook receiver..."
    if curl -s http://localhost:9095/health >/dev/null; then
        success "Webhook receiver running at http://localhost:9095"
    else
        error "Webhook receiver unavailable"
    fi
}

# Performance snapshot
check_performance() {
    header "System performance snapshot..."

    echo ""
    echo "=== CURRENT METRICS ==="

    # CPU
    local cpu_usage=$(curl -s "http://localhost:9091/api/v1/query?query=100-(avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")
    echo "CPU Usage: ${cpu_usage}%"

    # Memory
    local mem_usage=$(curl -s "http://localhost:9091/api/v1/query?query=(1-(node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))*100" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")
    echo "Memory Usage: ${mem_usage}%"

    # Disk
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    echo "Disk Usage: $disk_usage"

    # Containers
    local containers=$(docker ps | wc -l)
    echo "Running Containers: $((containers-1))"

    # GPU (if available)
    local gpu_temp=$(curl -s http://localhost:9445/metrics | grep "nvidia_gpu_temperature_celsius" | awk '{print $2}' | head -1 2>/dev/null || echo "N/A")
    if [ "$gpu_temp" != "N/A" ]; then
        echo "GPU Temperature: ${gpu_temp}°C"
    fi
}

# Main entrypoint
main() {
    echo "=================================================="
    echo "🔍 ERNI-KI MONITORING SYSTEM STATUS"
    echo "=================================================="
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Host: $(hostname)"
    echo ""

    local all_good=true

    # Execute checks
    if ! check_monitoring_services; then
        all_good=false
    fi
    echo ""

    check_metrics
    echo ""

    check_grafana_dashboards
    echo ""

    check_alerts
    echo ""

    check_performance
    echo ""

    echo "=================================================="
    if [ "$all_good" = true ]; then
        success "🎉 MONITORING STACK FULLY OPERATIONAL!"
        echo ""
        echo "📊 Interfaces:"
        echo "• Grafana: http://localhost:3000"
        echo "• Prometheus: http://localhost:9091"
        echo "• Alertmanager: http://localhost:9093"
        echo "• Loki: http://localhost:3100 (header X-Scope-OrgID: erni-ki)"
        echo ""
        echo "🔧 Exporters:"
        echo "• Node Exporter: http://localhost:9101/metrics"
        echo "• GPU Exporter: http://localhost:9445/metrics"
        echo "• cAdvisor: http://localhost:8081"
    else
        warning "⚠️ MONITORING STACK NEEDS ATTENTION"
        echo ""
        echo "Check logs for failing services:"
        echo "docker-compose -f monitoring/docker-compose.monitoring.yml logs <service>"
    fi
    echo "=================================================="
}

# Run
main "$@"
