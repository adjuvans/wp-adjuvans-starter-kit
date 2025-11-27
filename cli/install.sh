#!/bin/sh
# install.sh - Interactive WordPress installation wizard
# This is the main entry point for setting up a new WordPress site

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"
. "${SCRIPT_DIR}/lib/validators.sh"

# ASCII Banner
clear
cat <<'EOF'

     █████╗ ██████╗      ██╗██╗   ██╗██╗   ██╗ █████╗ ███╗   ██╗███████╗
    ██╔══██╗██╔══██╗     ██║██║   ██║██║   ██║██╔══██╗████╗  ██║██╔════╝
    ███████║██║  ██║     ██║██║   ██║██║   ██║███████║██╔██╗ ██║███████╗
    ██╔══██║██║  ██║██   ██║██║   ██║╚██╗ ██╔╝██╔══██║██║╚██╗██║╚════██║
    ██║  ██║██████╔╝╚█████╔╝╚██████╔╝ ╚████╔╝ ██║  ██║██║ ╚████║███████║
    ╚═╝  ╚═╝╚═════╝  ╚════╝  ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝

    WordPress Starter Kit - Interactive Installer
    https://github.com/adjuvans/wp-adjuvans-starter-kit

EOF

echo "${CYAN}This wizard will guide you through WordPress installation.${NORMAL}"
echo ""

# Check if configuration already exists
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"

if [ -f "$CONFIG_FILE" ]; then
    log_warn "Configuration file already exists: ${CONFIG_FILE}"
    printf "${YELLOW}Do you want to recreate it? This will overwrite existing config (y/N): ${NORMAL}"
    read -r REPLY
    echo ""
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        log_info "Using existing configuration"
        . "$CONFIG_FILE"

        # Skip to installation
        printf "${CYAN}Do you want to proceed with WordPress installation? (Y/n): ${NORMAL}"
        read -r INSTALL_NOW
        echo ""
        if [ "$INSTALL_NOW" != "n" ] && [ "$INSTALL_NOW" != "N" ]; then
            "${SCRIPT_DIR}/init.sh"
            "${SCRIPT_DIR}/install-wordpress.sh"
        fi
        exit 0
    fi
fi

log_section "PROJECT CONFIGURATION"

# Project information
echo "${BOLD}Project Information${NORMAL}"
printf "Project name (e.g., 'My Awesome Site'): "
read -r project_name

printf "Project slug (lowercase, hyphens only, e.g., 'my-awesome-site'): "
while true; do
    read -r project_slug
    if validate_slug "$project_slug"; then
        break
    fi
done

log_separator

# Database configuration
echo ""
echo "${BOLD}Database Configuration${NORMAL}"

printf "Database name: "
while true; do
    read -r db_name
    if validate_db_name "$db_name"; then
        break
    fi
done

printf "Database user: "
while true; do
    read -r db_user
    if validate_username "$db_user"; then
        break
    fi
done

printf "Database password: "
stty -echo
while true; do
    read -r db_pass
    stty echo
    echo ""
    if validate_password "$db_pass" 12; then
        break
    fi
    printf "Database password (try again): "
    stty -echo
done

printf "Database host [localhost]: "
read -r db_host
db_host=${db_host:-localhost}

printf "Table prefix [wp_]: "
read -r db_prefix
db_prefix=${db_prefix:-wp_}
if ! echo "$db_prefix" | grep -q '_$'; then
    db_prefix="${db_prefix}_"
fi

log_separator

# WordPress configuration
echo ""
echo "${BOLD}WordPress Configuration${NORMAL}"

printf "Site URL (with https://, e.g., https://example.test): "
while true; do
    read -r site_url
    if validate_url "$site_url"; then
        break
    fi
done

printf "Site title: "
read -r site_title

printf "Site locale [fr_FR]: "
read -r site_locale
site_locale=${site_locale:-fr_FR}

log_separator

# Admin account
echo ""
echo "${BOLD}WordPress Admin Account${NORMAL}"

printf "Admin username: "
while true; do
    read -r admin_login
    if validate_username "$admin_login"; then
        break
    fi
done

printf "Admin password (min 12 characters, must contain uppercase, lowercase, and digit): "
stty -echo
while true; do
    read -r admin_pass
    stty echo
    echo ""
    if validate_password "$admin_pass" 12; then
        break
    fi
    printf "Admin password (try again): "
    stty -echo
done

printf "Admin email: "
while true; do
    read -r admin_email
    if validate_email "$admin_email"; then
        break
    fi
done

log_separator

# Backup configuration
echo ""
echo "${BOLD}Backup Configuration${NORMAL}"

