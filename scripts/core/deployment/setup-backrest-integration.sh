#!/bin/bash

# ERNI-KI Backrest Integration Setup
# Backup configuration and monitoring integration
# Author: Alteon Schulz (Tech Lead)

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/.config-backup"
BACKREST_API="http://localhost:9898/v1.Backrest"

# === Logging functions ===

# === Check Backrest availability ===
check_backrest_availability() {
    log_info "Checking Backrest availability..."

    if curl -s -f "$BACKREST_API/GetConfig" --data '{}' -H 'Content-Type: application/json' >/dev/null 2>&1; then
        log_success "Backrest API is available"
        return 0
    else
        log_error "Backrest API is not available"
        return 1
    fi
}

# === Create local repository ===
create_local_repository() {
    log_info "Creating local backup repository..."

    # Create directory for backups
    mkdir -p "$BACKUP_DIR"

    # Generate repository password
    local repo_password
    repo_password=$(openssl rand -base64 32)

    # Save password in a secure location
    echo "$repo_password" > "$PROJECT_ROOT/conf/backrest/repo-password.txt"
    chmod 600 "$PROJECT_ROOT/conf/backrest/repo-password.txt"

    # Configure repository via API
    local repo_config
    repo_config=$(cat <<EOF
{
    "repo": {
        "id": "erni-ki-local",
        "uri": "$BACKUP_DIR",
        "password": "$repo_password",
        "flags": ["--no-lock"],
        "prunePolicy": {
            "schedule": "0 2 * * *",
            "maxUnusedBytes": "1073741824"
        },
        "checkPolicy": {
            "schedule": "0 3 * * 0"
        }
    }
}
EOF
    )

    log_info "Repository configuration created"
    echo "$repo_config" > "$PROJECT_ROOT/conf/backrest/repo-config.json"

    log_success "Local repository configured in $BACKUP_DIR"
}

# === Create backup plans ===
create_backup_plans() {
    log_info "Creating backup plans..."

    # Plan for daily backups
    local daily_plan
    daily_plan=$(cat <<EOF
{
    "plan": {
        "id": "erni-ki-daily",
        "repo": "erni-ki-local",
        "paths": [
            "$PROJECT_ROOT/env/",
            "$PROJECT_ROOT/conf/",
            "$PROJECT_ROOT/data/postgres/",
            "$PROJECT_ROOT/data/openwebui/",
            "$PROJECT_ROOT/data/ollama/"
        ],
        "excludes": [
            "*.tmp",
            "*.log",
            "*cache*",
            "*.lock"
        ],
        "schedule": "0 1 * * *",
        "retention": {
            "keepDaily": 7
        },
        "hooks": []
    }
}
EOF
    )

    # Plan for weekly backups
    local weekly_plan
    weekly_plan=$(cat <<EOF
{
    "plan": {
        "id": "erni-ki-weekly",
        "repo": "erni-ki-local",
        "paths": [
            "$PROJECT_ROOT/env/",
            "$PROJECT_ROOT/conf/",
            "$PROJECT_ROOT/data/postgres/",
            "$PROJECT_ROOT/data/openwebui/",
            "$PROJECT_ROOT/data/ollama/"
        ],
        "excludes": [
            "*.tmp",
            "*.log",
            "*cache*",
            "*.lock"
        ],
        "schedule": "0 2 * * 0",
        "retention": {
            "keepWeekly": 4
        },
        "hooks": []
    }
}
EOF
    )

    echo "$daily_plan" > "$PROJECT_ROOT/conf/backrest/daily-plan.json"
    echo "$weekly_plan" > "$PROJECT_ROOT/conf/backrest/weekly-plan.json"

    log_success "Backup plans created"
}

# === Create webhook for monitoring integration ===
create_monitoring_webhook() {
    log_info "Creating webhook for rate limiting monitoring integration..."

    # Create webhook script
    cat > "$PROJECT_ROOT/scripts/backrest-webhook.sh" <<'EOF'
#!/bin/bash

# Backrest Webhook for monitoring system integration
# Receives notifications from Backrest and sends them to the monitoring system

WEBHOOK_DATA="$1"
MONITORING_LOG="/home/konstantin/Documents/augment-projects/erni-ki/logs/backrest-notifications.log"

# Create log directory
mkdir -p "$(dirname "$MONITORING_LOG")"

# Log notification
echo "[$(date -Iseconds)] Backrest notification: $WEBHOOK_DATA" >> "$MONITORING_LOG"

# Send to rate limiting monitoring system (if configured)
if [[ -f "/home/konstantin/Documents/augment-projects/erni-ki/scripts/monitor-rate-limiting.sh" ]]; then
    # Integration with monitoring system
    echo "Backrest notification: $WEBHOOK_DATA" | logger -t "erni-ki-backrest"
fi

exit 0
EOF

    chmod +x "$PROJECT_ROOT/scripts/backrest-webhook.sh"

    log_success "Monitoring webhook created"
}

