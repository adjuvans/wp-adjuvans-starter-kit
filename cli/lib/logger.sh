#!/bin/sh
# logger.sh - Structured logging utilities
# Provides functions for logging with timestamps and levels

# Load colors if available
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "${SCRIPT_DIR}/colors.sh" ]; then
    . "${SCRIPT_DIR}/colors.sh"
fi

# Log directory (can be overridden by config)
LOG_DIR="${LOG_DIR:-./logs}"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Get log file path for current date
get_log_file() {
    echo "${LOG_DIR}/$(date +%Y-%m-%d)_cli.log"
}

# Internal logging function
# Usage: _log "LEVEL" "message"
_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file=$(get_log_file)

    # Write to log file
    echo "[${timestamp}] [${level}] ${message}" >> "$log_file"
}

# Log info message
# Usage: log_info "Processing data"
log_info() {
    _log "INFO" "$*"
    if [ -n "${CYAN:-}" ]; then
        echo "${CYAN}[INFO]${NORMAL} $*"
    else
        echo "[INFO] $*"
    fi
}

# Log warning message
# Usage: log_warn "Deprecated feature used"
log_warn() {
    _log "WARN" "$*"
    if [ -n "${YELLOW:-}" ]; then
        echo "${YELLOW}[WARN]${NORMAL} $*"
    else
        echo "[WARN] $*"
    fi
}

# Log error message
# Usage: log_error "Failed to connect to database"
log_error() {
    _log "ERROR" "$*"
    if [ -n "${RED:-}" ]; then
        echo "${RED}[ERROR]${NORMAL} $*" >&2
    else
        echo "[ERROR] $*" >&2
    fi
}

# Log success message
# Usage: log_success "Installation completed"
log_success() {
    _log "SUCCESS" "$*"
    if [ -n "${GREEN:-}" ]; then
        echo "${GREEN}[✔]${NORMAL} $*"
    else
        echo "[✔] $*"
    fi
}

# Log debug message (only if DEBUG=1)
# Usage: DEBUG=1 ./script.sh
log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        _log "DEBUG" "$*"
        if [ -n "${MAGENTA:-}" ]; then
            echo "${MAGENTA}[DEBUG]${NORMAL} $*"
        else
            echo "[DEBUG] $*"
        fi
    fi
}

# Log fatal error and exit
# Usage: log_fatal "Critical error occurred"
log_fatal() {
    _log "FATAL" "$*"
    if [ -n "${RED:-}" ]; then
        echo "${RED}${BOLD}[FATAL]${NORMAL} $*" >&2
    else
        echo "[FATAL] $*" >&2
    fi
    exit 1
}

# Print separator line
log_separator() {
    echo "---"
    _log "---" "---"
}

# Print section header
# Usage: log_section "Database Configuration"
log_section() {
    echo ""
    echo "---"
    if [ -n "${BLUE:-}" ]; then
        echo "${BLUE}${BOLD}# $*${NORMAL}"
    else
        echo "# $*"
    fi
    _log "SECTION" "$*"
}

# Clean old log files (keep last 30 days)
# Usage: log_cleanup
log_cleanup() {
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
        log_info "Old log files cleaned (kept last 30 days)"
    fi
}
