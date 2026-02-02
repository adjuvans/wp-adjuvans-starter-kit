#!/usr/bin/env bats
# test-logger.bats - Tests for cli/lib/logger.sh

load '../helpers/test-helper'

setup() {
    setup_temp_dir
    export LOG_DIR="$TEST_LOG_DIR"
    source "${LIB_DIR}/logger.sh"
}

teardown() {
    teardown_temp_dir
}

@test "logger.sh defines LOGGER_LOADED" {
    [ -n "$LOGGER_LOADED" ]
    [ "$LOGGER_LOADED" = "1" ]
}

@test "get_log_file returns valid path" {
    local log_file=$(get_log_file)
    [[ "$log_file" == *"_cli.log" ]]
}

@test "log_info outputs INFO message" {
    run log_info "Test message"
    assert_success
    [[ "$output" == *"INFO"* ]]
    [[ "$output" == *"Test message"* ]]
}

@test "log_warn outputs WARN message" {
    run log_warn "Warning message"
    assert_success
    [[ "$output" == *"WARN"* ]]
    [[ "$output" == *"Warning message"* ]]
}

@test "log_error outputs ERROR message to stderr" {
    run log_error "Error message"
    # log_error outputs to stderr, but bats captures both
    [[ "$output" == *"ERROR"* ]]
    [[ "$output" == *"Error message"* ]]
}

@test "log_success outputs success message" {
    run log_success "Success message"
    assert_success
    [[ "$output" == *"Success message"* ]]
}

@test "log_debug is silent without DEBUG=1" {
    unset DEBUG
    run log_debug "Debug message"
    assert_success
    [ -z "$output" ]
}

@test "log_debug outputs when DEBUG=1" {
    export DEBUG=1
    run log_debug "Debug message"
    assert_success
    [[ "$output" == *"DEBUG"* ]]
    [[ "$output" == *"Debug message"* ]]
}

@test "log_section outputs section header" {
    run log_section "Test Section"
    assert_success
    [[ "$output" == *"Test Section"* ]]
}

@test "log_separator outputs separator" {
    run log_separator
    assert_success
    [[ "$output" == *"---"* ]]
}

@test "logger creates log directory if missing" {
    local new_log_dir="${TEST_TEMP_DIR}/new_logs"
    export LOG_DIR="$new_log_dir"

    # Re-source to use new LOG_DIR
    source "${LIB_DIR}/logger.sh"

    log_info "Test message"

    # Log directory should be created
    [ -d "$new_log_dir" ]
}

@test "logger writes to log file" {
    log_info "File log test"

    local log_file=$(get_log_file)
    [ -f "$log_file" ]
    grep -q "File log test" "$log_file"
}
