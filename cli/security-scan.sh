#!/bin/sh
# security-scan.sh - Security scanner for WordPress installations
# Checks for vulnerabilities, misconfigurations, and security issues
# Created for WPASK v3.0

set -eu
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# =============================================================================
# SCRIPT SETUP
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

# Default options
QUIET_MODE="false"
JSON_OUTPUT="false"
SKIP_WPSCAN="false"
SPECIFIC_CHECKS=""

# Score tracking
CRITICAL_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0
TOTAL_SCORE=100

# Results storage for JSON
RESULTS=""

# =============================================================================
# USAGE
# =============================================================================

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Scan WordPress installation for security issues

OPTIONS:
    -h, --help              Show this help message
    -q, --quiet             Quiet mode (exit code only)
    -j, --json              Output results as JSON
    --skip-wpscan           Skip WPScan vulnerability check
    --check=CHECKS          Run specific checks only (comma-separated)

AVAILABLE CHECKS:
    checksums       Verify WordPress core file integrity
    plugins         Check for outdated/vulnerable plugins
    themes          Check for outdated themes
    permissions     Check file permissions
    config          Check wp-config.php security
    files           Scan for suspicious files
    server          Check server configuration
    all             Run all checks (default)

EXAMPLES:
    # Full security scan
    $SCRIPT_NAME

    # Quick scan without WPScan API
    $SCRIPT_NAME --skip-wpscan

    # Check only permissions and config
    $SCRIPT_NAME --check=permissions,config

    # JSON output for automation
    $SCRIPT_NAME --json > security-report.json

SCORING:
    A (90-100)  Excellent security posture
    B (80-89)   Good, minor improvements needed
    C (70-79)   Fair, several issues to address
    D (60-69)   Poor, significant vulnerabilities
    F (0-59)    Critical, immediate action required

EXIT CODES:
    0   No critical issues found
    1   Critical issues detected
    2   Script error
EOF
}

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -q|--quiet)
            QUIET_MODE="true"
            shift
            ;;
        -j|--json)
            JSON_OUTPUT="true"
            shift
            ;;
        --skip-wpscan)
            SKIP_WPSCAN="true"
            shift
            ;;
        --check=*)
            SPECIFIC_CHECKS="${1#*=}"
            shift
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            show_usage
            exit 2
            ;;
        *)
            shift
            ;;
    esac
done

# =============================================================================
# LOAD CONFIGURATION
# =============================================================================

CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    if [ "$JSON_OUTPUT" = "true" ]; then
        echo '{"error": "Configuration file not found"}'
    else
        echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    fi
    exit 2
fi

. "$CONFIG_FILE"

export LOG_DIR="${directory_log}"

. "${SCRIPT_DIR}/lib/colors.sh"
. "${SCRIPT_DIR}/lib/logger.sh"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Check if a specific check should run
should_run_check() {
    local check_name="$1"

    if [ -z "$SPECIFIC_CHECKS" ]; then
        return 0  # Run all checks
    fi

    echo ",$SPECIFIC_CHECKS," | grep -q ",$check_name," && return 0
    echo ",$SPECIFIC_CHECKS," | grep -q ",all," && return 0
    return 1
}

# Add issue to results
add_issue() {
    local severity="$1"
    local category="$2"
    local message="$3"
    local recommendation="${4:-}"

    case "$severity" in
        CRITICAL)
            CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
            TOTAL_SCORE=$((TOTAL_SCORE - 15))
            [ "$QUIET_MODE" = "false" ] && [ "$JSON_OUTPUT" = "false" ] && \
                echo "  ${RED}✗${NORMAL} $message"
            ;;
        WARNING)
            WARNING_COUNT=$((WARNING_COUNT + 1))
            TOTAL_SCORE=$((TOTAL_SCORE - 5))
            [ "$QUIET_MODE" = "false" ] && [ "$JSON_OUTPUT" = "false" ] && \
                echo "  ${YELLOW}!${NORMAL} $message"
            ;;
        INFO)
            INFO_COUNT=$((INFO_COUNT + 1))
            TOTAL_SCORE=$((TOTAL_SCORE - 1))
            [ "$QUIET_MODE" = "false" ] && [ "$JSON_OUTPUT" = "false" ] && \
                echo "  ${CYAN}ℹ${NORMAL} $message"
            ;;
    esac

    # Store for JSON output
    if [ "$JSON_OUTPUT" = "true" ]; then
        RESULTS="${RESULTS}{\"severity\":\"$severity\",\"category\":\"$category\",\"message\":\"$message\",\"recommendation\":\"$recommendation\"},"
    fi
}

