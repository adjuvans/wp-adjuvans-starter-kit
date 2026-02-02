# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Fixed
- Nothing yet

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

[Unreleased]: https://github.com/user/wp-adjuvans-starter-kit/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/user/wp-adjuvans-starter-kit/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/user/wp-adjuvans-starter-kit/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/user/wp-adjuvans-starter-kit/releases/tag/v1.0.0
