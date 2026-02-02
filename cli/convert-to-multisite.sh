#!/bin/sh
# convert-to-multisite.sh - Convert existing WordPress site to Multisite
# Wrapper around install-multisite.sh with additional checks for existing content
#
# This script is specifically designed for sites that already have content
# (posts, pages, users, etc.) and need to be converted to a Multisite network.

set -eu
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load configuration
CONFIG_FILE="${PROJECT_ROOT}/config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    echo "Please run 'cli/install.sh' or 'cli/adopt-site.sh' first."
    exit 1
fi
. "$CONFIG_FILE"

# Set LOG_DIR
export LOG_DIR="${directory_log:-./logs}"

# Load dependencies
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

show_help() {
    cat <<EOF
${BOLD}convert-to-multisite.sh${NORMAL} - Convert existing WordPress to Multisite

${YELLOW}DESCRIPTION${NORMAL}
    This script converts an existing WordPress site with content into a
    Multisite network. Your existing content (posts, pages, users, media)
    will become the main site of the network.

${YELLOW}USAGE${NORMAL}
    ./cli/convert-to-multisite.sh [OPTIONS]

${YELLOW}OPTIONS${NORMAL}
    -h, --help              Show this help message
    -m, --mode MODE         Multisite mode: 'subdomain' or 'subdirectory'
    -n, --dry-run           Show what would be done without making changes
    --force                 Skip content check warning

${YELLOW}WHAT HAPPENS DURING CONVERSION${NORMAL}
    1. Your WordPress installation is validated
    2. A backup is recommended before proceeding
    3. Multisite is enabled in wp-config.php
    4. Network tables are created in the database
    5. .htaccess rules are updated
    6. Your existing site becomes the main site (site ID 1)

${YELLOW}AFTER CONVERSION${NORMAL}
    - All your existing content remains on the main site
    - You can create new sites in the network
    - Network-wide plugins and themes can be installed
    - Super Admin dashboard available at /wp-admin/network/

${YELLOW}EXAMPLES${NORMAL}
    # Interactive conversion
    ./cli/convert-to-multisite.sh

    # Convert with subdirectory mode
    ./cli/convert-to-multisite.sh --mode=subdirectory

    # Dry run to preview changes
    ./cli/convert-to-multisite.sh --dry-run

For more details on multisite modes, run:
    ./cli/install-multisite.sh --help

EOF
}

# Detect PHP binary
detect_php() {
    if command -v php >/dev/null 2>&1; then
        echo "php"
    elif command -v php8.3 >/dev/null 2>&1; then
        echo "php8.3"
    elif command -v php8.2 >/dev/null 2>&1; then
        echo "php8.2"
    elif command -v php8.1 >/dev/null 2>&1; then
        echo "php8.1"
    elif command -v php8.0 >/dev/null 2>&1; then
        echo "php8.0"
    elif command -v php7.4 >/dev/null 2>&1; then
        echo "php7.4"
    else
        echo ""
    fi
}

# Check site content
check_site_content() {
    local php_bin="$1"
    local wpcli="$2"

    post_count=$($php_bin "$wpcli" post list --post_type=post --format=count 2>/dev/null || echo "0")
    page_count=$($php_bin "$wpcli" post list --post_type=page --format=count 2>/dev/null || echo "0")
    user_count=$($php_bin "$wpcli" user list --format=count 2>/dev/null || echo "0")
    media_count=$($php_bin "$wpcli" post list --post_type=attachment --format=count 2>/dev/null || echo "0")

    echo "posts:$post_count,pages:$page_count,users:$user_count,media:$media_count"
}

# ============================================================================
# MAIN
# ============================================================================

# Defaults
MODE=""
DRY_RUN="false"
FORCE="false"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        --mode=*)
            MODE="${1#*=}"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Header
clear
cat <<'EOF'

     ██████╗ ██████╗ ███╗   ██╗██╗   ██╗███████╗██████╗ ████████╗
    ██╔════╝██╔═══██╗████╗  ██║██║   ██║██╔════╝██╔══██╗╚══██╔══╝
    ██║     ██║   ██║██╔██╗ ██║██║   ██║█████╗  ██████╔╝   ██║
    ██║     ██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██╔══██╗   ██║
    ╚██████╗╚██████╔╝██║ ╚████║ ╚████╔╝ ███████╗██║  ██║   ██║
     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝

         ████████╗ ██████╗
         ╚══██╔══╝██╔═══██╗
            ██║   ██║   ██║
            ██║   ██║   ██║
            ██║   ╚██████╔╝
            ╚═╝    ╚═════╝

    ███╗   ███╗██╗   ██╗██╗  ████████╗██╗███████╗██╗████████╗███████╗
    ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║╚══██╔══╝██╔════╝
    ██╔████╔██║██║   ██║██║     ██║   ██║███████╗██║   ██║   █████╗
    ██║╚██╔╝██║██║   ██║██║     ██║   ██║╚════██║██║   ██║   ██╔══╝
    ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║███████║██║   ██║   ███████╗
    ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝   ╚══════╝

    Convert Existing WordPress to Multisite Network
    https://github.com/adjuvans/wp-adjuvans-starter-kit