# Add success to results
add_success() {
    local message="$1"
    [ "$QUIET_MODE" = "false" ] && [ "$JSON_OUTPUT" = "false" ] && \
        echo "  ${GREEN}✓${NORMAL} $message"
}

# Get letter grade from score
get_grade() {
    local score="$1"
    [ "$score" -lt 0 ] && score=0

    if [ "$score" -ge 90 ]; then
        echo "A"
    elif [ "$score" -ge 80 ]; then
        echo "B"
    elif [ "$score" -ge 70 ]; then
        echo "C"
    elif [ "$score" -ge 60 ]; then
        echo "D"
    else
        echo "F"
    fi
}

# Print section header
print_section() {
    local title="$1"
    [ "$QUIET_MODE" = "false" ] && [ "$JSON_OUTPUT" = "false" ] && \
        echo "" && echo "${BLUE}${BOLD}[$title]${NORMAL}"
}

# =============================================================================
# SECURITY CHECKS
# =============================================================================

# Check WordPress core integrity
check_checksums() {
    print_section "CORE INTEGRITY"

    cd "$directory_public" || return 1

    if [ ! -f "../${file_wpcli_phar}" ]; then
        add_issue "WARNING" "checksums" "WP-CLI not available - cannot verify checksums"
        return 0
    fi

    local result
    result=$(php "../${file_wpcli_phar}" core verify-checksums 2>&1) || true

    if echo "$result" | grep -q "Success"; then
        add_success "WordPress core files integrity verified"
    elif echo "$result" | grep -q "File doesn't verify"; then
        local modified_count
        modified_count=$(echo "$result" | grep -c "File doesn't verify" || echo "0")
        add_issue "CRITICAL" "checksums" "WordPress core files modified ($modified_count files)" "Reinstall WordPress core or restore from backup"
    elif echo "$result" | grep -q "File should not exist"; then
        add_issue "WARNING" "checksums" "Extra files found in WordPress core directories" "Review and remove unknown files"
    else
        add_success "WordPress core files integrity verified"
    fi

    cd ..
}

# Check plugins for updates and vulnerabilities
check_plugins() {
    print_section "PLUGINS"

    cd "$directory_public" || return 1

    if [ ! -f "../${file_wpcli_phar}" ]; then
        add_issue "WARNING" "plugins" "WP-CLI not available - cannot check plugins"
        return 0
    fi

    # Check for updates
    local outdated
    outdated=$(php "../${file_wpcli_phar}" plugin list --update=available --format=count 2>/dev/null || echo "0")

    if [ "$outdated" -gt 0 ]; then
        add_issue "WARNING" "plugins" "$outdated plugin(s) have updates available" "Run: make update-plugins"
    else
        add_success "All plugins are up to date"
    fi

    # Check for inactive plugins
    local inactive
    inactive=$(php "../${file_wpcli_phar}" plugin list --status=inactive --format=count 2>/dev/null || echo "0")

    if [ "$inactive" -gt 0 ]; then
        add_issue "INFO" "plugins" "$inactive inactive plugin(s) found" "Remove unused plugins to reduce attack surface"
    fi

    # Check WPScan for vulnerabilities (if enabled)
    if [ "$SKIP_WPSCAN" = "false" ]; then
        check_wpscan_vulnerabilities "plugins"
    fi

    cd ..
}

