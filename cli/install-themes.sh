#!/bin/sh
# install-themes.sh - Interactive theme installer

set -eu
# pipefail only if available (bash)
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    echo "Please run 'cli/install.sh' first to generate config/config.sh"
    exit 1
fi

. "$CONFIG_FILE"

resolve_path() {
    case "$1" in
        /*) echo "$1" ;;
        *) echo "${SCRIPT_DIR}/../${1#./}" ;;
    esac
}

export LOG_DIR="$(resolve_path "$directory_log")"

. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"

log_section "THEME INSTALLATION"

detect_php() {
    if command -v php >/dev/null 2>&1; then
        PHP_BIN="php"
    elif command -v php8.3 >/dev/null 2>&1; then
        PHP_BIN="php8.3"
    elif command -v php8.2 >/dev/null 2>&1; then
        PHP_BIN="php8.2"
    elif command -v php8.1 >/dev/null 2>&1; then
        PHP_BIN="php8.1"
    elif command -v php8.0 >/dev/null 2>&1; then
        PHP_BIN="php8.0"
    elif command -v php7.4 >/dev/null 2>&1; then
        PHP_BIN="php7.4"
    elif [ -x "/usr/local/bin/php" ]; then
        PHP_BIN="/usr/local/bin/php"
    elif [ -x "/usr/bin/php" ]; then
        PHP_BIN="/usr/bin/php"
    else
        log_fatal "PHP not found in PATH"
    fi
}

detect_php
log_info "Using PHP binary: ${GREEN}${PHP_BIN}${NORMAL}"

WP_CLI="$(resolve_path "$file_wpcli_phar")"
if [ ! -f "$WP_CLI" ]; then
    log_fatal "WP-CLI not found at ${WP_CLI}. Run 'cli/init.sh' first."
fi

WP_DIR="$(resolve_path "$directory_public")"
if [ ! -d "$WP_DIR" ]; then
    log_fatal "WordPress directory not found: ${WP_DIR}"
fi

cd "$WP_DIR" || log_fatal "Cannot access WordPress directory: ${WP_DIR}"

# Recommended themes for Elementor-based sites
THEMES="
hello-elementor
"

log_info "The following themes are recommended for Elementor-based sites"
echo ""

for theme in $THEMES; do
    printf "${CYAN}Install theme '%s'? (y/N): ${NORMAL}" "$theme"
    read -r REPLY

    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        log_info "Skipped ${theme}"
        continue
    fi

    log_info "Processing theme: ${theme}"

    if $PHP_BIN "$WP_CLI" theme is-installed "$theme" >/dev/null 2>&1; then
        log_info "Theme already installed"
        printf "${CYAN}Activate '%s'? (y/N): ${NORMAL}" "$theme"
        read -r ACTIVATE_REPLY
        if [ "$ACTIVATE_REPLY" = "y" ] || [ "$ACTIVATE_REPLY" = "Y" ]; then
            if $PHP_BIN "$WP_CLI" theme activate "$theme"; then
                log_success "${theme} activated"
            else
                log_warn "Could not activate ${theme}"
            fi
        fi
    else
        if $PHP_BIN "$WP_CLI" theme install "$theme"; then
            log_success "${theme} installed"
            printf "${CYAN}Activate '%s'? (y/N): ${NORMAL}" "$theme"
            read -r ACTIVATE_REPLY
            if [ "$ACTIVATE_REPLY" = "y" ] || [ "$ACTIVATE_REPLY" = "Y" ]; then
                if $PHP_BIN "$WP_CLI" theme activate "$theme"; then
                    log_success "${theme} activated"
                else
                    log_warn "Could not activate ${theme}"
                fi
            fi
        else
            log_warn "Failed to install ${theme}"
        fi
    fi
done

log_separator
log_success "Theme installation routine completed"
