#!/bin/bash
# Automated setup script for ERNI-KI
# Author: Alteon Schulz (Tech Lead)

set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# Colors

# Logging helpers
[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
✅ $1${NC}"; }
⚠️  $1${NC}"; }
❌ $1${NC}"; exit 1; }

# Dependencies check
check_dependencies() {
    log_info "Checking system dependencies..."

    # Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Install Docker: https://docs.docker.com/get-docker/"
    fi
    log_success "Docker found: $(docker --version)"

    # Docker Compose
    if ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose is not installed"
    fi
    log_success "Docker Compose found: $(docker compose version)"

    # Node.js (optional)
    if command -v node &> /dev/null; then
        log_success "Node.js found: $(node --version)"
    else
        log_warn "Node.js not found (needed for development)"
    fi

    # Go (optional)
    if command -v go &> /dev/null; then
        log_success "Go found: $(go version)"
    else
        log_warn "Go not found (required to build auth service)"
    fi

    # OpenSSL for key generation
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL is not installed (required for secret generation)"
    fi
    log_success "OpenSSL found"
}

# Create directories
create_directories() {
    log_info "Creating required directories..."

    directories=("data" "data/postgres" "data/redis" "data/ollama" "data/openwebui" "scripts" "logs")

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        else
            log_success "Directory already exists: $dir"
        fi
    done

    # Set permissions
    chmod 755 data/
    chmod 700 data/postgres
    log_success "Permissions set"
}

# Copy configuration files
copy_config_files() {
    log_info "Copying configuration files..."

    # Docker Compose
    if [ ! -f "compose.yml" ]; then
        cp compose.yml.example compose.yml
        log_success "Copied compose.yml"
    else
        log_warn "compose.yml already exists"
    fi

    # Service configs
    config_files=(
        "conf/cloudflare/config.example:conf/cloudflare/config.yml"
        "conf/mcposerver/config.example:conf/mcposerver/config.json"
        "conf/nginx/nginx.example:conf/nginx/nginx.conf"
        "conf/nginx/conf.d/default.example:conf/nginx/conf.d/default.conf"
        "conf/searxng/settings.yml.example:conf/searxng/settings.yml"
        "conf/searxng/uwsgi.ini.example:conf/searxng/uwsgi.ini"
    )

    for config in "${config_files[@]}"; do
        src="${config%:*}"
        dst="${config#*:}"

        if [ -f "$src" ] && [ ! -f "$dst" ]; then
            cp "$src" "$dst"
            log_success "Copied: $dst"
        elif [ ! -f "$src" ]; then
            log_warn "Source file not found: $src"
        else
            log_warn "File already exists: $dst"
        fi
    done
}

# Copy env files
copy_env_files() {
    log_info "Copying environment files..."

    env_files=(
        "auth" "cloudflared" "db" "edgetts"
        "mcposerver" "ollama" "openwebui" "redis"
        "searxng" "tika" "watchtower"
    )

    for env_file in "${env_files[@]}"; do
        src="env/${env_file}.example"
        dst="env/${env_file}.env"

        if [ -f "$src" ] && [ ! -f "$dst" ]; then
            cp "$src" "$dst"
            log_success "Copied: $dst"
        elif [ ! -f "$src" ]; then
            log_warn "Source file not found: $src"
        else
            log_warn "File already exists: $dst"
        fi
    done
}

# Generate secrets
generate_secrets() {
    log_info "Generating secret keys..."

    # Main secrets
    SECRET_KEY=$(openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    log_success "Secrets generated"

    # Update env files
    # Note: perl used for macOS/Linux compatibility (sed -i differs)
    if [ -f "env/auth.env" ]; then
        perl -pi -e "s/CHANGE_BEFORE_GOING_LIVE/$SECRET_KEY/g" env/auth.env
        log_success "Updated JWT_SECRET in env/auth.env"
    fi

    if [ -f "env/openwebui.env" ]; then
        perl -pi -e "s/CHANGE_BEFORE_GOING_LIVE/$SECRET_KEY/g" env/openwebui.env
        perl -pi -e "s/postgres:postgres@db/postgres:$DB_PASSWORD@db/g" env/openwebui.env
        log_success "Updated WEBUI_SECRET_KEY in env/openwebui.env"
    fi

    if [ -f "env/db.env" ]; then
        perl -pi -e "s/POSTGRES_PASSWORD=postgres/POSTGRES_PASSWORD=$DB_PASSWORD/g" env/db.env
        log_success "Updated DB password in env/db.env"
    fi

    if [ -f "env/searxng.env" ]; then
        perl -pi -e "s/YOUR-SECRET-KEY/$SECRET_KEY/g" env/searxng.env
        log_success "Updated SEARXNG_SECRET in env/searxng.env"
    fi

    # Save keys for reference
    cat > .secrets_backup << EOF
# ERNI-KI secret keys - $(date)
# WARNING: Keep this file secure!

SECRET_KEY=$SECRET_KEY
DB_PASSWORD=$DB_PASSWORD

# These keys have been applied to env files
EOF

    chmod 600 .secrets_backup
    log_success "Secrets saved to .secrets_backup"
}

# Domain setup
setup_domain() {
    log_info "Domain configuration..."

    echo -n "Enter your domain (or press Enter for localhost): "
    read -r domain

    if [ -z "$domain" ]; then
        domain="localhost"
        log_warn "Using localhost (local access only)"
    else
        log_success "Domain set: $domain"
    fi

    # Update Nginx config
    if [ -f "conf/nginx/conf.d/default.conf" ]; then
        sed -i "s/<domain-name>/$domain/g" conf/nginx/conf.d/default.conf
        log_success "Domain updated in Nginx config"
    fi

    # Update OpenWebUI URL
    if [ -f "env/openwebui.env" ]; then
        if [ "$domain" = "localhost" ]; then
            sed -i "s|WEBUI_URL=https://<domain-name>|WEBUI_URL=http://localhost|g" env/openwebui.env
        else
            sed -i "s/<domain-name>/$domain/g" env/openwebui.env
        fi
        log_success "URL updated in OpenWebUI config"
    fi
}

# Cloudflare setup (optional)
setup_cloudflare() {
    log_info "Cloudflare tunnel setup (optional)..."

    echo -n "Configure Cloudflare tunnel? (y/N): "
    read -r setup_cf

    if [[ "$setup_cf" =~ ^[Yy]$ ]]; then
        echo -n "Enter Cloudflare tunnel token: "
        read -r tunnel_token

        if [ -n "$tunnel_token" ] && [ -f "env/cloudflared.env" ]; then
            sed -i "s/add-your-cloudflare-tunnel-token-here/$tunnel_token/g" env/cloudflared.env
            log_success "Cloudflare token set"
        else
            log_warn "Token not provided or file missing"
        fi
    else
        log_success "Cloudflare tunnel skipped"
    fi
}

# Validate configuration
validate_config() {
    log_info "Validating configuration..."

    # Docker Compose validation
    if docker compose config > /dev/null 2>&1; then
        log_success "Docker Compose configuration is valid"
    else
        log_error "Docker Compose configuration error"
    fi

    # Secret placeholders check
    if grep -r "CHANGE_BEFORE_GOING_LIVE" env/ > /dev/null 2>&1; then
        log_error "Unchanged secret placeholders found!"
    fi

    if grep -r "YOUR-SECRET-KEY" env/ > /dev/null 2>&1; then
        log_error "Unchanged secret placeholders found!"
    fi

    log_success "All secret keys configured"
}

# Create helper scripts
create_helper_scripts() {
    log_info "Creating helper scripts..."

    # Startup script
    cat > scripts/start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting ERNI-KI..."
docker compose up -d
echo "✅ Services started. Check status: ./scripts/health_check.sh"
EOF

    # Shutdown script
    cat > scripts/stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping ERNI-KI..."
docker compose down
echo "✅ Services stopped"
EOF

    # Restart script
    cat > scripts/restart.sh << 'EOF'
#!/bin/bash
echo "🔄 Restarting ERNI-KI..."
docker compose down
docker compose up -d
echo "✅ Services restarted"
EOF

    # Backup script
    cat > scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Creating backup..."
docker compose exec -T db pg_dump -U postgres openwebui > "$BACKUP_DIR/database.sql"
tar -czf "$BACKUP_DIR/configs.tar.gz" env/ conf/
echo "✅ Backup created at $BACKUP_DIR"
EOF

    # Set executable permissions
    chmod +x scripts/*.sh
    log_success "Helper scripts created in scripts/ directory"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ERNI-KI Setup Script                     ║"
    echo "║              Automated system setup           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_dependencies
    echo ""

    create_directories
    echo ""

    copy_config_files
    echo ""

    copy_env_files
    echo ""

    generate_secrets
    echo ""

    setup_domain
    echo ""

    setup_cloudflare
    echo ""

    validate_config
    echo ""

    create_helper_scripts
    echo ""

    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Setup complete!                     ║"
    echo "║                                                              ║"
    echo "║  Next steps:                                             ║"
    echo "║  1. Run: ./scripts/start.sh                           ║"
    echo "║  2. Check: ./scripts/health_check.sh                    ║"
    echo "║  3. Open: http://localhost (or your domain)              ║"
    echo "║                                                              ║"
    echo "║  Documentation: DEPLOYMENT_GUIDE.md                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Run script
main "$@"
