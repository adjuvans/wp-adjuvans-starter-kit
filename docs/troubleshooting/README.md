# Dépannage (Troubleshooting)

Ce dossier contient les guides de dépannage pour les problèmes spécifiques aux différents environnements d'hébergement.

## Guides disponibles

| Guide | Description |
|-------|-------------|
| [ovh.md](ovh.md) | Dépannage spécifique aux hébergements mutualisés OVH |

## Problèmes communs

### PHP non trouvé

Sur certains hébergements mutualisés, la commande `php` peut ne pas fonctionner directement. Consultez le guide spécifique à votre hébergeur.

**Diagnostic rapide :**
```bash
./cli/diagnose-php.sh
```

### Permissions refusées

Vérifiez que les scripts sont exécutables :
```bash
chmod +x cli/*.sh cli/lib/*.sh
```

### Répertoires manquants

Créez les répertoires nécessaires :
```bash
mkdir -p logs save config
```

## Ajouter un guide

Pour ajouter un guide de dépannage pour un nouvel hébergeur :

1. Créer un fichier `<hebergeur>.md` dans ce dossier
2. Suivre la structure du guide OVH comme modèle
3. Mettre à jour ce README avec le nouveau guide
4. Mettre à jour [../README.md](../README.md) si nécessaire

## Voir aussi

- [../project/technical-requirements.md](../project/technical-requirements.md) - Prérequis système
- [../../README.md](../../README.md) - Documentation principale
