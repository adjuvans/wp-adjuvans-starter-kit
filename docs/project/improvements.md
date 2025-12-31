# Project Improvements & Future Enhancements

> **Note** : Ce fichier est une copie de [IMPROVEMENTS.md](../../IMPROVEMENTS.md) à la racine du projet.
> Pour les contributions, modifiez le fichier à la racine.

---

This document tracks the improvements made during the refactoring and suggests future enhancements.

---

## ✅ Completed Improvements

### Security Enhancements

| Issue | Status | Description |
|-------|--------|-------------|
| **Password exposure in CLI** | ✅ **FIXED** | Database and admin passwords no longer passed as CLI arguments. Using temporary files with `chmod 600` and immediate password rotation via `wp user update`. |
| **Credentials in config.sample.sh** | ✅ **FIXED** | Added missing `db_pass` and `admin_pass` variables to template. |
| **Unvalidated user inputs** | ✅ **FIXED** | Created `lib/validators.sh` with comprehensive validation functions (email, password strength, slugs, DB names, URLs, paths). |
| **Insecure downloads** | ✅ **FIXED** | Added `--proto '=https' --tlsv1.2` to all curl commands to prevent HTTP downgrade attacks. |
| **Plain-text backups** | ✅ **FIXED** | Implemented optional GPG encryption (AES256) with both symmetric and public-key modes in `backup.sh`. |
| **Inconsistent file permissions** | ✅ **FIXED** | Enforced permissions: 755 (dirs), 644 (files), 400 (wp-config.php, .htaccess), 600 (config.sh). |

### Bug Fixes

| Bug | Status | Description |
|-----|--------|-------------|
| **Wrong date format in backup.sh** | ✅ **FIXED** | Changed from `+%Y-%m-%y` (2-digit year) to `+%Y-%m-%d-%H%M%S` (correct format with timestamp). |
| **WP_DEBUG_LOG static date** | ✅ **FIXED** | Modified wp-config.php generation to use dynamic log file naming via PHP `date()` function. |
| **Missing error handling** | ✅ **FIXED** | Added `set -euo pipefail` to all scripts for strict error handling. |

### Code Quality Improvements

| Improvement | Status | Description |
|-------------|--------|-------------|
| **Structured logging system** | ✅ **IMPLEMENTED** | Created `lib/logger.sh` with `log_info()`, `log_warn()`, `log_error()`, `log_success()`, `log_fatal()` functions. All logs timestamped and saved to daily files. |
| **Color management** | ✅ **IMPLEMENTED** | Centralized terminal colors in `lib/colors.sh` with helper functions for consistent output. |
| **Input validation library** | ✅ **IMPLEMENTED** | Created reusable validators for email, password, slug, database names, URLs, usernames, table prefixes. |
| **Dependency checker** | ✅ **IMPLEMENTED** | New `cli/check-dependencies.sh` script verifies PHP version, extensions, and required commands. |
| **Interactive installer** | ✅ **IMPLEMENTED** | New `cli/install.sh` wizard with validation at each step, replacing manual config editing. |
| **Project structure** | ✅ **REORGANIZED** | Moved config to `config/` directory, created `lib/` for shared libraries, added `tests/` directory. |

### Documentation

| Document | Status | Description |
|----------|--------|-------------|
| **README.md** | ✅ **REWRITTEN** | Complete rewrite in English with: features, requirements, installation guide, usage, security section, troubleshooting. |
| **SECURITY.md** | ✅ **CREATED** | Comprehensive security policy with responsible disclosure process, best practices, known considerations. |
| **Makefile** | ✅ **CREATED** | Convenient `make` commands for common tasks (check, init, install, backup, compile, clean, etc.). |
| **.editorconfig** | ✅ **CREATED** | Coding style consistency across editors. |
| **.gitignore** | ✅ **UPDATED** | Comprehensive rules for WordPress, credentials, logs, backups, system files, IDEs. |

### New Features