# Check themes for updates
check_themes() {
    print_section "THEMES"

    cd "$directory_public" || return 1

    if [ ! -f "../${file_wpcli_phar}" ]; then
        add_issue "WARNING" "themes" "WP-CLI not available - cannot check themes"
        return 0
    fi

    # Check for updates
    local outdated
    outdated=$(php "../${file_wpcli_phar}" theme list --update=available --format=count 2>/dev/null || echo "0")

    if [ "$outdated" -gt 0 ]; then
        add_issue "WARNING" "themes" "$outdated theme(s) have updates available" "Run: make update-themes"
    else
        add_success "All themes are up to date"
    fi

    # Check for inactive themes (keep only active + one default)
    local inactive
    inactive=$(php "../${file_wpcli_phar}" theme list --status=inactive --format=count 2>/dev/null || echo "0")

    if [ "$inactive" -gt 1 ]; then
        add_issue "INFO" "themes" "$inactive inactive themes found" "Keep only active theme and one default fallback"
    fi

    cd ..
}

# Check WPScan API for known vulnerabilities
check_wpscan_vulnerabilities() {
    local check_type="${1:-all}"

    # Check if API key is configured
    local api_key_file="${SCRIPT_DIR}/../config/wpscan-api.key"

    if [ ! -f "$api_key_file" ]; then
        add_issue "INFO" "wpscan" "WPScan API not configured" "Run: ./cli/setup-wpscan-api.sh"
        return 0
    fi

    local api_key
    api_key=$(cat "$api_key_file" | tr -d '\n')

    if [ -z "$api_key" ]; then
        add_issue "INFO" "wpscan" "WPScan API key is empty" "Run: ./cli/setup-wpscan-api.sh"
        return 0
    fi

    # Get WordPress version for API check
    cd "$directory_public" || return 0

    if [ -f "../${file_wpcli_phar}" ]; then
        local wp_version
        wp_version=$(php "../${file_wpcli_phar}" core version 2>/dev/null || echo "")

        if [ -n "$wp_version" ]; then
            # Check WordPress core vulnerabilities
            local response
            response=$(curl -s -H "Authorization: Token token=$api_key" \
                "https://wpscan.com/api/v3/wordpresses/${wp_version}" 2>/dev/null || echo "")

            if echo "$response" | grep -q '"vulnerabilities":\[\]'; then
                add_success "No known vulnerabilities for WordPress $wp_version"
            elif echo "$response" | grep -q '"vulnerabilities":\['; then
                local vuln_count
                vuln_count=$(echo "$response" | grep -o '"id":' | wc -l | tr -d ' ')
                add_issue "CRITICAL" "wpscan" "WordPress $wp_version has $vuln_count known vulnerability(ies)" "Update WordPress immediately"
            fi
        fi
    fi

    cd ..
}

# Check file permissions
check_permissions() {
    print_section "FILE PERMISSIONS"

    # Check wp-config.php permissions
    local wp_config="${directory_public}/wp-config.php"
    if [ -f "$wp_config" ]; then
        local perms
        perms=$(stat -f "%Lp" "$wp_config" 2>/dev/null || stat -c "%a" "$wp_config" 2>/dev/null || echo "unknown")

        case "$perms" in
            400|440|600|640)
                add_success "wp-config.php has secure permissions ($perms)"
                ;;
            644)
                add_issue "WARNING" "permissions" "wp-config.php permissions too permissive ($perms)" "Run: chmod 640 wp-config.php"
                ;;
            *)
                if [ "$perms" != "unknown" ]; then
                    add_issue "WARNING" "permissions" "wp-config.php permissions: $perms" "Recommended: 640 or 600"
                fi
                ;;
        esac
    fi

    # Check .htaccess permissions
    local htaccess="${directory_public}/.htaccess"
    if [ -f "$htaccess" ]; then
        local perms
        perms=$(stat -f "%Lp" "$htaccess" 2>/dev/null || stat -c "%a" "$htaccess" 2>/dev/null || echo "unknown")

        case "$perms" in
            644|444)
                add_success ".htaccess has appropriate permissions ($perms)"
                ;;
            *)
                if [ "$perms" != "unknown" ]; then
                    add_issue "INFO" "permissions" ".htaccess permissions: $perms" "Recommended: 644"
                fi
                ;;
        esac
    fi

    # Check uploads directory for PHP files
    local uploads_dir="${directory_public}/wp-content/uploads"
    if [ -d "$uploads_dir" ]; then
        local php_in_uploads
        php_in_uploads=$(find "$uploads_dir" -name "*.php" -type f 2>/dev/null | wc -l | tr -d ' ')

        if [ "$php_in_uploads" -gt 0 ]; then
            add_issue "CRITICAL" "permissions" "PHP files found in uploads directory ($php_in_uploads files)" "Remove suspicious PHP files from wp-content/uploads/"
        else
            add_success "No PHP files in uploads directory"
        fi
    fi
}

