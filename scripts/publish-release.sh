#!/bin/sh
# Publish WPASK release to repo.adjuvans.fr
#
# Builds distribution and uploads to FTP/FTPS server.
# Requires .env file with FTP credentials.
#
# Usage:
#   ./scripts/publish-release.sh
#   ./scripts/publish-release.sh --dry-run
#
# Environment variables (from .env):
#   FTP_HOST      - FTP server hostname
#   FTP_USER      - FTP username
#   FTP_PASS      - FTP password
#   FTP_PATH      - Remote path for uploads (e.g., /wpask/)
#   FTP_PORT      - FTP port (default: 21)

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
    - FTP_HOST      FTP server hostname
    - FTP_USER      FTP username
    - FTP_PASS      FTP password
    - FTP_PATH      Remote path (e.g., /wpask/)
    - FTP_PORT      FTP port (default: 21)

${YELLOW}EXAMPLE .env${NC}
    FTP_HOST=repo.adjuvans.fr
    FTP_USER=wpask
    FTP_PASS=secret
    FTP_PATH=/wpask/
    FTP_PORT=21
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
[ -z "${FTP_HOST:-}" ] && fatal "FTP_HOST not set in .env"
[ -z "${FTP_USER:-}" ] && fatal "FTP_USER not set in .env"
[ -z "${FTP_PASS:-}" ] && fatal "FTP_PASS not set in .env"
[ -z "${FTP_PATH:-}" ] && fatal "FTP_PATH not set in .env"

FTP_PORT="${FTP_PORT:-21}"

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

# Step 3: Upload via FTP (with TLS)
info "Uploading to ${FTP_HOST}:${FTP_PATH}..."

# Check for lftp (required for FTP/FTPS)
if ! command -v lftp >/dev/null 2>&1; then
    fatal "lftp is required for FTP uploads. Install with: brew install lftp (macOS) or apt install lftp (Linux)"
fi

if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "${YELLOW}[DRY-RUN] Would upload:${NC}"
    echo "  - wpask-${VERSION}.tar.gz"
    echo "  - latest.txt"
    echo "  - version.json"
    echo ""
    echo "${YELLOW}To: ftp://${FTP_HOST}:${FTP_PORT}${FTP_PATH}${NC}"
    echo ""
else
    info "Using lftp..."

    # Upload using lftp
    # Note: Use ftp:// with ssl-force for explicit TLS (AUTH TLS)
    lftp -u "${FTP_USER},${FTP_PASS}" "ftp://${FTP_HOST}:${FTP_PORT}" <<LFTP_EOF
set ssl:verify-certificate no
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ftp:ssl-allow true
set ftp:passive-mode true
set net:timeout 10
set net:max-retries 2
set net:reconnect-interval-base 5
debug 3
cd ${FTP_PATH}
put ${DIST_FILE}
put ${MANIFEST_FILE}
put ${VERSION_JSON}
bye
LFTP_EOF

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
echo "  https://${FTP_HOST}${FTP_PATH}wpask-${VERSION}.tar.gz"
echo ""
echo "${YELLOW}Latest version check:${NC}"
echo "  https://${FTP_HOST}${FTP_PATH}latest.txt"
echo "  https://${FTP_HOST}${FTP_PATH}version.json"
echo ""
