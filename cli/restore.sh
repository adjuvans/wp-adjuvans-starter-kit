#!/bin/sh
# restore.sh - Restore WordPress installation from backup
# Supports encrypted (GPG) and plain backups
# Created for WPASK v3.0

set -eu
# pipefail only if available (bash)
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# =============================================================================
# SCRIPT SETUP
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

# Default options
DRY_RUN="false"
DB_ONLY="false"
FILES_ONLY="false"
NEW_URL=""
SKIP_BACKUP="false"
ARCHIVE_PATH=""

# =============================================================================
# USAGE
# =============================================================================

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [ARCHIVE_PATH]

Restore WordPress installation from a backup created by backup.sh

OPTIONS:
    -h, --help          Show this help message
    -n, --dry-run       Simulate restore without making changes
    -d, --db-only       Restore database only (skip files)
    -f, --files-only    Restore files only (skip database)
    -u, --new-url URL   Replace old URL with new URL after restore
    --skip-backup       Skip pre-restore backup (not recommended)
    -l, --list          List available backups

EXAMPLES:
    # Interactive mode (list and select backup)
    $SCRIPT_NAME

    # Restore specific backup
    $SCRIPT_NAME save/2024-01-15-120000_mysite.tar.gz

    # Restore with domain migration
    $SCRIPT_NAME --new-url="https://new-domain.com" save/backup.tar.gz

    # Restore database only
    $SCRIPT_NAME --db-only save/backup.tar.gz

    # Dry run (simulation)
    $SCRIPT_NAME --dry-run save/backup.tar.gz

NOTES:
    - Supports both plain (.tar.gz) and encrypted (.tar.gz.gpg) backups
    - Only backups created with WPASK v2.0+ are supported
    - A safety backup is created before restore (unless --skip-backup)
EOF
}

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================

LIST_MODE="false"

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -d|--db-only)
            DB_ONLY="true"
            shift
            ;;
        -f|--files-only)
            FILES_ONLY="true"
            shift
            ;;
        -u|--new-url)
            if [ -z "${2:-}" ]; then
                echo "ERROR: --new-url requires a URL argument" >&2
                exit 1
            fi
            NEW_URL="$2"
            shift 2
            ;;
        --new-url=*)
            NEW_URL="${1#*=}"
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP="true"
            shift
            ;;
        -l|--list)
            LIST_MODE="true"
            shift
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
        *)
            ARCHIVE_PATH="$1"
            shift
            ;;
    esac
done

# Validate mutually exclusive options
if [ "$DB_ONLY" = "true" ] && [ "$FILES_ONLY" = "true" ]; then
    echo "ERROR: --db-only and --files-only are mutually exclusive" >&2
    exit 1
fi

# =============================================================================
# LOAD CONFIGURATION
# =============================================================================

CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    echo "Run 'make init' to initialize the project first."
    exit 1
fi

. "$CONFIG_FILE"

# Set LOG_DIR from config before loading logger
export LOG_DIR="${directory_log}"

# Load dependencies
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# List available backups
list_backups() {
    local backup_dir="${directory_backup}"

    if [ ! -d "$backup_dir" ]; then
        log_error "Backup directory not found: ${backup_dir}"
        return 1
    fi

    local count=0
    echo ""
    echo "${CYAN}Available backups in ${backup_dir}:${NORMAL}"
    echo ""

    # List backups sorted by date (newest first)
    for backup in $(find "$backup_dir" -maxdepth 1 \( -name "*.tar.gz" -o -name "*.tar.gz.gpg" \) -type f 2>/dev/null | sort -r); do
        count=$((count + 1))
        local size=$(du -h "$backup" 2>/dev/null | cut -f1)
        local name=$(basename "$backup")
        local encrypted=""

        if echo "$name" | grep -q "\.gpg$"; then
            encrypted="${YELLOW}[encrypted]${NORMAL}"
        fi

        printf "  %2d. %s (%s) %s\n" "$count" "$name" "$size" "$encrypted"
    done

    if [ "$count" -eq 0 ]; then
        log_warn "No backups found in ${backup_dir}"
        return 1
    fi

    echo ""
    return 0
}

