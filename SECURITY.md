# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | :white_check_mark: |
| 1.x     | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. Email the maintainers directly (see repository contacts)
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Initial response**: Within 48 hours
- **Status update**: Within 7 days
- **Fix timeline**: Depends on severity (critical: ASAP, high: 30 days, medium: 90 days)

### Security Best Practices

When using this toolkit:

1. **Never commit `config/config.sh`** - Contains database credentials
2. **Use strong passwords** - Minimum 12 characters with mixed case, numbers
3. **Enable GPG encryption** - For backup files containing sensitive data
4. **Restrict file permissions** - `config.sh` should be 600, `wp-config.php` should be 640
5. **Keep WordPress updated** - Run `make update-all` regularly
6. **Run security scans** - Use `make security-scan` periodically

### Security Features

This toolkit implements several security measures:

- Credentials never passed via command line (prevents exposure in process list)
- Secure file permissions enforced during installation
- Optional GPG encryption for backups
- Input validation on all user inputs
- Security headers recommendations
- WordPress hardening (DISALLOW_FILE_EDIT, etc.)

See [docs/project/security.md](docs/project/security.md) for detailed security documentation.

## Acknowledgments

We appreciate responsible disclosure and will acknowledge security researchers who report valid vulnerabilities.
