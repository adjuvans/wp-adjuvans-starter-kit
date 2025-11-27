#!/bin/sh
# test-validators.sh - Unit tests for validator functions
# Run with: ./tests/test-validators.sh

set -euo pipefail

# Load test framework and validators
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../cli/lib/validators.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
test_equal() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$actual" = "$expected" ]; then
        echo "✓ Test $TESTS_RUN: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "✗ Test $TESTS_RUN: $description"
        echo "  Expected: $expected"
        echo "  Got: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_function_returns() {
    local description="$1"
    local func="$2"
    shift 2
    local args="$*"
    local expected_return="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if $func "$args" >/dev/null 2>&1; then
        actual_return=0
    else
        actual_return=1
    fi

    if [ "$actual_return" = "$expected_return" ]; then
        echo "✓ Test $TESTS_RUN: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "✗ Test $TESTS_RUN: $description"
        echo "  Expected return: $expected_return"
        echo "  Got return: $actual_return"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "======================================"
echo "Validator Functions - Unit Tests"
echo "======================================"
echo ""

# Email validation tests
echo "Testing: validate_email"
echo "--------------------------------------"

validate_email "user@example.com" && test_equal "Valid email (simple)" "0" "0" || test_equal "Valid email (simple)" "1" "0"
validate_email "user.name@example.com" && test_equal "Valid email (with dot)" "0" "0" || test_equal "Valid email (with dot)" "1" "0"
validate_email "user+tag@example.co.uk" && test_equal "Valid email (with plus)" "0" "0" || test_equal "Valid email (with plus)" "1" "0"

validate_email "invalid" && test_equal "Invalid email (no @)" "0" "1" || test_equal "Invalid email (no @)" "1" "1"
validate_email "invalid@" && test_equal "Invalid email (no domain)" "0" "1" || test_equal "Invalid email (no domain)" "1" "1"
validate_email "@example.com" && test_equal "Invalid email (no user)" "0" "1" || test_equal "Invalid email (no user)" "1" "1"

echo ""

# Password validation tests
echo "Testing: validate_password"
echo "--------------------------------------"

validate_password "ValidPass123" 12 && test_equal "Valid password (12 chars)" "0" "0" || test_equal "Valid password (12 chars)" "1" "0"
validate_password "SuperSecure99" 12 && test_equal "Valid password (mixed case)" "0" "0" || test_equal "Valid password (mixed case)" "1" "0"

validate_password "short1A" 12 && test_equal "Invalid password (too short)" "0" "1" || test_equal "Invalid password (too short)" "1" "1"
validate_password "nouppercase123" 12 && test_equal "Invalid password (no uppercase)" "0" "1" || test_equal "Invalid password (no uppercase)" "1" "1"
validate_password "NOLOWERCASE123" 12 && test_equal "Invalid password (no lowercase)" "0" "1" || test_equal "Invalid password (no lowercase)" "1" "1"
validate_password "NoDigitsHere" 12 && test_equal "Invalid password (no digits)" "0" "1" || test_equal "Invalid password (no digits)" "1" "1"

echo ""

# Slug validation tests
echo "Testing: validate_slug"
echo "--------------------------------------"

validate_slug "my-project" && test_equal "Valid slug (simple)" "0" "0" || test_equal "Valid slug (simple)" "1" "0"
validate_slug "project-123" && test_equal "Valid slug (with numbers)" "0" "0" || test_equal "Valid slug (with numbers)" "1" "0"

validate_slug "My-Project" && test_equal "Invalid slug (uppercase)" "0" "1" || test_equal "Invalid slug (uppercase)" "1" "1"
validate_slug "my_project" && test_equal "Invalid slug (underscore)" "0" "1" || test_equal "Invalid slug (underscore)" "1" "1"
validate_slug "my project" && test_equal "Invalid slug (space)" "0" "1" || test_equal "Invalid slug (space)" "1" "1"

echo ""

# Database name validation tests
echo "Testing: validate_db_name"
echo "--------------------------------------"

validate_db_name "wordpress_db" && test_equal "Valid DB name (with underscore)" "0" "0" || test_equal "Valid DB name (with underscore)" "1" "0"
validate_db_name "wpDB123" && test_equal "Valid DB name (mixed case)" "0" "0" || test_equal "Valid DB name (mixed case)" "1" "0"

validate_db_name "123invalid" && test_equal "Invalid DB name (starts with number)" "0" "1" || test_equal "Invalid DB name (starts with number)" "1" "1"
validate_db_name "db-name" && test_equal "Invalid DB name (hyphen)" "0" "1" || test_equal "Invalid DB name (hyphen)" "1" "1"

echo ""

# URL validation tests
echo "Testing: validate_url"
echo "--------------------------------------"

validate_url "https://example.com" && test_equal "Valid URL (https)" "0" "0" || test_equal "Valid URL (https)" "1" "0"
validate_url "http://localhost:8080" && test_equal "Valid URL (with port)" "0" "0" || test_equal "Valid URL (with port)" "1" "0"
validate_url "https://example.com/path" && test_equal "Valid URL (with path)" "0" "0" || test_equal "Valid URL (with path)" "1" "0"

validate_url "ftp://example.com" && test_equal "Invalid URL (wrong protocol)" "0" "1" || test_equal "Invalid URL (wrong protocol)" "1" "1"
validate_url "example.com" && test_equal "Invalid URL (no protocol)" "0" "1" || test_equal "Invalid URL (no protocol)" "1" "1"

echo ""

# Username validation tests
echo "Testing: validate_username"
echo "--------------------------------------"

validate_username "admin_user" && test_equal "Valid username (with underscore)" "0" "0" || test_equal "Valid username (with underscore)" "1" "0"
validate_username "user123" && test_equal "Valid username (with numbers)" "0" "0" || test_equal "Valid username (with numbers)" "1" "0"

validate_username "ab" && test_equal "Invalid username (too short)" "0" "1" || test_equal "Invalid username (too short)" "1" "1"
validate_username "this_is_way_too_long_username" && test_equal "Invalid username (too long)" "0" "1" || test_equal "Invalid username (too long)" "1" "1"
validate_username "user-name" && test_equal "Invalid username (hyphen)" "0" "1" || test_equal "Invalid username (hyphen)" "1" "1"

echo ""

# Table prefix validation tests
echo "Testing: validate_table_prefix"
echo "--------------------------------------"

validate_table_prefix "wp_" && test_equal "Valid prefix (standard)" "0" "0" || test_equal "Valid prefix (standard)" "1" "0"
validate_table_prefix "mysite_" && test_equal "Valid prefix (custom)" "0" "0" || test_equal "Valid prefix (custom)" "1" "0"

validate_table_prefix "wp" && test_equal "Invalid prefix (no underscore)" "0" "1" || test_equal "Invalid prefix (no underscore)" "1" "1"
validate_table_prefix "wp-" && test_equal "Invalid prefix (hyphen)" "0" "1" || test_equal "Invalid prefix (hyphen)" "1" "1"

echo ""
echo "======================================"
echo "Test Results"
echo "======================================"
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ ALL TESTS PASSED"
    exit 0
else
    echo "✗ SOME TESTS FAILED"
    exit 1
fi
