# Exigences techniques

## Prérequis système

### Dépendances obligatoires

| Outil | Version | Vérification | Rôle |
|-------|---------|--------------|------|
| **Bash** | ≥ 4.0 | `bash --version` | Interpréteur de scripts |
| **PHP** | ≥ 7.4 | `php -v` | Exécution WordPress et WP-CLI |
| **curl** | Any | `curl --version` | Téléchargement WP-CLI et WordPress |
| **tar** | Any | `tar --version` | Création d'archives |
| **gzip** | Any | `gzip --version` | Compression |
| **sha512sum** | Any | `sha512sum --version` | Vérification d'intégrité WP-CLI |

### Dépendances optionnelles

| Outil | Rôle | Alternative |
|-------|------|-------------|
| **mysql-client** | Opérations DB directes | WP-CLI gère la plupart des cas |
| **gpg** | Chiffrement des sauvegardes | Sauvegardes non chiffrées |
| **git** | Versioning | Non requis pour l'installation |

### Extensions PHP recommandées

```bash
# Vérifier les extensions installées
php -m | grep -E "(mysqli|curl|gd|imagick|mbstring|xml|zip)"
```

| Extension | Rôle | Obligatoire |
|-----------|------|-------------|
| `mysqli` | Connexion base de données | Oui |
| `curl` | Requêtes HTTP | Oui |
| `gd` ou `imagick` | Manipulation d'images | Recommandé |
| `mbstring` | Chaînes multi-octets | Recommandé |
| `xml` | Traitement XML | Recommandé |
| `zip` | Installation plugins/thèmes | Recommandé |

## Environnement d'exécution

### Hébergements compatibles

Le toolkit est conçu pour les hébergements mutualisés sans accès root :

- **OVH** (Web Hosting, Performance)
- **o2switch**
- **PlanetHoster**
- **Infomaniak**
- Tout hébergement avec SSH et PHP CLI

### Contraintes typiques

| Contrainte | Solution |
|------------|----------|
| Pas de Docker | Scripts Bash natifs |
| Pas de root/sudo | Permissions utilisateur uniquement |
| PHP via alias | `diagnose-php.sh` pour diagnostic |
| Limites mémoire | WP-CLI optimisé pour faible mémoire |

## Structure des répertoires

### Répertoires créés automatiquement

```
project/
├── wordpress/          # Installation WordPress (gitignored)
├── logs/               # Fichiers de log (gitignored)
├── save/               # Sauvegardes (gitignored)
└── config/
    └── config.sh       # Configuration générée (gitignored)
```

### Permissions attendues

| Chemin | Permission | Créé par |
|--------|------------|----------|
| `logs/` | 755 | `init.sh` |
| `save/` | 755 | `init.sh` |
| `config/` | 755 | Manuel ou `init.sh` |
| `config/config.sh` | 600 | `install.sh` |
| `wordpress/` | 755 | `install-wordpress.sh` |
| `wordpress/wp-config.php` | 400 | `install-wordpress.sh` |

## Réseau

### Accès sortants requis

| Destination | Port | Usage |
|-------------|------|-------|
| `raw.githubusercontent.com` | 443 | Téléchargement WP-CLI |
| `wordpress.org` | 443 | Téléchargement WordPress core |
| `api.wordpress.org` | 443 | Plugins et thèmes |
| `downloads.wordpress.org` | 443 | Archives plugins/thèmes |

### Configuration proxy (si nécessaire)

```bash
export http_proxy="http://proxy:port"
export https_proxy="http://proxy:port"
```

## Base de données

### Configuration MySQL/MariaDB

| Paramètre | Recommandation |
|-----------|----------------|
| Charset | `utf8mb4` |
| Collation | `utf8mb4_unicode_ci` |
| Préfixe tables | Personnalisé (pas `wp_`) |

### Création manuelle de la base

```sql
CREATE DATABASE nom_base CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'utilisateur'@'localhost' IDENTIFIED BY 'mot_de_passe';
GRANT ALL PRIVILEGES ON nom_base.* TO 'utilisateur'@'localhost';
FLUSH PRIVILEGES;
```

## Vérification des prérequis

### Commande de vérification

```bash
./cli/check-dependencies.sh
```

### Sortie attendue

```
---
# DEPENDENCY CHECK
[INFO] Checking required dependencies...

[✔] php (8.1.2)
[✔] curl (7.84.0)
[✔] tar (installed)
[✔] gzip (installed)
[✔] sha512sum (installed)

✔ ALL REQUIRED DEPENDENCIES SATISFIED

✔ System is ready for WordPress installation!
```

## Diagnostic avancé

### Pour les hébergements OVH

```bash
./cli/diagnose-php.sh
# ou
make diagnose-php
```

Ce script détecte :
- Version PHP réelle vs alias
- Extensions disponibles
- Limites mémoire et temps d'exécution
- Chemin PHP correct à utiliser

### Documentation complémentaire

Voir [TROUBLESHOOTING-OVH.md](../../TROUBLESHOOTING-OVH.md) pour les problèmes spécifiques OVH.
