#!/usr/bin/env bash
# ==============================================================================
# LiteLLM Gateway Integration Tests
# Tests gateway connectivity, health endpoints, and basic completion
# ==============================================================================
set -euo pipefail

# === Configuration ===
LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
LITELLM_API_KEY="${LITELLM_API_KEY:-}"
TIMEOUT=10
PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# === Helper Functions ===
log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

log_info() {
    echo -e "[INFO] $1"
}

# === Tests ===
test_health_liveness() {
    log_info "Testing liveness endpoint..."
    if curl -sf --max-time "$TIMEOUT" "${LITELLM_URL}/health/liveliness" > /dev/null 2>&1; then
        log_pass "Liveness check passed"
    else
        log_fail "Liveness check failed - gateway may be down"
    fi
}

test_health_readiness() {
    log_info "Testing readiness endpoint..."
    if curl -sf --max-time "$TIMEOUT" "${LITELLM_URL}/health/readiness" > /dev/null 2>&1; then
        log_pass "Readiness check passed"
    else
        log_fail "Readiness check failed - gateway not ready"
    fi
}

test_models_list() {
    log_info "Testing models list endpoint..."
    if [[ -z "$LITELLM_API_KEY" ]]; then
        log_skip "Models list (LITELLM_API_KEY not set)"
        return
    fi

    response=$(curl -sf --max-time "$TIMEOUT" \
        -H "Authorization: Bearer ${LITELLM_API_KEY}" \
        "${LITELLM_URL}/v1/models" 2>/dev/null || echo '{"error": true}')

    if echo "$response" | grep -q '"data"'; then
        model_count=$(echo "$response" | grep -o '"id"' | wc -l)
        log_pass "Models list returned ${model_count} models"
    else
        log_fail "Models list failed: $response"
    fi
}

test_model_alias_exists() {
    local alias="$1"
    log_info "Testing model alias: $alias..."

    if [[ -z "$LITELLM_API_KEY" ]]; then
        log_skip "Model alias '$alias' (LITELLM_API_KEY not set)"
        return
    fi

    response=$(curl -sf --max-time "$TIMEOUT" \
        -H "Authorization: Bearer ${LITELLM_API_KEY}" \
        "${LITELLM_URL}/model/info?model_name=${alias}" 2>/dev/null || echo '{"error": true}')

    if echo "$response" | grep -q '"data"'; then
        log_pass "Model alias '$alias' exists"
    else
        log_fail "Model alias '$alias' not found"
    fi
}

test_chat_completion() {
    log_info "Testing chat completion..."

    if [[ -z "$LITELLM_API_KEY" ]]; then
        log_skip "Chat completion (LITELLM_API_KEY not set)"
        return
    fi

    response=$(curl -sf --max-time 30 \
        -X POST "${LITELLM_URL}/v1/chat/completions" \
        -H "Authorization: Bearer ${LITELLM_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "docs-validator",
            "messages": [{"role": "user", "content": "Say OK"}],
            "max_tokens": 10
        }' 2>/dev/null || echo '{"error": true}')

    if echo "$response" | grep -q '"choices"'; then
        log_pass "Chat completion successful"
    elif echo "$response" | grep -q '"error"'; then
        # Check if it's a rate limit or quota error (acceptable)
        if echo "$response" | grep -qi "rate\|quota\|budget"; then
            log_skip "Chat completion (rate limit or budget exceeded)"
        else
            log_fail "Chat completion failed: $response"
        fi
    else
        log_fail "Chat completion failed: unexpected response"
    fi
}

test_spend_tracking() {
    log_info "Testing spend tracking endpoint..."

    if [[ -z "$LITELLM_API_KEY" ]]; then
        log_skip "Spend tracking (LITELLM_API_KEY not set)"
        return
    fi

    response=$(curl -sf --max-time "$TIMEOUT" \
        -H "Authorization: Bearer ${LITELLM_API_KEY}" \
        "${LITELLM_URL}/spend/logs" 2>/dev/null || echo '{"error": true}')

    if [[ "$response" != *'"error"'* ]]; then
        log_pass "Spend tracking endpoint accessible"
    else
        log_skip "Spend tracking (may require master key)"
    fi
}

# === Main ===
main() {
    echo "=============================================="
    echo "LiteLLM Gateway Integration Tests"
    echo "URL: $LITELLM_URL"
    echo "=============================================="
    echo ""

    # Health checks (no auth required)
    test_health_liveness
    test_health_readiness

    # Model tests (auth required)
    test_models_list
    test_model_alias_exists "docs-validator"
    test_model_alias_exists "code-reviewer"

    # Completion test (auth required)
    test_chat_completion

    # Spend tracking (may require master key)
    test_spend_tracking

    echo ""
    echo "=============================================="
    echo "Results: ${GREEN}${PASSED} passed${NC}, ${RED}${FAILED} failed${NC}"
    echo "=============================================="

    if [[ $FAILED -gt 0 ]]; then
        exit 1
    fi
}

# === Help ===
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "LiteLLM Gateway Integration Tests"
    echo ""
    echo "Environment variables:"
    echo "  LITELLM_URL       Gateway URL (default: http://localhost:4000)"
    echo "  LITELLM_API_KEY   API key for authenticated endpoints"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    exit 0
fi

main "$@"
