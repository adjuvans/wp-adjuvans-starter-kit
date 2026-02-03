#!/bin/sh
# WPASK Installer - Install WP Adjuvans Starter Kit
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/adjuvans/wp-adjuvans-starter-kit/main/install.sh | sh
#
# Or with a specific version:
#   curl -fsSL https://raw.githubusercontent.com/adjuvans/wp-adjuvans-starter-kit/main/install.sh | sh -s -- --version v2.2.0
#
# Or to a specific directory:
#   curl -fsSL https://raw.githubusercontent.com/adjuvans/wp-adjuvans-starter-kit/main/install.sh | sh -s -- --dir /var/www/mysite

set -eu

# Configuration
REPO_OWNER="adjuvans"
REPO_NAME="wp-adjuvans-starter-kit"
GITHUB_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"
DEFAULT_INSTALL_DIR="."

# Colors (if terminal supports it)
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

# Show banner
show_banner() {
    cat <<'EOF'

    ██╗    ██╗██████╗  █████╗ ███████╗██╗  ██╗
    ██║    ██║██╔══██╗██╔══██╗██╔════╝██║ ██╔╝
    ██║ █╗ ██║██████╔╝███████║███████╗█████╔╝
    ██║███╗██║██╔═══╝ ██╔══██║╚════██║██╔═██╗
    ╚███╔███╔╝██║     ██║  ██║███████║██║  ██╗
     ╚══╝╚══╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

    WP Adjuvans Starter Kit - Installer

EOF
}

# Show help
show_help() {
    cat <<EOF
${BOLD}WPASK Installer${NC}

${YELLOW}USAGE${NC}
    curl -fsSL ${GITHUB_URL}/raw/main/install.sh | sh
    curl -fsSL ${GITHUB_URL}/raw/main/install.sh | sh -s -- [OPTIONS]

${YELLOW}OPTIONS${NC}
    -d, --dir DIR       Installation directory (default: current directory)
    -v, --version VER   Install specific version (e.g., v2.2.0)
    -b, --branch BRANCH Install from branch (e.g., dev, main)
    -h, --help          Show this help message

${YELLOW}EXAMPLES${NC}
    # Install latest release to current directory
    curl -fsSL ${GITHUB_URL}/raw/main/install.sh | sh

    # Install to specific directory
    curl -fsSL ${GITHUB_URL}/raw/main/install.sh | sh -s -- --dir /var/www/mysite

    # Install specific version
    curl -fsSL ${GITHUB_URL}/raw/main/install.sh | sh -s -- --version v2.2.0

    # Install from dev branch
    curl -fsSL ${GITHUB_URL}/raw/main/install.sh | sh -s -- --branch dev

EOF
}

# Check for required commands
check_requirements() {
    info "Checking requirements..."

    # Check for curl or wget
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl"
        success "curl found"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget"
        success "wget found"
    else
        fatal "Neither curl nor wget found. Please install one of them."
    fi

    # Check for tar
    if ! command -v tar >/dev/null 2>&1; then
        fatal "tar is required but not found"
    fi
    success "tar found"

    # Check for unzip (fallback)
    if command -v unzip >/dev/null 2>&1; then
        HAS_UNZIP="true"
    else
        HAS_UNZIP="false"
    fi
}

# Download file
download() {
    local url="$1"
    local output="$2"

    if [ "$DOWNLOAD_CMD" = "curl" ]; then
        curl -fsSL "$url" -o "$output"
    else
        wget -q "$url" -O "$output"
    fi
}

# Get latest release version from GitHub
get_latest_version() {
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

    if [ "$DOWNLOAD_CMD" = "curl" ]; then
        curl -fsSL "$api_url" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
    else
        wget -qO- "$api_url" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
    fi
}

