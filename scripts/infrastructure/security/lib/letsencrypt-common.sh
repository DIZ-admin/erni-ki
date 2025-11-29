#!/usr/bin/env bash
# Common functions for LetsEncrypt SSL certificate management
# Provides shared utilities for acme.sh certificate operations

set -euo pipefail

# Source project common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../../lib/common.sh
source "${SCRIPT_DIR}/../../../lib/common.sh"

# Check if acme.sh is installed
# Arguments: acme_home (path to acme.sh installation)
# Example: check_acme_installed "$HOME/.acme.sh"
check_acme_installed() {
    local acme_home="${1:-$HOME/.acme.sh}"

    if [[ ! -f "$acme_home/acme.sh" ]]; then
        log_fatal "acme.sh missing. Install via: curl https://get.acme.sh | sh"
    fi

    log_debug "acme.sh found at: $acme_home"
}

# Check if Docker Compose is available
# Example: check_docker_compose
check_docker_compose() {
    if ! command -v docker >/dev/null 2>&1; then
        log_fatal "Docker not installed"
    fi

    if ! docker compose version >/dev/null 2>&1; then
        if ! command -v docker-compose >/dev/null 2>&1; then
            log_fatal "Docker Compose not installed"
        fi
    fi

    log_debug "Docker Compose is available"
}

# Backup SSL certificates
# Arguments: ssl_dir, backup_dir
# Example: backup_certificates "/path/to/ssl" "/path/to/backup"
backup_certificates() {
    local ssl_dir="$1"
    local backup_dir="$2"

    log_info "Backing up current certificates..."
    mkdir -p "$backup_dir"

    if [[ -d "$ssl_dir" && -n "$(ls -A "$ssl_dir" 2>/dev/null)" ]]; then
        cp -r "$ssl_dir/"* "$backup_dir/" 2>/dev/null || true
        log_success "Backup created at $backup_dir"
    else
        log_warn "SSL directory $ssl_dir is empty or does not exist, nothing to backup"
    fi
}

# Reload Nginx container via Docker Compose
# Example: reload_nginx_container
reload_nginx_container() {
    log_info "Reloading nginx..."

    # Check if we are in a directory with compose.yml
    if [[ ! -f "compose.yml" && ! -f "docker-compose.yml" ]]; then
        log_warn "No compose.yml found, cannot reload nginx via docker compose"
        return 1
    fi

    # Check if nginx container is running
    if ! docker compose ps nginx 2>/dev/null | grep -q "Up"; then
        log_warn "nginx container is not running"
        return 1
    fi

    # Test nginx configuration
    if docker compose exec nginx nginx -t >/dev/null 2>&1; then
        # Try graceful reload first
        if docker compose exec nginx nginx -s reload >/dev/null 2>&1; then
            log_success "nginx reloaded successfully"
        else
            # Fallback to container restart
            log_warn "Graceful reload failed, restarting container"
            docker compose restart nginx
        fi
    else
        log_error "nginx configuration invalid"
        return 1
    fi
}

# Verify Let's Encrypt certificate file
# Arguments: cert_file
# Example: verify_certificate_file "/path/to/nginx.crt"
verify_certificate_file() {
    local cert_file="$1"

    log_info "Verifying certificate: $cert_file"

    if [[ ! -f "$cert_file" ]]; then
        log_error "Certificate file missing: $cert_file"
        return 1
    fi

    # Check if it's a valid certificate
    if ! openssl x509 -in "$cert_file" -noout -text >/dev/null 2>&1; then
        log_error "Invalid certificate file: $cert_file"
        return 1
    fi

    # Check if issued by Let's Encrypt
    if openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null | grep -q "Let's Encrypt"; then
        local expiry
        expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
        log_success "Valid Let's Encrypt certificate (Expires: $expiry)"
        return 0
    else
        local issuer
        issuer=$(openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null || echo "unknown")
        log_warn "Certificate not issued by Let's Encrypt (Issuer: $issuer)"
        return 1
    fi
}
