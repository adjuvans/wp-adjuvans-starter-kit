# Backup & Restore Guide

Complete guide for backing up and restoring WordPress with WPASK.

## Overview

WPASK provides secure backup and restore capabilities:

- **Database export** via WP-CLI or mysqldump
- **Files compression** with tar/gzip
- **Optional GPG encryption** for sensitive data
- **Automatic rotation** to manage storage
- **Domain migration** support during restore

## Backup

### Quick Start

```bash
# Create a backup
make backup
```

### Backup Contents

Each backup archive contains:

```
backup-YYYY-MM-DD-HHMMSS_project.tar.gz
├── database.sql           # Full database dump
└── wordpress-files.tar.gz # WordPress files
```

### Configuration

Edit `config/config.sh`:

```bash
# Backup location
directory_backup="./save"

# Encryption (optional)
USE_GPG_ENCRYPTION="true"
GPG_RECIPIENT="your-email@example.com"

# Retention (number of backups to keep)
BACKUP_RETENTION="7"
```

### Encryption Options

#### No Encryption (default)

```bash
USE_GPG_ENCRYPTION="false"
```

Output: `*.tar.gz` (readable by anyone with file access)

#### Symmetric Encryption (password)

```bash
USE_GPG_ENCRYPTION="true"
GPG_RECIPIENT=""
```

You'll be prompted for a password. Output: `*.tar.gz.gpg`

#### Asymmetric Encryption (GPG key)

```bash
USE_GPG_ENCRYPTION="true"
GPG_RECIPIENT="your-email@example.com"
```

Requires GPG key pair. Output: `*.tar.gz.gpg`

### Backup Rotation

Old backups are automatically deleted to save space:

- Default: Keep last 7 backups
- Configure with `BACKUP_RETENTION`

### Scheduled Backups

Add to crontab for automatic backups:

```bash
# Daily at 2 AM
0 2 * * * cd /path/to/project && ./cli/backup.sh >> logs/backup-cron.log 2>&1

# Weekly on Sunday at 3 AM
0 3 * * 0 cd /path/to/project && ./cli/backup.sh >> logs/backup-cron.log 2>&1
```

---

## Restore

### Quick Start

```bash
# Interactive restore
make restore

# Or list available backups
make list-backups
```

### Restore Modes

#### Full Restore (default)

Restores both database and files:

```bash
./cli/restore.sh save/backup.tar.gz
```

#### Database Only

Restore only the database (keeps existing files):

```bash
./cli/restore.sh --db-only save/backup.tar.gz
```

Use case: Reverting content changes while keeping plugin/theme updates.

#### Files Only

Restore only files (keeps existing database):

```bash
./cli/restore.sh --files-only save/backup.tar.gz
```

Use case: Recovering corrupted files while keeping database intact.

### Domain Migration

Restore to a different domain:

```bash
./cli/restore.sh --new-url="https://new-domain.com" save/backup.tar.gz
```

This automatically:
1. Detects the old URL from the backup
2. Runs `wp search-replace` on all tables
3. Updates `siteurl` and `home` options
4. Flushes rewrite rules

### Dry Run

Simulate restore without making changes:

```bash
./cli/restore.sh --dry-run save/backup.tar.gz
```

### Safety Backup

By default, restore creates a safety backup before overwriting:

```bash
# To skip (not recommended)
./cli/restore.sh --skip-backup save/backup.tar.gz
```

### Encrypted Backups

GPG-encrypted backups are automatically detected and decrypted:

```bash
# You'll be prompted for password/key
./cli/restore.sh save/backup.tar.gz.gpg
```

---

## Troubleshooting

### Backup Issues

#### "WP-CLI not found"

The script falls back to mysqldump. To fix:

```bash
make init  # Installs WP-CLI
```

#### "GPG encryption failed"

1. Check GPG is installed: `gpg --version`
2. Verify recipient key exists: `gpg --list-keys your-email@example.com`
3. Try symmetric encryption (no recipient)

#### "Not enough disk space"

1. Check available space: `df -h`
2. Reduce retention: `BACKUP_RETENTION="3"`
3. Clean old backups: `make clean-backups`

### Restore Issues

#### "Archive not found"

Verify path and file exists:

```bash
ls -la save/
./cli/restore.sh save/exact-filename.tar.gz
```

#### "Invalid backup format"

Only WPASK v2.0+ backups are supported. Backup must contain:
- `database.sql`
- `wordpress-files.tar.gz`

#### "GPG decryption failed"

1. Ensure you have the correct passphrase
2. For asymmetric: verify private key exists
3. Check GPG agent: `gpg-agent --daemon`

#### "Database import failed"

1. Check database credentials in config
2. Verify database exists
3. Check MySQL/MariaDB is running
4. Try manual import: `wp db import database.sql`

#### "URL replacement failed"

Manual fix:

```bash
cd wordpress
wp search-replace 'old-url.com' 'new-url.com' --all-tables
wp option update siteurl 'https://new-url.com'
wp option update home 'https://new-url.com'
wp rewrite flush
```

---

## Best Practices

### Backup Strategy

1. **Regular backups**: Daily for active sites
2. **Before updates**: Always backup before WordPress/plugin updates
3. **Off-site storage**: Copy backups to external location
4. **Test restores**: Periodically verify backups work

### Security

1. **Enable encryption** for production backups
2. **Secure backup directory**: `chmod 700 save/`
3. **Don't commit backups** to git (already in .gitignore)
4. **Rotate GPG keys** periodically

### Storage Management

1. Set appropriate retention based on disk space
2. Monitor backup sizes over time
3. Consider compressed/incremental backups for large sites

---

## Command Reference

### backup.sh

```bash
./cli/backup.sh
```

No arguments. Uses configuration from `config/config.sh`.

### restore.sh

```bash
./cli/restore.sh [OPTIONS] [ARCHIVE]

Options:
  -h, --help          Show help
  -n, --dry-run       Simulate only
  -d, --db-only       Database only
  -f, --files-only    Files only
  -u, --new-url URL   Domain migration
  --skip-backup       Skip safety backup
  -l, --list          List backups
```

### Makefile

```bash
make backup        # Create backup
make restore       # Interactive restore
make list-backups  # List available backups
make clean-backups # Remove old backups
```
