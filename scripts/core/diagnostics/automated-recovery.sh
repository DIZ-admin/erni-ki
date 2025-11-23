#!/bin/bash
# Automated recovery of ERNI-KI services
# Detection and fixing of typical problems

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/var/log/erni-ki-recovery.log"
MAX_RESTART_ATTEMPTS=3
HEALTH_CHECK_TIMEOUT=60
DEPENDENCY_WAIT_TIME=30

# Logging functions
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${BLUE}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

success() {
    local message="✅ $1"
    echo -e "${GREEN}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

warning() {
    local message="⚠️  $1"
    echo -e "${YELLOW}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    local message="❌ $1"
    echo -e "${RED}$message${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

# Check service health status
check_service_health() {
    local service_name="$1"
    local max_attempts="${2:-3}"
    local attempt=1

    log "Checking service status: $service_name"

    while [[ $attempt -le $max_attempts ]]; do
        local status=$(docker-compose ps "$service_name" --format "{{.Status}}" 2>/dev/null || echo "not_found")

        case $status in
            *"Up"*"healthy"*)
                success "Service $service_name is running and healthy"
                return 0
                ;;
            *"Up"*)
                log "Service $service_name is running, checking health check (attempt $attempt/$max_attempts)"
                sleep 10
                ;;
            *"Exit"*|*"Exited"*)
                warning "Service $service_name is stopped"
                return 1
                ;;
            *"Restarting"*)
                log "Service $service_name is restarting, waiting (attempt $attempt/$max_attempts)"
                sleep 15
                ;;
            "not_found")
                error "Service $service_name not found"
                return 2
                ;;
            *)
                warning "Service $service_name in unknown state: $status"
                return 3
                ;;
        esac

        ((attempt++))
    done

    error "Service $service_name failed health check after $max_attempts attempts"
    return 1
}

# Restart service with dependencies
restart_service_with_dependencies() {
    local service_name="$1"
    local restart_dependencies="${2:-false}"

    log "Restarting service: $service_name"

    # Get service dependencies
    local dependencies=()
    case $service_name in
        "openwebui")
            dependencies=("db" "redis" "ollama" "searxng" "auth" "nginx")
            ;;
        "ollama")
            dependencies=("nvidia-container-runtime")
            ;;
        "searxng")
            dependencies=("redis")
            ;;
        "nginx")
            dependencies=("openwebui" "auth")
            ;;
        "auth")
            dependencies=("db")
            ;;
        "backrest")
            dependencies=("db" "redis")
            ;;
    esac

    # Check dependencies
    if [[ "$restart_dependencies" == "true" ]]; then
        for dep in "${dependencies[@]}"; do
            if [[ "$dep" != "nvidia-container-runtime" ]]; then
                log "Checking dependency: $dep"
                if ! check_service_health "$dep" 1; then
                    warning "Dependency $dep is unhealthy, restarting"
                    restart_service_with_dependencies "$dep" false
                fi
            fi
        done
    fi

    # Graceful service shutdown
    log "Graceful shutdown of service $service_name"
    if ! docker-compose stop "$service_name" --timeout=30; then
        warning "Graceful shutdown failed, forcing stop"
        docker-compose kill "$service_name"
    fi

    # Wait for complete shutdown
    sleep 5

    # Start service
    log "Starting service $service_name"
    if docker-compose up -d "$service_name"; then
        success "Service $service_name started"

        # Wait for readiness
        log "Waiting for service $service_name readiness"
        sleep $DEPENDENCY_WAIT_TIME

        # Health check
        if check_service_health "$service_name" 5; then
            success "Service $service_name successfully recovered"
            return 0
        else
            error "Service $service_name failed health check after restart"
            return 1
        fi
    else
        error "Failed to start service $service_name"
        return 1
    fi
}

# Clean up Docker resources
cleanup_docker_resources() {
    log "Cleaning up Docker resources"

    # Remove stopped containers
    local stopped_containers=$(docker ps -a -q --filter "status=exited" 2>/dev/null || true)
    if [[ -n "$stopped_containers" ]]; then
        log "Removing stopped containers"
        docker rm $stopped_containers || true
        success "Stopped containers removed"
    fi

    # Remove unused images
    log "Removing unused images"
    docker image prune -f || true

    # Remove unused volumes
    log "Removing unused volumes"
    docker volume prune -f || true

    # Remove unused networks
    log "Removing unused networks"
    docker network prune -f || true

    success "Docker resource cleanup completed"
}

# Check and fix GPU issues
fix_gpu_issues() {
    log "Checking GPU status"

    # Check nvidia-smi availability
    if ! command -v nvidia-smi &> /dev/null; then
        warning "nvidia-smi unavailable, skipping GPU check"
        return 0
    fi

    # Check GPU status
    if ! nvidia-smi &> /dev/null; then
        error "GPU unavailable"

        # Attempt to restart NVIDIA Container Runtime
        log "Restarting NVIDIA Container Runtime"
        sudo systemctl restart docker || true
        sleep 10

        # Recheck
        if nvidia-smi &> /dev/null; then
            success "GPU recovered"
        else
            error "Failed to recover GPU"
            return 1
        fi
    else
        success "GPU working normally"
    fi

    # Check GPU temperature
    local gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")
    if [[ $gpu_temp -gt 85 ]]; then
        warning "High GPU temperature: ${gpu_temp}°C"

        # Reduce GPU load
        log "Temporarily reducing load on Ollama"
        docker-compose exec ollama pkill -STOP ollama || true
        sleep 30
        docker-compose exec ollama pkill -CONT ollama || true
    fi

    return 0
}

