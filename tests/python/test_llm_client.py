"""Unit tests for scripts/lib/llm_client.py."""

from __future__ import annotations

import importlib.util
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Add scripts directory to path for lib imports
scripts_dir = Path(__file__).parent.parent.parent / "scripts"
sys.path.insert(0, str(scripts_dir))

from lib.llm_client import (  # noqa: E402
    LLMClient,
    LLMClientError,
    LLMConfig,
    LLMResponse,
    get_llm_client,
)

# Check if openai is available for integration tests
OPENAI_AVAILABLE = importlib.util.find_spec("openai") is not None

requires_openai = pytest.mark.skipif(not OPENAI_AVAILABLE, reason="openai package not installed")


class TestLLMConfig:
    """Tests for LLMConfig dataclass."""

    def test_default_values(self):
        """Test default configuration values."""
        with patch.dict(os.environ, {}, clear=True):
            config = LLMConfig()

        assert config.endpoint == "http://litellm:4000/v1"
        assert config.model == "gpt-4o-mini"
        assert config.timeout == 300.0
        assert config.max_retries == 3

    def test_env_override(self):
        """Test environment variable overrides."""
        env = {
            "LITELLM_ENDPOINT": "http://custom:8000/v1",
            "LITELLM_API_KEY": "test-key",  # pragma: allowlist secret
            "LITELLM_MODEL": "custom-model",
            "GITHUB_TOKEN": "github-token",  # pragma: allowlist secret
        }
        with patch.dict(os.environ, env, clear=True):
            # Pass empty strings to trigger env loading in __post_init__
            config = LLMConfig(endpoint="", api_key="", model="")

        assert config.endpoint == "http://custom:8000/v1"
        assert config.api_key == "test-key"  # pragma: allowlist secret
        # Note: model has a hardcoded default, but env is checked
        assert config.fallback_api_key == "github-token"  # pragma: allowlist secret

    def test_has_litellm(self):
        """Test LiteLLM configuration detection."""
        with patch.dict(
            os.environ,
            {"LITELLM_API_KEY": "key"},  # pragma: allowlist secret
            clear=True,
        ):
            config = LLMConfig()
        assert config.has_litellm is True

        with patch.dict(os.environ, {}, clear=True):
            config = LLMConfig()
        assert config.has_litellm is False

    def test_has_fallback(self):
        """Test fallback configuration detection."""
        with patch.dict(
            os.environ,
            {"GITHUB_TOKEN": "token"},  # pragma: allowlist secret
            clear=True,
        ):
            config = LLMConfig()
        assert config.has_fallback is True

        config = LLMConfig(enable_fallback=False)
        assert config.has_fallback is False


