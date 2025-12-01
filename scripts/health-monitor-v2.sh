#!/usr/bin/env bash

# ERNI-KI Unified Health Monitor (Refactored)
# Comprehensive health checking for all services
#
# Usage: ./health-monitor-v2.sh [options]
# Options:
#   -r, --report PATH     Save report to PATH (markdown format)
#   -f, --format FORMAT   Report format: markdown | text | json
#   -h, --help            Show help

set -euo pipefail

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# =============================================================================
# Configuration
# =============================================================================

PROJECT_ROOT=$(get_project_root)
COMPOSE_CMD=$(get_docker_compose_cmd)

# Load environment config if exists
HEALTH_MONITOR_ENV_FILE="${HEALTH_MONITOR_ENV_FILE:-${PROJECT_ROOT}/env/health-monitor.env}"
if [[ -f "$HEALTH_MONITOR_ENV_FILE" ]]; then
    log_debug "Loading config from: $HEALTH_MONITOR_ENV_FILE"
    set -a
    # shellcheck source=/dev/null
    source "$HEALTH_MONITOR_ENV_FILE"
    set +a
fi

# Health check parameters
LOG_WINDOW="${HEALTH_MONITOR_LOG_WINDOW:-5m}"
LOG_IGNORE_REGEX="${HEALTH_MONITOR_LOG_IGNORE_REGEX:-litellm\.proxy\.proxy_server\.user_api_key_auth|node-exporter.*(broken pipe|connection reset by peer)|cloudflared.*context canceled|redis-exporter.*Errorstats}"

# Report settings
REPORT_PATH=""
REPORT_FORMAT="markdown"

# Results tracking
declare -a RESULTS=()
FAILED=0
WARNINGS=0
PASSED=0

# =============================================================================
# Helper Functions
# =============================================================================

record_result() {
    local status="$1"
    local summary="$2"
    local details="$3"

    RESULTS+=("$status|$summary|$details")

    case "$status" in
        PASS)
            PASSED=$((PASSED + 1))
            log_success "$summary - $details"
            ;;
        WARN)
            WARNINGS=$((WARNINGS + 1))
            log_warn "$summary - $details"
            ;;
        FAIL)
            FAILED=$((FAILED + 1))
            log_error "$summary - $details"
            ;;
        *)
            log_info "$summary - $details"
            ;;
    esac
}

# =============================================================================
# Health Checks
# =============================================================================

check_compose_services() {
    log_info "Checking container status..."

    local compose_json
    local tmp_err
    tmp_err=$(mktemp)

    if ! compose_json="$(cd "$PROJECT_ROOT" && $COMPOSE_CMD ps --format json 2>"$tmp_err")"; then
        local compose_err
        compose_err="$(cat "$tmp_err")"
        rm -f "$tmp_err"
        record_result "FAIL" "Containers" "Failed to run docker compose ps: ${compose_err:-unknown error}"
        return
    fi
    rm -f "$tmp_err"

    local parsed
    if ! parsed="$(
        COMPOSE_JSON_PAYLOAD="$compose_json" python3 <<'PY'
from __future__ import annotations
import json
import os

data = json.loads(os.environ["COMPOSE_JSON_PAYLOAD"])
if not data:
    print("FAIL|0/0 services")
    exit(0)

total = len(data)
running = sum(1 for svc in data if svc.get("State") == "running")
healthy = sum(1 for svc in data if svc.get("Health") in ("healthy", ""))

unhealthy = []
for svc in data:
    state = svc.get("State", "unknown")
    health = svc.get("Health", "")
    if state != "running" or (health and health not in ("healthy", "")):
        unhealthy.append(svc["Name"])

if unhealthy:
    print(f"FAIL|{running}/{total} running, {healthy}/{total} healthy|Unhealthy: {', '.join(unhealthy)}")
elif running < total:
    print(f"WARN|{running}/{total} running, {healthy}/{total} healthy|Some services not running")
else:
    print(f"PASS|{total}/{total} services healthy|All services operational")
PY
    )"; then
        record_result "FAIL" "Containers" "Failed to parse docker compose output"
        return
    fi

    IFS='|' read -r status summary details <<< "$parsed"
    record_result "$status" "Containers: $summary" "$details"
}

