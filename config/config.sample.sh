#!/bin/sh
# config.sample.sh - Configuration template for WPASK
# Copy this file to config.sh and fill in your project details
#
# SECURITY WARNING:
# This file will contain sensitive data (passwords, database credentials).
# NEVER commit config.sh to version control!
# It is already excluded in .gitignore

# ============================================================================
# PROJECT INFORMATION
# ============================================================================

project_name="MY PROJECT NAME"
project_slug="my-project-slug"

# ============================================================================
# DIRECTORY CONFIGURATION
# ============================================================================

directory_public="./wordpress"       # WordPress installation directory
directory_log="./logs"               # Log files directory
directory_backup="./save"            # Backup files directory

# ============================================================================
# WP-CLI CONFIGURATION
# ============================================================================

file_wpcli_phar="./wp-cli.phar"
file_wpcli_completion="./wp-completion.bash"
file_wpcli_config="./wp-cli.yml"

# ============================================================================
# WORDPRESS CONFIGURATION
# ============================================================================

site_locale="fr_FR"                  # WordPress locale (en_US, fr_FR, etc.)
site_title="My WordPress Site"       # Site title
site_url="https://example.test"      # Site URL (with protocol)

# ============================================================================
# THEME CONFIGURATION
# ============================================================================

theme_name="hello-elementor"         # Parent theme slug
theme_child_name="hello-elementor"   # Child theme slug (or same as parent)

# ============================================================================
# DATABASE CONFIGURATION
# ============================================================================

db_host="localhost"                  # Database host
db_name="wordpress_db"               # Database name
db_user="wordpress_user"             # Database username
db_pass="CHANGE_ME_STRONG_PASSWORD"  # Database password
db_prefix="wp_"                      # Table prefix (keep the underscore!)
db_charset="utf8mb4"                 # Database charset

# ============================================================================
# WORDPRESS ADMIN ACCOUNT
# ============================================================================

admin_login="admin"                  # Admin username
admin_pass="CHANGE_ME_STRONG_PASSWORD"  # Admin password (min 12 chars)
admin_email="admin@example.com"      # Admin email address

# ============================================================================
# BACKUP CONFIGURATION
# ============================================================================

USE_GPG_ENCRYPTION="false"           # Enable GPG encryption for backups (true/false)
GPG_RECIPIENT=""                     # GPG recipient email (leave empty for symmetric encryption)
BACKUP_RETENTION="7"                 # Number of backups to keep

# ============================================================================
# TERMINAL COLORS (Auto-configured - don't modify)
# ============================================================================

# These are set automatically by lib/colors.sh
# Kept here for backward compatibility
red=""
green=""
blue=""
yellow=""
cyan=""
bold=""
normal=""