# Select backup interactively
select_backup() {
    local backup_dir="${directory_backup}"
    local backups=""
    local count=0

    # Build array of backups
    for backup in $(find "$backup_dir" -maxdepth 1 \( -name "*.tar.gz" -o -name "*.tar.gz.gpg" \) -type f 2>/dev/null | sort -r); do
        count=$((count + 1))
        backups="${backups}${backup}
"
    done

    if [ "$count" -eq 0 ]; then
        return 1
    fi

    list_backups

    printf "Select backup number (1-%d) or 'q' to quit: " "$count"
    read -r selection

    if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
        log_info "Restore cancelled by user"
        exit 0
    fi

    if ! echo "$selection" | grep -qE '^[0-9]+$'; then
        log_error "Invalid selection: ${selection}"
        return 1
    fi

    if [ "$selection" -lt 1 ] || [ "$selection" -gt "$count" ]; then
        log_error "Selection out of range: ${selection}"
        return 1
    fi

    # Get the selected backup
    ARCHIVE_PATH=$(echo "$backups" | sed -n "${selection}p")

    if [ -z "$ARCHIVE_PATH" ]; then
        log_error "Failed to select backup"
        return 1
    fi

    log_info "Selected: $(basename "$ARCHIVE_PATH")"
    return 0
}

# Verify archive integrity
verify_archive() {
    local archive="$1"
    local is_encrypted="false"

    log_info "Verifying archive integrity..."

    # Check if encrypted
    if echo "$archive" | grep -q "\.gpg$"; then
        is_encrypted="true"
        log_info "Archive is GPG encrypted"

        # For encrypted files, we can only verify GPG can read the header
        if ! gpg --list-packets "$archive" >/dev/null 2>&1; then
            log_error "Archive appears to be corrupted or not a valid GPG file"
            return 1
        fi
    else
        # For plain tar.gz, verify with gzip test
        if ! gzip -t "$archive" 2>/dev/null; then
            log_error "Archive is corrupted (gzip test failed)"
            return 1
        fi

        # Verify tar structure
        if ! tar -tzf "$archive" >/dev/null 2>&1; then
            log_error "Archive has invalid tar structure"
            return 1
        fi
    fi

    log_success "Archive integrity verified"
    return 0
}

# Check archive format (v2.0+ format)
check_archive_format() {
    local archive="$1"
    local temp_dir="$2"

    log_info "Checking archive format..."

    # Expected files in v2.0+ backup
    local has_db="false"
    local has_files="false"

    # List contents without extracting
    local contents=""
    if echo "$archive" | grep -q "\.gpg$"; then
        # For encrypted, we need to decrypt to temp to check
        # This is done later during actual extraction
        log_info "Encrypted archive - format will be verified after decryption"
        return 0
    else
        contents=$(tar -tzf "$archive" 2>/dev/null || true)
    fi

    if echo "$contents" | grep -q "^database\.sql$"; then
        has_db="true"
    fi

    if echo "$contents" | grep -q "^wordpress-files\.tar\.gz$"; then
        has_files="true"
    fi

    if [ "$has_db" = "false" ] || [ "$has_files" = "false" ]; then
        log_error "Invalid backup format - not a WPASK v2.0+ backup"
        log_error "Expected: database.sql and wordpress-files.tar.gz"
        log_error "Found: ${contents}"
        return 1
    fi

    log_success "Valid WPASK v2.0+ backup format"
    return 0
}

# Extract archive to temp directory
extract_archive() {
    local archive="$1"
    local temp_dir="$2"

    log_info "Extracting archive..."

    if echo "$archive" | grep -q "\.gpg$"; then
        # Decrypt and extract GPG encrypted archive
        log_info "Decrypting GPG archive..."

        if ! command -v gpg >/dev/null 2>&1; then
            log_fatal "GPG is required to decrypt this backup but is not installed"
        fi

        if ! gpg --decrypt "$archive" 2>/dev/null | tar -xzf - -C "$temp_dir"; then
            log_fatal "Failed to decrypt and extract archive"
        fi
    else
        # Extract plain tar.gz
        if ! tar -xzf "$archive" -C "$temp_dir"; then
            log_fatal "Failed to extract archive"
        fi
    fi

    # Verify extracted contents
    if [ ! -f "${temp_dir}/database.sql" ] && [ "$FILES_ONLY" = "false" ]; then
        log_fatal "database.sql not found in archive"
    fi

    if [ ! -f "${temp_dir}/wordpress-files.tar.gz" ] && [ "$DB_ONLY" = "false" ]; then
        log_fatal "wordpress-files.tar.gz not found in archive"
    fi

    log_success "Archive extracted successfully"
    return 0
}

