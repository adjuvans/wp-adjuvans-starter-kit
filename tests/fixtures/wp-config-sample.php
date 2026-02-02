<?php
/**
 * Sample wp-config.php for testing
 */

// Database settings
define('DB_NAME', 'test_database');
define('DB_USER', 'test_user');
define('DB_PASSWORD', 'test_password');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Authentication keys and salts
define('AUTH_KEY',         'test-auth-key');
define('SECURE_AUTH_KEY',  'test-secure-auth-key');
define('LOGGED_IN_KEY',    'test-logged-in-key');
define('NONCE_KEY',        'test-nonce-key');
define('AUTH_SALT',        'test-auth-salt');
define('SECURE_AUTH_SALT', 'test-secure-auth-salt');
define('LOGGED_IN_SALT',   'test-logged-in-salt');
define('NONCE_SALT',       'test-nonce-salt');

// Table prefix
$table_prefix = 'wp_';

// Debug mode
define('WP_DEBUG', false);

// WordPress directory
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
