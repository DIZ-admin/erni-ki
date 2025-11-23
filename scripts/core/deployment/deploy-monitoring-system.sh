#!/bin/bash
# Quick deployment of ERNI-KI monitoring system
# Critical priority - implementation within 24 hours

set -euo pipefail

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/erni-ki-monitoring-deployment.log"

# Logging functions
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${BLUE}$message${NC}"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
}

success() {
    local message="✅ $1"
    echo -e "${GREEN}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE" 2>/dev/null || true
}

warning() {
    local message="⚠️  $1"
    echo -e "${YELLOW}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE" 2>/dev/null || true
}

error() {
    local message="❌ $1"
    echo -e "${RED}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE" 2>/dev/null || true
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi

    # Check Docker Compose v2
    if ! docker compose version &> /dev/null; then
        error "Docker Compose v2 not available (need docker compose)"
        exit 1
    fi

    # Check port availability
    local ports=(9091 3000 9093 2020 9101 8000)
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep ":$port " &> /dev/null; then
            warning "Port $port is already in use"
        fi
    done

    # Check disk space
    local disk_usage=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 80 ]]; then
        error "Insufficient disk space: ${disk_usage}%"
        exit 1
    fi

    success "Prerequisites met"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."

    local dirs=(
        "$PROJECT_ROOT/data/prometheus"
        "$PROJECT_ROOT/data/grafana"
        "$PROJECT_ROOT/data/alertmanager"
        "$PROJECT_ROOT/data/elasticsearch"
        "$PROJECT_ROOT/data/fluent-bit/db"
        "$PROJECT_ROOT/monitoring/logs/critical"
        "$PROJECT_ROOT/monitoring/logs/webhook"
        "$PROJECT_ROOT/.config-backup/logs"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            success "Created directory: $dir"
        fi
    done

    # Set correct permissions
    chmod 755 "$PROJECT_ROOT/data/prometheus"
    chmod 755 "$PROJECT_ROOT/data/grafana"
    chmod 755 "$PROJECT_ROOT/data/alertmanager"

    success "Directories created"
}

# Create monitoring network
create_monitoring_network() {
    log "Creating monitoring network..."

    # Remove existing network if there are label issues
    if docker network ls | grep -q "erni-ki-monitoring"; then
        log "Removing existing erni-ki-monitoring network..."
        docker network rm erni-ki-monitoring 2>/dev/null || true
    fi

    # Create new network
    docker network create erni-ki-monitoring --driver bridge --label com.docker.compose.network=monitoring
    success "Network erni-ki-monitoring created"
}

# Deploy monitoring system
deploy_monitoring_stack() {
    log "Deploying monitoring system..."

    cd "$PROJECT_ROOT/monitoring"

    # Start basic monitoring components
    log "Starting Prometheus, Grafana, Alertmanager..."
    docker compose -f docker-compose.monitoring.yml up -d prometheus grafana alertmanager node-exporter

    # Wait for readiness
    sleep 30

    # Check status
    local services=("prometheus" "grafana" "alertmanager" "node-exporter")
    for service in "${services[@]}"; do
        if docker compose -f docker-compose.monitoring.yml ps "$service" | grep -q "Up"; then
            success "$service started"
        else
            error "$service failed to start"
        fi
    done
}

# Configure critical alerts
configure_critical_alerts() {
    log "Configuring critical alerts..."

    # Check Prometheus availability
    local prometheus_ready=false
    for i in {1..10}; do
        if curl -s http://localhost:9091/-/ready &> /dev/null; then
            prometheus_ready=true
            break
        fi
        log "Waiting for Prometheus readiness (attempt $i/10)..."
        sleep 10
    done

    if [[ "$prometheus_ready" == "true" ]]; then
        success "Prometheus is ready"

        # Reload alert configuration
        if curl -s -X POST http://localhost:9091/-/reload &> /dev/null; then
            success "Alert configuration reloaded"
        else
            warning "Failed to reload alert configuration"
        fi
    else
        error "Prometheus is not ready"
    fi
}

# Deploy GPU monitoring
deploy_gpu_monitoring() {
    log "Deploying GPU monitoring..."

    # Check NVIDIA availability
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi &> /dev/null; then
            log "Starting NVIDIA GPU Exporter..."
            cd "$PROJECT_ROOT/monitoring"
            docker compose -f docker-compose.monitoring.yml up -d nvidia-exporter

            sleep 10

            if docker compose -f docker-compose.monitoring.yml ps nvidia-exporter | grep -q "Up"; then
                success "NVIDIA GPU Exporter started"
            else
                warning "NVIDIA GPU Exporter failed to start"
            fi
        else
            warning "NVIDIA GPU not available"
        fi
    else
        warning "nvidia-smi not found, skipping GPU monitoring"
    fi
}

# Setup webhook notifications
setup_webhook_notifications() {
    log "Setting up webhook notifications..."

    cd "$PROJECT_ROOT/monitoring"

    # Start webhook receiver
    docker compose -f docker-compose.monitoring.yml up -d webhook-receiver

    sleep 10

    if docker compose -f docker-compose.monitoring.yml ps webhook-receiver | grep -q "Up"; then
        success "Webhook receiver started"

        # Test webhook
        if curl -s -f http://localhost:9093/health &> /dev/null; then
            success "Webhook receiver is available"
        else
            warning "Webhook receiver is not available"
        fi
    else
        error "Webhook receiver failed to start"
    fi
}

