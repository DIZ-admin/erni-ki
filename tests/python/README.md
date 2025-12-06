# Python Test Suite

Comprehensive test coverage for Python automation scripts using pytest.

## Overview

- **Test Files**: 23 test modules
- **Total Tests**: 332 passing tests
- **Framework**: pytest 9.0+ with pytest-cov
- **Coverage**: Configured in `pyproject.toml`

## Running Tests

```bash
# Activate virtual environment
source .venv/bin/activate  # or: .venv/bin/python

# Run all tests
python -m pytest tests/python/ -v

# Run specific test file
python -m pytest tests/python/test_validate_networks.py -v

# Run with quiet mode
python -m pytest tests/python/ -q

# Run tests matching pattern
python -m pytest tests/python/ -k "network" -v
```

## Test Structure

### Core Infrastructure Tests

- `test_validate_networks.py` - Docker Compose network validation
- `test_validate_no_emoji.py` - Emoji validation for documentation
- `test_config_validation.py` - Configuration file validation

### Documentation Tests

- `test_docs_scripts.py` - Documentation generation scripts
- `test_visuals_links_check_additional.py` - Link and visual validation
- `test_validate_metadata_additional.py` - Metadata validation

### Service Tests

- `test_webhook_*.py` - Webhook handler and receiver tests
- `test_services.py` - Service health checks
- `test_ollama_exporter_app.py` - Ollama exporter tests

### Utility Tests

- `test_exporters.py` - Data exporters
- `test_logger.py` - Logging utilities
- `test_scripts_smoke.py` - Smoke tests for critical scripts

## Configuration

Test configuration is in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
minversion = "6.0"
addopts = "-ra -q"
testpaths = ["tests"]
```

## Pre-commit Integration

Tests run automatically on pre-commit:

```yaml
- id: pytest-check
  name: 'Python: run pytest tests'
  entry:
    bash -c 'source .venv/bin/activate && python -m pytest tests/python/ -q
    --tb=short'
```

## Coverage Notes

Due to dynamic module imports in tests (using `sys.path` manipulation),
traditional line coverage tracking is limited. Instead, we track:

- **Test Count**: 332 passing tests
- **Test Files**: 23 comprehensive test modules
- **Coverage Badge**: Shows total passing tests in README

Tests use a mix of:

- Direct module imports for unit testing
- subprocess calls for CLI integration testing
- Mock fixtures for external dependencies

## Adding New Tests

1. Create test file: `test_<feature_name>.py`
2. Import required modules:

   ```python
   import sys
   from pathlib import Path
   import pytest

   sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
   import your_module
   ```

3. Write test classes and functions:

   ```python
   class TestFeature:
       def test_basic_functionality(self):
           result = your_module.function()
           assert result == expected
   ```

4. Run tests: `pytest tests/python/test_<feature_name>.py -v`

## CI Integration

Tests run in GitHub Actions CI pipeline:

- Pre-commit hooks: All tests run before commit
- CI workflow: Tests run on all PRs
- Coverage reporting: Test count tracked in README badge
