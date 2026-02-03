#!/bin/sh
# install-multisite.sh - Convert WordPress to Multisite network
# Requires: WordPress 6.0+, WP-CLI, existing WordPress installation

set -eu
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load configuration
CONFIG_FILE="${PROJECT_ROOT}/config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    echo "Please run 'cli/install.sh' first."
    exit 1
fi
. "$CONFIG_FILE"

# Set LOG_DIR
export LOG_DIR="${directory_log:-./logs}"

# Load dependencies
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"
. "${SCRIPT_DIR}/lib/validators.sh"

# Minimum WordPress version for multisite
MIN_WP_VERSION="6.0"

# ============================================================================
# FUNCTIONS
# ============================================================================

show_help() {
    cat <<EOF
${BOLD}install-multisite.sh${NORMAL} - Convert WordPress to Multisite network

${YELLOW}USAGE${NORMAL}
    ./cli/install-multisite.sh [OPTIONS]

${YELLOW}OPTIONS${NORMAL}
    -h, --help              Show this help message
    -m, --mode MODE         Multisite mode: 'subdomain' or 'subdirectory'
    -t, --title TITLE       Network title (default: site title)
    -n, --dry-run           Show what would be done without making changes
    --skip-checks           Skip compatibility checks (not recommended)

${YELLOW}MULTISITE MODES${NORMAL}
    ${GREEN}subdirectory${NORMAL} (Recommended for shared hosting)
        Sites are accessed via: example.com/site1/, example.com/site2/
        - Simpler DNS configuration
        - Works on all hosting types
        - No SSL wildcard certificate needed

    ${GREEN}subdomain${NORMAL}
        Sites are accessed via: site1.example.com, site2.example.com
        - Requires DNS wildcard record (*.example.com) OR manual DNS entries
        - May require wildcard SSL certificate
        - More professional-looking URLs

${YELLOW}REQUIREMENTS${NORMAL}
    - WordPress ${MIN_WP_VERSION}+ already installed
    - WordPress at domain root (not in /blog/ or subdirectory)
    - Admin access to wp-config.php
    - Empty .htaccess or permission to modify it

${YELLOW}EXAMPLES${NORMAL}
    # Interactive mode (asks for mode)
    ./cli/install-multisite.sh

    # Subdirectory mode (recommended)
    ./cli/install-multisite.sh --mode=subdirectory

    # Subdomain mode
    ./cli/install-multisite.sh --mode=subdomain

    # Dry run to see what would happen
    ./cli/install-multisite.sh --mode=subdirectory --dry-run

EOF
}

# Compare semantic versions (returns 0 if $1 >= $2)
version_gte() {
    # $1 = version to check, $2 = minimum version
    v1_major=$(echo "$1" | cut -d. -f1)
    v1_minor=$(echo "$1" | cut -d. -f2 | cut -d- -f1)
    v2_major=$(echo "$2" | cut -d. -f1)
    v2_minor=$(echo "$2" | cut -d. -f2)

    if [ "$v1_major" -gt "$v2_major" ]; then
        return 0
    elif [ "$v1_major" -eq "$v2_major" ] && [ "$v1_minor" -ge "$v2_minor" ]; then
        return 0
    else
        return 1
    fi
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
    elif [ -x "/usr/local/bin/php" ]; then
        echo "/usr/local/bin/php"
    elif [ -x "/usr/bin/php" ]; then
        echo "/usr/bin/php"
    else
        echo ""
    fi
}

# Check if WordPress is installed at root
check_wordpress_root() {
    local site_url="$1"

    # Extract path from URL
    url_path=$(echo "$site_url" | sed 's|^https\?://[^/]*||' | sed 's|/$||')

    if [ -n "$url_path" ] && [ "$url_path" != "/" ]; then
        log_error "WordPress is not at domain root"
        log_error "Current URL: ${site_url}"
        log_error "Detected path: ${url_path}"
        echo ""
        echo "${YELLOW}Multisite requires WordPress to be installed at the domain root.${NORMAL}"
        echo "For example: ${GREEN}https://example.com/${NORMAL}"
        echo "Not: ${RED}https://example.com${url_path}/${NORMAL}"
        echo ""
        echo "Options:"
        echo "  1. Reinstall WordPress at domain root"
        echo "  2. Configure your domain to point to the WordPress directory"
        return 1
    fi

    return 0
}

