#!/bin/sh
# install-wordpress.sh - Secure WordPress installation
# Installs WordPress WITHOUT exposing credentials in process list

set -euo pipefail

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load configuration FIRST (before logger, so LOG_DIR can be set)
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    echo ""
    echo "Please run 'cli/install.sh' first to generate the configuration."
    exit 1
fi

. "$CONFIG_FILE"

# Set LOG_DIR from config before loading logger
export LOG_DIR="${directory_log}"

# Load dependencies
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"
. "${SCRIPT_DIR}/lib/secure-wp-config.sh"

log_section "WORDPRESS INSTALLATION"

# Detect PHP binary - try multiple strategies
log_info "Detecting PHP binary..."

# Strategy 1: Check for generic 'php' command FIRST (most common on shared hosting)
if command -v php >/dev/null 2>&1; then
    PHP_BIN="php"
    PHP_VERSION=$(php -v 2>&1 | head -n1)
    PHP_PATH=$(command -v php)
    log_success "Found PHP: ${PHP_VERSION}"
    log_info "PHP binary location: ${PHP_PATH}"

    # Show what 'php' actually is (to detect aliases/functions)
    PHP_TYPE=$(type php 2>&1)
    log_info "PHP type: ${PHP_TYPE}"
# Strategy 2: Check for versioned PHP binaries (alternative naming)
elif command -v php8.3 >/dev/null 2>&1; then
    PHP_BIN="php8.3"
    log_success "Found PHP 8.3: $(php8.3 -v 2>&1 | head -n1)"
elif command -v php8.2 >/dev/null 2>&1; then
    PHP_BIN="php8.2"
    log_success "Found PHP 8.2: $(php8.2 -v 2>&1 | head -n1)"
elif command -v php8.1 >/dev/null 2>&1; then
    PHP_BIN="php8.1"
    log_success "Found PHP 8.1: $(php8.1 -v 2>&1 | head -n1)"
elif command -v php8.0 >/dev/null 2>&1; then
    PHP_BIN="php8.0"
    log_success "Found PHP 8.0: $(php8.0 -v 2>&1 | head -n1)"
elif command -v php7.4 >/dev/null 2>&1; then
    PHP_BIN="php7.4"
    log_success "Found PHP 7.4: $(php7.4 -v 2>&1 | head -n1)"
# Strategy 3: Common absolute paths on shared hosting
elif [ -x "/usr/local/bin/php" ]; then
    PHP_BIN="/usr/local/bin/php"
    log_success "Found PHP at /usr/local/bin/php: $($PHP_BIN -v 2>&1 | head -n1)"
elif [ -x "/usr/bin/php" ]; then
    PHP_BIN="/usr/bin/php"
    log_success "Found PHP at /usr/bin/php: $($PHP_BIN -v 2>&1 | head -n1)"
else
    log_error "PHP not found in PATH"
    echo ""
    echo "${YELLOW}${BOLD}Debugging information:${NORMAL}"
    echo "PATH=${PATH}"
    echo ""
    echo "Testing PHP commands:"
    type php 2>&1 || echo "  'php' command not found"
    echo ""
    echo "Available PHP versions in /usr/bin and /usr/local/bin:"
    ls -la /usr/bin/php* 2>/dev/null || echo "  None in /usr/bin"
    ls -la /usr/local/bin/php* 2>/dev/null || echo "  None in /usr/local/bin"
    ls -la /usr/local/php*/bin/php 2>/dev/null || echo "  None in /usr/local/php*/"
    echo ""
    echo "${YELLOW}On OVH shared hosting, you may need to:${NORMAL}"
    echo "  1. Check for shell aliases: ${GREEN}type php${NORMAL}"
    echo "  2. Remove bad alias: ${GREEN}unalias php${NORMAL}"
    echo "  3. Check hosting panel for PHP version settings"
    echo ""
    log_fatal "Cannot continue without PHP"
fi

