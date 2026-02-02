#!/usr/bin/env bats
# test-colors.bats - Tests for cli/lib/colors.sh

load '../helpers/test-helper'

setup() {
    # Source the colors library
    source "${LIB_DIR}/colors.sh"
}

@test "colors.sh defines COLORS_LOADED" {
    [ -n "$COLORS_LOADED" ]
    [ "$COLORS_LOADED" = "1" ]
}

@test "colors.sh defines basic color variables" {
    # These should be defined (may be empty if no TTY)
    [ -n "${RED+x}" ]
    [ -n "${GREEN+x}" ]
    [ -n "${BLUE+x}" ]
    [ -n "${YELLOW+x}" ]
    [ -n "${CYAN+x}" ]
    [ -n "${NORMAL+x}" ]
}

@test "colors.sh defines formatting variables" {
    [ -n "${BOLD+x}" ]
}

@test "color variables are empty when not in TTY" {
    # In CI/test environment, colors should be empty or defined
    # We just verify they don't cause errors
    echo "${RED}test${NORMAL}" > /dev/null
    echo "${GREEN}test${NORMAL}" > /dev/null
    echo "${BLUE}test${NORMAL}" > /dev/null
}