# Check if multisite is already enabled
check_multisite_enabled() {
    local wp_config="$1"

    if grep -q "MULTISITE.*true" "$wp_config" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Add multisite constants to wp-config.php
add_multisite_constants() {
    local wp_config="$1"
    local mode="$2"
    local dry_run="$3"

    log_info "Adding multisite constants to wp-config.php..."

    # Create backup
    if [ "$dry_run" = "false" ]; then
        cp "$wp_config" "${wp_config}.pre-multisite.bak"
        log_info "Backup created: ${wp_config}.pre-multisite.bak"
    fi

    # Constants to add before "/* That's all, stop editing! */" or "require_once ABSPATH"
    multisite_constants="
/* Multisite - Added by WPASK */
define( 'WP_ALLOW_MULTISITE', true );
"

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY-RUN] Would add to wp-config.php:"
        echo "$multisite_constants"
        return 0
    fi

    # Find the line to insert before
    if grep -q "That's all, stop editing" "$wp_config"; then
        insert_before="That's all, stop editing"
    elif grep -q "require_once.*ABSPATH" "$wp_config"; then
        insert_before="require_once.*ABSPATH"
    else
        log_error "Cannot find insertion point in wp-config.php"
        return 1
    fi

    # Create temp file with constants
    temp_file=$(mktemp)

    # Insert constants before the marker
    awk -v constants="$multisite_constants" -v pattern="$insert_before" '
    $0 ~ pattern && !inserted {
        print constants
        inserted = 1
    }
    { print }
    ' "$wp_config" > "$temp_file"

    # Make wp-config.php writable before replacing (it may have 0400 permissions)
    chmod u+w "$wp_config" 2>/dev/null || true
    mv -f "$temp_file" "$wp_config"
    chmod 640 "$wp_config"

    log_success "Multisite constants added to wp-config.php"
}

# Update wp-config.php with network configuration
update_wp_config_network() {
    local wp_config="$1"
    local mode="$2"
    local domain="$3"
    local dry_run="$4"

    log_info "Updating wp-config.php with network configuration..."

    # Network configuration constants
    if [ "$mode" = "subdomain" ]; then
        subdomain_install="true"
    else
        subdomain_install="false"
    fi

    network_constants="
/* Multisite Network Configuration - Added by WPASK */
define( 'MULTISITE', true );
define( 'SUBDOMAIN_INSTALL', ${subdomain_install} );
define( 'DOMAIN_CURRENT_SITE', '${domain}' );
define( 'PATH_CURRENT_SITE', '/' );
define( 'SITE_ID_CURRENT_SITE', 1 );
define( 'BLOG_ID_CURRENT_SITE', 1 );
"

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY-RUN] Would update wp-config.php with:"
        echo "$network_constants"
        return 0
    fi

    # Make wp-config.php writable before modifying (it may have 0400 permissions)
    chmod u+w "$wp_config" 2>/dev/null || true

    # Remove WP_ALLOW_MULTISITE (no longer needed after network install)
    sed -i.bak '/WP_ALLOW_MULTISITE/d' "$wp_config" 2>/dev/null || \
        sed -i '' '/WP_ALLOW_MULTISITE/d' "$wp_config"

    # Remove old comment
    sed -i.bak '/Multisite - Added by WPASK/d' "$wp_config" 2>/dev/null || \
        sed -i '' '/Multisite - Added by WPASK/d' "$wp_config"

    # Find insertion point
    if grep -q "That's all, stop editing" "$wp_config"; then
        insert_before="That's all, stop editing"
    elif grep -q "require_once.*ABSPATH" "$wp_config"; then
        insert_before="require_once.*ABSPATH"
    else
        log_error "Cannot find insertion point in wp-config.php"
        return 1
    fi

    # Insert network constants
    temp_file=$(mktemp)
    awk -v constants="$network_constants" -v pattern="$insert_before" '
    $0 ~ pattern && !inserted {
        print constants
        inserted = 1
    }
    { print }
    ' "$wp_config" > "$temp_file"

    mv -f "$temp_file" "$wp_config"
    chmod 640 "$wp_config"

    # Cleanup backup files
    rm -f "${wp_config}.bak"

    log_success "Network configuration added to wp-config.php"
}

