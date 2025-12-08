"""
Pytest configuration and fixtures for Python tests.

COVERAGE LIMITATION:
    Coverage tracking is limited due to dynamic imports via sys.path manipulation.
    coverage.py cannot reliably track modules imported after sys.path changes.

    Current approach: Track test count (332+ tests) instead of line coverage threshold.

    Future fix options:
    1. Convert scripts/ to proper Python package with __init__.py files
    2. Use pytest-pythonpath plugin instead of sys.path manipulation
    3. Configure PYTHONPATH in CI before running coverage
    4. Use `coverage run --source=scripts,conf` with explicit source paths

    See: tests/python/README.md for details
"""

import importlib.util
import sys
from pathlib import Path

import pytest

# Ensure repository root is on sys.path for module resolution (e.g., webhook_receiver shim)
ROOT = Path(__file__).resolve().parents[2]
root_str = str(ROOT)
if root_str not in sys.path:
    sys.path.insert(0, root_str)

# Add scripts directory to sys.path for coverage tracking
SCRIPTS_DIR = ROOT / "scripts"
scripts_str = str(SCRIPTS_DIR)
if scripts_str not in sys.path:
    sys.path.insert(0, scripts_str)


@pytest.fixture
def client():
    """Create a Flask test client for webhook_handler tests."""
    # Load webhook_handler module from the dashed directory
    module_path = ROOT / "conf" / "webhook-receiver" / "webhook_handler.py"
    spec = importlib.util.spec_from_file_location("webhook_handler", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook_handler from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["webhook_handler"] = module
    spec.loader.exec_module(module)

    app = module.app  # type: ignore
    app.testing = True
    return app.test_client()
