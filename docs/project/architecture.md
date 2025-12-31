# Architecture du WP Adjuvans Starter Kit

## Vue d'ensemble

WP Adjuvans Starter Kit est un toolkit Bash pour l'installation automatisée et sécurisée de WordPress sur des hébergements mutualisés (OVH, o2switch, etc.).

## Principes architecturaux

### Conception modulaire

Le projet est organisé en modules indépendants et réutilisables :

```
cli/
├── install.sh              # Orchestrateur principal (wizard interactif)
├── init.sh                 # Initialisation de l'environnement
├── install-wordpress.sh    # Installation WordPress
├── install-plugins.sh      # Installation interactive des plugins
├── install-themes.sh       # Installation interactive des thèmes
├── backup.sh               # Système de sauvegarde
├── check-dependencies.sh   # Vérification des prérequis
├── diagnose-php.sh         # Diagnostic PHP (spécifique OVH)
├── install-phpwpinfo.sh    # Outil de diagnostic WordPress
└── lib/                    # Bibliothèques partagées
    ├── colors.sh           # Sortie colorée terminal
    ├── logger.sh           # Journalisation structurée
    ├── validators.sh       # Validation des entrées
    └── secure-wp-config.sh # Génération sécurisée de wp-config.php
```

### Séparation des responsabilités

| Composant | Responsabilité |
|-----------|----------------|
| `install.sh` | Orchestration, interface utilisateur, flux principal |
| `lib/*.sh` | Fonctions utilitaires réutilisables |
| `config/` | Configuration isolée et gitignorée |
| `logs/` | Journaux d'exécution |
| `save/` | Sauvegardes chiffrées |

## Flux d'exécution

### Installation WordPress

```
install.sh
    │
    ├── Source: lib/colors.sh, lib/logger.sh, lib/validators.sh
    │
    ├── Collecte des informations (wizard interactif)
    │   ├── Projet (nom, slug)
    │   ├── Base de données (host, name, user, pass)
    │   ├── WordPress (URL, titre, locale)
    │   ├── Admin (login, password, email)
    │   └── Backup (GPG, rétention)
    │
    ├── Génération: config/config.sh
    │
    ├── Appel: init.sh
    │   ├── Création des répertoires
    │   ├── Téléchargement WP-CLI (avec vérification SHA512)
    │   └── Configuration des permissions
    │
    └── Appel: install-wordpress.sh
        ├── Téléchargement WordPress
        ├── Génération wp-config.php (via lib/secure-wp-config.sh)
        ├── Installation de la base de données
        ├── Création de l'utilisateur admin
        └── Nettoyage (plugins/thèmes par défaut)
```

### Sauvegarde

```
backup.sh
    │
    ├── Export base de données (WP-CLI db export)
    ├── Archive des fichiers (tar + gzip)
    ├── Chiffrement optionnel (GPG AES256)
    ├── Rotation des anciennes sauvegardes
    └── Journalisation
```

## Sécurité par conception

### Gestion des credentials

```
┌─────────────────────────────────────────────────────────────┐
│ JAMAIS dans la ligne de commande (visible via ps aux)       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ config/config.sh (permissions 600, gitignored)              │
│   └── Variables sourcées par les scripts                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Fichiers temporaires sécurisés                              │
│   └── Utilisés pour passer les mots de passe à WP-CLI      │
└─────────────────────────────────────────────────────────────┘
```

### Validation des entrées

Toutes les entrées utilisateur passent par `lib/validators.sh` :

- `validate_email()` - Format email RFC 5322
- `validate_password()` - Force du mot de passe (12+ caractères, mixte)
- `validate_db_name()` - Nom de base de données SQL-safe
- `validate_slug()` - Slug alphanumérique avec tirets
- `validate_url()` - URL avec protocole

### Permissions fichiers

| Fichier/Dossier | Permission | Justification |
|-----------------|------------|---------------|
| Répertoires | 755 | Lecture/exécution publique |
| Fichiers | 644 | Lecture publique |
| `wp-config.php` | 400 | Lecture propriétaire uniquement |
| `.htaccess` | 400 | Lecture propriétaire uniquement |
| `config/config.sh` | 600 | Lecture/écriture propriétaire |

## Gestion des erreurs

Tous les scripts utilisent le mode strict Bash :

```bash
set -euo pipefail
```

- `set -e` : Arrêt immédiat sur erreur
- `set -u` : Erreur sur variable non définie
- `set -o pipefail` : Propagation des erreurs dans les pipes

## Journalisation

Le système de logs (`lib/logger.sh`) fournit :

- Horodatage ISO 8601
- Niveaux : INFO, WARN, ERROR, SUCCESS
- Sortie colorée en terminal
- Fichiers de log dans `logs/`

## Extensibilité

### Ajout d'un nouveau script

1. Créer le script dans `cli/`
2. Sourcer les bibliothèques nécessaires
3. Utiliser les fonctions de validation et logging
4. Ajouter une cible dans le `Makefile`

### Ajout d'une fonction utilitaire

1. Identifier la bibliothèque appropriée dans `lib/`
2. Documenter la fonction avec des commentaires
3. Tester via `tests/`

## Dépendances externes

| Dépendance | Usage | Téléchargement |
|------------|-------|----------------|
| WP-CLI | Gestion WordPress | Automatique via `init.sh` |
| GPG (optionnel) | Chiffrement des backups | Manuel (système) |
