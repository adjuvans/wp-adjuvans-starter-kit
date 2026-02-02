#!/bin/sh
# adopt-site.sh - Adopt an existing WordPress site into WPASK
# Generates configuration from existing WordPress installation
# Created for WPASK v3.0

set -eu
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# =============================================================================
# SCRIPT SETUP
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Default options
AUTO_MODE="false"
WORDPRESS_PATH=""
DRY_RUN="false"
FORCE="false"

# =============================================================================
# USAGE
# =============================================================================

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [WORDPRESS_PATH]

Adopt an existing WordPress site to use WPASK tools (backup, restore, security-scan)

OPTIONS:
    -h, --help          Show this help message
    -a, --auto          Automatic mode (no prompts, detect everything)
    -n, --dry-run       Show what would be done without making changes
    -f, --force         Overwrite existing config if present

ARGUMENTS:
    WORDPRESS_PATH      Path to WordPress installation (default: ./wordpress)

REQUIREMENTS:
    - WordPress must be a standard installation:
      - wp-content/ at WordPress root
      - Standard directory structure (wp-admin/, wp-includes/, wp-content/)
      - No custom WP_CONTENT_DIR in wp-config.php
    - Local installation only (no SSH support)

EXAMPLES:
    # Interactive mode (current directory)
    $SCRIPT_NAME

    # Specify WordPress path
    $SCRIPT_NAME /var/www/html/wordpress

    # Automatic mode
    $SCRIPT_NAME --auto /var/www/html/wordpress

    # Dry run (see what would happen)
    $SCRIPT_NAME --dry-run /var/www/html/wordpress

WHAT THIS DOES:
    1. Detects WordPress configuration (database, URLs, etc.)
    2. Validates standard installation structure
    3. Generates config/config.sh for WPASK tools
    4. Verifies WPASK tools work with the site
    5. Does NOT modify your WordPress installation

AFTER ADOPTION:
    make backup         # Backup your site
    make restore        # Restore from backup
    make security-scan  # Security audit
    make update-all     # Update WordPress, plugins, themes
EOF
}

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -a|--auto)
            AUTO_MODE="true"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -f|--force)
            FORCE="true"
            shift
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
        *)
            WORDPRESS_PATH="$1"
            shift
            ;;
    esac
done

# =============================================================================
# LOAD COLORS (standalone, no config needed yet)
# =============================================================================

# Basic colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NORMAL='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NORMAL=''
fi

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

log_info() {
    echo "${CYAN}[INFO]${NORMAL} $*"
}

log_success() {
    echo "${GREEN}[✔]${NORMAL} $*"
}

log_warn() {
    echo "${YELLOW}[WARN]${NORMAL} $*"
}

log_error() {
    echo "${RED}[ERROR]${NORMAL} $*" >&2
}

log_fatal() {
    echo "${RED}${BOLD}[FATAL]${NORMAL} $*" >&2
    exit 1
}

# Ask yes/no question
ask_confirm() {
    local prompt="$1"
    local default="${2:-n}"

    if [ "$AUTO_MODE" = "true" ]; then
        [ "$default" = "y" ] && return 0 || return 1
    fi

    local yn_prompt
    if [ "$default" = "y" ]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi

    printf "%s %s " "$prompt" "$yn_prompt"
    read -r answer

    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        [Nn]|[Nn][Oo]) return 1 ;;
        "") [ "$default" = "y" ] && return 0 || return 1 ;;
        *) return 1 ;;
    esac
}

# Extract value from wp-config.php
extract_wp_config() {
    local file="$1"
    local name="$2"

    # Try define('NAME', 'value')
    local value
    value=$(grep -E "define\s*\(\s*['\"]${name}['\"]" "$file" 2>/dev/null | \
            sed -E "s/.*define\s*\(\s*['\"]${name}['\"]\s*,\s*['\"]([^'\"]*)['\"].*/\1/" | \
            head -1)

    echo "$value"
}

