# WP Adjuvans Starter Kit

> **A secure, automated WordPress installation toolkit for shared hosting environments**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![WordPress](https://img.shields.io/badge/WordPress-6.0+-blue.svg)](https://wordpress.org/)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Installation Guide](#installation-guide)
- [Usage](#usage)
- [Security](#security)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

**WP Adjuvans Starter Kit** is a collection of Bash scripts designed to automate WordPress installation and management on **shared hosting environments** (OVH, o2switch, etc.) where you don't have root access or Docker availability.

This toolkit provides:
- **Secure credential handling** (no passwords in process lists)
- **Automated WordPress installation** with WP-CLI
- **Encrypted backups** (optional GPG encryption)
- **Interactive configuration wizard**
- **Input validation** for security
- **Structured logging** system

### Why This Kit?

- ✅ **No Docker required** - works on basic shared hosting
- ✅ **No root/sudo required** - runs with user permissions
- ✅ **Portable** - only requires PHP, curl, and standard Unix tools
- ✅ **Secure** - credentials never exposed in command line arguments
- ✅ **Public-safe** - no sensitive data committed to git
- ✅ **Well-tested** - used in production for multiple WordPress sites

---

## ✨ Features

### Core Features

- 🔐 **Secure Credentials Handling**
  - Database passwords never appear in `ps aux` output
  - Admin passwords stored in git-ignored config files
  - WP-config.php created with restrictive permissions (400)

- 🚀 **Automated Installation**
  - Interactive wizard for configuration
  - One-command WordPress setup
  - Automatic WP-CLI download with SHA512 verification
  - Default plugins and themes cleanup

- 💾 **Intelligent Backup System**
  - Database and files archiving
  - Optional GPG encryption (symmetric or public-key)
  - Automatic backup rotation (keep last N backups)
  - Compressed archives to save disk space

- 🛡️ **Security Hardening**
  - File permissions enforcement (755/644/400)
  - `.htaccess` rules against SQL injection and XSS
  - WP debug logs outside web root
  - Directory browsing disabled
  - WordPress file editor disabled

- 📊 **Quality Tools**
  - Dependency checker
  - Input validators (email, password strength, slugs)
  - Structured logging with timestamps
  - Color-coded terminal output

---

## 📦 Requirements

### Mandatory Dependencies

| Tool | Version | Purpose |
|------|---------|---------|
| **PHP** | ≥ 7.4 | WordPress requirement |
| **curl** | Any | Download WP-CLI and WordPress core |
| **tar** | Any | Archive creation for backups |
| **gzip** | Any | Compression |
| **sha512sum** | Any | WP-CLI integrity verification |
| **Bash** | ≥ 4.0 | Shell scripting |

### Optional Dependencies

| Tool | Purpose |
|------|---------|
| **mysql-client** | Direct database operations (fallback) |
| **gpg** | Encrypted backups |
| **git** | Version control |

### PHP Extensions (Recommended)

- `mysqli` - Database connectivity
- `curl` - HTTP requests
- `gd` or `imagick` - Image manipulation
- `mbstring` - Multibyte string handling
- `xml` - XML processing
- `zip` - Plugin/theme installation

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/adjuvans/wp-adjuvans-starter-kit.git
cd wp-adjuvans-starter-kit
```

### 2. Check Dependencies

```bash
chmod +x cli/*.sh cli/lib/*.sh
./cli/check-dependencies.sh
```

### 3. Run Interactive Installer

```bash
./cli/install.sh
```

This wizard will:
- Ask for project details (name, slug)
- Configure database credentials (with validation)
- Set up WordPress admin account
- Optionally enable GPG backup encryption
- Generate secure configuration file
- Install WordPress automatically

### 4. Access Your Site

```bash
# Visit your WordPress site
open https://your-site.test

# Or login to admin panel
open https://your-site.test/wp-admin
```

---

## 📖 Installation Guide

### Detailed Step-by-Step Installation

#### Step 1: Prepare Your Environment

1. **Create a database** on your hosting provider:
   ```sql
   CREATE DATABASE wordpress_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'strong_password_here';
   GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

2. **Clone the starter kit**:
   ```bash
   cd /path/to/your/hosting/root
   git clone https://github.com/adjuvans/wp-adjuvans-starter-kit.git myproject
   cd myproject
   ```

3. **Make scripts executable**:
   ```bash
   chmod +x cli/*.sh cli/lib/*.sh
   ```

#### Step 2: Verify Dependencies

```bash
./cli/check-dependencies.sh
```

Expected output:
```
---
# DEPENDENCY CHECK
[INFO] Checking required dependencies...

[✔] php (8.1.2)
[✔] curl (7.84.0)
[✔] tar (installed)
[✔] gzip (installed)
[✔] sha512sum (installed)

✔ ALL REQUIRED DEPENDENCIES SATISFIED

✔ System is ready for WordPress installation!
```

#### Step 3: Configure Your Project

**Option A: Interactive Installer (Recommended)**

```bash
./cli/install.sh
```

Follow the prompts to configure:
- Project name and slug
- Database credentials
- WordPress site URL and title
- Admin account (username, password, email)
- Backup settings (encryption, retention)

**Option B: Manual Configuration**

```bash
cp config/config.sample.sh config/config.sh
nano config/config.sh  # Edit configuration
```

Then run:
```bash
./cli/init.sh                  # Initialize environment
./cli/install-wordpress.sh      # Install WordPress
```

#### Step 4: Install Plugins (Optional)

Recommended plugins for typical WordPress sites:

```bash
cd wordpress

# Page Builder
php ../wp-cli.phar plugin install elementor --activate

# SEO
php ../wp-cli.phar plugin install wordpress-seo --activate

# Security & Utilities
php ../wp-cli.phar plugin install code-snippets --activate
php ../wp-cli.phar plugin install enable-media-replace --activate
php ../wp-cli.phar plugin install loco-translate --activate
php ../wp-cli.phar plugin install redirection --activate
php ../wp-cli.phar plugin install google-site-kit --activate
php ../wp-cli.phar plugin install duplicate-post --activate
```

---

## 🎮 Usage

### Available Commands

```bash
# Check system dependencies
./cli/check-dependencies.sh

# Interactive installation wizard
./cli/install.sh

# Initialize environment (WP-CLI, directories, permissions)
./cli/init.sh

# Install WordPress
./cli/install-wordpress.sh

# Install phpwpinfo (WordPress diagnostics tool)
./cli/install-phpwpinfo.sh

# Create backup (files + database)
./cli/backup.sh
```

### Using the Makefile (Optional)

```bash
# Check dependencies
make check

# Initialize environment
make init

# Install WordPress
make install

# Create backup
make backup

# Clean installation (DANGER: deletes WordPress!)
make clean

# Show help
make help
```

### 🔍 WordPress Diagnostics with phpwpinfo

**phpwpinfo** is a diagnostic tool (similar to phpinfo) for WordPress installations. It displays comprehensive information about your WordPress environment.

#### Installation

```bash
./cli/install-phpwpinfo.sh
```

This will download and install phpwpinfo.php in your WordPress directory.

#### Usage

Access the diagnostic page at: `https://your-site.com/phpwpinfo.php`

**Information displayed:**
- WordPress version and configuration
- Active plugins and themes
- PHP configuration
- Server environment
- Database information
- Security settings
- Performance metrics

#### ⚠️ Security Warning

**IMPORTANT:** phpwpinfo.php exposes sensitive information about your installation!

**Recommended security measures:**

1. **Delete after use** (most secure):
   ```bash
   rm wordpress/phpwpinfo.php
   ```

2. **Protect with IP restriction** (`.htaccess`):
   ```apache
   <Files "phpwpinfo.php">
       Order Deny,Allow
       Deny from all
       Allow from YOUR.IP.ADDRESS
   </Files>
   ```

3. **Rename the file**:
   ```bash
   mv wordpress/phpwpinfo.php wordpress/diagnostic-$(date +%s).php
   ```

**Never leave phpwpinfo.php accessible on production without protection!**

More info: [BeAPI/phpwpinfo on GitHub](https://github.com/BeAPI/phpwpinfo)

---

## 🔒 Security

### Security Features

1. **No Credentials in Process List**
   - Database and admin passwords are NEVER passed as CLI arguments
   - WP-config.php created via secure temporary files
   - Admin password set via WP-CLI user update (not during install)

2. **File Permissions Enforcement**
   - Directories: `755` (rwxr-xr-x)
   - Regular files: `644` (rw-r--r--)
   - wp-config.php: `400` (r--------)
   - .htaccess: `400` (r--------)

3. **Configuration File Protection**
   - `config/config.sh` excluded from git
   - Permissions set to `600` (owner read/write only)
   - Contains encrypted backup keys (if GPG enabled)

4. **Input Validation**
   - Email format validation
   - Password strength requirements (12+ chars, mixed case, digits)
   - SQL-safe database names and table prefixes
   - Path traversal protection

5. **Backup Encryption**
   - Optional GPG encryption (AES256 cipher)
   - Supports symmetric (password) or public-key encryption
   - Backup rotation to limit disk usage

6. **WordPress Hardening**
   - File editor disabled in admin (`DISALLOW_FILE_EDIT`)
   - Comments disabled by default
   - Search engines discouraged on new installs
   - Default plugins/themes removed
   - Security headers in `.htaccess`

### Security Best Practices

⚠️ **CRITICAL RULES:**

1. **NEVER commit `config/config.sh`** - it's already in `.gitignore`
2. **Use strong passwords** - minimum 12 characters, mixed case, numbers, symbols
3. **Change default admin username** - never use "admin"
4. **Enable HTTPS** - use Let's Encrypt or similar
5. **Keep WordPress updated** - run `wp core update` regularly
6. **Backup regularly** - run `./cli/backup.sh` via cron
7. **Monitor logs** - check `logs/` directory for suspicious activity

### Reporting Security Issues

Please see [SECURITY.md](SECURITY.md) for our security policy and how to report vulnerabilities.

---

## 📁 Project Structure

```
wp-adjuvans-starter-kit/
├── cli/                              # CLI scripts
│   ├── install.sh                    # Main interactive installer
│   ├── init.sh                       # Environment initialization
│   ├── install-wordpress.sh          # WordPress installation
│   ├── install-phpwpinfo.sh          # Install phpwpinfo diagnostic tool
│   ├── backup.sh                     # Backup creation
│   ├── check-dependencies.sh         # Dependency checker
│   └── lib/                          # Shared libraries
│       ├── colors.sh                 # Terminal colors
│       ├── logger.sh                 # Logging functions
│       ├── validators.sh             # Input validation
│       └── secure-wp-config.sh       # Secure wp-config generator
│
├── config/                           # Configuration (git-ignored)
│   ├── config.sample.sh              # Configuration template
│   └── config.sh                     # Actual config (generated, git-ignored)
│
├── wordpress/                        # WordPress installation (git-ignored)
├── logs/                             # Log files (git-ignored)
├── save/                             # Backups (git-ignored)
│
├── .gitignore                        # Git ignore rules
├── Makefile                          # Convenience commands
├── README.md                         # This file
├── SECURITY.md                       # Security policy
└── LICENSE                           # License file
```

---

## ⚙️ Configuration

### Configuration File Reference

The configuration file (`config/config.sh`) is generated automatically by `cli/install.sh`, but you can also create it manually from the template.

#### Project Settings

```bash
project_name="My WordPress Site"     # Human-readable project name
project_slug="my-wordpress-site"     # Lowercase slug (used for backups)
```

#### Directory Settings

```bash
directory_public="./wordpress"       # WordPress installation directory
directory_log="./logs"               # Log files location
directory_backup="./save"            # Backup storage location
```

#### Database Configuration

```bash
db_host="localhost"                  # Database server hostname
db_name="wp_database"                # Database name
db_user="wp_user"                    # Database username
db_pass="SecurePassword123!"         # Database password
db_prefix="wp_"                      # Table prefix (must end with _)
db_charset="utf8mb4"                 # Character set
```

#### WordPress Settings

```bash
site_url="https://example.com"       # Site URL (with protocol)
site_title="My Awesome Site"         # Site title
site_locale="fr_FR"                  # Locale (en_US, fr_FR, es_ES, etc.)
```

#### Admin Account

```bash
admin_login="admin_user"             # Admin username (NOT "admin")
admin_pass="VeryStrongPass123!"      # Admin password (12+ chars)
admin_email="admin@example.com"      # Admin email
```

#### Backup Configuration

```bash
USE_GPG_ENCRYPTION="true"            # Enable GPG encryption (true/false)
GPG_RECIPIENT="your@email.com"       # GPG recipient (or empty for symmetric)
BACKUP_RETENTION="7"                 # Number of backups to keep
```

---

## 🔍 Troubleshooting

### Common Issues

#### Issue: "PHP version too old"

**Error:**
```
[ERROR] PHP version 7.2.0 is too old (minimum required: 7.4)
```

**Solution:**
Update PHP on your hosting:
```bash
# cPanel: Use "Select PHP Version" tool
# Command line (if available):
sudo update-alternatives --config php
```

#### Issue: "WP-CLI signature verification failed"

**Error:**
```
[ERROR] SHA512 verification failed - WP-CLI signature is invalid
```

**Solution:**
This indicates a potentially compromised download. Delete and retry:
```bash
rm -f wp-cli.phar wp-cli.phar.sha512
./cli/init.sh
```

#### Issue: "Database connection error"

**Error:**
```
Error establishing a database connection
```

**Solution:**
1. Verify database credentials in `config/config.sh`
2. Ensure database exists:
   ```bash
   mysql -h localhost -u root -p -e "SHOW DATABASES;"
   ```
3. Check database user permissions:
   ```bash
   mysql -h localhost -u your_user -p your_database -e "SELECT 1;"
   ```

#### Issue: "Permission denied"

**Error:**
```
./cli/install.sh: Permission denied
```

**Solution:**
```bash
chmod +x cli/*.sh cli/lib/*.sh
```

#### Issue: "gpg: command not found" (during backup)

**Error:**
```
[WARN] GPG encryption requested but GPG not available
```

**Solution:**
Either install GPG:
```bash
# Debian/Ubuntu
sudo apt-get install gnupg

# macOS
brew install gnupg
```

Or disable encryption in `config/config.sh`:
```bash
USE_GPG_ENCRYPTION="false"
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages: `git commit -m "Add amazing feature"`
6. Push to your fork: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Standards

- **Shell scripts:** Use `#!/bin/sh` and POSIX-compatible syntax
- **Comments:** All comments must be in English
- **Error handling:** Always use `set -euo pipefail`
- **Validation:** Validate all user inputs
- **Security:** Never log or expose credentials

---

## 📜 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- **WP-CLI Team** - For the excellent WordPress command-line tool
- **WordPress Community** - For the world's most popular CMS
- **Contributors** - Everyone who has contributed to this project

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/adjuvans/wp-adjuvans-starter-kit/issues)
- **Email:** support@adjuvans.fr

---

**Made with ❤️ by [Adjuvans](https://adjuvans.fr)**
