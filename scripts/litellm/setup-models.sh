#!/usr/bin/env bash
# ==============================================================================
# LiteLLM Model Setup Script
# Configures model aliases, fallbacks, and API keys via LiteLLM Admin API
# All settings are stored in PostgreSQL (store_model_in_db: true)
# ==============================================================================
set -euo pipefail

# === Configuration ===
LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
LITELLM_MASTER_KEY="${LITELLM_MASTER_KEY:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === Helper Functions ===
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_prerequisites() {
    if [[ -z "$LITELLM_MASTER_KEY" ]]; then
        log_error "LITELLM_MASTER_KEY is required"
        echo "Set it via: export LITELLM_MASTER_KEY=sk-..."
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi
}

wait_for_litellm() {
    log_info "Waiting for LiteLLM to be ready..."
    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if curl -sf "${LITELLM_URL}/health/readiness" > /dev/null 2>&1; then
            log_info "LiteLLM is ready"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done

    log_error "LiteLLM did not become ready in time"
    exit 1
}

# === API Functions ===
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local args=(
        -s
        -X "$method"
        -H "Authorization: Bearer ${LITELLM_MASTER_KEY}"
        -H "Content-Type: application/json"
    )

    if [[ -n "$data" ]]; then
        args+=(-d "$data")
    fi

    curl "${args[@]}" "${LITELLM_URL}${endpoint}"
}