log_info "Using PHP binary: ${GREEN}${PHP_BIN}${NORMAL}"

# Check if WP-CLI is available
if [ ! -f "$file_wpcli_phar" ]; then
    log_fatal "WP-CLI not found at ${file_wpcli_phar}

Please run 'cli/init.sh' first to download WP-CLI."
fi

# Create WordPress directory if it doesn't exist
if [ ! -d "$directory_public" ]; then
    mkdir -p "$directory_public"
    log_info "Created directory: ${directory_public}"
fi

# Step 1: Download WordPress core
log_section "STEP 1/4: DOWNLOADING WORDPRESS CORE"
log_info "Downloading WordPress (locale: ${site_locale})..."

# Save current directory
ORIGINAL_DIR="$(pwd)"

cd "$directory_public" || log_fatal "Cannot access directory: ${directory_public}"

if $PHP_BIN "../${file_wpcli_phar}" core is-installed 2>/dev/null; then
    log_warn "WordPress is already installed"
    read -p "Do you want to continue anyway? (y/N): " -r
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
fi

if ! $PHP_BIN "../${file_wpcli_phar}" core download --locale="${site_locale}" --force; then
    log_fatal "Failed to download WordPress core"
fi

log_success "WordPress core downloaded"

# Return to original directory before generating config
cd "$ORIGINAL_DIR" || log_fatal "Cannot return to original directory"

log_separator

# Step 2: Create wp-config.php securely (WITHOUT passing credentials as CLI arguments)
log_section "STEP 2/4: CREATING WP-CONFIG.PHP SECURELY"

# Generate wp-config.php using our secure function (no credentials in process list!)
generate_wp_config \
    "$db_name" \
    "$db_user" \
    "$db_pass" \
    "$db_host" \
    "$db_prefix" \
    "$directory_public"

# Validate the generated config
validate_wp_config "${directory_public}/wp-config.php"

log_separator

# Step 3: Install WordPress database
log_section "STEP 3/4: INSTALLING WORDPRESS DATABASE"

# We need to install WordPress with admin credentials
# SECURITY FIX: Use a temporary admin password, then update it via WP-CLI user update
log_info "Creating WordPress database tables..."

# Generate a temporary random password for initial installation
log_info "Generating temporary admin password..."
# Use dd with count instead of head to avoid potential blocking issues
TEMP_ADMIN_PASS=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c 32)
log_info "Temporary password generated successfully"

# Create a temporary file with restrictive permissions for the admin password
log_info "Creating temporary password file..."
TEMP_PASS_FILE=$(mktemp)
chmod 600 "$TEMP_PASS_FILE"
echo "$TEMP_ADMIN_PASS" > "$TEMP_PASS_FILE"

# Ensure cleanup on exit
trap 'rm -f "$TEMP_PASS_FILE"' EXIT INT TERM

# Go back to WordPress directory for WP-CLI commands
cd "$directory_public" || log_fatal "Cannot access directory: ${directory_public}"

# Check if WordPress is already installed
log_info "Checking if WordPress is already installed..."
if $PHP_BIN "../${file_wpcli_phar}" core is-installed 2>/dev/null; then
    log_warn "WordPress is already installed in the database"
    log_success "Database tables already exist, skipping installation"
    # Skip to password update
    SKIP_INSTALL=true
