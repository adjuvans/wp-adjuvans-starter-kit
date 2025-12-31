# Sécurité

> **Note** : Ce document complète [SECURITY.md](../../SECURITY.md) à la racine du projet qui contient la politique de sécurité officielle et le processus de signalement de vulnérabilités.

Ce document décrit les mesures de sécurité implémentées dans le WP Adjuvans Starter Kit.

## Table des matières

- [Principes de sécurité](#principes-de-sécurité)
- [Gestion des credentials](#gestion-des-credentials)
- [Permissions fichiers](#permissions-fichiers)
- [Validation des entrées](#validation-des-entrées)
- [Chiffrement des sauvegardes](#chiffrement-des-sauvegardes)
- [Hardening WordPress](#hardening-wordpress)
- [Vérification d'intégrité](#vérification-dintégrité)
- [Considérations connues](#considérations-connues)
- [Bonnes pratiques](#bonnes-pratiques)
- [Checklist de sécurité](#checklist-de-sécurité)

---

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

### 4. Téléchargements sécurisés

Tous les téléchargements utilisent HTTPS avec TLS 1.2 minimum :

```bash
curl --proto '=https' --tlsv1.2 -sSf <url>
```

---

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

### Protection du mot de passe admin

Lors de l'installation WordPress :

1. Un mot de passe temporaire aléatoire (32 caractères) est utilisé
2. Le vrai mot de passe est immédiatement défini via `wp user update`
3. Le mot de passe temporaire est stocké dans un fichier `chmod 600`
4. Le fichier temporaire est supprimé à la fin du script

---

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

---

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

### Prévention des injections

- **SQL injection** : Noms de bases de données et préfixes de tables validés
- **Path traversal** : Tous les chemins sont normalisés
- **XSS** : Règles .htaccess de filtrage

---

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

---

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

---

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

### WordPress Core

Après installation, l'intégrité peut être vérifiée :

```bash
wp core verify-checksums
```

---

## Considérations connues

### 1. Exposition temporaire du mot de passe (Risque faible)

**Problème** : Pendant `wp core install`, le mot de passe admin doit être passé en argument CLI, ce qui l'expose brièvement dans la liste des processus.

**Atténuation** :
- Un mot de passe temporaire aléatoire est généré
- Le vrai mot de passe est immédiatement défini via `wp user update` (plus sécurisé)
- Le fichier temporaire a les permissions `chmod 600`
- Le fichier temporaire est supprimé à la fin du script

**Niveau de risque** : **Faible** (fenêtre d'exposition < 1 seconde)

### 2. Mot de passe base de données en clair

**Problème** : Le mot de passe de la base de données est stocké en clair dans `config/config.sh`.

**Atténuation** :
- Permissions du fichier : `600` (lecture/écriture propriétaire uniquement)
- Fichier exclu de git via `.gitignore`
- Alternative : utiliser les fichiers de config MySQL (`~/.my.cnf`)

**Niveau de risque** : **Moyen** (acceptable pour l'hébergement mutualisé)

### 3. Passphrase de chiffrement des sauvegardes

**Problème** : Avec le chiffrement GPG symétrique, la passphrase doit être entrée manuellement.

**Atténuation** :
- Utiliser le chiffrement par clé publique à la place (définir `GPG_RECIPIENT`)
- Ou utiliser un gestionnaire de mots de passe pour générer/stocker des passphrases fortes
- Ne jamais coder en dur les passphrases dans les scripts

**Niveau de risque** : **Faible** (risque géré par l'utilisateur)

---

## Bonnes pratiques

### ✅ À faire

- Utiliser HTTPS (Let's Encrypt)
- Changer le nom d'utilisateur admin (jamais "admin")
- Activer l'authentification à deux facteurs
- Mettre à jour WordPress régulièrement : `wp core update`
- Mettre à jour plugins et thèmes : `wp plugin update --all`
- Exécuter `./cli/backup.sh` via cron
- Surveiller les logs dans `logs/`
- Utiliser des mots de passe forts (12+ caractères, mixte)
- Utiliser des mots de passe différents pour la BDD et l'admin
- Activer le chiffrement GPG pour les sauvegardes
- Tester régulièrement la restauration des sauvegardes

### ❌ À ne pas faire

- Ne jamais commiter `config/config.sh`
- Ne pas utiliser de mots de passe faibles
- Ne pas exposer `phpwpinfo.php` en production
- Ne pas désactiver les mises à jour automatiques de sécurité
- Ne pas partager les fichiers de configuration via email ou chat
- Ne pas réutiliser les mots de passe sur plusieurs sites
- Ne pas utiliser FTP (utiliser SFTP ou SSH)
- Ne pas définir des permissions `777`

---

## Checklist de sécurité

Utilisez cette checklist après l'installation :

- [ ] Fichier de configuration (`config/config.sh`) a les permissions `600`
- [ ] Fichier de configuration n'est PAS commité dans git
- [ ] Mot de passe admin fort (12+ caractères, mixte, chiffres, symboles)
- [ ] Nom d'utilisateur admin n'est PAS "admin"
- [ ] Mot de passe BDD différent du mot de passe admin
- [ ] HTTPS activé (Let's Encrypt ou similaire)
- [ ] WordPress core à jour
- [ ] Plugins à jour
- [ ] Version PHP ≥ 7.4
- [ ] `WP_DEBUG_DISPLAY` est `false` en production
- [ ] Éditeur de fichiers désactivé (`DISALLOW_FILE_EDIT`)
- [ ] Sauvegardes chiffrées (si données sensibles)
- [ ] Sauvegardes testées (restauration vérifiée)
- [ ] Répertoire logs protégé (`.htaccess` refuse l'accès web)
- [ ] Option moteurs de recherche configurée (Réglages → Lecture)
- [ ] Clés SSH utilisées au lieu des mots de passe (si applicable)

---

## Signalement de vulnérabilités

**NE PAS ouvrir d'issue GitHub publique pour les vulnérabilités de sécurité.**

Pour signaler une vulnérabilité :
1. Envoyer un email à : **cyrille@gourcy.net**
2. Objet : `[SECURITY] Description brève de la vulnérabilité`

Voir [SECURITY.md](../../SECURITY.md) pour la politique de sécurité complète et le processus de divulgation responsable.

### Délais de réponse

| Sévérité | Description | Délai de correction |
|----------|-------------|---------------------|
| **Critique** | Exécution de code à distance, contournement d'authentification | 24-48 heures |
| **Haute** | Escalade de privilèges, exposition de credentials, injection SQL | 1 semaine |
| **Moyenne** | XSS, CSRF, divulgation d'informations | 2 semaines |
| **Faible** | Fuites mineures, violations de bonnes pratiques | 1 mois |

---

## Ressources additionnelles

- [WordPress Security Best Practices](https://wordpress.org/support/article/hardening-wordpress/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [WP-CLI Security](https://wp-cli.org/)
- [GPG Encryption Guide](https://gnupg.org/documentation/)
