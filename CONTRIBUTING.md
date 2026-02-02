# Contributing to WP Adjuvans Starter Kit

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful, inclusive, and constructive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include:
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, shell, PHP version)
   - Relevant logs

### Suggesting Features

1. Open a discussion or issue
2. Describe the use case
3. Explain the proposed solution
4. Consider backward compatibility

### Pull Requests

1. Fork the repository
2. Create a feature branch from `dev`:
   ```bash
   git checkout dev
   git checkout -b feature/my-feature
   ```
3. Make your changes
4. Run tests: `make test`
5. Run linting: `make lint`
6. Commit with conventional commits
7. Push and create PR against `dev` branch

## Development Setup

```bash
# Clone the repo
git clone https://github.com/your-username/wp-adjuvans-starter-kit.git
cd wp-adjuvans-starter-kit

# Install development dependencies
# bats-core for testing
brew install bats-core  # macOS
# or
sudo apt install bats   # Ubuntu

# Run tests
make test

# Check syntax
make lint
```

## Coding Standards

### Shell Scripts

- Use POSIX-compatible syntax (`#!/bin/sh`)
- Enable strict mode: `set -eu`
- Add pipefail for bash: `[ -n "${BASH_VERSION:-}" ] && set -o pipefail || true`
- Comments in English
- Use functions for reusable logic
- Validate all user inputs
- Never expose credentials in logs or command line

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Scripts | `kebab-case.sh` | `security-scan.sh` |
| Functions | `snake_case` | `validate_email` |
| Variables | `UPPER_CASE` for constants | `SCRIPT_DIR` |
| Variables | `lower_case` for locals | `local result` |

### File Structure

```
cli/
├── script-name.sh     # Main scripts
└── lib/
    └── library.sh     # Shared functions

tests/
├── bats/
│   └── test-*.bats    # Test files
├── fixtures/          # Test data
└── helpers/           # Test utilities
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

Examples:
```
feat(restore): add --new-url option for domain migration
fix(backup): handle spaces in directory names
docs(readme): update installation instructions
```

## Testing

### Running Tests

```bash
# All tests
make test

# Specific test file
bats tests/bats/test-validators.bats

# With verbose output
bats tests/bats/ --verbose-run
```

### Writing Tests

```bash
#!/usr/bin/env bats

load '../helpers/test-helper'

setup() {
    # Runs before each test
    setup_temp_dir
}

teardown() {
    # Runs after each test
    teardown_temp_dir
}

@test "description of what is being tested" {
    run some_command
    assert_success
    [[ "$output" == *"expected"* ]]
}
```

## Documentation

- Update README.md for user-facing changes
- Update CHANGELOG.md under `[Unreleased]`
- Add/update docs in `docs/project/` for technical changes
- Keep docs in sync with code

## Release Process

See [VERSIONING.md](VERSIONING.md) for version policy.

1. Update CHANGELOG.md
2. Update VERSION file
3. Create PR to merge `dev` → `master`
4. After merge, tag the release: `git tag v2.x.x`
5. Push tag: `git push origin v2.x.x`
6. GitHub Actions creates the release

## Questions?

- Open a GitHub Discussion
- Check existing documentation in `docs/`

Thank you for contributing!
