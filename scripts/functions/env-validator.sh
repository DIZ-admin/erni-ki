#!/bin/bash
# Environment Variable Validation Utility
# Source this file in entrypoint scripts to validate required environment variables
# Usage: source scripts/lib/env-validator.sh && validate_env "VAR1" "VAR2" "VAR3"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to validate required environment variables
# Usage: validate_env "VAR1" "VAR2" "VAR3"
validate_env() {
    local missing_vars=()
    local all_valid=true

    for var in "$@"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
            all_valid=false
        fi
    done

    if [[ "$all_valid" == false ]]; then
        echo -e "${RED}❌ ERROR: Missing required environment variables:${NC}"
        for var in "${missing_vars[@]}"; do
            echo -e "${RED}  - $var${NC}"
        done
        return 1
    fi

    echo -e "${GREEN}✓ All required environment variables set${NC}"
    return 0
}

# Function to validate URL is reachable
# Usage: validate_url "http://service:port/path" "service_name"
validate_url() {
    local url=$1
    local service_name=${2:-"Service"}
    local timeout=${3:-5}

    if ! curl -sf --max-time "$timeout" "$url" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  WARNING: $service_name not accessible at $url${NC}"
        echo -e "${YELLOW}  Continuing anyway (service may initialize later)${NC}"
        return 0
    fi

    echo -e "${GREEN}✓ $service_name is accessible at $url${NC}"
    return 0
}

# Function to validate port is open
# Usage: validate_port "hostname" "port" "service_name"
validate_port() {
    local host=$1
    local port=$2
    local service_name=${3:-"Service"}

    if ! timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  WARNING: Cannot connect to $service_name at $host:$port${NC}"
        return 0
    fi

    echo -e "${GREEN}✓ $service_name is reachable at $host:$port${NC}"
    return 0
}

# Function to validate file exists
# Usage: validate_file "/path/to/file" "description"
validate_file() {
    local file=$1
    local description=${2:-"File"}

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}❌ ERROR: $description not found at $file${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ $description found at $file${NC}"
    return 0
}

# Function to validate directory exists
# Usage: validate_dir "/path/to/dir" "description"
validate_dir() {
    local dir=$1
    local description=${2:-"Directory"}

    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}❌ ERROR: $description not found at $dir${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ $description found at $dir${NC}"
    return 0
}

# Function to validate database connectivity
# Usage: validate_database "postgresql" "postgresql://<user>:<password>@host:5432/db"
validate_database() {
    local db_type=$1
    local db_url=$2

    case "$db_type" in
        postgresql)
            if ! psql "$db_url" -c "SELECT 1;" > /dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  WARNING: PostgreSQL not yet reachable at $db_url${NC}"
                return 0
            fi
            echo -e "${GREEN}✓ PostgreSQL is reachable${NC}"
            ;;
        redis)
            local host port password
            # Simple redis URL parser (basic)
            if ! redis-cli -u "$db_url" ping > /dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  WARNING: Redis not yet reachable${NC}"
                return 0
            fi
            echo -e "${GREEN}✓ Redis is reachable${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown database type: $db_type${NC}"
            return 0
            ;;
    esac
}

# Function to validate GPU is available (if CUDA_VISIBLE_DEVICES set)
# Usage: validate_gpu
validate_gpu() {
    if [[ -z "$CUDA_VISIBLE_DEVICES" ]]; then
        echo -e "${YELLOW}⚠️  CUDA_VISIBLE_DEVICES not set (GPU disabled)${NC}"
        return 0
    fi

    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}❌ ERROR: CUDA_VISIBLE_DEVICES set but nvidia-smi not found${NC}"
        return 1
    fi

    if ! nvidia-smi > /dev/null 2>&1; then
        echo -e "${RED}❌ ERROR: GPU not accessible (nvidia-smi failed)${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ GPU is available and initialized${NC}"
    return 0
}

# Function to validate disk space
# Usage: validate_disk_space "/path/to/check" "1G" (minimum required)
validate_disk_space() {
    local path=$1
    local min_required=${2:-"1G"}

    local available=$(df "$path" | awk 'NR==2 {print $4}')
    # Convert to KB for comparison
    local min_kb=$(echo "$min_required" | numfmt --from=iec)

    if [[ $available -lt $min_kb ]]; then
        echo -e "${RED}❌ ERROR: Not enough disk space at $path (required: $min_required, available: $(numfmt --to=iec $available))${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Sufficient disk space available at $path${NC}"
    return 0
}

# Function to start up with validation
# Usage: startup_with_validation "APP_NAME" "VAR1" "VAR2" "VAR3"
startup_with_validation() {
    local app_name=$1
    shift
    local vars=("$@")

    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}Starting $app_name${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""

    # Validate required variables
    if ! validate_env "${vars[@]}"; then
        echo ""
        echo -e "${RED}Cannot start $app_name: missing required environment variables${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}✓ $app_name ready to start${NC}"
    echo ""
}

# Export functions so they're available in sourcing scripts
export -f validate_env
export -f validate_url
export -f validate_port
export -f validate_file
export -f validate_dir
export -f validate_database
export -f validate_gpu
export -f validate_disk_space
export -f startup_with_validation
