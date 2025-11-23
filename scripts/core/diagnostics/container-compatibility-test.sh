#!/bin/bash
# ERNI-KI container compatibility test
# Author: Alteon Schulz (Tech Lead)

set -e

# Colors for output
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

# Check Docker and docker-compose versions
check_docker_versions() {
    section "Checking Docker and Docker Compose versions"

    # Docker binary check
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        success "Docker version: $docker_version"

        # Enforce minimum version (>=20.10)
        local major=$(echo "$docker_version" | cut -d. -f1)
        local minor=$(echo "$docker_version" | cut -d. -f2)

        if [ "$major" -gt 20 ] || ([ "$major" -eq 20 ] && [ "$minor" -ge 10 ]); then
            success "Docker version meets ERNI-KI requirements"
        else
            warning "Docker version may be outdated (>=20.10 recommended)"
        fi

        # Check Docker daemon status
        if docker info &> /dev/null; then
            success "Docker daemon is running"

            # Docker info
            local docker_root=$(docker info --format '{{.DockerRootDir}}')
            local storage_driver=$(docker info --format '{{.Driver}}')
            success "Docker root: $docker_root"
            success "Storage driver: $storage_driver"
        else
            error "Docker daemon is not running"
            return 1
        fi
    else
        error "Docker is not installed"
        return 1
    fi

    # Check docker-compose binary
    if command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
        success "Docker Compose version: $compose_version"

        # Enforce minimum version (>=1.29)
        local major=$(echo "$compose_version" | cut -d. -f1)
        local minor=$(echo "$compose_version" | cut -d. -f2)

        if [ "$major" -gt 1 ] || ([ "$major" -eq 1 ] && [ "$minor" -ge 29 ]); then
            success "Docker Compose meets requirements"
        else
            warning "Docker Compose may be outdated (>=1.29 recommended)"
        fi
    else
        error "Docker Compose is not installed"
        return 1
    fi

    # Check docker compose v2 availability
    if docker compose version &> /dev/null; then
        local compose_v2=$(docker compose version --short)
        info "Docker Compose v2 available: $compose_v2"
    fi

    echo ""
}

# Check Docker Compose configuration
check_compose_config() {
    section "Validating Docker Compose config"

    if [ -f "compose.yml" ]; then
        success "compose.yml found"

        # Validate config
        if docker-compose config &> /dev/null; then
            success "Docker Compose config is valid"

            # Count services
            local services_count=$(docker-compose config --services | wc -l)
            success "Service count: $services_count"

            # List services
            info "Services defined in compose.yml:"
            docker-compose config --services | while read service; do
                echo "  • $service"
            done
        else
            error "Docker Compose configuration invalid"
            docker-compose config
            return 1
        fi
    else
        error "compose.yml not found"
        return 1
    fi
    echo ""
}

# Docker image checks
check_docker_images() {
    # Check availability of Docker images

    # Get image list from compose.yml
    local images=$(docker-compose config | grep "image:" | awk '{print $2}' | sort -u)

    echo "$images" | while read image; do
        if [ -n "$image" ]; then
            log "Checking image: $image"

            # Check if image exists locally
            if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
                success "Image $image is available locally"
            else
                info "Image $image missing locally"

                # Try to pull the image
                log "Attempting to pull image $image..."
                if docker pull "$image" &> /dev/null; then
                    success "Image $image pulled successfully"
                else
                    warning "Failed to pull image $image"
                fi
            fi
        fi
    done
    echo ""
}

