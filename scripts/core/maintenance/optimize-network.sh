#!/bin/bash

# ERNI-KI Network Optimization Script
# Script for optimizing system network performance

set -euo pipefail

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (sudo)"
        exit 1
    fi
}

# Backup current settings
backup_current_settings() {
    log "Creating backup of current network settings..."

    local backup_dir=".config-backup/network-settings-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    # Save current kernel settings
    sysctl -a > "$backup_dir/sysctl-current.conf" 2>/dev/null || true

    # Save Docker settings
    if command -v docker &> /dev/null; then
        docker network ls > "$backup_dir/docker-networks.txt" 2>/dev/null || true
        docker system info > "$backup_dir/docker-info.txt" 2>/dev/null || true
    fi

    # Save network settings
    ip addr show > "$backup_dir/ip-addr.txt" 2>/dev/null || true
    ip route show > "$backup_dir/ip-route.txt" 2>/dev/null || true

    log "Backup created in $backup_dir"
}

# Optimize kernel parameters for network performance
optimize_kernel_parameters() {
    log "Optimizing kernel parameters for network performance..."

    # Create sysctl config file
    cat > /etc/sysctl.d/99-erni-ki-network.conf << 'EOF'
# ERNI-KI Network Optimization Settings
# Network parameter optimization for high performance

# TCP/IP Stack Optimization
# TCP/IP Stack Optimization
net.core.rmem_default = 262144
net.core.rmem_max = 536870912
net.core.wmem_default = 262144
net.core.wmem_max = 536870912
net.core.netdev_max_backlog = 30000
net.core.netdev_budget = 600

# TCP Buffer Sizes
# TCP Buffer Sizes
net.ipv4.tcp_rmem = 4096 87380 536870912
net.ipv4.tcp_wmem = 4096 65536 536870912
net.ipv4.tcp_mem = 786432 1048576 26777216

# TCP Connection Optimization
# TCP Connection Optimization
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0

# TCP Keepalive Settings
# TCP Keepalive Settings
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3

# Connection Limits
# Connection Limits
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1

# Network Security (does not affect performance, but important)
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# IPv6 Optimization (if used)
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0

# File System Optimization for Network I/O
# File System Optimization for Network I/O
fs.file-max = 2097152
fs.nr_open = 2097152

# Virtual Memory Optimization
# Virtual Memory Optimization
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
EOF

    # Apply settings
    sysctl -p /etc/sysctl.d/99-erni-ki-network.conf

    log "Kernel parameters optimized"
}

# Optimize Docker for network performance
optimize_docker_settings() {
    log "Optimizing Docker settings..."

    # Create or update daemon.json
    local docker_config="/etc/docker/daemon.json"
    local temp_config="/tmp/docker-daemon.json"

    # Read existing config or create new one
    if [[ -f "$docker_config" ]]; then
        cp "$docker_config" "$temp_config"
    else
        echo '{}' > "$temp_config"
    fi

    # Add optimizations using jq
    if command -v jq &> /dev/null; then
        jq '. + {
            "default-address-pools": [
                {
                    "base": "172.20.0.0/16",
                    "size": 24
                },
                {
                    "base": "172.21.0.0/16",
                    "size": 24
                },
                {
                    "base": "172.22.0.0/16",
                    "size": 24
                },
                {
                    "base": "172.23.0.0/16",
                    "size": 24
                }
            ],
            "bip": "172.17.0.1/16",
            "mtu": 1500,
            "live-restore": true,
            "max-concurrent-downloads": 10,
            "max-concurrent-uploads": 10,
            "storage-driver": "overlay2",
            "storage-opts": [
                "overlay2.override_kernel_check=true"
            ],
            "log-driver": "json-file",
            "log-opts": {
                "max-size": "10m",
                "max-file": "3"
            }
        }' "$temp_config" > "$docker_config"
    else
        warn "jq not installed, creating configuration manually"
        cat > "$docker_config" << 'EOF'
{
    "default-address-pools": [
        {
            "base": "172.20.0.0/16",
            "size": 24
        },
        {
            "base": "172.21.0.0/16",
            "size": 24
        },
        {
            "base": "172.22.0.0/16",
            "size": 24
        },
        {
            "base": "172.23.0.0/16",
            "size": 24
        }
    ],
    "bip": "172.17.0.1/16",
    "mtu": 1500,
    "live-restore": true,
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 10,
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
    fi

    rm -f "$temp_config"

    log "Docker settings optimized"
}

# Create optimized Docker networks
create_optimized_networks() {
    log "Creating optimized Docker networks..."

    # Remove existing networks (if any)
    docker network rm erni-ki-backend erni-ki-monitoring erni-ki-internal 2>/dev/null || true

    # Create backend network
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

# Check and install required packages
install_dependencies() {
    log "Checking and installing required packages..."

    # Update package list
    apt-get update -qq

    # Install required packages
    apt-get install -y \
        net-tools \
        iptables-persistent \
        ethtool \
        tcpdump \
        iftop \
        nethogs \
        jq \
        curl \
        wget

    log "Required packages installed"
}

# Optimize network interfaces
optimize_network_interfaces() {
    log "Optimizing network interfaces..."

    # Get list of active interfaces
    local interfaces=$(ip link show | grep -E '^[0-9]+:' | grep -v 'lo:' | cut -d: -f2 | tr -d ' ')

    for interface in $interfaces; do
        if [[ "$interface" =~ ^(eth|ens|enp) ]]; then
            info "Optimizing interface $interface"

            # Increase buffer sizes (if supported)
            ethtool -G "$interface" rx 4096 tx 4096 2>/dev/null || warn "Failed to change buffer sizes for $interface"

            # Enable offloading (if supported)
            ethtool -K "$interface" gso on tso on gro on lro on 2>/dev/null || warn "Failed to enable offloading for $interface"

            # Optimize interrupt settings
            ethtool -C "$interface" rx-usecs 50 tx-usecs 50 2>/dev/null || warn "Failed to optimize interrupts for $interface"
        fi
    done

    log "Network interfaces optimized"
}

# Verify optimization results
verify_optimization() {
    log "Verifying optimization results..."

    info "Current TCP buffer settings:"
    sysctl net.core.rmem_max net.core.wmem_max net.ipv4.tcp_rmem net.ipv4.tcp_wmem

    info "Connection settings:"
    sysctl net.core.somaxconn net.ipv4.tcp_max_syn_backlog

    info "Docker networks:"
    docker network ls | grep erni-ki

    info "Docker status:"
    systemctl is-active docker

    log "Verification completed"
}

# Main function
main() {
    log "Starting ERNI-KI network optimization..."

    check_root
    backup_current_settings
    install_dependencies
    optimize_kernel_parameters
    optimize_docker_settings

    # Restart Docker to apply settings
    log "Restarting Docker to apply settings..."
    systemctl restart docker
    sleep 10

    create_optimized_networks
    optimize_network_interfaces
    verify_optimization

    log "Network optimization completed!"
    warn "System reboot recommended to fully apply all settings"
    info "To apply changes in ERNI-KI run: docker-compose down && docker-compose up -d"
}

# Run main function
main "$@"
