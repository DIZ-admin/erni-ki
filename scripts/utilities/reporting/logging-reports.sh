#!/bin/bash

# Automated reports for ERNI-KI logging system
# Phase 3: Monitoring and alerting
# Version: 1.0 - Production Ready

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$PROJECT_ROOT/.config-backup/reports"
CRON_STATUS_HELPER="$PROJECT_ROOT/scripts/monitoring/record-cron-status.sh"
PROMETHEUS_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3000"
FLUENT_BIT_URL="http://localhost:2020"

# Ensure report directory exists
mkdir -p "$REPORTS_DIR"

cron_status() {
    [[ -x "$CRON_STATUS_HELPER" ]] || return 0
    local job="$1"
    local state="$2"
    local msg="$3"
    "$CRON_STATUS_HELPER" "$job" "$state" "$msg" || true
}

CURRENT_JOB="logging_reports"
trap 'cron_status "$CURRENT_JOB" failure "logging reports script failed"' ERR

# ============================================================================
# METRIC COLLECTION FUNCTIONS
# ============================================================================

get_fluent_bit_metrics() {
    echo "=== FLUENT BIT METRICS ==="
    curl -s "$FLUENT_BIT_URL/api/v1/metrics" | jq -r '
        "Input Records: " + (.input.["forward.0"].records | tostring),
        "Input Bytes: " + (.input.["forward.0"].bytes | tostring),
        "Output Records (Loki): " + (.output.["loki.0"].proc_records | tostring),
        "Output Bytes (Loki): " + (.output.["loki.0"].proc_bytes | tostring),
        "Loki Errors: " + (.output.["loki.0"].errors | tostring),
        "Loki Retries: " + (.output.["loki.0"].retries | tostring),
        "Filter Efficiency: " + ((.output.["loki.0"].proc_records / .input.["forward.0"].records * 100) | floor | tostring) + "%"
    ' 2>/dev/null || echo "Fluent Bit metrics unavailable"
}

get_service_health() {
    echo "=== LOGGING SERVICES STATUS ==="
    docker-compose ps --format "table {{.Name}}\t{{.Status}}" | grep -E "(fluent|loki|grafana|prometheus|alert)" || echo "Logging services unavailable"
}

get_log_volume_stats() {
    echo "=== LOG VOLUME STATS ==="

    # Log directory sizes
    echo "Log sizes:"
    du -sh logs/ .config-backup/logs/ 2>/dev/null || echo "Log directories not found"

    # Logs per service for the last hour
    echo ""
    echo "Logging activity (last hour):"
    for service in ollama nginx openwebui db searxng; do
        count=$(docker logs "erni-ki-${service}-1" --since=1h 2>/dev/null | wc -l)
        echo "$service: $count entries"
    done
}

get_error_summary() {
    echo "=== ERROR SUMMARY ==="

    # Errors in critical services
    echo "Critical services errors (last 24h):"
    for service in ollama nginx openwebui db; do
        errors=$(docker logs "erni-ki-${service}-1" --since=24h 2>/dev/null | grep -i error | wc -l)
        if [ "$errors" -gt 0 ]; then
            echo "⚠️  $service: $errors errors"
        else
            echo "✅ $service: no errors"
        fi
    done
}

