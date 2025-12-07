"""
AI Function Tests using GitHub Models (GPT-4o-mini).

Uses GITHUB_TOKEN for authentication - no separate API key needed!
These tests verify basic connectivity and response capabilities.

Rate Limits (Free Tier):
- gpt-4o-mini: 15 RPM, 150,000 TPM
- gpt-4o: 10 RPM, 50,000 TPM

Tests are configured to respect rate limits with delays between requests.
"""

from __future__ import annotations

import os
import time
from typing import TYPE_CHECKING, Any

import pytest

if TYPE_CHECKING:
    from openai import OpenAI as OpenAIType
    from openai.types.chat import ChatCompletion

# GitHub Models configuration
ENDPOINT = "https://models.github.ai/inference"
MODEL = "openai/gpt-4o-mini"

# Rate limit configuration (15 RPM = 4 seconds minimum between requests)
# Using 5 seconds to be safe
REQUEST_DELAY_SECONDS = 5

# Try to import OpenAI client
try:
    from openai import OpenAI

    OPENAI_AVAILABLE = True
except ImportError:
    OpenAI = None  # type: ignore[misc,assignment]
    OPENAI_AVAILABLE = False


class RateLimitedClient:
    """Wrapper around OpenAI client that respects rate limits."""

    def __init__(self, client: OpenAIType) -> None:
        self._client = client
        self._last_request_time: float = 0

    def _wait_for_rate_limit(self) -> None:
        """Wait if needed to respect rate limits."""
        if self._last_request_time > 0:
            elapsed = time.time() - self._last_request_time
            if elapsed < REQUEST_DELAY_SECONDS:
                sleep_time = REQUEST_DELAY_SECONDS - elapsed
                time.sleep(sleep_time)
        self._last_request_time = time.time()

    def create_completion(self, **kwargs: Any) -> ChatCompletion:
        """Create a chat completion with rate limiting."""
        self._wait_for_rate_limit()
        return self._client.chat.completions.create(**kwargs)


# Module-level client instance for rate limiting across tests
_rate_limited_client: RateLimitedClient | None = None


@pytest.fixture(scope="module")
def client() -> RateLimitedClient:
    """Create rate-limited OpenAI client configured for GitHub Models."""
    global _rate_limited_client  # noqa: PLW0603

    if not OPENAI_AVAILABLE:
        pytest.skip("openai package not installed")

    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        pytest.skip("GITHUB_TOKEN not available")

    if _rate_limited_client is None:
        raw_client = OpenAI(base_url=ENDPOINT, api_key=token)
        _rate_limited_client = RateLimitedClient(raw_client)

    return _rate_limited_client


class TestGitHubModelsConnectivity:
    """Basic connectivity tests for GitHub Models API."""

    def test_api_connection(self, client: RateLimitedClient) -> None:
        """Test that we can connect to GitHub Models API."""
        response = client.create_completion(
            model=MODEL,
            messages=[{"role": "user", "content": "Say 'ok'"}],
            max_tokens=5,
        )
        assert response is not None
        assert response.choices is not None
        assert len(response.choices) > 0

    def test_simple_completion(self, client: RateLimitedClient) -> None:
        """Test basic chat completion returns valid response."""
        response = client.create_completion(
            model=MODEL,
            messages=[{"role": "user", "content": "Say 'test' and nothing else"}],
            max_tokens=10,
        )
        content = response.choices[0].message.content
        assert content is not None
        assert len(content) > 0

    def test_response_has_usage_info(self, client: RateLimitedClient) -> None:
        """Test that response includes token usage information."""
        response = client.create_completion(
            model=MODEL,
            messages=[{"role": "user", "content": "Hello"}],
            max_tokens=10,
        )
        assert response.usage is not None
        assert response.usage.prompt_tokens > 0
        assert response.usage.completion_tokens > 0


class TestGitHubModelsBasicFunctionality:
    """Test basic AI functionality."""

    def test_system_prompt_respected(self, client: RateLimitedClient) -> None:
        """Test that system prompt influences the response."""
        system_content = "You are a helpful assistant. Always start your response with 'HELLO:'"
        response = client.create_completion(
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

    def test_temperature_affects_output(self, client: RateLimitedClient) -> None:
        """Test that temperature parameter is accepted."""
        # Low temperature should work without errors
        response = client.create_completion(
            model=MODEL,
            messages=[{"role": "user", "content": "Say hello"}],
            max_tokens=10,
            temperature=0.0,
        )
        assert response.choices[0].message.content is not None

    def test_max_tokens_limit_respected(self, client: RateLimitedClient) -> None:
        """Test that max_tokens parameter limits response length."""
        response = client.create_completion(
            model=MODEL,
            messages=[{"role": "user", "content": "Write a very long story about a cat"}],
            max_tokens=5,
        )
        # Response should be truncated due to max_tokens
        assert response.usage is not None
        assert response.usage.completion_tokens <= 10  # Some tolerance
