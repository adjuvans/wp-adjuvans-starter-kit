#!/bin/sh
set -euo pipefail

CONFIG_FILE="$(dirname "$0")/config.sh"
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE" || { echo "Missing config: $CONFIG_FILE"; exit 1; }

echo ""
echo "---"
echo "${blue}${bold}# INSTALLATION DE WORDPRESS${normal}"

# Étape 1 : téléchargement
echo "${blue}[1/3] Téléchargement de WordPress...${normal}"
wp core download --locale="${site_locale}" --quiet

# Étape 2 : création du wp-config.php
echo "${blue}[2/3] Création du fichier wp-config.php...${normal}"
wp config create \\
    --dbname="${db_name}" \\
    --dbuser="${db_user}" \\
    --dbpass="${db_pass}" \\
    --dbhost="${db_host}" \\
    --dbprefix="${db_prefix}" \\
    --skip-check \\
    --extra-php <<PHP
define('WP_DEBUG_DISPLAY', false);
define('WP_DEBUG_LOG', dirname(__FILE__) . '/../logs/' . date('Y-m-d') . '_wp-errors.log');
PHP

# Étape 3 : installation
echo "${blue}[3/3] Installation du site WordPress...${normal}"
wp core install \\
    --url="${site_url}" \\
    --title="${site_title}" \\
    --admin_user="${admin_login}" \\
    --admin_password="${admin_pass}" \\
    --admin_email="${admin_email}" \\
    --skip-email

echo "${green}✔ Installation WordPress terminée.${normal}"
echo "---"
