# Contributing to ERNI-KI

Thank you for your interest in contributing to ERNI-KI! We appreciate all
contributions.

## Table of Contents

- [How to Contribute](#how-to-contribute)
- [Reporting Issues](#reporting-issues)
- [Proposing Improvements](#proposing-improvements)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## How to Contribute

### Reporting Issues

1.  **Search existing issues**: Check
    [Issues](https://github.com/DIZ-admin/erni-ki/issues) to avoid duplicates.
2.  **Use the template**: Provide detailed information using the issue template.
3.  **Reproduce**: Ensure the bug is reproducible and provide steps.

### Proposing Improvements

1.  **Discuss first**: Open a discussion in
    [Discussions](https://github.com/DIZ-admin/erni-ki/discussions).
2.  **Create Feature Request**: Describe the feature and the problem it solves.

### Improving Documentation

- Fix typos and grammar.
- Add usage examples.
- Translate documentation (current languages: `ru` default, `en`, `de`).
- **Note**: New code and configuration comments must be in **English**.
- Run `npm run lint:language` to check language policies.
- See `docs/reference/language-policy.md` for detailed rules.

## Development Workflow

### Branching Strategy

- **`main`**: Production releases.
- **`develop`**: Integration branch for ongoing work.
- **Feature branches**: `feature/<name>`, `fix/<name>`, `docs/<name>`.
- **Process**:
  1.  Branch from `develop` (or `main` for hotfixes).
  2.  Open PR to `develop`.
  3.  Pass all CI checks.
  4.  Squash merge.

### Pre-commit Hooks

We use `pre-commit` to ensure code quality.

```bash
# Install hooks
pip install -r requirements-dev.txt
pre-commit install
pre-commit install --hook-type commit-msg

# Run manually
pre-commit run --all-files
```

## coding Standards

### TypeScript/JavaScript

- Use strict typing.
- Prefer `async/await`.
- Run `npm run lint` (ESLint).

### Go

- Follow standard Go conventions.
- Use `gofmt` and `goimports`.

### Python

- Follow PEP 8.
- Use strict type hints.
- Run `ruff check .` .

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance

## Testing

Ensure all tests pass before submitting a PR.

```bash
# All tests
npm test

# Unit tests
npm run test:unit

# Go tests
cd auth && go test -v ./...
```

## Documentation

- Update `docs/reference/api-reference.md` for API changes.
- Update `docs/getting-started/user-guide.md` for new features.
- Primary documentation language is **Russian** (currently), but English is
  required for code/config.

## License

By contributing, you agree that your contributions will be licensed under the
MIT License.