class TestLLMResponse:
    """Tests for LLMResponse dataclass."""

    def test_to_dict(self):
        """Test dictionary conversion."""
        response = LLMResponse(
            content="Hello",
            model="gpt-4o-mini",
            usage={"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
            finish_reason="stop",
        )

        result = response.to_dict()

        assert result["content"] == "Hello"
        assert result["model"] == "gpt-4o-mini"
        assert result["usage"]["total_tokens"] == 15
        assert result["finish_reason"] == "stop"


@requires_openai
class TestLLMClient:
    """Tests for LLMClient class (requires openai package)."""

    @pytest.fixture
    def mock_openai(self):
        """Create mock OpenAI client."""
        # Mock at the point of import in the module
        with patch("openai.OpenAI") as mock:
            yield mock

    def test_init_with_params(self):
        """Test client initialization with parameters."""
        with patch.dict(os.environ, {}, clear=True):
            client = LLMClient(
                model="custom-model",
                endpoint="http://test:4000/v1",
                api_key="test-key",  # pragma: allowlist secret
                timeout=60.0,
            )

        assert client.config.model == "custom-model"
        assert client.config.endpoint == "http://test:4000/v1"
        assert client.config.api_key == "test-key"  # pragma: allowlist secret
        assert client.config.timeout == 60.0

    def test_chat_success(self, mock_openai):
        """Test successful chat completion."""
        # Setup mock response
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "Hello, world!"
        mock_response.choices[0].finish_reason = "stop"
        mock_response.model = "gpt-4o-mini"
        mock_response.usage = MagicMock()
        mock_response.usage.prompt_tokens = 10
        mock_response.usage.completion_tokens = 5
        mock_response.usage.total_tokens = 15

        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_openai.return_value = mock_client

        with patch.dict(
            os.environ,
            {"LITELLM_API_KEY": "test-key"},  # pragma: allowlist secret
            clear=True,
        ):
            client = LLMClient()
            response = client.chat([{"role": "user", "content": "Hello"}])

        assert response.content == "Hello, world!"
        assert response.model == "gpt-4o-mini"
        assert response.usage["total_tokens"] == 15

    def test_complete_with_system(self, mock_openai):
        """Test complete method with system prompt."""
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "Response"
        mock_response.choices[0].finish_reason = "stop"
        mock_response.model = "gpt-4o-mini"
        mock_response.usage = None

        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_openai.return_value = mock_client

        with patch.dict(
            os.environ,
            {"LITELLM_API_KEY": "test-key"},  # pragma: allowlist secret
            clear=True,
        ):
            client = LLMClient()
            client.complete("Hello", system="Be helpful")

        # Verify messages include system prompt
        call_args = mock_client.chat.completions.create.call_args
        messages = call_args.kwargs["messages"]
        assert messages[0]["role"] == "system"
        assert messages[0]["content"] == "Be helpful"
        assert messages[1]["role"] == "user"
        assert messages[1]["content"] == "Hello"

    def test_analyze_json_success(self, mock_openai):
        """Test JSON analysis with valid response."""
        json_content = '{"score": 85, "issues": []}'
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = json_content
        mock_response.choices[0].finish_reason = "stop"
        mock_response.model = "gpt-4o-mini"
        mock_response.usage = None

        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_openai.return_value = mock_client

        with patch.dict(
            os.environ,
            {"LITELLM_API_KEY": "test-key"},  # pragma: allowlist secret
            clear=True,
        ):
            client = LLMClient()
            result = client.analyze_json("Analyze this")

        assert result["score"] == 85
        assert result["issues"] == []

    def test_analyze_json_code_block(self, mock_openai):
        """Test JSON extraction from markdown code block."""
        json_content = '```json\n{"score": 90}\n```'
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = json_content
        mock_response.choices[0].finish_reason = "stop"
        mock_response.model = "gpt-4o-mini"
        mock_response.usage = None

        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_openai.return_value = mock_client

        with patch.dict(
            os.environ,
            {"LITELLM_API_KEY": "test-key"},  # pragma: allowlist secret
            clear=True,
        ):
            client = LLMClient()
            result = client.analyze_json("Analyze this")

        assert result["score"] == 90

    def test_analyze_json_invalid(self, mock_openai):
        """Test JSON analysis with invalid response."""
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "Not valid JSON"
        mock_response.choices[0].finish_reason = "stop"
        mock_response.model = "gpt-4o-mini"
        mock_response.usage = None

        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_openai.return_value = mock_client

        with patch.dict(
            os.environ,
            {"LITELLM_API_KEY": "test-key"},  # pragma: allowlist secret
            clear=True,
        ):
            client = LLMClient()

            with pytest.raises(LLMClientError) as exc_info:
                client.analyze_json("Analyze this")

            assert "Invalid JSON" in str(exc_info.value)

    def test_fallback_on_error(self, mock_openai):
        """Test fallback to GitHub Models on primary failure."""
        # Setup primary to fail, fallback to succeed
        mock_primary = MagicMock()
        mock_primary.chat.completions.create.side_effect = Exception("Primary failed")

        mock_fallback_response = MagicMock()
        mock_fallback_response.choices = [MagicMock()]
        mock_fallback_response.choices[0].message.content = "Fallback response"
        mock_fallback_response.choices[0].finish_reason = "stop"
        mock_fallback_response.model = "openai/gpt-4o-mini"
        mock_fallback_response.usage = None

        mock_fallback = MagicMock()
        mock_fallback.chat.completions.create.return_value = mock_fallback_response

        # Return different clients for primary and fallback
        mock_openai.side_effect = [mock_primary, mock_fallback]

        env = {
            "LITELLM_API_KEY": "primary-key",  # pragma: allowlist secret
            "GITHUB_TOKEN": "fallback-token",  # pragma: allowlist secret
        }
        with patch.dict(os.environ, env, clear=True):
            client = LLMClient()
            response = client.chat([{"role": "user", "content": "Hello"}])

        assert response.content == "Fallback response"
        assert client.is_using_fallback is True

    def test_no_auth_error(self, mock_openai):
        """Test error when no authentication is configured."""
        with patch.dict(os.environ, {}, clear=True):
            client = LLMClient()

            with pytest.raises(LLMClientError) as exc_info:
                client.chat([{"role": "user", "content": "Hello"}])

            assert "No LLM configuration" in str(exc_info.value)


class TestGetLLMClient:
    """Tests for get_llm_client factory function."""

    def test_factory_returns_client(self):
        """Test factory returns LLMClient instance."""
        with patch.dict(os.environ, {}, clear=True):
            client = get_llm_client()

        assert isinstance(client, LLMClient)

    def test_factory_with_params(self):
        """Test factory with custom parameters."""
        with patch.dict(os.environ, {}, clear=True):
            client = get_llm_client(model="custom", endpoint="http://test:4000/v1")

        assert client.config.model == "custom"
        assert client.config.endpoint == "http://test:4000/v1"
