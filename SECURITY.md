# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest | :x:                |

We recommend always using the latest version from the `master` branch.

---

## Security Features

This project implements several security measures to protect your WordPress installation:

### 1. Credential Protection

- **No passwords in process lists**: Database and admin credentials are NEVER passed as command-line arguments
- **Secure file permissions**: Configuration files are set to `600` (owner read/write only)
- **Git-ignored secrets**: `config/config.sh` is excluded from version control
- **Temporary file security**: All temporary files use `chmod 600` and are cleaned up on exit

### 2. WordPress Hardening

- **File editor disabled**: `DISALLOW_FILE_EDIT` prevents code injection via admin panel
- **Read-only wp-config.php**: Permissions set to `400` (read-only)
- **Security headers**: `.htaccess` includes rules to prevent SQL injection, XSS, and path traversal
- **Directory browsing disabled**: `Options -Indexes` in `.htaccess`

### 3. Backup Security

- **Optional GPG encryption**: Backups can be encrypted with AES256
- **Secure storage**: Backups are stored outside the web root
- **Web access denied**: `.htaccess` rules prevent direct access to backup files

### 4. Input Validation

- **Email validation**: RFC-compliant email format checking
- **Password strength**: Minimum 12 characters, mixed case, digits required
- **SQL injection prevention**: Database names and table prefixes are validated
- **Path traversal protection**: All file paths are sanitized

---

## Reporting a Vulnerability

### DO NOT open a public GitHub issue for security vulnerabilities

If you discover a security vulnerability, please follow these steps:

### 1. Contact Us Privately

Send an email to: **cyrille@gourcy.net**

**Subject format:** `[SECURITY] Brief description of vulnerability`

### 2. Include the Following Information

Please provide as much information as possible:

- **Description**: Detailed explanation of the vulnerability
- **Impact**: What could an attacker achieve?
- **Affected versions**: Which versions are vulnerable?
- **Steps to reproduce**: Clear reproduction steps
- **Proof of concept**: Code or commands demonstrating the issue (if applicable)
- **Proposed solution**: If you have a fix, please share it
- **Your contact information**: For follow-up questions

### 3. Response Timeline

You can expect:

- **Initial response**: Within 48 hours
- **Status update**: Within 7 days
- **Fix timeline**: Depending on severity (see below)

### 4. Severity Levels and Response Times

| Severity | Description | Target Fix Time |
|----------|-------------|-----------------|
| **Critical** | Remote code execution, authentication bypass, database compromise | 24-48 hours |
| **High** | Privilege escalation, credential exposure, SQL injection | 1 week |
| **Medium** | XSS, CSRF, information disclosure | 2 weeks |
| **Low** | Minor information leaks, best practice violations | 1 month |

---

## Security Best Practices for Users

### 1. Credential Management

✅ **DO:**
- Use strong passwords (12+ characters, mixed case, numbers, symbols)
- Change default admin username (never use "admin")
- Store passwords in a password manager
- Use different passwords for database and admin account
- Enable GPG encryption for backups

❌ **DON'T:**
- Commit `config/config.sh` to version control
- Share configuration files via email or chat
- Reuse passwords across multiple sites
- Use simple passwords like "password123"

### 2. File Permissions

✅ **DO:**
- Keep `wp-config.php` at `400` (read-only)
- Set `config/config.sh` to `600` (owner only)
- Maintain directory permissions at `755`
- Keep regular files at `644`

❌ **DON'T:**
- Set overly permissive permissions (`777`)
- Allow group or world write access to sensitive files
- Run scripts as root unless absolutely necessary

### 3. Regular Maintenance

✅ **DO:**
- Update WordPress core regularly: `wp core update`
- Update plugins and themes: `wp plugin update --all`
- Run backups frequently (recommend daily via cron)
- Monitor logs in `logs/` directory
- Enable HTTPS with Let's Encrypt
- Keep your hosting environment up to date

❌ **DON'T:**
- Ignore WordPress security updates
- Leave debugging enabled in production
- Use outdated PHP versions (< 7.4)
- Disable security features for convenience

### 4. Hosting Security

✅ **DO:**
- Use a reputable hosting provider
- Enable firewall rules if available
- Use SSH keys instead of passwords
- Restrict database access to localhost
- Enable automatic MySQL backups
- Use HTTPS for all connections

