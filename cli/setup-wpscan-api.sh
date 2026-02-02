#!/bin/sh
# setup-wpscan-api.sh - Configure WPScan API key for vulnerability scanning
# Created for WPASK v3.0

set -eu
[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true

# =============================================================================
# SCRIPT SETUP
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
API_KEY_FILE="${CONFIG_DIR}/wpscan-api.key"

# =============================================================================
# USAGE
# =============================================================================

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Configure WPScan API key for vulnerability scanning

OPTIONS:
    -h, --help              Show this help message
    -k, --api-key KEY       Set API key directly (non-interactive)
    -c, --check             Check current API key status
    -r, --remove            Remove configured API key
    -t, --test              Test API key validity

GETTING AN API KEY:
    1. Create a free account at https://wpscan.com/register
    2. Go to your profile page
    3. Copy your API token

FREE TIER LIMITS:
    - 25 API requests per day
    - Sufficient for most personal/small sites

EXAMPLES:
    # Interactive setup
    $(basename "$0")

    # Set key directly
    $(basename "$0") --api-key "YOUR_API_KEY_HERE"

    # Check status
    $(basename "$0") --check

    # Test API key
    $(basename "$0") --test
EOF
}

# =============================================================================
# FUNCTIONS
# =============================================================================

# Check if API key is configured
check_status() {
    echo "WPScan API Key Status"
    echo "====================="
    echo ""

    if [ -f "$API_KEY_FILE" ]; then
        local key_length
        key_length=$(cat "$API_KEY_FILE" | tr -d '\n' | wc -c | tr -d ' ')

        if [ "$key_length" -gt 0 ]; then
            # Show masked key
            local masked_key
            masked_key=$(cat "$API_KEY_FILE" | tr -d '\n' | sed 's/\(.\{4\}\).*\(.\{4\}\)/\1****\2/')
            echo "Status: Configured"
            echo "Key:    $masked_key"
            echo "File:   $API_KEY_FILE"

            # Check file permissions
            local perms
            perms=$(stat -f "%Lp" "$API_KEY_FILE" 2>/dev/null || stat -c "%a" "$API_KEY_FILE" 2>/dev/null || echo "unknown")
            echo "Perms:  $perms"

            if [ "$perms" != "600" ] && [ "$perms" != "unknown" ]; then
                echo ""
                echo "WARNING: File permissions should be 600 for security"
                echo "Run: chmod 600 $API_KEY_FILE"
            fi
        else
            echo "Status: File exists but empty"
            echo "Run this script to configure your API key"
        fi
    else
        echo "Status: Not configured"
        echo ""
        echo "To configure, run: $(basename "$0")"
        echo "Or: $(basename "$0") --api-key YOUR_KEY"
    fi

    echo ""
}

# Test API key validity
test_api_key() {
    local api_key="${1:-}"

    if [ -z "$api_key" ] && [ -f "$API_KEY_FILE" ]; then
        api_key=$(cat "$API_KEY_FILE" | tr -d '\n')
    fi

    if [ -z "$api_key" ]; then
        echo "ERROR: No API key provided or configured"
        return 1
    fi

    echo "Testing API key..."

    # Test with a simple API call (WordPress latest version)
    local response
    response=$(curl -s -w "\n%{http_code}" -H "Authorization: Token token=$api_key" \
        "https://wpscan.com/api/v3/wordpresses/670" 2>/dev/null || echo "error")

    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    case "$http_code" in
        200)
            echo "SUCCESS: API key is valid"
            echo ""

            # Show remaining requests if available
            if echo "$body" | grep -q "requests_remaining"; then
                local remaining
                remaining=$(echo "$body" | grep -o '"requests_remaining":[0-9]*' | cut -d: -f2)
                echo "Daily requests remaining: $remaining"
            fi
            return 0
            ;;
        401)
            echo "ERROR: Invalid API key (Unauthorized)"
            return 1
            ;;
        429)
            echo "WARNING: Rate limit exceeded"
            echo "The API key is valid but you've hit the daily limit"
            return 0
            ;;
        *)
            echo "ERROR: API request failed (HTTP $http_code)"
            echo "Response: $body"
            return 1
            ;;
    esac
}

# Save API key securely
save_api_key() {
    local api_key="$1"

    # Validate key format (basic check)
    if [ ${#api_key} -lt 20 ]; then
        echo "ERROR: API key seems too short. Please verify your key."
        return 1
    fi

    # Create config directory if needed
    mkdir -p "$CONFIG_DIR"

    # Save key with secure permissions
    echo "$api_key" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"

    echo "API key saved to: $API_KEY_FILE"
    echo "Permissions set to: 600 (owner read/write only)"
    echo ""

    # Test the key
    echo "Validating API key..."
    if test_api_key "$api_key"; then
        echo ""
        echo "Setup complete! You can now run: ./cli/security-scan.sh"
    else
        echo ""
        echo "WARNING: API key saved but validation failed"
        echo "Please verify your API key at https://wpscan.com/profile"
    fi
}

# Remove API key
remove_api_key() {
    if [ -f "$API_KEY_FILE" ]; then
        rm -f "$API_KEY_FILE"
        echo "API key removed"
    else
        echo "No API key file found"
    fi
}

# Interactive setup
interactive_setup() {
    echo "WPScan API Key Setup"
    echo "===================="
    echo ""
    echo "To get a free API key:"
    echo "  1. Visit https://wpscan.com/register"
    echo "  2. Create an account (free)"
    echo "  3. Go to your profile page"
    echo "  4. Copy your API token"
    echo ""
    echo "Free tier includes 25 requests/day (sufficient for most users)"
    echo ""

    printf "Enter your WPScan API key (or 'q' to quit): "
    read -r api_key

    if [ "$api_key" = "q" ] || [ "$api_key" = "Q" ]; then
        echo "Setup cancelled"
        exit 0
    fi

    if [ -z "$api_key" ]; then
        echo "ERROR: No API key entered"
        exit 1
    fi

    # Remove any whitespace
    api_key=$(echo "$api_key" | tr -d ' \t\n\r')

    save_api_key "$api_key"
}

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================

ACTION="interactive"
API_KEY=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -k|--api-key)
            if [ -z "${2:-}" ]; then
                echo "ERROR: --api-key requires an argument"
                exit 1
            fi
            ACTION="set"
            API_KEY="$2"
            shift 2
            ;;
        --api-key=*)
            ACTION="set"
            API_KEY="${1#*=}"
            shift
            ;;
        -c|--check)
            ACTION="check"
            shift
            ;;
        -r|--remove)
            ACTION="remove"
            shift
            ;;
        -t|--test)
            ACTION="test"
            shift
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# =============================================================================
# MAIN EXECUTION
# =============================================================================

case "$ACTION" in
    interactive)
        interactive_setup
        ;;
    set)
        save_api_key "$API_KEY"
        ;;
    check)
        check_status
        ;;
    remove)
        remove_api_key
        ;;
    test)
        test_api_key
        ;;
esac
