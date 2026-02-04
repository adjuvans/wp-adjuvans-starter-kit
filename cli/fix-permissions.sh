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

# Colors (bright/pastel variants for better readability)
if [ -t 1 ]; then
    RED='\033[0;91m'
    GREEN='\033[0;92m'
    YELLOW='\033[0;93m'
    BLUE='\033[0;94m'
    CYAN='\033[0;96m'
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

# Count setgid/setuid files and directories separately
info "Scanning for setgid/setuid bits..."

SETGID_DIRS=$(find "$TARGET_DIR" -type d -perm /6000 2>/dev/null | wc -l | tr -d ' ')
SETGID_FILES=$(find "$TARGET_DIR" -type f -perm /6000 2>/dev/null | wc -l | tr -d ' ')

# Only FILES with setgid/setuid are a real problem
# Directories with setgid are common on shared hosting and usually harmless
HAS_FILE_ISSUES="false"
if [ "$SETGID_FILES" -gt 0 ]; then
    HAS_FILE_ISSUES="true"
fi

if [ "$SETGID_DIRS" -gt 0 ] || [ "$SETGID_FILES" -gt 0 ]; then
    if [ "$SETGID_FILES" -gt 0 ]; then
        error "Found ${SETGID_FILES} FILES with setgid/setuid bits (CRITICAL):"
    fi
    if [ "$SETGID_DIRS" -gt 0 ]; then
        info "Found ${SETGID_DIRS} directories with setgid bit"
        echo "  ${YELLOW}Note: Directory setgid is common on shared hosting (Infomaniak, OVH)${NC}"
        echo "  ${YELLOW}      and is usually harmless - it's set by the hosting provider.${NC}"
    fi
    echo ""

    # Only show files if there are problematic files
    if [ "$SETGID_FILES" -gt 0 ]; then
        echo "${RED}Files with setgid/setuid (MUST FIX):${NC}"
        find "$TARGET_DIR" -type f -perm /6000 -ls 2>/dev/null | head -20 | while read -r line; do
            echo "  $line"
        done
        echo ""
    fi
else
    success "No setgid/setuid bits found"
fi

# Check-only mode: exit here
if [ "$CHECK_ONLY" = "true" ]; then
    echo ""
    if [ "$HAS_FILE_ISSUES" = "true" ]; then
        error "Found ${SETGID_FILES} file permission issues that need fixing"
        echo ""
        echo "Run without --check to fix: ${GREEN}./cli/fix-permissions.sh${NC}"
        exit 1
    else
        if [ "$SETGID_DIRS" -gt 0 ]; then
            success "No critical permission issues (directory setgid is normal on shared hosting)"
        else
            success "All permissions are correct"
        fi
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

# Step 6: Verify no setgid/setuid remains on FILES
echo ""
info "Verifying..."
REMAINING_FILES=$(find "$TARGET_DIR" -type f -perm /6000 2>/dev/null | wc -l | tr -d ' ')
REMAINING_DIRS=$(find "$TARGET_DIR" -type d -perm /6000 2>/dev/null | wc -l | tr -d ' ')

if [ "$REMAINING_FILES" -gt 0 ]; then
    error "${REMAINING_FILES} files still have setgid/setuid bits (may require root access)"
    find "$TARGET_DIR" -type f -perm /6000 -ls 2>/dev/null | head -10
elif [ "$REMAINING_DIRS" -gt 0 ]; then
    info "${REMAINING_DIRS} directories still have setgid bit (normal on shared hosting)"
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
if [ "$REMAINING_FILES" -eq 0 ]; then
    echo "  ${GREEN}setgid/setuid:${NC}  REMOVED from files"
fi
echo ""

if [ "$REMAINING_FILES" -eq 0 ]; then
    success "Your site should now work on shared hosting (Infomaniak, OVH, etc.)"
    if [ "$REMAINING_DIRS" -gt 0 ]; then
        echo ""
        info "Directory setgid bits are managed by your hosting provider and are harmless."
    fi
else
    error "Some file permissions could not be fixed. Contact hosting support."
fi

echo ""
