#!/bin/bash
# Run pytest tests for pre-commit hook
# Handles missing .venv gracefully

set -euo pipefail

if [ -d ".venv" ]; then
    # shellcheck source=/dev/null
    source .venv/bin/activate
    python -m pytest tests/python/ -q --tb=short
else
    echo "Warning: .venv not found, skipping pytest"
    echo "To set up: python -m venv .venv && pip install -r requirements-dev.txt"
fi