| Feature | Status | Description |
|---------|--------|-------------|
| **GPG backup encryption** | ✅ **IMPLEMENTED** | Optional AES256 encryption for backups with symmetric or public-key modes. Configurable via `USE_GPG_ENCRYPTION` and `GPG_RECIPIENT`. |
| **Backup rotation** | ✅ **IMPLEMENTED** | Automatic deletion of old backups (configurable retention period via `BACKUP_RETENTION`). |
| **Secure wp-config.php generation** | ✅ **IMPLEMENTED** | New `lib/secure-wp-config.sh` creates wp-config.php without exposing credentials. Fetches WordPress salts from official API. |
| **Validation prompts** | ✅ **IMPLEMENTED** | Interactive prompts with retry logic (max 3 attempts) for validated inputs. |
| **Log cleanup** | ✅ **IMPLEMENTED** | Automatic removal of logs older than 30 days. |
| **Test suite** | ✅ **IMPLEMENTED** | Basic unit tests for validator functions in `tests/test-validators.sh`. |

---

## 🔄 Future Improvements (Recommended)

### Priority: High

#### 1. Complete Test Coverage

**Current state**: Only validator functions are tested.

**Proposed improvement**:
- Add integration tests for installation workflow
- Add tests for backup/restore functionality
- Add tests for permission enforcement
- Implement CI/CD pipeline (GitHub Actions)

**Files to create**:
```
tests/
├── test-validators.sh      # ✅ Done
├── test-installation.sh    # TODO
├── test-backup.sh          # TODO
├── test-permissions.sh     # TODO
└── run-all-tests.sh        # TODO
```

#### 2. Plugin Installation Script

**Current state**: Plugins listed in README, must be installed manually.

**Proposed improvement**:
Create `cli/plugins-install.sh` that:
- Installs recommended plugins from a config list
- Allows custom plugin lists per project
- Handles plugin activation and basic configuration

**Example implementation**:
```bash
# cli/plugins-install.sh
RECOMMENDED_PLUGINS="elementor wordpress-seo code-snippets"
for plugin in $RECOMMENDED_PLUGINS; do
    wp plugin install "$plugin" --activate
done
```

#### 3. Restore Script

**Current state**: Backup creation exists, but no restore script.

**Proposed improvement**:
Create `cli/restore.sh` that:
- Lists available backups
- Prompts user to select backup
- Decrypts if GPG-encrypted
- Extracts database and files
- Imports database via WP-CLI
- Restores file permissions

### Priority: Medium

#### 4. Environment Detection

**Current state**: No detection of hosting environment.

**Proposed improvement**:
- Detect shared hosting provider (OVH, o2switch, etc.)
- Auto-configure paths and settings based on environment
- Warn about environment-specific limitations

#### 5. WordPress Security Scan

**Current state**: Basic hardening, no scanning.

**Proposed improvement**:
Create `cli/security-scan.sh` that:
- Checks file permissions
- Scans for suspicious files
- Verifies WordPress core integrity (`wp core verify-checksums`)
- Checks for outdated plugins/themes
- Reviews user accounts for weak passwords

#### 6. Staging Environment Support

**Current state**: Single environment only.

**Proposed improvement**:
- Add `--env` flag (production, staging, development)
- Separate configs per environment
- Migration script between environments
- Search/replace URLs automatically

#### 7. Cron Job Setup

**Current state**: Manual backup execution.

**Proposed improvement**:
Create `cli/setup-cron.sh` that:
- Installs cron jobs for backups
- Configures WordPress cron
- Schedules log cleanup
- Allows customizable backup frequency

### Priority: Low

#### 8. ~~Theme Development Workflow~~ ❌ REMOVED

**Status**: **REMOVED** in v2.0.0

**Rationale**: SASS compilation was removed as it's out of scope for this installation toolkit. Theme development should use modern build tools (npm scripts, Vite, Webpack) integrated in the theme's own package.json.

Developers needing theme compilation workflows should set up their own build pipeline using:
- `npm` / `yarn` with scripts
- Vite for modern builds
- Webpack for legacy support
- PostCSS for CSS processing

#### 9. Multi-site Support

**Current state**: Single-site only.

**Proposed improvement**:
- Support WordPress multisite installation
- Network-level plugin management
- Per-site backups
- Domain mapping configuration

#### 10. Docker Option

**Current state**: No Docker support.

**Proposed improvement**:
- Optional `docker-compose.yml` for local development
- Maintain compatibility with shared hosting
- Easy switch between Docker and traditional setup

---