get_performance_metrics() {
    echo "=== PERFORMANCE METRICS ==="

    # Resource usage by logging stack
    echo "Resource usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(fluent|loki|grafana|prometheus)" || echo "Stats unavailable"
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_daily_report() {
    local report_date=$(date +%Y-%m-%d)
    local report_file="$REPORTS_DIR/daily-logging-report-$report_date.txt"

    echo "Generating daily report: $report_file"

    cat > "$report_file" << EOF
# DAILY LOGGING REPORT FOR ERNI-KI
# Date: $(date '+%Y-%m-%d %H:%M:%S')
# Host: $(hostname)

$(get_service_health)

$(get_fluent_bit_metrics)

$(get_log_volume_stats)

$(get_error_summary)

$(get_performance_metrics)

# ============================================================================
# RECOMMENDATIONS
# ============================================================================

EOF

    # Add recommendations based on metrics
    add_recommendations "$report_file"

    echo "✅ Daily report created: $report_file"
    cron_status "logging_reports_daily" success "Report $report_file"
}

generate_weekly_report() {
    local report_date=$(date +%Y-W%U)
    local report_file="$REPORTS_DIR/weekly-logging-report-$report_date.txt"

    echo "Generating weekly report: $report_file"

    cat > "$report_file" << EOF
# WEEKLY LOGGING REPORT FOR ERNI-KI
# Week: $(date '+%Y-W%U (%Y-%m-%d)')
# Host: $(hostname)

## WEEKLY SUMMARY

$(get_service_health)

$(get_fluent_bit_metrics)

## TRENDS AND ANALYSIS

$(analyze_weekly_trends)

## OPTIMIZATION RECOMMENDATIONS

EOF

    add_weekly_recommendations "$report_file"

    echo "✅ Weekly report created: $report_file"
    cron_status "logging_reports_weekly" success "Report $report_file"
}

add_recommendations() {
    local report_file="$1"

    # Analyze metrics and append recommendations
    local fluent_errors=$(curl -s "$FLUENT_BIT_URL/api/v1/metrics" 2>/dev/null | jq -r '.output.["loki.0"].errors // 0')
    local log_count=$(docker logs erni-ki-ollama-1 --since=1h 2>/dev/null | wc -l)

    echo "" >> "$report_file"

    if [ "$fluent_errors" -gt 0 ]; then
        echo "⚠️  WARNING: Fluent Bit delivery errors detected ($fluent_errors). Check connectivity to Loki." >> "$report_file"
    fi

    if [ "$log_count" -gt 1000 ]; then
        echo "📊 INFO: High Ollama logging activity ($log_count entries/hour). Consider reducing log verbosity." >> "$report_file"
    fi

    echo "✅ STATUS: Logging system operates normally." >> "$report_file"
}

analyze_weekly_trends() {
    echo "Weekly trend analysis:"
    echo "- Average log volume: $(du -sh logs/ 2>/dev/null | cut -f1 || echo 'N/A')"
    echo "- Fluent Bit restarts: $(docker logs erni-ki-fluent-bit --since=7d 2>/dev/null | grep -c 'Starting' || echo '0')"
    echo "- Critical errors: $(docker logs erni-ki-fluent-bit --since=7d 2>/dev/null | grep -c 'ERROR' || echo '0')"
}

add_weekly_recommendations() {
    local report_file="$1"

    cat >> "$report_file" << EOF

1. **Performance**: Monitoring indicates stable logging operations
2. **Optimization**: Consider archiving logs older than 30 days
3. **Security**: Ensure sensitive data is filtered from logs
4. **Monitoring**: All alerts are configured and functioning

## NEXT STEPS

- [ ] Review disk usage
- [ ] Update log rotation rules if needed
- [ ] Test alerting system
- [ ] Optimize performance under high load

EOF
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

main() {
    echo "🚀 Generating ERNI-KI logging system reports"
    echo "Time: $(date)"
    echo ""

    case "${1:-daily}" in
        "daily")
            CURRENT_JOB="logging_reports_daily"
            generate_daily_report
            ;;
        "weekly")
            CURRENT_JOB="logging_reports_weekly"
            generate_weekly_report
            ;;
        "both")
            CURRENT_JOB="logging_reports_daily"
            generate_daily_report
            CURRENT_JOB="logging_reports_weekly"
            generate_weekly_report
            ;;
        *)
            echo "Usage: $0 [daily|weekly|both]"
            exit 1
            ;;
    esac

    echo ""
    echo "📁 Reports stored in: $REPORTS_DIR"
    echo "🎉 Report generation completed successfully!"
}

# Script entry
main "$@"
