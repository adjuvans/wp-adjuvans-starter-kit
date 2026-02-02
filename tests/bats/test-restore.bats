#!/usr/bin/env bats
# test-restore.bats - Tests for cli/restore.sh

load '../helpers/test-helper'

setup() {
    setup_temp_dir
}

teardown() {
    teardown_temp_dir
}

@test "restore.sh exists and is executable" {
    [ -x "${CLI_DIR}/restore.sh" ]
}

@test "restore.sh --help shows usage" {
    run "${CLI_DIR}/restore.sh" --help
    assert_success
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"restore"* ]]
}

@test "restore.sh --help shows --dry-run option" {
    run "${CLI_DIR}/restore.sh" --help
    assert_success
    [[ "$output" == *"--dry-run"* ]]
}

@test "restore.sh --help shows --db-only option" {
    run "${CLI_DIR}/restore.sh" --help
    assert_success
    [[ "$output" == *"--db-only"* ]]
}

@test "restore.sh --help shows --files-only option" {
    run "${CLI_DIR}/restore.sh" --help
    assert_success
    [[ "$output" == *"--files-only"* ]]
}

@test "restore.sh --help shows --new-url option" {
    run "${CLI_DIR}/restore.sh" --help
    assert_success
    [[ "$output" == *"--new-url"* ]]
}

@test "restore.sh --help shows --list option" {
    run "${CLI_DIR}/restore.sh" --help
    assert_success
    [[ "$output" == *"--list"* ]]
}

@test "restore.sh rejects mutually exclusive options" {
    run "${CLI_DIR}/restore.sh" --db-only --files-only --help
    assert_failure
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "restore.sh fails with invalid option" {
    run "${CLI_DIR}/restore.sh" --invalid-option
    assert_failure
    [[ "$output" == *"Unknown option"* ]]
}

@test "restore.sh requires config file" {
    # Without config, should fail
    cd "$TEST_TEMP_DIR"
    run "${CLI_DIR}/restore.sh" --list
    assert_failure
    [[ "$output" == *"Configuration file not found"* ]] || [[ "$output" == *"config"* ]]
}