# Check and fix database issues
fix_database_issues() {
    log "Checking database status"

    # Check PostgreSQL connection
    if ! docker-compose exec -T db pg_isready -U postgres &> /dev/null; then
        warning "Database unavailable"

        # Check database logs
        local db_logs=$(docker-compose logs db --tail=50 2>/dev/null || echo "")
        if echo "$db_logs" | grep -i "corrupt\|error\|fatal" &> /dev/null; then
            error "Errors found in database logs"

            # Attempt recovery
            log "Attempting database recovery"
            restart_service_with_dependencies "db" false
        fi
    else
        success "Database working normally"

        # Check connection count
        local connections=$(docker-compose exec -T db psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tr -d ' ' || echo "0")
        if [[ $connections -gt 80 ]]; then
            warning "High number of active database connections: $connections"

            # Terminate long-running queries
            log "Terminating long-running queries"
            docker-compose exec -T db psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - interval '5 minutes';" || true
        fi
    fi
}

# Check and fix Redis issues
fix_redis_issues() {
    log "Checking Redis status"

    # Check Redis connection
    if ! docker-compose exec -T redis redis-cli ping &> /dev/null; then
        warning "Redis unavailable"
        restart_service_with_dependencies "redis" false
    else
        success "Redis working normally"

        # Check memory usage
        local memory_usage=$(docker-compose exec -T redis redis-cli info memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r' || echo "0B")
        log "Redis memory usage: $memory_usage"

        # Clear cache on high usage
        local memory_percent=$(docker-compose exec -T redis redis-cli info memory | grep "used_memory_rss_human" | cut -d: -f2 | tr -d '\r' | sed 's/[^0-9]//g' || echo "0")
        if [[ $memory_percent -gt 500 ]]; then  # More than 500MB
            warning "High Redis memory usage"
            log "Clearing Redis cache"
            docker-compose exec -T redis redis-cli flushdb || true
        fi
    fi
}

# Check disk space
check_disk_space() {
    log "Checking disk space"

    # Check main disk
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    log "Disk usage /: ${disk_usage}%"

    if [[ $disk_usage -gt 90 ]]; then
        error "Critically low disk space: ${disk_usage}%"

        # Clean up Docker logs
        log "Cleaning up Docker logs"
        docker system prune -f --volumes || true

        # Clean up old archives
        log "Cleaning up old log archives"
        find "$PROJECT_ROOT/.config-backup/logs" -name "*.gz" -mtime +7 -delete 2>/dev/null || true

        # Recheck
        disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [[ $disk_usage -gt 85 ]]; then
            warning "Disk space still critical: ${disk_usage}%"
        else
            success "Disk space freed: ${disk_usage}%"
        fi
    elif [[ $disk_usage -gt 80 ]]; then
        warning "Low disk space: ${disk_usage}%"
    else
        success "Sufficient disk space: ${disk_usage}%"
    fi
}

# Automated recovery of all services
auto_recovery() {
    log "Starting ERNI-KI automated recovery"

    # Check system resources
    check_disk_space
    echo ""

    # Clean up Docker resources
    cleanup_docker_resources
    echo ""

    # Fix GPU issues
    fix_gpu_issues
    echo ""

    # Fix database issues
    fix_database_issues
    echo ""

    # Fix Redis issues
    fix_redis_issues
    echo ""

    # Check critical services
    local critical_services=("db" "redis" "nginx" "auth")
    for service in "${critical_services[@]}"; do
        log "Checking critical service: $service"
        if ! check_service_health "$service" 2; then
            warning "Critical service $service is unhealthy, restarting"
            restart_service_with_dependencies "$service" false
        fi
        echo ""
    done

    # Check AI services
    local ai_services=("ollama" "openwebui" "searxng")
    for service in "${ai_services[@]}"; do
        log "Checking AI service: $service"
        if ! check_service_health "$service" 2; then
            warning "AI service $service is unhealthy, restarting"
            restart_service_with_dependencies "$service" true
        fi
        echo ""
    done

    # Final check of all services
    log "Final check of all services"
    local all_services=("db" "redis" "nginx" "auth" "ollama" "openwebui" "searxng" "edgetts" "tika" "mcposerver" "cloudflared" "watchtower" "backrest")
    local unhealthy_count=0

    for service in "${all_services[@]}"; do
        if ! check_service_health "$service" 1; then
            ((unhealthy_count++))
        fi
    done

    if [[ $unhealthy_count -eq 0 ]]; then
        success "All services are healthy! Automated recovery completed successfully"
    else
        warning "Found $unhealthy_count unhealthy services after recovery"
        warning "Manual intervention required"
    fi
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                ERNI-KI Automated Recovery                   ║"
    echo "║              Automated Recovery                             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Change to working directory
    cd "$PROJECT_ROOT"

    # Execute recovery
    auto_recovery
}

# Handle command line arguments
case "${1:-}" in
    --service)
        if [[ -n "${2:-}" ]]; then
            log "Recovering specific service: $2"
            cd "$PROJECT_ROOT"
            restart_service_with_dependencies "$2" true
        else
            error "Specify service name to recover"
            exit 1
        fi
        ;;
    --gpu)
        log "Fixing GPU issues"
        fix_gpu_issues
        ;;
    --database)
        log "Fixing database issues"
        cd "$PROJECT_ROOT"
        fix_database_issues
        ;;
    --redis)
        log "Fixing Redis issues"
        cd "$PROJECT_ROOT"
        fix_redis_issues
        ;;
    --cleanup)
        log "Cleaning up Docker resources"
        cleanup_docker_resources
        ;;
    --disk)
        log "Checking disk space"
        check_disk_space
        ;;
    *)
        main
        ;;
esac
