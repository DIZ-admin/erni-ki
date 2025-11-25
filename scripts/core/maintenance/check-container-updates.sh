#!/bin/bash
# Script to check for Docker container updates in ERNI-KI
# Author: Alteon Schultz, Tech Lead
# Date: August 29, 2025

set -euo pipefail

# === CONFIGURATION ===
COMPOSE_FILE="compose.yml"
REPORT_FILE="container-updates-report-$(date +%Y%m%d_%H%M%S).md"

# === LOGGING COLORS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === LOGGING FUNCTIONS ===
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

# === PREREQUISITES CHECK ===
check_prerequisites() {
    log "Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi

    # Check docker-compose
    if ! command -v docker-compose &> /dev/null; then
        error "docker-compose is not installed"
        exit 1
    fi

    # Check jq
    if ! command -v jq &> /dev/null; then
        error "jq is not installed. Install it: sudo apt install jq"
        exit 1
    fi

    # Check curl
    if ! command -v curl &> /dev/null; then
        error "curl is not installed"
        exit 1
    fi

    # Check compose file
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        error "File $COMPOSE_FILE not found"
        exit 1
    fi

    success "Prerequisites met"
}

# === GET CURRENT VERSIONS ===
get_current_versions() {
    log "Getting current container versions..."

    # Extract images from compose file
    declare -gA CURRENT_IMAGES

    # Parse compose.yml to get images
    while IFS= read -r line; do
        if [[ $line =~ image:[[:space:]]*(.+) ]]; then
            image="${BASH_REMATCH[1]}"
            # Remove quotes if present
            image=$(echo "$image" | sed 's/["'"'"']//g')

            # Split into repository and tag
            if [[ $image =~ (.+):(.+) ]]; then
                repo="${BASH_REMATCH[1]}"
                tag="${BASH_REMATCH[2]}"
            else
                repo="$image"
                tag="latest"
            fi

            CURRENT_IMAGES["$repo"]="$tag"
        fi
    done < "$COMPOSE_FILE"

    success "Found ${#CURRENT_IMAGES[@]} images in compose file"
}

# === CHECK AVAILABLE VERSIONS ===
check_available_versions() {
    log "Checking available versions in registry..."

    declare -gA LATEST_VERSIONS
    declare -gA UPDATE_AVAILABLE

    for repo in "${!CURRENT_IMAGES[@]}"; do
        current_tag="${CURRENT_IMAGES[$repo]}"
        log "Checking $repo:$current_tag..."

        # Determine registry and check method
        if [[ $repo =~ ^ghcr\.io/ ]]; then
            # GitHub Container Registry
            check_ghcr_version "$repo" "$current_tag"
        elif [[ $repo =~ ^quay\.io/ ]]; then
            # Quay.io Registry
            check_quay_version "$repo" "$current_tag"
        elif [[ $repo =~ / ]]; then
            # Docker Hub (with namespace)
            check_dockerhub_version "$repo" "$current_tag"
        else
            # Docker Hub (official images)
            check_dockerhub_official_version "$repo" "$current_tag"
        fi
    done
}