# Service startup tests
test_services_startup() {
# Service startup tests

    # Critical services launch order
    local critical_services=("db" "redis" "auth" "ollama" "nginx" "openwebui")
    local optional_services=("searxng" "edgetts" "tika" "mcposerver")

    # Stop all services for clean test
    log "Stopping all services for a clean test..."
    docker-compose down &> /dev/null || true

    # Testing critical services
    for service in "${critical_services[@]}"; do
        log "Testing service startup: $service"

        if docker-compose up -d "$service" &> /dev/null; then
            sleep 5

            # Check container status
            local status=$(docker-compose ps "$service" --format "{{.State}}" 2>/dev/null || echo "unknown")
            if echo "$status" | grep -q "Up"; then
                success "Service $service started successfully"
            else
                warning "Service $service has issues: $status"

                # Show recent logs
                echo "Recent logs for $service:"
                docker-compose logs --tail=10 "$service" 2>/dev/null || echo "Logs unavailable"
            fi
        else
            error "Failed to start service $service"
        fi
    done

    # Test optional services
    log "Testing optional services..."
    for service in "${optional_services[@]}"; do
        if docker-compose up -d "$service" &> /dev/null; then
            sleep 3
            local status=$(docker-compose ps "$service" --format "{{.State}}" 2>/dev/null || echo "unknown")
            if echo "$status" | grep -q "Up"; then
                success "Optional service $service is running"
            else
                info "Optional service $service: $status"
            fi
        else
            info "Optional service $service failed to start"
        fi
    done
    echo ""
}

# Inter-service communication checks
test_inter_service_communication() {
    section "Testing inter-service connectivity"

    # Validate database connectivity
    log "Testing PostgreSQL connectivity..."
    if docker-compose exec -T db pg_isready -U postgres &> /dev/null; then
        success "PostgreSQL is reachable"

        # Verify connection establishment
        if docker-compose exec -T db psql -U postgres -d openwebui -c "SELECT 1;" &> /dev/null; then
            success "Database connection is operational"
        else
            warning "Database connection issues detected"
        fi
    else
        error "PostgreSQL unreachable"
    fi

    # Check Redis connectivity
    log "Testing Redis connectivity..."
    if docker-compose exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        success "Redis is available"
    else
        error "Redis is unavailable"
    fi

    # Verify Ollama API
    log "Testing Ollama API..."
    if curl -sf http://localhost:11434/api/version &> /dev/null; then
        success "Ollama API reachable"

        # Verify listed models
        local models=$(docker-compose exec -T ollama ollama list 2>/dev/null | tail -n +2 | wc -l)
        if [ "$models" -gt 0 ]; then
            success "Ollama: $models models loaded"
        else
            warning "Ollama: no models loaded"
        fi
    else
        error "Ollama API unreachable"
    fi

    # Validate Auth API
    log "Testing Auth API..."
    if curl -sf http://localhost:9090/health &> /dev/null; then
        success "Auth API reachable"
    else
        error "Auth API unreachable"
    fi

    # Validate Nginx
    log "Testing Nginx availability..."
    if curl -sf http://localhost &> /dev/null; then
        success "Nginx is reachable"
    else
        error "Nginx is unreachable"
    fi

    # Validate OpenWebUI
    log "Checking OpenWebUI..."
    if curl -sf http://localhost:8080 &> /dev/null; then
        success "OpenWebUI is reachable"
    else
        warning "OpenWebUI may be unreachable"
    fi
    echo ""
}

# Resource usage analysis
analyze_resource_usage() {
    section "Resource usage analysis"

    # Gather container stats
    log "Gathering resource usage statistics..."

    # Table header
    printf "%-20s %-10s %-15s %-15s %-10s\n" "CONTAINER" "CPU %" "MEM" "NETWORK I/O" "BLOCK I/O"
    echo "────────────────────────────────────────────────────────────────────────"

    # Stats per container
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | tail -n +2 | while read line; do
        echo "$line"
    done

    echo ""

    # Totals
    local total_containers=$(docker ps -q | wc -l)
    success "Containers running: $total_containers"

    # Resource limits
    log "Checking defined resource limits..."
    docker-compose config | grep -A 5 -B 5 "mem_limit\|cpus\|memory" | grep -v "^--$" || info "No resource limits configured"

    echo ""
}

