# Collaboration avec l'IA

Ce projet est conçu pour être maintenu et développé en collaboration avec des assistants IA (Claude, etc.). Ce document décrit les conventions et processus établis.

## Système d'agents

### Concept

Les **agents** sont des prompts persistants définissant des rôles spécialisés. Chaque agent possède :

- Un contexte et des responsabilités définis
- Des règles et contraintes à respecter
- Des checklists et processus à suivre

### Convention de nommage

Les fichiers d'agents suivent le pattern `a.<nom-du-role>.md` :

```
docs/agents/
├── a.architect.md              # Architecte logiciel
├── a.developer-senior.md       # Développeur senior
├── a.documentation-maintainer.md # Mainteneur documentation
├── a.prompt-orchestrator.md    # Organisateur des prompts
├── a.release-publisher.md      # Gestionnaire de releases
└── a.security-maintainer.md    # Auditeur sécurité
```

### Agents disponibles

| Agent | Fichier | Responsabilités |
|-------|---------|-----------------|
| **Architecte** | `a.architect.md` | Décisions structurantes, validation des patterns, principes SOLID |
| **Développeur Senior** | `a.developer-senior.md` | Implémentation, standards de code, bonnes pratiques |
| **Documentation** | `a.documentation-maintainer.md` | Mise à jour docs, synchronisation README |
| **Orchestrateur** | `a.prompt-orchestrator.md` | Organisation du dossier docs/, classification |
| **Release** | `a.release-publisher.md` | Versioning sémantique, publication |
| **Sécurité** | `a.security-maintainer.md` | Audit, OWASP, checklist pré-release |

## Utilisation des agents

### Invoquer un agent

Pour utiliser un agent, référencer son fichier au début de la conversation :

```
@docs/agents/a.developer-senior.md

Implémente une nouvelle fonction de validation pour les URLs...
```

### Combiner plusieurs agents

Pour des tâches complexes, plusieurs agents peuvent être invoqués :

```
@docs/agents/a.architect.md
@docs/agents/a.security-maintainer.md

Propose une architecture pour le système de sauvegarde chiffrée...
```

## Prompts de tâches

### Distinction agents vs prompts

| Type | Emplacement | Caractéristiques |
|------|-------------|------------------|
| **Agents** | `docs/agents/` | Rôles durables, réutilisables, préfixés `a.` |
| **Prompts** | `docs/prompts/` | Tâches ponctuelles, procédures spécifiques |
| **Archivés** | `docs/prompts/archived/` | Prompts obsolètes, conservés pour mémoire |

### Exemples de prompts de tâches

- Procédures de déploiement
- Scripts de migration
- Workflows de release

## Bonnes pratiques

### Pour l'IA

1. **Lire le contexte** : Consulter les fichiers d'agents pertinents
2. **Respecter les contraintes** : Suivre les règles définies dans chaque agent
3. **Documenter les décisions** : Expliquer le raisonnement
4. **Proposer avant d'agir** : Pour les changements structurels

### Pour les humains

1. **Mettre à jour les agents** : Quand les pratiques évoluent
2. **Archiver les prompts obsolètes** : Ne pas supprimer, déplacer vers `archived/`
3. **Maintenir la cohérence** : Entre agents et documentation projet

## Structure de la documentation

```
docs/
├── README.md                 # Index et navigation
├── agents/                   # Prompts d'agents (rôles durables)
│   ├── README.md
│   └── a.*.md
├── prompts/                  # Prompts de tâches (ponctuels)
│   ├── README.md
│   └── archived/             # Prompts obsolètes
└── project/                  # Documentation projet
    ├── README.md
    ├── architecture.md       # Architecture technique
    ├── technical-requirements.md
    ├── security.md
    ├── ai-collaboration.md   # Ce fichier
    └── roles.md              # Mapping rôles → agents
```

## Workflow de collaboration

### Nouvelle fonctionnalité

```
1. @a.architect.md        → Validation de l'approche
2. @a.developer-senior.md → Implémentation
3. @a.security-maintainer.md → Audit sécurité
4. @a.documentation-maintainer.md → Mise à jour docs
```

### Correction de bug

```
1. @a.developer-senior.md → Analyse et fix
2. @a.security-maintainer.md → Vérification impact sécurité (si pertinent)
```

### Release

```
1. @a.release-publisher.md → Préparation et publication
2. @a.documentation-maintainer.md → Mise à jour CHANGELOG
```

## Configuration Claude Code

Le projet utilise Claude Code avec une configuration dans `.claude/` :

- Contexte projet pré-chargé
- Règles de formatage
- Exclusions de fichiers sensibles

## Évolution du système

Ce système d'agents est évolutif. Pour ajouter un nouvel agent :

1. Créer `docs/agents/a.<nouveau-role>.md`
2. Définir contexte, responsabilités, contraintes
3. Mettre à jour `docs/project/roles.md`
4. Mettre à jour ce document si nécessaire