printf "Enable GPG encryption for backups? (y/N): "
read -r use_gpg
if [ "$use_gpg" = "y" ] || [ "$use_gpg" = "Y" ]; then
    USE_GPG_ENCRYPTION="true"

    printf "GPG recipient email (leave empty for symmetric encryption): "
    read -r GPG_RECIPIENT
else
    USE_GPG_ENCRYPTION="false"
    GPG_RECIPIENT=""
fi

printf "Number of backups to keep [7]: "
read -r BACKUP_RETENTION
BACKUP_RETENTION=${BACKUP_RETENTION:-7}

log_separator

# Summary
echo ""
log_section "CONFIGURATION SUMMARY"
echo ""
echo "${CYAN}Project:${NORMAL}      ${GREEN}${project_name}${NORMAL} (${project_slug})"
echo "${CYAN}Site URL:${NORMAL}     ${GREEN}${site_url}${NORMAL}"
echo "${CYAN}Database:${NORMAL}     ${GREEN}${db_name}${NORMAL} @ ${db_host}"
echo "${CYAN}DB User:${NORMAL}      ${GREEN}${db_user}${NORMAL}"
echo "${CYAN}Admin:${NORMAL}        ${GREEN}${admin_login}${NORMAL} <${admin_email}>"
echo "${CYAN}Locale:${NORMAL}       ${GREEN}${site_locale}${NORMAL}"
echo "${CYAN}Encryption:${NORMAL}   ${GREEN}${USE_GPG_ENCRYPTION}${NORMAL}"
echo ""

printf "${YELLOW}Is this configuration correct? (Y/n): ${NORMAL}"
read -r CONFIRM
echo ""

if [ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ]; then
    log_error "Configuration cancelled by user"
    exit 1
fi

# Generate configuration file
log_section "GENERATING CONFIGURATION FILE"

cat > "$CONFIG_FILE" <<EOF
#!/bin/sh
# Generated configuration file
# Created: $(date '+%Y-%m-%d %H:%M:%S')
# SECURITY WARNING: This file contains sensitive data - NEVER commit to git!

# Project
project_name="${project_name}"
project_slug="${project_slug}"

# Directories
directory_public="./wordpress"
directory_log="./logs"
directory_backup="./save"

# WP-CLI
file_wpcli_phar="./wp-cli.phar"
file_wpcli_completion="./wp-completion.bash"
file_wpcli_config="./wp-cli.yml"

# WordPress
site_locale="${site_locale}"
site_title="${site_title}"
site_url="${site_url}"

# Theme
theme_name="hello-elementor"
theme_child_name="hello-elementor"

# Database
db_host="${db_host}"
db_name="${db_name}"
db_user="${db_user}"
db_pass="${db_pass}"
db_prefix="${db_prefix}"
db_charset="utf8mb4"

# Admin
admin_login="${admin_login}"
admin_pass="${admin_pass}"
admin_email="${admin_email}"

# Backup
USE_GPG_ENCRYPTION="${USE_GPG_ENCRYPTION}"
GPG_RECIPIENT="${GPG_RECIPIENT}"
BACKUP_RETENTION="${BACKUP_RETENTION}"
EOF

chmod 600 "$CONFIG_FILE"
log_success "Configuration saved: ${CONFIG_FILE}"
log_info "File permissions: 600 (owner read/write only)"

log_separator

# Proceed with installation
echo ""
printf "${CYAN}${BOLD}Do you want to proceed with WordPress installation now? (Y/n): ${NORMAL}"
read -r INSTALL_NOW
echo ""

if [ "$INSTALL_NOW" = "n" ] || [ "$INSTALL_NOW" = "N" ]; then
    echo ""
    log_info "Configuration complete. Run these commands to install WordPress:"
    echo ""
    echo "  ${GREEN}cli/init.sh${NORMAL}              # Initialize environment"
    echo "  ${GREEN}cli/install-wordpress.sh${NORMAL} # Install WordPress"
    echo ""
    exit 0
fi

# Run initialization
log_section "RUNNING INITIALIZATION"
"${SCRIPT_DIR}/init.sh"

log_separator

# Run WordPress installation
log_section "RUNNING WORDPRESS INSTALLATION"
"${SCRIPT_DIR}/install-wordpress.sh"

echo ""
log_success "INSTALLATION COMPLETE!"
echo ""
echo "${CYAN}${BOLD}What's next?${NORMAL}"
echo "  1. Install plugins: ${GREEN}cli/plugins-install.sh${NORMAL}"
echo "  2. Visit your site: ${GREEN}${site_url}${NORMAL}"
echo "  3. Login to admin: ${GREEN}${site_url}/wp-admin${NORMAL}"
echo ""
