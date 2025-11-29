#!/usr/bin/env bats
# Integration tests for health-monitor-v2.sh

setup() {
    export TEST_PROJECT_ROOT="${BATS_TEST_DIRNAME}/../../.."
    export SCRIPT_PATH="${TEST_PROJECT_ROOT}/scripts/health-monitor-v2.sh"

    # Skip if Docker not available
    if ! command -v docker &>/dev/null; then
        skip "Docker not available"
    fi
}

@test "health-monitor shows help" {
    run bash "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Options:" ]]
}

@test "health-monitor accepts markdown format" {
    skip "Requires running Docker Compose stack"

    local report_file="/tmp/health-report-$$.md"
    run bash "$SCRIPT_PATH" -r "$report_file" -f markdown

    [ -f "$report_file" ]
    grep -q "# ERNI-KI Health Report" "$report_file"

    rm -f "$report_file"
}

@test "health-monitor accepts json format" {
    skip "Requires running Docker Compose stack"

    local report_file="/tmp/health-report-$$.json"
    run bash "$SCRIPT_PATH" -r "$report_file" -f json

    [ -f "$report_file" ]
    grep -q '"timestamp"' "$report_file"
    grep -q '"summary"' "$report_file"

    rm -f "$report_file"
}

@test "health-monitor rejects invalid format" {
    run bash "$SCRIPT_PATH" -f invalid_format
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Invalid format" ]]
}

@test "health-monitor checks compose services" {
    skip "Requires running Docker Compose stack"

    run bash "$SCRIPT_PATH"
    [[ "$output" =~ "Checking container status" ]]
}

@test "health-monitor validates report path is writable" {
    local readonly_dir="/tmp/readonly-test-$$"
    mkdir -p "$readonly_dir"
    chmod 444 "$readonly_dir"

    run bash "$SCRIPT_PATH" -r "${readonly_dir}/report.md"
    [ "$status" -ne 0 ]

    chmod 755 "$readonly_dir"
    rm -rf "$readonly_dir"
}
