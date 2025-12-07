"""Pytest configuration for AI tests using GitHub Models."""

from __future__ import annotations

import os

import pytest


def pytest_configure(config: pytest.Config) -> None:
    """Register custom markers."""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )


@pytest.fixture(scope="session")
def github_token() -> str | None:
    """Get GitHub token from environment."""
    return os.environ.get("GITHUB_TOKEN")


@pytest.fixture(scope="session")
def github_models_available(github_token: str | None) -> bool:
    """Check if GitHub Models API is accessible."""
    return github_token is not None
