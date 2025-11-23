#!/bin/bash
# Quick audit of ERNI-KI system to create report
# Simplified version for detailed report generation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Report variables
AUDIT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
AUDIT_REPORT_FILE="comprehensive-audit-report-$(date +%Y%m%d_%H%M%S).md"

# Collect system information
collect_system_info() {
    log "Gathering system information..."

    HOSTNAME=$(hostname)
    USER=$(whoami)
    DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Not installed")
    COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "Not installed")

    # System resources
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1 2>/dev/null || echo "N/A")
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "N/A")
    DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' 2>/dev/null || echo "N/A")

    success "System information collected"
}

# Security audit
audit_security() {
    log "Performing security audit..."

    SECURITY_ISSUES=()

    # Check for default passwords in production files
    if grep -r "CHANGE_BEFORE_GOING_LIVE\|password123\|admin123" env/ --exclude="*.example" 2>/dev/null; then
        SECURITY_ISSUES+=("CRITICAL|Default passwords|Unreplaced default passwords found in production files|Replace all default passwords with secure ones")
    fi

    # Check .env file permissions
    if find env/ -name "*.env" -not -name "*.example" -not -perm 600 2>/dev/null | grep -q .; then
        SECURITY_ISSUES+=("HIGH|Weak file permissions|Secret files have overly permissive rights|Set 600 permissions on all .env files")
    fi

    # Check Docker socket
    if grep -q "/var/run/docker.sock" compose.yml 2>/dev/null; then
        SECURITY_ISSUES+=("MEDIUM|Docker socket exposure|Containers have access to Docker socket|Restrict socket access to required services")
    fi

    # Check SSL/TLS
    if ! grep -q "ssl\|tls\|https" conf/nginx/ 2>/dev/null; then
        SECURITY_ISSUES+=("HIGH|Missing SSL/TLS|Web traffic is unencrypted|Configure SSL/TLS certificates")
    fi

    success "Security audit complete (${#SECURITY_ISSUES[@]} issues found)"
}

# Performance audit
audit_performance() {
    log "Performing performance audit..."

    PERFORMANCE_ISSUES=()

    # Check resource usage
    if [ "$CPU_USAGE" != "N/A" ] && [ "$CPU_USAGE" -gt 80 ] 2>/dev/null; then
        PERFORMANCE_ISSUES+=("MEDIUM|High CPU load|CPU at ${CPU_USAGE}%|Tune workloads or add resources")
    fi

    if [ "$MEMORY_USAGE" != "N/A" ] && [ "${MEMORY_USAGE%.*}" -gt 85 ] 2>/dev/null; then
        PERFORMANCE_ISSUES+=("MEDIUM|High memory usage|RAM at ${MEMORY_USAGE}%|Optimize memory use or increase RAM")
    fi

    if [ "$DISK_USAGE" != "N/A" ] && [ "${DISK_USAGE%\%}" -gt 85 ] 2>/dev/null; then
        PERFORMANCE_ISSUES+=("HIGH|Low disk space|Disk at ${DISK_USAGE}|Clean up disk or expand storage")
    fi

    # Check resource limits
    if ! grep -q "mem_limit\|cpus\|memory" compose.yml 2>/dev/null; then
        PERFORMANCE_ISSUES+=("MEDIUM|Missing resource limits|Containers may consume unlimited resources|Define mem_limit and cpus for all services")
    fi

    success "Performance audit complete (${#PERFORMANCE_ISSUES[@]} issues found)"
}

