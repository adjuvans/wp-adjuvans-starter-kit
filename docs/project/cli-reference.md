# CLI Reference

Complete reference for all WP Adjuvans Starter Kit commands.

## Makefile Commands

Run commands with `make <command>`:

### Setup & Installation

| Command | Description |
|---------|-------------|
| `make check` | Check system dependencies (PHP, MySQL, curl, etc.) |
| `make init` | Initialize environment (WP-CLI, directories, permissions) |
| `make install` | Run interactive WordPress installation wizard |
| `make install-wordpress` | Install WordPress (requires existing config) |
| `make diagnose-php` | Diagnose PHP installation and environment |

### Plugins & Themes

| Command | Description |
|---------|-------------|
| `make install-plugins` | Interactive plugin installation wizard |
| `make install-themes` | Interactive theme installation wizard |
| `make install-plugin PLUGIN=<slug>` | Install specific plugin |
| `make install-theme THEME=<slug>` | Install specific theme |
| `make activate-theme THEME=<slug>` | Activate a theme |
| `make list-plugins` | List installed plugins |
| `make list-themes` | List installed themes |

### Maintenance

| Command | Description |
|---------|-------------|
| `make backup` | Create backup (with optional GPG encryption) |
| `make restore` | Restore from backup (interactive) |
| `make list-backups` | List available backups |
| `make security-scan` | Run security scan |
| `make setup-wpscan` | Configure WPScan API key |

### Updates

| Command | Description |
|---------|-------------|
| `make update-wp` | Update WordPress core |
| `make update-plugins` | Update all plugins |
| `make update-themes` | Update all themes |
| `make update-all` | Update WordPress, plugins, and themes |

### Development & Testing

| Command | Description |
|---------|-------------|
| `make test` | Run bats-core test suite |
| `make lint` | Check shell scripts syntax |
| `make permissions` | Fix file permissions |
| `make config-check` | Validate config file syntax |

### Information

| Command | Description |
|---------|-------------|
| `make help` | Display all available commands |
| `make status` | Show project status |
| `make version` | Show WordPress version |
| `make toolkit-version` | Show WPASK toolkit version |
| `make release-check` | Check if ready for release |

### Cleanup

| Command | Description |
|---------|-------------|
| `make clean` | Remove WordPress installation (DANGER!) |
| `make clean-logs` | Remove old log files (30+ days) |
| `make clean-backups` | Remove old backups (keeps last 7) |

---

## CLI Scripts

Direct script usage from `cli/` directory.

### backup.sh

Create secure backups of WordPress installation.

```bash
./cli/backup.sh
```

**Features:**
- Database export via WP-CLI
- Files compression
- Optional GPG encryption
- Backup rotation (configurable retention)

**Configuration** (in `config/config.sh`):
```bash
USE_GPG_ENCRYPTION="true"    # Enable encryption
GPG_RECIPIENT="user@email"   # GPG key for encryption
BACKUP_RETENTION="7"         # Number of backups to keep
```

**Output:**
- `save/YYYY-MM-DD-HHMMSS_projectslug.tar.gz` (unencrypted)
- `save/YYYY-MM-DD-HHMMSS_projectslug.tar.gz.gpg` (encrypted)

---

### restore.sh

Restore WordPress from backup.

```bash
./cli/restore.sh [OPTIONS] [ARCHIVE_PATH]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help |
| `-n, --dry-run` | Simulate without changes |
| `-d, --db-only` | Restore database only |
| `-f, --files-only` | Restore files only |
| `-u, --new-url URL` | Replace URLs after restore |
| `--skip-backup` | Skip pre-restore safety backup |
| `-l, --list` | List available backups |

**Examples:**

```bash
# Interactive mode
./cli/restore.sh

# Restore specific backup
./cli/restore.sh save/2024-01-15_backup.tar.gz

# Restore with domain migration
./cli/restore.sh --new-url="https://newdomain.com" save/backup.tar.gz

