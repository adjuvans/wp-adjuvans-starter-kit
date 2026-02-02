#!/usr/bin/env bats
# test-backup.bats - Tests for cli/backup.sh

load '../helpers/test-helper'

setup() {
    setup_temp_dir
}

teardown() {
    teardown_temp_dir
}

@test "backup.sh exists and is executable" {
    [ -x "${CLI_DIR}/backup.sh" ]
}

@test "backup.sh requires config file" {
    cd "$TEST_TEMP_DIR"
    run "${CLI_DIR}/backup.sh"
    assert_failure
    [[ "$output" == *"Configuration file not found"* ]] || [[ "$output" == *"config"* ]]
}