EOF

log_section "ANALYZING EXISTING SITE"

# Detect PHP
PHP_BIN=$(detect_php)
if [ -z "$PHP_BIN" ]; then
    log_fatal "PHP not found. Please install PHP 7.4 or later."
fi

# Check WP-CLI
WPCLI="${PROJECT_ROOT}/${file_wpcli_phar}"
if [ ! -f "$WPCLI" ]; then
    log_fatal "WP-CLI not found. Please run 'cli/init.sh' first."
fi

# Check WordPress directory
WP_DIR="${PROJECT_ROOT}/${directory_public}"
if [ ! -d "$WP_DIR" ]; then
    log_fatal "WordPress directory not found: ${WP_DIR}"
fi

# Change to WordPress directory
cd "$WP_DIR" || log_fatal "Cannot access WordPress directory"

# Check if WordPress is installed
if ! $PHP_BIN "$WPCLI" core is-installed 2>/dev/null; then
    log_fatal "WordPress is not installed."
fi
log_success "WordPress installation detected"

# Check existing content
log_info "Analyzing site content..."
CONTENT_INFO=$(check_site_content "$PHP_BIN" "$WPCLI")

# Parse content counts
POSTS=$(echo "$CONTENT_INFO" | sed 's/.*posts:\([0-9]*\).*/\1/')
PAGES=$(echo "$CONTENT_INFO" | sed 's/.*pages:\([0-9]*\).*/\1/')
USERS=$(echo "$CONTENT_INFO" | sed 's/.*users:\([0-9]*\).*/\1/')
MEDIA=$(echo "$CONTENT_INFO" | sed 's/.*media:\([0-9]*\).*/\1/')

echo ""
echo "${CYAN}${BOLD}=== EXISTING SITE CONTENT ===${NORMAL}"
echo ""
echo "  ${CYAN}•${NORMAL} Posts:  ${GREEN}${POSTS}${NORMAL}"
echo "  ${CYAN}•${NORMAL} Pages:  ${GREEN}${PAGES}${NORMAL}"
echo "  ${CYAN}•${NORMAL} Users:  ${GREEN}${USERS}${NORMAL}"
echo "  ${CYAN}•${NORMAL} Media:  ${GREEN}${MEDIA}${NORMAL}"
echo ""

# Calculate total content
TOTAL_CONTENT=$((POSTS + PAGES + MEDIA))

if [ "$TOTAL_CONTENT" -gt 0 ] && [ "$FORCE" = "false" ]; then
    log_warn "Your site has existing content!"
    echo ""
    echo "${YELLOW}${BOLD}Important:${NORMAL} Converting to Multisite will affect your site."
    echo ""
    echo "What will happen:"
    echo "  ${GREEN}✓${NORMAL} Your content will be preserved on the main site"
    echo "  ${GREEN}✓${NORMAL} Your users will remain with their roles"
    echo "  ${GREEN}✓${NORMAL} Your media files will stay in place"
    echo "  ${YELLOW}!${NORMAL} URL structure may change slightly"
    echo "  ${YELLOW}!${NORMAL} Some plugins may need network activation"
    echo ""
    echo "${RED}${BOLD}Recommendation:${NORMAL} Create a backup before proceeding!"
    echo "  ${GREEN}./cli/backup.sh${NORMAL}"
    echo ""

    printf "${YELLOW}Have you created a backup or want to proceed anyway? (y/N): ${NORMAL}"
    read -r backup_confirm

    if [ "$backup_confirm" != "y" ] && [ "$backup_confirm" != "Y" ]; then
        echo ""
        log_info "Please run './cli/backup.sh' first, then retry."
        exit 0
    fi
fi

log_separator

# Build arguments for install-multisite.sh
MULTISITE_ARGS=""

if [ -n "$MODE" ]; then
    MULTISITE_ARGS="$MULTISITE_ARGS --mode=$MODE"
fi

if [ "$DRY_RUN" = "true" ]; then
    MULTISITE_ARGS="$MULTISITE_ARGS --dry-run"
fi

# Call install-multisite.sh
log_section "STARTING MULTISITE CONVERSION"
echo ""
log_info "Launching multisite installer..."
echo ""

# shellcheck disable=SC2086
exec "${SCRIPT_DIR}/install-multisite.sh" $MULTISITE_ARGS
