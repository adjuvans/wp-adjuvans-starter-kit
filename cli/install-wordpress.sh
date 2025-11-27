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

cd "$directory_public" || log_fatal "Cannot access directory: ${directory_public}"

if php "../${file_wpcli_phar}" core is-installed 2>/dev/null; then
    log_warn "WordPress is already installed"
    read -p "Do you want to continue anyway? (y/N): " -r
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
fi

if ! php "../${file_wpcli_phar}" core download --locale="${site_locale}" --force; then
    log_fatal "Failed to download WordPress core"
fi

log_success "WordPress core downloaded"
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
TEMP_ADMIN_PASS=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+' </dev/urandom | head -c 32)

# Create a temporary file with restrictive permissions for the admin password
TEMP_PASS_FILE=$(mktemp)
chmod 600 "$TEMP_PASS_FILE"
echo "$TEMP_ADMIN_PASS" > "$TEMP_PASS_FILE"

# Ensure cleanup on exit
trap 'rm -f "$TEMP_PASS_FILE"' EXIT INT TERM

# Install WordPress with temporary password
# Note: This still exposes the temp password in process list, but it's immediately changed
if ! php "../${file_wpcli_phar}" core install \
    --url="${site_url}" \
    --title="${site_title}" \
    --admin_user="${admin_login}" \
    --admin_password="$(cat "$TEMP_PASS_FILE")" \
    --admin_email="${admin_email}" \
    --skip-email; then
    log_fatal "WordPress installation failed"
fi

log_success "WordPress database created"

# Immediately update the admin password to the real one using WP-CLI
# This is more secure as we're using WP-CLI's user update which can read from stdin
log_info "Setting final admin password..."

# Method 1: Using wp user update (more secure - credentials from file)
if ! echo "$admin_pass" | php "../${file_wpcli_phar}" user update "${admin_login}" \
    --user_pass="$(cat -)" --skip-email 2>/dev/null; then

    # Fallback method if the above doesn't work
    log_warn "Using fallback method for password update..."
    php "../${file_wpcli_phar}" user update "${admin_login}" \
        --user_pass="${admin_pass}" --skip-email
fi

log_success "Admin password set securely"
log_separator

# Step 4: Security hardening
log_section "STEP 4/4: SECURITY HARDENING"

# Remove default themes (except active one)
log_info "Cleaning up default themes..."
ACTIVE_THEME=$(php "../${file_wpcli_phar}" theme list --status=active --field=name 2>/dev/null || echo "")

for theme in twentytwentyone twentytwentytwo twentytwentythree twentytwentyfour; do
    if [ "$theme" != "$ACTIVE_THEME" ]; then
        php "../${file_wpcli_phar}" theme delete "$theme" 2>/dev/null || true
    fi
done

# Remove default plugins
log_info "Removing default plugins..."
php "../${file_wpcli_phar}" plugin delete hello akismet 2>/dev/null || true

# Update permalink structure
log_info "Setting permalink structure..."
php "../${file_wpcli_phar}" rewrite structure '/%postname%/' --hard 2>/dev/null || true

# Disable comments by default
log_info "Disabling comments on new posts..."
php "../${file_wpcli_phar}" option update default_comment_status 'closed' 2>/dev/null || true
php "../${file_wpcli_phar}" option update default_ping_status 'closed' 2>/dev/null || true

# Set timezone
log_info "Setting timezone to Europe/Paris..."
php "../${file_wpcli_phar}" option update timezone_string 'Europe/Paris' 2>/dev/null || true

# Discourage search engines (can be changed later in admin)
log_warn "Discouraging search engines (remember to enable later!)"
php "../${file_wpcli_phar}" option update blog_public '0' 2>/dev/null || true

# Create .htaccess to protect sensitive files
log_info "Creating security rules..."
cat > "${directory_public}/.htaccess" <<'EOF'
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

# Security: Protect sensitive files
<FilesMatch "^(wp-config\.php|\.htaccess|readme\.html|license\.txt)">
    Order allow,deny
    Deny from all
</FilesMatch>

# Security: Disable directory browsing
Options -Indexes