check_critical_endpoints() {
    log_info "Checking critical HTTP endpoints..."

    local -A endpoints=(
        ["OpenWebUI"]="http://localhost:8080/health"
        ["LiteLLM"]="http://localhost:4000/health"
        ["Prometheus"]="http://localhost:9090/-/healthy"
        ["Grafana"]="http://localhost:3000/api/health"
    )

    local failures=0
    local checked=0

    for name in "${!endpoints[@]}"; do
        local url="${endpoints[$name]}"
        checked=$((checked + 1))

        if check_url "$url" 5; then
            log_debug "✓ $name endpoint OK"
        else
            failures=$((failures + 1))
            record_result "FAIL" "Endpoint $name" "URL not accessible: $url"
        fi
    done

    if [[ $failures -eq 0 ]]; then
        record_result "PASS" "HTTP Endpoints" "All $checked critical endpoints accessible"
    elif [[ $failures -lt $checked ]]; then
        record_result "WARN" "HTTP Endpoints" "$failures/$checked endpoints failed"
    fi
}

check_service_logs() {
    log_info "Checking service logs for errors..."

    local critical_services=("openwebui" "ollama" "db" "nginx" "litellm")
    local error_count=0
    local services_with_errors=()

    for service in "${critical_services[@]}"; do
        if ! is_service_running "$service"; then
            log_debug "Service $service not running, skipping log check"
            continue
        fi

        local logs
        logs=$(cd "$PROJECT_ROOT" && $COMPOSE_CMD logs --since "$LOG_WINDOW" "$service" 2>/dev/null || echo "")

        if [[ -n "$logs" ]]; then
            # Filter out ignored patterns
            logs=$(echo "$logs" | grep -Ev "$LOG_IGNORE_REGEX" || true)

            # Check for errors
            local errors
            errors=$(echo "$logs" | grep -iE "error|fatal|exception" | wc -l)

            if [[ $errors -gt 0 ]]; then
                error_count=$((error_count + errors))
                services_with_errors+=("$service($errors)")
            fi
        fi
    done

    if [[ $error_count -eq 0 ]]; then
        record_result "PASS" "Service Logs" "No errors in critical services (last $LOG_WINDOW)"
    elif [[ $error_count -lt 10 ]]; then
        record_result "WARN" "Service Logs" "$error_count errors found in: ${services_with_errors[*]}"
    else
        record_result "FAIL" "Service Logs" "$error_count errors found in: ${services_with_errors[*]}"
    fi
}

check_disk_space() {
    log_info "Checking disk space..."

    local usage
    usage=$(df -h "$PROJECT_ROOT" | tail -1 | awk '{print $5}' | sed 's/%//')

    if [[ $usage -lt 80 ]]; then
        record_result "PASS" "Disk Space" "${usage}% used"
    elif [[ $usage -lt 90 ]]; then
        record_result "WARN" "Disk Space" "${usage}% used (threshold: 80%)"
    else
        record_result "FAIL" "Disk Space" "${usage}% used (critical: 90%+)"
    fi
}

check_memory_usage() {
    log_info "Checking memory usage..."

    if command_exists free; then
        local mem_usage
        mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')

        if [[ $mem_usage -lt 80 ]]; then
            record_result "PASS" "Memory Usage" "${mem_usage}%"
        elif [[ $mem_usage -lt 90 ]]; then
            record_result "WARN" "Memory Usage" "${mem_usage}% (threshold: 80%)"
        else
            record_result "FAIL" "Memory Usage" "${mem_usage}% (critical: 90%+)"
        fi
    else
        record_result "WARN" "Memory Usage" "free command not available"
    fi
}

# =============================================================================
# Reporting
# =============================================================================

