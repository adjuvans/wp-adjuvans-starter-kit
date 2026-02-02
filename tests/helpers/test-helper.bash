#!/usr/bin/env bash
# test-helper.bash - Common test utilities for bats tests

# Project root directory
export PROJECT_ROOT="${BATS_TEST_DIRNAME}/../.."
export CLI_DIR="${PROJECT_ROOT}/cli"
export LIB_DIR="${PROJECT_ROOT}/cli/lib"
export FIXTURES_DIR="${BATS_TEST_DIRNAME}/../fixtures"

# Create a temporary directory for test artifacts
setup_temp_dir() {
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_CONFIG_DIR="${TEST_TEMP_DIR}/config"
    export TEST_WORDPRESS_DIR="${TEST_TEMP_DIR}/wordpress"
    export TEST_BACKUP_DIR="${TEST_TEMP_DIR}/save"
    export TEST_LOG_DIR="${TEST_TEMP_DIR}/logs"

    mkdir -p "$TEST_CONFIG_DIR" "$TEST_WORDPRESS_DIR" "$TEST_BACKUP_DIR" "$TEST_LOG_DIR"
}

# Clean up temporary directory
teardown_temp_dir() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a minimal test config file
create_test_config() {
    cat > "${TEST_CONFIG_DIR}/config.sh" << 'EOF'
#!/bin/sh
# Test configuration

project_name="Test Project"
project_slug="test-project"

directory_public="./wordpress"
directory_log="./logs"
directory_backup="./save"

file_wpcli_phar="./wp-cli.phar"
file_wpcli_completion="./wp-completion.bash"
file_wpcli_config="./wp-cli.yml"

site_locale="en_US"
site_title="Test Site"
site_url="https://test.local"

theme_name="twentytwentyfour"
theme_child_name="twentytwentyfour"

db_host="localhost"
db_name="test_db"
db_user="test_user"
db_pass="test_password"
db_prefix="wp_"
db_charset="utf8mb4"

admin_login="admin"
admin_pass="test_admin_password"
admin_email="admin@test.local"

USE_GPG_ENCRYPTION="false"
GPG_RECIPIENT=""
BACKUP_RETENTION="7"
EOF
}

# Create a mock WordPress directory structure
create_mock_wordpress() {
    mkdir -p "${TEST_WORDPRESS_DIR}/wp-admin"
    mkdir -p "${TEST_WORDPRESS_DIR}/wp-content/plugins"
    mkdir -p "${TEST_WORDPRESS_DIR}/wp-content/themes"
    mkdir -p "${TEST_WORDPRESS_DIR}/wp-includes"

    # Create minimal wp-config.php
    cat > "${TEST_WORDPRESS_DIR}/wp-config.php" << 'EOF'
<?php
define('DB_NAME', 'test_db');
define('DB_USER', 'test_user');
define('DB_PASSWORD', 'test_password');
define('DB_HOST', 'localhost');
$table_prefix = 'wp_';
EOF

    # Create a dummy index.php
    echo "<?php // WordPress" > "${TEST_WORDPRESS_DIR}/index.php"
}

# Create a mock backup archive
create_mock_backup() {
    local backup_name="${1:-test_backup}"
    local backup_dir="${TEST_BACKUP_DIR}"

    # Create temporary files for the backup
    local temp_dir=$(mktemp -d)

    # Create database.sql
    cat > "${temp_dir}/database.sql" << 'EOF'
-- Mock database dump
DROP TABLE IF EXISTS `wp_options`;
CREATE TABLE `wp_options` (
  `option_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `option_name` varchar(191) NOT NULL,
  `option_value` longtext NOT NULL,
  PRIMARY KEY (`option_id`)
);
INSERT INTO `wp_options` VALUES (1,'siteurl','https://test.local');
INSERT INTO `wp_options` VALUES (2,'home','https://test.local');
INSERT INTO `wp_options` VALUES (3,'blogname','Test Site');
EOF

    # Create wordpress-files.tar.gz
    mkdir -p "${temp_dir}/wp-files"
    echo "<?php // Test" > "${temp_dir}/wp-files/index.php"
    tar -czf "${temp_dir}/wordpress-files.tar.gz" -C "${temp_dir}/wp-files" .

    # Create the backup archive
    tar -czf "${backup_dir}/${backup_name}.tar.gz" -C "${temp_dir}" database.sql wordpress-files.tar.gz

    rm -rf "${temp_dir}"

    echo "${backup_dir}/${backup_name}.tar.gz"
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Expected file to exist: $file" >&2
        return 1
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Expected directory to exist: $dir" >&2
        return 1
    fi
}

# Assert that output contains a string
assert_output_contains() {
    local expected="$1"
    if [[ ! "$output" == *"$expected"* ]]; then
        echo "Expected output to contain: $expected" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Assert command succeeds
assert_success() {
    if [ "$status" -ne 0 ]; then
        echo "Expected success (status 0), got status $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Assert command fails
assert_failure() {
    if [ "$status" -eq 0 ]; then
        echo "Expected failure (non-zero status), got status 0" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Skip test if command not available
skip_if_command_missing() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        skip "$cmd is not installed"
    fi
}

# Load a library for testing
load_lib() {
    local lib_name="$1"
    source "${LIB_DIR}/${lib_name}.sh"
}