# Extract table prefix from wp-config.php
extract_table_prefix() {
    local file="$1"

    local prefix
    prefix=$(grep -E '^\s*\$table_prefix\s*=' "$file" 2>/dev/null | \
             sed -E "s/.*=\s*['\"]([^'\"]*)['\"].*/\1/" | \
             head -1)

    echo "$prefix"
}

# =============================================================================
# DETECTION FUNCTIONS
# =============================================================================

# Check if path is a valid WordPress installation
detect_wordpress() {
    local path="$1"

    # Check essential files
    [ -f "${path}/wp-config.php" ] || return 1
    [ -d "${path}/wp-admin" ] || return 1
    [ -d "${path}/wp-includes" ] || return 1
    [ -d "${path}/wp-content" ] || return 1

    return 0
}

# Check for standard installation (not Bedrock, not custom wp-content)
check_standard_installation() {
    local path="$1"
    local wp_config="${path}/wp-config.php"
    local issues=""

    # Check 1: wp-content at root
    if [ ! -d "${path}/wp-content" ]; then
        issues="${issues}\n  - wp-content/ directory not found at WordPress root"
    fi

    # Check 2: No custom WP_CONTENT_DIR
    if grep -qE "define\s*\(\s*['\"]WP_CONTENT_DIR['\"]" "$wp_config" 2>/dev/null; then
        local custom_dir
        custom_dir=$(extract_wp_config "$wp_config" "WP_CONTENT_DIR")
        issues="${issues}\n  - Custom WP_CONTENT_DIR defined: $custom_dir"
    fi

    # Check 3: No custom WP_CONTENT_URL
    if grep -qE "define\s*\(\s*['\"]WP_CONTENT_URL['\"]" "$wp_config" 2>/dev/null; then
        issues="${issues}\n  - Custom WP_CONTENT_URL defined"
    fi

    # Check 4: Standard wp-admin and wp-includes
    if [ ! -d "${path}/wp-admin" ] || [ ! -d "${path}/wp-includes" ]; then
        issues="${issues}\n  - Missing standard WordPress directories (wp-admin/ or wp-includes/)"
    fi

    # Check 5: Not a Bedrock installation (check for specific patterns)
    if [ -f "${path}/composer.json" ]; then
        if grep -q "roots/wordpress" "${path}/composer.json" 2>/dev/null; then
            issues="${issues}\n  - Bedrock installation detected (uses Composer for WordPress)"
        fi
    fi

    # Check 6: WordPress not in subdirectory (relative to web root)
    if grep -qE "define\s*\(\s*['\"]WP_SITEURL['\"]" "$wp_config" 2>/dev/null; then
        local siteurl
        siteurl=$(extract_wp_config "$wp_config" "WP_SITEURL")
        if echo "$siteurl" | grep -qE "/wp$|/wordpress$|/blog$"; then
            issues="${issues}\n  - WordPress may be in a subdirectory: $siteurl"
        fi
    fi

    if [ -n "$issues" ]; then
        echo "$issues"
        return 1
    fi

    return 0
}