model_exists() {
    local model_name="$1"
    local response
    response=$(api_call GET "/model/info?model_name=${model_name}" 2>/dev/null || echo '{"error": true}')

    if echo "$response" | jq -e '.data' > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

create_model() {
    local model_name="$1"
    local backend_model="$2"
    local description="$3"
    local api_key_env="${4:-OPENAI_API_KEY}"

    if model_exists "$model_name"; then
        log_warn "Model '$model_name' already exists, skipping"
        return 0
    fi

    log_info "Creating model: $model_name -> $backend_model"

    local payload
    payload=$(jq -n \
        --arg model_name "$model_name" \
        --arg model "$backend_model" \
        --arg api_key "os.environ/${api_key_env}" \
        --arg description "$description" \
        '{
            model_name: $model_name,
            litellm_params: {
                model: $model,
                api_key: $api_key
            },
            model_info: {
                description: $description
            }
        }')

    local response
    response=$(api_call POST "/model/new" "$payload")

    if echo "$response" | jq -e '.model_id' > /dev/null 2>&1; then
        log_info "Model '$model_name' created successfully"
    else
        log_error "Failed to create model '$model_name': $response"
        return 1
    fi
}

key_exists() {
    local key_alias="$1"
    local response
    response=$(api_call GET "/key/info?key_alias=${key_alias}" 2>/dev/null || echo '{"error": true}')

    if echo "$response" | jq -e '.key' > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

create_api_key() {
    local key_alias="$1"
    local max_budget="$2"
    local duration="$3"
    local models="$4"  # JSON array string
    local team="${5:-ci}"
    local workflow="${6:-default}"

    if key_exists "$key_alias"; then
        log_warn "API key '$key_alias' already exists, skipping"
        return 0
    fi

    log_info "Creating API key: $key_alias (budget: \$$max_budget, duration: $duration)"

    local payload
    payload=$(jq -n \
        --arg key_alias "$key_alias" \
        --argjson max_budget "$max_budget" \
        --arg duration "$duration" \
        --argjson models "$models" \
        --arg team "$team" \
        --arg workflow "$workflow" \
        '{
            key_alias: $key_alias,
            max_budget: $max_budget,
            duration: $duration,
            models: $models,
            metadata: {
                team: $team,
                workflow: $workflow,
                created_by: "setup-models.sh"
            }
        }')

    local response
    response=$(api_call POST "/key/generate" "$payload")

    if echo "$response" | jq -e '.key' > /dev/null 2>&1; then
        local key
        key=$(echo "$response" | jq -r '.key')
        log_info "API key '$key_alias' created: ${key:0:20}..."
        echo ""
        echo "=== SAVE THIS KEY ==="
        echo "Key alias: $key_alias"
        echo "Key: $key"
        echo "===================="
        echo ""
    else
        log_error "Failed to create API key '$key_alias': $response"
        return 1
    fi
}

update_router_settings() {
    log_info "Updating router fallback settings..."

    local payload
    payload=$(cat <<'EOF'
{
    "router_settings": {
        "fallbacks": [
            {"docs-validator": ["claude-3-5-haiku", "ollama/llama3.2:3b"]},
            {"code-reviewer": ["gpt-4", "gpt-4o-mini"]},
            {"release-notes": ["gpt-4", "gpt-4o-mini"]},
            {"ci-assistant": ["claude-3-5-haiku", "ollama/llama3.2:3b"]}
        ],
        "enable_fallbacks": true,
        "cooldown_time": 30,
        "allowed_fails": 3
    }
}
EOF
)

    local response
    response=$(api_call POST "/config/update" "$payload")

    if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
        log_info "Router settings updated successfully"
    else
        log_warn "Could not update router settings (may require restart): $response"
    fi
}

# === Main Setup ===
main() {
    echo "=============================================="
    echo "LiteLLM Model Setup for ERNI-KI"
    echo "=============================================="
    echo ""

    check_prerequisites
    wait_for_litellm

    echo ""
    log_info "=== Phase 1: Creating Model Aliases ==="

    # Documentation validation (cost-optimized)
    create_model "docs-validator" "gpt-4o-mini" \
        "Documentation validation - cost optimized" "OPENAI_API_KEY"

    # Code review (quality-focused)
    create_model "code-reviewer" "claude-3-5-sonnet-20241022" \
        "Code review - quality focused" "ANTHROPIC_API_KEY"

    # Release notes generation
    create_model "release-notes" "claude-3-5-sonnet-20241022" \
        "Release notes generation" "ANTHROPIC_API_KEY"

    # General CI tasks
    create_model "ci-assistant" "gpt-4o-mini" \
        "General CI/CD assistant tasks" "OPENAI_API_KEY"

    echo ""
    log_info "=== Phase 2: Configuring Fallback Chains ==="
    update_router_settings

    echo ""
    log_info "=== Phase 3: Creating API Keys ==="

    # GitHub Actions CI key
    create_api_key "github-actions-ci" 10.0 "30d" \
        '["docs-validator", "ci-assistant"]' "ci" "docs-validation"

    # Code review key (higher budget for Claude)
    create_api_key "github-actions-review" 25.0 "30d" \
        '["code-reviewer", "release-notes"]' "ci" "code-review"

    echo ""
    log_info "=============================================="
    log_info "Setup complete!"
    log_info "=============================================="
    echo ""
    echo "Next steps:"
    echo "1. Add the generated API keys to GitHub Secrets:"
    echo "   - LITELLM_API_KEY (for docs-validation workflows)"
    echo "   - LITELLM_REVIEW_KEY (for code-review workflows)"
    echo ""
    echo "2. Verify models in LiteLLM Admin UI:"
    echo "   ${LITELLM_URL}/ui"
    echo ""
}

# === Script Entry Point ===
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Configure LiteLLM models and API keys via Admin API"
        echo ""
        echo "Environment variables:"
        echo "  LITELLM_URL         LiteLLM API URL (default: http://localhost:4000)"
        echo "  LITELLM_MASTER_KEY  Admin master key (required)"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --models      Create models only"
        echo "  --keys        Create API keys only"
        echo "  --fallbacks   Configure fallbacks only"
        exit 0
        ;;
    --models)
        check_prerequisites
        wait_for_litellm
        create_model "docs-validator" "gpt-4o-mini" "Documentation validation" "OPENAI_API_KEY"
        create_model "code-reviewer" "claude-3-5-sonnet-20241022" "Code review" "ANTHROPIC_API_KEY"
        create_model "release-notes" "claude-3-5-sonnet-20241022" "Release notes" "ANTHROPIC_API_KEY"
        create_model "ci-assistant" "gpt-4o-mini" "CI assistant" "OPENAI_API_KEY"
        ;;
    --keys)
        check_prerequisites
        wait_for_litellm
        create_api_key "github-actions-ci" 10.0 "30d" '["docs-validator", "ci-assistant"]' "ci" "docs"
        create_api_key "github-actions-review" 25.0 "30d" '["code-reviewer", "release-notes"]' "ci" "review"
        ;;
    --fallbacks)
        check_prerequisites
        wait_for_litellm
        update_router_settings
        ;;
    *)
        main
        ;;
esac