# Network configuration checks
check_network_configuration() {
    section "Inspecting Docker network configuration"

    # Docker networks list
    success "Docker networks:"
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

    # Project network
    local project_network=$(docker-compose config | grep -A 10 "networks:" | grep -v "networks:" | head -1 | awk '{print $1}' | sed 's/://')
    if [ -n "$project_network" ]; then
        info "Project network: $project_network"

        # Network details
        docker network inspect "$project_network" &> /dev/null && success "Project network configured" || warning "Project network issues detected"
    fi

    # Open ports
    log "Listing key ports..."
    netstat -tuln 2>/dev/null | grep -E ":(80|5432|6379|8080|9090|11434|5001|5050|9998|8000) " | while read line; do
        local port=$(echo "$line" | awk '{print $4}' | cut -d: -f2)
        success "Port $port is listening"
    done

    echo ""
}

# Compatibility report
generate_compatibility_report() {
    section "Container compatibility report"

    local score=0
    local max_score=8
    local issues=()
    local recommendations=()

    # Docker verification
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        score=$((score + 2))
        success "Docker: operational"
    else
        error "Docker: installation/runtime issues"
        issues+=("Docker is not functioning correctly")
    fi

    # Docker Compose verification
    if command -v docker-compose &> /dev/null && docker-compose config &> /dev/null; then
        score=$((score + 1))
        success "Docker Compose: configuration valid"
    else
        error "Docker Compose: configuration issues"
        issues+=("Docker Compose issues")
    fi

    # Verify running services
    local running_services=$(docker-compose ps --services --filter "status=running" | wc -l)
    local total_services=$(docker-compose ps --services | wc -l)

    if [ "$running_services" -ge 8 ]; then
        score=$((score + 2))
        success "Services: $running_services/$total_services running"
    elif [ "$running_services" -ge 5 ]; then
        score=$((score + 1))
        warning "Services: $running_services/$total_services running"
        recommendations+=("Investigate services that failed to start")
    else
        error "Services: critically few containers running"
        issues+=("Most services are not running")
    fi

    # API endpoint checks
    local working_apis=0
    local apis=("http://localhost" "http://localhost:9090/health" "http://localhost:11434/api/version")

    for api in "${apis[@]}"; do
        if curl -sf "$api" &> /dev/null; then
            working_apis=$((working_apis + 1))
        fi
    done

    if [ "$working_apis" -eq 3 ]; then
        score=$((score + 2))
        success "API: all core endpoints reachable"
    elif [ "$working_apis" -ge 2 ]; then
        score=$((score + 1))
        warning "API: some endpoints unreachable"
        recommendations+=("Check the unreachable APIs")
    else
        error "API: critical accessibility issues"
        issues+=("Core APIs unreachable")
    fi

    # Inter-service communication checks
    if docker-compose exec -T db pg_isready &> /dev/null && docker-compose exec -T redis redis-cli ping &> /dev/null; then
        score=$((score + 1))
        success "Communication: inter-service links are healthy"
    else
        warning "Communication: inter-service issues detected"
        recommendations+=("Review service-to-service network connectivity")
    fi

    # Final score
    local percentage=$((score * 100 / max_score))
    echo ""

    if [ "$percentage" -ge 90 ]; then
        success "Compatibility score: ${percentage}% - Excellent"
    elif [ "$percentage" -ge 70 ]; then
        info "Compatibility score: ${percentage}% - Good"
    elif [ "$percentage" -ge 50 ]; then
        warning "Compatibility score: ${percentage}% - Fair"
    else
        error "Compatibility score: ${percentage}% - Poor"
    fi

    # Issues
    if [ ${#issues[@]} -gt 0 ]; then
        echo ""
        error "Issues detected:"
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
}

# Main function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Container Compatibility Test                   ║"
    echo "║           Container compatibility testing                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_docker_versions
    check_compose_config
    check_docker_images
    test_services_startup
    test_inter_service_communication
    analyze_resource_usage
    check_network_configuration
    generate_compatibility_report

    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  Testing completed                         ║"
    echo "║       Results saved to compatibility_report.txt            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Run test
main "$@" | tee compatibility_report.txt
