# Versioning Policy

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

## Version Format

```
MAJOR.MINOR.PATCH[-PRERELEASE]
```

### Version Components

| Component | When to Increment | Example |
|-----------|-------------------|---------|
| **MAJOR** | Breaking changes that require user action | `2.0.0` → `3.0.0` |
| **MINOR** | New features, backward compatible | `2.0.0` → `2.1.0` |
| **PATCH** | Bug fixes, backward compatible | `2.0.1` → `2.0.2` |

### Pre-release Versions

Pre-release versions use suffixes:

- `-alpha.N` - Early development, unstable
- `-beta.N` - Feature complete, testing phase
- `-rc.N` - Release candidate, final testing

Example: `2.1.0-beta.1`

## What Constitutes a Breaking Change?

A breaking change is any modification that requires users to take action:

- Removed CLI options or commands
- Changed behavior of existing commands
- Modified backup format (not backward compatible)
- Changed configuration file format
- Removed support for a shell or platform

## Version Files

- `VERSION` - Contains the current version number
- `CHANGELOG.md` - Documents all changes per version

## Release Process

1. Update `CHANGELOG.md` with changes under `[Unreleased]`
2. Move unreleased changes to new version section
3. Update `VERSION` file
4. Commit: `git commit -m "chore: release vX.Y.Z"`
5. Tag: `git tag vX.Y.Z`
6. Push: `git push origin vX.Y.Z`
7. GitHub Actions creates the release automatically

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `master` | Stable releases only |
| `dev` | Development branch, PRs target here |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `release/*` | Release preparation |

## Deprecation Policy

When deprecating features:

1. Mark as deprecated in documentation
2. Add deprecation warning in code (if applicable)
3. Keep deprecated feature for at least 1 MINOR version
4. Remove in next MAJOR version

## Support Policy

| Version | Support Level |
|---------|---------------|
| Current MAJOR | Full support |
| Previous MAJOR | Security fixes only |
| Older | No support |
