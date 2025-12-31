# Agents

Ce dossier contient les prompts d'agents persistants pour la collaboration IA.

## Convention de nommage

Chaque fichier suit le pattern `a.<nom-du-role>.md` et définit un rôle réutilisable et durable.

## Agents disponibles

| Agent | Fichier | Description |
|-------|---------|-------------|
| Architecte | `a.architect.md` | Décisions architecturales et validation des patterns |
| Développeur Senior | `a.developer-senior.md` | Implémentation et standards de code |
| Documentation | `a.documentation-maintainer.md` | Maintenance de la documentation |
| Orchestrateur | `a.prompt-orchestrator.md` | Organisation du dossier docs/ |
| Release Manager | `a.release-publisher.md` | Versioning et publication |
| Sécurité | `a.security-maintainer.md` | Audit et checklist sécurité |

## Utilisation

Pour invoquer un agent, référencer son fichier :

```
@docs/agents/a.developer-senior.md

Implémente une fonction de validation...
```

## Voir aussi

- [../project/roles.md](../project/roles.md) - Détail des responsabilités
- [../project/ai-collaboration.md](../project/ai-collaboration.md) - Guide de collaboration IA