# Extract all configuration from WordPress
extract_configuration() {
    local path="$1"
    local wp_config="${path}/wp-config.php"

    # Database settings
    DB_NAME=$(extract_wp_config "$wp_config" "DB_NAME")
    DB_USER=$(extract_wp_config "$wp_config" "DB_USER")
    DB_PASSWORD=$(extract_wp_config "$wp_config" "DB_PASSWORD")
    DB_HOST=$(extract_wp_config "$wp_config" "DB_HOST")
    DB_CHARSET=$(extract_wp_config "$wp_config" "DB_CHARSET")
    TABLE_PREFIX=$(extract_table_prefix "$wp_config")

    # Set defaults
    [ -z "$DB_HOST" ] && DB_HOST="localhost"
    [ -z "$DB_CHARSET" ] && DB_CHARSET="utf8mb4"
    [ -z "$TABLE_PREFIX" ] && TABLE_PREFIX="wp_"

    # Try to get site URL from database or wp-config
    SITE_URL=""
    if command -v php >/dev/null 2>&1 && [ -f "${PROJECT_ROOT}/wp-cli.phar" ]; then
        SITE_URL=$(cd "$path" && php "${PROJECT_ROOT}/wp-cli.phar" option get siteurl 2>/dev/null || echo "")
    fi

    if [ -z "$SITE_URL" ]; then
        SITE_URL=$(extract_wp_config "$wp_config" "WP_SITEURL")
    fi

    if [ -z "$SITE_URL" ]; then
        SITE_URL=$(extract_wp_config "$wp_config" "WP_HOME")
    fi

    # Try to get site title
    SITE_TITLE=""
    if command -v php >/dev/null 2>&1 && [ -f "${PROJECT_ROOT}/wp-cli.phar" ]; then
        SITE_TITLE=$(cd "$path" && php "${PROJECT_ROOT}/wp-cli.phar" option get blogname 2>/dev/null || echo "")
    fi
    [ -z "$SITE_TITLE" ] && SITE_TITLE="Adopted WordPress Site"

    # Get active theme
    ACTIVE_THEME=""
    if command -v php >/dev/null 2>&1 && [ -f "${PROJECT_ROOT}/wp-cli.phar" ]; then
        ACTIVE_THEME=$(cd "$path" && php "${PROJECT_ROOT}/wp-cli.phar" theme list --status=active --field=name 2>/dev/null | head -1 || echo "")
    fi
    [ -z "$ACTIVE_THEME" ] && ACTIVE_THEME="twentytwentyfour"

    # Get locale
    SITE_LOCALE=""
    if command -v php >/dev/null 2>&1 && [ -f "${PROJECT_ROOT}/wp-cli.phar" ]; then
        SITE_LOCALE=$(cd "$path" && php "${PROJECT_ROOT}/wp-cli.phar" option get WPLANG 2>/dev/null || echo "")
    fi
    [ -z "$SITE_LOCALE" ] && SITE_LOCALE="en_US"

    return 0
}