# Database only
./cli/restore.sh --db-only save/backup.tar.gz

# Dry run
./cli/restore.sh --dry-run save/backup.tar.gz
```

---

### security-scan.sh

Scan WordPress for security issues.

```bash
./cli/security-scan.sh [OPTIONS]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help |
| `-q, --quiet` | Quiet mode (exit code only) |
| `-j, --json` | Output as JSON |
| `--skip-wpscan` | Skip WPScan API checks |
| `--check=CHECKS` | Run specific checks only |

**Available checks:**
- `checksums` - WordPress core file integrity
- `plugins` - Plugin updates and vulnerabilities
- `themes` - Theme updates
- `permissions` - File permissions
- `config` - wp-config.php security
- `files` - Suspicious files
- `server` - Server configuration

**Examples:**

```bash
# Full scan
./cli/security-scan.sh

# Quick scan without API
./cli/security-scan.sh --skip-wpscan

# Specific checks
./cli/security-scan.sh --check=permissions,config

# JSON output
./cli/security-scan.sh --json > report.json

# CI/CD integration
./cli/security-scan.sh --quiet && echo "Security OK"
```

**Exit codes:**
- `0` - No critical issues
- `1` - Critical issues found
- `2` - Script error

---

### setup-wpscan-api.sh

Configure WPScan API for vulnerability scanning.

```bash
./cli/setup-wpscan-api.sh [OPTIONS]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help |
| `-k, --api-key KEY` | Set API key directly |
| `-c, --check` | Check current status |
| `-r, --remove` | Remove API key |
| `-t, --test` | Test API key validity |

**Examples:**

```bash
# Interactive setup
./cli/setup-wpscan-api.sh

# Direct key setup
./cli/setup-wpscan-api.sh --api-key="YOUR_KEY"

# Check status
./cli/setup-wpscan-api.sh --check

# Test key
./cli/setup-wpscan-api.sh --test
```

---

### install.sh

Interactive WordPress installation wizard.

```bash
./cli/install.sh
```

Guides through:
1. Project configuration
2. Database setup
3. WordPress download and configuration
4. Admin account creation
5. Theme and plugin selection

---

### check-dependencies.sh

Verify system requirements.

```bash
./cli/check-dependencies.sh
```

Checks:
- PHP version (7.4+)
- Required PHP extensions
- MySQL/MariaDB
- curl
- tar, gzip
- Optional: GPG, WP-CLI

---

## Library Functions

Available in `cli/lib/` for use in custom scripts.

### colors.sh

Terminal color utilities.

```bash
source cli/lib/colors.sh

echo "${RED}Error${NORMAL}"
echo "${GREEN}Success${NORMAL}"
echo "${YELLOW}Warning${NORMAL}"
echo "${BLUE}Info${NORMAL}"
echo "${BOLD}Bold text${NORMAL}"
```

### logger.sh

Structured logging.

```bash
source cli/lib/logger.sh

log_info "Information message"
log_warn "Warning message"
log_error "Error message"
log_success "Success message"
log_fatal "Fatal error - exits script"
log_debug "Debug (only if DEBUG=1)"
log_section "Section Header"
log_separator
```

### validators.sh

Input validation functions.

```bash
source cli/lib/validators.sh

validate_email "user@example.com" && echo "Valid"
validate_password "MyP@ssw0rd123"
validate_slug "my-project"
validate_url "https://example.com"
validate_db_name "wordpress_db"
validate_table_prefix "wp_"
validate_username "admin"
validate_path "/var/www/html"

# Sanitize dangerous characters
clean=$(sanitize_input "$user_input")
```

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Enable debug output | `0` |
| `LOG_DIR` | Log files directory | `./logs` |
| `USE_GPG_ENCRYPTION` | Enable backup encryption | `false` |
| `GPG_RECIPIENT` | GPG key for encryption | (empty) |
| `BACKUP_RETENTION` | Number of backups to keep | `7` |