generate_report() {
    local format="$1"
    local output=""

    case "$format" in
        markdown)
            output="# ERNI-KI Health Report\n\n"
            output+="**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")\n\n"
            output+="## Summary\n\n"
            output+="- ✅ Passed: $PASSED\n"
            output+="- ⚠️  Warnings: $WARNINGS\n"
            output+="- ❌ Failed: $FAILED\n\n"
            output+="## Details\n\n"
            output+="| Status | Check | Details |\n"
            output+="|--------|-------|----------|\n"

            for result in "${RESULTS[@]}"; do
                IFS='|' read -r status summary details <<< "$result"
                local icon
                case "$status" in
                    PASS) icon="✅" ;;
                    WARN) icon="⚠️ " ;;
                    FAIL) icon="❌" ;;
                    *) icon="ℹ️ " ;;
                esac
                output+="| $icon | $summary | $details |\n"
            done
            ;;

        text)
            output="ERNI-KI Health Report\n"
            output+="Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")\n\n"
            output+="Summary:\n"
            output+="  Passed: $PASSED\n"
            output+="  Warnings: $WARNINGS\n"
            output+="  Failed: $FAILED\n\n"
            output+="Details:\n"

            for result in "${RESULTS[@]}"; do
                IFS='|' read -r status summary details <<< "$result"
                output+="  [$status] $summary - $details\n"
            done
            ;;

        json)
            output='{\n'
            output+="  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",\n"
            output+="  \"summary\": {\n"
            output+="    \"passed\": $PASSED,\n"
            output+="    \"warnings\": $WARNINGS,\n"
            output+="    \"failed\": $FAILED\n"
            output+="  },\n"
            output+="  \"checks\": [\n"

            local first=1
            for result in "${RESULTS[@]}"; do
                IFS='|' read -r status summary details <<< "$result"
                [[ $first -eq 0 ]] && output+=",\n"
                first=0
                output+="    {\n"
                output+="      \"status\": \"$status\",\n"
                output+="      \"summary\": \"$summary\",\n"
                output+="      \"details\": \"$details\"\n"
                output+="    }"
            done

            output+="\n  ]\n}\n"
            ;;
    esac

    echo -e "$output"
}

# =============================================================================
# Main
# =============================================================================

usage() {
    cat <<EOF
ERNI-KI Unified Health Monitor

Usage: $(basename "$0") [options]

Options:
  -r, --report PATH     Save report to PATH (default format: markdown)
  -f, --format FORMAT   Report format: markdown | text | json (default: markdown)
  -h, --help            Show this help message

Examples:
  $(basename "$0")                                    # Run health checks
  $(basename "$0") -r report.md                       # Save markdown report
  $(basename "$0") -r report.json -f json             # Save JSON report

Environment Variables:
  HEALTH_MONITOR_LOG_WINDOW        Log window to check (default: 5m)
  HEALTH_MONITOR_LOG_IGNORE_REGEX  Regex to ignore in logs
  DEBUG                            Enable debug output (0 or 1)
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--report)
                REPORT_PATH="$2"
                shift 2
                ;;
            -f|--format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate format
    if [[ ! "$REPORT_FORMAT" =~ ^(markdown|text|json)$ ]]; then
        log_fatal "Invalid format: $REPORT_FORMAT. Must be: markdown, text, or json"
    fi
}

main() {
    parse_args "$@"

    log_info "Starting ERNI-KI health monitoring..."

    # Run all health checks
    check_compose_services
    check_critical_endpoints
    check_service_logs
    check_disk_space
    check_memory_usage

    # Generate and display report
    local report
    report=$(generate_report "$REPORT_FORMAT")

    if [[ -n "$REPORT_PATH" ]]; then
        echo -e "$report" > "$REPORT_PATH"
        log_success "Report saved to: $REPORT_PATH"
    else
        echo -e "$report"
    fi

    # Exit with appropriate code
    if [[ $FAILED -gt 0 ]]; then
        log_error "Health check failed: $FAILED failures, $WARNINGS warnings"
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        log_warn "Health check completed with warnings: $WARNINGS warnings"
        exit 0
    else
        log_success "Health check passed: all $PASSED checks OK"
        exit 0
    fi
}

main "$@"
