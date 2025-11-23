#!/bin/bash
# GPU monitoring for ERNI-KI
# Author: Alteon Schultz (Tech Lead)

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

# Ensure nvidia-smi is available
check_nvidia_smi() {
    if ! command -v nvidia-smi &> /dev/null; then
        error "nvidia-smi not found. Please install NVIDIA drivers."
        exit 1
    fi
}

# Display GPU info
show_gpu_info() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    GPU Monitor ERNI-KI                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Basic GPU details
    local gpu_info=$(nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv,noheader,nounits)
    local gpu_name=$(echo "$gpu_info" | cut -d, -f1 | tr -d ' ')
    local driver_version=$(echo "$gpu_info" | cut -d, -f2 | tr -d ' ')
    local memory_total=$(echo "$gpu_info" | cut -d, -f3 | tr -d ' ')
    local compute_cap=$(echo "$gpu_info" | cut -d, -f4 | tr -d ' ')

    success "GPU: $gpu_name"
    success "Driver: $driver_version"
    success "Memory: ${memory_total} MB"
    success "Compute Capability: $compute_cap"
    echo ""
}

# Realtime monitoring
monitor_realtime() {
    local interval=${1:-2}

    echo -e "${CYAN}GPU monitoring (update every ${interval}s, Ctrl+C to exit)${NC}"
    echo ""

    # Table header
    printf "%-8s %-6s %-12s %-8s %-6s %-8s %-10s\n" "TIME" "GPU%" "MEMORY" "TEMP" "FAN" "POWER" "PROCESSES"
    echo "────────────────────────────────────────────────────────────────────────────"

    while true; do
        local timestamp=$(date +%H:%M:%S)

        # Read GPU metrics
        local gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
        local mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
        local mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
        local temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
        local fan=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits)
        local power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits)

        # Processes using GPU
        local processes=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader | wc -l)

        # Memory formatting
        local mem_percent=$(echo "scale=0; $mem_used * 100 / $mem_total" | bc 2>/dev/null || echo "0")
        local mem_display="${mem_used}/${mem_total}MB"

        # Color coding
        local gpu_color=""
        local temp_color=""
        local power_color=""

        # Color for GPU utilization
        if [ "$gpu_util" -gt 80 ]; then
            gpu_color="${RED}"
        elif [ "$gpu_util" -gt 50 ]; then
            gpu_color="${YELLOW}"
        else
            gpu_color="${GREEN}"
        fi

        # Color for temperature
        if [ "$temp" -gt 80 ]; then
            temp_color="${RED}"
        elif [ "$temp" -gt 70 ]; then
            temp_color="${YELLOW}"
        else
            temp_color="${GREEN}"
        fi

        # Color for power draw
        local power_int=$(echo "$power" | cut -d. -f1)
        if [ "$power_int" -gt 60 ]; then
            power_color="${RED}"
        elif [ "$power_int" -gt 40 ]; then
            power_color="${YELLOW}"
        else
            power_color="${GREEN}"
        fi

        # Print monitoring line
        printf "%-8s ${gpu_color}%-6s${NC} %-12s ${temp_color}%-6s°C${NC} %-6s%% ${power_color}%-8sW${NC} %-10s\n" \
            "$timestamp" "${gpu_util}%" "$mem_display" "$temp" "$fan" "$power" "$processes"

        sleep "$interval"
    done
}

# Short status
show_status() {
    local gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    local mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    local mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
    local temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    local power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits)

    echo "GPU Status:"
    echo "  Utilization: ${gpu_util}%"
    echo "  Memory: ${mem_used}/${mem_total} MB ($(echo "scale=0; $mem_used * 100 / $mem_total" | bc)%)"
    echo "  Temperature: ${temp}°C"
    echo "  Power: ${power}W"

    # Processes
    local processes=$(nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader)
    if [ -n "$processes" ]; then
        echo "  Processes:"
        echo "$processes" | while read line; do
            echo "    $line"
        done
    else
        echo "  Processes: none"
    fi
}

# GPU health check
health_check() {
    local issues=0

    echo "GPU health check:"

    # Temperature check
    local temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    if [ "$temp" -gt 85 ]; then
        error "Critical temperature: ${temp}°C"
        issues=$((issues + 1))
    elif [ "$temp" -gt 75 ]; then
        warning "High temperature: ${temp}°C"
    else
        success "Temperature is within limits: ${temp}°C"
    fi

    # Power draw check
    local power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits)
    local power_limit=$(nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits)
    local power_percent=$(echo "scale=0; $power * 100 / $power_limit" | bc)

    if [ "$power_percent" -gt 95 ]; then
        warning "High power consumption: ${power}W (${power_percent}%)"
    else
        success "Power consumption is within limits: ${power}W (${power_percent}%)"
    fi

    # Memory usage check
    local mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    local mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
    local mem_percent=$(echo "scale=0; $mem_used * 100 / $mem_total" | bc)

    if [ "$mem_percent" -gt 90 ]; then
        warning "High memory usage: ${mem_percent}%"
    else
        success "Memory usage is within limits: ${mem_percent}%"
    fi

    # ECC errors check (not supported on Quadro P2200)
    # local ecc_errors=$(nvidia-smi --query-gpu=ecc.errors.corrected.total --format=csv,noheader,nounits 2>/dev/null || echo "N/A")
    # if [[ "$ecc_errors" != "N/A" ]] && [[ "$ecc_errors" =~ ^[0-9]+$ ]] && [ "$ecc_errors" -gt 0 ]; then
    #     warning "ECC errors detected: $ecc_errors"
    # fi

    if [ "$issues" -eq 0 ]; then
        success "GPU is healthy"
        return 0
    else
        error "$issues GPU issues detected"
        return 1
    fi
}

# Log to file
log_to_file() {
    local logfile=${1:-"gpu_monitor.log"}
    local interval=${2:-60}

    log "Starting GPU logging to file: $logfile (interval: ${interval}s)"

    # Log header
    echo "timestamp,gpu_util,mem_used,mem_total,temp,fan,power,processes" > "$logfile"

    while true; do
        local timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
        local gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
        local mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
        local mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
        local temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
        local fan=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits)
        local power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits)
        local processes=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader | wc -l)

        echo "$timestamp,$gpu_util,$mem_used,$mem_total,$temp,$fan,$power,$processes" >> "$logfile"

        sleep "$interval"
    done
}

# Help text
show_help() {
    echo "GPU Monitor for ERNI-KI"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  monitor [interval]   - Realtime monitoring (default: 2s)"
    echo "  status               - Show current GPU status"
    echo "  health               - GPU health check"
    echo "  log [file] [interval]- Log metrics to file (default: gpu_monitor.log, 60s)"
    echo "  info                 - Show GPU info"
    echo "  help                 - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 monitor           - Monitor every 2 seconds"
    echo "  $0 monitor 5         - Monitor every 5 seconds"
    echo "  $0 status            - Short status"
    echo "  $0 health            - Health check"
    echo "  $0 log gpu.log 30    - Log every 30 seconds"
}

# Main function
main() {
    check_nvidia_smi

    case "${1:-monitor}" in
        "monitor")
            show_gpu_info
            monitor_realtime "${2:-2}"
            ;;
        "status")
            show_gpu_info
            show_status
            ;;
        "health")
            show_gpu_info
            health_check
            ;;
        "log")
            show_gpu_info
            log_to_file "${2:-gpu_monitor.log}" "${3:-60}"
            ;;
        "info")
            show_gpu_info
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Signal handling
trap 'echo -e "\n${CYAN}Monitoring stopped${NC}"; exit 0' INT TERM

# Launch
main "$@"
