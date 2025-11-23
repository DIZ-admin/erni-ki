#!/bin/bash
# Local backup setup script for ERNI-KI using Backrest
# Creates repository and backup plan for critical data

set -euo pipefail

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    exit 1
}

# Configuration
BACKREST_URL="http://localhost:9898"
REPO_ID="erni-ki-local"
REPO_PATH="/backup-sources/.config-backup"
PLAN_ID="erni-ki-critical-data"

# Retrieve credentials
get_credentials() {
    if [ -f ".backrest_secrets" ]; then
        BACKREST_PASSWORD=$(grep "BACKREST_PASSWORD=" .backrest_secrets | cut -d'=' -f2)
        RESTIC_PASSWORD=$(grep "RESTIC_PASSWORD=" .backrest_secrets | cut -d'=' -f2)

        if [ -z "$BACKREST_PASSWORD" ] || [ -z "$RESTIC_PASSWORD" ]; then
            error "Failed to obtain credentials from .backrest_secrets"
        fi

        success "Credentials loaded"
    else
        error "File .backrest_secrets not found. Please run ./scripts/backrest-setup.sh first"
    fi
}

# Check Backrest availability
check_backrest() {
    log "Checking Backrest availability..."

    if ! curl -s -o /dev/null -w "%{http_code}" "$BACKREST_URL/" | grep -q "200"; then
        error "Backrest not reachable at $BACKREST_URL"
    fi

    success "Backrest is reachable"
}

# Repository creation via web UI (instructions)
create_repository_instructions() {
    log "Creating local repository..."

    echo ""
    echo "=== INSTRUCTIONS FOR CREATING REPOSITORY ==="
    echo ""
    echo "1. Open the Backrest web interface: $BACKREST_URL"
    echo "2. Log in with credentials:"
    echo "   - User: admin"
    echo "   - Password: $BACKREST_PASSWORD"
    echo ""
    echo "3. Click 'Add Repository' and fill in:"
    echo "   - Repository ID: $REPO_ID"
    echo "   - Repository URI: $REPO_PATH"
    echo "   - Password: $RESTIC_PASSWORD"
    echo ""
    echo "4. Set 'Prune Policy' section:"
    echo "   - Schedule: 0 3 * * * (daily at 03:00)"
    echo "   - Max Unused Bytes: 1GB"
    echo ""
    echo "5. Set 'Check Policy' section:"
    echo "   - Schedule: 0 4 * * 0 (weekly on Sunday at 04:00)"
    echo ""
    echo "6. Click 'Create Repository'"
    echo ""
}

# Backup plan creation (instructions)
create_backup_plan_instructions() {
    log "Creating backup plan..."

    echo ""
    echo "=== INSTRUCTIONS FOR CREATING BACKUP PLAN ==="
    echo ""
    echo "1. After creating the repository, click 'Add Plan'"
    echo ""
    echo "2. Fill in the main settings:"
    echo "   - Plan ID: $PLAN_ID"
    echo "   - Repository: $REPO_ID"
    echo ""
    echo "3. Add paths in the 'Paths' section:"
    echo "   - /backup-sources/env"
    echo "   - /backup-sources/conf"
    echo "   - /backup-sources/data/postgres"
    echo "   - /backup-sources/data/openwebui"
    echo "   - /backup-sources/data/ollama"
    echo ""
    echo "4. Add excludes in the 'Excludes' section:"
    echo "   - *.log"
    echo "   - *.tmp"
    echo "   - **/cache/**"
    echo "   - **/temp/**"
    echo "   - **/.git/**"
    echo "   - **/node_modules/**"
    echo ""
    echo "5. Set schedule in the 'Schedule' section:"
    echo "   - Schedule: 0 2 * * * (daily at 02:00)"
    echo ""
    echo "6. In 'Retention Policy', select 'Time-based' and set:"
    echo "   - Keep Daily: 7"
    echo "   - Keep Weekly: 4"
    echo "   - Keep Monthly: 0"
    echo "   - Keep Yearly: 0"
    echo ""
    echo "7. Click 'Create Plan'"
    echo ""
}

# Test backup creation (instructions)
create_test_backup_instructions() {
    log "Creating test backup..."

    echo ""
    echo "=== INSTRUCTIONS FOR CREATING TEST BACKUP ==="
    echo ""
    echo "1. After creating the plan, go to the 'Plans' page"
    echo "2. Find the plan '$PLAN_ID'"
    echo "3. Click the 'Backup Now' button next to the plan"
    echo "4. Wait for the backup operation to complete"
    echo "5. Verify that files appear in the .config-backup/ directory"
    echo ""
}

# Verify created backup
check_backup() {
    log "Verifying created backup..."

    if [ -d ".config-backup" ] && [ "$(ls -A .config-backup 2>/dev/null)" ]; then
        success "Directory .config-backup contains backup data"
        echo "Directory contents:"
        ls -la .config-backup/
    else
        warning "Directory .config-backup is empty or contains no backup data"
        echo "Ensure you have created and run the backup plan via the web interface"
    fi
}