# Reliability audit
audit_reliability() {
    log "Performing reliability audit..."

    RELIABILITY_ISSUES=()

    # Check health checks
    SERVICES_WITHOUT_HEALTHCHECK=()
    while IFS= read -r service; do
        if ! grep -A 10 "^  $service:" compose.yml | grep -q "healthcheck:" 2>/dev/null; then
            SERVICES_WITHOUT_HEALTHCHECK+=("$service")
        fi
    done < <(grep -E "^  [a-zA-Z].*:" compose.yml | sed 's/://g' | awk '{print $1}' 2>/dev/null || true)

    if [ ${#SERVICES_WITHOUT_HEALTHCHECK[@]} -gt 0 ]; then
        RELIABILITY_ISSUES+=("MEDIUM|Missing health checks|Services ${SERVICES_WITHOUT_HEALTHCHECK[*]} lack health probes|Add healthcheck for all critical services")
    fi

    # Check restart policies
    if ! grep -q "restart:" compose.yml 2>/dev/null; then
        RELIABILITY_ISSUES+=("MEDIUM|Missing restart policies|Some services won't auto-restart|Use restart: unless-stopped for each service")
    fi

    # Check backup system
    if [ ! -d ".config-backup" ] || [ ! "$(ls -A .config-backup 2>/dev/null)" ]; then
        RELIABILITY_ISSUES+=("HIGH|No backups|Backrest missing or empty|Setup and test backup system")
    fi

    success "Reliability audit complete (${#RELIABILITY_ISSUES[@]} issues found)"
}

# Configuration audit
audit_configuration() {
    log "Performing configuration audit..."

    CONFIG_ISSUES=()

    # Check Docker Compose version
    COMPOSE_VERSION_NUM=$(grep "version:" compose.yml | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'" 2>/dev/null || echo "")
    if [ -z "$COMPOSE_VERSION_NUM" ]; then
        CONFIG_ISSUES+=("LOW|Missing Compose version|Docker Compose file lacks version declaration|Add version: '3.8' at top")
    fi

    # Check example files
    for env_file in env/*.env; do
        if [ -f "$env_file" ]; then
            example_file="${env_file}.example"
            if [ ! -f "$example_file" ]; then
                CONFIG_ISSUES+=("LOW|Missing example file|No $example_file|Create example with safe defaults")
            fi
        fi
    done 2>/dev/null || true

    # Check bind mounts
    if grep -E "^\s*-\s*\./.*:" compose.yml | grep -v ":ro" 2>/dev/null; then
        CONFIG_ISSUES+=("MEDIUM|Unsafe bind mounts|Read-write bind mounts allow changes|Use :ro where possible")
    fi

    success "Configuration audit complete (${#CONFIG_ISSUES[@]} issues found)"
}

# Count issues by severity
count_issues_by_severity() {
    CRITICAL_COUNT=0
    HIGH_COUNT=0
    MEDIUM_COUNT=0
    LOW_COUNT=0

    # Combine all issue arrays
    ALL_ISSUES=()
    ALL_ISSUES+=("${SECURITY_ISSUES[@]}")
    ALL_ISSUES+=("${PERFORMANCE_ISSUES[@]}")
    ALL_ISSUES+=("${RELIABILITY_ISSUES[@]}")
    ALL_ISSUES+=("${CONFIG_ISSUES[@]}")

    for issue in "${ALL_ISSUES[@]}"; do
        severity=$(echo "$issue" | cut -d'|' -f1)
        case $severity in
            "CRITICAL") ((CRITICAL_COUNT++)) ;;
            "HIGH") ((HIGH_COUNT++)) ;;
            "MEDIUM") ((MEDIUM_COUNT++)) ;;
            "LOW") ((LOW_COUNT++)) ;;
        esac
    done
}

# Generate report
generate_report() {
    log "Creating detailed report..."

    cat > "$AUDIT_REPORT_FILE" << EOF
# 🔍 ERNI-KI Pre-production Audit

**Audit date**: $AUDIT_DATE
**System**: $HOSTNAME
**User**: $USER
**Docker version**: $DOCKER_VERSION
**Docker Compose version**: $COMPOSE_VERSION

## 📊 Results summary

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| Security | $(echo "${SECURITY_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#SECURITY_ISSUES[@]} |
| Performance | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#PERFORMANCE_ISSUES[@]} |
| Reliability | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#RELIABILITY_ISSUES[@]} |
| Configuration | $(echo "${CONFIG_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#CONFIG_ISSUES[@]} |
| **TOTAL** | **$CRITICAL_COUNT** | **$HIGH_COUNT** | **$MEDIUM_COUNT** | **$LOW_COUNT** | **$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))** |

## 🎯 Production readiness

EOF

    # Determine overall readiness
    if [ $CRITICAL_COUNT -eq 0 ] && [ $HIGH_COUNT -eq 0 ]; then
        echo "✅ **READY FOR PRODUCTION** - No critical or high issues" >> "$AUDIT_REPORT_FILE"
    elif [ $CRITICAL_COUNT -eq 0 ] && [ $HIGH_COUNT -le 2 ]; then
        echo "⚠️ **CONDITIONALLY READY** - Resolve outstanding high issues" >> "$AUDIT_REPORT_FILE"
    else
        echo "❌ **NOT READY** - Critical issues must be resolved first" >> "$AUDIT_REPORT_FILE"
    fi

    # Add detailed sections
    add_detailed_sections

    success "Report saved: $AUDIT_REPORT_FILE"
}

# Add detailed sections to report
add_detailed_sections() {
    cat >> "$AUDIT_REPORT_FILE" << 'EOF'

## 📈 System resources

EOF

    echo "- **CPU**: ${CPU_USAGE}% utilized" >> "$AUDIT_REPORT_FILE"
    echo "- **Memory**: ${MEMORY_USAGE}% used" >> "$AUDIT_REPORT_FILE"
    echo "- **Disk**: ${DISK_USAGE} full" >> "$AUDIT_REPORT_FILE"
    echo "" >> "$AUDIT_REPORT_FILE"

    add_issues_section "🔒 Security audit" "${SECURITY_ISSUES[@]}"
    add_issues_section "⚡ Performance audit" "${PERFORMANCE_ISSUES[@]}"
    add_issues_section "🛡️ Reliability audit" "${RELIABILITY_ISSUES[@]}"
    add_issues_section "⚙️ Configuration audit" "${CONFIG_ISSUES[@]}"

    cat >> "$AUDIT_REPORT_FILE" << 'EOF'

## 💡 Priority recommendations

### 🔴 Critical
- Replace default passwords with secure values
- Deploy SSL/TLS for all public services
- Patch critical security vulnerabilities

### 🟠 High
- Apply resource limits to every container
- Add health checks for critical services
- Validate and test backup routines

### 🟡 Medium
- Optimize PostgreSQL configuration
- Implement centralized logging & monitoring
- Restrict Docker socket access

### 🟢 Low
- Update Docker Compose to the latest stable version
- Provide sample configs for every env file
- Deploy custom Docker networks for isolation

## 📅 4-week action plan

### Week 1: Security hardening
- [ ] Replace default passwords
- [ ] Deploy SSL/TLS certificates
- [ ] Correct file permissions
- [ ] Conduct network security audit

### Week 2: Reliability improvements
- [ ] Enforce resource limits
- [ ] Expand health checks
- [ ] Test backup routines
- [ ] Validate restart policies

### Week 3: Performance tuning
- [ ] Optimize PostgreSQL
- [ ] Monitor resource usage
- [ ] Centralize logging
- [ ] Execute load testing

### Week 4: Finalization
- [ ] Refresh configuration files
- [ ] Document missing procedures
- [ ] Perform final acceptance testing
- [ ] Prepare for production rollout

## 📋 Production readiness checklist

### Security ✅
- [ ] Replace default passwords
- [ ] Enable SSL/TLS
- [ ] Ensure .env files use 600 perms
- [ ] Harden networking
- [ ] Apply firewall rules

### Performance ⚡
- [ ] Tune system resources
- [ ] Enforce resource limits
- [ ] Optimize the database
- [ ] Configure caching
- [ ] Run load tests

### Reliability 🛡️
- [ ] Add health checks
- [ ] Enforce restart policies
- [ ] Verify backups
- [ ] Document disaster recovery procedures
- [ ] Keep monitoring & alerting online

### Configuration ⚙️
- [ ] Validate Docker Compose files
- [ ] Document environment variables
- [ ] Optimize volumes and networks
- [ ] Keep documentation current
- [ ] Test deployment procedures

---

**Report generated**: $(date)
**Tool**: ERNI-KI Quick Audit Script
**Version**: 1.0
**Status**: Ready for technical briefing

EOF
}

}

# Function to add issues to report
add_issues_section() {
    local section_title="$1"
    shift
    local issues=("$@")

    cat >> "$AUDIT_REPORT_FILE" << EOF

## $section_title

EOF

    if [ ${#issues[@]} -eq 0 ]; then
        echo "✅ No issues detected" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Issues found" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${issues[@]}"; do
            IFS='|' read -r severity title description recommendation <<< "$issue"
            echo "#### [$severity] $title" >> "$AUDIT_REPORT_FILE"
            echo "**Description**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Recommendation**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

# Main function
main() {
    log "Running ERNI-KI quick audit..."
    echo "Audit date: $AUDIT_DATE"
    echo "Report will be saved to: $AUDIT_REPORT_FILE"
    echo ""

    collect_system_info
    audit_security
    audit_performance
    audit_reliability
    audit_configuration
    count_issues_by_severity
    generate_report

    echo ""
    success "Comprehensive audit complete!"
    echo "Report saved to: $AUDIT_REPORT_FILE"
    echo ""
    echo "Issue summary:"
    echo "  🔴 Critical: $CRITICAL_COUNT"
    echo "  🟠 High: $HIGH_COUNT"
    echo "  🟡 Medium: $MEDIUM_COUNT"
    echo "  🟢 Low: $LOW_COUNT"
    echo "  📊 Total: $((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))"
}

# Run audit
main "$@"