❌ **DON'T:**
- Use FTP (use SFTP or SSH instead)
- Allow root MySQL access remotely
- Disable server security features
- Use default database port if avoidable

### 5. Backup Security

✅ **DO:**
- Enable GPG encryption for backups containing sensitive data
- Store backups in multiple locations (offsite)
- Test backup restoration regularly
- Limit backup retention to prevent disk exhaustion
- Secure backup directory with `.htaccess`

❌ **DON'T:**
- Store unencrypted backups in public directories
- Upload backups to insecure cloud storage
- Keep backups indefinitely without rotation
- Share backup encryption keys insecurely

---

## Known Security Considerations

### 1. Temporary Password Exposure (Mitigated)

**Issue**: During WordPress installation (`wp core install`), the admin password must be passed as a CLI argument, which briefly appears in the process list.

**Mitigation**:
- We generate a random temporary password
- The real password is immediately set via `wp user update` (more secure)
- Temporary password is stored in a file with `chmod 600`
- Temporary file is deleted on script exit

**Risk level**: **Low** (exposure window < 1 second)

### 2. Database Password in config.sh

**Issue**: Database password is stored in plain text in `config/config.sh`.

**Mitigation**:
- File permissions set to `600` (owner read/write only)
- File is excluded from git via `.gitignore`
- Alternative: Use environment variables or MySQL config files

**Risk level**: **Medium** (acceptable for shared hosting)

**Recommendation**: For production, consider using MySQL's `.my.cnf` file with `chmod 600`.

### 3. Backup Encryption Passphrase

**Issue**: If using symmetric GPG encryption, the passphrase must be entered manually during backup creation.

**Mitigation**:
- Use public-key encryption instead (set `GPG_RECIPIENT` in config)
- Or use a password manager to generate/store strong passphrases
- Never hardcode passphrases in scripts

**Risk level**: **Low** (user-managed risk)

---

## Security Checklist

Use this checklist after installation:

- [ ] Configuration file (`config/config.sh`) has permissions `600`
- [ ] Configuration file is NOT committed to git
- [ ] Admin password is strong (12+ characters, mixed case, digits, symbols)
- [ ] Admin username is NOT "admin"
- [ ] Database password is different from admin password
- [ ] HTTPS is enabled (Let's Encrypt or similar)
- [ ] WordPress core is up to date
- [ ] Plugins are up to date
- [ ] PHP version is ≥ 7.4
- [ ] `WP_DEBUG_DISPLAY` is `false` in production
- [ ] File editor is disabled (`DISALLOW_FILE_EDIT`)
- [ ] Backups are encrypted (if they contain sensitive data)
- [ ] Backups are tested (restoration verified)
- [ ] Logs directory is protected (`.htaccess` denies web access)
- [ ] WordPress search engines option is configured (Settings → Reading)
- [ ] SSH keys are used instead of passwords (if applicable)

---

## Responsible Disclosure

We support responsible disclosure of security vulnerabilities. If you report a security issue to us:

1. **We will acknowledge your report** within 48 hours
2. **We will investigate and validate** the vulnerability
3. **We will develop and test a fix** according to severity levels
4. **We will coordinate disclosure** with you
5. **We will credit you** in the security advisory (if desired)

### Hall of Fame

We recognize security researchers who have helped improve this project:

- *(No reports yet)*

---

## Security Updates

Security updates are announced via:

- **GitHub Security Advisories**: https://github.com/adjuvans/wp-adjuvans-starter-kit/security/advisories
- **Git Commit Messages**: Prefixed with `[SECURITY]`
- **CHANGELOG.md**: Listed under "Security" section

---

## Additional Resources

- [WordPress Security Best Practices](https://wordpress.org/support/article/hardening-wordpress/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [WP-CLI Security](https://wp-cli.org/)
- [GPG Encryption Guide](https://gnupg.org/documentation/)

---

## Contact

For security-related inquiries:

- **Email**: support@adjuvans.fr
- **PGP Key**: *(Coming soon)*

For general questions and support, please use [GitHub Issues](https://github.com/adjuvans/wp-adjuvans-starter-kit/issues).

---

**Last updated**: 2025-01-27
