#!/bin/sh
# backup.sh - Create secure backups of WordPress installation and database
# Supports optional GPG encryption for sensitive data

set -euo pipefail

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load configuration FIRST (before logger, so LOG_DIR can be set)
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    exit 1
fi

. "$CONFIG_FILE"

# Set LOG_DIR from config before loading logger
export LOG_DIR="${directory_log}"

# Load dependencies
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"

# Check if GPG encryption should be used
USE_ENCRYPTION="${USE_GPG_ENCRYPTION:-false}"

log_section "WORDPRESS BACKUP"

# Generate backup filename with correct date format (FIXED BUG)
BACKUP_DATE="$(date +%Y-%m-%d-%H%M%S)"  # Fixed: was +%Y-%m-%y (wrong year format)
BACKUP_NAME="${BACKUP_DATE}_${project_slug:-wordpress}"

log_info "Creating backup: ${BACKUP_NAME}"
log_separator

# Create temporary directory for backup files
TEMP_DIR=$(mktemp -d)
chmod 700 "$TEMP_DIR"

# Ensure cleanup on exit
trap "rm -rf $TEMP_DIR" EXIT INT TERM

# Step 1: Export database
log_section "DATABASE EXPORT"

if [ ! -f "$file_wpcli_phar" ]; then
    log_error "WP-CLI not found at ${file_wpcli_phar}"
    log_info "Attempting direct mysqldump..."

    if command -v mysqldump >/dev/null 2>&1; then
        MYSQL_PWD="$db_pass" mysqldump -h "$db_host" -u "$db_user" "$db_name" > "${TEMP_DIR}/database.sql"
    else
        log_fatal "Neither WP-CLI nor mysqldump available for database backup"
    fi
else
    cd "$directory_public" || log_fatal "Cannot access directory: ${directory_public}"
    if ! php "../${file_wpcli_phar}" db export "${TEMP_DIR}/database.sql" --quiet; then
        log_fatal "Database export failed"
    fi
    cd ..
fi

log_success "Database exported: $(du -h "${TEMP_DIR}/database.sql" | cut -f1)"
log_separator

# Step 2: Archive WordPress files
log_section "FILES ARCHIVE"

log_info "Compressing WordPress files..."
if ! tar -czf "${TEMP_DIR}/wordpress-files.tar.gz" -C "${directory_public}" . 2>/dev/null; then
    log_fatal "File archiving failed"
fi

log_success "Files archived: $(du -h "${TEMP_DIR}/wordpress-files.tar.gz" | cut -f1)"
log_separator

# Step 3: Create final backup (with optional encryption)
log_section "FINAL BACKUP"

# Ensure backup directory exists
mkdir -p "$directory_backup"

if [ "$USE_ENCRYPTION" = "true" ] && command -v gpg >/dev/null 2>&1; then
    # Encrypted backup
    log_info "Creating encrypted backup with GPG..."

    # Check if GPG recipient is configured
    if [ -z "${GPG_RECIPIENT:-}" ]; then
        log_warn "GPG_RECIPIENT not set in config, using symmetric encryption"

        # Symmetric encryption (password-based)
        if ! tar -czf - -C "$TEMP_DIR" database.sql wordpress-files.tar.gz | \
            gpg --symmetric --cipher-algo AES256 --batch --yes \
            -o "${directory_backup}/${BACKUP_NAME}.tar.gz.gpg"; then
            log_fatal "GPG encryption failed"
        fi

        log_success "Encrypted backup created: ${BACKUP_NAME}.tar.gz.gpg"
        log_warn "Backup is encrypted with symmetric key - you'll need the passphrase to restore"

    else
        # Public key encryption
        if ! tar -czf - -C "$TEMP_DIR" database.sql wordpress-files.tar.gz | \
            gpg --encrypt --recipient "$GPG_RECIPIENT" --batch --yes \
            -o "${directory_backup}/${BACKUP_NAME}.tar.gz.gpg"; then
            log_fatal "GPG encryption failed"
        fi

        log_success "Encrypted backup created: ${BACKUP_NAME}.tar.gz.gpg"
        log_info "Encrypted for recipient: ${GPG_RECIPIENT}"
    fi

else
    # Plain backup (no encryption)
    if [ "$USE_ENCRYPTION" = "true" ]; then
        log_warn "GPG encryption requested but GPG not available - creating plain backup"
    fi

    log_info "Creating unencrypted backup..."

    # Create tar.gz with both database and files
    if ! tar -czf "${directory_backup}/${BACKUP_NAME}.tar.gz" \
        -C "$TEMP_DIR" database.sql wordpress-files.tar.gz; then
        log_fatal "Backup creation failed"
    fi

    log_success "Backup created: ${BACKUP_NAME}.tar.gz"
    log_warn "Backup is NOT encrypted - database credentials are in plain text!"
fi

BACKUP_SIZE=$(du -h "${directory_backup}/${BACKUP_NAME}"* | cut -f1)
log_success "Final backup size: ${BACKUP_SIZE}"

log_separator

# Step 4: Backup rotation (keep last N backups)
KEEP_BACKUPS="${BACKUP_RETENTION:-7}"  # Default: keep 7 backups

log_section "BACKUP ROTATION"
log_info "Keeping last ${KEEP_BACKUPS} backups..."

# Count existing backups
BACKUP_COUNT=$(find "$directory_backup" -name "*.tar.gz*" -type f | wc -l | tr -d ' ')

if [ "$BACKUP_COUNT" -gt "$KEEP_BACKUPS" ]; then
    log_info "Found ${BACKUP_COUNT} backups, removing old ones..."

    # Remove old backups (keep last N)
    find "$directory_backup" -name "*.tar.gz*" -type f -printf '%T+ %p\n' | \
        sort -r | tail -n +$((KEEP_BACKUPS + 1)) | cut -d' ' -f2- | \
        while read -r old_backup; do
            rm -f "$old_backup"
            log_info "Removed old backup: $(basename "$old_backup")"
        done
else
    log_info "Backup count (${BACKUP_COUNT}) within retention limit"
fi

log_separator

# Final summary
echo ""
log_success "BACKUP COMPLETE!"
echo ""
echo "${CYAN}Backup Details:${NORMAL}"
echo "  File: ${GREEN}${directory_backup}/${BACKUP_NAME}$([ "$USE_ENCRYPTION" = "true" ] && echo ".tar.gz.gpg" || echo ".tar.gz")${NORMAL}"
echo "  Size: ${GREEN}${BACKUP_SIZE}${NORMAL}"
echo "  Date: ${GREEN}${BACKUP_DATE}${NORMAL}"
echo ""

if [ "$USE_ENCRYPTION" = "true" ] && command -v gpg >/dev/null 2>&1; then
    echo "${YELLOW}To restore encrypted backup:${NORMAL}"
    if [ -n "${GPG_RECIPIENT:-}" ]; then
        echo "  gpg --decrypt ${BACKUP_NAME}.tar.gz.gpg | tar xzf -"
    else
        echo "  gpg --decrypt ${BACKUP_NAME}.tar.gz.gpg | tar xzf -"
        echo "  (You will be prompted for the passphrase)"
    fi
else
    echo "${YELLOW}To restore backup:${NORMAL}"
    echo "  cd ${directory_backup}"
    echo "  tar xzf ${BACKUP_NAME}.tar.gz"
    echo "  # Then use cli/restore.sh script"
fi

echo ""
