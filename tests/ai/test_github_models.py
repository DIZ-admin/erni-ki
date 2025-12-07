"""
AI Function Tests using GitHub Models (GPT-4o-mini).

Uses GITHUB_TOKEN for authentication - no separate API key needed!
These tests verify basic connectivity and response capabilities.

Rate Limits (Free Tier):
- gpt-4o-mini: 15 RPM, 150,000 TPM
- gpt-4o: 10 RPM, 50,000 TPM

Tests use exponential backoff retry to handle rate limits gracefully.
"""

from __future__ import annotations

import os
import time
from typing import TYPE_CHECKING, Any

import pytest

if TYPE_CHECKING:
    from openai import OpenAI as OpenAIType
    from openai.types.chat import ChatCompletion

# GitHub Models configuration (sync with workflow env vars)
ENDPOINT = os.getenv("GITHUB_MODELS_ENDPOINT", "https://models.github.ai/inference")
MODEL = os.getenv("GITHUB_MODELS_MODEL", "openai/gpt-4o-mini")

# Rate limit configuration
REQUEST_DELAY_SECONDS = 10  # Base delay between requests
MAX_RETRIES = 3  # Number of retries on rate limit
INITIAL_BACKOFF = 15  # Initial backoff in seconds

# Try to import OpenAI client - explicit initialization to avoid CodeQL warning
OpenAI: Any = None
RateLimitError: Any = None
OPENAI_AVAILABLE = False
try:
    from openai import OpenAI as _OpenAI
    from openai import RateLimitError as _RateLimitError

    OpenAI = _OpenAI
    RateLimitError = _RateLimitError
    OPENAI_AVAILABLE = True
except ImportError:
    pass


class RateLimitedClient:
    """Wrapper around OpenAI client with rate limiting and retry logic."""

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
        """Create a chat completion with rate limiting and retry."""
        last_error = None

        for attempt in range(MAX_RETRIES + 1):
            self._wait_for_rate_limit()

            try:
                return self._client.chat.completions.create(**kwargs)
            except Exception as e:
                # Check if it's a rate limit error
                if RateLimitError is not None and isinstance(e, RateLimitError):
                    last_error = e
                    if attempt < MAX_RETRIES:
                        # Exponential backoff: 15s, 30s, 60s
                        backoff = INITIAL_BACKOFF * (2**attempt)
                        time.sleep(backoff)
                        continue
                # Re-raise non-rate-limit errors immediately
                raise

        # All retries exhausted
        if last_error:
            raise last_error
        msg = "All retries exhausted"
        raise RuntimeError(msg)


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
    """Basic connectivity test for GitHub Models API.

    Only one test to minimize API calls and avoid rate limits.
    """

    def test_api_connection_and_completion(self, client: RateLimitedClient) -> None:
        """Test API connectivity, completion, and usage info in one call."""
        response = client.create_completion(
            model=MODEL,
            messages=[{"role": "user", "content": "Say 'test' and nothing else"}],
            max_tokens=10,
        )

        # Verify response structure
        assert response is not None
        assert response.choices is not None
        assert len(response.choices) > 0

        # Verify content
        content = response.choices[0].message.content
        assert content is not None
        assert len(content) > 0

        # Verify usage info
        assert response.usage is not None
        assert response.usage.prompt_tokens > 0
        assert response.usage.completion_tokens > 0
