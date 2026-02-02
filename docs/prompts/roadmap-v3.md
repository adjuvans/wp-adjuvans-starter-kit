# Prompt : Evolutions Majeures WPASK v3.0

## Contexte

Ce prompt decrit les evolutions majeures demandees par le PO pour etendre les capacites du WP Adjuvans Starter Kit (WPASK) a :

1. La gestion d'installations WordPress multisite
2. La conversion de sites existants vers multisite
3. L'adoption de sites WordPress existants (non crees avec WPASK)
4. **Script de restauration de backups (critique)**
5. **Tests d'integration et CI/CD**
6. **Script de scan securite**
7. **Audit et refonte documentation**
8. **Politique de versions et releases GitHub**

## Objectif global

Permettre au toolkit de gerer des installations WordPress plus complexes, assurer la fiabilite via tests automatises, et renforcer la securite - tout en conservant sa philosophie : securite, automatisation et compatibilite hebergements mutualises.

---

## User Story 1 : Installation WordPress Multisite

### Description

> En tant qu'utilisateur du toolkit,
> Je veux pouvoir installer un WordPress en mode multisite,
> Afin de gerer plusieurs sites depuis une seule installation WordPress.

### Contraintes (decisions PO)

- **Version minimum WordPress** : 6.0
- **Deux modes supportes** : sous-domaines ET sous-repertoires
- **Bascule entre modes** : Possibilite de changer de mode apres installation

### Criteres d'acceptation

- [ ] Verification version WordPress >= 6.0
- [ ] Le wizard `install.sh` propose une option multisite (oui/non)
- [ ] Si multisite active, choix du type : sous-domaines ou sous-repertoires
  - [ ] Afficher recommandation : sous-repertoires = plus simple pour mutualises
  - [ ] Si sous-domaines : informer sur prerequis DNS et SSL
- [ ] Configuration automatique du `wp-config.php` pour multisite
- [ ] Configuration automatique du `.htaccess` pour multisite
- [ ] Activation du reseau via WP-CLI (`wp core multisite-install`)
- [ ] **Script de bascule** `cli/multisite-switch-mode.sh` :
  - [ ] Sous-domaines → sous-repertoires
  - [ ] Sous-repertoires → sous-domaines
  - [ ] Backup obligatoire avant bascule
  - [ ] Mise a jour automatique URLs des sous-sites
- [ ] Documentation mise a jour avec les specificites multisite
- [ ] Tests de validation pour l'installation multisite

### Considerations techniques

