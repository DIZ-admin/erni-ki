#!/bin/bash
# Comprehensive server hardware analysis for ERNI-KI
# Author: Alteon Schultz (Tech Lead)

set -e

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging helpers
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
section() { echo -e "${PURPLE}🔍 $1${NC}"; }

# Helper to format sizes
format_size() {
    local size=$1
    if [ "$size" -gt 1073741824 ]; then
        echo "$(( size / 1073741824 )) GB"
    elif [ "$size" -gt 1048576 ]; then
        echo "$(( size / 1048576 )) MB"
    elif [ "$size" -gt 1024 ]; then
        echo "$(( size / 1024 )) KB"
    else
        echo "${size} B"
    fi
}

# CPU analysis
analyze_cpu() {
    section "CPU analysis"

    # Core CPU information
    if [ -f /proc/cpuinfo ]; then
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        local cpu_cores=$(nproc)
        local cpu_threads=$(grep -c "processor" /proc/cpuinfo)
        local cpu_arch=$(uname -m)

        success "Model: $cpu_model"
        success "Architecture: $cpu_arch"
        success "Physical cores: $cpu_cores"
        success "Logical threads: $cpu_threads"

        # CPU frequency
        if [ -f /proc/cpuinfo ]; then
            local cpu_freq=$(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
            if [ -n "$cpu_freq" ]; then
                success "Current frequency: ${cpu_freq} MHz"
            fi
        fi

        # Maximum frequency
        if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
            local max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
            if [ -n "$max_freq" ]; then
                success "Max frequency: $((max_freq / 1000)) MHz"
            fi
        fi

        # Processor cache
        local l3_cache=$(grep "cache size" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        if [ -n "$l3_cache" ]; then
            success "L3 cache: $l3_cache"
        fi

        # CPU flags (virtualization/perf hints)
        local cpu_flags=$(grep "flags" /proc/cpuinfo | head -1 | cut -d: -f2)
        if echo "$cpu_flags" | grep -q "avx2"; then
            success "AVX2 supported (accelerated workloads)"
        else
            warning "AVX2 not supported"
        fi

        if echo "$cpu_flags" | grep -q "sse4_2"; then
            success "SSE4.2 supported"
        else
            warning "SSE4.2 not supported"
        fi

        # Current CPU load
        local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        success "Current load: $cpu_load"

        # ERNI-KI suitability
        if [ "$cpu_cores" -ge 8 ]; then
            success "CPU is excellent for ERNI-KI (8+ cores)"
        elif [ "$cpu_cores" -ge 4 ]; then
            info "CPU is acceptable for ERNI-KI (4+ cores)"
        else
            warning "CPU may be insufficient (<4 cores)"
        fi
    else
        error "Unable to read CPU information"
    fi
    echo ""
}

# Memory analysis
analyze_memory() {
    section "RAM analysis"

    if [ -f /proc/meminfo ]; then
        local total_mem=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        local available_mem=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
        local free_mem=$(grep "MemFree" /proc/meminfo | awk '{print $2}')
        local cached_mem=$(grep "Cached" /proc/meminfo | head -1 | awk '{print $2}')
        local buffers_mem=$(grep "Buffers" /proc/meminfo | awk '{print $2}')

        # Convert to human-readable values
        local total_gb=$((total_mem / 1024 / 1024))
        local available_gb=$((available_mem / 1024 / 1024))
        local used_mem=$((total_mem - available_mem))
        local used_gb=$((used_mem / 1024 / 1024))
        local usage_percent=$((used_mem * 100 / total_mem))

        success "Total RAM: ${total_gb} GB"
        success "Used: ${used_gb} GB (${usage_percent}%)"
        success "Available: ${available_gb} GB"
        success "Cache: $((cached_mem / 1024)) MB"
        success "Buffers: $((buffers_mem / 1024)) MB"

        # Swap details
        local swap_total=$(grep "SwapTotal" /proc/meminfo | awk '{print $2}')
        local swap_free=$(grep "SwapFree" /proc/meminfo | awk '{print $2}')
        local swap_used=$((swap_total - swap_free))

        if [ "$swap_total" -gt 0 ]; then
            success "Swap total: $((swap_total / 1024 / 1024)) GB"
            success "Swap used: $((swap_used / 1024)) MB"
        else
            warning "Swap is not configured"
        fi

        # ERNI-KI guideline
        if [ "$total_gb" -ge 32 ]; then
            success "RAM is excellent for ERNI-KI (32+ GB)"
        elif [ "$total_gb" -ge 16 ]; then
            info "RAM is acceptable for ERNI-KI (16+ GB)"
        elif [ "$total_gb" -ge 8 ]; then
            warning "RAM is minimal for ERNI-KI (8+ GB)"
        else
            error "RAM is insufficient (<8 GB)"
        fi

        if [ "$usage_percent" -gt 80 ]; then
            warning "High memory usage (${usage_percent}%)"
        elif [ "$usage_percent" -gt 60 ]; then
            info "Moderate memory usage (${usage_percent}%)"
        else
            success "Low memory usage (${usage_percent}%)"
        fi
    else
        error "Unable to read memory info"
    fi
    echo ""
}

# Storage analysis
analyze_storage() {
    section "Storage analysis"

    # Disk overview
    success "Filesystem usage:"
    df -h | grep -E "^/dev/" | while read line; do
        echo "  $line"
    done

    # Root filesystem stats
    local root_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    local root_available=$(df -h / | tail -1 | awk '{print $4}')

    success "Root mount: ${root_usage}% used, ${root_available} free"

    # Docker storage
    local docker_dir="/var/lib/docker"
    if [ -d "$docker_dir" ]; then
        local docker_size=$(du -sh "$docker_dir" 2>/dev/null | cut -f1)
        success "Docker data footprint: $docker_size"
    fi

    # Project directory size
    local project_size=$(du -sh . 2>/dev/null | cut -f1)
    success "ERNI-KI project size: $project_size"

    # Disk speed benchmark
    log "Benchmarking disk read/write..."
    local write_speed=$(dd if=/dev/zero of=/tmp/test_write bs=1M count=100 2>&1 | grep -o '[0-9.]* MB/s' | tail -1)
    local read_speed=$(dd if=/tmp/test_write of=/dev/null bs=1M 2>&1 | grep -o '[0-9.]* MB/s' | tail -1)
    rm -f /tmp/test_write

    if [ -n "$write_speed" ]; then
        success "Write speed: $write_speed"
    fi
    if [ -n "$read_speed" ]; then
        success "Read speed: $read_speed"
    fi

    # ERNI-KI guidance
    if [ "$root_usage" -lt 50 ]; then
        success "Sufficient capacity for ERNI-KI"
    elif [ "$root_usage" -lt 80 ]; then
        warning "Storage becoming constrained – plan cleanup"
    else
        error "Critically low free space (${root_usage}%)"
    fi
    echo ""
}

# GPU analysis
analyze_gpu() {
    section "GPU capabilities"

    # NVIDIA GPU
    if command -v nvidia-smi &> /dev/null; then
        success "NVIDIA GPU detected:"
        nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,temperature.gpu,power.draw --format=csv,noheader,nounits | while read line; do
            echo "  $line"
        done

        # CUDA availability
        if command -v nvcc &> /dev/null; then
            local cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -d, -f1)
            success "CUDA version: $cuda_version"
        else
            warning "CUDA toolkit not installed"
        fi

        # Docker GPU passthrough
        if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null; then
            success "Docker GPU support verified"
        else
            warning "Docker GPU support unavailable"
        fi

        success "GPU ready for accelerated Ollama workloads"
    else
        # AMD GPU
        if command -v rocm-smi &> /dev/null; then
            success "AMD GPU detected:"
            rocm-smi --showproductname --showmeminfo
            info "AMD GPUs can run Ollama via ROCm"
        else
            # Intel GPU fallback
            if lspci | grep -i "vga\|3d\|display" | grep -i intel &> /dev/null; then
                local intel_gpu=$(lspci | grep -i "vga\|3d\|display" | grep -i intel | head -1)
                info "Intel GPU detected: $intel_gpu"
                warning "Intel GPU has limited Ollama support"
            else
                warning "No discrete GPU detected"
                info "Ollama will fall back to CPU (slower)"
            fi
        fi
    fi
    echo ""
}

# Network analysis
analyze_network() {
    section "Network capabilities"

    # Interfaces
    success "Active network interfaces:"
    ip addr show | grep -E "^[0-9]+:" | while read line; do
        local interface=$(echo "$line" | awk '{print $2}' | sed 's/://')
        local status=$(echo "$line" | grep -o "state [A-Z]*" | awk '{print $2}')
        echo "  $interface: $status"
    done

    # Download speed smoke test
    if command -v curl &> /dev/null; then
        log "Running download speed check..."
        local download_speed=$(curl -o /dev/null -s -w '%{speed_download}' http://speedtest.wdc01.softlayer.com/downloads/test10.zip | awk '{print int($1/1024/1024)}')
        if [ "$download_speed" -gt 0 ]; then
            success "Download throughput: ~${download_speed} MB/s"
        fi
    fi

    # Docker port status
    success "ERNI-KI port status:"
    local ports=(80 5432 6379 8080 9090 11434)
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep ":$port " &> /dev/null; then
            success "Port $port: in use (service healthy)"
        else
            info "Port $port: available"
        fi
    done

    # Docker networks
    if command -v docker &> /dev/null; then
        local docker_networks=$(docker network ls --format "{{.Name}}" | wc -l)
        success "Docker networks: $docker_networks"
    fi
    echo ""
}

# Operating system analysis
analyze_os() {
    section "Operating system analysis"

    # OS metadata
    if [ -f /etc/os-release ]; then
        local os_name=$(grep "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
        local os_version=$(grep "VERSION_ID" /etc/os-release | cut -d= -f2 | tr -d '"')
        success "OS: $os_name"
        success "Version: $os_version"
    fi

    # Kernel version
    local kernel_version=$(uname -r)
    success "Kernel: $kernel_version"

    # System uptime
   local uptime_info=$(uptime -p)
    success "Uptime: $uptime_info"

    # systemd availability
    if command -v systemctl &> /dev/null; then
        success "Systemd: available"
    else
        warning "Systemd: not available"
    fi

    # cgroups support
    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        success "Cgroups v2: supported"
    else
        info "Cgroups v1: in use"
    fi
    echo ""
}

# Final compatibility report
generate_summary() {
    section "ERNI-KI compatibility summary"

    local score=0
    local max_score=10
    local recommendations=()

    # CPU score
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -ge 8 ]; then
        score=$((score + 3))
        success "CPU: Excellent (${cpu_cores} cores)"
    elif [ "$cpu_cores" -ge 4 ]; then
        score=$((score + 2))
        info "CPU: Good (${cpu_cores} cores)"
    else
        score=$((score + 1))
        warning "CPU: Adequate (${cpu_cores} cores)"
        recommendations+=("Upgrade to 4+ cores for better performance")
    fi

    # RAM score
    local total_mem=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
    local total_gb=$((total_mem / 1024 / 1024))
    if [ "$total_gb" -ge 32 ]; then
        score=$((score + 3))
        success "RAM: Excellent (${total_gb} GB)"
    elif [ "$total_gb" -ge 16 ]; then
        score=$((score + 2))
        info "RAM: Good (${total_gb} GB)"
    elif [ "$total_gb" -ge 8 ]; then
        score=$((score + 1))
        warning "RAM: Minimal (${total_gb} GB)"
        recommendations+=("Recommended 16+ GB RAM for smoother workloads")
    else
        error "RAM: Insufficient (${total_gb} GB)"
        recommendations+=("CRITICAL: minimum 8 GB RAM required")
    fi

    # Disk score
    local root_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$root_usage" -lt 50 ]; then
        score=$((score + 2))
        success "Disk: ample free space"
    elif [ "$root_usage" -lt 80 ]; then
        score=$((score + 1))
        warning "Disk: limited free space"
        recommendations+=("Free up disk capacity")
    else
        error "Disk: critical free space"
        recommendations+=("CRITICAL: free disk space urgently")
    fi

    # GPU score
    if command -v nvidia-smi &> /dev/null; then
        score=$((score + 2))
        success "GPU: NVIDIA GPU available"
    else
        info "GPU: CPU-only mode"
        recommendations+=("NVIDIA GPU recommended for faster Ollama inference")
    fi

    # Overall score
    local percentage=$((score * 100 / max_score))
    echo ""
    if [ "$percentage" -ge 80 ]; then
        success "OVERALL SCORE: ${percentage}% — excellent fit"
    elif [ "$percentage" -ge 60 ]; then
        info "OVERALL SCORE: ${percentage}% — good fit"
    elif [ "$percentage" -ge 40 ]; then
        warning "OVERALL SCORE: ${percentage}% — adequate"
    else
        error "OVERALL SCORE: ${percentage}% — not recommended"
    fi

    # Recommendations
    if [ ${#recommendations[@]} -gt 0 ]; then
        echo ""
        warning "Suggested improvements:"
        for rec in "${recommendations[@]}"; do
            echo "  • $rec"
        done
    fi
}

# Main function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 ERNI-KI Hardware Analysis                    ║"
    echo "║             Comprehensive server hardware check              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    analyze_os
    analyze_cpu
    analyze_memory
    analyze_storage
    analyze_gpu
    analyze_network
    generate_summary

    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Analysis complete                         ║"
    echo "║         Results saved to hardware_report.txt                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Run analysis
main "$@" | tee hardware_report.txt
