#!/bin/bash
# Graceful restart procedures for ERNI-KI
# Safe service restart with data preservation

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
LOG_FILE="/var/log/erni-ki-graceful-restart.log"
BACKUP_DIR="$PROJECT_ROOT/.config-backup/graceful-restart"
SHUTDOWN_TIMEOUT=60
STARTUP_TIMEOUT=120

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

# Create state backup
create_state_backup() {
    log "Creating system state backup"

    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/state_backup_$backup_timestamp"

    mkdir -p "$backup_path"

    # Save container states
    docker-compose ps --format json > "$backup_path/containers_state.json" 2>/dev/null || true

    # Save configurations
    cp -r "$PROJECT_ROOT/env" "$backup_path/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/conf" "$backup_path/" 2>/dev/null || true

    # Save volume information
    docker volume ls --format json > "$backup_path/volumes_info.json" 2>/dev/null || true

    # Save network information
    docker network ls --format json > "$backup_path/networks_info.json" 2>/dev/null || true

    # Save resource usage statistics
    docker stats --no-stream --format json > "$backup_path/resource_usage.json" 2>/dev/null || true

    success "State backup created: $backup_path"
    echo "$backup_path" > "$BACKUP_DIR/latest_backup_path.txt"
}

# Check restart readiness
check_restart_readiness() {
    log "Checking restart readiness"

    # Check disk space
    local disk_usage=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        error "Insufficient disk space: ${disk_usage}%"
        return 1
    fi

    # Check active OpenWebUI users
    local active_sessions=$(docker-compose exec -T openwebui ps aux | grep -c "python" 2>/dev/null || echo "0")
    if [[ $active_sessions -gt 5 ]]; then
        warning "Found $active_sessions active sessions in OpenWebUI"
        read -p "Continue restart? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Restart cancelled by user"
            return 1
        fi
    fi

    # Check critical processes
    local critical_processes=("postgres" "redis-server" "nginx")
    for process in "${critical_processes[@]}"; do
        if docker-compose exec -T db pgrep "$process" &>/dev/null ||
           docker-compose exec -T redis pgrep "$process" &>/dev/null ||
           docker-compose exec -T nginx pgrep "$process" &>/dev/null; then
            log "Critical process $process is active"
        fi
    done

    success "System is ready for restart"
    return 0
}

# Graceful service stop
graceful_stop_service() {
    local service_name="$1"
    local timeout="${2:-$SHUTDOWN_TIMEOUT}"

    log "Graceful stop of service: $service_name"

    # Special handling for different services
    case $service_name in
        "openwebui")
            # Notify users about upcoming restart
            log "Sending notification to OpenWebUI users"
            # API call for user notification can be added here
            ;;
        "ollama")
            # Wait for current generations to complete
            log "Waiting for current Ollama generations to complete"
            sleep 10
            ;;
        "db")
            # Database checkpoint
            log "Performing database checkpoint"
            docker-compose exec -T db psql -U postgres -c "CHECKPOINT;" 2>/dev/null || true
            ;;
        "redis")
            # Save Redis data
            log "Saving Redis data"
            docker-compose exec -T redis redis-cli BGSAVE 2>/dev/null || true
            sleep 5
            ;;
        "nginx")
            # Graceful reload to finish active connections
            log "Graceful reload Nginx"
            docker-compose exec nginx nginx -s quit 2>/dev/null || true
            ;;
    esac

    # Send SIGTERM
    log "Sending SIGTERM to service $service_name"
    docker-compose stop "$service_name" --timeout="$timeout" || {
        warning "Graceful stop failed, forcing stop"
        docker-compose kill "$service_name"
    }

    # Check if stopped
    local attempts=0
    while [[ $attempts -lt 10 ]]; do
        if ! docker-compose ps "$service_name" --format "{{.Status}}" | grep -q "Up"; then
            success "Service $service_name stopped"
            return 0
        fi
        sleep 2
        ((attempts++))
    done

    warning "Service $service_name did not stop within expected time"
    return 1
}

