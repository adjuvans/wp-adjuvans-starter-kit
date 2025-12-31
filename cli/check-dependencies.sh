#!/bin/sh
# check-dependencies.sh - Verify required system dependencies
# This script checks if all necessary commands are available before installation

set -eu
# pipefail only if available (bash)
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"

log_section "DEPENDENCY CHECK"

# Track missing dependencies
MISSING_DEPS=""
OPTIONAL_MISSING=""

# Check if a command exists
# Usage: check_command "curl" "required"
check_command() {
    local cmd="$1"
    local required="${2:-required}"
    local install_hint="${3:-}"

    if command -v "$cmd" >/dev/null 2>&1; then
        local version=""
        case "$cmd" in
            php)
                version=$(php -v | head -n1 | cut -d' ' -f2)
                ;;
            mysql)
                version=$(mysql --version 2>/dev/null | awk '{print $5}' | sed 's/,$//' || echo "unknown")
                ;;
            curl)
                version=$(curl --version | head -n1 | awk '{print $2}')
                ;;
            *)
                version="installed"
                ;;
        esac
        log_success "${cmd} (${version})"
        return 0
    else
        if [ "$required" = "required" ]; then
            log_error "${cmd} - MISSING (required)"
            MISSING_DEPS="${MISSING_DEPS}${cmd} "
            if [ -n "$install_hint" ]; then
                echo "         ${YELLOW}Installation hint: ${install_hint}${NORMAL}"
            fi
        else
            log_warn "${cmd} - missing (optional)"
            OPTIONAL_MISSING="${OPTIONAL_MISSING}${cmd} "
            if [ -n "$install_hint" ]; then
                echo "         ${CYAN}Installation hint: ${install_hint}${NORMAL}"
            fi
        fi
        return 1
    fi
}

# Required dependencies
log_info "Checking required dependencies..."
echo ""

check_command "sh" "required"
check_command "bash" "required"
check_command "php" "required" "https://www.php.net/downloads"
check_command "curl" "required" "apt-get install curl / yum install curl"
check_command "tar" "required" "apt-get install tar"
check_command "gzip" "required" "apt-get install gzip"
check_command "sha512sum" "required" "apt-get install coreutils"
check_command "chmod" "required"
check_command "mkdir" "required"
check_command "grep" "required"
check_command "sed" "required"

echo ""
log_separator

# Check PHP version (minimum 7.4 for WordPress)
log_info "Checking PHP version..."
if command -v php >/dev/null 2>&1; then
    PHP_VERSION=$(php -r "echo PHP_VERSION;" 2>/dev/null || echo "0.0.0")
    PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d. -f1)
    PHP_MINOR=$(echo "$PHP_VERSION" | cut -d. -f2)

    if [ "$PHP_MAJOR" -gt 7 ] || { [ "$PHP_MAJOR" -eq 7 ] && [ "$PHP_MINOR" -ge 4 ]; }; then
        log_success "PHP version ${PHP_VERSION} meets minimum requirement (>= 7.4)"
    else
        log_error "PHP version ${PHP_VERSION} is too old (minimum required: 7.4)"
        MISSING_DEPS="${MISSING_DEPS}php-7.4+ "
    fi
else
    log_error "PHP not found"
    MISSING_DEPS="${MISSING_DEPS}php "
fi

echo ""
log_separator

# Check PHP extensions required by WordPress
log_info "Checking PHP extensions..."
check_php_extension() {
    local ext="$1"
    if php -m 2>/dev/null | grep -qi "^${ext}$"; then
        log_success "PHP extension: ${ext}"
        return 0
    else
        log_warn "PHP extension missing: ${ext} (recommended)"
        OPTIONAL_MISSING="${OPTIONAL_MISSING}php-${ext} "
        return 1
    fi
}

check_php_extension "mysqli"
check_php_extension "curl"
check_php_extension "gd"
check_php_extension "mbstring"
check_php_extension "xml"
check_php_extension "zip"
check_php_extension "json"

echo ""
log_separator

# Optional dependencies
log_info "Checking optional dependencies..."
echo ""

check_command "mysql" "optional" "apt-get install mysql-client"
check_command "git" "optional" "apt-get install git"
check_command "gpg" "optional" "apt-get install gnupg (for encrypted backups)"
check_command "unzip" "optional" "apt-get install unzip"

echo ""
log_separator

# Check disk space (minimum 500MB recommended)
log_info "Checking available disk space..."
AVAILABLE_SPACE=$(df -m . | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -gt 500 ]; then
    log_success "Available disk space: ${AVAILABLE_SPACE}MB"
else
    log_warn "Low disk space: ${AVAILABLE_SPACE}MB (recommended: 500MB+)"
fi

echo ""
log_separator

# Final summary
echo ""
if [ -n "$MISSING_DEPS" ]; then
    log_error "DEPENDENCY CHECK FAILED"
    echo ""
    echo "${RED}Missing required dependencies:${NORMAL}"
    for dep in $MISSING_DEPS; do
        echo "  - $dep"
    done
    echo ""
    echo "${YELLOW}Please install the missing dependencies before continuing.${NORMAL}"
    echo ""
    exit 1
else
    log_success "ALL REQUIRED DEPENDENCIES SATISFIED"

    if [ -n "$OPTIONAL_MISSING" ]; then
        echo ""
        echo "${YELLOW}Optional dependencies missing (some features may be limited):${NORMAL}"
        for dep in $OPTIONAL_MISSING; do
            echo "  - $dep"
        done
    fi

    echo ""
    echo "${GREEN}${BOLD}✔ System is ready for WordPress installation!${NORMAL}"
    echo ""
    exit 0
fi