# Generate multisite .htaccess rules
generate_htaccess() {
    local htaccess_file="$1"
    local mode="$2"
    local dry_run="$3"

    log_info "Generating .htaccess rules for multisite..."

    if [ "$mode" = "subdomain" ]; then
        htaccess_rules='# BEGIN WordPress Multisite
# Using subdomain network type

RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]

# Add a trailing slash to /wp-admin
RewriteRule ^wp-admin$ wp-admin/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^(wp-(content|admin|includes).*) $1 [L]
RewriteRule ^(.*\.php)$ $1 [L]
RewriteRule . index.php [L]

# END WordPress Multisite'
    else
        htaccess_rules='# BEGIN WordPress Multisite
# Using subdirectory network type

RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]

# Add a trailing slash to /wp-admin
RewriteRule ^([_0-9a-zA-Z-]+/)?wp-admin$ $1wp-admin/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(wp-(content|admin|includes).*) $2 [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(.*\.php)$ $2 [L]
RewriteRule . index.php [L]

# END WordPress Multisite'
    fi

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY-RUN] Would write to .htaccess:"
        echo "$htaccess_rules"
        return 0
    fi

    # Backup existing .htaccess
    if [ -f "$htaccess_file" ]; then
        cp "$htaccess_file" "${htaccess_file}.pre-multisite.bak"
        log_info "Backup created: ${htaccess_file}.pre-multisite.bak"
    fi

    echo "$htaccess_rules" > "$htaccess_file"
    chmod 644 "$htaccess_file"

    log_success ".htaccess updated for multisite"
}

# ============================================================================
# MAIN
# ============================================================================

# Defaults
MULTISITE_MODE=""
NETWORK_TITLE=""
DRY_RUN="false"
SKIP_CHECKS="false"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--mode)
            MULTISITE_MODE="$2"
            shift 2
            ;;
        --mode=*)
            MULTISITE_MODE="${1#*=}"
            shift
            ;;
        -t|--title)
            NETWORK_TITLE="$2"
            shift 2
            ;;
        --title=*)
            NETWORK_TITLE="${1#*=}"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        --skip-checks)
            SKIP_CHECKS="true"
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

    ██╗    ██╗██████╗     ███╗   ███╗██╗   ██╗██╗  ████████╗██╗███████╗██╗████████╗███████╗
    ██║    ██║██╔══██╗    ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║╚══██╔══╝██╔════╝
    ██║ █╗ ██║██████╔╝    ██╔████╔██║██║   ██║██║     ██║   ██║███████╗██║   ██║   █████╗
    ██║███╗██║██╔═══╝     ██║╚██╔╝██║██║   ██║██║     ██║   ██║╚════██║██║   ██║   ██╔══╝
    ╚███╔███╔╝██║         ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║███████║██║   ██║   ███████╗
     ╚══╝╚══╝ ╚═╝         ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝   ╚══════╝

    WordPress Multisite Installation
    https://github.com/adjuvans/wp-adjuvans-starter-kit

EOF

if [ "$DRY_RUN" = "true" ]; then
    echo "${YELLOW}${BOLD}=== DRY-RUN MODE ===${NORMAL}"
    echo "${YELLOW}No changes will be made to your WordPress installation.${NORMAL}"
    echo ""
fi

log_section "CHECKING PREREQUISITES"

# Detect PHP
PHP_BIN=$(detect_php)
if [ -z "$PHP_BIN" ]; then
    log_fatal "PHP not found. Please install PHP 7.4 or later."
fi
log_success "PHP found: $($PHP_BIN -v 2>&1 | head -n1)"

# Check WP-CLI
if [ ! -f "${PROJECT_ROOT}/${file_wpcli_phar}" ]; then
    log_fatal "WP-CLI not found. Please run 'cli/init.sh' first."
fi
log_success "WP-CLI found"