# Test database connection
test_database_connection() {
    local db_host="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"

    if command -v mysql >/dev/null 2>&1; then
        if MYSQL_PWD="$db_pass" mysql -h "$db_host" -u "$db_user" -e "USE $db_name" 2>/dev/null; then
            return 0
        fi
    fi

    # Try with PHP/mysqli if mysql client not available
    if command -v php >/dev/null 2>&1; then
        local result
        result=$(php -r "
            \$c = @new mysqli('$db_host', '$db_user', '$db_pass', '$db_name');
            echo \$c->connect_error ? 'error' : 'ok';
        " 2>/dev/null || echo "error")

        [ "$result" = "ok" ] && return 0
    fi

    return 1
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

# Generate config file
generate_config() {
    local output_file="$1"
    local wp_path="$2"

    # Generate project slug from site title
    local project_slug
    project_slug=$(echo "$SITE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
    [ -z "$project_slug" ] && project_slug="adopted-site"

    cat > "$output_file" << EOF
#!/bin/sh
# config.sh - Generated by WPASK adopt-site.sh
# Source: ${wp_path}
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
#
# SECURITY WARNING:
# This file contains sensitive data (database credentials).
# NEVER commit this file to version control!

# ============================================================================
# PROJECT INFORMATION
# ============================================================================

project_name="${SITE_TITLE}"
project_slug="${project_slug}"

# ============================================================================
# DIRECTORY CONFIGURATION
# ============================================================================

directory_public="${wp_path}"
directory_log="${PROJECT_ROOT}/logs"
directory_backup="${PROJECT_ROOT}/save"

# ============================================================================
# WP-CLI CONFIGURATION
# ============================================================================

file_wpcli_phar="${PROJECT_ROOT}/wp-cli.phar"
file_wpcli_completion="${PROJECT_ROOT}/wp-completion.bash"
file_wpcli_config="${PROJECT_ROOT}/wp-cli.yml"

# ============================================================================
# WORDPRESS CONFIGURATION
# ============================================================================

site_locale="${SITE_LOCALE}"
site_title="${SITE_TITLE}"
site_url="${SITE_URL}"

# ============================================================================
# THEME CONFIGURATION
# ============================================================================

theme_name="${ACTIVE_THEME}"
theme_child_name="${ACTIVE_THEME}"

# ============================================================================
# DATABASE CONFIGURATION
# ============================================================================

db_host="${DB_HOST}"
db_name="${DB_NAME}"
db_user="${DB_USER}"
db_pass="${DB_PASSWORD}"
db_prefix="${TABLE_PREFIX}"
db_charset="${DB_CHARSET}"

# ============================================================================
# WORDPRESS ADMIN ACCOUNT
# ============================================================================
# Note: These are not used for adopted sites (admin already exists)

admin_login="admin"
admin_pass="CHANGE_ME_NOT_USED"
admin_email="admin@example.com"

# ============================================================================
# BACKUP CONFIGURATION
# ============================================================================

USE_GPG_ENCRYPTION="false"
GPG_RECIPIENT=""
BACKUP_RETENTION="7"
EOF

    chmod 600 "$output_file"
}

# Verify WPASK tools work
verify_tools() {
    local config_file="$1"

    log_info "Verifying WPASK tools..."

    # Source the generated config
    . "$config_file"

    # Check WP-CLI
    if [ -f "$file_wpcli_phar" ]; then
        if cd "$directory_public" && php "$file_wpcli_phar" core is-installed --quiet 2>/dev/null; then
            log_success "WP-CLI can access WordPress"
        else
            log_warn "WP-CLI cannot verify WordPress installation"
        fi
        cd "$PROJECT_ROOT"
    else
        log_warn "WP-CLI not installed - run 'make init' to install"
    fi

    # Check backup would work (dry-run concept)
    if [ -d "$directory_public" ] && [ -r "${directory_public}/wp-config.php" ]; then
        log_success "Backup script can access WordPress files"
    else
        log_warn "Backup script may have permission issues"
    fi

    return 0
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

echo ""
echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${NORMAL}"
echo "${CYAN}║              WPASK SITE ADOPTION                             ║${NORMAL}"
echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${NORMAL}"
echo ""

# Determine WordPress path
if [ -z "$WORDPRESS_PATH" ]; then
    WORDPRESS_PATH="${PROJECT_ROOT}/wordpress"
fi

# Convert to absolute path
if [ ! "${WORDPRESS_PATH#/}" = "$WORDPRESS_PATH" ]; then
    # Already absolute
    :
else
    WORDPRESS_PATH="$(cd "$(dirname "$WORDPRESS_PATH")" 2>/dev/null && pwd)/$(basename "$WORDPRESS_PATH")"
fi

log_info "WordPress path: ${WORDPRESS_PATH}"

# Step 1: Detect WordPress
echo ""
log_info "Detecting WordPress installation..."

if ! detect_wordpress "$WORDPRESS_PATH"; then
    log_fatal "No valid WordPress installation found at: ${WORDPRESS_PATH}

Please verify:
  - Path contains wp-config.php
  - Path contains wp-admin/, wp-includes/, wp-content/
  - You have read permissions

Usage: $SCRIPT_NAME [path-to-wordpress]"
fi

log_success "WordPress installation detected"

# Step 2: Check for standard installation
echo ""
log_info "Checking installation type..."

issues=$(check_standard_installation "$WORDPRESS_PATH" 2>&1) || true

if [ -n "$issues" ]; then
    echo ""
    log_error "Non-standard WordPress installation detected!"
    echo ""
    echo "${YELLOW}Issues found:${NORMAL}"
    printf "%b\n" "$issues"
    echo ""
    echo "${RED}WPASK only supports standard WordPress installations.${NORMAL}"
    echo ""
    echo "Standard installation requirements:"
    echo "  - wp-content/ at WordPress root"
    echo "  - No custom WP_CONTENT_DIR or WP_CONTENT_URL"
    echo "  - Not a Bedrock or Composer-based installation"
    echo ""
    echo "For non-standard installations, manual configuration may be required."
    exit 1
fi

log_success "Standard WordPress installation confirmed"

# Step 3: Extract configuration
echo ""
log_info "Extracting configuration from wp-config.php..."

extract_configuration "$WORDPRESS_PATH"

# Display detected configuration
echo ""
echo "${BLUE}Detected Configuration:${NORMAL}"
echo "  Site Title:    ${GREEN}${SITE_TITLE}${NORMAL}"
echo "  Site URL:      ${GREEN}${SITE_URL:-'(not detected)'}${NORMAL}"
echo "  Database:      ${GREEN}${DB_NAME}${NORMAL} @ ${DB_HOST}"
echo "  DB User:       ${GREEN}${DB_USER}${NORMAL}"
echo "  Table Prefix:  ${GREEN}${TABLE_PREFIX}${NORMAL}"
echo "  Active Theme:  ${GREEN}${ACTIVE_THEME}${NORMAL}"
echo "  Locale:        ${GREEN}${SITE_LOCALE}${NORMAL}"
echo ""

# Step 4: Test database connection
log_info "Testing database connection..."

if test_database_connection "$DB_HOST" "$DB_NAME" "$DB_USER" "$DB_PASSWORD"; then
    log_success "Database connection successful"
else
    log_warn "Could not verify database connection (may still work)"
fi

# Step 5: Check for existing config
CONFIG_FILE="${PROJECT_ROOT}/config/config.sh"

if [ -f "$CONFIG_FILE" ] && [ "$FORCE" != "true" ]; then
    echo ""
    log_warn "Configuration file already exists: ${CONFIG_FILE}"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would ask to overwrite"
    elif ! ask_confirm "Overwrite existing configuration?"; then
        log_info "Adoption cancelled. Use --force to overwrite."
        exit 0
    fi
fi

# Step 6: Generate configuration
echo ""

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Would generate configuration file:"
    echo ""
    echo "  ${CONFIG_FILE}"
    echo ""
    log_info "[DRY-RUN] Configuration preview:"
    echo "  project_name=\"${SITE_TITLE}\""
    echo "  directory_public=\"${WORDPRESS_PATH}\""
    echo "  db_name=\"${DB_NAME}\""
    echo "  db_user=\"${DB_USER}\""
    echo "  site_url=\"${SITE_URL}\""
    echo ""
else
    log_info "Generating configuration..."

    # Ensure config directory exists
    mkdir -p "$(dirname "$CONFIG_FILE")"

    generate_config "$CONFIG_FILE" "$WORDPRESS_PATH"

    log_success "Configuration generated: ${CONFIG_FILE}"

    # Ensure directories exist
    mkdir -p "${PROJECT_ROOT}/logs" "${PROJECT_ROOT}/save"
    log_success "Created logs/ and save/ directories"
fi

# Step 7: Verify tools
if [ "$DRY_RUN" != "true" ]; then
    echo ""
    verify_tools "$CONFIG_FILE"
fi

# Final summary
echo ""
echo "${GREEN}════════════════════════════════════════════════════════════════${NORMAL}"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    log_success "DRY RUN COMPLETE - No changes were made"
    echo ""
    echo "Run without --dry-run to adopt the site."
else
    log_success "SITE ADOPTED SUCCESSFULLY!"
    echo ""
    echo "${CYAN}Your WordPress site is now integrated with WPASK.${NORMAL}"
    echo ""
    echo "Available commands:"
    echo "  ${GREEN}make backup${NORMAL}         Create a backup"
    echo "  ${GREEN}make restore${NORMAL}        Restore from backup"
    echo "  ${GREEN}make security-scan${NORMAL}  Run security audit"
    echo "  ${GREEN}make update-all${NORMAL}     Update WordPress, plugins, themes"
    echo "  ${GREEN}make status${NORMAL}         Check project status"
    echo ""
    echo "${YELLOW}Note:${NORMAL} Your WordPress installation was NOT modified."
    echo "WPASK tools work alongside your existing setup."
fi

echo ""