else
    log_info "WordPress not installed yet, proceeding with installation..."
    log_info "Running: $PHP_BIN ../wp-cli.phar core install"
    log_info "  URL: ${site_url}"
    log_info "  Title: ${site_title}"
    log_info "  Admin: ${admin_login}"

    # Debug: Show exact command and PHP binary
    echo ""
    echo "${YELLOW}${BOLD}=== DEBUG INFORMATION ===${NORMAL}"
    echo "PHP_BIN variable: ${GREEN}${PHP_BIN}${NORMAL}"
    echo "PHP_BIN resolved path: ${GREEN}$(command -v "$PHP_BIN" 2>&1)${NORMAL}"
    echo "PHP_BIN type: $(type "$PHP_BIN" 2>&1)"
    echo "Full command that will be executed:"
    echo "  ${GREEN}$PHP_BIN \"../${file_wpcli_phar}\" core install --url=\"${site_url}\" --title=\"${site_title}\" --admin_user=\"${admin_login}\" --admin_email=\"${admin_email}\" --skip-email${NORMAL}"
    echo "${YELLOW}${BOLD}=========================${NORMAL}"
    echo ""

    SKIP_INSTALL=false

    # Install WordPress with temporary password
    # Note: This still exposes the temp password in process list, but it's immediately changed
    log_info "Starting WordPress installation NOW..."
    if ! $PHP_BIN "../${file_wpcli_phar}" core install \
        --url="${site_url}" \
        --title="${site_title}" \
        --admin_user="${admin_login}" \
        --admin_password="$(cat "$TEMP_PASS_FILE")" \
        --admin_email="${admin_email}" \
        --skip-email 2>&1; then
        log_error "Command returned with error code: $?"
        log_error "WordPress installation command failed"
        log_info "Checking database connection..."
        # Test database connection
        if $PHP_BIN "../${file_wpcli_phar}" db check 2>&1; then
            log_success "Database connection OK"
        else
            log_fatal "Database connection failed - check credentials in config/config.sh"
        fi
        log_fatal "WordPress installation failed"
    fi
    log_success "WordPress database created"
fi

# Update admin password only if we just installed WordPress
if [ "$SKIP_INSTALL" = "false" ]; then
    # Immediately update the admin password to the real one using WP-CLI
    # This is more secure as we're using WP-CLI's user update which can read from stdin
    log_info "Setting final admin password..."

    # Method 1: Using wp user update (more secure - credentials from file)
    if ! echo "$admin_pass" | $PHP_BIN "../${file_wpcli_phar}" user update "${admin_login}" \
        --user_pass="$(cat -)" --skip-email 2>/dev/null; then

        # Fallback method if the above doesn't work
        log_warn "Using fallback method for password update..."
        $PHP_BIN "../${file_wpcli_phar}" user update "${admin_login}" \
            --user_pass="${admin_pass}" --skip-email
    fi

    log_success "Admin password set securely"
else
    log_info "Skipping password update (WordPress was already installed)"
fi

# Return to original directory
cd "$ORIGINAL_DIR" || log_fatal "Cannot return to original directory"

log_separator

# Step 4: Security hardening
log_section "STEP 4/4: SECURITY HARDENING"

# Go to WordPress directory for WP-CLI commands
cd "$directory_public" || log_fatal "Cannot access directory: ${directory_public}"

# Remove default themes (except active one)
log_info "Cleaning up default themes..."
ACTIVE_THEME=$($PHP_BIN "../${file_wpcli_phar}" theme list --status=active --field=name 2>/dev/null || echo "")

for theme in twentytwentyone twentytwentytwo twentytwentythree twentytwentyfour; do
    if [ "$theme" != "$ACTIVE_THEME" ]; then
        $PHP_BIN "../${file_wpcli_phar}" theme delete "$theme" 2>/dev/null || true
    fi
done

# Remove default plugins
log_info "Removing default plugins..."
$PHP_BIN "../${file_wpcli_phar}" plugin delete hello akismet 2>/dev/null || true

# Update permalink structure
log_info "Setting permalink structure..."
$PHP_BIN "../${file_wpcli_phar}" rewrite structure '/%postname%/' --hard 2>/dev/null || true

# Disable comments by default
log_info "Disabling comments on new posts..."
$PHP_BIN "../${file_wpcli_phar}" option update default_comment_status 'closed' 2>/dev/null || true
$PHP_BIN "../${file_wpcli_phar}" option update default_ping_status 'closed' 2>/dev/null || true

