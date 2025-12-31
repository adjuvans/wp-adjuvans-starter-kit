# Changelog

> **Note** : Ce fichier est une copie de [CHANGELOG.md](../../CHANGELOG.md) à la racine du projet.
> Pour les contributions, modifiez le fichier à la racine.

---

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2025-01-27

### 🔒 Security

- **CRITICAL**: Fixed password exposure in CLI arguments - database and admin passwords no longer passed as CLI arguments
- **CRITICAL**: Added `db_pass` variable to `config.sample.sh` (was missing)
- Added comprehensive input validation (email, password strength, slugs, DB names, URLs)
- Implemented secure wp-config.php generation via temporary files
- Enhanced curl security with `--proto '=https' --tlsv1.2` flags
- Added GPG encryption support for backups (AES256)
- Enforced strict file permissions (755/644/400/600)
- Added `.htaccess` security rules against SQL injection and XSS

### ✨ Added

- Interactive installation wizard (`cli/install.sh`)
- Structured logging system (`cli/lib/logger.sh`)
- Input validation library (`cli/lib/validators.sh`)
- Color management library (`cli/lib/colors.sh`)
- Secure wp-config generator (`cli/lib/secure-wp-config.sh`)
- Dependency checker script (`cli/check-dependencies.sh`)
- GPG backup encryption (symmetric and public-key modes)
- Automatic backup rotation (configurable retention)
- Log cleanup (removes logs older than 30 days)
- Makefile with convenient commands
- Comprehensive test suite for validators (`tests/test-validators.sh`)
- `.editorconfig` for coding style consistency
- `SECURITY.md` with responsible disclosure policy
- `IMPROVEMENTS.md` tracking future enhancements

### 🐛 Fixed

- Fixed date format bug in `backup.sh` (`+%Y-%m-%y` → `+%Y-%m-%d-%H%M%S`)
- Fixed WP_DEBUG_LOG static date issue (now uses dynamic PHP date)
- Added missing `set -euo pipefail` to all scripts for error handling
- Fixed inconsistent error handling across scripts

### 🔧 Changed

- **BREAKING**: Moved configuration to `config/` directory
- **BREAKING**: Restructured project with `cli/lib/` for libraries
- Reorganized ASCII branding (moved from `config.sample.sh` to `install.sh`)
- Simplified `config.sample.sh` template (removed colors, added all variables)
- Refactored `init.sh` with secure downloads and better logging
- Refactored `install-wordpress.sh` with secure credential handling
- Refactored `backup.sh` with GPG encryption and rotation
- Complete rewrite of `README.md` in English
- Updated `.gitignore` for new structure

### 📚 Documentation

- Rewrote README.md in English with comprehensive sections
- Added Security Policy (SECURITY.md)
- Added improvements tracking (IMPROVEMENTS.md)
- Added this CHANGELOG
- Documented all security features and best practices
- Added troubleshooting section to README
- Added configuration reference

### 🧪 Testing

- Added unit tests for validator functions
- Created test framework with assertions
- Implemented test runner with pass/fail reporting

### ♻️ Refactored

- Extracted reusable functions to `cli/lib/` libraries
- Centralized color handling
- Centralized logging
- Centralized validation
- Improved code comments (all in English)
- Consistent error handling across all scripts

### 🗑️ Removed

- Removed `cli/compile-sass.sh` - SASS compilation is out of scope for this installation toolkit
- Removed `sass` from optional dependencies - theme development should use modern build tools (Vite, Webpack, npm scripts)
- Removed `make compile` target from Makefile

**Rationale**: This starter kit focuses on WordPress installation and management, not theme development workflows. Developers needing SASS compilation should use dedicated build tools (npm, Vite, Webpack) integrated in their theme's package.json.

---

## [1.0.0] - 2020-XX-XX

### Initial Release

- Basic WordPress installation via WP-CLI
- Configuration file system
- SASS compilation support
- Database backup functionality
- French locale by default
- OVH/o2switch compatibility

---

## Migration Guide: v1.x → v2.0

### Breaking Changes

1. **Configuration location changed**:
   ```bash
   # Old: cli/config.sh
   # New: config/config.sh

   # Migration:
   mv cli/config.sh config/config.sh
   ```

2. **New variables required in config**:
   - `admin_pass` (was missing)
   - `USE_GPG_ENCRYPTION` (optional, default: false)
   - `GPG_RECIPIENT` (optional)
   - `BACKUP_RETENTION` (optional, default: 7)

3. **Updated installation process**:
   ```bash
   # Old workflow:
   cp cli/config.sample.sh cli/config.sh
   # Edit cli/config.sh
   cli/init.sh
   cli/install-wordpress.sh

   # New workflow (recommended):
   cli/install.sh  # Interactive wizard

   # Or manual (still supported):
   cp config/config.sample.sh config/config.sh
   # Edit config/config.sh
   cli/init.sh
   cli/install-wordpress.sh
   ```

### Backward Compatibility

- Old `cli/config.sh` location still works (deprecated warning)
- All existing config variables are supported
- New variables have sensible defaults

### Recommended Actions After Upgrading

1. Run dependency checker:
   ```bash
   ./cli/check-dependencies.sh
   ```

2. Update .gitignore:
   ```bash
   cp .gitignore.new .gitignore  # If you customized it
   ```

3. Enable GPG encryption (optional):
   ```bash
   # Edit config/config.sh:
   USE_GPG_ENCRYPTION="true"
   GPG_RECIPIENT="your@email.com"
   ```

4. Test backup/restore:
   ```bash
   ./cli/backup.sh
   # Verify backup in save/ directory
   ```

5. Review SECURITY.md for best practices

---

## Versioning Policy

- **Major version** (X.0.0): Breaking changes, major refactoring
- **Minor version** (x.X.0): New features, non-breaking changes
- **Patch version** (x.x.X): Bug fixes, security patches

---

## Support

- **Issues**: [GitHub Issues](https://github.com/adjuvans/wp-adjuvans-starter-kit/issues)
- **Security**: See [security.md](security.md)
- **Email**: support@adjuvans.fr

---

**[Unreleased]**: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v2.0.0...HEAD
**[2.0.0]**: https://github.com/adjuvans/wp-adjuvans-starter-kit/compare/v1.0.0...v2.0.0
**[1.0.0]**: https://github.com/adjuvans/wp-adjuvans-starter-kit/releases/tag/v1.0.0
