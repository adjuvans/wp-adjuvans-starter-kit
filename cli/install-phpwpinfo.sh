#!/bin/sh
# install-phpwpinfo.sh - Install phpwpinfo for WordPress diagnostics
# phpwpinfo: https://github.com/BeAPI/phpwpinfo

set -eu
# pipefail only if available (bash)
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

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

log_section "PHPWPINFO INSTALLATION"

# Check if WordPress is installed
if [ ! -f "${directory_public}/wp-config.php" ]; then
    log_fatal "WordPress is not installed yet.

Please run 'cli/install-wordpress.sh' first."
fi

# Define phpwpinfo details
PHPWPINFO_URL="https://raw.githubusercontent.com/BeAPI/phpwpinfo/master/phpwpinfo.php"
PHPWPINFO_FILE="${directory_public}/phpwpinfo.php"

# Download phpwpinfo
log_info "Downloading phpwpinfo from GitHub..."
if curl --proto '=https' --tlsv1.2 -sSfL -o "$PHPWPINFO_FILE" "$PHPWPINFO_URL"; then
    chmod 644 "$PHPWPINFO_FILE"
    log_success "phpwpinfo installed: ${PHPWPINFO_FILE}"
else
    log_fatal "Failed to download phpwpinfo"
fi

log_separator

# Security check
log_section "SECURITY CONFIGURATION"

# Create .htaccess rule to protect phpwpinfo (only allow from specific IPs if needed)
log_info "phpwpinfo is now accessible at: ${site_url}/phpwpinfo.php"
log_warn "This file contains sensitive information about your installation!"

echo ""
echo "${YELLOW}${BOLD}⚠ IMPORTANT - SÉCURITÉ${NORMAL}"
echo ""
echo "  Le fichier phpwpinfo.php contient des informations sensibles sur votre installation."
echo "  ${RED}Ne le laissez pas accessible en production !${NORMAL}"
echo ""
echo "${CYAN}Options de sécurité :${NORMAL}"
echo ""
echo "${YELLOW}1. Protection par IP (recommandé)${NORMAL}"
echo "   Créer un fichier .htaccess dans ${directory_public}/ avec :"
echo "   ${GREEN}<Files \"phpwpinfo.php\">"
echo "   Order Deny,Allow"
echo "   Deny from all"
echo "   Allow from VOTRE.IP.ICI"
echo "   </Files>${NORMAL}"
echo ""
echo "${YELLOW}2. Suppression après utilisation (le plus sûr)${NORMAL}"
echo "   ${GREEN}rm ${PHPWPINFO_FILE}${NORMAL}"
echo ""
echo "${YELLOW}3. Renommer le fichier${NORMAL}"
echo "   ${GREEN}mv ${PHPWPINFO_FILE} ${directory_public}/diagnostic-$(date +%s).php${NORMAL}"
echo ""
echo "${CYAN}Accès :${NORMAL}"
echo "   ${GREEN}${site_url}/phpwpinfo.php${NORMAL}"
echo ""

log_separator
log_success "Installation terminée !"
echo ""
