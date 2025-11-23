#!/bin/bash

# ===== WATCHTOWER PERFORMANCE MONITORING SCRIPT =====
# Monitoring resources, execution time, and system impact

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs/watchtower"
METRICS_FILE="$LOG_DIR/performance-metrics.json"
REPORT_FILE="$LOG_DIR/performance-report.txt"

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create logs directory
mkdir -p "$LOG_DIR"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Get container metrics
get_container_metrics() {
    local container_name="$1"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if ! docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" "$container_name" 2>/dev/null; then
        error "Failed to get metrics for container $container_name"
        return 1
    fi
}

# Detailed metrics in JSON format
get_detailed_metrics() {
    local container_name="$1"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Get container statistics
    local stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}}" "$container_name" 2>/dev/null || echo "0.00%,0B / 0B,0B / 0B,0B / 0B")

    # Parse statistics
    IFS=',' read -r cpu_perc mem_usage net_io block_io <<< "$stats"

    # Extract numeric values
    cpu_value=$(echo "$cpu_perc" | sed 's/%//')
    mem_used=$(echo "$mem_usage" | cut -d'/' -f1 | sed 's/[^0-9.]//g')
    mem_total=$(echo "$mem_usage" | cut -d'/' -f2 | sed 's/[^0-9.]//g')

    # Create JSON
    cat << EOF
{
  "timestamp": "$timestamp",
  "container": "$container_name",
  "cpu_percent": "$cpu_value",
  "memory_used_mb": "$mem_used",
  "memory_total_mb": "$mem_total",
  "network_io": "$net_io",
  "block_io": "$block_io"
}
EOF
}

# Monitor Watchtower execution time
monitor_execution_time() {
    log "Monitoring Watchtower execution time..."

    local start_time=$(date +%s)
    local container_name="erni-ki-watchtower-1"

    # Get initial metrics
    local start_metrics=$(get_detailed_metrics "$container_name")

    # Wait for check cycle completion (max 5 minutes)
    local timeout=300
    local elapsed=0

    while [[ $elapsed -lt $timeout ]]; do
        if docker logs "$container_name" --since="$start_time" 2>/dev/null | grep -q "Session done"; then
            break
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done

    local end_time=$(date +%s)
    local execution_time=$((end_time - start_time))

    # Get final metrics
    local end_metrics=$(get_detailed_metrics "$container_name")

    # Save results
    cat << EOF >> "$METRICS_FILE"
{
  "execution_start": "$start_time",
  "execution_end": "$end_time",
  "execution_time_seconds": $execution_time,
  "start_metrics": $start_metrics,
  "end_metrics": $end_metrics
},
EOF

    success "Execution time: ${execution_time}s"
}

# Analyze Watchtower logs
analyze_logs() {
    log "Analyzing Watchtower logs..."

    local container_name="erni-ki-watchtower-1"
    local since_time="24h"

    # Get logs for the last 24 hours
    local logs=$(docker logs "$container_name" --since="$since_time" 2>/dev/null || echo "")

    if [[ -z "$logs" ]]; then
        warning "Watchtower logs unavailable"
        return 1
    fi

    # Analyze logs
    local total_sessions=$(echo "$logs" | grep -c "Session done" || echo "0")
    local failed_updates=$(echo "$logs" | grep -c "level=error" || echo "0")
    local successful_updates=$(echo "$logs" | grep -c "updated to" || echo "0")
    local skipped_containers=$(echo "$logs" | grep -c "Skipping" || echo "0")

    # Average time between checks
    local check_intervals=$(echo "$logs" | grep "Scheduled next run" | wc -l || echo "0")

    cat << EOF
=== WATCHTOWER LOG ANALYSIS (24h) ===
Total sessions: $total_sessions
Successful updates: $successful_updates
Errors: $failed_updates
Skipped containers: $skipped_containers
Scheduled checks: $check_intervals
EOF
}

# Check system impact
check_system_impact() {
    log "Checking system impact..."

    # Get overall system load
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/,//g')
    local memory_info=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    local disk_usage=$(df -h / | awk 'NR==2{print $5}')

    # Check number of running containers
    local running_containers=$(docker ps --format "table {{.Names}}" | wc -l)
    local total_containers=$(docker ps -a --format "table {{.Names}}" | wc -l)

    cat << EOF
=== SYSTEM IMPACT ===
CPU Load: $load_avg
Memory Usage: $memory_info
Disk Usage: $disk_usage
Running Containers: $running_containers
Total Containers: $total_containers
EOF
}

