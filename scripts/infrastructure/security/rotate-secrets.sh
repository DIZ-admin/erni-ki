#!/bin/bash

# =============================================================================
# ERNI-KI: Secrets rotation script
# =============================================================================
# Automatic password rotation for PostgreSQL, Redis, Backrest
# Usage: ./scripts/rotate-secrets.sh [--dry-run] [--service SERVICE]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Dependency check
check_dependencies() {
    local deps=("docker-compose" "openssl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Dependency '$dep' not found. Install it before running the script."
        fi
    done
}

# Ensure we run from project root
check_project_root() {
    if [ ! -f "compose.yml" ] || [ ! -d "env" ] || [ ! -d "secrets" ]; then
        error "Run this script from the ERNI-KI repository root"
    fi
}

# Backup current secrets/env files
backup_secrets() {
    local backup_dir=".config-backup/secrets-rotation-$(date +%Y%m%d-%H%M%S)"
    log "Creating secrets backup in $backup_dir"

    mkdir -p "$backup_dir"
    cp -r secrets/ "$backup_dir/"
    cp -r env/ "$backup_dir/"

    success "Backup stored in $backup_dir"
}

# Generate random passwords
generate_passwords() {
    log "Generating new random passwords..."

    NEW_POSTGRES_PASSWORD=$(openssl rand -base64 32)
    NEW_REDIS_PASSWORD=$(openssl rand -base64 32)
    NEW_BACKREST_PASSWORD=$(openssl rand -base64 32)

    success "Fresh passwords generated"
}

# Update PostgreSQL password
rotate_postgres_password() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Skipping PostgreSQL password update"
        return
    fi

    log "Rotating PostgreSQL password..."

    # Update env file
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${NEW_POSTGRES_PASSWORD}/" env/db.env

    # Update secret file
    echo "$NEW_POSTGRES_PASSWORD" > secrets/postgres_password.txt
    chmod 600 secrets/postgres_password.txt

    success "PostgreSQL password rotated"
}

# Update Redis password
rotate_redis_password() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Skipping Redis password update"
        return
    fi

    log "Rotating Redis password..."

    # Update env file
    sed -i "s/REDIS_ARGS=\"--requirepass [^\"]*\"/REDIS_ARGS=\"--requirepass ${NEW_REDIS_PASSWORD} --maxmemory 1gb --maxmemory-policy allkeys-lru\"/" env/redis.env

    # Update secret file
    echo "$NEW_REDIS_PASSWORD" > secrets/redis_password.txt
    chmod 600 secrets/redis_password.txt

    success "Redis password rotated"
}

# Update Backrest password
rotate_backrest_password() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Skipping Backrest password update"
        return
    fi

    log "Rotating Backrest password..."

    # Update env file
    sed -i "s/BACKREST_PASSWORD=.*/BACKREST_PASSWORD=${NEW_BACKREST_PASSWORD}/" env/backrest.env
    sed -i "s/RESTIC_PASSWORD=.*/RESTIC_PASSWORD=${NEW_BACKREST_PASSWORD}/" env/backrest.env

    # Update secret file
    echo "$NEW_BACKREST_PASSWORD" > secrets/backrest_password.txt
    chmod 600 secrets/backrest_password.txt

    success "Backrest password rotated"
}

# Restart services
restart_services() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Skipping service restart for: $1"
        return
    fi

    local services="$1"
    log "Restarting services: $services"

    # Graceful restart with health checks
    for service in $services; do
        log "Restarting $service..."
        docker-compose restart "$service"

        # Wait for service to become healthy
        local max_attempts=30
        local attempt=1

        while [ $attempt -le $max_attempts ]; do
            if docker-compose ps "$service" | grep -q "healthy\|Up"; then
                success "$service restarted successfully"
                break
            fi

            if [ $attempt -eq $max_attempts ]; then
                error "$service failed to recover after restart"
            fi

            log "Waiting for $service to recover (attempt $attempt/$max_attempts)..."
            sleep 10
            ((attempt++))
        done
    done
}

# Validate services after rotation
verify_rotation() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Skipping post-rotation checks"
        return
    fi

    log "Verifying services after rotation..."

    # PostgreSQL
    if docker-compose exec -T db pg_isready -U postgres; then
        success "PostgreSQL is healthy"
    else
        error "PostgreSQL is unavailable after rotation"
    fi

    # Redis
    if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
        success "Redis is healthy"
    else
        error "Redis is unavailable after rotation"
    fi

    # Backrest
    if curl -s http://localhost:9898/health >/dev/null; then
        success "Backrest responds to health checks"
    else
        warning "Backrest did not respond (check manually)"
    fi
}

# Main function
main() {
    local service_filter=""
    DRY_RUN=false

    # Parse CLI arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --service)
                service_filter="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--service SERVICE]"
                echo "  --dry-run    Show actions without applying changes"
                echo "  --service    Rotate only the selected service (postgres|redis|backrest)"
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                ;;
        esac
    done

    log "🔄 Starting ERNI-KI secrets rotation..."

    if [ "$DRY_RUN" = true ]; then
        warning "DRY RUN MODE - no changes will be applied"
    fi

    check_dependencies
    check_project_root

    if [ "$DRY_RUN" = false ]; then
        backup_secrets
    fi

    generate_passwords

    # Handle service filter
    case "$service_filter" in
        "postgres")
            rotate_postgres_password
            restart_services "db"
            ;;
        "redis")
            rotate_redis_password
            restart_services "redis"
            ;;
        "backrest")
            rotate_backrest_password
            restart_services "backrest"
            ;;
        "")
            # Rotate every service
            rotate_postgres_password
            rotate_redis_password
            rotate_backrest_password
            restart_services "db redis backrest"
            ;;
        *)
            error "Unknown service: $service_filter"
            ;;
    esac

    verify_rotation

    success "✅ Secrets rotation completed successfully!"

    if [ "$DRY_RUN" = false ]; then
        warning "IMPORTANT: Save the new passwords securely!"
        echo "PostgreSQL: $NEW_POSTGRES_PASSWORD"
        echo "Redis: $NEW_REDIS_PASSWORD"
        echo "Backrest: $NEW_BACKREST_PASSWORD"
    fi
}

# Starting script
main "$@"
