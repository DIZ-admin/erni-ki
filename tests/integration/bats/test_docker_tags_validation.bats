#!/usr/bin/env bats
# Tests for scripts/utilities/check-docker-tags.sh

setup() {
    export TEST_PROJECT_ROOT="${BATS_TEST_DIRNAME}/../../.."
    export SCRIPT_PATH="${TEST_PROJECT_ROOT}/scripts/utilities/check-docker-tags.sh"
}

@test "check-docker-tags accepts lowercase tags" {
    echo "ghcr.io/org/image:latest" | bash "$SCRIPT_PATH"
}

@test "check-docker-tags rejects uppercase in org" {
    run bash "$SCRIPT_PATH" <<< "ghcr.io/ORG/image:latest"
    [ "$status" -ne 0 ]
}

@test "check-docker-tags rejects uppercase in image name" {
    run bash "$SCRIPT_PATH" <<< "ghcr.io/org/IMAGE:latest"
    [ "$status" -ne 0 ]
}

@test "check-docker-tags rejects uppercase in tag" {
    run bash "$SCRIPT_PATH" <<< "ghcr.io/org/image:Latest"
    [ "$status" -ne 0 ]
}

@test "check-docker-tags handles multiple tags" {
    run bash "$SCRIPT_PATH" <<< $'ghcr.io/org/image:v1\nghcr.io/org/image:v2'
    [ "$status" -eq 0 ]
}

@test "check-docker-tags rejects mixed case in multiple tags" {
    run bash "$SCRIPT_PATH" <<< $'ghcr.io/org/image:v1\nghcr.io/org/image:V2'
    [ "$status" -ne 0 ]
}

@test "check-docker-tags handles empty input" {
    run bash "$SCRIPT_PATH" <<< ""
    # Should handle gracefully
    [ "$status" -eq 0 ]
}

@test "check-docker-tags validates sha tags" {
    run bash "$SCRIPT_PATH" <<< "ghcr.io/org/image:sha-abc123"
    [ "$status" -eq 0 ]
}

@test "check-docker-tags rejects SHA in tag" {
    run bash "$SCRIPT_PATH" <<< "ghcr.io/org/image:SHA-abc123"
    [ "$status" -ne 0 ]
}