## 🐛 Known Limitations & Workarounds

### 1. Temporary Password Exposure (Low Risk)

**Issue**: During `wp core install`, a temporary password is briefly visible in process list.

**Current mitigation**:
- Temporary password is random (32 chars)
- Exposed for < 1 second
- Real password immediately set via `wp user update`

**Future improvement**: Explore WP-CLI environment variables or stdin input for passwords.

### 2. Database Password in Config File

**Issue**: Database password stored in plain text in `config/config.sh`.

**Current mitigation**:
- File permissions: `600` (owner only)
- File excluded from git

**Future improvement**: Support MySQL config files (`~/.my.cnf`) as alternative.

### 3. No Automated SSL Certificate

**Issue**: HTTPS must be configured manually.

**Future improvement**: Integrate Let's Encrypt automation (if hosting allows).

### 4. Limited Error Messages for Shared Hosting

**Issue**: Some error messages assume `apt-get` availability.

**Current mitigation**: Messages include manual installation hints.

**Future improvement**: Detect hosting type and provide specific instructions.

---

## 📊 Performance Optimizations (Optional)

### 1. Parallel Downloads

**Current state**: WP-CLI and WordPress downloaded sequentially.

**Proposed improvement**: Use background downloads where safe.

### 2. Incremental Backups

**Current state**: Full backups only.

**Proposed improvement**: Support for differential/incremental backups (using `rsync` or similar).

### 3. Compressed Log Storage

**Current state**: Plain text logs.

**Proposed improvement**: Automatic gzip compression for old logs.

---

## 🔐 Security Enhancements (Nice to Have)

### 1. Two-Factor Authentication

**Proposed**: Add instructions/script for 2FA plugin installation and configuration.

### 2. Security Headers Script

**Proposed**: Script to add security headers to Apache/Nginx config:
- Content-Security-Policy
- X-Frame-Options
- X-Content-Type-Options
- Strict-Transport-Security

### 3. Fail2Ban Integration

**Proposed**: Documentation for Fail2Ban setup to block brute-force attacks.

### 4. Web Application Firewall

**Proposed**: Instructions for installing ModSecurity or similar WAF.

---

## 📝 Documentation Enhancements

### 1. Video Tutorial

**Proposed**: Record installation walkthrough screencast.

### 2. Troubleshooting Database

**Proposed**: Expand troubleshooting section with:
- MySQL connection errors (all variants)
- Permission issues (detailed)
- Hosting-specific quirks (OVH, o2switch, etc.)

### 3. Migration Guide

**Proposed**: Document how to migrate existing WordPress to this kit.

### 4. Contribution Guide

**Proposed**: Create `CONTRIBUTING.md` with:
- Code style guidelines
- Pull request process
- Testing requirements
- Commit message format

---

## 🎯 Success Metrics

After implementation, we expect:

- **Security incidents**: 0 (no credential leaks, no compromised installations)
- **Installation time**: < 5 minutes (from clone to working WordPress)
- **User errors**: < 10% (validation prevents most mistakes)
- **Backup success rate**: > 99% (automated, tested)
- **Community adoption**: Target 100+ stars on GitHub

---

## 📅 Suggested Roadmap

### Phase 1: Core Stability
- ✅ Security fixes
- ✅ Bug fixes
- ✅ Documentation
- ✅ Basic tests
- 🔄 Integration testing
- 🔄 User acceptance testing

### Phase 2: Feature Completeness
- Restore script
- Plugin installer
- Security scanner
- Cron setup
- Complete test suite

### Phase 3: Advanced Features
- Staging environments
- Multi-site support
- Docker option
- Theme workflow improvements

### Phase 4: Community & Polish
- Video tutorials
- Hosting-specific guides
- Performance optimizations
- Community feedback integration

---

## 💡 Community Contributions Welcome

We welcome contributions in these areas:

- 🐛 **Bug reports**: Found an issue? Open a GitHub issue
- ✨ **Feature requests**: Have an idea? Start a discussion
- 📝 **Documentation**: Improve README, add translations
- 🧪 **Testing**: Add tests, report compatibility
- 🔧 **Code**: Submit pull requests for new features

---

**Last updated**: 2025-01-27
**Version**: 2.0.0 (Post-refactoring)
