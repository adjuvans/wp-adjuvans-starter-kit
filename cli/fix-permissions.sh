#!/bin/sh
# fix-permissions.sh - Fix WordPress permissions for shared hosting
#
# Use this script after deployment if you get 403 errors on shared hosting
# (Infomaniak, OVH, o2switch, etc.)
#
# Safe permissions for Apache/PHP-FPM:
#   - Directories: 755 (rwxr-xr-x)
#   - Files: 644 (rw-r--r--)
#   - wp-config.php: 640 (rw-r-----)
#   - NO setgid (2xxx) or setuid (4xxx)
#
# Usage:
#   ./cli/fix-permissions.sh              # Fix WordPress directory
#   ./cli/fix-permissions.sh --check      # Check only, don't fix
#   ./cli/fix-permissions.sh --all        # Fix entire project

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

# Logging
info() { printf "${CYAN}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# Options
CHECK_ONLY="false"
FIX_ALL="false"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            cat <<EOF
${BOLD}fix-permissions.sh${NC} - Fix WordPress permissions for shared hosting

${YELLOW}USAGE${NC}
    ./cli/fix-permissions.sh [OPTIONS]

${YELLOW}OPTIONS${NC}
    -h, --help      Show this help message
    -c, --check     Check only, don't fix (exit 1 if issues found)
    -a, --all       Fix entire project directory (not just WordPress)

${YELLOW}PERMISSIONS APPLIED${NC}
    Directories:    755 (rwxr-xr-x)
    Files:          644 (rw-r--r--)
    wp-config.php:  640 (rw-r-----)
    Scripts (.sh):  755 (rwxr-xr-x)

${YELLOW}SPECIAL BITS REMOVED${NC}
    setgid (2xxx):  Causes 403 errors on Apache
    setuid (4xxx):  Security risk, not needed

${YELLOW}EXAMPLES${NC}
    ./cli/fix-permissions.sh              # Fix WordPress
    ./cli/fix-permissions.sh --check      # Check only
    ./cli/fix-permissions.sh --all        # Fix entire project
EOF
            exit 0
            ;;
        -c|--check)
            CHECK_ONLY="true"
            shift
            ;;
        -a|--all)
            FIX_ALL="true"
            shift
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Load config if available
CONFIG_FILE="${PROJECT_ROOT}/config/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    WP_DIR="${directory_public:-${PROJECT_ROOT}/wordpress}"
else
    WP_DIR="${PROJECT_ROOT}/wordpress"
fi

# Determine target directory
if [ "$FIX_ALL" = "true" ]; then
    TARGET_DIR="$PROJECT_ROOT"
    TARGET_NAME="entire project"
else
    TARGET_DIR="$WP_DIR"
    TARGET_NAME="WordPress directory"
fi

# Check if target exists
if [ ! -d "$TARGET_DIR" ]; then
    error "Target directory not found: ${TARGET_DIR}"
    exit 1
fi

echo ""
echo "${CYAN}${BOLD}WordPress Permissions Fixer${NC}"
echo "${CYAN}Compatible with: Infomaniak, OVH, o2switch, etc.${NC}"
echo ""

info "Target: ${TARGET_DIR}"
info "Mode: $([ "$CHECK_ONLY" = "true" ] && echo "Check only" || echo "Fix permissions")"
echo ""

# Count setgid/setuid files
info "Scanning for setgid/setuid bits..."

SETGID_DIRS=$(find "$TARGET_DIR" -type d -perm /6000 2>/dev/null | wc -l | tr -d ' ')
SETGID_FILES=$(find "$TARGET_DIR" -type f -perm /6000 2>/dev/null | wc -l | tr -d ' ')
TOTAL_ISSUES=$((SETGID_DIRS + SETGID_FILES))

if [ "$TOTAL_ISSUES" -gt 0 ]; then
    warn "Found ${TOTAL_ISSUES} items with setgid/setuid bits:"
    echo ""
    echo "  Directories with setgid: ${SETGID_DIRS}"
    echo "  Files with setgid/setuid: ${SETGID_FILES}"
    echo ""

    if [ "$TOTAL_ISSUES" -le 20 ]; then
        echo "${YELLOW}Affected items:${NC}"
        find "$TARGET_DIR" -perm /6000 -ls 2>/dev/null | while read -r line; do
            echo "  $line"
        done
        echo ""
    else
        echo "${YELLOW}First 20 affected items:${NC}"
        find "$TARGET_DIR" -perm /6000 -ls 2>/dev/null | head -20 | while read -r line; do
            echo "  $line"
        done
        echo "  ... and $((TOTAL_ISSUES - 20)) more"
        echo ""
    fi
else
    success "No setgid/setuid bits found"
fi

# Check-only mode: exit here
if [ "$CHECK_ONLY" = "true" ]; then
    echo ""
    if [ "$TOTAL_ISSUES" -gt 0 ]; then
        error "Found ${TOTAL_ISSUES} permission issues"
        echo ""
        echo "Run without --check to fix: ${GREEN}./cli/fix-permissions.sh${NC}"
        exit 1
    else
        success "All permissions are correct"
        exit 0
    fi
fi

# Fix permissions
echo "${CYAN}Fixing permissions...${NC}"
echo ""

# Step 1: Fix directory permissions (755, remove setgid)
info "Setting directory permissions to 755..."
find "$TARGET_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true

# Step 2: Fix file permissions (644)
info "Setting file permissions to 644..."
find "$TARGET_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true

# Step 3: Make shell scripts executable
info "Making shell scripts executable..."
find "$TARGET_DIR" -type f -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true

# Step 4: Secure sensitive files
if [ -f "${WP_DIR}/wp-config.php" ]; then
    info "Securing wp-config.php (640)..."
    chmod 640 "${WP_DIR}/wp-config.php"
fi

if [ -f "${WP_DIR}/.htaccess" ]; then
    info "Securing .htaccess (644)..."
    chmod 644 "${WP_DIR}/.htaccess"
fi

# Step 5: Secure config directory
if [ -d "${PROJECT_ROOT}/config" ]; then
    info "Securing config directory..."
    chmod 750 "${PROJECT_ROOT}/config" 2>/dev/null || true
    find "${PROJECT_ROOT}/config" -type f -exec chmod 640 {} \; 2>/dev/null || true
fi

# Step 6: Verify no setgid/setuid remains
echo ""
info "Verifying..."
REMAINING=$(find "$TARGET_DIR" -perm /6000 2>/dev/null | wc -l | tr -d ' ')

if [ "$REMAINING" -gt 0 ]; then
    warn "${REMAINING} items still have special bits (may require root access)"
    find "$TARGET_DIR" -perm /6000 -ls 2>/dev/null | head -10
else
    success "All setgid/setuid bits removed"
fi

# Summary
echo ""
echo "${GREEN}${BOLD}Permissions fixed!${NC}"
echo ""
echo "${CYAN}Summary:${NC}"
echo "  ${GREEN}Directories:${NC}    755 (rwxr-xr-x)"
echo "  ${GREEN}Files:${NC}          644 (rw-r--r--)"
echo "  ${GREEN}Scripts (.sh):${NC}  755 (rwxr-xr-x)"
echo "  ${GREEN}wp-config.php:${NC}  640 (rw-r-----)"
echo "  ${GREEN}config/*:${NC}       640 (rw-r-----)"
echo "  ${GREEN}setgid/setuid:${NC}  REMOVED"
echo ""

if [ "$REMAINING" -eq 0 ]; then
    success "Your site should now work on shared hosting (Infomaniak, OVH, etc.)"
else
    warn "Some items could not be fixed. Check permissions manually or contact hosting support."
fi

echo ""
