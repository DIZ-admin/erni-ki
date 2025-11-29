#!/usr/bin/env bats
# BATS tests for scripts/lib/common.sh

setup() {
    # Load the common library
    load "../../../scripts/lib/common.sh"

    # Set test project root
    export TEST_PROJECT_ROOT="${BATS_TEST_DIRNAME}/../../.."
}

@test "log_info outputs formatted message" {
    run log_info "Test message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "INFO" ]]
    [[ "$output" =~ "Test message" ]]
}

@test "log_error outputs formatted error" {
    run log_error "Error message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ERROR" ]]
    [[ "$output" =~ "Error message" ]]
}

@test "log_fatal exits with error code" {
    run log_fatal "Fatal error" 42
    [ "$status" -eq 42 ]
    [[ "$output" =~ "FATAL" ]]
}

@test "get_project_root returns valid path" {
    run get_project_root
    [ "$status" -eq 0 ]
    [ -d "$output" ]
    [ -f "$output/compose.yml" ]
}

@test "command_exists detects existing command" {
    run command_exists "bash"
    [ "$status" -eq 0 ]
}

@test "command_exists fails for non-existing command" {
    run command_exists "nonexistent_command_xyz123"
    [ "$status" -eq 1 ]
}

@test "version_compare handles equal versions" {
    run version_compare "1.2.3" "1.2.3"
    [ "$output" -eq 0 ]
}

@test "version_compare detects newer version" {
    run version_compare "1.2.4" "1.2.3"
    [ "$output" -eq 1 ]
}

@test "version_compare detects older version" {
    run version_compare "1.2.2" "1.2.3"
    [ "$output" -eq -1 ]
}

@test "version_compare handles v prefix" {
    run version_compare "v1.2.3" "1.2.3"
    [ "$output" -eq 0 ]
}

@test "read_secret returns empty for non-existent secret" {
    run read_secret "nonexistent_secret_xyz123"
    [ "$status" -eq 1 ]
}

@test "ensure_directory creates directory" {
    local test_dir="/tmp/erni-ki-test-$$"
    run ensure_directory "$test_dir"
    [ "$status" -eq 0 ]
    [ -d "$test_dir" ]
    rm -rf "$test_dir"
}

@test "get_docker_compose_cmd returns valid command" {
    run get_docker_compose_cmd
    [ "$status" -eq 0 ]
    [[ "$output" =~ "docker" ]]
}
