#!/bin/sh
# WPASK Self-Update Script
#
# Checks for updates and installs the latest version while preserving
# user configuration and data.
#
# Usage:
#   ./cli/self-update.sh              # Check and update if available
#   ./cli/self-update.sh --check      # Only check for updates
#   ./cli/self-update.sh --force      # Force update even if up-to-date

set -eu

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Update sources (in order of preference)
PRIMARY_SOURCE="https://repo.adjuvans.fr/wpask"
FALLBACK_SOURCE="https://github.com/adjuvans/wp-adjuvans-starter-kit"

# Colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# Logging functions
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }
fatal() { error "$1"; exit 1; }

# Show help
show_help() {
    cat <<EOF
${BOLD}WPASK Self-Update${NC}

${YELLOW}USAGE${NC}
    ./cli/self-update.sh [OPTIONS]

${YELLOW}OPTIONS${NC}
    -c, --check     Only check for updates, don't install
    -f, --force     Force update even if already up-to-date
    -s, --source    Specify update source (repo or github)
    -h, --help      Show this help message

${YELLOW}EXAMPLES${NC}
    # Check and update if available
    ./cli/self-update.sh

    # Only check for updates
    ./cli/self-update.sh --check

    # Force reinstall current version
    ./cli/self-update.sh --force

    # Use GitHub as source
    ./cli/self-update.sh --source github

${YELLOW}PRESERVED FILES${NC}
    The following are preserved during updates:
    - config/config.sh (your configuration)
    - wordpress/ (WordPress installation)
    - save/ (backups)
    - logs/ (log files)
    - .env (environment variables)
EOF
}

# Check for download tool
check_download_tool() {
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget"
    else
        fatal "Neither curl nor wget found. Please install one of them."
    fi
}

# Download file
download() {
    local url="$1"
    local output="$2"

    if [ "$DOWNLOAD_CMD" = "curl" ]; then
        curl -fsSL "$url" -o "$output" 2>/dev/null
    else
        wget -q "$url" -O "$output" 2>/dev/null
    fi
}

# Download to stdout
download_stdout() {
    local url="$1"

    if [ "$DOWNLOAD_CMD" = "curl" ]; then
        curl -fsSL "$url" 2>/dev/null
    else
        wget -qO- "$url" 2>/dev/null
    fi
}

# Get current version
get_current_version() {
    if [ -f "${PROJECT_ROOT}/VERSION" ]; then
        cat "${PROJECT_ROOT}/VERSION" | tr -d '\n'
    else
        echo "unknown"
    fi
}

# Get latest version from repo.adjuvans.fr
get_latest_version_repo() {
    download_stdout "${PRIMARY_SOURCE}/latest.txt" 2>/dev/null | tr -d '\n'
}

# Get latest version from GitHub
get_latest_version_github() {
    local api_url="https://api.github.com/repos/adjuvans/wp-adjuvans-starter-kit/releases/latest"
    download_stdout "$api_url" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/'
}

# Compare versions (returns 0 if v1 < v2)
version_lt() {
    local v1="$1"
    local v2="$2"

    # Remove 'v' prefix if present
    v1=$(echo "$v1" | sed 's/^v//')
    v2=$(echo "$v2" | sed 's/^v//')

    # Compare using sort -V if available
    if printf '%s\n%s\n' "$v1" "$v2" | sort -V 2>/dev/null | head -1 | grep -q "^${v1}$"; then
        [ "$v1" != "$v2" ]
    else
        # Fallback: simple string comparison
        [ "$v1" != "$v2" ] && [ "$(printf '%s\n%s\n' "$v1" "$v2" | sort | head -1)" = "$v1" ]
    fi
}