# Check WordPress directory
WP_DIR="${PROJECT_ROOT}/${directory_public}"
if [ ! -d "$WP_DIR" ]; then
    log_fatal "WordPress directory not found: ${WP_DIR}"
fi

WP_CONFIG="${WP_DIR}/wp-config.php"
if [ ! -f "$WP_CONFIG" ]; then
    log_fatal "wp-config.php not found. Is WordPress installed?"
fi
log_success "WordPress found at: ${WP_DIR}"

# Change to WordPress directory
cd "$WP_DIR" || log_fatal "Cannot access WordPress directory"

# Check if WordPress is installed
if ! $PHP_BIN "${PROJECT_ROOT}/${file_wpcli_phar}" core is-installed 2>/dev/null; then
    log_fatal "WordPress is not installed. Please run 'cli/install-wordpress.sh' first."
fi
log_success "WordPress is installed"

# Check WordPress version
if [ "$SKIP_CHECKS" = "false" ]; then
    WP_VERSION=$($PHP_BIN "${PROJECT_ROOT}/${file_wpcli_phar}" core version 2>/dev/null)
    log_info "WordPress version: ${WP_VERSION}"

    if ! version_gte "$WP_VERSION" "$MIN_WP_VERSION"; then
        log_error "WordPress ${MIN_WP_VERSION}+ required for multisite"
        log_error "Current version: ${WP_VERSION}"
        log_info "Please update WordPress: make update-wp"
        exit 1
    fi
    log_success "WordPress version OK (>= ${MIN_WP_VERSION})"
fi

# Check WordPress is at root
if [ "$SKIP_CHECKS" = "false" ]; then
    if ! check_wordpress_root "$site_url"; then
        exit 1
    fi
    log_success "WordPress is at domain root"
fi

# Check if multisite is already enabled
if check_multisite_enabled "$WP_CONFIG"; then
    log_warn "Multisite is already enabled!"

    # Check if network is installed
    if $PHP_BIN "${PROJECT_ROOT}/${file_wpcli_phar}" network list 2>/dev/null | grep -q "^1"; then
        log_success "Multisite network is already configured"
        echo ""
        echo "Your multisite network is ready. Manage it at:"
        echo "  ${GREEN}${site_url}/wp-admin/network/${NORMAL}"
        exit 0
    else
        log_warn "Multisite is enabled but network is not installed"
        log_info "Continuing with network installation..."
    fi
fi

log_separator

# Select multisite mode
log_section "MULTISITE MODE SELECTION"

if [ -z "$MULTISITE_MODE" ]; then
    echo ""
    echo "${BOLD}Choose your multisite mode:${NORMAL}"
    echo ""
    echo "${GREEN}1) Subdirectory${NORMAL} ${CYAN}(Recommended for shared hosting)${NORMAL}"
    echo "   Sites: example.com/site1/, example.com/site2/"
    echo "   ${CYAN}+${NORMAL} Works on all hosting types"
    echo "   ${CYAN}+${NORMAL} Simple DNS configuration"
    echo "   ${CYAN}+${NORMAL} No wildcard SSL needed"
    echo ""
    echo "${GREEN}2) Subdomain${NORMAL}"
    echo "   Sites: site1.example.com, site2.example.com"
    echo "   ${YELLOW}!${NORMAL} Requires DNS wildcard (*.example.com) OR manual DNS entries"
    echo "   ${YELLOW}!${NORMAL} May require wildcard SSL certificate"
    echo "   ${CYAN}+${NORMAL} Cleaner URLs"
    echo ""

    while true; do
        printf "${YELLOW}Select mode (1 or 2): ${NORMAL}"
        read -r mode_choice

        case "$mode_choice" in
            1|subdirectory|sub-directory)
                MULTISITE_MODE="subdirectory"
                break
                ;;
            2|subdomain|sub-domain)
                MULTISITE_MODE="subdomain"
                break
                ;;
            *)
                log_error "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
fi

# Validate mode
case "$MULTISITE_MODE" in
    subdirectory|subdirectories|sub-directory)
        MULTISITE_MODE="subdirectory"
        ;;
    subdomain|subdomains|sub-domain)
        MULTISITE_MODE="subdomain"
        ;;
    *)
        log_fatal "Invalid multisite mode: ${MULTISITE_MODE}. Use 'subdomain' or 'subdirectory'."
        ;;
