# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.2.0] - 2026-02-04

### Added
- `cli/fix-permissions.sh` - Comprehensive permission fixing script for shared hosting
  - Detects and removes setgid/setuid bits causing 403 errors
  - Check-only mode (`--check`) for CI/CD validation
  - Fix entire project (`--all`) or WordPress directory only
  - Safe permissions: 755 (dirs), 644 (files), 640 (wp-config.php)
  - Compatible with Infomaniak, OVH, o2switch shared hosting
- `make fix-permissions` - Fix all permissions for shared hosting
- `make check-permissions` - Check for dangerous permissions (setgid/setuid)

### Fixed
- **Critical**: Permission sanitization in build/deployment scripts
  - Prevents 403 Forbidden errors on Apache/PHP-FPM shared hosting
  - Removes inherited setgid bits from parent directories
- `scripts/build-dist.sh` - Added permission sanitization before archive creation
- `install.sh` - Added permission sanitization in post-install step
- `.github/workflows/release.yml` - Added `--no-same-permissions` flag to tar
- `cli/self-update.sh` - Fixed ANSI color codes not being interpreted in terminal output
- `scripts/build-dist.sh` - Exclude macOS extended attributes from archives (prevents tar warnings on Linux)

## [3.1.1] - 2026-02-03

### Fixed
- Makefile.dist uses `sh ./cli/...` to avoid permission denied errors on shared hosting
- `cli/self-update.sh` - Corrected primary download URL

## [3.1.0] - 2026-02-03

### Added
- `Makefile.dist` - Simplified Makefile for distribution
  - Detailed command descriptions with usage context
  - Quick Start section in help output
  - Practical examples in help footer
  - Contextual help when commands are run without arguments
  - Excludes development-only commands (test, lint, dist, publish, etc.)

### Changed
- `scripts/build-dist.sh` - Now uses Makefile.dist instead of full Makefile
  - Distribution package contains only user-relevant commands
  - Cleaner help output for end-users

## [3.0.0] - 2026-02-03

### Added
- `cli/install-multisite.sh` - WordPress Multisite installation
  - Interactive mode selection (subdomain or subdirectory)
  - Subdirectory mode recommended for shared hosting
  - Subdomain mode with DNS wildcard or manual DNS warnings
  - WordPress 6.0+ version requirement
  - WordPress at domain root validation
  - Automatic wp-config.php and .htaccess configuration
  - Pre-installation backups
  - Dry-run mode (`--dry-run`)
  - SSO/shared cookies option (`--share-cookies`)
  - Cross-domain SSO warning with WP Remote Users Sync plugin suggestion
  - Automatic plugin installation for cross-domain user sync
- `cli/multisite-status.sh` - Multisite diagnostics and management
  - Show network configuration and statistics
  - List all sites in network
  - List network-activated plugins
  - Install WP Remote Users Sync plugin on demand
  - Regenerate .htaccess rules (`fix-htaccess`)
  - Check wp-config.php multisite constants (`fix-config`)
  - JSON output for automation (`--json`)
- `make multisite-status` - Check multisite configuration
- `install.sh` - Remote installer script
  - One-liner installation: `curl -fsSL .../install.sh | sh`
  - Version selection (`--version v2.2.0`)
  - Branch installation (`--branch dev`)
  - Custom directory (`--dir /var/www/mysite`)
  - Automatic latest version detection via GitHub API
  - Overwrite protection for existing installations
- `make multisite-install` - Convert WordPress to Multisite
- `cli/convert-to-multisite.sh` - Convert existing site with content
  - Analyzes existing content (posts, pages, users, media)
  - Recommends backup before conversion
  - Content preservation confirmation
  - Wrapper around install-multisite.sh with additional safety checks
- `make multisite-convert` - Convert existing site to Multisite
- `cli/security-scan.sh` - WordPress security scanner
  - Core integrity verification (checksums)
  - Plugin/theme update checks
  - File permission audits
  - wp-config.php security settings
  - Suspicious file detection
  - Server configuration checks
  - WPScan API integration for CVE detection
  - Security score (A-F grading)
  - JSON output for automation (`--json`)
  - Specific checks (`--check=permissions,config`)
- `cli/setup-wpscan-api.sh` - WPScan API key configuration
  - Interactive and non-interactive setup
  - API key validation and testing
  - Secure storage (600 permissions)
