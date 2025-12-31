# Documentation

Bienvenue dans la documentation du **WP Adjuvans Starter Kit**.

## Structure

```
docs/
├── README.md                 # Ce fichier (index)
├── agents/                   # Prompts d'agents IA persistants
│   ├── a.architect.md
│   ├── a.developer-senior.md
│   ├── a.documentation-maintainer.md
│   ├── a.prompt-orchestrator.md
│   ├── a.release-publisher.md
│   └── a.security-maintainer.md
├── prompts/                  # Prompts de tâches ponctuelles
│   └── archived/             # Prompts obsolètes
└── project/                  # Documentation technique
    ├── architecture.md
    ├── technical-requirements.md
    ├── security.md
    ├── ai-collaboration.md
    └── roles.md
```

## Navigation rapide

### Documentation technique

| Document | Description |
|----------|-------------|
| [project/architecture.md](project/architecture.md) | Architecture et structure du toolkit |
| [project/technical-requirements.md](project/technical-requirements.md) | Prérequis système et dépendances |
| [project/security.md](project/security.md) | Mesures de sécurité implémentées |

### Collaboration IA

| Document | Description |
|----------|-------------|
| [project/ai-collaboration.md](project/ai-collaboration.md) | Guide de travail avec les agents IA |
| [project/roles.md](project/roles.md) | Rôles et responsabilités |
| [agents/README.md](agents/README.md) | Index des agents disponibles |

### Agents disponibles

| Agent | Rôle |
|-------|------|
| [a.architect.md](agents/a.architect.md) | Décisions architecturales |
| [a.developer-senior.md](agents/a.developer-senior.md) | Implémentation et code |
| [a.security-maintainer.md](agents/a.security-maintainer.md) | Audit sécurité |
| [a.release-publisher.md](agents/a.release-publisher.md) | Versioning et releases |
| [a.documentation-maintainer.md](agents/a.documentation-maintainer.md) | Maintenance docs |
| [a.prompt-orchestrator.md](agents/a.prompt-orchestrator.md) | Organisation docs/ |

## Pour commencer

### Nouveau sur le projet ?

1. Lire [project/architecture.md](project/architecture.md) pour comprendre la structure
2. Consulter [project/technical-requirements.md](project/technical-requirements.md) pour les prérequis
3. Voir le [README principal](../README.md) pour l'installation

### Contribuer avec l'IA ?

1. Lire [project/ai-collaboration.md](project/ai-collaboration.md)
2. Identifier l'agent approprié dans [agents/](agents/)
3. Invoquer l'agent avec `@docs/agents/a.<role>.md`

## Documentation principale

La documentation utilisateur principale se trouve à la racine du projet :

- [README.md](../README.md) - Guide d'installation et utilisation
- [SECURITY.md](../SECURITY.md) - Politique de sécurité
- [CHANGELOG.md](../CHANGELOG.md) - Historique des versions
- [TROUBLESHOOTING-OVH.md](../TROUBLESHOOTING-OVH.md) - Guide OVH

## Conventions

### Nommage des fichiers

| Pattern | Type | Exemple |
|---------|------|---------|
| `a.<role>.md` | Agent persistant | `a.architect.md` |
| `<action>.md` | Prompt de tâche | `deploy-production.md` |
| `<sujet>.md` | Documentation | `architecture.md` |

### Langue

- Documentation technique : Français
- Code et commentaires : Anglais
- README principal : Anglais (public GitHub)