# Check wp-config.php security settings
check_config() {
    print_section "CONFIGURATION"

    local wp_config="${directory_public}/wp-config.php"

    if [ ! -f "$wp_config" ]; then
        add_issue "CRITICAL" "config" "wp-config.php not found"
        return 1
    fi

    # Check DISALLOW_FILE_EDIT
    if grep -q "DISALLOW_FILE_EDIT.*true" "$wp_config" 2>/dev/null; then
        add_success "File editing disabled (DISALLOW_FILE_EDIT)"
    else
        add_issue "WARNING" "config" "File editing not disabled in admin" "Add: define('DISALLOW_FILE_EDIT', true);"
    fi

    # Check WP_DEBUG in production
    if grep -q "WP_DEBUG.*true" "$wp_config" 2>/dev/null; then
        add_issue "CRITICAL" "config" "Debug mode is enabled (WP_DEBUG true)" "Set WP_DEBUG to false in production"
    else
        add_success "Debug mode is disabled"
    fi

    # Check for unique salts
    if grep -q "put your unique phrase here" "$wp_config" 2>/dev/null; then
        add_issue "CRITICAL" "config" "Security keys/salts not configured" "Generate new salts at: https://api.wordpress.org/secret-key/1.1/salt/"
    else
        add_success "Security keys/salts are configured"
    fi

    # Check table prefix
    local prefix
    prefix=$(grep "table_prefix" "$wp_config" 2>/dev/null | grep -o "'[^']*'" | head -1 | tr -d "'" || echo "wp_")

    if [ "$prefix" = "wp_" ]; then
        add_issue "WARNING" "config" "Using default table prefix 'wp_'" "Consider using a custom table prefix"
    else
        add_success "Custom table prefix in use"
    fi

    # Check for exposed debug.log
    if [ -f "${directory_public}/wp-content/debug.log" ]; then
        add_issue "WARNING" "config" "debug.log file exists and may be publicly accessible" "Remove or protect debug.log"
    fi
}

# Check for suspicious files
check_files() {
    print_section "SUSPICIOUS FILES"

    local suspicious_count=0

    # Common backdoor/shell patterns
    local patterns="eval\(base64_decode\|eval\(\$_\|system\(\$_\|passthru\|shell_exec\|phpinfo()"

    # Search for suspicious patterns in PHP files (limited to avoid performance issues)
    local matches
    matches=$(find "$directory_public" -name "*.php" -type f -exec grep -l "$patterns" {} \; 2>/dev/null | head -20 || true)

    if [ -n "$matches" ]; then
        suspicious_count=$(echo "$matches" | wc -l | tr -d ' ')
        add_issue "CRITICAL" "files" "Suspicious code patterns found in $suspicious_count file(s)" "Review files for malicious code"

        if [ "$QUIET_MODE" = "false" ] && [ "$JSON_OUTPUT" = "false" ]; then
            echo "$matches" | head -5 | while read -r file; do
                echo "      - $file"
            done
            [ "$suspicious_count" -gt 5 ] && echo "      ... and $((suspicious_count - 5)) more"
        fi
    else
        add_success "No suspicious code patterns detected"
    fi

    # Check for common webshell filenames
    local webshells="c99.php|r57.php|shell.php|webshell.php|backdoor.php|cmd.php"
    local shell_files
    shell_files=$(find "$directory_public" -type f \( -name "c99.php" -o -name "r57.php" -o -name "shell.php" -o -name "webshell.php" -o -name "backdoor.php" -o -name "cmd.php" \) 2>/dev/null || true)

    if [ -n "$shell_files" ]; then
        add_issue "CRITICAL" "files" "Potential webshell files detected" "Investigate and remove immediately"
    fi
}

