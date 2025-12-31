# Sécurité

Ce document décrit les mesures de sécurité implémentées dans le WP Adjuvans Starter Kit.

## Principes de sécurité

### 1. Aucun credential en ligne de commande

Les mots de passe ne sont **jamais** passés en argument de commande :

```bash
# INTERDIT - Visible via `ps aux`
mysql -u user -ppassword database

# IMPLÉMENTÉ - Fichier temporaire sécurisé
mysql --defaults-extra-file=/tmp/secure_xxx database
```

### 2. Configuration isolée et protégée

```
config/
└── config.sh    # Permissions 600, gitignored
```

- Fichier non versionné (`.gitignore`)
- Permissions restrictives (lecture/écriture propriétaire)
- Généré par le wizard interactif

### 3. Validation systématique des entrées

Toutes les entrées utilisateur sont validées via `lib/validators.sh` avant utilisation.

## Gestion des credentials

### Flux sécurisé

```
┌──────────────────┐
│ Saisie utilisateur│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Validation       │ ← lib/validators.sh
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ config/config.sh │ ← Permissions 600, gitignored
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Fichier temp.    │ ← Créé, utilisé, supprimé immédiatement
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ wp-config.php    │ ← Permissions 400 (read-only)
└──────────────────┘
```

### Génération sécurisée de wp-config.php

Le script `lib/secure-wp-config.sh` :

1. Crée un fichier temporaire avec `mktemp`
2. Écrit la configuration avec les clés de sécurité WordPress
3. Déplace vers `wp-config.php`
4. Applique les permissions 400
5. Supprime toute trace temporaire

## Permissions fichiers

### Matrice des permissions

| Fichier/Dossier | Permission | Mode | Justification |
|-----------------|------------|------|---------------|
| Répertoires | 755 | drwxr-xr-x | Traversée nécessaire |
| Fichiers standards | 644 | -rw-r--r-- | Lecture web server |
| `wp-config.php` | 400 | -r-------- | Secrets uniquement propriétaire |
| `.htaccess` | 400 | -r-------- | Règles de sécurité critiques |
| `config/config.sh` | 600 | -rw------- | Secrets installation |
| `save/*.gpg` | 600 | -rw------- | Backups chiffrés |

### Application automatique

```bash
# Exécuté par install-wordpress.sh
find wordpress -type d -exec chmod 755 {} \;
find wordpress -type f -exec chmod 644 {} \;
chmod 400 wordpress/wp-config.php
chmod 400 wordpress/.htaccess
```

## Validation des entrées

### Fonctions de validation

| Fonction | Règles |
|----------|--------|
| `validate_email` | Format RFC 5322 |
| `validate_password` | 12+ caractères, majuscules, minuscules, chiffres |
| `validate_db_name` | Alphanumérique + underscore, max 64 caractères |
| `validate_slug` | Alphanumérique + tirets, lowercase |
| `validate_url` | URL avec protocole (http/https) |
| `validate_table_prefix` | Alphanumérique + underscore, termine par `_` |

### Exemple d'utilisation

```bash
source lib/validators.sh

if ! validate_email "$email"; then
    log_error "Email invalide"
    exit 1
fi
```

## Chiffrement des sauvegardes

### Configuration GPG

```bash
# Dans config/config.sh
USE_GPG_ENCRYPTION="true"
GPG_RECIPIENT="your@email.com"  # Vide = chiffrement symétrique
```

### Modes de chiffrement

| Mode | Configuration | Sécurité |
|------|--------------|----------|
| Symétrique | `GPG_RECIPIENT=""` | Mot de passe demandé |
| Clé publique | `GPG_RECIPIENT="email"` | Aucun mot de passe requis |
| Désactivé | `USE_GPG_ENCRYPTION="false"` | Archive non chiffrée |

### Algorithme

- Cipher : AES256
- Compression : gzip avant chiffrement
- Format : `.tar.gz.gpg`

## Hardening WordPress

### Mesures appliquées automatiquement

1. **Éditeur de fichiers désactivé**
   ```php
   define('DISALLOW_FILE_EDIT', true);
   ```

2. **Logs debug hors racine web**
   ```php
   define('WP_DEBUG_LOG', '/path/outside/webroot/debug.log');
   ```

3. **Commentaires désactivés par défaut**

4. **Plugins/thèmes par défaut supprimés**
   - Hello Dolly
   - Akismet
   - Thèmes Twenty* (sauf un)

### Règles .htaccess

```apache
# Protection contre l'injection SQL
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=http:// [OR]
    RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=https:// [OR]
    RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(\.\.//?)+ [OR]
    RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=ftp:// [OR]
    RewriteCond %{QUERY_STRING} mosConfig_[a-zA-Z_]{1,21}(=|\%3D) [OR]
    RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [OR]
    RewriteCond %{QUERY_STRING} ^.*(\[|\]|\(|\)|<|>|'|"|\.).*
    RewriteRule ^(.*)$ - [F,L]
</IfModule>

# Désactivation du directory listing
Options -Indexes
```

## Vérification d'intégrité

### WP-CLI

Le téléchargement de WP-CLI est vérifié via SHA512 :

```bash
# Téléchargement
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.sha512

# Vérification
sha512sum -c wp-cli.phar.sha512
```

En cas d'échec de vérification, l'installation est interrompue.

## Bonnes pratiques

### À faire

- [ ] Utiliser HTTPS (Let's Encrypt)
- [ ] Changer le nom d'utilisateur admin (jamais "admin")
- [ ] Activer l'authentification à deux facteurs
- [ ] Mettre à jour WordPress régulièrement
- [ ] Exécuter `./cli/backup.sh` via cron
- [ ] Surveiller les logs dans `logs/`

### À ne pas faire

- [ ] Ne jamais commiter `config/config.sh`
- [ ] Ne pas utiliser de mots de passe faibles
- [ ] Ne pas exposer `phpwpinfo.php` en production
- [ ] Ne pas désactiver les mises à jour automatiques de sécurité

## Signalement de vulnérabilités

Voir [SECURITY.md](../../SECURITY.md) pour la politique de sécurité et le processus de signalement.
