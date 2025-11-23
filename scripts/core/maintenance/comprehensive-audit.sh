#!/bin/bash
# Comprehensive pre-production audit of ERNI-KI system
# Performs complete security, performance, reliability and configuration checks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

# Global variables for report
AUDIT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
AUDIT_REPORT_FILE="audit-report-$(date +%Y%m%d_%H%M%S).md"
SECURITY_ISSUES=()
PERFORMANCE_ISSUES=()
RELIABILITY_ISSUES=()
CONFIG_ISSUES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

# Function to add issue to report
add_issue() {
    local category="$1"
    local severity="$2"
    local title="$3"
    local description="$4"
    local recommendation="$5"

    case $severity in
        "CRITICAL") ((CRITICAL_COUNT++)) ;;
        "HIGH") ((HIGH_COUNT++)) ;;
        "MEDIUM") ((MEDIUM_COUNT++)) ;;
        "LOW") ((LOW_COUNT++)) ;;
    esac

    local issue="**[$severity]** $title|$description|$recommendation"

    case $category in
        "SECURITY") SECURITY_ISSUES+=("$issue") ;;
        "PERFORMANCE") PERFORMANCE_ISSUES+=("$issue") ;;
        "RELIABILITY") RELIABILITY_ISSUES+=("$issue") ;;
        "CONFIG") CONFIG_ISSUES+=("$issue") ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    section "Checking prerequisites"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        critical "Docker is not installed"
        add_issue "CONFIG" "CRITICAL" "Docker not found" "Docker is not installed on the system" "Install Docker"
        return 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        critical "Docker Compose not found"
        add_issue "CONFIG" "CRITICAL" "Docker Compose not found" "Docker Compose is not installed" "Install Docker Compose"
        return 1
    fi

    # Check project files
    if [ ! -f "compose.yml" ]; then
        critical "File compose.yml not found"
        add_issue "CONFIG" "CRITICAL" "Missing compose.yml" "Main configuration file not found" "Create compose.yml from compose.yml.example"
        return 1
    fi

    success "Prerequisites met"
    return 0
}

# Security audit
audit_security() {
    section "SECURITY AUDIT"

    # Check secret files
    log "Checking secrets management..."

    # Check .env files
    if find env/ -name "*.env" -exec grep -l "password\|secret\|key" {} \; 2>/dev/null | grep -q .; then
        warning "Secrets found in .env files"

        # Check for default passwords (excluding example files)
        if grep -r "CHANGE_BEFORE_GOING_LIVE\|password123\|admin123" env/ --exclude="*.example" 2>/dev/null; then
            critical "Default passwords found"
            add_issue "SECURITY" "CRITICAL" "Default passwords" "Unchanged default passwords detected in production files" "Replace all default passwords with secure ones"
        fi

        # Check secret file permissions (excluding example files)
        if find env/ -name "*.env" -not -name "*.example" -not -perm 600 2>/dev/null | grep -q .; then
            error "Insecure permissions for .env files"
            add_issue "SECURITY" "HIGH" "Insecure permissions" "Files with secrets have overly open permissions" "Set permissions to 600 for all .env files"
        fi
    fi

    # Check Docker security configuration
    log "Checking Docker configuration..."

    # Check for privileged containers
    if grep -q "privileged.*true" compose.yml 2>/dev/null; then
        error "Privileged containers found"
        add_issue "SECURITY" "HIGH" "Privileged containers" "Containers running with privileged rights" "Remove privileged: true or justify necessity"
    fi

    # Check Docker socket mounting
    if grep -q "/var/run/docker.sock" compose.yml 2>/dev/null; then
        warning "Docker socket mounted in containers"
        add_issue "SECURITY" "MEDIUM" "Docker socket access" "Containers have access to Docker socket" "Limit access to necessary services only"
    fi

    # Check network configuration
    log "Checking network security..."

    # Check open ports
    if grep -E "ports:" compose.yml | grep -E "0\.0\.0\.0|::" 2>/dev/null; then
        warning "Ports open to all interfaces"
        add_issue "SECURITY" "MEDIUM" "Open ports" "Services accessible on all network interfaces" "Limit port access to necessary interfaces only"
    fi

    # Check SSL/TLS configuration
    if ! grep -q "ssl\|tls\|https" conf/nginx/ 2>/dev/null; then
        error "SSL/TLS not configured"
        add_issue "SECURITY" "HIGH" "Missing SSL/TLS" "Web traffic is not encrypted" "Configure SSL/TLS certificates"
    fi

    success "Security audit completed"
}

