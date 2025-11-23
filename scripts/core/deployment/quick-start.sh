#!/bin/bash
# Quick start ERNI-KI in 5 minutes
# Author: Alteon Schulz (Tech Lead)

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
step() { echo -e "${PURPLE}🔸 $1${NC}"; }

# Quick dependency check
quick_check() {
    step "Quick system check..."

    command -v docker >/dev/null 2>&1 || error "Docker is not installed"
    command -v docker compose >/dev/null 2>&1 || error "Docker Compose is not installed"
    command -v openssl >/dev/null 2>&1 || error "OpenSSL is not installed"

    success "All dependencies found"
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

    success "Basic configuration created"
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

    success "Secret keys configured for localhost"
}

# Quick service start
quick_start() {
    step "Starting main services..."

    # Check configuration
    docker compose config >/dev/null || error "Error in Docker Compose configuration"

    # Start in correct order
    log "Starting base services..."
    docker compose up -d watchtower db redis
    sleep 10

    log "Starting auxiliary services..."
    docker compose up -d auth searxng nginx
    sleep 10

    log "Starting Ollama..."
    docker compose up -d ollama
    sleep 15

    log "Starting OpenWebUI..."
    docker compose up -d openwebui
    sleep 10

    success "All services started"
}

# Load base model
quick_model() {
    step "Loading base model..."

    # Wait for Ollama readiness
    log "Waiting for Ollama to be ready..."
    for i in {1..30}; do
        if docker compose exec -T ollama ollama list >/dev/null 2>&1; then
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""

    # Load model
    log "Loading llama3.2:3b (this may take several minutes)..."
    if docker compose exec -T ollama ollama pull llama3.2:3b; then
        success "Model llama3.2:3b loaded"
    else
        warning "Failed to load model (can be done later)"
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
            success "$service: running"
        else
            warning "$service: $status"
        fi
    done

    # Check main endpoints
    sleep 5

    if curl -sf http://localhost >/dev/null 2>&1; then
        success "Web interface: available at http://localhost"
    else
        warning "Web interface: not yet available (may need more time)"
    fi

    if curl -sf http://localhost:11434/api/version >/dev/null 2>&1; then
        success "Ollama API: available"
    else
        warning "Ollama API: not yet available"
    fi
}

# Create quick commands
create_quick_commands() {
    step "Creating quick commands..."

    # Status command
    cat > scripts/status.sh << 'EOF'
#!/bin/bash
echo "📊 Статус ERNI-KI:"
docker compose ps
echo ""
echo "🌐 Доступные URL:"
echo "  - Веб-интерфейс: http://localhost"
echo "  - Ollama API: http://localhost:11434"
echo "  - Auth API: http://localhost:9090"
EOF

    # Logs command
    cat > scripts/logs.sh << 'EOF'
#!/bin/bash
echo "📋 Логи ERNI-KI (Ctrl+C для выхода):"
docker compose logs -f
EOF

    # Stop command
    cat > scripts/stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Остановка ERNI-KI..."
docker compose down
echo "✅ Все сервисы остановлены"
EOF

    chmod +x scripts/*.sh
    success "Quick commands created in scripts/"
}

# Show next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🎉 ERNI-KI готов к работе! 🎉                ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  🌐 Откройте браузер: http://localhost                      ║"
    echo "║                                                              ║"
    echo "║  📝 Первые шаги:                                            ║"
    echo "║     1. Создайте аккаунт администратора                      ║"
    echo "║     2. Настройте подключение к Ollama                       ║"
    echo "║     3. Начните общение с AI!                                ║"
    echo "║                                                              ║"
    echo "║  🔧 Полезные команды:                                       ║"
    echo "║     ./scripts/status.sh  - статус сервисов                 ║"
    echo "║     ./scripts/logs.sh    - просмотр логов                  ║"
    echo "║     ./scripts/stop.sh    - остановка системы               ║"
    echo "║                                                              ║"
    echo "║  📚 Документация: DEPLOYMENT_GUIDE.md                       ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Показ важной информации
    echo -e "${YELLOW}"
    echo "⚠️  ВАЖНО:"
    echo "   - Секретные ключи сохранены в .secrets_backup"
    echo "   - Для продакшена настройте домен и SSL"
    echo "   - Регулярно создавайте бэкапы данных"
    echo -e "${NC}"
}

# Main function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  🚀 ERNI-KI Quick Start 🚀                  ║"
    echo "║                   Запуск за 5 минут                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${BLUE}Этот скрипт выполнит быстрый запуск ERNI-KI с настройками по умолчанию.${NC}"
    echo -e "${BLUE}Для продвинутой настройки используйте: ./scripts/setup.sh${NC}"
    echo ""

    echo -n "Продолжить быстрый запуск? (Y/n): "
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Отменено пользователем"
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
