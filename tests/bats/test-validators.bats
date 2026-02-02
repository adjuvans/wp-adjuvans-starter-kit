#!/usr/bin/env bats
# test-validators.bats - Tests for cli/lib/validators.sh

load '../helpers/test-helper'

setup() {
    source "${LIB_DIR}/validators.sh"
}

# =============================================================================
# validate_email tests
# =============================================================================

@test "validate_email: accepts valid email" {
    run validate_email "user@example.com"
    assert_success
}

@test "validate_email: accepts email with subdomain" {
    run validate_email "user@mail.example.com"
    assert_success
}

@test "validate_email: accepts email with plus" {
    run validate_email "user+tag@example.com"
    assert_success
}

@test "validate_email: rejects email without @" {
    run validate_email "userexample.com"
    assert_failure
}

@test "validate_email: rejects email without domain" {
    run validate_email "user@"
    assert_failure
}

@test "validate_email: rejects empty string" {
    run validate_email ""
    assert_failure
}

# =============================================================================
# validate_password tests
# =============================================================================

@test "validate_password: accepts strong password (uppercase, lowercase, digit, 12+ chars)" {
    run validate_password "MyStr0ngPassword"
    assert_success
}

@test "validate_password: rejects password without uppercase" {
    run validate_password "mystr0ngpassword"
    assert_failure
}

@test "validate_password: rejects password without lowercase" {
    run validate_password "MYSTR0NGPASSWORD"
    assert_failure
}

@test "validate_password: rejects password without digit" {
    run validate_password "MyStrongPassword"
    assert_failure
}

@test "validate_password: rejects short password (less than 12 chars)" {
    run validate_password "MyStr0ng"
    assert_failure
}

@test "validate_password: rejects empty password" {
    run validate_password ""
    assert_failure
}

@test "validate_password: accepts custom minimum length" {
    run validate_password "MyStr0ng" 8
    assert_success
}

# =============================================================================
# validate_slug tests
# =============================================================================

@test "validate_slug: accepts valid slug" {
    run validate_slug "my-project"
    assert_success
}

@test "validate_slug: accepts slug with numbers" {
    run validate_slug "project-123"
    assert_success
}

@test "validate_slug: accepts lowercase only" {
    run validate_slug "myproject"
    assert_success
}

@test "validate_slug: rejects uppercase" {
    run validate_slug "MyProject"
    assert_failure
}

@test "validate_slug: rejects spaces" {
    run validate_slug "my project"
    assert_failure
}

@test "validate_slug: rejects underscores" {
    run validate_slug "my_project"
    assert_failure
}

@test "validate_slug: rejects empty string" {
    run validate_slug ""
    assert_failure
}

@test "validate_slug: rejects starting with hyphen" {
    run validate_slug "-myproject"
    assert_failure
}

@test "validate_slug: rejects ending with hyphen" {
    run validate_slug "myproject-"
    assert_failure
}

# =============================================================================
# validate_url tests
# =============================================================================

@test "validate_url: accepts https URL" {
    run validate_url "https://example.com"
    assert_success
}

@test "validate_url: accepts http URL" {
    run validate_url "http://example.com"
    assert_success
}

@test "validate_url: accepts URL with path" {
    run validate_url "https://example.com/path/to/page"
    assert_success
}

@test "validate_url: accepts URL with port" {
    run validate_url "https://example.com:8080"
    assert_success
}

@test "validate_url: rejects URL without protocol" {
    run validate_url "example.com"
    assert_failure
}

@test "validate_url: rejects empty string" {
    run validate_url ""
    assert_failure
}

# =============================================================================
# validate_db_name tests
# =============================================================================

@test "validate_db_name: accepts valid database name" {
    run validate_db_name "wordpress_db"
    assert_success
}

@test "validate_db_name: accepts name with numbers" {
    run validate_db_name "wp_db_123"
    assert_success
}

@test "validate_db_name: accepts name starting with underscore" {
    run validate_db_name "_database"
    assert_success
}

@test "validate_db_name: rejects name starting with number" {
    run validate_db_name "123database"
    assert_failure
}

@test "validate_db_name: rejects name with hyphen" {
    run validate_db_name "my-database"
    assert_failure
}

@test "validate_db_name: rejects empty string" {
    run validate_db_name ""
    assert_failure
}

# =============================================================================
# validate_table_prefix tests
# =============================================================================

@test "validate_table_prefix: accepts valid prefix with underscore" {
    run validate_table_prefix "wp_"
    assert_success
}

@test "validate_table_prefix: accepts custom prefix" {
    run validate_table_prefix "mysite_"
    assert_success
}

@test "validate_table_prefix: accepts prefix with numbers" {
    run validate_table_prefix "wp2_"
    assert_success
}

@test "validate_table_prefix: rejects prefix without trailing underscore" {
    run validate_table_prefix "wp"
    assert_failure
}

@test "validate_table_prefix: rejects prefix with hyphen" {
    run validate_table_prefix "wp-test_"
    assert_failure
}

@test "validate_table_prefix: rejects empty string" {
    run validate_table_prefix ""
    assert_failure
}

# =============================================================================
# validate_path tests
# =============================================================================

@test "validate_path: accepts relative path" {
    run validate_path "./wordpress"
    assert_success
}

@test "validate_path: accepts absolute path" {
    run validate_path "/var/www/html"
    assert_success
}

@test "validate_path: rejects path traversal with .." {
    run validate_path "../parent/child"
    assert_failure
}

@test "validate_path: rejects empty path" {
    run validate_path ""
    assert_failure
}

# =============================================================================
# validate_username tests
# =============================================================================

@test "validate_username: accepts valid username" {
    run validate_username "admin"
    assert_success
}

@test "validate_username: accepts username with underscore" {
    run validate_username "admin_user"
    assert_success
}

@test "validate_username: accepts username with numbers" {
    run validate_username "admin123"
    assert_success
}

@test "validate_username: rejects username too short (< 3 chars)" {
    run validate_username "ab"
    assert_failure
}

@test "validate_username: rejects username too long (> 16 chars)" {
    run validate_username "verylongusername123"
    assert_failure
}

@test "validate_username: rejects username with hyphen" {
    run validate_username "admin-user"
    assert_failure
}

@test "validate_username: rejects empty string" {
    run validate_username ""
    assert_failure
}

# =============================================================================
# sanitize_input tests
# =============================================================================

@test "sanitize_input: removes semicolons" {
    result=$(sanitize_input "test;command")
    [ "$result" = "testcommand" ]
}

@test "sanitize_input: removes pipes" {
    result=$(sanitize_input "test|command")
    [ "$result" = "testcommand" ]
}

@test "sanitize_input: removes backticks" {
    result=$(sanitize_input 'test`command`')
    [ "$result" = "testcommand" ]
}

@test "sanitize_input: removes dollar signs" {
    result=$(sanitize_input 'test$VAR')
    [ "$result" = "testVAR" ]
}

@test "sanitize_input: removes parentheses" {
    result=$(sanitize_input "test(command)")
    [ "$result" = "testcommand" ]
}

@test "sanitize_input: keeps normal text" {
    result=$(sanitize_input "normal text 123")
    [ "$result" = "normal text 123" ]
}
