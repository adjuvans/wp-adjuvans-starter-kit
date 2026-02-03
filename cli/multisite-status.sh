#!/bin/sh
# multisite-status.sh - Check and manage WordPress Multisite installation
#
# This script provides diagnostics for multisite installations and allows
# re-running specific setup steps.

set -eu
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load colors early for help display
. "${SCRIPT_DIR}/lib/colors.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

show_help() {
    cat <<EOF
${BOLD}multisite-status.sh${NORMAL} - Check and manage WordPress Multisite

${YELLOW}USAGE${NORMAL}
    ./cli/multisite-status.sh [COMMAND] [OPTIONS]

${YELLOW}COMMANDS${NORMAL}
    status              Show multisite status and configuration (default)
    sites               List all sites in the network
    plugins             List network-activated plugins
    install-plugin      Install WP Remote Users Sync plugin
    fix-htaccess        Regenerate .htaccess rules
    fix-config          Check and fix wp-config.php multisite constants

${YELLOW}OPTIONS${NORMAL}
    -h, --help          Show this help message
    -j, --json          Output in JSON format (for status command)
    -q, --quiet         Minimal output

${YELLOW}EXAMPLES${NORMAL}
    # Show full multisite status
    ./cli/multisite-status.sh

    # List all network sites
    ./cli/multisite-status.sh sites

    # Install cross-domain sync plugin
    ./cli/multisite-status.sh install-plugin

    # Regenerate .htaccess
    ./cli/multisite-status.sh fix-htaccess

    # JSON output for automation
    ./cli/multisite-status.sh status --json

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

# Get config value safely
get_wp_config() {
    local key="$1"
    local default="${2:-}"
    local value
    value=$($PHP_BIN "$WPCLI" config get "$key" 2>/dev/null) || value="$default"
    echo "$value"
}

# Check if multisite is enabled
check_multisite_enabled() {
    local multisite
    multisite=$(get_wp_config "MULTISITE" "false")
    [ "$multisite" = "1" ] || [ "$multisite" = "true" ]
}

# Get multisite mode
get_multisite_mode() {
    local subdomain
    subdomain=$(get_wp_config "SUBDOMAIN_INSTALL" "false")
    if [ "$subdomain" = "1" ] || [ "$subdomain" = "true" ]; then
        echo "subdomain"
    else
        echo "subdirectory"
    fi
}

# Check SSO configuration
check_sso_config() {
    local cookie_domain
    cookie_domain=$(get_wp_config "COOKIE_DOMAIN" "")
    if [ -n "$cookie_domain" ]; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

# Show multisite status
show_status() {
    local json_output="$1"

    # Check WordPress
    if ! $PHP_BIN "$WPCLI" core is-installed 2>/dev/null; then
        if [ "$json_output" = "true" ]; then
            echo '{"error": "WordPress is not installed"}'
        else
            log_fatal "WordPress is not installed"
        fi
        exit 1
    fi

    # Check if multisite
    if ! check_multisite_enabled; then
        if [ "$json_output" = "true" ]; then
            echo '{"multisite": false, "message": "WordPress is not configured as multisite"}'
        else
            echo ""
            log_warn "WordPress is NOT configured as Multisite"
            echo ""
            echo "To convert to multisite, run:"
            echo "  ${GREEN}./cli/install-multisite.sh${NORMAL}"
            echo ""
        fi
        exit 0
    fi

    # Gather information
    local mode domain path site_count user_count
    mode=$(get_multisite_mode)
    domain=$(get_wp_config "DOMAIN_CURRENT_SITE" "")
    path=$(get_wp_config "PATH_CURRENT_SITE" "/")
    cookie_domain=$(get_wp_config "COOKIE_DOMAIN" "")
    sso_status=$(check_sso_config)

    # Count sites and users
    site_count=$($PHP_BIN "$WPCLI" site list --format=count 2>/dev/null) || site_count="?"
    user_count=$($PHP_BIN "$WPCLI" user list --format=count 2>/dev/null) || user_count="?"

    # Get WordPress and network info
    wp_version=$($PHP_BIN "$WPCLI" core version 2>/dev/null) || wp_version="?"
    network_title=$($PHP_BIN "$WPCLI" network meta get 1 site_name 2>/dev/null) || network_title="?"
    admin_email=$($PHP_BIN "$WPCLI" network meta get 1 admin_email 2>/dev/null) || admin_email="?"

    # Check for WP Remote Users Sync plugin
    wprus_installed="false"
    wprus_active="false"
    if $PHP_BIN "$WPCLI" plugin is-installed wp-remote-users-sync 2>/dev/null; then
        wprus_installed="true"
        if $PHP_BIN "$WPCLI" plugin is-active wp-remote-users-sync --network 2>/dev/null; then
            wprus_active="true"
        fi
    fi

    if [ "$json_output" = "true" ]; then
        # JSON output
        cat <<EOF
{
  "multisite": true,
  "mode": "${mode}",
  "domain": "${domain}",
  "path": "${path}",
  "network_title": "${network_title}",
  "admin_email": "${admin_email}",
  "wordpress_version": "${wp_version}",
  "site_count": ${site_count},
  "user_count": ${user_count},
  "sso": {
    "enabled": $([ "$sso_status" = "enabled" ] && echo "true" || echo "false"),
    "cookie_domain": "${cookie_domain}"
  },
  "plugins": {
    "wp_remote_users_sync": {
      "installed": ${wprus_installed},
      "network_active": ${wprus_active}
    }
  }
}
EOF
    else
        # Human-readable output
        clear
        cat <<'EOF'

    ███╗   ███╗██╗   ██╗██╗  ████████╗██╗███████╗██╗████████╗███████╗
    ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║╚══██╔══╝██╔════╝
    ██╔████╔██║██║   ██║██║     ██║   ██║███████╗██║   ██║   █████╗
    ██║╚██╔╝██║██║   ██║██║     ██║   ██║╚════██║██║   ██║   ██╔══╝
    ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║███████║██║   ██║   ███████╗
    ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝   ╚══════╝

    ███████╗████████╗ █████╗ ████████╗██╗   ██╗███████╗
    ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██╔════╝
    ███████╗   ██║   ███████║   ██║   ██║   ██║███████╗
    ╚════██║   ██║   ██╔══██║   ██║   ██║   ██║╚════██║
    ███████║   ██║   ██║  ██║   ██║   ╚██████╔╝███████║
    ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝

EOF

        log_section "NETWORK INFORMATION"
        echo ""
        echo "${CYAN}Network Title:${NORMAL}    ${GREEN}${network_title}${NORMAL}"
        echo "${CYAN}Admin Email:${NORMAL}      ${GREEN}${admin_email}${NORMAL}"
        echo "${CYAN}WordPress:${NORMAL}        ${GREEN}${wp_version}${NORMAL}"
        echo ""

        log_section "MULTISITE CONFIGURATION"
        echo ""
        echo "${CYAN}Multisite Mode:${NORMAL}   ${GREEN}${mode}${NORMAL}"
        echo "${CYAN}Domain:${NORMAL}           ${GREEN}${domain}${NORMAL}"
        echo "${CYAN}Path:${NORMAL}             ${GREEN}${path}${NORMAL}"
        echo ""

        if [ "$mode" = "subdomain" ]; then
            echo "${YELLOW}Site URLs:${NORMAL}        ${GREEN}sitename.${domain}${NORMAL}"
        else
            echo "${YELLOW}Site URLs:${NORMAL}        ${GREEN}${domain}${path}sitename/${NORMAL}"
        fi
        echo ""

        log_section "NETWORK STATISTICS"
        echo ""
        echo "${CYAN}Total Sites:${NORMAL}      ${GREEN}${site_count}${NORMAL}"
        echo "${CYAN}Total Users:${NORMAL}      ${GREEN}${user_count}${NORMAL}"
        echo ""

        log_section "SSO / SHARED LOGIN"
        echo ""
        if [ "$sso_status" = "enabled" ]; then
            echo "${CYAN}Cookie Sharing:${NORMAL}   ${GREEN}Enabled${NORMAL}"
            echo "${CYAN}Cookie Domain:${NORMAL}    ${GREEN}${cookie_domain}${NORMAL}"
            echo ""
            echo "${YELLOW}Note:${NORMAL} SSO only works for subdomains of ${GREEN}${cookie_domain}${NORMAL}"
        else
            echo "${CYAN}Cookie Sharing:${NORMAL}   ${YELLOW}Disabled${NORMAL}"
            echo ""
            echo "Users must log in separately to each site."
        fi
        echo ""

        log_section "CROSS-DOMAIN SYNC PLUGIN"
        echo ""
        if [ "$wprus_installed" = "true" ]; then
            echo "${CYAN}WP Remote Users Sync:${NORMAL} ${GREEN}Installed${NORMAL}"
            if [ "$wprus_active" = "true" ]; then
                echo "${CYAN}Network Active:${NORMAL}       ${GREEN}Yes${NORMAL}"
                echo ""
                echo "Configure at: ${GREEN}${domain}${path}wp-admin/network/settings.php?page=wprus${NORMAL}"
            else
                echo "${CYAN}Network Active:${NORMAL}       ${YELLOW}No${NORMAL}"
                echo ""
                echo "To activate: ${GREEN}wp plugin activate wp-remote-users-sync --network${NORMAL}"
            fi
        else
            echo "${CYAN}WP Remote Users Sync:${NORMAL} ${YELLOW}Not installed${NORMAL}"
            echo ""
            echo "This plugin is needed for cross-domain user synchronization."
            echo "Install with: ${GREEN}./cli/multisite-status.sh install-plugin${NORMAL}"
        fi
        echo ""

        log_section "USEFUL COMMANDS"
        echo ""
        echo "  ${GREEN}./cli/multisite-status.sh sites${NORMAL}          # List all sites"
        echo "  ${GREEN}./cli/multisite-status.sh plugins${NORMAL}        # List network plugins"
        echo "  ${GREEN}./cli/multisite-status.sh install-plugin${NORMAL} # Install sync plugin"
        echo "  ${GREEN}./cli/multisite-status.sh fix-htaccess${NORMAL}   # Regenerate .htaccess"
        echo ""
        echo "  ${GREEN}wp site create --slug=newsite${NORMAL}            # Create new site"
        echo "  ${GREEN}wp site list${NORMAL}                             # WP-CLI site list"
        echo ""
    fi
}

# List all sites
list_sites() {
    log_section "NETWORK SITES"
    echo ""
    $PHP_BIN "$WPCLI" site list --fields=blog_id,url,registered,last_updated
    echo ""
}

# List network plugins
list_plugins() {
    log_section "NETWORK-ACTIVATED PLUGINS"
    echo ""
    $PHP_BIN "$WPCLI" plugin list --status=active-network --fields=name,version,update
    echo ""

    log_section "ALL PLUGINS"
    echo ""
    $PHP_BIN "$WPCLI" plugin list --fields=name,status,version,update
    echo ""
}

# Install WP Remote Users Sync
install_sync_plugin() {
    log_section "INSTALLING WP REMOTE USERS SYNC"
    echo ""

    # Check if already installed
    if $PHP_BIN "$WPCLI" plugin is-installed wp-remote-users-sync 2>/dev/null; then
        log_info "Plugin is already installed"

        # Check if active
        if $PHP_BIN "$WPCLI" plugin is-active wp-remote-users-sync --network 2>/dev/null; then
            log_success "Plugin is already network-activated"
        else
            log_info "Activating plugin on network..."
            if $PHP_BIN "$WPCLI" plugin activate wp-remote-users-sync --network 2>&1; then
                log_success "Plugin network-activated successfully"
            else
                log_error "Failed to activate plugin"
                exit 1
            fi
        fi
    else
        log_info "Installing WP Remote Users Sync..."
        if $PHP_BIN "$WPCLI" plugin install wp-remote-users-sync --activate-network 2>&1; then
            log_success "Plugin installed and network-activated"
        else
            log_error "Failed to install plugin"
            echo ""
            echo "You can install manually from:"
            echo "  ${GREEN}https://wordpress.org/plugins/wp-remote-users-sync/${NORMAL}"
            exit 1
        fi
    fi

    echo ""
    echo "${YELLOW}Next Steps:${NORMAL}"
    echo "  1. Go to Network Admin > Settings > WP Remote Users Sync"
    echo "  2. Configure remote sites to sync with"
    echo "  3. Set up the same plugin on other WordPress installations"
    echo ""
    echo "Documentation: ${GREEN}https://github.com/froger-me/wp-remote-users-sync${NORMAL}"
    echo ""
}

# Regenerate .htaccess
fix_htaccess() {
    log_section "REGENERATING .HTACCESS"
    echo ""

    if ! check_multisite_enabled; then
        log_fatal "WordPress is not configured as multisite"
    fi

    local mode htaccess_file
    mode=$(get_multisite_mode)
    htaccess_file="${WP_DIR}/.htaccess"

    log_info "Detected mode: ${mode}"
    log_info "Target file: ${htaccess_file}"

    # Backup existing
    if [ -f "$htaccess_file" ]; then
        backup_dir="${PROJECT_ROOT}/${directory_save:-save}"
        mkdir -p "$backup_dir"
        backup_file="${backup_dir}/htaccess.backup.$(date +%Y%m%d-%H%M%S).bak"
        cp "$htaccess_file" "$backup_file"
        log_info "Backup created: ${backup_file}"
    fi

    # Generate new rules
    if [ "$mode" = "subdomain" ]; then
        htaccess_rules="# BEGIN WordPress Multisite (Subdomain)
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\\.php\$ - [L]

# add a trailing slash to /wp-admin
RewriteRule ^wp-admin\$ wp-admin/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^(wp-(content|admin|includes).*) \$1 [L]
RewriteRule ^(.*\\.php)\$ \$1 [L]
RewriteRule . index.php [L]
# END WordPress Multisite"
    else
        htaccess_rules="# BEGIN WordPress Multisite (Subdirectory)
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\\.php\$ - [L]

# add a trailing slash to /wp-admin
RewriteRule ^([_0-9a-zA-Z-]+/)?wp-admin\$ \$1wp-admin/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(wp-(content|admin|includes).*) \$2 [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(.*\\.php)\$ \$2 [L]
RewriteRule . index.php [L]
# END WordPress Multisite"
    fi

    echo "$htaccess_rules" > "$htaccess_file"
    chmod 644 "$htaccess_file"

    log_success ".htaccess regenerated successfully"
    echo ""
    echo "New .htaccess content:"
    echo "${CYAN}----------------------------------------${NORMAL}"
    cat "$htaccess_file"
    echo "${CYAN}----------------------------------------${NORMAL}"
    echo ""
}

# Check and fix wp-config.php
fix_config() {
    log_section "CHECKING WP-CONFIG.PHP"
    echo ""

    local wp_config="${WP_DIR}/wp-config.php"

    if [ ! -f "$wp_config" ]; then
        log_fatal "wp-config.php not found: ${wp_config}"
    fi

    # Check for multisite constants
    local issues=0

    echo "${CYAN}Checking multisite constants...${NORMAL}"
    echo ""

    # MULTISITE
    if grep -q "define.*MULTISITE" "$wp_config"; then
        local multisite_val
        multisite_val=$(get_wp_config "MULTISITE" "")
        echo "  ${GREEN}✓${NORMAL} MULTISITE = ${multisite_val}"
    else
        echo "  ${RED}✗${NORMAL} MULTISITE not defined"
        issues=$((issues + 1))
    fi

    # SUBDOMAIN_INSTALL
    if grep -q "define.*SUBDOMAIN_INSTALL" "$wp_config"; then
        local subdomain_val
        subdomain_val=$(get_wp_config "SUBDOMAIN_INSTALL" "")
        echo "  ${GREEN}✓${NORMAL} SUBDOMAIN_INSTALL = ${subdomain_val}"
    else
        echo "  ${RED}✗${NORMAL} SUBDOMAIN_INSTALL not defined"
        issues=$((issues + 1))
    fi

    # DOMAIN_CURRENT_SITE
    if grep -q "define.*DOMAIN_CURRENT_SITE" "$wp_config"; then
        local domain_val
        domain_val=$(get_wp_config "DOMAIN_CURRENT_SITE" "")
        echo "  ${GREEN}✓${NORMAL} DOMAIN_CURRENT_SITE = ${domain_val}"
    else
        echo "  ${RED}✗${NORMAL} DOMAIN_CURRENT_SITE not defined"
        issues=$((issues + 1))
    fi

    # PATH_CURRENT_SITE
    if grep -q "define.*PATH_CURRENT_SITE" "$wp_config"; then
        local path_val
        path_val=$(get_wp_config "PATH_CURRENT_SITE" "")
        echo "  ${GREEN}✓${NORMAL} PATH_CURRENT_SITE = ${path_val}"
    else
        echo "  ${RED}✗${NORMAL} PATH_CURRENT_SITE not defined"
        issues=$((issues + 1))
    fi

    # SITE_ID_CURRENT_SITE
    if grep -q "define.*SITE_ID_CURRENT_SITE" "$wp_config"; then
        echo "  ${GREEN}✓${NORMAL} SITE_ID_CURRENT_SITE defined"
    else
        echo "  ${YELLOW}!${NORMAL} SITE_ID_CURRENT_SITE not defined (optional)"
    fi

    # BLOG_ID_CURRENT_SITE
    if grep -q "define.*BLOG_ID_CURRENT_SITE" "$wp_config"; then
        echo "  ${GREEN}✓${NORMAL} BLOG_ID_CURRENT_SITE defined"
    else
        echo "  ${YELLOW}!${NORMAL} BLOG_ID_CURRENT_SITE not defined (optional)"
    fi

    echo ""

    # SSO constants
    echo "${CYAN}Checking SSO constants...${NORMAL}"
    echo ""

    if grep -q "define.*COOKIE_DOMAIN" "$wp_config"; then
        local cookie_val
        cookie_val=$(get_wp_config "COOKIE_DOMAIN" "")
        echo "  ${GREEN}✓${NORMAL} COOKIE_DOMAIN = ${cookie_val}"
    else
        echo "  ${YELLOW}○${NORMAL} COOKIE_DOMAIN not defined (SSO disabled)"
    fi

    if grep -q "define.*COOKIEPATH" "$wp_config"; then
        echo "  ${GREEN}✓${NORMAL} COOKIEPATH defined"
    else
        echo "  ${YELLOW}○${NORMAL} COOKIEPATH not defined"
    fi

    echo ""

    if [ "$issues" -gt 0 ]; then
        log_warn "Found ${issues} missing required constant(s)"
        echo ""
        echo "To fix, run the multisite installer again:"
        echo "  ${GREEN}./cli/install-multisite.sh${NORMAL}"
    else
        log_success "All required multisite constants are present"
    fi

    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

# Defaults
COMMAND="status"
JSON_OUTPUT="false"
QUIET="false"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -j|--json)
            JSON_OUTPUT="true"
            shift
            ;;
        -q|--quiet)
            QUIET="true"
            shift
            ;;
        status|sites|plugins|install-plugin|fix-htaccess|fix-config)
            COMMAND="$1"
            shift
            ;;
        *)
            echo "${RED}ERROR:${NORMAL} Unknown option or command: $1"
            show_help
            exit 1
            ;;
    esac
