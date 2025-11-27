#!/bin/sh
# diagnose-php.sh - Diagnostic PHP for OVH shared hosting
# This script helps identify which PHP binary is available on your system

set -euo pipefail

echo "=========================================="
echo "PHP DIAGNOSTIC FOR SHARED HOSTING"
echo "=========================================="
echo ""

echo "## 1. ENVIRONMENT"
echo "Hostname: $(hostname 2>/dev/null || echo 'unknown')"
echo "User: $(whoami 2>/dev/null || echo 'unknown')"
echo "PWD: $(pwd)"
echo ""

echo "## 2. PATH VARIABLE"
echo "PATH=${PATH}"
echo ""

echo "## 3. CHECKING PHP COMMANDS"
echo ""

# Check generic 'php'
echo "Testing: php"
if command -v php >/dev/null 2>&1; then
    echo "  ✓ FOUND: $(command -v php)"
    echo "  Version: $(php -v 2>&1 | head -n1)"
else
    echo "  ✗ NOT FOUND"
fi
echo ""

# Check versioned PHP binaries
for version in 8.3 8.2 8.1 8.0 7.4 7.3; do
    cmd="php${version}"
    echo "Testing: ${cmd}"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  ✓ FOUND: $(command -v "$cmd")"
        echo "  Version: $($cmd -v 2>&1 | head -n1)"
    else
        echo "  ✗ NOT FOUND"
    fi
    echo ""
done

echo "## 4. CHECKING COMMON PHP PATHS"
echo ""

for path in /usr/bin/php /usr/local/bin/php /opt/php*/bin/php; do
    echo "Testing: ${path}"
    if [ -x "$path" ]; then
        echo "  ✓ EXECUTABLE: ${path}"
        echo "  Version: $("$path" -v 2>&1 | head -n1)"
    else
        echo "  ✗ NOT FOUND OR NOT EXECUTABLE"
    fi
    echo ""
done

echo "## 5. LISTING PHP BINARIES IN COMMON DIRECTORIES"
echo ""

echo "/usr/bin/php*:"
ls -la /usr/bin/php* 2>/dev/null || echo "  None found"
echo ""

echo "/usr/local/bin/php*:"
ls -la /usr/local/bin/php* 2>/dev/null || echo "  None found"
echo ""

echo "/opt/php*/bin/php:"
ls -la /opt/php*/bin/php 2>/dev/null || echo "  None found"
echo ""

echo "## 6. RECOMMENDED PHP BINARY FOR THIS SYSTEM"
echo ""

# Determine best PHP binary
if command -v php8.3 >/dev/null 2>&1; then
    PHP_BIN="php8.3"
elif command -v php8.2 >/dev/null 2>&1; then
    PHP_BIN="php8.2"
elif command -v php8.1 >/dev/null 2>&1; then
    PHP_BIN="php8.1"
elif command -v php8.0 >/dev/null 2>&1; then
    PHP_BIN="php8.0"
elif command -v php7.4 >/dev/null 2>&1; then
    PHP_BIN="php7.4"
elif command -v php >/dev/null 2>&1; then
    PHP_BIN="php"
elif [ -x "/usr/local/bin/php" ]; then
    PHP_BIN="/usr/local/bin/php"
elif [ -x "/usr/bin/php" ]; then
    PHP_BIN="/usr/bin/php"
else
    PHP_BIN="NOT FOUND"
fi

if [ "$PHP_BIN" != "NOT FOUND" ]; then
    echo "✓ RECOMMENDED: ${PHP_BIN}"
    echo "  Full path: $(command -v "$PHP_BIN" 2>/dev/null || echo "$PHP_BIN")"
    echo "  Version: $($PHP_BIN -v 2>&1 | head -n1)"
    echo ""
    echo "  Test command:"
    echo "  $ ${PHP_BIN} -v"
else
    echo "✗ NO PHP BINARY FOUND"
    echo ""
    echo "  On OVH shared hosting, you may need to:"
    echo "  - Check your hosting control panel for PHP version settings"
    echo "  - Contact support to verify PHP is installed and accessible"
fi

echo ""
echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="
