#!/bin/sh
# colors.sh - Terminal colors and formatting utilities
# This library provides color variables for terminal output

# Mark as loaded to prevent double-loading
export COLORS_LOADED=1

# Check if stdout is a terminal and supports colors
if test -t 1; then
    ncolors=$(tput colors)
    if test -n "$ncolors" && test "$ncolors" -ge 8; then
        # Text formatting
        export BOLD="$(tput bold)"
        export UNDERLINE="$(tput smul)"
        export STANDOUT="$(tput smso)"
        export NORMAL="$(tput sgr0)"

        # Colors
        export BLACK="$(tput setaf 0)"
        export RED="$(tput setaf 1)"
        export GREEN="$(tput setaf 2)"
        export YELLOW="$(tput setaf 3)"
        export BLUE="$(tput setaf 4)"
        export MAGENTA="$(tput setaf 5)"
        export CYAN="$(tput setaf 6)"
        export WHITE="$(tput setaf 7)"
    else
        # No color support - use empty strings
        export BOLD=""
        export UNDERLINE=""
        export STANDOUT=""
        export NORMAL=""
        export BLACK=""
        export RED=""
        export GREEN=""
        export YELLOW=""
        export BLUE=""
        export MAGENTA=""
        export CYAN=""
        export WHITE=""
    fi
else
    # Not a terminal - disable colors
    export BOLD=""
    export UNDERLINE=""
    export STANDOUT=""
    export NORMAL=""
    export BLACK=""
    export RED=""
    export GREEN=""
    export YELLOW=""
    export BLUE=""
    export MAGENTA=""
    export CYAN=""
    export WHITE=""
fi

# Helper function to print colored text
# Usage: print_color "red" "Error message"
print_color() {
    local color="$1"
    shift
    local message="$*"

    case "$color" in
        red)     echo "${RED}${message}${NORMAL}" ;;
        green)   echo "${GREEN}${message}${NORMAL}" ;;
        yellow)  echo "${YELLOW}${message}${NORMAL}" ;;
        blue)    echo "${BLUE}${message}${NORMAL}" ;;
        magenta) echo "${MAGENTA}${message}${NORMAL}" ;;
        cyan)    echo "${CYAN}${message}${NORMAL}" ;;
        *)       echo "${message}" ;;
    esac
}

# Helper function to print section headers
# Usage: print_header "Section Title"
print_header() {
    echo ""
    echo "---"
    echo "${BLUE}${BOLD}# $*${NORMAL}"
}

# Helper function to print success messages
# Usage: print_success "Operation completed"
print_success() {
    echo "${GREEN}✔ $*${NORMAL}"
}

# Helper function to print error messages
# Usage: print_error "Something went wrong"
print_error() {
    echo "${RED}✘ $*${NORMAL}"
}

# Helper function to print warning messages
# Usage: print_warning "Be careful"
print_warning() {
    echo "${YELLOW}⚠ $*${NORMAL}"
}

# Helper function to print info messages
# Usage: print_info "Processing..."
print_info() {
    echo "${CYAN}ℹ $*${NORMAL}"
}