# Check server configuration
check_server() {
    print_section "SERVER"

    # Check PHP version
    local php_version
    php_version=$(php -v 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "unknown")

    if [ "$php_version" != "unknown" ]; then
        local major_version
        major_version=$(echo "$php_version" | cut -d. -f1)

        if [ "$major_version" -lt 8 ]; then
            add_issue "WARNING" "server" "PHP $php_version is outdated" "Upgrade to PHP 8.0 or higher"
        else
            add_success "PHP version $php_version is supported"
        fi
    fi

    # Check if site uses HTTPS (from config)
    if echo "$site_url" | grep -q "^https://"; then
        add_success "Site configured to use HTTPS"
    else
        add_issue "WARNING" "server" "Site not using HTTPS" "Enable HTTPS with SSL certificate"
    fi

    # Check for exposed sensitive files
    local sensitive_files=".git .env .htpasswd wp-config.php.bak wp-config.php.old"
    for file in $sensitive_files; do
        if [ -e "${directory_public}/../$file" ] || [ -e "${directory_public}/$file" ]; then
            add_issue "WARNING" "server" "Sensitive file/directory may be exposed: $file" "Remove or protect from web access"
        fi
    done
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Header
if [ "$QUIET_MODE" = "false" ] && [ "$JSON_OUTPUT" = "false" ]; then
    echo ""
    echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${NORMAL}"
    echo "${CYAN}║              WPASK SECURITY SCAN                             ║${NORMAL}"
    echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${NORMAL}"
    echo ""
    echo "Target: ${directory_public}"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Run checks
should_run_check "checksums" && check_checksums
should_run_check "plugins" && check_plugins
should_run_check "themes" && check_themes
should_run_check "permissions" && check_permissions
should_run_check "config" && check_config
should_run_check "files" && check_files
should_run_check "server" && check_server

# Calculate final score
[ "$TOTAL_SCORE" -lt 0 ] && TOTAL_SCORE=0
GRADE=$(get_grade "$TOTAL_SCORE")

# Output results
if [ "$JSON_OUTPUT" = "true" ]; then
    # Remove trailing comma from results
    RESULTS=$(echo "$RESULTS" | sed 's/,$//')

    cat << EOF
{
  "scan_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "target": "$directory_public",
  "score": $TOTAL_SCORE,
  "grade": "$GRADE",
  "summary": {
    "critical": $CRITICAL_COUNT,
    "warning": $WARNING_COUNT,
    "info": $INFO_COUNT
  },
  "issues": [$RESULTS]
}
EOF
elif [ "$QUIET_MODE" = "false" ]; then
    echo ""
    echo "${CYAN}══════════════════════════════════════════════════════════════${NORMAL}"
    echo ""

    # Score display with color
    local score_color="$GREEN"
    [ "$TOTAL_SCORE" -lt 80 ] && score_color="$YELLOW"
    [ "$TOTAL_SCORE" -lt 60 ] && score_color="$RED"

    echo "  ${BOLD}Security Score: ${score_color}${GRADE} (${TOTAL_SCORE}/100)${NORMAL}"
    echo ""

    # Summary
    [ "$CRITICAL_COUNT" -gt 0 ] && echo "  ${RED}CRITICAL: $CRITICAL_COUNT issue(s)${NORMAL}"
    [ "$WARNING_COUNT" -gt 0 ] && echo "  ${YELLOW}WARNING: $WARNING_COUNT issue(s)${NORMAL}"
    [ "$INFO_COUNT" -gt 0 ] && echo "  ${CYAN}INFO: $INFO_COUNT suggestion(s)${NORMAL}"

    if [ "$CRITICAL_COUNT" -eq 0 ] && [ "$WARNING_COUNT" -eq 0 ]; then
        echo "  ${GREEN}No significant security issues found!${NORMAL}"
    fi

    echo ""

    # Recommendations
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo "${YELLOW}RECOMMENDED ACTIONS:${NORMAL}"
        echo "  1. Address all CRITICAL issues immediately"
        echo "  2. Review and fix WARNING items"
        echo "  3. Run this scan again after remediation"
        echo ""
    fi
fi

# Exit code based on critical issues
if [ "$CRITICAL_COUNT" -gt 0 ]; then
    exit 1
fi

exit 0
