"""
AI Function Tests using GitHub Models (GPT-4o-mini).

Uses GITHUB_TOKEN for authentication - no separate API key needed!
These tests verify basic connectivity and response capabilities.

Rate Limits (Free Tier):
- gpt-4o-mini: 15 RPM, 150,000 TPM
- gpt-4o: 10 RPM, 50,000 TPM
"""

from __future__ import annotations

import os

import pytest

# GitHub Models configuration
ENDPOINT = "https://models.github.ai/inference"
MODEL = "openai/gpt-4o-mini"


@pytest.fixture
def client():
    """Create OpenAI client configured for GitHub Models."""
    try:
        from openai import OpenAI
    except ImportError:
        pytest.skip("openai package not installed")

    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        pytest.skip("GITHUB_TOKEN not available")

    return OpenAI(base_url=ENDPOINT, api_key=token)


class TestGitHubModelsConnectivity:
    """Basic connectivity tests for GitHub Models API."""

    def test_api_connection(self, client) -> None:
        """Test that we can connect to GitHub Models API."""
        response = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": "Say 'ok'"}],
            max_tokens=5,
        )
        assert response is not None
        assert response.choices is not None
        assert len(response.choices) > 0

    def test_simple_completion(self, client) -> None:
        """Test basic chat completion returns valid response."""
        response = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": "Say 'test' and nothing else"}],
            max_tokens=10,
        )
        content = response.choices[0].message.content
        assert content is not None
        assert len(content) > 0

    def test_response_has_usage_info(self, client) -> None:
        """Test that response includes token usage information."""
        response = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": "Hello"}],
            max_tokens=10,
        )
        assert response.usage is not None
        assert response.usage.prompt_tokens > 0
        assert response.usage.completion_tokens > 0


class TestGitHubModelsBasicFunctionality:
    """Test basic AI functionality."""

    def test_system_prompt_respected(self, client) -> None:
        """Test that system prompt influences the response."""
        system_content = "You are a helpful assistant. Always start your response with 'HELLO:'"
        response = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": system_content},
                {"role": "user", "content": "What is 2+2?"},
            ],
            max_tokens=50,
        )
        content = response.choices[0].message.content
        assert content is not None
        # System prompt should influence the response format
        assert "HELLO:" in content or "hello:" in content.lower()

    def test_temperature_affects_output(self, client) -> None:
        """Test that temperature parameter is accepted."""
        # Low temperature should work without errors
        response = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": "Say hello"}],
            max_tokens=10,
            temperature=0.0,
        )
        assert response.choices[0].message.content is not None

    def test_max_tokens_limit_respected(self, client) -> None:
        """Test that max_tokens parameter limits response length."""
        response = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": "Write a very long story about a cat"}],
            max_tokens=5,
        )
        # Response should be truncated due to max_tokens
        assert response.usage is not None
        assert response.usage.completion_tokens <= 10  # Some tolerance