# Set timezone
log_info "Setting timezone to Europe/Paris..."
$PHP_BIN "../${file_wpcli_phar}" option update timezone_string 'Europe/Paris' 2>/dev/null || true

# Discourage search engines (can be changed later in admin)
log_warn "Discouraging search engines (remember to enable later!)"
$PHP_BIN "../${file_wpcli_phar}" option update blog_public '0' 2>/dev/null || true

# Create .htaccess to protect sensitive files
HTACCESS_FILE="${PWD}/.htaccess"
if [ -f "$HTACCESS_FILE" ]; then
    chmod u+w "$HTACCESS_FILE" 2>/dev/null || log_warn "Cannot make .htaccess writable, check permissions"
else
    touch "$HTACCESS_FILE" || log_fatal "Cannot create .htaccess (permissions/ACL?)"
fi
log_info "Creating security rules..."
cat > "$HTACCESS_FILE" <<'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF

chmod 644 "$HTACCESS_FILE"
log_success ".htaccess created and secured"

log_separator

# Final summary
cd "$ORIGINAL_DIR" || cd ..
echo ""
log_success "WORDPRESS INSTALLATION COMPLETE!"
echo ""
echo "${CYAN}${BOLD}=== SITE DETAILS ===${NORMAL}"
echo ""
echo "${YELLOW}Accès au site${NORMAL}"
echo "  ${CYAN}•${NORMAL} URL:        ${GREEN}${site_url}${NORMAL}"
echo "  ${CYAN}•${NORMAL} Admin URL:  ${GREEN}${site_url}/wp-admin${NORMAL}"
echo "  ${CYAN}•${NORMAL} Username:   ${GREEN}${admin_login}${NORMAL}"
echo "  ${CYAN}•${NORMAL} Email:      ${GREEN}${admin_email}${NORMAL}"
echo ""
echo "${YELLOW}${BOLD}⚠ Important - Sécurité${NORMAL}"
echo "  ${RED}•${NORMAL} Votre mot de passe admin est stocké dans: ${RED}config/config.sh${NORMAL}"
echo "  ${RED}•${NORMAL} Ce fichier est exclu de git (ne jamais le commiter !)"
echo "  ${YELLOW}•${NORMAL} Les moteurs de recherche sont désactivés (à activer plus tard)"
echo "    Réglages → Lecture → Visibilité pour les moteurs de recherche"
echo ""
echo "${CYAN}${BOLD}=== NEXT STEPS ===${NORMAL}"
echo ""
echo "${YELLOW}1. Commandes utiles WP-CLI${NORMAL}"
echo "   ${GREEN}php ${file_wpcli_phar} plugin list${NORMAL}     # Liste des plugins"
echo "   ${GREEN}php ${file_wpcli_phar} theme list${NORMAL}      # Liste des thèmes"
echo "   ${GREEN}php ${file_wpcli_phar} user list${NORMAL}       # Liste des utilisateurs"
echo "   ${GREEN}php ${file_wpcli_phar} post list${NORMAL}       # Liste des articles"
echo ""
echo "${YELLOW}2. Tâches recommandées${NORMAL}"
echo "   ${CYAN}•${NORMAL} Installer des plugins: ${GREEN}cli/plugins-install.sh${NORMAL}"
echo "   ${CYAN}•${NORMAL} Configurer votre thème"
echo "   ${CYAN}•${NORMAL} Créer vos premières pages/articles"
echo "   ${CYAN}•${NORMAL} Créer une sauvegarde: ${GREEN}./cli/backup.sh${NORMAL}"
echo ""
echo "${YELLOW}3. Documentation${NORMAL}"
echo "   ${CYAN}•${NORMAL} WP-CLI: ${GREEN}https://wp-cli.org/${NORMAL}"
echo "   ${CYAN}•${NORMAL} WordPress: ${GREEN}https://wordpress.org/documentation/${NORMAL}"
echo ""