- `make security-scan` - Run security scan
- `make setup-wpscan` - Configure WPScan API
- `.github/workflows/ci.yml` - CI/CD pipeline with GitHub Actions
  - ShellCheck linting for all shell scripts
  - Syntax validation for shell scripts
  - bats-core test execution
  - Test matrix: Ubuntu + macOS
  - Security scan for hardcoded secrets
- `tests/` directory with bats-core test framework
  - `tests/bats/test-colors.bats` - Tests for colors.sh
  - `tests/bats/test-logger.bats` - Tests for logger.sh
  - `tests/bats/test-validators.bats` - Tests for validators.sh (40+ tests)
  - `tests/bats/test-restore.bats` - Tests for restore.sh
  - `tests/bats/test-backup.bats` - Tests for backup.sh
  - `tests/helpers/test-helper.bash` - Common test utilities
  - `tests/fixtures/` - Test fixtures and mock data
- `cli/adopt-site.sh` - Adopt existing WordPress sites
  - Auto-detect WordPress configuration from wp-config.php
  - Validate standard installation structure
  - Detect and reject non-standard installations (Bedrock, custom wp-content)
  - Generate config/config.sh from existing site
  - Test database connection
  - Verify WPASK tools compatibility
  - Interactive and automatic modes (`--auto`)
  - Dry-run mode (`--dry-run`)
- `make adopt` - Adopt an existing WordPress site
- Documentation improvements:
  - `SECURITY.md` - Security policy and vulnerability reporting
  - `CONTRIBUTING.md` - Contribution guidelines
  - `docs/project/cli-reference.md` - Complete CLI reference
  - `docs/project/backup-restore.md` - Backup and restore guide

### Changed
- `cli/install-wordpress.sh` - Detect orphan database tables from failed installations
  - Automatically detects tables with configured prefix when WordPress is not fully installed
  - Offers to reset database and start fresh
  - Prevents cryptic "tables unavailable" errors
- `make test` now runs bats-core tests (requires bats-core installed)

## [2.1.0] - 2026-02-02

### Added
- `cli/restore.sh` - Complete backup restoration script
  - Support for plain (.tar.gz) and encrypted (.tar.gz.gpg) backups
  - Interactive backup selection mode
  - `--db-only` and `--files-only` restore modes
  - `--dry-run` for simulation
  - `--new-url` for domain migration with automatic URL replacement
  - Pre-restore safety backup
  - Archive integrity verification
- `make restore` - Makefile target for restore
- `make list-backups` - Makefile target to list available backups
- `VERSIONING.md` - Versioning policy documentation
- `CHANGELOG.md` - This changelog file
- `VERSION` - Version tracking file
- `.github/workflows/release.yml` - Automated GitHub releases

### Changed
- Updated `Makefile` with restore and list-backups targets

## [2.0.0] - 2026-01-15

### Added
- Complete rewrite of the toolkit
- `cli/install.sh` - Interactive WordPress installation wizard
- `cli/init.sh` - Environment initialization
- `cli/backup.sh` - Secure backup with optional GPG encryption
- `cli/check-dependencies.sh` - System requirements checker
- `cli/lib/logger.sh` - Structured logging utilities
- `cli/lib/colors.sh` - Terminal color utilities
- `cli/lib/validators.sh` - Input validation functions
- `cli/lib/secure-wp-config.sh` - Secure wp-config.php generation
- Support for shared hosting (OVH, o2switch, Infomaniak)
- POSIX shell compatibility (dash, bash, zsh)

### Changed
- Migrated from bash-specific to POSIX-compatible shell scripts
- Improved security: credentials never passed via command line
- Backup format now includes database.sql and wordpress-files.tar.gz

### Security
- Passwords and credentials read from config file only
- Secure file permissions (600 for config, 640 for wp-config.php)
- GPG encryption support for backups

## [1.0.0] - 2025-06-01

### Added
- Initial release
- Basic WordPress installation script
- Simple backup functionality

---

[Unreleased]: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v3.2.0...HEAD
[3.2.0]: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v2.1.0...v3.0.0
[2.1.0]: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/adjuvans/wp-adjuvans-starter-kit/releases/tag/v1.0.0
