# Prompts

Ce dossier contient les prompts de tâches ponctuelles ou procédures spécifiques.

## Distinction avec les agents

| Type | Emplacement | Caractéristique |
|------|-------------|-----------------|
| **Agents** | `../agents/` | Rôles durables, réutilisables (préfixés `a.`) |
| **Prompts** | Ce dossier | Tâches ponctuelles, procédures |
| **Archivés** | `./archived/` | Prompts obsolètes conservés |

## Contenu actuel

*Aucun prompt de tâche actif pour le moment.*

## Sous-dossiers

| Dossier | Description |
|---------|-------------|
| `archived/` | Prompts et documents obsolètes, conservés pour référence historique |

## Ajouter un prompt

1. Créer un fichier `.md` dans ce dossier
2. Nommer clairement selon la tâche (ex: `deploy-production.md`)
3. Documenter le contexte et les étapes

## Archivage

Quand un prompt devient obsolète :

1. Le déplacer dans `archived/`
2. Mettre à jour `archived/README.md`
3. Ne jamais supprimer (conservation historique)

## Voir aussi

- [../agents/README.md](../agents/README.md) - Prompts d'agents persistants
- [../project/ai-collaboration.md](../project/ai-collaboration.md) - Guide de collaboration IA