# Perform the update
do_update() {
    local version="$1"
    local source="$2"
    local temp_dir

    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT

    # Determine download URL
    local download_url
    if [ "$source" = "repo" ]; then
        download_url="${PRIMARY_SOURCE}/wpask-${version}.tar.gz"
    else
        download_url="${FALLBACK_SOURCE}/archive/refs/tags/v${version}.tar.gz"
    fi

    info "Downloading WPASK v${version}..."
    local tarball="${temp_dir}/wpask.tar.gz"
    if ! download "$download_url" "$tarball"; then
        fatal "Failed to download update from $download_url"
    fi
    success "Downloaded v${version}"

    # Extract to temp directory
    info "Extracting..."
    tar -xzf "$tarball" -C "$temp_dir"

    # Find extracted directory
    local extracted_dir
    extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d \( -name "wpask*" -o -name "wp-adjuvans-starter-kit*" \) | head -1)
    if [ -z "$extracted_dir" ]; then
        fatal "Could not find extracted directory"
    fi

    # Backup current installation (just the cli and scripts)
    info "Backing up current installation..."
    local backup_dir="${PROJECT_ROOT}/.update-backup"
    rm -rf "$backup_dir"
    mkdir -p "$backup_dir"
    [ -d "${PROJECT_ROOT}/cli" ] && cp -r "${PROJECT_ROOT}/cli" "$backup_dir/"
    [ -d "${PROJECT_ROOT}/scripts" ] && cp -r "${PROJECT_ROOT}/scripts" "$backup_dir/"
    [ -f "${PROJECT_ROOT}/Makefile" ] && cp "${PROJECT_ROOT}/Makefile" "$backup_dir/"
    [ -f "${PROJECT_ROOT}/VERSION" ] && cp "${PROJECT_ROOT}/VERSION" "$backup_dir/"

    # Update files (preserving user data)
    info "Updating files..."

    # Update CLI scripts
    if [ -d "${extracted_dir}/cli" ]; then
        rm -rf "${PROJECT_ROOT}/cli"
        cp -r "${extracted_dir}/cli" "${PROJECT_ROOT}/"
        chmod +x "${PROJECT_ROOT}"/cli/*.sh 2>/dev/null || true
        chmod +x "${PROJECT_ROOT}"/cli/lib/*.sh 2>/dev/null || true
    fi

    # Update scripts directory
    if [ -d "${extracted_dir}/scripts" ]; then
        rm -rf "${PROJECT_ROOT}/scripts"
        cp -r "${extracted_dir}/scripts" "${PROJECT_ROOT}/"
        chmod +x "${PROJECT_ROOT}"/scripts/*.sh 2>/dev/null || true
    fi

    # Update Makefile
    [ -f "${extracted_dir}/Makefile" ] && cp "${extracted_dir}/Makefile" "${PROJECT_ROOT}/"

    # Update VERSION
    [ -f "${extracted_dir}/VERSION" ] && cp "${extracted_dir}/VERSION" "${PROJECT_ROOT}/"

    # Update README (optional)
    [ -f "${extracted_dir}/README.md" ] && cp "${extracted_dir}/README.md" "${PROJECT_ROOT}/"

    # Update config sample (don't overwrite user config)
    if [ -f "${extracted_dir}/config/config.sample.sh" ]; then
        mkdir -p "${PROJECT_ROOT}/config"
        cp "${extracted_dir}/config/config.sample.sh" "${PROJECT_ROOT}/config/"
    fi

    # Cleanup backup
    rm -rf "$backup_dir"

    success "Update complete!"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local check_only="false"
    local force_update="false"
    local preferred_source="repo"

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                check_only="true"
                shift
                ;;
            -f|--force)
                force_update="true"
                shift
                ;;
            -s|--source)
                preferred_source="$2"
                shift 2
                ;;
            --source=*)
                preferred_source="${1#*=}"
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo ""
    echo "${CYAN}${BOLD}WPASK Update Check${NC}"
    echo ""

    check_download_tool

    # Get current version
    CURRENT_VERSION=$(get_current_version)
    info "Current version: ${BOLD}${CURRENT_VERSION}${NC}"

    # Get latest version
    info "Checking for updates..."
    LATEST_VERSION=""
    UPDATE_SOURCE=""

    if [ "$preferred_source" = "repo" ]; then
        LATEST_VERSION=$(get_latest_version_repo)
        if [ -n "$LATEST_VERSION" ]; then
            UPDATE_SOURCE="repo"
        else
            warn "Could not reach repo.adjuvans.fr, trying GitHub..."
            LATEST_VERSION=$(get_latest_version_github)
            UPDATE_SOURCE="github"
        fi
    else
        LATEST_VERSION=$(get_latest_version_github)
        UPDATE_SOURCE="github"
    fi

    if [ -z "$LATEST_VERSION" ]; then
        fatal "Could not determine latest version. Check your internet connection."
    fi

    info "Latest version: ${BOLD}${LATEST_VERSION}${NC} (from ${UPDATE_SOURCE})"

    # Compare versions
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ "$force_update" = "false" ]; then
        echo ""
        success "You are running the latest version!"
        echo ""
        exit 0
    fi

    UPDATE_AVAILABLE="false"
    if version_lt "$CURRENT_VERSION" "$LATEST_VERSION"; then
        UPDATE_AVAILABLE="true"
    fi

    if [ "$check_only" = "true" ]; then
        echo ""
        if [ "$UPDATE_AVAILABLE" = "true" ]; then
            echo "${YELLOW}${BOLD}Update available: v${CURRENT_VERSION} → v${LATEST_VERSION}${NC}"
            echo ""
            echo "Run ${GREEN}make update${NC} or ${GREEN}./cli/self-update.sh${NC} to update."
        else
            success "You are running the latest version!"
        fi
        echo ""
        exit 0
    fi

    # Confirm update
    if [ "$force_update" = "false" ] && [ "$UPDATE_AVAILABLE" = "false" ]; then
        echo ""
        success "Already up-to-date. Use --force to reinstall."
        echo ""
        exit 0
    fi

    echo ""
    if [ "$UPDATE_AVAILABLE" = "true" ]; then
        echo "${YELLOW}${BOLD}Update available: v${CURRENT_VERSION} → v${LATEST_VERSION}${NC}"
    else
        echo "${YELLOW}${BOLD}Reinstalling v${LATEST_VERSION}${NC}"
    fi
    echo ""
    echo "${YELLOW}The following will be updated:${NC}"
    echo "  - cli/ (CLI scripts)"
    echo "  - scripts/ (build scripts)"
    echo "  - Makefile"
    echo "  - VERSION"
    echo "  - README.md"
    echo ""
    echo "${GREEN}The following will be preserved:${NC}"
    echo "  - config/config.sh"
    echo "  - wordpress/"
    echo "  - save/"
    echo "  - logs/"
    echo "  - .env"
    echo ""
    printf "${YELLOW}Proceed with update? (y/N): ${NC}"
    read -r confirm

    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        info "Update cancelled"
        exit 0
    fi

    echo ""
    do_update "$LATEST_VERSION" "$UPDATE_SOURCE"

    echo ""
    echo "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo "${GREEN}${BOLD}  WPASK updated to v${LATEST_VERSION}!${NC}"
    echo "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${YELLOW}What's new:${NC}"
    echo "  See CHANGELOG.md for details"
    echo ""
}

main "$@"
