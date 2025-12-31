# Dépannage OVH

> **Note** : Ce fichier est une copie de [TROUBLESHOOTING-OVH.md](../../TROUBLESHOOTING-OVH.md) à la racine du projet.
> Pour les contributions, modifiez le fichier à la racine.

---

Ce document explique comment résoudre les problèmes spécifiques aux environnements d'hébergement mutualisé OVH.

## Table des matières

- [Problème d'alias PHP](#-important--problème-dalias-php-sur-ovh)
- [Diagnostic PHP](#-diagnostic-php)
- [Configuration manuelle](#️-configuration-manuelle-du-binaire-php)
- [Problèmes courants](#-problèmes-courants-ovh)
- [Checklist de dépannage](#-checklist-de-dépannage-ovh)
- [Installation en mode debug](#-installation-en-mode-debug)
- [Vérification post-installation](#-vérification-post-installation)
- [Ressources OVH](#-ressources-ovh)

---

## ⚠️ IMPORTANT : Problème d'alias PHP sur OVH

### Symptôme

Quand vous tapez `php` dans le terminal, vous obtenez :
```
-ovh_ssh: /usr/local/php7.0/bin/php: Aucun fichier ou dossier de ce type
```

Mais `which php` montre `/usr/local/php8.2/bin/php` et le diagnostic indique que PHP 8.2 est bien installé.

### Cause

OVH définit un **alias shell** ou une **fonction** pour `php` qui pointe vers un ancien chemin hardcodé. Cet alias est prioritaire sur la variable PATH.

### Solution 1 : Supprimer l'alias PHP (RECOMMANDÉ)

```bash
# Vérifier si c'est un alias
type php
# Si ça affiche "php is aliased to ..." ou "php is a function"

# Supprimer l'alias temporairement
unalias php 2>/dev/null || true

# Ou désactiver la fonction
unset -f php 2>/dev/null || true

# Vérifier que ça marche maintenant
php -v
```

**Rendre la correction permanente :**

Ajoutez dans votre `~/.bashrc` ou `~/.bash_profile` :

```bash
# Fix OVH PHP alias pointing to wrong version
unalias php 2>/dev/null || true
unset -f php 2>/dev/null || true
```

Puis rechargez :
```bash
source ~/.bashrc
```

### Solution 2 : Utiliser WP-CLI directement

Si WordPress est déjà installé, vous pouvez utiliser `wp` au lieu de `php wp-cli.phar` :

```bash
# Au lieu de :
php wp-cli.phar core version

# Utilisez :
wp core version
```

### Solution 3 : Utiliser le chemin complet

```bash
# Utiliser le chemin complet de PHP
/usr/local/php8.2/bin/php wp-cli.phar core version
```

### Vérifier si WordPress est installé

Si `wp core is-installed` ne retourne rien (code de sortie 0), WordPress EST déjà installé :

```bash
wp core is-installed && echo "WordPress est installé" || echo "WordPress n'est pas installé"
```

---

## 🔍 Diagnostic PHP

### Problème : "php: Aucun fichier ou dossier de ce type"

Sur les hébergements mutualisés OVH, le binaire PHP n'est pas toujours accessible via la commande `php` simple. Il peut être nécessaire d'utiliser une commande versionnée comme `php8.2`, `php8.1`, etc.

### Solution 1 : Script de diagnostic automatique

Lancez le script de diagnostic pour identifier quel PHP est disponible sur votre système :

```bash
./cli/diagnose-php.sh
```

Ce script va :
- Tester toutes les commandes PHP possibles (php, php8.3, php8.2, etc.)
- Vérifier les chemins absolus courants (/usr/bin/php, /usr/local/bin/php, etc.)
- Afficher votre variable PATH
- Recommander le binaire PHP à utiliser
- Détecter les alias problématiques

### Solution 2 : Test manuel

Si le script de diagnostic ne fonctionne pas, testez manuellement :

```bash
# Vérifier le type de commande
type php           # Peut montrer un alias ou une fonction
type -a php        # Montrer toutes les définitions

# Tester différentes commandes PHP
which php
which php8.2
which php8.1
which php8.0

# Afficher votre PATH
echo $PATH

# Lister les binaires PHP disponibles
ls -la /usr/bin/php*
ls -la /usr/local/bin/php*
ls -la /usr/local/php*/bin/php
```

### Solution 3 : Vérifier la configuration OVH

1. Connectez-vous à votre espace client OVH
2. Allez dans "Hébergements" → Votre hébergement
3. Cliquez sur "Configuration"
4. Vérifiez la version PHP active
5. Si nécessaire, changez la version PHP

---

## 🛠️ Configuration manuelle du binaire PHP

Si les scripts ne détectent pas automatiquement PHP, vous pouvez modifier manuellement le fichier `cli/install-wordpress.sh` :

1. Identifiez votre binaire PHP (exemple : `/usr/local/php8.2/bin/php`)
2. Éditez le fichier `cli/install-wordpress.sh`
3. Trouvez la ligne qui commence par `# Detect PHP binary`
4. Ajoutez en haut de la section de détection :

```bash
# Force PHP binary for OVH (use full path to bypass alias)
PHP_BIN="/usr/local/php8.2/bin/php"
log_info "Using forced PHP binary: ${PHP_BIN}"
```

---

## 🔧 Problèmes courants OVH

### Problème : Script bloque à "Installing WordPress database"

**Symptôme :**
```
# STEP 3/4: INSTALLING WORDPRESS DATABASE
[INFO] Creating WordPress database tables...
[le script se bloque ici indéfiniment]
```

**Causes possibles :**
1. PHP non trouvé ou non exécutable (alias pointant vers mauvais chemin)
2. WordPress déjà installé (le script attend confirmation)
3. Timeout de la base de données
4. Problème de connexion à la base de données

**Solutions :**

1. **Vérifier si WordPress est déjà installé :**
   ```bash
   cd wordpress
   wp core is-installed && echo "Déjà installé" || echo "Pas installé"

   # Voir la version
   wp core version

   # Tester l'accès admin
   wp user list
   ```

2. **Vérifier l'alias PHP :**
   ```bash
   type php
   # Si c'est un alias, le supprimer :
   unalias php
   ```

3. **Tester la connexion à la base de données :**
   ```bash
   mysql -h localhost -u votre_user -p votre_database -e "SELECT 1;"
   ```

4. **Tester WP-CLI manuellement avec wp (sans php) :**
   ```bash
   cd wordpress
   wp core version
   wp db check
   ```

5. **Réinstaller WordPress (ATTENTION : efface la base) :**
   ```bash
   wp db reset --yes
   wp core install \
     --url="votre-site.com" \
     --title="Mon Site" \
     --admin_user="admin" \
     --admin_password="VotreMotDePasse" \
     --admin_email="vous@example.com"
   ```

### Problème : Permission denied lors de l'écriture des logs

**Symptôme :**
```
./logs/2025-11-27_cli.log: Aucun fichier ou dossier de ce type
```

**Solution :**

1. Créer les répertoires manuellement :
   ```bash
   mkdir -p logs save config
   chmod 755 logs save config
   ```

2. Vérifier les permissions :
   ```bash
   ls -la logs/
   ```

### Problème : wp-config.php existe déjà

**Symptôme :**
```
mv : voulez-vous remplacer './wordpress/wp-config.php'
```

**Solution :**

Le script a été mis à jour pour gérer automatiquement ce cas avec `mv -f`. Si le problème persiste :

```bash
# Supprimer l'ancien wp-config.php
chmod 600 wordpress/wp-config.php
rm wordpress/wp-config.php

# Relancer l'installation
./cli/install-wordpress.sh
```

---

## 📋 Checklist de dépannage OVH

Avant de contacter le support, vérifiez :

- [ ] PHP est bien installé et accessible (`./cli/diagnose-php.sh`)
- [ ] Il n'y a pas d'alias PHP problématique (`type php`)
- [ ] La version PHP est ≥ 7.4 (`/usr/local/php8.2/bin/php -v`)
- [ ] WordPress n'est pas déjà installé (`wp core is-installed`)
- [ ] La base de données existe et est accessible
- [ ] Les credentials dans `config/config.sh` sont corrects
- [ ] Les permissions sont correctes (`chmod +x cli/*.sh cli/lib/*.sh`)
- [ ] Les répertoires logs/ et save/ existent
- [ ] WP-CLI est téléchargé (`ls -la wp-cli.phar`)
- [ ] Vous êtes dans le bon répertoire (`pwd`)

---

## 🚀 Installation en mode debug

Pour plus de détails lors de l'installation :

```bash
# Activer le mode debug shell
set -x

# Lancer l'installation
./cli/install-wordpress.sh

# Désactiver le mode debug
set +x
```

Cela affichera toutes les commandes exécutées et leurs résultats.

---

## 🎯 Vérification post-installation

Si vous pensez que WordPress est installé mais n'êtes pas sûr :

```bash
cd wordpress

# Vérifier l'installation
wp core is-installed && echo "✓ WordPress installé" || echo "✗ Pas installé"

# Afficher la version
wp core version

# Lister les utilisateurs
wp user list

# Vérifier les tables de la base
wp db tables

# Tester l'URL du site
wp option get siteurl
wp option get home

# Vérifier les thèmes
wp theme list

# Vérifier les plugins
wp plugin list
```

---

## 📞 Besoin d'aide ?

Si les solutions ci-dessus ne fonctionnent pas :

1. Lancez le script de diagnostic : `./cli/diagnose-php.sh`
2. Vérifiez les alias : `type php` et `type -a php`
3. Vérifiez l'installation : `wp core is-installed`
4. Sauvegardez la sortie complète
5. Créez une issue sur GitHub avec :
   - La sortie du diagnostic PHP
   - La sortie de `type php`
   - Les messages d'erreur complets
   - Votre environnement (OVH Performance, OVH Pro, etc.)
   - La version de votre formule d'hébergement

---

## 🔗 Ressources OVH

- [Configuration PHP sur les hébergements mutualisés OVH](https://docs.ovh.com/fr/hosting/configurer-le-php-sur-son-hebergement-web-mutu-2014/)
- [Accès SSH aux hébergements mutualisés OVH](https://docs.ovh.com/fr/hosting/mutualise-le-ssh-sur-les-hebergements-mutualises/)
- [Gérer une base de données sur un hébergement mutualisé](https://docs.ovh.com/fr/hosting/creer-base-de-donnees/)