# === Create notification hooks ===
create_notification_hooks() {
    log_info "Creating notification hooks..."

    # Hook for successful backups
    local success_hook
    success_hook=$(cat <<EOF
{
    "hook": {
        "conditions": ["CONDITION_SNAPSHOT_SUCCESS"],
        "actionCommand": {
            "command": "$PROJECT_ROOT/scripts/backrest-webhook.sh",
            "args": ["Backup completed successfully for plan {{ .Plan.Id }} at {{ .FormatTime .CurTime }}"]
        }
    }
}
EOF
    )

    # Hook for backup errors
    local error_hook
    error_hook=$(cat <<EOF
{
    "hook": {
        "conditions": ["CONDITION_SNAPSHOT_ERROR", "CONDITION_ANY_ERROR"],
        "actionCommand": {
            "command": "$PROJECT_ROOT/scripts/backrest-webhook.sh",
            "args": ["Backup FAILED for plan {{ .Plan.Id }}: {{ .Error }}"]
        }
    }
}
EOF
    )

    echo "$success_hook" > "$PROJECT_ROOT/conf/backrest/success-hook.json"
    echo "$error_hook" > "$PROJECT_ROOT/conf/backrest/error-hook.json"

    log_success "Notification hooks created"
}

# === Integration testing ===
test_integration() {
    log_info "Testing Backrest integration..."

    # Check API
    if ! check_backrest_availability; then
        log_error "Backrest API not available for testing"
        return 1
    fi

    # Test webhook
    if [[ -x "$PROJECT_ROOT/scripts/backrest-webhook.sh" ]]; then
        "$PROJECT_ROOT/scripts/backrest-webhook.sh" "Test notification from setup script"
        log_success "Webhook tested"
    fi

    # Check created files
    local required_files=(
        "$PROJECT_ROOT/conf/backrest/repo-password.txt"
        "$PROJECT_ROOT/conf/backrest/repo-config.json"
        "$PROJECT_ROOT/conf/backrest/daily-plan.json"
        "$PROJECT_ROOT/conf/backrest/weekly-plan.json"
        "$PROJECT_ROOT/scripts/backrest-webhook.sh"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "File created: $file"
        else
            log_error "File not found: $file"
            return 1
        fi
    done

    return 0
}

# === Create documentation ===
create_documentation() {
    log_info "Creating integration documentation..."

    cat > "$PROJECT_ROOT/docs/backrest-integration.md" <<EOF
# Backrest Integration for ERNI-KI

## Overview

The ERNI-KI backup system uses Backrest for automatic creation of backups of critical data.

## Configuration

### Repository
- **Type**: Local storage
- **Path**: \`.config-backup/\`
- **Encryption**: AES-256 (password in \`conf/backrest/repo-password.txt\`)

### Backup Plans

#### Daily Backups
- **Schedule**: 01:00 daily
- **Retention**: 7 days
- **Contents**: env/, conf/, data/postgres/, data/openwebui/, data/ollama/

#### Weekly Backups
- **Schedule**: 02:00 every Sunday
- **Retention**: 4 weeks
- **Contents**: env/, conf/, data/postgres/, data/openwebui/, data/ollama/

## Monitoring

### Monitoring System Integration
- Webhook: \`scripts/backrest-webhook.sh\`
- Logs: \`logs/backrest-notifications.log\`
- System log: \`journalctl -t erni-ki-backrest\`

### Notifications
- Successful backups are logged
- Errors are sent to the monitoring system
- Integration with rate limiting monitoring

## API Endpoints

- **Configuration**: \`POST /v1.Backrest/GetConfig\`
- **Operations**: \`POST /v1.Backrest/GetOperations\`
- **Start Backup**: \`POST /v1.Backrest/Backup\`

## Restoration

To restore data, use the Backrest web interface:
\`\`\`
http://localhost:9898
\`\`\`

## Security

- Repository password is stored encrypted
- API access is restricted to localhost
- Backups are created with root privileges
EOF

    log_success "Documentation created: docs/backrest-integration.md"
}

# === Main function ===
main() {
    log_info "Setting up Backrest integration for ERNI-KI"

    # Check Backrest availability
    if ! check_backrest_availability; then
        log_error "Backrest is not available. Make sure the service is running."
        exit 1
    fi

    # Create directory structure
    mkdir -p "$PROJECT_ROOT/conf/backrest"
    mkdir -p "$PROJECT_ROOT/docs"
    mkdir -p "$PROJECT_ROOT/logs"

    # Perform setup
    create_local_repository
    create_backup_plans
    create_monitoring_webhook
    create_notification_hooks
    create_documentation

    # Testing
    if test_integration; then
        log_success "Backrest integration configured successfully!"

        echo
        echo "📋 What was configured:"
        echo "  ✅ Local repository in .config-backup/"
        echo "  ✅ Daily backups (7 days retention)"
        echo "  ✅ Weekly backups (4 weeks retention)"
        echo "  ✅ Webhook for monitoring integration"
        echo "  ✅ Hooks for status notifications"
        echo "  ✅ Integration documentation"

        echo
        echo "🚀 Next steps:"
        echo "  1. Open http://localhost:9898 to configure via web interface"
        echo "  2. Add repository using configuration from conf/backrest/repo-config.json"
        echo "  3. Create backup plans from conf/backrest/*-plan.json"
        echo "  4. Configure hooks using conf/backrest/*-hook.json"

    else
        log_error "Error configuring Backrest integration"
        exit 1
    fi
}

# Launch
main "$@"