# === CHECK GITHUB CONTAINER REGISTRY ===
check_ghcr_version() {
    local repo="$1"
    local current_tag="$2"

    # Extract owner/repo from ghcr.io/owner/repo
    local github_repo
    github_repo=$(echo "$repo" | sed 's|ghcr\.io/||')

    # Get latest release via GitHub API
    local latest_tag
    latest_tag=$(curl -s "https://api.github.com/repos/$github_repo/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null || echo "")

    if [[ -n "$latest_tag" ]]; then
        LATEST_VERSIONS["$repo"]="$latest_tag"
        if [[ "$current_tag" != "$latest_tag" && "$current_tag" != "latest" ]]; then
            UPDATE_AVAILABLE["$repo"]="yes"
        else
            UPDATE_AVAILABLE["$repo"]="no"
        fi
    else
        LATEST_VERSIONS["$repo"]="unknown"
        UPDATE_AVAILABLE["$repo"]="unknown"
        warning "Failed to get version for $repo"
    fi
}

# === CHECK DOCKER HUB ===
check_dockerhub_version() {
    local repo="$1"
    local current_tag="$2"

    # Get tags via Docker Hub API
    local api_url="https://registry.hub.docker.com/v2/repositories/$repo/tags/"
    local latest_tag

    # Try to get latest tag
    latest_tag=$(curl -s "$api_url" | jq -r '.results[] | select(.name == "latest") | .name' 2>/dev/null || echo "")

    if [[ -n "$latest_tag" ]]; then
        LATEST_VERSIONS["$repo"]="latest"
        if [[ "$current_tag" != "latest" ]]; then
            UPDATE_AVAILABLE["$repo"]="maybe"
        else
            UPDATE_AVAILABLE["$repo"]="no"
        fi
    else
        LATEST_VERSIONS["$repo"]="unknown"
        UPDATE_AVAILABLE["$repo"]="unknown"
        warning "Failed to get version for $repo"
    fi
}

# === CHECK DOCKER HUB OFFICIAL IMAGES ===
check_dockerhub_official_version() {
    local repo="$1"
    local current_tag="$2"

    # For official images use library/ prefix
    check_dockerhub_version "library/$repo" "$current_tag"

    # Copy result without library/ prefix
    if [[ -n "${LATEST_VERSIONS["library/$repo"]:-}" ]]; then
        LATEST_VERSIONS["$repo"]="${LATEST_VERSIONS["library/$repo"]}"
        UPDATE_AVAILABLE["$repo"]="${UPDATE_AVAILABLE["library/$repo"]}"
        unset LATEST_VERSIONS["library/$repo"]
        unset UPDATE_AVAILABLE["library/$repo"]
    fi
}

# === CHECK QUAY.IO ===
check_quay_version() {
    local repo="$1"
    local current_tag="$2"

    # Quay.io API to get tags
    local quay_repo
    quay_repo=$(echo "$repo" | sed 's|quay\.io/||')

    local api_url="https://quay.io/api/v1/repository/$quay_repo/tag/"
    local latest_tag

    latest_tag=$(curl -s "$api_url" | jq -r '.tags[] | select(.name == "latest") | .name' 2>/dev/null || echo "")

    if [[ -n "$latest_tag" ]]; then
        LATEST_VERSIONS["$repo"]="latest"
        if [[ "$current_tag" != "latest" ]]; then
            UPDATE_AVAILABLE["$repo"]="maybe"
        else
            UPDATE_AVAILABLE["$repo"]="no"
        fi
    else
        LATEST_VERSIONS["$repo"]="unknown"
        UPDATE_AVAILABLE["$repo"]="unknown"
        warning "Failed to get version for $repo"
    fi
}

# === ANALYZE UPDATE CRITICALITY ===
analyze_update_criticality() {
    log "Analyzing update criticality..."

    declare -gA UPDATE_PRIORITY
    declare -gA UPDATE_RISK
    declare -gA SECURITY_UPDATES

    for repo in "${!CURRENT_IMAGES[@]}"; do
        current_tag="${CURRENT_IMAGES[$repo]}"
        latest_tag="${LATEST_VERSIONS[$repo]:-unknown}"

        # Determine update priority
        case "$repo" in
            *postgres*|*postgresql*)
                UPDATE_PRIORITY["$repo"]="HIGH"
                UPDATE_RISK["$repo"]="MEDIUM"
                ;;
            *nginx*)
                UPDATE_PRIORITY["$repo"]="HIGH"
                UPDATE_RISK["$repo"]="LOW"
                ;;
            *ollama*)
                UPDATE_PRIORITY["$repo"]="HIGH"
                UPDATE_RISK["$repo"]="MEDIUM"
                ;;
            *open-webui*)
                UPDATE_PRIORITY["$repo"]="HIGH"
                UPDATE_RISK["$repo"]="MEDIUM"
                ;;
            *prometheus*)
                UPDATE_PRIORITY["$repo"]="MEDIUM"
                UPDATE_RISK["$repo"]="LOW"
                ;;
            *grafana*)
                UPDATE_PRIORITY["$repo"]="MEDIUM"
                UPDATE_RISK["$repo"]="LOW"
                ;;
            *redis*|*valkey*)
                UPDATE_PRIORITY["$repo"]="MEDIUM"
                UPDATE_RISK["$repo"]="MEDIUM"
                ;;
            *)
                UPDATE_PRIORITY["$repo"]="LOW"
                UPDATE_RISK["$repo"]="LOW"
                ;;
        esac

        # Check for security updates (simplified logic)
        if [[ "$current_tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ "$latest_tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # Compare versions to determine update type
            local current_major current_minor current_patch
            local latest_major latest_minor latest_patch

            IFS='.' read -r current_major current_minor current_patch <<< "$current_tag"
            IFS='.' read -r latest_major latest_minor latest_patch <<< "$latest_tag"

            if [[ $latest_major -gt $current_major ]]; then
                UPDATE_PRIORITY["$repo"]="MAJOR"
            elif [[ $latest_minor -gt $current_minor ]]; then
                UPDATE_PRIORITY["$repo"]="MINOR"
            elif [[ $latest_patch -gt $current_patch ]]; then
                UPDATE_PRIORITY["$repo"]="PATCH"
                SECURITY_UPDATES["$repo"]="possible"
            fi
        fi
    done
}

# === GENERATE REPORT ===
generate_report() {
    log "Generating update report..."

    cat > "$REPORT_FILE" << EOF
# ERNI-KI Container Updates Report

**Date:** $(date)
**System:** ERNI-KI
**Analysis:** $(whoami)

## 📊 Updates Summary

$(generate_summary_table)

## 📋 Detailed Analysis

$(generate_detailed_analysis)

## 🚀 Recommended Update Plan

$(generate_update_plan)

## ⚠️ Risks and Warnings

$(generate_risk_analysis)

## 🔧 Update Commands

$(generate_update_commands)

## 🧪 Testing Procedures

$(generate_testing_procedures)

---
*Report generated automatically by check-container-updates.sh script*
EOF

    success "Report saved: $REPORT_FILE"
}

# === GENERATE SUMMARY TABLE ===
generate_summary_table() {
    echo "| Service | Current Version | Available Version | Update | Priority | Risk |"
    echo "|--------|----------------|------------------|------------|-----------|------|"

    for repo in "${!CURRENT_IMAGES[@]}"; do
        current_tag="${CURRENT_IMAGES[$repo]}"
        latest_tag="${LATEST_VERSIONS[$repo]:-unknown}"
        update_available="${UPDATE_AVAILABLE[$repo]:-unknown}"
        priority="${UPDATE_PRIORITY[$repo]:-LOW}"
        risk="${UPDATE_RISK[$repo]:-LOW}"

        # Determine update status
        local status_icon
        case "$update_available" in
            "yes") status_icon="🔄" ;;
            "no") status_icon="✅" ;;
            "maybe") status_icon="❓" ;;
            *) status_icon="❌" ;;
        esac

        echo "| $repo | $current_tag | $latest_tag | $status_icon $update_available | $priority | $risk |"
    done
}

