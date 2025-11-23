#!/bin/bash

# SearXNG Optimization Script for ERNI-KI
# Optimizes SearXNG configuration and restarts services

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging helpers
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Dependency check
check_dependencies() {
    log "Checking dependencies..."

    command -v openssl >/dev/null 2>&1 || error "openssl not found"
    command -v docker >/dev/null 2>&1 || error "docker not found"

    if command -v docker-compose >/dev/null 2>&1; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        error "docker-compose or docker compose not found"
    fi

    success "All dependencies present"
}

# Generate secure secret key
generate_searxng_secret() {
    log "Generating secure secret key for SearXNG..."

    local secret_key
    secret_key=$(openssl rand -hex 32)

    # Update env file
    if [ -f "env/searxng.env" ]; then
        sed -i "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${secret_key}/" env/searxng.env
    else
        cp env/searxng.example env/searxng.env
        sed -i "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${secret_key}/" env/searxng.env
    fi

    success "Secret key generated and saved to env/searxng.env"
}

# Copy configuration files
copy_config_files() {
    log "Copying updated configuration files..."

    # SearXNG configs
    if [ ! -f "conf/searxng/settings.yml" ]; then
        cp conf/searxng/settings.yml.example conf/searxng/settings.yml
        success "Copied conf/searxng/settings.yml"
    else
        warning "conf/searxng/settings.yml already exists, creating backup"
        cp conf/searxng/settings.yml conf/searxng/settings.yml.backup.$(date +%Y%m%d_%H%M%S)
        cp conf/searxng/settings.yml.example conf/searxng/settings.yml
        success "Updated conf/searxng/settings.yml (backup created)"
    fi

    if [ ! -f "conf/searxng/uwsgi.ini" ]; then
        cp conf/searxng/uwsgi.ini.example conf/searxng/uwsgi.ini
        success "Copied conf/searxng/uwsgi.ini"
    else
        warning "conf/searxng/uwsgi.ini already exists, creating backup"
        cp conf/searxng/uwsgi.ini conf/searxng/uwsgi.ini.backup.$(date +%Y%m%d_%H%M%S)
        cp conf/searxng/uwsgi.ini.example conf/searxng/uwsgi.ini
        success "Updated conf/searxng/uwsgi.ini (backup created)"
    fi

    # Nginx configs
    if [ ! -f "conf/nginx/conf.d/default.conf" ]; then
        cp conf/nginx/conf.d/default.example conf/nginx/conf.d/default.conf
        success "Copied conf/nginx/conf.d/default.conf"
    else
        warning "conf/nginx/conf.d/default.conf already exists, creating backup"
        cp conf/nginx/conf.d/default.conf conf/nginx/conf.d/default.conf.backup.$(date +%Y%m%d_%H%M%S)
        cp conf/nginx/conf.d/default.example conf/nginx/conf.d/default.conf
        success "Updated conf/nginx/conf.d/default.conf (backup created)"
    fi

    # Docker Compose
    if [ ! -f "compose.yml" ]; then
        cp compose.yml.example compose.yml
        success "Copied compose.yml"
    else
        warning "compose.yml already exists, creating backup"
        cp compose.yml compose.yml.backup.$(date +%Y%m%d_%H%M%S)
        cp compose.yml.example compose.yml
        success "Updated compose.yml (backup created)"
    fi
}

# Validate configuration
validate_config() {
    log "Validating configuration..."

    if command -v python3 >/dev/null 2>&1; then
        python3 - <<'PYCODE' || exit 1
import yaml
yaml.safe_load(open('conf/searxng/settings.yml', 'r'))
PYCODE
        success "conf/searxng/settings.yml is valid"
    fi

    $DOCKER_COMPOSE config >/dev/null || error "Invalid compose.yml"
    success "compose.yml is valid"
}

# Restart services
restart_services() {
    log "Restarting SearXNG and related services..."
    $DOCKER_COMPOSE stop searxng nginx || warning "Failed to stop some services"
    $DOCKER_COMPOSE up -d searxng nginx || error "Failed to start services"
    success "Services restarted"
}

# Health check
health_check() {
    log "Checking SearXNG availability..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:8081/ >/dev/null 2>&1; then
            success "SearXNG is reachable and running"
            return 0
        fi

        log "Attempt $attempt/$max_attempts: waiting for SearXNG to start..."
        sleep 2
        ((attempt++))
    done

    error "SearXNG did not respond after $max_attempts attempts"
}

# Show status
show_status() {
    log "Service status:"
    $DOCKER_COMPOSE ps searxng nginx redis

    echo ""
    log "Inspecting SearXNG logs (last 10 lines):"
    $DOCKER_COMPOSE logs --tail=10 searxng
}

# Main
main() {
    log "Starting SearXNG optimization for ERNI-KI..."

    if [ ! -f "compose.yml.example" ]; then
        error "Script must be run from the ERNI-KI project root"
    fi

    check_dependencies
    generate_searxng_secret
    copy_config_files
    validate_config
    restart_services
    health_check
    show_status

    success "SearXNG optimization completed successfully!"

    echo ""
    log "Next steps:"
    echo "1. Verify SearXNG: http://localhost:8081/"
    echo "2. Validate integration with OpenWebUI"
    echo "3. Monitor logs: $DOCKER_COMPOSE logs -f searxng"
    echo "4. Check uWSGI metrics: http://localhost:9191"

    warning "IMPORTANT: Store the generated secret key in a secure location!"
}

main "$@"
