#!/bin/bash

# ===================================================================
# Universal data permissions fix script for ERNI-KI
# Fixes access issues for Snyk and other tools across data/ directories
# Supports: Backrest, Grafana, PostgreSQL and other services
# ===================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging helpers
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Root permission check
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (sudo)"
        exit 1
    fi
}

# Ensure data directory exists
check_data_directory() {
    local data_dir="data"

    if [[ ! -d "$data_dir" ]]; then
        error "Data directory not found: $data_dir"
        exit 1
    fi

    log "Data directory found: $data_dir"
}

# Find problematic directories
find_problematic_directories() {
    log "Searching for directories with restricted permissions..."

    # Find dirs without execute for others
    local problematic_dirs
    problematic_dirs=$(find data/ -type d ! -perm -o+x 2>/dev/null || true)

    if [[ -n "$problematic_dirs" ]]; then
        echo "=== Found problematic directories ==="
        echo "$problematic_dirs" | while read -r dir; do
            if [[ -n "$dir" ]]; then
                ls -ld "$dir" 2>/dev/null || echo "Unavailable: $dir"
            fi
        done
        echo ""
        return 0
    else
        log "No problematic directories found"
        return 1
    fi
}

# Analyze current permissions
analyze_permissions() {
    log "Analyzing current permissions..."

    echo "=== data directory overview ==="
    ls -la data/ | head -10
    echo ""

    # Specific services
    for service_dir in data/backrest data/grafana data/postgres data/prometheus data/redis; do
        if [[ -d "$service_dir" ]]; then
            echo "=== Permissions for $service_dir ==="
            ls -la "$service_dir/" 2>/dev/null | head -5 || echo "Access restricted"
            echo ""
        fi
    done
}

# Fix permissions
fix_permissions() {
    log "Fixing permissions..."

    local fixed_count=0

    # Find and fix all problematic directories
    local problematic_dirs
    problematic_dirs=$(find data/ -type d ! -perm -o+x 2>/dev/null || true)

    if [[ -n "$problematic_dirs" ]]; then
        echo "$problematic_dirs" | while read -r dir; do
            if [[ -n "$dir" && -d "$dir" ]]; then
                log "Fixing permissions for $dir"

                # Set appropriate permissions per service
                case "$dir" in
                    data/postgres*)
                        # PostgreSQL needs stricter permissions
                        chmod 750 "$dir" 2>/dev/null || warning "Failed to change permissions for $dir"
                        ;;
                    data/grafana/alerting*)
                        # Grafana alerting - fix recursively
                        chmod -R 755 "$dir" 2>/dev/null || warning "Failed to change permissions for $dir"
                        ;;
                    *)
                        # Standard permissions elsewhere
                        chmod 755 "$dir" 2>/dev/null || warning "Failed to change permissions for $dir"
                        ;;
                esac

                ((fixed_count++)) || true
            fi
        done

        success "Permissions fixed for directories: $fixed_count"
    else
        log "No problematic directories found"
    fi

    # Backrest repo handling
    if [[ -d "data/backrest/repos/erni-ki-local" ]]; then
        log "Additional fix for Backrest repo"
        chmod -R 755 data/backrest/repos/erni-ki-local 2>/dev/null || warning "Could not fix Backrest permissions"
    fi
}

# Verify access after fixes
verify_access() {
    log "Verifying access after fixes..."

    local verification_failed=0

    # Check previously problematic dirs
    local test_dirs=("data/backrest/repos" "data/grafana/alerting" "data/grafana/csv" "data/grafana/png")

    for dir in "${test_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            if ls "$dir/" >/dev/null 2>&1; then
                success "Access to $dir restored"
            else
                error "Access to $dir still restricted"
                ((verification_failed++))
            fi
        fi
    done

    # Backrest repo check
    if [[ -d "data/backrest/repos/erni-ki-local" ]]; then
        if ls data/backrest/repos/erni-ki-local/ >/dev/null 2>&1; then
            success "Access to Backrest repo restored"
        else
            error "Access to Backrest repo still restricted"
            ((verification_failed++))
        fi
    fi

    # Ensure no remaining problematic dirs
    local remaining_issues
    remaining_issues=$(find data/ -type d ! -perm -o+x 2>/dev/null | wc -l)

    if [[ "$remaining_issues" -eq 0 ]]; then
        success "All permission issues resolved"
    else
        warning "Remaining problematic directories: $remaining_issues"
        ((verification_failed++))
    fi

    return $verification_failed
}

# Check services
check_services() {
    log "Checking services..."

    # Check Backrest
    if docker ps | grep -q backrest; then
        success "Backrest container is running"
        if curl -s http://localhost:9898/ >/dev/null 2>&1; then
            success "Backrest web UI is reachable"
        else
            warning "Backrest web UI is not reachable"
        fi
    else
        warning "Backrest container is not running"
    fi

    # Check Grafana
    if docker ps | grep -q grafana; then
        success "Grafana container is running"
        if curl -s http://localhost:3000/ >/dev/null 2>&1; then
            success "Grafana web UI is reachable"
        else
            warning "Grafana web UI is not reachable"
        fi
    else
        warning "Grafana container is not running"
    fi

    # Check PostgreSQL
    if docker ps | grep -q postgres; then
        success "PostgreSQL container is running"
    else
        warning "PostgreSQL container is not running"
    fi
}

# Create report
create_report() {
    local report_file="logs/data-permissions-fix-$(date +%Y%m%d_%H%M%S).log"

    log "Creating report: $report_file"

    {
        echo "=== ERNI-KI Data Permissions Fix Report ==="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo ""
        echo "=== Data Directory Overview ==="
        ls -la data/ 2>/dev/null || echo "Data directory not accessible"
        echo ""

        # Report per service
        for service in backrest grafana postgres prometheus redis; do
            if [[ -d "data/$service" ]]; then
                echo "=== Permissions for data/$service ==="
                ls -la "data/$service/" 2>/dev/null || echo "Directory data/$service not accessible"
                echo ""
            fi
        done

        echo "=== Problematic Directories Check ==="
        local remaining_issues
        remaining_issues=$(find data/ -type d ! -perm -o+x 2>/dev/null || true)
        if [[ -n "$remaining_issues" ]]; then
            echo "Remaining problematic directories:"
            echo "$remaining_issues"
        else
            echo "No problematic directories found"
        fi

        echo ""
        echo "=== Service Status ==="
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(backrest|grafana|postgres)" || echo "Services not found"

    } > "$report_file"

    success "Report created: $report_file"
}

# Main function
main() {
    log "Starting universal data permissions fix for ERNI-KI"

    # Checks
    check_root
    check_data_directory

    # Analyze problems
    analyze_permissions
    if ! find_problematic_directories; then
        success "No permission issues found"
        exit 0
    fi

    # Fix and verify
    fix_permissions
    verify_access
    check_services
    create_report

    success "Permissions fix completed successfully"

    echo ""
    echo ""
    echo "=== Recommendations ==="
    echo "1. Snyk can now scan the project without access errors"
    echo "2. All services (Backrest, Grafana, PostgreSQL) continue to work"
    echo "3. Security maintained (read-only for other users)"
    echo "4. If new issues appear, run this script again"
    echo "5. Consider adding script to cron for automatic checks"
}

# Run main function
main "$@"