# Check schedule and next run
check_schedule() {
    log "Checking Watchtower schedule..."

    local container_name="erni-ki-watchtower-1"

    # Get next run info from logs
    local next_run=$(docker logs "$container_name" --tail=50 2>/dev/null | grep "Scheduled next run" | tail -1 | awk -F'Scheduled next run: ' '{print $2}' || echo "Not found")

    # Check schedule configuration
    local schedule_config=$(docker exec "$container_name" env | grep "WATCHTOWER_SCHEDULE" || echo "WATCHTOWER_SCHEDULE=not configured")

    cat << EOF
=== WATCHTOWER SCHEDULE ===
Configuration: $schedule_config
Next run: $next_run
EOF
}

# Generate performance report
generate_performance_report() {
    log "Generating performance report..."

    local timestamp=$(date +'%Y-%m-%d %H:%M:%S UTC')

    cat << EOF > "$REPORT_FILE"
===== WATCHTOWER PERFORMANCE REPORT =====
Generated at: $timestamp

$(check_system_impact)

$(analyze_logs)

$(check_schedule)

=== RECOMMENDATIONS ===
1. Optimal run time: 03:00 UTC (minimal load)
2. Check frequency: Daily (balance between freshness and load)
3. Resource monitoring: Memory limit 128MB, CPU 0.1 core
4. Image cleanup: Enabled to save space
5. Critical services: Excluded from auto-updates

=== QUALITY METRICS ===
- Execution time: <60 seconds (target)
- Memory usage: <128MB (limit)
- CPU impact: <5% (target)
- Update success rate: >95% (target)

=== NEXT STEPS ===
1. Configure notifications for critical errors
2. Integrate with monitoring system
3. Create rollback procedures for failed updates
4. Configure backup before updates

EOF

    success "Report saved: $REPORT_FILE"
}

# Optimize configuration
optimize_configuration() {
    log "Analyzing optimization opportunities..."

    local config_file="$PROJECT_DIR/env/watchtower.env"
    local suggestions=()

    # Check current configuration
    if ! grep -q "WATCHTOWER_SCHEDULE=" "$config_file"; then
        suggestions+=("Add schedule: WATCHTOWER_SCHEDULE=0 0 3 * * *")
    fi

    if ! grep -q "WATCHTOWER_CLEANUP=true" "$config_file"; then
        suggestions+=("Enable image cleanup: WATCHTOWER_CLEANUP=true")
    fi

    if ! grep -q "WATCHTOWER_LOG_FORMAT=json" "$config_file"; then
        suggestions+=("Use JSON logs: WATCHTOWER_LOG_FORMAT=json")
    fi

    if [[ ${#suggestions[@]} -gt 0 ]]; then
        warning "Optimization recommendations:"
        for suggestion in "${suggestions[@]}"; do
            echo "  - $suggestion"
        done
    else
        success "Configuration optimized"
    fi
}

# Main function
main() {
    local command="${1:-monitor}"

    case "$command" in
        "monitor")
            monitor_execution_time
            ;;
        "analyze")
            analyze_logs
            ;;
        "impact")
            check_system_impact
            ;;
        "schedule")
            check_schedule
            ;;
        "report")
            generate_performance_report
            ;;
        "optimize")
            optimize_configuration
            ;;
        "full")
            log "Starting full monitoring..."
            check_system_impact
            echo ""
            analyze_logs
            echo ""
            check_schedule
            echo ""
            optimize_configuration
            echo ""
            generate_performance_report
            ;;
        *)
            cat << EOF
Usage: $0 [COMMAND]

Commands:
    monitor   - Monitor execution time
    analyze   - Analyze logs
    impact    - Check system impact
    schedule  - Check schedule
    report    - Generate report
    optimize  - Optimization recommendations
    full      - Full analysis

Files:
    Metrics: $METRICS_FILE
    Report: $REPORT_FILE
EOF
            ;;
    esac
}

# Check environment
if [[ ! -f "$PROJECT_DIR/compose.yml" ]]; then
    error "Script must be run from ERNI-KI project"
    exit 1
fi

# Run
main "$@"