done

# Load configuration
CONFIG_FILE="${PROJECT_ROOT}/config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    if [ "$JSON_OUTPUT" = "true" ]; then
        echo '{"error": "Configuration file not found"}'
    else
        echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
        echo "Please run 'cli/install.sh' or 'cli/adopt-site.sh' first."
    fi
    exit 1
fi
. "$CONFIG_FILE"

# Set LOG_DIR and load logger
export LOG_DIR="${directory_log:-./logs}"
. "${SCRIPT_DIR}/lib/logger.sh"

# Detect PHP
PHP_BIN=$(detect_php)
if [ -z "$PHP_BIN" ]; then
    if [ "$JSON_OUTPUT" = "true" ]; then
        echo '{"error": "PHP not found"}'
    else
        log_fatal "PHP not found. Please install PHP 7.4 or later."
    fi
    exit 1
fi

# Check WP-CLI
WPCLI="${PROJECT_ROOT}/${file_wpcli_phar}"
if [ ! -f "$WPCLI" ]; then
    if [ "$JSON_OUTPUT" = "true" ]; then
        echo '{"error": "WP-CLI not found"}'
    else
        log_fatal "WP-CLI not found. Please run 'cli/init.sh' first."
    fi
    exit 1
fi

# Check WordPress directory
WP_DIR="${PROJECT_ROOT}/${directory_public}"
if [ ! -d "$WP_DIR" ]; then
    if [ "$JSON_OUTPUT" = "true" ]; then
        echo '{"error": "WordPress directory not found"}'
    else
        log_fatal "WordPress directory not found: ${WP_DIR}"
    fi
    exit 1
fi

# Change to WordPress directory
cd "$WP_DIR" || exit 1

# Execute command
case "$COMMAND" in
    status)
        show_status "$JSON_OUTPUT"
        ;;
    sites)
        list_sites
        ;;
    plugins)
        list_plugins
        ;;
    install-plugin)
        install_sync_plugin
        ;;
    fix-htaccess)
        fix_htaccess
        ;;
    fix-config)
        fix_config
        ;;
esac
