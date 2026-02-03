#!/bin/sh
# Publish WPASK release to repo.adjuvans.fr
#
# Builds distribution and uploads to SFTP server.
# Requires .env file with SFTP credentials.
#
# Usage:
#   ./scripts/publish-release.sh
#   ./scripts/publish-release.sh --dry-run
#
# Environment variables (from .env):
#   SFTP_HOST     - SFTP server hostname
#   SFTP_USER     - SFTP username
#   SFTP_PASS     - SFTP password (optional if using SSH key)
#   SFTP_PATH     - Remote path for uploads (e.g., /wpask/)
#   SFTP_PORT     - SFTP port (default: 22)

set -eu

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    BOLD=''
    NC=''
fi

# Logging functions
info() { printf "${CYAN}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }
fatal() { error "$1"; exit 1; }

# Parse arguments
DRY_RUN="false"
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            cat <<EOF
${BOLD}WPASK Release Publisher${NC}

${YELLOW}USAGE${NC}
    ./scripts/publish-release.sh [OPTIONS]

${YELLOW}OPTIONS${NC}
    -n, --dry-run    Show what would be uploaded without actually uploading
    -h, --help       Show this help message

${YELLOW}ENVIRONMENT${NC}
    Requires .env file in project root with:
    - SFTP_HOST     SFTP server hostname
    - SFTP_USER     SFTP username
    - SFTP_PASS     SFTP password (optional if using SSH key)
    - SFTP_PATH     Remote path (e.g., /wpask/)
    - SFTP_PORT     SFTP port (default: 22)

${YELLOW}EXAMPLE .env${NC}
    SFTP_HOST=repo.adjuvans.fr
    SFTP_USER=wpask
    SFTP_PASS=secret
    SFTP_PATH=/wpask/
    SFTP_PORT=22
EOF
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Load environment
ENV_FILE="${PROJECT_ROOT}/.env"
if [ ! -f "$ENV_FILE" ]; then
    fatal ".env file not found. Copy .env.sample to .env and fill in your credentials."
fi

# Source .env file (POSIX-compatible)
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    case "$key" in
        \#*|"") continue ;;
    esac
    # Remove quotes from value
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    # Export the variable
    export "$key=$value"
done < "$ENV_FILE"

# Validate required variables
[ -z "${SFTP_HOST:-}" ] && fatal "SFTP_HOST not set in .env"
[ -z "${SFTP_USER:-}" ] && fatal "SFTP_USER not set in .env"
[ -z "${SFTP_PATH:-}" ] && fatal "SFTP_PATH not set in .env"

SFTP_PORT="${SFTP_PORT:-22}"

# Read version
VERSION=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
DIST_FILE="${PROJECT_ROOT}/dist/wpask-${VERSION}.tar.gz"

echo ""
echo "${GREEN}${BOLD}WPASK Release Publisher${NC}"
echo ""

# Step 1: Build distribution
info "Building distribution..."
if [ "$DRY_RUN" = "true" ]; then
    info "[DRY-RUN] Would run: ./scripts/build-dist.sh"
    if [ ! -f "$DIST_FILE" ]; then
        warn "Distribution file not found: $DIST_FILE"
        warn "Run without --dry-run to build it"
    fi
else
    "${SCRIPT_DIR}/build-dist.sh"
fi

if [ ! -f "$DIST_FILE" ] && [ "$DRY_RUN" = "false" ]; then
    fatal "Distribution file not found: $DIST_FILE"
fi

# Step 2: Create version manifest
MANIFEST_FILE="${PROJECT_ROOT}/dist/latest.txt"
VERSION_JSON="${PROJECT_ROOT}/dist/version.json"

info "Creating version manifest..."
if [ "$DRY_RUN" = "false" ]; then
    echo "$VERSION" > "$MANIFEST_FILE"
    cat > "$VERSION_JSON" <<EOF
{
  "version": "${VERSION}",
  "file": "wpask-${VERSION}.tar.gz",
  "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "sha256": "$(shasum -a 256 "$DIST_FILE" | cut -d' ' -f1)"
}
EOF
    success "Created version manifest"
else
    info "[DRY-RUN] Would create latest.txt and version.json"
fi

# Step 3: Upload via SFTP
info "Uploading to ${SFTP_HOST}:${SFTP_PATH}..."

# Check for required tools
if command -v sshpass >/dev/null 2>&1; then
    HAS_SSHPASS="true"
else
    HAS_SSHPASS="false"
fi

if command -v sftp >/dev/null 2>&1; then
    HAS_SFTP="true"
elif command -v lftp >/dev/null 2>&1; then
    HAS_LFTP="true"
else
    fatal "Neither sftp nor lftp found. Please install one of them."
fi

# Build SFTP commands
SFTP_COMMANDS=$(cat <<EOF
cd ${SFTP_PATH}
put ${DIST_FILE}
put ${MANIFEST_FILE}
put ${VERSION_JSON}
bye
EOF
)

if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "${YELLOW}[DRY-RUN] Would upload:${NC}"
    echo "  - wpask-${VERSION}.tar.gz"
    echo "  - latest.txt"
    echo "  - version.json"
    echo ""
    echo "${YELLOW}To: ${SFTP_HOST}:${SFTP_PATH}${NC}"
    echo ""
else
    # Use lftp if available (better for scripting with passwords)
    if [ "${HAS_LFTP:-false}" = "true" ]; then
        if [ -n "${SFTP_PASS:-}" ]; then
            lftp -u "${SFTP_USER},${SFTP_PASS}" -p "${SFTP_PORT}" "sftp://${SFTP_HOST}" <<EOF
cd ${SFTP_PATH}
put ${DIST_FILE}
put ${MANIFEST_FILE}
put ${VERSION_JSON}
bye
EOF
        else
            lftp -u "${SFTP_USER}," -p "${SFTP_PORT}" "sftp://${SFTP_HOST}" <<EOF
cd ${SFTP_PATH}
put ${DIST_FILE}
put ${MANIFEST_FILE}
put ${VERSION_JSON}
bye
EOF
        fi
    else
        # Use sftp with sshpass if password provided
        if [ -n "${SFTP_PASS:-}" ] && [ "$HAS_SSHPASS" = "true" ]; then
            echo "$SFTP_COMMANDS" | sshpass -p "${SFTP_PASS}" sftp -oPort="${SFTP_PORT}" -oBatchMode=no "${SFTP_USER}@${SFTP_HOST}"
        else
            # Rely on SSH key authentication
            echo "$SFTP_COMMANDS" | sftp -oPort="${SFTP_PORT}" "${SFTP_USER}@${SFTP_HOST}"
        fi
    fi

    success "Upload complete"
fi

# Summary
echo ""
echo "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
if [ "$DRY_RUN" = "true" ]; then
    echo "${YELLOW}${BOLD}  DRY RUN - No files were uploaded${NC}"
else
    echo "${GREEN}${BOLD}  WPASK v${VERSION} published successfully!${NC}"
fi
echo "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "${YELLOW}Download URL:${NC}"
echo "  https://${SFTP_HOST}${SFTP_PATH}wpask-${VERSION}.tar.gz"
echo ""
echo "${YELLOW}Latest version check:${NC}"
echo "  https://${SFTP_HOST}${SFTP_PATH}latest.txt"
echo "  https://${SFTP_HOST}${SFTP_PATH}version.json"
echo ""
