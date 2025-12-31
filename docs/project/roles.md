# Rôles et responsabilités

Ce document définit les rôles utilisés dans le projet et leur correspondance avec les agents IA.

## Vue d'ensemble

| Rôle | Agent | Focus principal |
|------|-------|-----------------|
| Architecte | [a.architect.md](../agents/a.architect.md) | Structure et patterns |
| Développeur Senior | [a.developer-senior.md](../agents/a.developer-senior.md) | Implémentation |
| Sécurité | [a.security-maintainer.md](../agents/a.security-maintainer.md) | Audit et protection |
| Release Manager | [a.release-publisher.md](../agents/a.release-publisher.md) | Versioning et publication |
| Documentation | [a.documentation-maintainer.md](../agents/a.documentation-maintainer.md) | Docs et README |
| Orchestrateur | [a.prompt-orchestrator.md](../agents/a.prompt-orchestrator.md) | Organisation docs/ |

## Détail des rôles

### Architecte

**Agent** : [a.architect.md](../agents/a.architect.md)

**Responsabilités** :
- Décisions architecturales structurantes
- Validation des design patterns
- Application des principes SOLID
- Revue des choix techniques majeurs

**Quand l'invoquer** :
- Nouvelle fonctionnalité majeure
- Refactoring significatif
- Choix de bibliothèque/outil

### Développeur Senior

**Agent** : [a.developer-senior.md](../agents/a.developer-senior.md)

**Responsabilités** :
- Implémentation du code
- Standards de codage (Bash, PHP)
- Tests et qualité
- Optimisation des performances

**Quand l'invoquer** :
- Écriture de nouveaux scripts
- Correction de bugs
- Amélioration de code existant

### Sécurité

**Agent** : [a.security-maintainer.md](../agents/a.security-maintainer.md)

**Responsabilités** :
- Audit de sécurité
- Vérification OWASP Top 10
- Checklist pré-release
- Revue des credentials et permissions

**Quand l'invoquer** :
- Avant chaque release
- Modification de la gestion des credentials
- Nouveau endpoint ou interface

### Release Manager

**Agent** : [a.release-publisher.md](../agents/a.release-publisher.md)

**Responsabilités** :
- Gestion du versioning sémantique
- Préparation des releases
- Mise à jour du CHANGELOG
- Coordination de la publication

**Quand l'invoquer** :
- Préparation d'une nouvelle version
- Bump de version (major/minor/patch)
- Création de tags Git

### Documentation Maintainer

**Agent** : [a.documentation-maintainer.md](../agents/a.documentation-maintainer.md)

**Responsabilités** :
- Rédaction et mise à jour de la documentation
- Synchronisation des README
- Détection du contenu obsolète
- Cohérence de la documentation

**Quand l'invoquer** :
- Après ajout d'une fonctionnalité
- Modification d'une API ou interface
- Revue périodique de la documentation

### Prompt Orchestrator

**Agent** : [a.prompt-orchestrator.md](../agents/a.prompt-orchestrator.md)

**Responsabilités** :
- Organisation du dossier `docs/`
- Classification des prompts (agents vs tâches)
- Application des conventions de nommage
- Archivage des prompts obsolètes

**Quand l'invoquer** :
- Réorganisation de la documentation
- Création d'un nouvel agent
- Nettoyage périodique

## Workflows types

### Nouvelle fonctionnalité

```
Architecte → Développeur Senior → Sécurité → Documentation
```

### Correction de bug critique

```
Développeur Senior → Sécurité → Release Manager
```

### Release

```
Release Manager → Documentation → (déploiement)
```

## Voir aussi

- [ai-collaboration.md](ai-collaboration.md) - Guide complet de collaboration IA
- [../agents/README.md](../agents/README.md) - Index des agents