esac

log_success "Selected mode: ${MULTISITE_MODE}"

# Subdomain mode warnings
if [ "$MULTISITE_MODE" = "subdomain" ]; then
    echo ""
    log_section "SUBDOMAIN MODE REQUIREMENTS"
    echo ""
    echo "${YELLOW}${BOLD}Important: DNS Configuration${NORMAL}"
    echo ""
    echo "For subdomain multisite, you have two options:"
    echo ""
    echo "${GREEN}Option A: DNS Wildcard Record${NORMAL}"
    echo "  Add a wildcard DNS record pointing to your server:"
    echo "  ${CYAN}*.example.com -> YOUR_SERVER_IP${NORMAL}"
    echo "  This allows automatic subdomain creation."
    echo ""
    echo "${GREEN}Option B: Manual DNS Entries${NORMAL}"
    echo "  Create individual DNS records for each site:"
    echo "  ${CYAN}site1.example.com -> YOUR_SERVER_IP${NORMAL}"
    echo "  ${CYAN}site2.example.com -> YOUR_SERVER_IP${NORMAL}"
    echo "  You must add a DNS record before creating each site."
    echo ""
    echo "${YELLOW}${BOLD}SSL Certificate${NORMAL}"
    echo "  For HTTPS, you may need:"
    echo "  - A wildcard SSL certificate (*.example.com), OR"
    echo "  - Individual certificates for each subdomain"
    echo "  - Let's Encrypt can issue wildcard certificates with DNS validation"
    echo ""

    printf "${YELLOW}Do you understand these requirements and want to continue? (y/N): ${NORMAL}"
    read -r confirm_subdomain

    if [ "$confirm_subdomain" != "y" ] && [ "$confirm_subdomain" != "Y" ]; then
        log_info "Installation cancelled. Consider using subdirectory mode instead."
        exit 0
    fi
fi

log_separator

# Network title
if [ -z "$NETWORK_TITLE" ]; then
    NETWORK_TITLE="${site_title:-WordPress Network}"
fi
log_info "Network title: ${NETWORK_TITLE}"

# Extract domain from URL
DOMAIN=$(echo "$site_url" | sed 's|^https\?://||' | sed 's|/.*||')
log_info "Domain: ${DOMAIN}"

log_separator

# Summary before installation
log_section "INSTALLATION SUMMARY"
echo ""
echo "${CYAN}WordPress:${NORMAL}      ${GREEN}${WP_DIR}${NORMAL}"
echo "${CYAN}Site URL:${NORMAL}       ${GREEN}${site_url}${NORMAL}"
echo "${CYAN}Network Title:${NORMAL}  ${GREEN}${NETWORK_TITLE}${NORMAL}"
echo "${CYAN}Multisite Mode:${NORMAL} ${GREEN}${MULTISITE_MODE}${NORMAL}"
echo "${CYAN}Domain:${NORMAL}         ${GREEN}${DOMAIN}${NORMAL}"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo "${YELLOW}[DRY-RUN] The following changes would be made:${NORMAL}"
    echo "  1. Add WP_ALLOW_MULTISITE to wp-config.php"
    echo "  2. Run 'wp core multisite-install'"
    echo "  3. Update wp-config.php with network configuration"
    echo "  4. Update .htaccess with multisite rules"
    echo ""
fi

if [ "$DRY_RUN" = "false" ]; then
    printf "${YELLOW}${BOLD}Proceed with multisite installation? (y/N): ${NORMAL}"
    read -r confirm_install

    if [ "$confirm_install" != "y" ] && [ "$confirm_install" != "Y" ]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
fi

log_separator

# Step 1: Add WP_ALLOW_MULTISITE
log_section "STEP 1/4: ENABLING MULTISITE"

if ! check_multisite_enabled "$WP_CONFIG"; then
    add_multisite_constants "$WP_CONFIG" "$MULTISITE_MODE" "$DRY_RUN"
fi

log_separator