# Create pre-restore backup
create_safety_backup() {
    if [ "$SKIP_BACKUP" = "true" ]; then
        log_warn "Skipping pre-restore backup (--skip-backup)"
        return 0
    fi

    log_section "SAFETY BACKUP"
    log_info "Creating safety backup before restore..."

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would create safety backup"
        return 0
    fi

    # Create a quick backup using backup.sh
    local backup_script="${SCRIPT_DIR}/backup.sh"

    if [ -x "$backup_script" ]; then
        if ! "$backup_script"; then
            log_error "Failed to create safety backup"
            printf "Continue without safety backup? (y/N): "
            read -r answer
            if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
                log_fatal "Restore aborted - no safety backup"
            fi
        else
            log_success "Safety backup created"
        fi
    else
        log_warn "backup.sh not found or not executable - skipping safety backup"
    fi

    return 0
}

# Restore database
restore_database() {
    local sql_file="$1"

    log_section "DATABASE RESTORE"

    if [ ! -f "$sql_file" ]; then
        log_error "Database dump not found: ${sql_file}"
        return 1
    fi

    local sql_size=$(du -h "$sql_file" | cut -f1)
    log_info "Restoring database from ${sql_size} dump..."

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would restore database (${sql_size})"
        return 0
    fi

    # Change to WordPress directory for WP-CLI
    cd "$directory_public" || log_fatal "Cannot access directory: ${directory_public}"

    # Use WP-CLI if available
    if [ -f "../${file_wpcli_phar}" ]; then
        log_info "Using WP-CLI for database import..."

        if ! php "../${file_wpcli_phar}" db import "$sql_file" --quiet; then
            log_fatal "Database import failed"
        fi
    else
        # Fallback to mysql command
        log_info "Using mysql client for database import..."

        if command -v mysql >/dev/null 2>&1; then
            if ! MYSQL_PWD="$db_pass" mysql -h "$db_host" -u "$db_user" "$db_name" < "$sql_file"; then
                log_fatal "Database import failed"
            fi
        else
            log_fatal "Neither WP-CLI nor mysql client available for database import"
        fi
    fi

    cd ..

    log_success "Database restored successfully"
    return 0
}