# Download and extract release
install_release() {
    local version="$1"
    local install_dir="$2"
    local temp_dir

    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT

    local tarball_url="${GITHUB_URL}/archive/refs/tags/${version}.tar.gz"
    local tarball_file="${temp_dir}/wpask.tar.gz"

    info "Downloading WPASK ${version}..."
    if ! download "$tarball_url" "$tarball_file"; then
        fatal "Failed to download release ${version}"
    fi
    success "Downloaded ${version}"

    info "Extracting to ${install_dir}..."
    mkdir -p "$install_dir"

    # Extract and strip the top-level directory
    tar -xzf "$tarball_file" -C "$temp_dir"

    # Find the extracted directory (wp-adjuvans-starter-kit-X.X.X)
    local extracted_dir
    extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "${REPO_NAME}*" | head -1)

    if [ -z "$extracted_dir" ]; then
        fatal "Could not find extracted directory"
    fi

    # Copy contents to install directory
    cp -r "$extracted_dir"/* "$install_dir/"

    success "Extracted to ${install_dir}"
}

# Download and extract from branch
install_branch() {
    local branch="$1"
    local install_dir="$2"
    local temp_dir

    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT

    local tarball_url="${GITHUB_URL}/archive/refs/heads/${branch}.tar.gz"
    local tarball_file="${temp_dir}/wpask.tar.gz"

    info "Downloading WPASK from branch '${branch}'..."
    if ! download "$tarball_url" "$tarball_file"; then
        fatal "Failed to download branch ${branch}"
    fi
    success "Downloaded branch ${branch}"

    info "Extracting to ${install_dir}..."
    mkdir -p "$install_dir"

    tar -xzf "$tarball_file" -C "$temp_dir"

    local extracted_dir
    extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "${REPO_NAME}*" | head -1)

    if [ -z "$extracted_dir" ]; then
        fatal "Could not find extracted directory"
    fi

    cp -r "$extracted_dir"/* "$install_dir/"

    success "Extracted to ${install_dir}"
}

# Post-installation setup
post_install() {
    local install_dir="$1"

    info "Setting up permissions..."

    # Make scripts executable
    chmod +x "$install_dir"/cli/*.sh 2>/dev/null || true
    chmod +x "$install_dir"/cli/lib/*.sh 2>/dev/null || true
    chmod +x "$install_dir"/install.sh 2>/dev/null || true

    # Create directories
    mkdir -p "$install_dir/config" "$install_dir/logs" "$install_dir/save" "$install_dir/wordpress"

    success "Permissions set"
}

# Show completion message
show_completion() {
    local install_dir="$1"
    local version="$2"

    echo ""
    echo "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo "${GREEN}${BOLD}  WPASK ${version} installed successfully!${NC}"
    echo "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${YELLOW}Installation directory:${NC} ${GREEN}${install_dir}${NC}"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "  ${CYAN}1.${NC} cd ${install_dir}"
    echo "  ${CYAN}2.${NC} make check          # Verify dependencies"
    echo "  ${CYAN}3.${NC} make install        # Start WordPress installation wizard"
    echo ""
    echo "${YELLOW}Or adopt an existing WordPress site:${NC}"
    echo "  ${CYAN}•${NC} make adopt"
    echo ""
    echo "${YELLOW}Documentation:${NC}"
    echo "  ${CYAN}•${NC} ${GITHUB_URL}"
    echo "  ${CYAN}•${NC} make help"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local install_dir="$DEFAULT_INSTALL_DIR"
    local version=""
    local branch=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dir)
                install_dir="$2"
                shift 2
                ;;
            --dir=*)
                install_dir="${1#*=}"
                shift
                ;;
            -v|--version)
                version="$2"
                shift 2
                ;;
            --version=*)
                version="${1#*=}"
                shift
                ;;
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            --branch=*)
                branch="${1#*=}"
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    show_banner
    check_requirements

    # Resolve install directory to absolute path
    if [ "$install_dir" = "." ]; then
        install_dir="$(pwd)"
    else
        mkdir -p "$install_dir"
        install_dir="$(cd "$install_dir" && pwd)"
    fi

    # Check if directory is not empty
    if [ -d "$install_dir" ] && [ "$(ls -A "$install_dir" 2>/dev/null)" ]; then
        if [ -f "$install_dir/VERSION" ]; then
            current_version=$(cat "$install_dir/VERSION")
            warn "WPASK ${current_version} is already installed in ${install_dir}"
            printf "${YELLOW}Overwrite existing installation? (y/N): ${NC}"
            read -r confirm
            if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                info "Installation cancelled"
                exit 0
            fi
        else
            warn "Directory ${install_dir} is not empty"
            printf "${YELLOW}Continue anyway? (y/N): ${NC}"
            read -r confirm
            if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                info "Installation cancelled"
                exit 0
            fi
        fi
    fi

    # Install from branch or version
    if [ -n "$branch" ]; then
        install_branch "$branch" "$install_dir"
        version="$branch (branch)"
    else
        # Get latest version if not specified
        if [ -z "$version" ]; then
            info "Fetching latest version..."
            version=$(get_latest_version)
            if [ -z "$version" ]; then
                warn "Could not determine latest version, using 'main' branch"
                install_branch "main" "$install_dir"
                version="main (branch)"
            else
                success "Latest version: ${version}"
                install_release "$version" "$install_dir"
            fi
        else
            install_release "$version" "$install_dir"
        fi
    fi

    post_install "$install_dir"
    show_completion "$install_dir" "$version"
}

main "$@"
