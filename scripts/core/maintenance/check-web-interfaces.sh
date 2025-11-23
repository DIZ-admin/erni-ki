#!/bin/bash

# Web interface availability check for ERNI-KI
# Author: Alteon Schultz (ERNI-KI Tech Lead)

set -euo pipefail

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Parameters
VERBOSE=false
MAIN_ONLY=false
TIMEOUT=10

# Logging helpers
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# URL checker
check_url() {
    local name="$1"
    local url="$2"
    local expected_codes="${3:-200,302,307}"
    local header="${4:-}"

    local status_code
    if [[ -n "$header" ]]; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT -H "$header" "$url" 2>/dev/null || echo "000")
    else
        status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT "$url" 2>/dev/null || echo "000")
    fi

    if [[ ",$expected_codes," == *",$status_code,"* ]]; then
        success "$(printf "%-25s %-30s %s" "$name" "$url" "$status_code")"
        return 0
    else
        error "$(printf "%-25s %-30s %s" "$name" "$url" "$status_code")"
        return 1
    fi
}

# Check core AI services
check_ai_services() {
    header "AI SERVICES"
    printf "%-25s %-30s %s\n" "SERVICE" "URL" "STATUS"
    echo "------------------------------------------------------------------------"

    local failed=0

    check_url "OpenWebUI (Local)" "http://localhost:8080" "200" || ((failed++))
    check_url "OpenWebUI (HTTPS)" "https://diz.zone" "200" || ((failed++))
    check_url "LiteLLM" "http://localhost:4000" "200,404" || ((failed++))

    echo ""
    if [ $failed -eq 0 ]; then
        success "All AI services are reachable"
    else
        warning "$failed AI services are unreachable"
    fi

    return $failed
}

# Check monitoring and analytics
check_monitoring() {
    header "MONITORING & ANALYTICS"
    printf "%-25s %-30s %s\n" "SERVICE" "URL" "STATUS"
    echo "------------------------------------------------------------------------"

    local failed=0

    check_url "Grafana" "http://localhost:3000" "200,302" || ((failed++))
    check_url "Prometheus" "http://localhost:9091" "200,302" || ((failed++))
    check_url "Alertmanager" "http://localhost:9093" "200" || ((failed++))
    check_url "Loki" "http://localhost:3100/ready" "200,204" "X-Scope-OrgID: erni-ki" || ((failed++))

    echo ""
    if [ $failed -eq 0 ]; then
        success "All monitoring services are reachable"
    else
        warning "$failed monitoring services are unreachable"
    fi

    return $failed
}

# Check admin services
check_admin() {
    header "ADMINISTRATION"
    printf "%-25s %-30s %s\n" "SERVICE" "URL" "STATUS"
    echo "------------------------------------------------------------------------"

    local failed=0

    check_url "Backrest" "http://localhost:9898" "200" || ((failed++))
    check_url "Auth Server" "http://localhost:9090" "200,404" || ((failed++))
    check_url "cAdvisor" "http://localhost:8081" "200,307" || ((failed++))
    check_url "Tika" "http://localhost:9998" "200" || ((failed++))

    echo ""
    if [ $failed -eq 0 ]; then
        success "All admin services are reachable"
    else
        warning "$failed admin services are unreachable"
    fi

    return $failed
}

# Check exporters
check_exporters() {
    header "EXPORTERS & METRICS"
    printf "%-25s %-30s %s\n" "SERVICE" "URL" "STATUS"
    echo "------------------------------------------------------------------------"

    local failed=0

    check_url "Node Exporter" "http://localhost:9101/metrics" "200" || ((failed++))
    check_url "PostgreSQL Exporter" "http://localhost:9187/metrics" "200" || ((failed++))
    check_url "Redis Exporter" "http://localhost:9121/metrics" "200" || ((failed++))
    check_url "NVIDIA Exporter" "http://localhost:9445/metrics" "200" || ((failed++))
    check_url "Blackbox Exporter" "http://localhost:9115/metrics" "200" || ((failed++))
    check_url "Webhook Receiver" "http://localhost:9095/health" "200" || ((failed++))

    echo ""
    if [ $failed -eq 0 ]; then
        success "All exporters are reachable"
    else
        warning "$failed exporters are unreachable"
    fi

    return $failed
}

# Credentials reference
check_credentials() {
    header "CREDENTIALS"
    echo "Default credentials for local access:"
    echo ""
    echo "OpenWebUI:"
    echo "  Email: diz-admin@proton.me"
    echo "  Password: testpass"
    echo "  URL: https://diz.zone"
    echo ""
    echo "Grafana:"
    echo "  Login: admin"
    echo "  Password: erni-ki-admin-2025"
    echo "  URL: http://localhost:3000"
    echo ""
    echo "Backrest:"
    echo "  Login: admin"
    echo "  Password: (not set - configure!)"
    echo "  URL: http://localhost:9898"
    echo ""
    warning "IMPORTANT: Change all default passwords in production!"
}

# Summary
show_summary() {
    local total_failed=$1

    header "RESULT SUMMARY"

    if [ $total_failed -eq 0 ]; then
        success "🎉 ALL WEB INTERFACES ARE AVAILABLE!"
        echo ""
        echo "✅ AI services: Healthy"
        echo "✅ Monitoring: Healthy"
        echo "✅ Administration: Healthy"
        echo "✅ Exporters: Healthy"
        echo ""
        echo "ERNI-KI is ready for use."
    else
        error "⚠️ ISSUES DETECTED: $total_failed services unreachable"
        echo ""
        echo "Recommendations:"
        echo "1. Check logs of problematic services"
        echo "2. Ensure all containers are running"
        echo "3. Verify network settings"
        echo "4. Restart problematic services"
    fi
}

# Help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --main-only    Check only core services"
    echo "  --verbose      Verbose output"
    echo "  --timeout N    Connection timeout (default: 10s)"
    echo "  --help         Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full check"
    echo "  $0 --main-only       # Core services only"
    echo "  $0 --verbose         # Verbose mode"
}

# Arguments handling
while [[ $# -gt 0 ]]; do
    case $1 in
        --main-only)
            MAIN_ONLY=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main
main() {
    echo "=================================================="
    echo "🔍 ERNI-KI WEB INTERFACE CHECK"
    echo "=================================================="
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Host: $(hostname)"
    echo "Timeout: ${TIMEOUT}s"
    echo ""

    local total_failed=0

    # AI services
    check_ai_services || total_failed=$((total_failed + $?))
    echo ""

    # Monitoring
    check_monitoring || total_failed=$((total_failed + $?))
    echo ""

    # Administration
    check_admin || total_failed=$((total_failed + $?))
    echo ""

    # Exporters (when not limited to core)
    if [ "$MAIN_ONLY" = false ]; then
        check_exporters || total_failed=$((total_failed + $?))
        echo ""
    fi

    # Show credentials (when verbose)
    if [ "$VERBOSE" = true ]; then
        check_credentials
        echo ""
    fi

    # Summary
    show_summary $total_failed
    echo ""
    echo "=================================================="

    # Exit with error count
    exit $total_failed
}

# Entry
main "$@"
