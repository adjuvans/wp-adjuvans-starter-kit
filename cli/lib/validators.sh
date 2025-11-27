#!/bin/sh
# validators.sh - Input validation utilities
# Provides functions to validate user inputs for security and correctness

# Load logger if available
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "${SCRIPT_DIR}/logger.sh" ]; then
    . "${SCRIPT_DIR}/logger.sh"
fi

# Validate email address
# Usage: validate_email "user@example.com" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_email() {
    local email="$1"

    if [ -z "$email" ]; then
        [ -n "${log_error:-}" ] && log_error "Email cannot be empty"
        return 1
    fi

    # Basic email regex pattern
    if echo "$email" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'; then
        return 0
    else
        [ -n "${log_error:-}" ] && log_error "Invalid email format: $email"
        return 1
    fi
}

# Validate password strength
# Requirements: at least 12 characters, contains uppercase, lowercase, digit
# Usage: validate_password "MyP@ssw0rd123" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_password() {
    local password="$1"
    local min_length="${2:-12}"

    if [ -z "$password" ]; then
        [ -n "${log_error:-}" ] && log_error "Password cannot be empty"
        return 1
    fi

    # Check minimum length
    if [ ${#password} -lt "$min_length" ]; then
        [ -n "${log_error:-}" ] && log_error "Password must be at least ${min_length} characters long"
        return 1
    fi

    # Check for at least one uppercase letter
    if ! echo "$password" | grep -q '[A-Z]'; then
        [ -n "${log_error:-}" ] && log_error "Password must contain at least one uppercase letter"
        return 1
    fi

    # Check for at least one lowercase letter
    if ! echo "$password" | grep -q '[a-z]'; then
        [ -n "${log_error:-}" ] && log_error "Password must contain at least one lowercase letter"
        return 1
    fi

    # Check for at least one digit
    if ! echo "$password" | grep -q '[0-9]'; then
        [ -n "${log_error:-}" ] && log_error "Password must contain at least one digit"
        return 1
    fi

    return 0
}

# Validate slug (alphanumeric + hyphens only)
# Usage: validate_slug "my-project-name" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_slug() {
    local slug="$1"

    if [ -z "$slug" ]; then
        [ -n "${log_error:-}" ] && log_error "Slug cannot be empty"
        return 1
    fi

    # Check if slug contains only lowercase letters, numbers, and hyphens
    if echo "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        return 0
    else
        [ -n "${log_error:-}" ] && log_error "Invalid slug format: $slug (use lowercase letters, numbers, and hyphens only)"
        return 1
    fi
}

# Validate database name (alphanumeric + underscores only)
# Usage: validate_db_name "wp_database" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_db_name() {
    local db_name="$1"

    if [ -z "$db_name" ]; then
        [ -n "${log_error:-}" ] && log_error "Database name cannot be empty"
        return 1
    fi

    # Check if database name contains only letters, numbers, and underscores
    # and doesn't start with a number
    if echo "$db_name" | grep -Eq '^[a-zA-Z_][a-zA-Z0-9_]*$'; then
        return 0
    else
        [ -n "${log_error:-}" ] && log_error "Invalid database name: $db_name (use letters, numbers, and underscores only)"
        return 1
    fi
}

# Validate URL format
# Usage: validate_url "https://example.com" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_url() {
    local url="$1"

    if [ -z "$url" ]; then
        [ -n "${log_error:-}" ] && log_error "URL cannot be empty"
        return 1
    fi

    # Check if URL starts with http:// or https://
    if echo "$url" | grep -Eq '^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$'; then
        return 0
    else
        [ -n "${log_error:-}" ] && log_error "Invalid URL format: $url (must start with http:// or https://)"
        return 1
    fi
}

# Sanitize input by removing dangerous characters
# Usage: sanitized=$(sanitize_input "$user_input")
# Removes: newlines, carriage returns, semicolons, pipes, backticks, dollar signs, parentheses
sanitize_input() {
    local input="$1"
    # Remove dangerous shell characters
    echo "$input" | tr -d '\n\r' | sed 's/[;&|`$()]//g'
}

# Validate directory path (no path traversal)
# Usage: validate_path "/var/www/html" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_path() {
    local path="$1"

    if [ -z "$path" ]; then
        [ -n "${log_error:-}" ] && log_error "Path cannot be empty"
        return 1
    fi

    # Check for path traversal attempts
    if echo "$path" | grep -q '\.\.'; then
        [ -n "${log_error:-}" ] && log_error "Path traversal detected: $path"
        return 1
    fi

    return 0
}

# Validate username (alphanumeric + underscores, 3-16 chars)
# Usage: validate_username "admin_user" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_username() {
    local username="$1"

    if [ -z "$username" ]; then
        [ -n "${log_error:-}" ] && log_error "Username cannot be empty"
        return 1
    fi

    # Check length (3-16 characters)
    if [ ${#username} -lt 3 ] || [ ${#username} -gt 16 ]; then
        [ -n "${log_error:-}" ] && log_error "Username must be 3-16 characters long"
        return 1
    fi

    # Check if username contains only letters, numbers, and underscores
    if echo "$username" | grep -Eq '^[a-zA-Z0-9_]+$'; then
        return 0
    else
        [ -n "${log_error:-}" ] && log_error "Invalid username: $username (use letters, numbers, and underscores only)"
        return 1
    fi
}

# Validate table prefix (alphanumeric + underscores, ends with _)
# Usage: validate_table_prefix "wp_" && echo "Valid"
# Returns: 0 if valid, 1 if invalid
validate_table_prefix() {
    local prefix="$1"

    if [ -z "$prefix" ]; then
        [ -n "${log_error:-}" ] && log_error "Table prefix cannot be empty"
        return 1
    fi

    # Check if prefix contains only letters, numbers, and underscores
    # and ends with an underscore
    if echo "$prefix" | grep -Eq '^[a-zA-Z0-9_]+_$'; then
        return 0
    else
        [ -n "${log_error:-}" ] && log_error "Invalid table prefix: $prefix (must end with underscore)"
        return 1
    fi
}

# Prompt for input with validation
# Usage: validated_input=$(prompt_validated "Enter email: " validate_email)
prompt_validated() {
    local prompt="$1"
    local validator="$2"
    local input=""
    local max_attempts=3
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        printf "%s" "$prompt"
        read -r input

        if $validator "$input"; then
            echo "$input"
            return 0
        fi

        attempt=$((attempt + 1))
        if [ $attempt -lt $max_attempts ]; then
            [ -n "${log_warn:-}" ] && log_warn "Invalid input. Please try again ($((max_attempts - attempt)) attempts remaining)"
        fi
    done

    [ -n "${log_fatal:-}" ] && log_fatal "Maximum validation attempts exceeded"
    return 1
}

# Prompt for password with validation (hidden input)
# Usage: password=$(prompt_password "Enter password: " 12)
prompt_password() {
    local prompt="$1"
    local min_length="${2:-12}"
    local password=""
    local max_attempts=3
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        printf "%s" "$prompt"
        # Use -s flag to hide password input
        stty -echo 2>/dev/null
        read -r password
        stty echo 2>/dev/null
        echo ""

        if validate_password "$password" "$min_length"; then
            echo "$password"
            return 0
        fi

        attempt=$((attempt + 1))
        if [ $attempt -lt $max_attempts ]; then
            [ -n "${log_warn:-}" ] && log_warn "Invalid password. Please try again ($((max_attempts - attempt)) attempts remaining)"
        fi
    done

    [ -n "${log_fatal:-}" ] && log_fatal "Maximum validation attempts exceeded"
    return 1
}