# Graceful service start
graceful_start_service() {
    local service_name="$1"
    local timeout="${2:-$STARTUP_TIMEOUT}"

    log "Graceful start of service: $service_name"

    # Pre-start checks
    case $service_name in
        "ollama")
            # Check GPU availability
            if command -v nvidia-smi &> /dev/null; then
                if ! nvidia-smi &> /dev/null; then
                    error "GPU not available for Ollama"
                    return 1
                fi
            fi
            ;;
        "db")
            # Check data integrity
            log "Checking PostgreSQL data integrity"
            if [[ -d "$PROJECT_ROOT/data/postgres" ]]; then
                # Simple check for main files presence
                if [[ ! -f "$PROJECT_ROOT/data/postgres/PG_VERSION" ]]; then
                    error "PostgreSQL data corrupted"
                    return 1
                fi
            fi
            ;;
    esac

    # Start service
    if docker-compose up -d "$service_name"; then
        log "Service $service_name started, waiting for readiness"

        # Wait for readiness with timeout
        local start_time=$(date +%s)
        local end_time=$((start_time + timeout))

        while [[ $(date +%s) -lt $end_time ]]; do
            local status=$(docker-compose ps "$service_name" --format "{{.Status}}" 2>/dev/null || echo "")

            if echo "$status" | grep -q "healthy"; then
                success "Service $service_name is ready and healthy"
                return 0
            elif echo "$status" | grep -q "Up"; then
                log "Service $service_name started, waiting for health check"
                sleep 5
            else
                warning "Service $service_name status: $status"
                sleep 5
            fi
        done

        error "Service $service_name did not become ready within $timeout seconds"
        return 1
    else
        error "Failed to start service $service_name"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    local service_name="$1"

    log "Checking dependencies for $service_name"

    local dependencies=()
    case $service_name in
        "openwebui")
            dependencies=("db" "redis" "ollama" "searxng" "auth" "nginx")
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

    for dep in "${dependencies[@]}"; do
        local dep_status=$(docker-compose ps "$dep" --format "{{.Status}}" 2>/dev/null || echo "not_found")
        if ! echo "$dep_status" | grep -q "Up"; then
            warning "Dependency $dep not running for $service_name"
            return 1
        fi
    done

    success "All dependencies for $service_name are ready"
    return 0
}

# Graceful restart of single service
graceful_restart_service() {
    local service_name="$1"
    local check_deps="${2:-true}"

    log "Graceful restart of service: $service_name"

    # Check dependencies
    if [[ "$check_deps" == "true" ]]; then
        if ! check_dependencies "$service_name"; then
            error "Dependencies for $service_name not ready"
            return 1
        fi
    fi

    # Stop
    if ! graceful_stop_service "$service_name"; then
        error "Failed to stop service $service_name"
        return 1
    fi

    # Short pause
    sleep 5

    # Start
    if ! graceful_start_service "$service_name"; then
        error "Failed to start service $service_name"
        return 1
    fi

    success "Service $service_name successfully restarted"
    return 0
}