# Fix problematic services
fix_problematic_services() {
    log "Fixing problematic services..."

    cd "$PROJECT_ROOT"

    # Check and fix EdgeTTS
    log "Checking EdgeTTS..."
    if ! curl -s -f http://localhost:5050/voices &> /dev/null; then
        warning "EdgeTTS not available, restarting..."
        docker compose restart edgetts
        sleep 15

        if curl -s -f http://localhost:5050/voices &> /dev/null; then
            success "EdgeTTS restored"
        else
            error "EdgeTTS still not available"
        fi
    else
        success "EdgeTTS is working"
    fi

    # Check proxied SearXNG
    local searx_url="http://localhost:8080/api/searxng/search?q=monitoring&format=json"
    log "Checking SearXNG..."
    if ! curl -s -f --max-time 5 "$searx_url" &> /dev/null; then
        warning "SearXNG not available, restarting..."
        docker compose restart searxng || true
        sleep 20

        if curl -s -f --max-time 5 "$searx_url" &> /dev/null; then
            success "SearXNG restored"
        else
            error "SearXNG still not available"
        fi
    else
        success "SearXNG is working"
    fi
}

# Verify monitoring system
verify_monitoring_system() {
    log "Verifying monitoring system..."

    local endpoints=(
        "http://localhost:9091/-/healthy:Prometheus"
        "http://localhost:3000/api/health:Grafana"
        "http://localhost:9093/-/healthy:Alertmanager"
        "http://localhost:9101/metrics:Node Exporter"
        "http://localhost:9093/health:Webhook Receiver"
    )

    local healthy_count=0
    local total_count=${#endpoints[@]}

    for endpoint_info in "${endpoints[@]}"; do
        local endpoint=$(echo "$endpoint_info" | cut -d: -f1)
        local service=$(echo "$endpoint_info" | cut -d: -f2)

        if curl -s -f "$endpoint" &> /dev/null; then
            success "$service is available"
            ((healthy_count++))
        else
            error "$service is not available ($endpoint)"
        fi
    done

    log "Verification result: $healthy_count/$total_count services are healthy"

    if [[ $healthy_count -eq $total_count ]]; then
        success "Monitoring system is fully functional"
        return 0
    else
        error "Monitoring system is partially operational"
        return 1
    fi
}

# Generate deployment report
generate_deployment_report() {
    log "Generating deployment report..."

    local report_file="$PROJECT_ROOT/.config-backup/monitoring-deployment-report-$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=== ERNI-KI MONITORING SYSTEM DEPLOYMENT REPORT ==="
        echo "Date: $(date)"
        echo "Host: $(hostname)"
        echo ""

        echo "=== MONITORING COMPONENTS STATUS ==="
        cd "$PROJECT_ROOT/monitoring"
        docker compose -f docker-compose.monitoring.yml ps
        echo ""

        echo "=== ENDPOINT AVAILABILITY ==="
        curl -s http://localhost:9091/-/healthy && echo "Prometheus: ✅ Healthy" || echo "Prometheus: ❌ Unhealthy"
        curl -s http://localhost:3000/api/health && echo "Grafana: ✅ Healthy" || echo "Grafana: ❌ Unhealthy"
        curl -s http://localhost:9093/-/healthy && echo "Alertmanager: ✅ Healthy" || echo "Alertmanager: ❌ Unhealthy"
        curl -s http://localhost:9101/metrics > /dev/null && echo "Node Exporter: ✅ Healthy" || echo "Node Exporter: ❌ Unhealthy"
        echo ""

        echo "=== RESOURCE USAGE ==="
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(prometheus|grafana|alertmanager|node-exporter|webhook)"
        echo ""

        echo "=== NEXT STEPS ==="
        echo "1. Open Grafana: http://localhost:3000 (admin/admin123)"
        echo "2. Open Prometheus: http://localhost:9091"
        echo "3. Open Alertmanager: http://localhost:9093"
        echo "4. Configure additional dashboards in Grafana"
        echo "5. Test alerts"

    } > "$report_file"

    success "Report saved: $report_file"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           ERNI-KI Monitoring System Deployment              ║"
    echo "║              Monitoring System Deployment              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Change to working directory
    cd "$PROJECT_ROOT"

    # Execute deployment
    check_prerequisites
    echo ""

    create_directories
    echo ""

    create_monitoring_network
    echo ""

    deploy_monitoring_stack
    echo ""

    configure_critical_alerts
    echo ""

    deploy_gpu_monitoring
    echo ""

    setup_webhook_notifications
    echo ""

    fix_problematic_services
    echo ""

    verify_monitoring_system
    echo ""

    generate_deployment_report
    echo ""

    success "Monitoring system deployment completed!"
    echo ""
    echo -e "${GREEN}🎯 Next steps:${NC}"
    echo "1. Open Grafana: http://localhost:3000 (admin/admin123)"
    echo "2. Open Prometheus: http://localhost:9091"
    echo "3. Open Alertmanager: http://localhost:9093"
    echo "4. Run full diagnostics: ./scripts/health_check.sh --report"
}

# Handle command-line arguments
case "${1:-}" in
    --quick)
        log "Quick deployment (basic components only)"
        check_prerequisites
        create_directories
        create_monitoring_network
        deploy_monitoring_stack
        verify_monitoring_system
        ;;
    --gpu-only)
        log "Deploying GPU monitoring only"
        deploy_gpu_monitoring
        ;;
    --fix-services)
        log "Fixing problematic services"
        fix_problematic_services
        ;;
    --verify)
        log "Verifying monitoring system"
        verify_monitoring_system
        ;;
    *)
        main
        ;;
esac