# === GENERATE DETAILED ANALYSIS ===
generate_detailed_analysis() {
    for repo in "${!CURRENT_IMAGES[@]}"; do
        current_tag="${CURRENT_IMAGES[$repo]}"
        latest_tag="${LATEST_VERSIONS[$repo]:-unknown}"
        update_available="${UPDATE_AVAILABLE[$repo]:-unknown}"
        priority="${UPDATE_PRIORITY[$repo]:-LOW}"
        risk="${UPDATE_RISK[$repo]:-LOW}"

        echo "### $repo"
        echo ""
        echo "**Current Version:** $current_tag  "
        echo "**Available Version:** $latest_tag  "
        echo "**Update Priority:** $priority  "
        echo "**Update Risk:** $risk  "

        if [[ "${SECURITY_UPDATES[$repo]:-}" == "possible" ]]; then
            echo "**⚠️ Possible security updates**"
        fi

        # Specific recommendations for each service
        case "$repo" in
            *ollama*)
                echo ""
                echo "**Recommendations:**"
                echo "- Ollama is actively developing, update is recommended"
                echo "- Check compatibility with current models"
                echo "- Backup models before updating"
                ;;
            *open-webui*)
                echo ""
                echo "**Recommendations:**"
                echo "- OpenWebUI frequently releases updates with new features"
                echo "- Check changelog for breaking changes"
                echo "- Backup the database"
                ;;
            *postgres*|*postgresql*)
                echo ""
                echo "**Recommendations:**"
                echo "- Critical service, requires careful update"
                echo "- Mandatory full database backup"
                echo "- Test on staging environment"
                ;;
            *nginx*)
                echo ""
                echo "**Recommendations:**"
                echo "- Usually safe update"
                echo "- Check configuration after update"
                echo "- Monitor performance"
                ;;
        esac

        echo ""
    done
}