# Create restoration instructions
create_restore_instructions() {
    log "Creating restoration instructions..."

    cat > docs/local-backup-restore-guide.md << 'EOF'
# Guide for restoring from local ERNI-KI backup

## 🎯 Overview

This guide describes procedures for restoring data from a local backup created with Backrest in the `.config-backup/` directory.

## 📋 What is included in the backup

- **Configuration files**: `env/` and `conf/`
- **PostgreSQL database**: `data/postgres/`
- **Open WebUI data**: `data/openwebui/`
- **Ollama models**: `data/ollama/`

## 🔧 Restoration via Backrest web interface

### 1. Access the restoration interface

1. Open http://localhost:9898
2. Log in with credentials from `.backrest_secrets`
3. Navigate to the "Snapshots" section
4. Select the desired snapshot for restoration

### 2. Restoring individual files

1. In the snapshots list, click "Browse"
2. Navigate to the required files
3. Select files for restoration
4. Click "Restore" and specify the destination path

### 3. Full system restoration

1. Stop all ERNI-KI services:
   ```bash
   docker-compose down
   ```

2. Create a backup of current data:
   ```bash
   mv data data.backup.$(date +%Y%m%d_%H%M%S)
   mv env env.backup.$(date +%Y%m%d_%H%M%S)
   mv conf conf.backup.$(date +%Y%m%d_%H%M%S)
   ```

3. Restore data via Backrest web interface:
    - Select the latest successful snapshot
    - Restore each directory to its appropriate location
    - Ensure file permissions are correct

4. Start services:
   ```bash
   docker-compose up -d
   ```

## 🛠️ Restoration via command line

### 1. Direct use of restic

```bash
# Set environment variables
export RESTIC_REPOSITORY="/path/to/.config-backup"
export RESTIC_PASSWORD="your_restic_password_from_.backrest_secrets"

# View available snapshots
restic snapshots

# Restore a specific snapshot
restic restore latest --target ./restore-temp

# Restore specific files
restic restore latest --target ./restore-temp --include "*/env/*"
```

### 2. Using the Backrest Docker container

```bash
# Enter the Backrest container
docker-compose exec backrest sh

# Inside the container
export RESTIC_REPOSITORY="/backup-sources/.config-backup"
export RESTIC_PASSWORD="your_restic_password"

# View snapshots
restic snapshots

# Restoration
restic restore latest --target /tmp/restore
```

## 🚨 Emergency recovery procedures

### Scenario 1: Loss of configuration files

```bash
# 1. Stop services
docker-compose down

# 2. Restore configurations
# Use the Backrest web interface to restore:
# - /backup-sources/env -> ./env
# - /backup-sources/conf -> ./conf

# 3. Verify and start
docker-compose up -d
```

### Scenario 2: Database corruption

```bash
# 1. Stop services
docker-compose down

# 2. Backup the corrupted DB
mv data/postgres data/postgres.corrupted.$(date +%Y%m%d_%H%M%S)

# 3. Restore DB from backup
# Use Backrest to restore /backup-sources/data/postgres -> ./data/postgres

# 4. Verify permissions
sudo chown -R 999:999 data/postgres

# 5. Start services
docker-compose up -d db
# Wait for the DB to start, then start other services
docker-compose up -d
```

### Scenario 3: Loss of Ollama models

```bash
# 1. Stop Ollama
docker-compose stop ollama

# 2. Restore models
# Use Backrest to restore /backup-sources/data/ollama -> ./data/ollama

# 3. Verify permissions
sudo chown -R 1000:1000 data/ollama

# 4. Start Ollama
docker-compose start ollama
```

## ✅ Verify successful restoration

### 1. Verify services

```bash
# Status of all containers
docker-compose ps

# Check logs
docker-compose logs --tail=50
```

### 2. Verify functionality

1. **Open WebUI**: http://localhost (or your domain)
2. **Backrest**: http://localhost:9898
3. **Database**:
   ```bash
    docker-compose exec db psql -U postgres -d openwebui -c "SELECT COUNT(*) FROM users;"
   ```

### 3. Verify data

- Ensure users can log in
- Verify availability of loaded Ollama models
- Ensure chats and settings are preserved

## 📝 Recommendations

1. **Regular testing**: Perform test restorations monthly
2. **Documentation**: Keep a log of all restoration operations
3. **Monitoring**: Set up alerts for failed backups
4. **Security**: Store encryption passwords securely

## 🆘 Support

If you encounter restoration issues:

1. Check Backrest logs: `docker-compose logs backrest`
2. Verify backup integrity: `restic check`
3. Refer to Backrest documentation: https://garethgeorge.github.io/backrest/
4. Check file and directory permissions

---

**Important**: Always create a backup of current data before restoration!
EOF

    success "Restoration guide created: docs/local-backup-restore-guide.md"
}

# Main function
main() {
    log "Setting up local ERNI-KI backup..."

    get_credentials
    check_backrest
    create_repository_instructions
    create_backup_plan_instructions
    create_test_backup_instructions
    create_restore_instructions

    echo ""
    success "Local backup setup completed!"
    echo ""
    warning "NEXT STEPS:"
    echo "1. Open the Backrest web interface: $BACKREST_URL"
    echo "2. Follow the above instructions to create the repository and plan"
    echo "3. Create a test backup"
    echo "4. Check the contents of the .config-backup/ directory"
    echo ""
    echo "Login credentials:"
    echo "- User: admin"
    echo "- Password: $BACKREST_PASSWORD"
}

# Script entry point
main "$@"