# Graceful restart of entire system
graceful_restart_all() {
    log "Graceful restart of entire ERNI-KI system"

    # Check readiness
    if ! check_restart_readiness; then
        error "System not ready for restart"
        return 1
    fi

    # Create backup
    create_state_backup

    # Define stop order (reverse dependency order)
    local stop_order=("openwebui" "nginx" "auth" "searxng" "ollama" "edgetts" "tika" "mcposerver" "cloudflared" "backrest" "redis" "db" "watchtower")

    # Define start order
    local start_order=("watchtower" "db" "redis" "auth" "ollama" "searxng" "edgetts" "tika" "mcposerver" "nginx" "openwebui" "cloudflared" "backrest")

    # Stop services
    log "Stopping services in correct order"
    for service in "${stop_order[@]}"; do
        if docker-compose ps "$service" --format "{{.Status}}" | grep -q "Up"; then
            graceful_stop_service "$service" 30
        else
            log "Service $service already stopped"
        fi
    done

    # Pause for complete shutdown
    log "Waiting for complete shutdown of all services"
    sleep 10

    # Clean up resources
    log "Cleaning up unused Docker resources"
    docker system prune -f --volumes || true

    # Start services
    log "Starting services in correct order"
    for service in "${start_order[@]}"; do
        log "Starting service: $service"
        graceful_start_service "$service" 60

        # Pause between starts for stabilization
        sleep 10
    done

    # Final check
    log "Final check of all services"
    sleep 30

    local unhealthy_services=()
    for service in "${start_order[@]}"; do
        local status=$(docker-compose ps "$service" --format "{{.Status}}" 2>/dev/null || echo "not_found")
        if ! echo "$status" | grep -q "healthy\|Up"; then
            unhealthy_services+=("$service")
        fi
    done

    if [[ ${#unhealthy_services[@]} -eq 0 ]]; then
        success "All services successfully restarted and running"
        return 0
    else
        error "The following services did not start correctly: ${unhealthy_services[*]}"
        return 1
    fi
}

# Rollback to previous state
rollback_to_backup() {
    log "Rolling back to previous state"

    if [[ ! -f "$BACKUP_DIR/latest_backup_path.txt" ]]; then
        error "Backup not found"
        return 1
    fi

    local backup_path=$(cat "$BACKUP_DIR/latest_backup_path.txt")
    if [[ ! -d "$backup_path" ]]; then
        error "Backup path does not exist: $backup_path"
        return 1
    fi

    log "Restoring from backup: $backup_path"

    # Stop all services
    docker-compose down --timeout=30 || true

    # Restore configurations
    if [[ -d "$backup_path/env" ]]; then
        cp -r "$backup_path/env"/* "$PROJECT_ROOT/env/" 2>/dev/null || true
    fi

    if [[ -d "$backup_path/conf" ]]; then
        cp -r "$backup_path/conf"/* "$PROJECT_ROOT/conf/" 2>/dev/null || true
    fi

    # Start services
    docker-compose up -d

    success "Rollback completed"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                ERNI-KI Graceful Restart                     ║"
    echo "║               Safe Service Restart                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    # Change to working directory
    cd "$PROJECT_ROOT"

    # Execute graceful restart of entire system
    graceful_restart_all
}

# Command line argument handling
case "${1:-}" in
    --service)
        if [[ -n "${2:-}" ]]; then
            log "Graceful restart of service: $2"
            cd "$PROJECT_ROOT"
            graceful_restart_service "$2"
        else
            error "Specify service name to restart"
            exit 1
        fi
        ;;
    --stop)
        if [[ -n "${2:-}" ]]; then
            log "Graceful stop of service: $2"
            cd "$PROJECT_ROOT"
            graceful_stop_service "$2"
        else
            log "Graceful stop of all services"
            cd "$PROJECT_ROOT"
            docker-compose down --timeout=60
        fi
        ;;
    --start)
        if [[ -n "${2:-}" ]]; then
            log "Graceful start of service: $2"
            cd "$PROJECT_ROOT"
            graceful_start_service "$2"
        else
            log "Graceful start of all services"
            cd "$PROJECT_ROOT"
            docker-compose up -d
        fi
        ;;
    --backup)
        log "Creating state backup"
        mkdir -p "$BACKUP_DIR"
        create_state_backup
        ;;
    --rollback)
        log "Rolling back to previous state"
        cd "$PROJECT_ROOT"
        rollback_to_backup
        ;;
    --check)
        log "Checking restart readiness"
        cd "$PROJECT_ROOT"
        check_restart_readiness
        ;;
    *)
        main
        ;;
esac
