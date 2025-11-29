#!/usr/bin/env bats
# Integration tests for nginx healthcheck.sh

setup() {
    export TEST_PROJECT_ROOT="${BATS_TEST_DIRNAME}/../../.."
    export SCRIPT_PATH="${TEST_PROJECT_ROOT}/conf/nginx/healthcheck.sh"

    # Skip if script doesn't exist
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "healthcheck.sh not found"
    fi
}

@test "healthcheck script exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "healthcheck returns 0 for valid nginx status" {
    skip "Requires running nginx"

    run bash "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "healthcheck handles missing nginx gracefully" {
    # Test with non-existent service
    run bash -c "NGINX_HOST=nonexistent bash '$SCRIPT_PATH'"
    # Should fail gracefully
    [ "$status" -ne 0 ]
}

@test "healthcheck script has proper shebang" {
    head -1 "$SCRIPT_PATH" | grep -q "^#!/"
}

@test "healthcheck validates environment variables" {
    # Test that script handles missing env vars
    run bash -c "unset NGINX_HOST; bash '$SCRIPT_PATH'"
    # Should fail when required env vars are missing
    [ "$status" -ne 0 ]
}