# Step 2: Install network
log_section "STEP 2/4: INSTALLING NETWORK"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Would run: wp core multisite-install"
    log_info "  --title=\"${NETWORK_TITLE}\""
    if [ "$MULTISITE_MODE" = "subdomain" ]; then
        log_info "  --subdomains"
    fi
else
    log_info "Running multisite installation..."

    if [ "$MULTISITE_MODE" = "subdomain" ]; then
        SUBDOMAIN_FLAG="--subdomains"
    else
        SUBDOMAIN_FLAG=""
    fi

    # shellcheck disable=SC2086
    if ! $PHP_BIN "${PROJECT_ROOT}/${file_wpcli_phar}" core multisite-install \
        --title="$NETWORK_TITLE" \
        $SUBDOMAIN_FLAG \
        --skip-email 2>&1; then
        log_error "Network installation failed"
        log_info "Restoring wp-config.php backup..."
        if [ -f "${WP_CONFIG}.pre-multisite.bak" ]; then
            cp "${WP_CONFIG}.pre-multisite.bak" "$WP_CONFIG"
            log_success "Backup restored"
        fi
        exit 1
    fi

    log_success "Network installed successfully"
fi

log_separator

# Step 3: Update wp-config.php
log_section "STEP 3/4: UPDATING WP-CONFIG.PHP"

update_wp_config_network "$WP_CONFIG" "$MULTISITE_MODE" "$DOMAIN" "$DRY_RUN"

log_separator

# Step 4: Update .htaccess
log_section "STEP 4/4: UPDATING .HTACCESS"

HTACCESS_FILE="${WP_DIR}/.htaccess"
generate_htaccess "$HTACCESS_FILE" "$MULTISITE_MODE" "$DRY_RUN"

log_separator

# Final summary
if [ "$DRY_RUN" = "true" ]; then
    echo ""
    log_success "DRY-RUN COMPLETE"
    echo ""
    echo "To perform the actual installation, run without --dry-run:"
    echo "  ${GREEN}./cli/install-multisite.sh --mode=${MULTISITE_MODE}${NORMAL}"
else
    echo ""
    log_success "MULTISITE INSTALLATION COMPLETE!"
    echo ""
    echo "${CYAN}${BOLD}=== NETWORK DETAILS ===${NORMAL}"
    echo ""
    echo "${YELLOW}Network Admin${NORMAL}"
    echo "  ${CYAN}•${NORMAL} Network Admin:  ${GREEN}${site_url}/wp-admin/network/${NORMAL}"
    echo "  ${CYAN}•${NORMAL} Add New Site:   ${GREEN}${site_url}/wp-admin/network/site-new.php${NORMAL}"
    echo ""
    echo "${YELLOW}Multisite Mode: ${GREEN}${MULTISITE_MODE}${NORMAL}"
    if [ "$MULTISITE_MODE" = "subdomain" ]; then
        echo "  ${CYAN}•${NORMAL} New sites will be: ${GREEN}sitename.${DOMAIN}${NORMAL}"
        echo "  ${CYAN}•${NORMAL} Remember to configure DNS for each new site"
    else
        echo "  ${CYAN}•${NORMAL} New sites will be: ${GREEN}${site_url}/sitename/${NORMAL}"
    fi
    echo ""
    echo "${YELLOW}${BOLD}Next Steps${NORMAL}"
    echo "  1. Visit the Network Admin dashboard"
    echo "  2. Create your first subsite"
    echo "  3. Install network-enabled themes and plugins"
    echo ""
    echo "${YELLOW}${BOLD}Backup Files${NORMAL}"
    echo "  ${CYAN}•${NORMAL} wp-config.php backup: ${GREEN}${WP_CONFIG}.pre-multisite.bak${NORMAL}"
    echo "  ${CYAN}•${NORMAL} .htaccess backup:     ${GREEN}${HTACCESS_FILE}.pre-multisite.bak${NORMAL}"
    echo ""
    echo "${YELLOW}Useful Commands${NORMAL}"
    echo "  ${GREEN}wp site list${NORMAL}              # List all sites"
    echo "  ${GREEN}wp site create --slug=site1${NORMAL} # Create a new site"
    echo "  ${GREEN}wp network meta list${NORMAL}      # Network settings"
    echo ""
fi