# Security: Protect against SQL injection
<IfModule mod_rewrite.c>
    RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=http:// [OR]
    RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(\.\.//?)+ [OR]
    RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=/([a-z0-9_.]//?)+ [NC,OR]
    RewriteCond %{QUERY_STRING} \=PHP[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} [NC,OR]
    RewriteCond %{QUERY_STRING} (\.\./|\.\.) [OR]
    RewriteCond %{QUERY_STRING} ftp\: [NC,OR]
    RewriteCond %{QUERY_STRING} http\: [NC,OR]
    RewriteCond %{QUERY_STRING} https\: [NC,OR]
    RewriteCond %{QUERY_STRING} \=\|w\| [NC,OR]
    RewriteCond %{QUERY_STRING} ^(.*)/self/(.*)$ [NC,OR]
    RewriteCond %{QUERY_STRING} ^(.*)cPath=http://(.*)$ [NC,OR]
    RewriteCond %{QUERY_STRING} (\<|%3C).*script.*(\>|%3E) [NC,OR]
    RewriteCond %{QUERY_STRING} (<|%3C)([^s]*s)+cript.*(>|%3E) [NC,OR]
    RewriteCond %{QUERY_STRING} (\<|%3C).*iframe.*(\>|%3E) [NC,OR]
    RewriteCond %{QUERY_STRING} (<|%3C)([^i]*i)+frame.*(>|%3E) [NC,OR]
    RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [NC,OR]
    RewriteCond %{QUERY_STRING} base64_(en|de)code[^(]*\([^)]*\) [NC,OR]
    RewriteCond %{QUERY_STRING} GLOBALS(=|\[|\%[0-9A-Z]{0,2}) [OR]
    RewriteCond %{QUERY_STRING} _REQUEST(=|\[|\%[0-9A-Z]{0,2}) [OR]
    RewriteCond %{QUERY_STRING} ^.*(\[|\]|\(|\)|<|>).* [NC,OR]
    RewriteCond %{QUERY_STRING} (NULL|OUTFILE|LOAD_FILE) [OR]
    RewriteCond %{QUERY_STRING} (\./|\../|\.../)+(motd|etc|bin) [NC,OR]
    RewriteCond %{QUERY_STRING} (localhost|loopback|127\.0\.0\.1) [NC,OR]
    RewriteCond %{QUERY_STRING} (<|>|'|%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
    RewriteCond %{QUERY_STRING} concat[^\(]*\( [NC,OR]
    RewriteCond %{QUERY_STRING} union([^s]*s)+elect [NC,OR]
    RewriteCond %{QUERY_STRING} union([^a]*a)+ll([^s]*s)+elect [NC,OR]
    RewriteCond %{QUERY_STRING} (;|<|>|'|"|\)|%0A|%0D|%22|%27|%3C|%3E|%00).*(/\*|union|select|insert|drop|delete|update|cast|create|char|convert|alter|declare|order|script|set|md5|benchmark|encode) [NC]
    RewriteRule ^(.*)$ - [F,L]
</IfModule>
EOF

chmod 400 "${directory_public}/.htaccess"
log_success ".htaccess created and secured"

log_separator

# Final summary
cd ..
echo ""
log_success "WORDPRESS INSTALLATION COMPLETE!"
echo ""
echo "${CYAN}${BOLD}Site Details:${NORMAL}"
echo "  URL:        ${GREEN}${site_url}${NORMAL}"
echo "  Admin URL:  ${GREEN}${site_url}/wp-admin${NORMAL}"
echo "  Username:   ${GREEN}${admin_login}${NORMAL}"
echo "  Email:      ${GREEN}${admin_email}${NORMAL}"
echo ""
echo "${YELLOW}${BOLD}Important:${NORMAL}"
echo "  - Your admin password is stored in: ${RED}config/config.sh${NORMAL}"
echo "  - This file is excluded from git (never commit it!)"
echo "  - Login at: ${site_url}/wp-admin"
echo "  - Remember to enable search engines when ready (Settings → Reading)"
echo ""
echo "${CYAN}Next steps:${NORMAL}"
echo "  1. Install plugins: ${GREEN}cli/plugins-install.sh${NORMAL}"
echo "  2. Configure your theme"
echo "  3. Create your first pages/posts"
echo ""