# === GENERATE UPDATE PLAN ===
generate_update_plan() {
    echo "### Phase 1: Preparation (0 downtime)"
    echo ""
    echo "1. **Backup all critical data**"
    echo "   \`\`\`bash"
    echo "   # Backup PostgreSQL"
    echo "   docker-compose exec db pg_dump -U postgres openwebui > backup-$(date +%Y%m%d).sql"
    echo "   "
    echo "   # Backup Ollama models"
    echo "   docker-compose exec ollama ollama list > models-backup-$(date +%Y%m%d).txt"
    echo "   "
    echo "   # Backup configurations"
    echo "   tar -czf config-backup-$(date +%Y%m%d).tar.gz env/ conf/"
    echo "   \`\`\`"
    echo ""
    echo "2. **Check availability of new images**"
    echo "   \`\`\`bash"

    for repo in "${!CURRENT_IMAGES[@]}"; do
        latest_tag="${LATEST_VERSIONS[$repo]:-unknown}"
        if [[ "$latest_tag" != "unknown" && "${UPDATE_AVAILABLE[$repo]}" == "yes" ]]; then
            echo "   docker pull $repo:$latest_tag"
        fi
    done

    echo "   \`\`\`"
    echo ""
    echo "### Phase 2: Low-risk service updates (< 30 sec downtime)"
    echo ""

    # Sort by priority and risk
    local low_risk_services=()
    for repo in "${!CURRENT_IMAGES[@]}"; do
        if [[ "${UPDATE_RISK[$repo]:-LOW}" == "LOW" && "${UPDATE_AVAILABLE[$repo]}" == "yes" ]]; then
            low_risk_services+=("$repo")
        fi
    done

    if [[ ${#low_risk_services[@]} -gt 0 ]]; then
        echo "**Low-risk services:**"
        for service in "${low_risk_services[@]}"; do
            echo "- $service"
        done
        echo ""
        echo "\`\`\`bash"
        for service in "${low_risk_services[@]}"; do
            latest_tag="${LATEST_VERSIONS[$service]:-unknown}"
            echo "docker-compose stop ${service##*/}"
            echo "docker-compose up -d ${service##*/}"
            echo "sleep 10  # Wait for startup"
            echo ""
        done
        echo "\`\`\`"
    fi

    echo ""
    echo "### Phase 3: Critical service updates (< 2 min downtime)"
    echo ""

    local high_risk_services=()
    for repo in "${!CURRENT_IMAGES[@]}"; do
        if [[ "${UPDATE_RISK[$repo]:-LOW}" != "LOW" && "${UPDATE_AVAILABLE[$repo]}" == "yes" ]]; then
            high_risk_services+=("$repo")
        fi
    done

    if [[ ${#high_risk_services[@]} -gt 0 ]]; then
        echo "**Critical services (one by one):**"
        for service in "${high_risk_services[@]}"; do
            echo "- $service"
        done
        echo ""
        echo "\`\`\`bash"
        echo "# Update one service at a time with verification"
        for service in "${high_risk_services[@]}"; do
            echo "echo 'Updating $service...'"
            echo "docker-compose stop ${service##*/}"
            echo "docker-compose up -d ${service##*/}"
            echo "sleep 30  # Wait for full startup"
            echo "docker-compose ps ${service##*/}  # Check status"
            echo "# Verify functionality before proceeding"
            echo ""
        done
        echo "\`\`\`"
    fi
}

# === GENERATE RISK ANALYSIS ===
generate_risk_analysis() {
    echo "### 🔴 High-risk updates"
    echo ""

    local high_risk_found=false
    for repo in "${!CURRENT_IMAGES[@]}"; do
        if [[ "${UPDATE_RISK[$repo]:-LOW}" == "HIGH" ]]; then
            high_risk_found=true
            echo "**$repo**"
            echo "- May require configuration changes"
            echo "- Possible breaking changes in API"
            echo "- Testing on staging is recommended"
            echo ""
        fi
    done

    if [[ "$high_risk_found" == false ]]; then
        echo "No high-risk updates found."
        echo ""
    fi

    echo "### ⚠️ General Warnings"
    echo ""
    echo "- **Always backup before updating**"
    echo "- **Test updates on staging environment**"
    echo "- **Monitor logs after update**"
    echo "- **Have a rollback plan**"
    echo "- **Update one service at a time**"
    echo ""

    echo "### 🔄 Rollback Plan"
    echo ""
    echo "\`\`\`bash"
    echo "# In case of problems - rollback to previous versions"
    echo "docker-compose down"
    echo "# Restore previous images in compose.yml"
    echo "docker-compose up -d"
    echo ""
    echo "# Restore database (if needed)"
    echo "# docker-compose exec db psql -U postgres openwebui < backup-YYYYMMDD.sql"
    echo "\`\`\`"
}

# === GENERATE UPDATE COMMANDS ===
generate_update_commands() {
    echo "### 🚀 Automated Update"
    echo ""
    echo "\`\`\`bash"
    echo "#!/bin/bash"
    echo "# Script for automatic ERNI-KI container updates"
    echo ""
    echo "set -euo pipefail"
    echo ""
    echo "# Create backup"
    echo "echo 'Creating backup...'"
    echo "mkdir -p .backups/$(date +%Y%m%d_%H%M%S)"
    echo "docker-compose exec db pg_dump -U postgres openwebui > .backups/$(date +%Y%m%d_%H%M%S)/db-backup.sql"
    echo ""
    echo "# Update images"
    echo "echo 'Downloading new images...'"

    for repo in "${!CURRENT_IMAGES[@]}"; do
        latest_tag="${LATEST_VERSIONS[$repo]:-unknown}"
        if [[ "$latest_tag" != "unknown" && "${UPDATE_AVAILABLE[$repo]}" == "yes" ]]; then
            echo "docker pull $repo:$latest_tag"
        fi
    done

    echo ""
    echo "# Update compose file"
    echo "echo 'Updating compose.yml...'"
    echo "cp compose.yml compose.yml.backup"
    echo ""

    # Generate sed commands to update compose file
    for repo in "${!CURRENT_IMAGES[@]}"; do
        current_tag="${CURRENT_IMAGES[$repo]}"
        latest_tag="${LATEST_VERSIONS[$repo]:-unknown}"
        if [[ "$latest_tag" != "unknown" && "${UPDATE_AVAILABLE[$repo]}" == "yes" ]]; then
            echo "sed -i 's|$repo:$current_tag|$repo:$latest_tag|g' compose.yml"
        fi
    done

    echo ""
    echo "# Restart services"
    echo "echo 'Restarting services...'"
    echo "docker-compose down"
    echo "docker-compose up -d"
    echo ""
    echo "# Check status"
    echo "echo 'Checking service status...'"
    echo "sleep 30"
    echo "docker-compose ps"
    echo ""
    echo "echo 'Update completed!'"
    echo "\`\`\`"
    echo ""
    echo "### 🎯 Selective Update"
    echo ""
    echo "\`\`\`bash"
    echo "# Update only specific service"
    echo "SERVICE_NAME=openwebui  # Replace with desired service"
    echo "docker-compose stop \$SERVICE_NAME"
    echo "docker-compose pull \$SERVICE_NAME"
    echo "docker-compose up -d \$SERVICE_NAME"
    echo "docker-compose logs -f \$SERVICE_NAME"
    echo "\`\`\`"
}

# === GENERATE TESTING PROCEDURES ===
generate_testing_procedures() {
    echo "### ✅ Post-update Health Check"
    echo ""
    echo "\`\`\`bash"
    echo "#!/bin/bash"
    echo "# Script to check ERNI-KI health after update"
    echo ""
    echo "echo '=== Checking container status ==='"
    echo "docker-compose ps"
    echo ""
    echo "echo '=== Checking logs for errors ==='"
    echo "docker-compose logs --tail=50 | grep -i error || echo 'No errors found'"
    echo ""
    echo "echo '=== Checking service availability ==='"
    echo "# OpenWebUI"
    echo "curl -f http://localhost:8080/health || echo 'OpenWebUI unavailable'"
    echo ""
    echo "# Ollama"
    echo "curl -f http://localhost:11434/api/tags || echo 'Ollama unavailable'"
    echo ""
    echo "# PostgreSQL"
    echo "docker-compose exec db pg_isready -U postgres || echo 'PostgreSQL unavailable'"
    echo ""
    echo "echo '=== Checking disk space ==='"
    echo "df -h"
    echo ""
    echo "echo '=== Checking memory usage ==='"
    echo "docker stats --no-stream"
    echo ""
    echo "echo 'Check completed!'"
    echo "\`\`\`"
    echo ""
    echo "### 🔍 Post-update Monitoring"
    echo ""
    echo "**What to monitor in the first 24 hours:**"
    echo ""
    echo "1. **Service Logs**"
    echo "   \`\`\`bash"
    echo "   docker-compose logs -f --tail=100"
    echo "   \`\`\`"
    echo ""
    echo "2. **Performance**"
    echo "   \`\`\`bash"
    echo "   docker stats"
    echo "   \`\`\`"
    echo ""
    echo "3. **Browser Availability**"
    echo "   - OpenWebUI: http://localhost:8080"
    echo "   - Grafana: http://localhost:3000"
    echo "   - Prometheus: http://localhost:9090"
    echo ""
    echo "4. **RAG Functionality**"
    echo "   - Document search testing"
    echo "   - Response generation check"
    echo "   - Integration validation (SearXNG, Ollama)"
}

# === MAIN FUNCTION ===
main() {
    echo "🔍 ERNI-KI Docker Container Update Check"
    echo "========================================"

    check_prerequisites
    get_current_versions
    check_available_versions
    analyze_update_criticality
    generate_report

    echo ""
    success "✅ Update analysis completed!"
    echo "📄 Report: $REPORT_FILE"
    echo ""
    echo "📋 Brief Summary:"

    local total_images=${#CURRENT_IMAGES[@]}
    local updates_available=0
    local high_priority=0

    for repo in "${!UPDATE_AVAILABLE[@]}"; do
        if [[ "${UPDATE_AVAILABLE[$repo]}" == "yes" ]]; then
            ((updates_available++))
        fi
        if [[ "${UPDATE_PRIORITY[$repo]}" == "HIGH" ]]; then
            ((high_priority++))
        fi
    done

    echo "- Total images: $total_images"
    echo "- Updates available: $updates_available"
    echo "- High priority: $high_priority"
}

# === RUN ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