- **Sous-domaines** :
  - Necessite wildcard DNS (`*.example.com`) OU creation manuelle de chaque sous-domaine
  - Certificat SSL wildcard recommande (ou Let's Encrypt par sous-domaine)
  - Le script doit **informer l'utilisateur** de ces prerequis
- **Sous-repertoires** :
  - Plus simple, fonctionne sur tous les hebergements mutualises
  - Le script doit **recommander ce mode** pour les hebergements mutualises
- **Bascule de mode** : Necessite search-replace sur toutes les URLs des sous-sites

---

## User Story 2 : Conversion vers Multisite

### Description

> En tant qu'utilisateur du toolkit,
> Je veux pouvoir analyser un site WordPress existant et le convertir en multisite,
> Afin de migrer progressivement vers une architecture multisite.

### Contraintes (decisions PO)

- **Version minimum WordPress** : 6.0
- **WordPress a la racine** : Conversion impossible si WP dans sous-repertoire (detecter et signaler)
- **Backup OBLIGATOIRE** : Aucune conversion sans backup prealable (pas d'option pour skip)
- **Deux modes supportes** : Choix sous-domaines ou sous-repertoires lors de la conversion

### Criteres d'acceptation

- [ ] Nouveau script `cli/convert-to-multisite.sh`
- [ ] Analyse pre-conversion :
  - [ ] Version WordPress compatible (>= 6.0)
  - [ ] **Detection emplacement WordPress** : doit etre a la racine du domaine (pas dans /blog/, /wp/, etc.)
    - [ ] Si non-racine : abandon avec message explicatif
  - [ ] Aucun conflit de plugins connu
  - [ ] Sauvegarde automatique avant conversion
  - [ ] Verification espace disque suffisant
- [ ] Conversion automatisee :
  - [ ] Backup complet (DB + fichiers)
  - [ ] Mise a jour `wp-config.php`
  - [ ] Mise a jour `.htaccess`
  - [ ] Execution `wp core multisite-convert`
  - [ ] Verification post-conversion
- [ ] Rollback automatique en cas d'echec
- [ ] Rapport de conversion detaille

### Workflow propose

```
1. Analyse du site existant
   └── Verification compatibilite
   └── Detection plugins problematiques
   └── Estimation ressources necessaires

2. Preparation
   └── Backup automatique via backup.sh
   └── Point de restauration cree

3. Conversion
   └── Modification wp-config.php
   └── Modification .htaccess
   └── wp core multisite-convert

4. Validation
   └── Tests de connectivite
   └── Verification admin accessible
   └── Tests plugins critiques

5. Finalisation ou Rollback
   └── Succes : nettoyage fichiers temporaires
   └── Echec : restauration automatique du backup
```

### Risques identifies

- **WordPress dans un sous-repertoire** : conversion impossible, message explicatif
- Plugins non compatibles multisite
- Themes non compatibles multisite
- Permaliens custom a reconfigurer
- Certificats SSL a adapter pour sous-domaines

---

## User Story 3 : Adoption de Sites Existants

### Description

> En tant qu'utilisateur du toolkit,
> Je veux pouvoir adopter un site WordPress existant (non cree avec WPASK),
> Afin qu'il puisse beneficier des outils du kit (backup, maintenance, etc.).

### Contraintes (decisions PO)

- **Installations standard uniquement** : wp-content a la racine, structure classique
- **Detection non-standard** : Si installation non-standard detectee, abandon avec message explicatif
- **Local uniquement** : Pas de support SSH pour sites distants

### Criteres d'acceptation

- [ ] Nouveau script `cli/adopt-site.sh`
- [ ] **Detection installation non-standard** :
  - [ ] Verifier presence wp-content/ a la racine
  - [ ] Verifier absence de WP_CONTENT_DIR custom dans wp-config.php
  - [ ] Verifier structure standard (wp-admin/, wp-includes/, wp-content/)
  - [ ] Si non-standard : **abandon avec message explicatif** listant les anomalies detectees
- [ ] Detection automatique de la configuration existante :
  - [ ] Chemin WordPress
  - [ ] Configuration base de donnees (depuis wp-config.php)
  - [ ] URL du site
  - [ ] Prefix des tables
- [ ] Generation du fichier `config/config.sh` depuis le site existant
- [ ] Verification de la compatibilite :
  - [ ] Version PHP suffisante
  - [ ] Version WordPress supportee
  - [ ] WP-CLI installable/disponible
- [ ] Integration non-intrusive (aucune modification du site)
- [ ] Validation que les outils fonctionnent :
  - [ ] `make backup` operationnel
  - [ ] `make check` operationnel
  - [ ] Logging fonctionnel

### Workflow propose

```
1. Detection
   └── Localisation du wp-config.php
   └── Extraction des parametres DB
   └── Detection URL et chemins

2. Analyse
   └── Version WordPress
   └── Version PHP
   └── Plugins installes
   └── Themes installes

3. Generation config
   └── Creation config/config.sh depuis donnees detectees
   └── Validation des credentials DB (connexion test)
   └── Configuration des chemins

4. Verification
   └── Test backup (dry-run)
   └── Test WP-CLI
   └── Rapport de compatibilite

5. Finalisation
   └── Instructions post-adoption
   └── Recommandations securite si necessaire
```

### Mode d'adoption

Le script doit fonctionner en deux modes :

1. **Mode interactif** : wizard avec questions/confirmations
2. **Mode automatique** : detection complete sans intervention (flag `--auto`)

### Structure cible apres adoption

```
projet/
├── wordpress/          # Lien symbolique ou chemin vers WP existant
├── config/
│   └── config.sh       # Genere depuis wp-config.php existant
├── logs/               # Cree par le toolkit
├── save/               # Cree par le toolkit
└── cli/                # Scripts du toolkit (copies ou lies)
```

---

## User Story 4 : Script de Restauration (CRITIQUE)

### Description

> En tant qu'utilisateur du toolkit,
> Je veux pouvoir restaurer un site depuis une sauvegarde,
> Afin de recuperer mon site en cas de probleme ou de migration.

### Contexte

Le script `backup.sh` existe et fonctionne, mais **aucun script de restore n'existe**. C'est une lacune critique : un backup sans restore est inutile.

### Contraintes (decisions PO)

- **Pas de retrocompatibilite** : Seuls les backups crees avec v2.0+ sont supportes
- **Migration domaine** : Option `--new-url` disponible des la v1

### Criteres d'acceptation

- [ ] Nouveau script `cli/restore.sh`
- [ ] Support des archives non-chiffrees (`.tar.gz`)
- [ ] Support des archives chiffrees GPG (`.tar.gz.gpg`)
- [ ] Modes de restauration :
  - [ ] Restauration complete (DB + fichiers)
  - [ ] Restauration DB uniquement (`--db-only`)
  - [ ] Restauration fichiers uniquement (`--files-only`)
- [ ] Verification integrite archive avant restauration
- [ ] Backup automatique du site actuel avant restauration (securite)
- [ ] Support dry-run (`--dry-run`) pour simuler
- [ ] Gestion des conflits (fichiers existants)
- [ ] Rapport de restauration detaille

### Workflow propose

```
1. Selection de l'archive
   └── Liste des backups disponibles dans save/
   └── Selection interactive ou par argument

2. Verification
   └── Integrite de l'archive (checksum si disponible)
   └── Dechiffrement GPG si necessaire
   └── Verification espace disque suffisant

3. Securite pre-restore
   └── Backup automatique du site actuel
   └── Point de restauration cree

4. Restauration
   └── Extraction fichiers vers wordpress/
   └── Import base de donnees via WP-CLI
   └── Mise a jour URLs si domaine different (search-replace)

5. Validation
   └── Test connectivite DB
   └── Test acces admin WordPress
   └── Verification fichiers critiques

6. Finalisation
   └── Nettoyage fichiers temporaires
   └── Rapport de restauration
   └── Instructions post-restore
```

### Options CLI

```bash
# Restauration complete interactive
./cli/restore.sh

# Restauration d'une archive specifique
./cli/restore.sh save/2025-01-15_backup.tar.gz

# Restauration DB uniquement
./cli/restore.sh --db-only save/2025-01-15_backup.tar.gz

# Restauration fichiers uniquement
./cli/restore.sh --files-only save/2025-01-15_backup.tar.gz

# Dry-run (simulation)
./cli/restore.sh --dry-run save/2025-01-15_backup.tar.gz

# Avec changement de domaine
./cli/restore.sh --new-url="https://nouveau-domaine.com" save/backup.tar.gz
```

### Considerations techniques

- Utiliser `wp db import` pour la DB
- Utiliser `wp search-replace` si changement de domaine
- Gerer les permissions fichiers apres extraction
- Supporter les backups crees avant v2.0 (retrocompatibilite)

---

## User Story 5 : Tests d'Integration et CI/CD

### Description

> En tant que developpeur du toolkit,
> Je veux une suite de tests automatises et un pipeline CI/CD,
> Afin de garantir la qualite et prevenir les regressions.

### Contexte

Actuellement seuls les tests unitaires pour `validators.sh` existent. Aucun test d'integration ni pipeline CI/CD.

### Criteres d'acceptation

#### Tests d'integration

- [ ] Framework de test : `bats-core` (Bash Automated Testing System)
- [ ] Tests pour chaque script CLI :
  - [ ] `test-init.bats` - Initialisation environnement
  - [ ] `test-check-dependencies.bats` - Verification dependances
  - [ ] `test-install-wordpress.bats` - Installation WordPress (mock)
  - [ ] `test-backup.bats` - Sauvegarde
  - [ ] `test-restore.bats` - Restauration
- [ ] Tests des bibliotheques :
  - [ ] `test-colors.bats`
  - [ ] `test-logger.bats`
  - [ ] `test-validators.bats` (migration depuis shell vers bats)
  - [ ] `test-secure-wp-config.bats`
- [ ] Fixtures et mocks pour simuler WordPress
- [ ] Tests sur environnements multiples (bash, dash, zsh)

#### Pipeline CI/CD (GitHub Actions)

- [ ] Fichier `.github/workflows/ci.yml`
- [ ] Jobs :
  - [ ] **lint** : shellcheck sur tous les scripts
  - [ ] **test** : execution bats-core
  - [ ] **test-matrix** : Ubuntu, macOS, versions Bash multiples
  - [ ] **security** : scan dependances et secrets
- [ ] Declenchement sur push et pull requests
- [ ] Badge status dans README.md
- [ ] Cache des dependances pour performance

### Structure proposee

```
tests/
├── bats/                    # Tests bats-core
│   ├── test-init.bats
│   ├── test-backup.bats
│   ├── test-restore.bats
│   └── ...
├── fixtures/                # Donnees de test
│   ├── wp-config-sample.php
│   ├── mock-wordpress/
│   └── sample-backup.tar.gz
├── helpers/                 # Fonctions helper pour tests
│   └── test-helper.bash
└── test-validators.sh       # Tests existants (a migrer)

.github/
└── workflows/
    └── ci.yml               # Pipeline CI/CD
```

### Exemple workflow GitHub Actions

```yaml
name: CI

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: ShellCheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './cli'

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install bats
        run: sudo apt-get install -y bats
      - name: Run tests
        run: bats tests/bats/

  test-matrix:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        bash: ['4.4', '5.0', '5.1']
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: make test
```

---

## User Story 6 : Script de Scan Securite

### Description

> En tant qu'utilisateur du toolkit,
> Je veux pouvoir scanner mon installation WordPress pour detecter les problemes de securite,
> Afin de maintenir mon site securise et a jour.

### Criteres d'acceptation

- [ ] Nouveau script `cli/security-scan.sh`
- [ ] Verifications WordPress :
  - [ ] `wp core verify-checksums` - Integrite fichiers core
  - [ ] `wp plugin list --update=available` - Plugins obsoletes
  - [ ] `wp theme list --update=available` - Themes obsoletes
  - [ ] Detection plugins/themes abandonnes
  - [ ] Detection plugins vulnerables (base WPScan si disponible)
- [ ] Verifications fichiers :
  - [ ] Permissions fichiers sensibles (wp-config.php, .htaccess)
  - [ ] Detection fichiers suspects (shells, backdoors patterns)
  - [ ] Verification .htaccess securise
  - [ ] Detection fichiers PHP dans uploads/
- [ ] Verifications configuration :
  - [ ] DISALLOW_FILE_EDIT active
  - [ ] Debug desactive en production
  - [ ] Salts/Keys definies et uniques
  - [ ] Prefix tables non-standard
- [ ] Verifications serveur :
  - [ ] Version PHP supportee
  - [ ] HTTPS actif
  - [ ] Headers securite (X-Frame-Options, etc.)
- [ ] Rapport de scan :
  - [ ] Score de securite global (A-F)
  - [ ] Liste des problemes par severite (critique, warning, info)
  - [ ] Recommandations de remediation
  - [ ] Export JSON optionnel (`--json`)

### Niveaux de severite

| Niveau | Exemples |
|--------|----------|
| **CRITIQUE** | Checksums invalides, fichiers PHP dans uploads, debug actif prod |
| **WARNING** | Plugins obsoletes, permissions trop permissives, prefix standard |
| **INFO** | Plugins sans MAJ recente, headers manquants |

### Output exemple

```
╔══════════════════════════════════════════════════════════════╗
║                    WPASK SECURITY SCAN                       ║
║                    Score: B (78/100)                         ║
╚══════════════════════════════════════════════════════════════╝

[CRITIQUE] 2 problemes
  ✗ Plugin 'contact-form-7' version 5.4 vulnerable (CVE-2023-XXXX)
  ✗ Fichier suspect: wp-content/uploads/2024/shell.php

[WARNING] 4 problemes
  ! 3 plugins ont des mises a jour disponibles
  ! wp-config.php permissions 644 (recommande: 400)
  ! Prefix tables 'wp_' (standard, recommande: custom)
  ! Header X-Content-Type-Options manquant

[INFO] 2 remarques
  ℹ Plugin 'akismet' derniere MAJ > 6 mois
  ℹ PHP 8.1 disponible (actuel: 7.4)

RECOMMANDATIONS:
  1. Mettre a jour contact-form-7 immediatement
  2. Supprimer le fichier suspect et scanner le site
  3. Executer: chmod 400 wp-config.php
```

### Options CLI

```bash
# Scan complet interactif
./cli/security-scan.sh

# Scan silencieux (exit code selon resultat)
./cli/security-scan.sh --quiet

# Export JSON
./cli/security-scan.sh --json > security-report.json

# Scan specifique
./cli/security-scan.sh --check=checksums,permissions,plugins

# Ignorer WPScan (si pas de cle API configuree)
./cli/security-scan.sh --skip-wpscan
```

### Configuration WPScan API

Script d'installation de la cle API WPScan :

```bash
# Configuration interactive de la cle API
./cli/setup-wpscan-api.sh

# Ou directement
./cli/setup-wpscan-api.sh --api-key="YOUR_API_KEY"

# Verification de la configuration
./cli/setup-wpscan-api.sh --check
```

La cle sera stockee dans `config/wpscan-api.key` (permissions 600, gitignored).

**Note** : Sans cle API, le scan fonctionne mais sans detection des CVE. Un message info rappelle de configurer la cle.

---

## User Story 7 : Audit et Refonte Documentation

### Description

> En tant qu'utilisateur du toolkit,
> Je veux une documentation complete, a jour et bien structuree,
> Afin de comprendre et utiliser toutes les fonctionnalites de WPASK.

### Contexte

La documentation actuelle date de la v1.x et n'a pas ete mise a jour pour refleter les evolutions v2.0. Certaines sections sont incompletes ou obsoletes.

### Criteres d'acceptation

- [ ] **Audit documentation existante** :
  - [ ] Inventaire de tous les fichiers docs existants
  - [ ] Identification des contenus obsoletes
  - [ ] Identification des manques (fonctionnalites non documentees)
  - [ ] Rapport d'audit avec recommandations
- [ ] **Refonte README.md principal** :
  - [ ] Structure claire : Installation, Usage rapide, Commandes, Configuration
  - [ ] Badges : CI status, version, license
  - [ ] Table des matieres auto-generee
  - [ ] Exemples d'usage concrets
  - [ ] Section FAQ
- [ ] **Documentation par fonctionnalite** :
  - [ ] Guide installation (`docs/project/installation.md`)
  - [ ] Guide backup/restore (`docs/project/backup-restore.md`)
  - [ ] Guide securite (`docs/project/security.md`)
  - [ ] Guide configuration (`docs/project/configuration.md`)
  - [ ] Reference CLI (`docs/project/cli-reference.md`)
- [ ] **Documentation troubleshooting** :
  - [ ] Erreurs courantes et solutions
  - [ ] Compatibilite hebergeurs (OVH, o2switch, Infomaniak)
  - [ ] Debug et logs
- [ ] **Coherence et qualite** :
  - [ ] Style uniforme (ton, formatage)
  - [ ] Liens internes fonctionnels
  - [ ] Screenshots/exemples a jour

### Livrables

| Document | Description |
|----------|-------------|
| `docs/AUDIT.md` | Rapport d'audit initial |
| `README.md` | Refonte complete |
| `docs/project/*.md` | Guides par fonctionnalite |
| `docs/troubleshooting/*.md` | Guides de depannage |
| `docs/CONTRIBUTING.md` | Guide contribution |

---

## User Story 8 : Politique de Versions et Releases

### Description

> En tant que mainteneur du toolkit,
> Je veux une politique de versioning claire et des releases automatisees,
> Afin d'assurer la tracabilite et faciliter les mises a jour utilisateurs.

### Criteres d'acceptation

#### Semantic Versioning

- [ ] Adoption stricte de SemVer 2.0 :
  - MAJOR : changements breaking (incompatibilites)
  - MINOR : nouvelles fonctionnalites retrocompatibles
  - PATCH : corrections de bugs retrocompatibles
- [ ] Documentation de la politique dans `VERSIONING.md`
- [ ] Pre-releases supportees (`-alpha`, `-beta`, `-rc`)

#### CHANGELOG

- [ ] Fichier `CHANGELOG.md` au format Keep a Changelog
- [ ] Sections : Added, Changed, Deprecated, Removed, Fixed, Security
- [ ] Mise a jour obligatoire a chaque PR/merge
- [ ] Lien vers les releases GitHub

#### GitHub Releases

- [ ] Workflow GitHub Actions pour releases automatiques
- [ ] Declenchement sur push de tag `v*`
- [ ] Notes de release auto-generees depuis CHANGELOG
- [ ] Assets attaches (archive du toolkit)
- [ ] Draft releases pour review avant publication

#### Workflow release

```
1. Mise a jour CHANGELOG.md
2. Bump version dans VERSION ou package.json
3. Commit "chore: release vX.Y.Z"
4. Tag git: git tag vX.Y.Z
5. Push tag: git push origin vX.Y.Z
6. GitHub Actions cree la release automatiquement
```

### Livrables

| Fichier | Description |
|---------|-------------|
| `VERSIONING.md` | Politique de versioning documentee |
| `CHANGELOG.md` | Historique des changements |
| `VERSION` | Fichier version (ou dans Makefile) |
| `.github/workflows/release.yml` | Workflow release automatique |

### Exemple workflow release.yml

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract version from tag
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          name: Release ${{ steps.version.outputs.VERSION }}
          body_path: CHANGELOG.md
          draft: true
          generate_release_notes: true
```

---

## Priorites suggerees

| Priorite | User Story | Justification |
|----------|------------|---------------|
| **P0** | US4 - Restore | **CRITIQUE** - Un backup sans restore est inutile |
| **P1** | US5 - Tests + CI/CD | Prerequis qualite avant nouvelles features |
| **P1** | US6 - Security Scan | Securite = priorite du projet |
| **P1** | US8 - Versioning + Releases | Prerequis pour releases propres |
| **P2** | US7 - Documentation | Facilite adoption et maintenance |
| **P2** | US3 - Adoption | Permet d'utiliser le toolkit sur sites existants |
| **P3** | US1 - Installation Multisite | Extension naturelle de l'installation existante |
| **P4** | US2 - Conversion Multisite | Plus complexe, necessite US1 fonctionnel |

---

## Agents a consulter

| Agent | Raison | User Stories |
|-------|--------|--------------|
| **Architect** | Validation architecture globale, integration avec existant | Toutes |
| **Developer WordPress Senior** | Implementation scripts, commandes WP-CLI | US1, US2, US3, US4 |
| **DevOps Senior** | Pipeline CI/CD, GitHub Actions, releases | US5, US8 |
| **Security Maintainer** | Script scan securite, validation securite multisite | US4, US6, US1 |
| **Test Engineer** | Framework tests, integration tests, fixtures | US5 |
| **Documentation Maintainer** | Audit doc, refonte, guides | US7, Toutes |
| **Release Publisher** | Politique versioning, workflow releases | US8 |

---

## Livrables attendus

### Scripts CLI

| Script | User Story | Priorite |
|--------|------------|----------|
| `cli/restore.sh` | US4 | P0 |
| `cli/security-scan.sh` | US6 | P1 |
| `cli/setup-wpscan-api.sh` | US6 | P1 |
| `cli/adopt-site.sh` | US3 | P2 |
| Modifications `cli/install.sh` | US1 | P3 |
| `cli/multisite-switch-mode.sh` | US1 | P3 |
| `cli/convert-to-multisite.sh` | US2 | P4 |

### Bibliotheques

| Bibliotheque | Description |
|--------------|-------------|
| `cli/lib/restore.sh` | Fonctions restauration |
| `cli/lib/security.sh` | Fonctions scan securite |
| `cli/lib/multisite.sh` | Fonctions partagees multisite |
| `cli/lib/wp-config-parser.sh` | Extraction config existante |

### Tests et CI/CD

| Fichier | Description |
|---------|-------------|
| `.github/workflows/ci.yml` | Pipeline CI/CD GitHub Actions |
| `tests/bats/*.bats` | Tests d'integration bats-core |
| `tests/fixtures/` | Donnees de test et mocks |
| `tests/helpers/test-helper.bash` | Fonctions helper tests |

### Documentation (US7)

| Document | Description |
|----------|-------------|
| `README.md` | Refonte complete avec badges, TOC, exemples |
| `docs/AUDIT.md` | Rapport d'audit documentation |
| `docs/project/installation.md` | Guide installation |
| `docs/project/backup-restore.md` | Guide backup et restauration |
| `docs/project/security.md` | Guide securite |
| `docs/project/configuration.md` | Guide configuration |
| `docs/project/cli-reference.md` | Reference complete CLI |
| `docs/project/multisite.md` | Guide multisite |
| `docs/project/testing.md` | Guide contribution tests |
| `docs/troubleshooting/*.md` | Guides de depannage |
| `docs/CONTRIBUTING.md` | Guide contribution |

### Versioning et Releases (US8)

| Fichier | Description |
|---------|-------------|
| `VERSIONING.md` | Politique de versioning |
| `CHANGELOG.md` | Historique des changements |
| `VERSION` | Fichier version |
| `.github/workflows/release.yml` | Workflow release automatique |

---

## Decisions PO (validees 2026-02-02)

### US4 - Restore (P0)

| Question | Decision |
|----------|----------|
| Retrocompatibilite backups < v2.0 | **NON** - Seuls les backups v2.0+ supportes |
| Migration domaine `--new-url` | **OUI** - Disponible des la v1 |
| Backup auto pre-restore | A definir |

### US5 - Tests + CI/CD (P1)

| Question | Decision |
|----------|----------|
| Framework de test | **bats-core** confirme |
| Matrice OS | **Linux + macOS** |
| Couverture minimum | A definir |

### US6 - Security Scan (P1)

| Question | Decision |
|----------|----------|
| WPScan API | **OUI** - Optionnel avec script d'installation cle API |
| Option ignorer WPScan | **OUI** - Flag `--skip-wpscan` si pas de cle configuree |
| Fix automatique `--fix` | **NON** - Rapport uniquement, corrections manuelles |
| Notifications | A definir |

### US3 - Adoption (P2)

| Question | Decision |
|----------|----------|
| Installations non-standard | **Standard uniquement** - Detecter et signaler si non-standard (abandon avec message explicatif) |
| Sites distants via SSH | **NON** - Local uniquement |

### US1/US2 - Multisite (P3/P4)

| Question | Decision |
|----------|----------|
| Modes multisite | **Les deux** (sous-domaines ET sous-repertoires) + option bascule entre modes |
| Version minimum WordPress | **6.0** (WP-CLI optimise, support securite actif, ~85% du parc mutualises FR) |
| Backup pre-conversion | **OUI** - Obligatoire avant toute conversion |
| Sous-domaines | Informer : wildcard DNS ou creation manuelle + certificat SSL |
| Sous-repertoires | Recommander : plus simple pour mutualises |
| WordPress racine | Detecter et signaler si WP pas a la racine (conversion impossible) |

### US7 - Documentation (P2)

| Question | Decision |
|----------|----------|
| Scope | **Audit + refonte complete** (pas juste mise a jour) |
| Focus prioritaire | README.md comme porte d'entree |
| Style | A definir (guide de style) |

### US8 - Versioning + Releases (P1)

| Question | Decision |
|----------|----------|
| Standard versioning | **SemVer 2.0** strict |
| Format changelog | **Keep a Changelog** |
| Releases | **GitHub Releases** avec notes auto-generees |
| Draft avant publication | **OUI** - Review avant publication |

---

## Notes techniques

### WP-CLI Multisite

```bash
# Installation multisite (sous-repertoires)
wp core multisite-install --title="Network" --base="/"

# Installation multisite (sous-domaines)
wp core multisite-install --title="Network" --subdomains

# Conversion site existant
wp core multisite-convert

# Creer un sous-site
wp site create --slug="nouveau-site" --title="Nouveau Site"
```

### Extraction wp-config.php

```bash
# Extraire DB_NAME
grep "DB_NAME" wp-config.php | cut -d"'" -f4

# Extraire table_prefix
grep "table_prefix" wp-config.php | cut -d"'" -f2
```

---

*Prompt cree le : 2026-02-02*
*Derniere MAJ : 2026-02-02*
*Statut : **VALIDE PAR LE PO** - Pret pour implementation*
*Version : 3.1* (ajout US7 Documentation, US8 Versioning)
