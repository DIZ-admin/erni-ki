#!/bin/bash
# Quick start ERNI-KI in 5 minutes
# Author: Alteon Schulz (Tech Lead)

set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# Color definitions for output

PURPLE='\033[0;35m'

# Logging functions
[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
✅ $1${NC}"; }
⚠️  $1${NC}"; }
❌ $1${NC}"; exit 1; }
step() { echo -e "${PURPLE}🔸 $1${NC}"; }

# Quick dependency check
quick_check() {
    step "Quick system check..."

    command -v docker >/dev/null 2>&1 || log_error "Docker is not installed"
    command -v docker compose >/dev/null 2>&1 || log_error "Docker Compose is not installed"
    command -v openssl >/dev/null 2>&1 || log_error "OpenSSL is not installed"

    log_success "All dependencies found"
}

# Quick setup
quick_setup() {
    step "Quick configuration setup..."

    # Create main directories
    mkdir -p data/{postgres,redis,ollama,openwebui} scripts logs
    chmod 755 data/ && chmod 700 data/postgres

    # Copy main files
    [ ! -f "compose.yml" ] && cp compose.yml.example compose.yml

    # Main env files
    for env in auth db openwebui searxng; do
        [ ! -f "env/${env}.env" ] && cp "env/${env}.example" "env/${env}.env"
    done

    # Main configurations
    [ ! -f "conf/nginx/nginx.conf" ] && cp conf/nginx/nginx.example conf/nginx/nginx.conf
    [ ! -f "conf/nginx/conf.d/default.conf" ] && cp conf/nginx/conf.d/default.example conf/nginx/conf.d/default.conf

    log_success "Basic configuration created"
}

# Quick secret generation
quick_secrets() {
    step "Generating secret keys..."

    SECRET_KEY=$(openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    # Update keys
    sed -i "s/CHANGE_BEFORE_GOING_LIVE/$SECRET_KEY/g" env/auth.env env/openwebui.env
    sed -i "s/YOUR-SECRET-KEY/$SECRET_KEY/g" env/searxng.env
    sed -i "s/POSTGRES_PASSWORD=postgres/POSTGRES_PASSWORD=$DB_PASSWORD/g" env/db.env
    sed -i "s/postgres:postgres@db/postgres:$DB_PASSWORD@db/g" env/openwebui.env

    # Configure localhost
    sed -i "s/<domain-name>/localhost/g" conf/nginx/conf.d/default.conf
    sed -i "s|WEBUI_URL=https://<domain-name>|WEBUI_URL=http://localhost|g" env/openwebui.env

    log_success "Secret keys configured for localhost"
}

# Quick service start
quick_start() {
    step "Starting main services..."

    # Check configuration
    docker compose config >/dev/null || log_error "Error in Docker Compose configuration"

    # Start in correct order
    log_info "Starting base services..."
    docker compose up -d watchtower db redis
    sleep 10

    log_info "Starting auxiliary services..."
    docker compose up -d auth searxng nginx
    sleep 10

    log_info "Starting Ollama..."
    docker compose up -d ollama
    sleep 15

    log_info "Starting OpenWebUI..."
    docker compose up -d openwebui
    sleep 10

    log_success "All services started"
}

# Load base model
quick_model() {
    step "Loading base model..."

    # Wait for Ollama readiness
    log_info "Waiting for Ollama to be ready..."
    for i in {1..30}; do
        if docker compose exec -T ollama ollama list >/dev/null 2>&1; then
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""

    # Load model
    log_info "Loading llama3.2:3b (this may take several minutes)..."
    if docker compose exec -T ollama ollama pull llama3.2:3b; then
        log_success "Model llama3.2:3b loaded"
    else
        log_warn "Failed to load model (can be done later)"
    fi
}

# Quick health check
quick_health() {
    step "Quick status check..."

    # Check main services
    services=("auth" "db" "redis" "ollama" "nginx" "openwebui")

    for service in "${services[@]}"; do
        status=$(docker compose ps "$service" --format "{{.State}}" 2>/dev/null || echo "not_found")
        if [ "$status" = "running" ]; then
            log_success "$service: running"
        else
            log_warn "$service: $status"
        fi
    done

    # Check main endpoints
    sleep 5

    if curl -sf http://localhost >/dev/null 2>&1; then
        log_success "Web interface: available at http://localhost"
    else
        log_warn "Web interface: not yet available (may need more time)"
    fi

    if curl -sf http://localhost:11434/api/version >/dev/null 2>&1; then
        log_success "Ollama API: available"
    else
        log_warn "Ollama API: not yet available"
    fi
}

# Create quick commands
create_quick_commands() {
    step "Creating quick commands..."

    # Status command
    cat > scripts/status.sh << 'EOF'
#!/bin/bash
echo "📊 ERNI-KI Status:"
docker compose ps
echo ""
echo "🌐 Available URLs:"
echo "  - Web interface: http://localhost"
echo "  - Ollama API: http://localhost:11434"
echo "  - Auth API: http://localhost:9090"
EOF

    # Logs command
    cat > scripts/logs.sh << 'EOF'
#!/bin/bash
echo "📋 ERNI-KI Logs (Ctrl+C to exit):"
docker compose logs -f
EOF

    # Stop command
    cat > scripts/stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping ERNI-KI..."
docker compose down
echo "✅ All services stopped"
EOF

    chmod +x scripts/*.sh
    log_success "Quick commands created in scripts/"
}

# Show next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🎉 ERNI-KI is ready! 🎉                ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  🌐 Open browser: http://localhost                      ║"
    echo "║                                                              ║"
    echo "║  📝 First steps:                                            ║"
    echo "║     1. Create an administrator account                      ║"
    echo "║     2. Configure Ollama connection                       ║"
    echo "║     3. Start chatting with AI!                                ║"
    echo "║                                                              ║"
    echo "║  🔧 Useful commands:                                       ║"
    echo "║     ./scripts/status.sh  - service status                 ║"
    echo "║     ./scripts/logs.sh    - view logs                  ║"
    echo "║     ./scripts/stop.sh    - stop system               ║"
    echo "║                                                              ║"
    echo "║  📚 Documentation: DEPLOYMENT_GUIDE.md                       ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Show important information
    echo -e "${YELLOW}"
    echo "⚠️  IMPORTANT:"
    echo "   - Secret keys saved in .secrets_backup"
    echo "   - For production, configure domain and SSL"
    echo "   - Regularly create data backups"
    echo -e "${NC}"
}

# Main function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  🚀 ERNI-KI Quick Start 🚀                  ║"
    echo "║                   Launch in 5 minutes                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${BLUE}This script will perform a quick launch of ERNI-KI with default settings.${NC}"
    echo -e "${BLUE}For advanced configuration, use: ./scripts/setup.sh${NC}"
    echo ""

    echo -n "Continue with quick start? (Y/n): "
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Cancelled by user"
        exit 0
    fi

    echo ""

    quick_check
    echo ""

    quick_setup
    echo ""

    quick_secrets
    echo ""

    quick_start
    echo ""

    quick_model
    echo ""

    quick_health
    echo ""

    create_quick_commands
    echo ""

    show_next_steps
}

# Script entry point
main "$@"