# Performance audit
audit_performance() {
    section "PERFORMANCE AUDIT"

    # Check system resources
    log "Analyzing system resources..."

    # Check CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
    if [ "$CPU_USAGE" -gt 80 ] 2>/dev/null; then
        warning "High CPU usage: ${CPU_USAGE}%"
        add_issue "PERFORMANCE" "MEDIUM" "High CPU load" "CPU load is ${CPU_USAGE}%" "Optimize processes or increase resources"
    fi

    # Check memory usage
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$MEMORY_USAGE" -gt 85 ] 2>/dev/null; then
        warning "High memory usage: ${MEMORY_USAGE}%"
        add_issue "PERFORMANCE" "MEDIUM" "High memory usage" "RAM usage is ${MEMORY_USAGE}%" "Optimize memory usage or increase RAM"
    fi

    # Check disk space
    DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    if [ "$DISK_USAGE" -gt 85 ]; then
        error "Critically low disk space: ${DISK_USAGE}%"
        add_issue "PERFORMANCE" "HIGH" "Low disk space" "Disk is ${DISK_USAGE}% full" "Clean up disk or increase storage"
    fi

    # Check Docker resource configuration
    log "Checking container resource limits..."

    if ! grep -q "mem_limit\|cpus\|memory" compose.yml 2>/dev/null; then
        warning "Resource limits not configured for containers"
        add_issue "PERFORMANCE" "MEDIUM" "Missing resource limits" "Containers can consume unlimited resources" "Configure mem_limit and cpus for all services"
    fi

    # Check database configuration
    log "Checking PostgreSQL configuration..."

    if [ -f "conf/postgres/postgresql.conf" ]; then
        # Check shared_buffers
        if ! grep -q "shared_buffers" conf/postgres/postgresql.conf 2>/dev/null; then
            warning "shared_buffers not configured"
            add_issue "PERFORMANCE" "MEDIUM" "PostgreSQL not optimized" "shared_buffers not configured" "Set shared_buffers = 25% of RAM"
        fi
    fi

    success "Performance audit completed"
}

