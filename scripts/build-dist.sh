#!/bin/sh
# Build distribution package for WP Adjuvans Starter Kit
#
# Creates a minimal tarball with only essential files for installation.
# Output: dist/wpask-<version>.tar.gz

set -eu

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read version
VERSION=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
DIST_NAME="wpask-${VERSION}"
DIST_DIR="${PROJECT_ROOT}/dist"
ARCHIVE_NAME="${DIST_NAME}.tar.gz"

# Colors
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    CYAN=''
    NC=''
fi

info() { printf "${CYAN}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }

echo ""
echo "${GREEN}Building WPASK distribution v${VERSION}${NC}"
echo ""

# Clean and create dist directory
info "Cleaning dist directory..."
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}/${DIST_NAME}"

# Copy essential files
info "Copying essential files..."

# CLI scripts (core functionality)
cp -r "${PROJECT_ROOT}/cli" "${DIST_DIR}/${DIST_NAME}/"

# Configuration template
mkdir -p "${DIST_DIR}/${DIST_NAME}/config"
cp "${PROJECT_ROOT}/config/config.sample.sh" "${DIST_DIR}/${DIST_NAME}/config/"

# Core files
# Use simplified Makefile for distribution (without dev commands)
cp "${PROJECT_ROOT}/Makefile.dist" "${DIST_DIR}/${DIST_NAME}/Makefile"
cp "${PROJECT_ROOT}/VERSION" "${DIST_DIR}/${DIST_NAME}/"
cp "${PROJECT_ROOT}/README.md" "${DIST_DIR}/${DIST_NAME}/"
cp "${PROJECT_ROOT}/install.sh" "${DIST_DIR}/${DIST_NAME}/"

# Optional files (if they exist)
[ -f "${PROJECT_ROOT}/wp-cli.yml.sample" ] && cp "${PROJECT_ROOT}/wp-cli.yml.sample" "${DIST_DIR}/${DIST_NAME}/"
[ -f "${PROJECT_ROOT}/CHANGELOG.md" ] && cp "${PROJECT_ROOT}/CHANGELOG.md" "${DIST_DIR}/${DIST_NAME}/"

# Create empty directories that are expected
mkdir -p "${DIST_DIR}/${DIST_NAME}/logs"
mkdir -p "${DIST_DIR}/${DIST_NAME}/save"
mkdir -p "${DIST_DIR}/${DIST_NAME}/wordpress"

# Add .gitkeep files for empty dirs
touch "${DIST_DIR}/${DIST_NAME}/logs/.gitkeep"
touch "${DIST_DIR}/${DIST_NAME}/save/.gitkeep"
touch "${DIST_DIR}/${DIST_NAME}/wordpress/.gitkeep"

# Set permissions
# CRITICAL: Sanitize all permissions first (remove setgid/setuid bits)
# This prevents 403 errors on shared hosting (Apache/PHP-FPM like Infomaniak)
info "Sanitizing permissions (removing setgid/setuid)..."
find "${DIST_DIR}/${DIST_NAME}" -type d -exec chmod 755 {} \;
find "${DIST_DIR}/${DIST_NAME}" -type f -exec chmod 644 {} \;

# Re-apply execute bit on scripts
info "Setting script permissions..."
chmod +x "${DIST_DIR}/${DIST_NAME}"/cli/*.sh 2>/dev/null || true
chmod +x "${DIST_DIR}/${DIST_NAME}"/cli/lib/*.sh 2>/dev/null || true
chmod +x "${DIST_DIR}/${DIST_NAME}/install.sh"

# Create tarball
# COPYFILE_DISABLE=1 prevents macOS extended attributes (._files, xattr) from being included
# This avoids "Ignoring unknown extended header keyword" warnings on Linux
info "Creating archive..."
cd "${DIST_DIR}"
COPYFILE_DISABLE=1 tar -czf "${ARCHIVE_NAME}" "${DIST_NAME}"

# Cleanup extracted directory (keep only tarball)
rm -rf "${DIST_DIR}/${DIST_NAME}"

# Show result
ARCHIVE_SIZE=$(ls -lh "${DIST_DIR}/${ARCHIVE_NAME}" | awk '{print $5}')
ARCHIVE_PATH="${DIST_DIR}/${ARCHIVE_NAME}"

echo ""
success "Distribution built successfully!"
echo ""
echo "${YELLOW}Archive:${NC} ${GREEN}${ARCHIVE_PATH}${NC}"
echo "${YELLOW}Size:${NC}    ${GREEN}${ARCHIVE_SIZE}${NC}"
echo "${YELLOW}Version:${NC} ${GREEN}${VERSION}${NC}"
echo ""
echo "${YELLOW}Contents:${NC}"
tar -tzf "${ARCHIVE_PATH}" | head -20
echo "..."
echo ""
echo "${YELLOW}To test:${NC}"
echo "  mkdir /tmp/wpask-test && cd /tmp/wpask-test"
echo "  tar -xzf ${ARCHIVE_PATH}"
echo "  cd ${DIST_NAME} && make check"
echo ""
