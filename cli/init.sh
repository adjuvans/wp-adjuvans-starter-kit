#!/bin/sh
# init.sh - Initialize WordPress environment securely
# Downloads WP-CLI, sets up directories, and configures permissions

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"

# Load configuration
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    log_fatal "Configuration file not found: ${CONFIG_FILE}

Please run 'cli/install.sh' first to generate the configuration."
fi

. "$CONFIG_FILE"

log_section "WORDPRESS ENVIRONMENT INITIALIZATION"

# WP-CLI security check (SHA512 verification)
log_section "WP-CLI DOWNLOAD & VERIFICATION"

TMP_PHAR="wp-cli.phar"
TMP_SHA="wp-cli.phar.sha512"

# Download WP-CLI phar and its SHA512 signature with secure options
log_info "Downloading WP-CLI..."
if ! curl --proto '=https' --tlsv1.2 -sSfL -o "$TMP_PHAR" \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; then
    log_fatal "Failed to download WP-CLI phar"
fi

log_info "Downloading WP-CLI signature..."
if ! curl --proto '=https' --tlsv1.2 -sSfL -o "$TMP_SHA" \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.sha512; then
    log_fatal "Failed to download WP-CLI signature"
fi

# Verify SHA512 signature
log_info "Verifying WP-CLI integrity..."
if echo "$(cat "$TMP_SHA")  $TMP_PHAR" | sha512sum -c - >/dev/null 2>&1; then
    mv "$TMP_PHAR" "$file_wpcli_phar"
    chmod 700 "$file_wpcli_phar"
    rm -f "$TMP_SHA"
    log_success "WP-CLI verified and installed: ${file_wpcli_phar}"
else
    log_error "SHA512 verification failed - WP-CLI signature is invalid"
    rm -f "$TMP_PHAR" "$TMP_SHA"
    log_fatal "Installation aborted for security reasons"
fi

log_separator

# WP-CLI bash completion
log_section "WP-CLI BASH COMPLETION"

if curl --proto '=https' --tlsv1.2 -sSfL -o "${file_wpcli_completion}" \
    https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash; then
    chmod 700 "${file_wpcli_completion}"
    log_success "Bash completion installed: ${file_wpcli_completion}"
    log_info "To enable: add 'source ${file_wpcli_completion}' to your ~/.bashrc"
else
    log_warn "Failed to download bash completion (optional, continuing...)"
fi

log_separator

# WP-CLI configuration file
log_section "WP-CLI CONFIGURATION FILE"

if [ ! -f "${file_wpcli_config}" ]; then
    echo "path: ${directory_public}" > "${file_wpcli_config}"
    chmod 700 "${file_wpcli_config}"
    log_success "Config created: ${file_wpcli_config}"
else
    chmod 700 "${file_wpcli_config}"
    log_info "Config already exists: ${file_wpcli_config}"
fi

log_separator

# Function to secure a directory
# Usage: secure_directory "/path/to/dir" "Directory Label"
secure_directory() {
    local dir="$1"
    local label="$2"

    if [ -d "$dir" ]; then
        # Set permissions: 755 for directories, 644 for files
        find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
        find "$dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
        log_info "${label}: permissions applied (755/644)"
    else
        log_info "${label}: creating directory..."
        mkdir -p -m 755 "$dir"
        log_success "${label}: created with permissions 755"
    fi
}

# Secure public directory (WordPress installation)
log_section "PUBLIC DIRECTORY PERMISSIONS"
secure_directory "${directory_public}" "WordPress directory"

# If wp-config.php exists, make it read-only
if [ -f "${directory_public}/wp-config.php" ]; then
    chmod 400 "${directory_public}/wp-config.php"
    log_success "wp-config.php: set to read-only (400)"
fi

# If .htaccess exists, make it read-only
if [ -f "${directory_public}/.htaccess" ]; then
    chmod 400 "${directory_public}/.htaccess"
    log_success ".htaccess: set to read-only (400)"
fi

log_separator

# Secure logs and backups directories
log_section "LOGS & BACKUPS DIRECTORIES"
secure_directory "${directory_log}" "Logs directory"
secure_directory "${directory_backup}" "Backups directory"

# Create .htaccess to deny web access to logs and backups
for dir in "${directory_log}" "${directory_backup}"; do
    if [ -d "$dir" ]; then
        cat > "${dir}/.htaccess" <<'EOF'
# Deny all web access
Order deny,allow
Deny from all
EOF
        chmod 644 "${dir}/.htaccess"
        log_success "Web access denied: ${dir}"
    fi
done

log_separator

# Clean old log files (keep last 30 days)
log_section "LOG CLEANUP"
log_cleanup

log_separator

# Final summary
echo ""
log_success "INITIALIZATION COMPLETE"
echo ""
echo "${CYAN}Next steps:${NORMAL}"
echo "  1. Review configuration: ${GREEN}config/config.sh${NORMAL}"
echo "  2. Install WordPress: ${GREEN}cli/install-wordpress.sh${NORMAL}"
echo "  3. Install plugins: ${GREEN}cli/plugins-install.sh${NORMAL}"
echo ""
