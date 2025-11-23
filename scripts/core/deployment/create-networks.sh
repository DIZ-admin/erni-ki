#!/bin/bash

# ERNI-KI Network Creation Script
# Creates optimized Docker networks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging helpers
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }
info() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"; }

# Create optimized Docker networks
create_optimized_networks() {
    log "Creating optimized Docker networks..."

    # Remove existing networks if present
    info "Removing existing networks..."
    docker network rm erni-ki-backend 2>/dev/null || warn "Network erni-ki-backend not found"
    docker network rm erni-ki-monitoring 2>/dev/null || warn "Network erni-ki-monitoring not found"
    docker network rm erni-ki-internal 2>/dev/null || warn "Network erni-ki-internal not found"

    # Create backend network
    info "Creating backend network..."
    docker network create \
        --driver bridge \
        --subnet=172.21.0.0/16 \
        --gateway=172.21.0.1 \
        --opt com.docker.network.bridge.name=erni-ki-be0 \
        --opt com.docker.network.driver.mtu=1500 \
        --opt com.docker.network.bridge.enable_icc=true \
        --opt com.docker.network.bridge.enable_ip_masquerade=true \
        erni-ki-backend

    # Create monitoring network
    info "Creating monitoring network..."
    docker network create \
        --driver bridge \
        --subnet=172.22.0.0/16 \
        --gateway=172.22.0.1 \
        --opt com.docker.network.bridge.name=erni-ki-mon0 \
        --opt com.docker.network.driver.mtu=1500 \
        --opt com.docker.network.bridge.enable_icc=true \
        --opt com.docker.network.bridge.enable_ip_masquerade=true \
        erni-ki-monitoring

    # Create internal network with jumbo frames
    info "Creating internal network..."
    docker network create \
        --driver bridge \
        --subnet=172.23.0.0/16 \
        --gateway=172.23.0.1 \
        --internal \
        --opt com.docker.network.bridge.name=erni-ki-int0 \
        --opt com.docker.network.driver.mtu=9000 \
        --opt com.docker.network.bridge.enable_icc=true \
        erni-ki-internal

    log "Optimized Docker networks created"
}

# Verify created networks
verify_networks() {
    log "Verifying created networks..."

    info "Docker networks:"
    docker network ls | grep erni-ki

    info "Backend network details:"
    docker network inspect erni-ki-backend --format '{{.IPAM.Config}}'

    info "Monitoring network details:"
    docker network inspect erni-ki-monitoring --format '{{.IPAM.Config}}'

    info "Internal network details:"
    docker network inspect erni-ki-internal --format '{{.IPAM.Config}}'

    log "Network verification complete"
}

# Main
main() {
    log "Starting optimized Docker network creation..."

    # Ensure Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running or unavailable"
        exit 1
    fi

    create_optimized_networks
    verify_networks

    log "Optimized Docker network creation completed!"
    info "You can now start ERNI-KI with the new networking layout"
    info "Run: docker-compose up -d"
}

# Run main
main "$@"