# Reliability audit
audit_reliability() {
    section "RELIABILITY AUDIT"

    # Check health checks
    log "Checking health checks..."

    SERVICES_WITHOUT_HEALTHCHECK=()
    while IFS= read -r service; do
        if ! grep -A 10 "^  $service:" compose.yml | grep -q "healthcheck:" 2>/dev/null; then
            SERVICES_WITHOUT_HEALTHCHECK+=("$service")
        fi
    done < <(grep -E "^  [a-zA-Z].*:" compose.yml | sed 's/://g' | awk '{print $1}')

    if [ ${#SERVICES_WITHOUT_HEALTHCHECK[@]} -gt 0 ]; then
        warning "Services without health checks: ${SERVICES_WITHOUT_HEALTHCHECK[*]}"
        add_issue "RELIABILITY" "MEDIUM" "Missing health checks" "Services ${SERVICES_WITHOUT_HEALTHCHECK[*]} have no health checks" "Add healthcheck for all critical services"
    fi

    # Check restart policies
    log "Checking restart policies..."

    if grep -c "restart:" compose.yml | grep -q "0"; then
        warning "Not all services have restart policy"
        add_issue "RELIABILITY" "MEDIUM" "Missing restart policies" "Some services will not restart automatically" "Add restart: unless-stopped for all services"
    fi

    # Check backup system
    log "Checking backup system..."

    if [ ! -d ".config-backup" ] || [ ! "$(ls -A .config-backup 2>/dev/null)" ]; then
        error "Backup system not configured"
        add_issue "RELIABILITY" "HIGH" "Missing backup" "Backrest not configured or contains no data" "Configure and test backup system"
    fi

    # Check logging system
    log "Checking logging system..."

    if ! grep -q "logging:" compose.yml 2>/dev/null; then
        warning "Centralized logging not configured"
        add_issue "RELIABILITY" "LOW" "Missing centralized logging" "Container logs are not centralized" "Configure logging driver for all services"
    fi

    success "Reliability audit completed"
}

# Configuration audit
audit_configuration() {
    section "CONFIGURATION AUDIT"

    # Check Docker Compose version
    log "Checking Docker Compose file version..."

    COMPOSE_VERSION=$(grep "version:" compose.yml | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'")
    if [ -z "$COMPOSE_VERSION" ]; then
        warning "Docker Compose version not specified"
        add_issue "CONFIG" "LOW" "Missing Compose version" "Docker Compose file version not specified" "Add version: '3.8' at the beginning of file"
    elif [[ "$COMPOSE_VERSION" < "3.7" ]]; then
        warning "Outdated Docker Compose version: $COMPOSE_VERSION"
        add_issue "CONFIG" "MEDIUM" "Outdated Compose version" "Using version $COMPOSE_VERSION" "Update to version 3.8 or higher"
    fi

    # Check environment variables
    log "Checking environment variables..."

    # Check for example files
    for env_file in env/*.env; do
        if [ -f "$env_file" ]; then
            example_file="${env_file}.example"
            if [ ! -f "$example_file" ]; then
                warning "Missing example file for $env_file"
                add_issue "CONFIG" "LOW" "Missing example file" "No $example_file" "Create example file with safe default values"
            fi
        fi
    done

    # Check volumes
    log "Checking volumes configuration..."

    # Check for bind mounts in production
    if grep -E "^\s*-\s*\./.*:" compose.yml | grep -v ":ro" 2>/dev/null; then
        warning "Bind mounts used without read-only"
        add_issue "CONFIG" "MEDIUM" "Insecure bind mounts" "Bind mounts without :ro can be modified by containers" "Add :ro for read-only bind mounts where possible"
    fi

    # Check networks
    log "Checking network configuration..."

    if ! grep -q "networks:" compose.yml 2>/dev/null; then
        warning "Custom networks not configured"
        add_issue "CONFIG" "LOW" "Missing custom networks" "All services in default network" "Create isolated networks for different service groups"
    fi

    success "Configuration audit completed"
}

# Main audit function
main() {
    log "Starting comprehensive pre-production audit of ERNI-KI..."
    echo "Audit Date: $AUDIT_DATE"
    echo "Report will be saved to: $AUDIT_REPORT_FILE"
    echo ""

    # Check prerequisites
    if ! check_prerequisites; then
        error "Failed to perform prerequisite checks"
        exit 1
    fi

    # Execute audits
    audit_security
    echo ""
    audit_performance
    echo ""
    audit_reliability
    echo ""
    audit_configuration

    echo ""
    section "REPORT GENERATION"
    generate_report

    echo ""
    success "Comprehensive audit completed!"
    echo "Report saved to: $AUDIT_REPORT_FILE"
    echo ""
    echo "Issues Summary:"
    echo "  🔴 Critical: $CRITICAL_COUNT"
    echo "  🟠 High: $HIGH_COUNT"
    echo "  🟡 Medium: $MEDIUM_COUNT"
    echo "  🟢 Low: $LOW_COUNT"
}

# Generate report
generate_report() {
    log "Creating detailed report..."

    cat > "$AUDIT_REPORT_FILE" << EOF
# 🔍 Comprehensive Pre-production Audit of ERNI-KI

**Audit Date**: $AUDIT_DATE
**System**: $(hostname)
**User**: $(whoami)
**Docker Version**: $(docker --version 2>/dev/null || echo "Not installed")
**Docker Compose Version**: $(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "Not installed")

## 📊 Results Summary

| Category | Critical | High | Medium | Low | Total |
|-----------|-------------|---------|---------|--------|-------|
| 🔒 Security | $(echo "${SECURITY_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${SECURITY_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#SECURITY_ISSUES[@]} |
| ⚡ Performance | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${PERFORMANCE_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#PERFORMANCE_ISSUES[@]} |
| 🛡️ Reliability | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${RELIABILITY_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#RELIABILITY_ISSUES[@]} |
| ⚙️ Configuration | $(echo "${CONFIG_ISSUES[@]}" | grep -o "CRITICAL" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "HIGH" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "MEDIUM" | wc -l) | $(echo "${CONFIG_ISSUES[@]}" | grep -o "LOW" | wc -l) | ${#CONFIG_ISSUES[@]} |
| **TOTAL** | **$CRITICAL_COUNT** | **$HIGH_COUNT** | **$MEDIUM_COUNT** | **$LOW_COUNT** | **$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))** |

## 🎯 Production Readiness Assessment

EOF

    # Determine overall readiness
    if [ $CRITICAL_COUNT -eq 0 ] && [ $HIGH_COUNT -eq 0 ]; then
        echo "✅ **READY FOR PRODUCTION** - No critical or high issues" >> "$AUDIT_REPORT_FILE"
    elif [ $CRITICAL_COUNT -eq 0 ] && [ $HIGH_COUNT -le 2 ]; then
        echo "⚠️ **CONDITIONALLY READY** - High issues need to be resolved" >> "$AUDIT_REPORT_FILE"
    else
        echo "❌ **NOT READY FOR PRODUCTION** - Critical issues need to be resolved" >> "$AUDIT_REPORT_FILE"
    fi

    # Add detailed sections
    add_security_section
    add_performance_section
    add_reliability_section
    add_configuration_section
    add_recommendations_section
    add_action_plan_section

    success "Report created: $AUDIT_REPORT_FILE"
}

# Add report sections
add_security_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 🔒 Security Audit

EOF

    if [ ${#SECURITY_ISSUES[@]} -eq 0 ]; then
        echo "✅ No security issues found" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Detected Issues:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${SECURITY_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Description**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Recommendation**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_performance_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## ⚡ Performance Audit

### System Resources
- **CPU**: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% loaded
- **Memory**: $(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')% used
- **Disk**: $(df -h . | awk 'NR==2 {print $5}') full

EOF

    if [ ${#PERFORMANCE_ISSUES[@]} -eq 0 ]; then
        echo "✅ No performance issues found" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Detected Issues:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${PERFORMANCE_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Description**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Recommendation**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_reliability_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 🛡️ Reliability Audit

EOF

    if [ ${#RELIABILITY_ISSUES[@]} -eq 0 ]; then
        echo "✅ No reliability issues found" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Detected Issues:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${RELIABILITY_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Description**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Recommendation**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_configuration_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## ⚙️ Configuration Audit

EOF

    if [ ${#CONFIG_ISSUES[@]} -eq 0 ]; then
        echo "✅ No configuration issues found" >> "$AUDIT_REPORT_FILE"
    else
        echo "### Detected Issues:" >> "$AUDIT_REPORT_FILE"
        echo "" >> "$AUDIT_REPORT_FILE"
        for issue in "${CONFIG_ISSUES[@]}"; do
            IFS='|' read -r title description recommendation <<< "$issue"
            echo "#### $title" >> "$AUDIT_REPORT_FILE"
            echo "**Description**: $description" >> "$AUDIT_REPORT_FILE"
            echo "**Recommendation**: $recommendation" >> "$AUDIT_REPORT_FILE"
            echo "" >> "$AUDIT_REPORT_FILE"
        done
    fi
}

add_recommendations_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 💡 General Recommendations

### Priority 1 (Critical)
- Replace all default passwords with secure ones
- Configure SSL/TLS encryption
- Fix critical security vulnerabilities

### Priority 2 (High)
- Configure resource limits for containers
- Add health checks for all services
- Configure backup system

### Priority 3 (Medium)
- Optimize database configuration
- Configure monitoring and alerting
- Add centralized logging

### Priority 4 (Low)
- Update Docker Compose versions
- Create custom networks
- Add example files for configurations

EOF
}

add_action_plan_section() {
    cat >> "$AUDIT_REPORT_FILE" << EOF

## 📅 Action Plan

### Week 1 (Critical Issues)
- [ ] Replace default passwords
- [ ] Configure SSL/TLS
- [ ] Fix critical vulnerabilities
- [ ] Security testing

### Week 2 (High Issues)
- [ ] Configure resource limits
- [ ] Add health checks
- [ ] Configure backup
- [ ] Reliability testing

### Week 3 (Medium Issues)
- [ ] Optimize performance
- [ ] Configure monitoring
- [ ] Centralized logging
- [ ] Load testing

### Week 4 (Low Issues and Finalization)
- [ ] Update configurations
- [ ] Create documentation
- [ ] Final testing
- [ ] Prepare for production

## 📋 Production Readiness Checklist

### Security
- [ ] All default passwords replaced
- [ ] SSL/TLS configured and working
- [ ] File permissions correct
- [ ] Network security configured
- [ ] Security audit passed

### Performance
- [ ] System resources optimized
- [ ] Container limits configured
- [ ] Database optimized
- [ ] Load testing passed
- [ ] Performance monitoring configured

### Reliability
- [ ] Health checks added for all services
- [ ] Restart policies configured
- [ ] Backup working
- [ ] Disaster recovery procedures tested
- [ ] Logging and alerting configured

### Configuration
- [ ] Docker Compose files valid
- [ ] Environment variables configured
- [ ] Volumes and networks optimized
- [ ] Documentation up to date
- [ ] Deployment procedures tested

---

**Report Created**: $(date)
**Tool**: ERNI-KI Comprehensive Audit Script
**Version**: 1.0

EOF
}

# Run audit
main "$@"