# Restore WordPress files
restore_files() {
    local files_archive="$1"

    log_section "FILES RESTORE"

    if [ ! -f "$files_archive" ]; then
        log_error "Files archive not found: ${files_archive}"
        return 1
    fi

    local archive_size=$(du -h "$files_archive" | cut -f1)
    log_info "Restoring files from ${archive_size} archive..."

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would restore files to ${directory_public}"
        log_info "[DRY-RUN] Archive size: ${archive_size}"
        return 0
    fi

    # Backup current wp-config.php if it exists (might have local modifications)
    local wp_config_backup=""
    if [ -f "${directory_public}/wp-config.php" ]; then
        wp_config_backup=$(mktemp)
        cp "${directory_public}/wp-config.php" "$wp_config_backup"
        log_info "Current wp-config.php backed up"
    fi

    # Clear existing files (except wp-config.php)
    log_info "Clearing existing WordPress files..."

    # Create a temporary location for extraction
    local extract_dir=$(mktemp -d)
    chmod 700 "$extract_dir"

    # Extract files to temp directory first
    if ! tar -xzf "$files_archive" -C "$extract_dir"; then
        rm -rf "$extract_dir"
        log_fatal "Failed to extract files archive"
    fi

    # Remove old WordPress files (keeping wp-config.php)
    find "$directory_public" -mindepth 1 ! -name 'wp-config.php' -delete 2>/dev/null || true

    # Move extracted files to WordPress directory
    if ! cp -r "$extract_dir"/* "$directory_public"/; then
        rm -rf "$extract_dir"
        log_fatal "Failed to copy restored files"
    fi

    rm -rf "$extract_dir"

    # Restore original wp-config.php if we had one and user wants to keep it
    if [ -n "$wp_config_backup" ] && [ -f "$wp_config_backup" ]; then
        log_info "Restoring original wp-config.php (contains local DB settings)"
        cp "$wp_config_backup" "${directory_public}/wp-config.php"
        rm -f "$wp_config_backup"
    fi

    # Set proper permissions
    log_info "Setting file permissions..."
    find "$directory_public" -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "$directory_public" -type f -exec chmod 644 {} \; 2>/dev/null || true

    # Secure wp-config.php
    if [ -f "${directory_public}/wp-config.php" ]; then
        chmod 640 "${directory_public}/wp-config.php" 2>/dev/null || true
    fi

    log_success "Files restored successfully"
    return 0
}

# Perform URL replacement
replace_url() {
    local old_url="$1"
    local new_url="$2"

    log_section "URL REPLACEMENT"
    log_info "Replacing URLs: ${old_url} -> ${new_url}"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would replace URL"
        return 0
    fi

    cd "$directory_public" || log_fatal "Cannot access directory: ${directory_public}"

    if [ -f "../${file_wpcli_phar}" ]; then
        log_info "Running search-replace via WP-CLI..."

        if ! php "../${file_wpcli_phar}" search-replace "$old_url" "$new_url" --all-tables --quiet; then
            log_warn "URL replacement completed with warnings"
        else
            log_success "URL replacement completed"
        fi

        # Also update siteurl and home options explicitly
        php "../${file_wpcli_phar}" option update siteurl "$new_url" --quiet 2>/dev/null || true
        php "../${file_wpcli_phar}" option update home "$new_url" --quiet 2>/dev/null || true

        # Flush rewrite rules
        php "../${file_wpcli_phar}" rewrite flush --quiet 2>/dev/null || true

    else
        log_warn "WP-CLI not available - manual URL replacement required"
        log_info "Run this SQL after restore:"
        echo ""
        echo "  UPDATE ${db_prefix}options SET option_value = '${new_url}' WHERE option_name = 'siteurl';"
        echo "  UPDATE ${db_prefix}options SET option_value = '${new_url}' WHERE option_name = 'home';"
        echo ""
    fi

    cd ..
    return 0
}

# Detect old URL from database dump
detect_old_url() {
    local sql_file="$1"

    if [ ! -f "$sql_file" ]; then
        echo ""
        return
    fi

    # Extract siteurl from SQL dump
    local old_url=$(grep -oP "INSERT INTO \`?${db_prefix}options\`?.*'siteurl'[^']*'([^']+)'" "$sql_file" 2>/dev/null | grep -oP "https?://[^'\"]+'" | head -1 | tr -d "'" || true)

    if [ -z "$old_url" ]; then
        # Try another pattern
        old_url=$(grep "siteurl" "$sql_file" 2>/dev/null | grep -oP "https?://[^'\"]+" | head -1 || true)
    fi

    echo "$old_url"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

log_section "WORDPRESS RESTORE"

# List mode
if [ "$LIST_MODE" = "true" ]; then
    list_backups
    exit $?
fi

# Determine archive path
if [ -z "$ARCHIVE_PATH" ]; then
    # Interactive mode
    log_info "No archive specified - entering interactive mode"
    if ! select_backup; then
        log_fatal "No backup selected"
    fi
fi

# Validate archive exists
if [ ! -f "$ARCHIVE_PATH" ]; then
    log_fatal "Archive not found: ${ARCHIVE_PATH}"
fi

# Display restore plan
echo ""
log_info "Restore Plan:"
echo "  Archive: ${GREEN}${ARCHIVE_PATH}${NORMAL}"
echo "  Target:  ${GREEN}${directory_public}${NORMAL}"
echo "  Mode:    ${CYAN}$([ "$DB_ONLY" = "true" ] && echo "Database only" || ([ "$FILES_ONLY" = "true" ] && echo "Files only" || echo "Full restore"))${NORMAL}"
if [ -n "$NEW_URL" ]; then
    echo "  New URL: ${CYAN}${NEW_URL}${NORMAL}"
fi
if [ "$DRY_RUN" = "true" ]; then
    echo "  ${YELLOW}*** DRY RUN - No changes will be made ***${NORMAL}"
fi
echo ""

# Confirm restore
if [ "$DRY_RUN" = "false" ]; then
    printf "${YELLOW}This will overwrite your current WordPress installation!${NORMAL}\n"
    printf "Continue? (y/N): "
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log_info "Restore cancelled by user"
        exit 0
    fi
fi

log_separator

# Step 1: Verify archive
verify_archive "$ARCHIVE_PATH" || log_fatal "Archive verification failed"

# Step 2: Check archive format
check_archive_format "$ARCHIVE_PATH" "" || log_fatal "Archive format check failed"

# Step 3: Create safety backup
create_safety_backup

# Step 4: Extract archive to temp directory
log_section "EXTRACTION"

TEMP_DIR=$(mktemp -d)
chmod 700 "$TEMP_DIR"

# Cleanup trap
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

extract_archive "$ARCHIVE_PATH" "$TEMP_DIR"

# Step 5: Restore database (unless --files-only)
if [ "$FILES_ONLY" = "false" ]; then
    restore_database "${TEMP_DIR}/database.sql"
fi

# Step 6: Restore files (unless --db-only)
if [ "$DB_ONLY" = "false" ]; then
    restore_files "${TEMP_DIR}/wordpress-files.tar.gz"
fi

# Step 7: URL replacement (if requested)
if [ -n "$NEW_URL" ] && [ "$FILES_ONLY" = "false" ]; then
    # Detect old URL from backup
    old_url=$(detect_old_url "${TEMP_DIR}/database.sql")

    if [ -n "$old_url" ]; then
        log_info "Detected old URL: ${old_url}"
        replace_url "$old_url" "$NEW_URL"
    else
        log_warn "Could not detect old URL from backup"
        log_info "Using configured site_url: ${site_url}"
        replace_url "$site_url" "$NEW_URL"
    fi
fi

# Step 8: Final verification
log_section "VERIFICATION"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Would verify restore"
else
    # Check WordPress installation
    cd "$directory_public" || log_fatal "Cannot access WordPress directory"

    if [ -f "../${file_wpcli_phar}" ]; then
        log_info "Verifying WordPress installation..."

        if php "../${file_wpcli_phar}" core is-installed --quiet 2>/dev/null; then
            log_success "WordPress is properly installed"

            # Get site info
            site_name=$(php "../${file_wpcli_phar}" option get blogname --quiet 2>/dev/null || echo "Unknown")
            site_url_current=$(php "../${file_wpcli_phar}" option get siteurl --quiet 2>/dev/null || echo "Unknown")

            echo ""
            echo "${CYAN}Restored Site Info:${NORMAL}"
            echo "  Name: ${GREEN}${site_name}${NORMAL}"
            echo "  URL:  ${GREEN}${site_url_current}${NORMAL}"
        else
            log_warn "WordPress installation check returned warnings"
        fi
    else
        log_info "WP-CLI not available - skipping verification"
    fi

    cd ..
fi

log_separator

# Final summary
echo ""
if [ "$DRY_RUN" = "true" ]; then
    log_success "DRY RUN COMPLETE - No changes were made"
    echo ""
    echo "Run without --dry-run to perform actual restore."
else
    log_success "RESTORE COMPLETE!"
    echo ""
    echo "${CYAN}Next steps:${NORMAL}"
    echo "  1. Test your site in a browser"
    echo "  2. Check WordPress admin: ${site_url:-}/wp-admin/"
    echo "  3. Verify plugins and themes are working"
    if [ -n "$NEW_URL" ]; then
        echo "  4. Update any hardcoded URLs in theme files"
    fi
fi

echo ""
