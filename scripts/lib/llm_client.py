#!/usr/bin/env python3
"""
ERNI-KI Unified LLM Client Library

Provides a unified interface for LLM API calls through LiteLLM gateway
with automatic fallback to GitHub Models.

Usage:
    from scripts.lib.llm_client import get_llm_client, LLMClient

    # Simple usage
    client = get_llm_client()
    response = client.chat([{"role": "user", "content": "Hello"}])

    # With custom model
    client = get_llm_client(model="docs-validator")
    response = client.complete("Analyze this code", system="You are a code reviewer")

Environment Variables:
    LITELLM_API_KEY      - API key for LiteLLM gateway (primary)
    LITELLM_ENDPOINT     - LiteLLM endpoint URL (default: http://litellm:4000/v1)
    LITELLM_MODEL        - Default model alias (default: gpt-4o-mini)
    GITHUB_TOKEN         - Fallback to GitHub Models if LiteLLM unavailable
"""

from __future__ import annotations

import json
import logging
import os
import sys
from collections.abc import Iterator
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from openai import OpenAI
    from openai.types.chat import ChatCompletion

# === Configuration ===
DEFAULT_LITELLM_ENDPOINT = "http://litellm:4000/v1"
DEFAULT_MODEL = "gpt-4o-mini"
GITHUB_MODELS_ENDPOINT = "https://models.github.ai/inference"
GITHUB_MODELS_MODEL = "openai/gpt-4o-mini"

logger = logging.getLogger(__name__)


@dataclass
class LLMConfig:
    """LLM client configuration."""

    endpoint: str = ""
    api_key: str = ""
    model: str = DEFAULT_MODEL
    timeout: float = 300.0
    max_retries: int = 3

    # Fallback configuration
    fallback_endpoint: str = GITHUB_MODELS_ENDPOINT
    fallback_api_key: str = ""
    fallback_model: str = GITHUB_MODELS_MODEL
    enable_fallback: bool = True

    def __post_init__(self) -> None:
        """Load configuration from environment variables."""
        self.endpoint = self.endpoint or os.environ.get(
            "LITELLM_ENDPOINT", DEFAULT_LITELLM_ENDPOINT
        )
        self.api_key = self.api_key or os.environ.get("LITELLM_API_KEY", "")
        self.model = self.model or os.environ.get("LITELLM_MODEL", DEFAULT_MODEL)
        self.fallback_api_key = self.fallback_api_key or os.environ.get("GITHUB_TOKEN", "")

    @property
    def has_litellm(self) -> bool:
        """Check if LiteLLM is configured."""
        return bool(self.api_key)

    @property
    def has_fallback(self) -> bool:
        """Check if fallback is configured."""
        return self.enable_fallback and bool(self.fallback_api_key)


@dataclass
class LLMResponse:
    """Structured LLM response."""

    content: str
    model: str
    usage: dict[str, int] = field(default_factory=dict)
    finish_reason: str = ""
    raw_response: Any = None

    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            "content": self.content,
            "model": self.model,
            "usage": self.usage,
            "finish_reason": self.finish_reason,
        }


class LLMClientError(Exception):
    """Base exception for LLM client errors."""

    pass


class LLMConnectionError(LLMClientError):
    """Connection error to LLM service."""

    pass


class LLMAuthError(LLMClientError):
    """Authentication error."""

    pass


class LLMClient:
    """
    Unified LLM client with LiteLLM primary and GitHub Models fallback.

    Example:
        >>> client = LLMClient()
        >>> response = client.chat([
        ...     {"role": "system", "content": "You are helpful."},
        ...     {"role": "user", "content": "Hello!"}
        ... ])
        >>> print(response.content)
    """

    def __init__(
        self,
        model: str | None = None,
        endpoint: str | None = None,
        api_key: str | None = None,
        timeout: float | None = None,
        enable_fallback: bool = True,
    ):
        """
        Initialize LLM client.

        Args:
            model: Model name or alias (default from env)
            endpoint: LiteLLM endpoint URL (default from env)
            api_key: API key (default from env)
            timeout: Request timeout in seconds
            enable_fallback: Enable GitHub Models fallback
        """
        self.config = LLMConfig(
            endpoint=endpoint or "",
            api_key=api_key or "",
            model=model or "",
            timeout=timeout or 300.0,
            enable_fallback=enable_fallback,
        )
        self._client: OpenAI | None = None
        self._fallback_client: OpenAI | None = None
        self._using_fallback = False

    @property
    def client(self) -> OpenAI:
        """Get or create the primary OpenAI client."""
        if self._client is None:
            self._client = self._create_client(self.config.endpoint, self.config.api_key)
        return self._client

    @property
    def fallback_client(self) -> OpenAI | None:
        """Get or create the fallback OpenAI client."""
        if not self.config.has_fallback:
            return None
        if self._fallback_client is None:
            self._fallback_client = self._create_client(
                self.config.fallback_endpoint, self.config.fallback_api_key
            )
        return self._fallback_client

    def _create_client(self, endpoint: str, api_key: str) -> OpenAI:
        """Create an OpenAI client instance."""
        try:
            from openai import OpenAI
        except ImportError as e:
            raise LLMClientError("openai package not installed. Run: pip install openai") from e

        if not api_key:
            raise LLMAuthError("API key not configured")

        return OpenAI(
            base_url=endpoint,
            api_key=api_key,
            timeout=self.config.timeout,
            max_retries=self.config.max_retries,
        )

    def _get_active_client_and_model(self) -> tuple[OpenAI, str]:
        """Get the active client and model based on configuration."""
        if self.config.has_litellm:
            return self.client, self.config.model

        if self.config.has_fallback:
            logger.warning("LiteLLM not configured, using GitHub Models fallback")
            self._using_fallback = True
            if self.fallback_client is None:
                raise LLMAuthError("Neither LiteLLM nor fallback configured")
            return self.fallback_client, self.config.fallback_model

        raise LLMAuthError(
            "No LLM configuration available. "
            "Set LITELLM_API_KEY or GITHUB_TOKEN environment variable."
        )

    def chat(
        self,
        messages: list[dict[str, str]],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int | None = None,
        stream: bool = False,
        **kwargs: Any,
    ) -> LLMResponse | Iterator[str]:
        """
        Send a chat completion request.

        Args:
            messages: List of message dicts with 'role' and 'content'
            model: Override model (uses default if not specified)
            temperature: Sampling temperature (0-2)
            max_tokens: Maximum tokens in response
            stream: Enable streaming response
            **kwargs: Additional parameters passed to API

        Returns:
            LLMResponse object or iterator for streaming

        Example:
            >>> response = client.chat([
            ...     {"role": "user", "content": "What is 2+2?"}
            ... ])
            >>> print(response.content)
            "4"
        """
        client, default_model = self._get_active_client_and_model()
        use_model = model or default_model

        request_params: dict[str, Any] = {
            "model": use_model,
            "messages": messages,
            "temperature": temperature,
            "stream": stream,
            **kwargs,
        }

        if max_tokens is not None:
            request_params["max_tokens"] = max_tokens

        try:
            if stream:
                return self._stream_response(client, request_params)

            response = client.chat.completions.create(**request_params)
            return self._parse_response(response)

        except Exception as e:
            # Try fallback if primary fails
            if (
                not self._using_fallback
                and self.config.has_fallback
                and self.fallback_client is not None
            ):
                logger.warning(f"Primary LLM failed ({e}), trying fallback...")
                self._using_fallback = True
                request_params["model"] = self.config.fallback_model

                if stream:
                    return self._stream_response(self.fallback_client, request_params)

                response = self.fallback_client.chat.completions.create(**request_params)
                return self._parse_response(response)

            raise LLMClientError(f"LLM request failed: {e}") from e

    def _stream_response(self, client: OpenAI, params: dict[str, Any]) -> Iterator[str]:
        """Handle streaming response."""
        stream = client.chat.completions.create(**params)
        for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content

    def _parse_response(self, response: ChatCompletion) -> LLMResponse:
        """Parse API response into LLMResponse."""
        choice = response.choices[0] if response.choices else None
        content = choice.message.content if choice else ""
        finish_reason = choice.finish_reason if choice else ""

        usage = {}
        if response.usage:
            usage = {
                "prompt_tokens": response.usage.prompt_tokens,
                "completion_tokens": response.usage.completion_tokens,
                "total_tokens": response.usage.total_tokens,
            }

        return LLMResponse(
            content=content or "",
            model=response.model,
            usage=usage,
            finish_reason=finish_reason or "",
            raw_response=response,
        )

    def complete(
        self,
        prompt: str,
        system: str | None = None,
        model: str | None = None,
        **kwargs: Any,
    ) -> LLMResponse:
        """
        Simplified completion with optional system prompt.

        Args:
            prompt: User prompt
            system: Optional system prompt
            model: Override model
            **kwargs: Additional parameters

        Returns:
            LLMResponse object

        Example:
            >>> response = client.complete(
            ...     "Review this code",
            ...     system="You are a code reviewer"
            ... )
        """
        messages: list[dict[str, str]] = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})

        result = self.chat(messages, model=model, **kwargs)
        if isinstance(result, LLMResponse):
            return result
        # Handle streaming case (shouldn't happen with complete())
        return LLMResponse(content="".join(result), model=model or self.config.model)

    def analyze_json(
        self,
        prompt: str,
        system: str | None = None,
        model: str | None = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """
        Request JSON response and parse it.

        Args:
            prompt: User prompt requesting JSON output
            system: Optional system prompt
            model: Override model
            **kwargs: Additional parameters

        Returns:
            Parsed JSON dictionary

        Raises:
            LLMClientError: If response is not valid JSON
        """
        if system:
            system += "\n\nRespond with valid JSON only, no markdown."
        else:
            system = "Respond with valid JSON only, no markdown."

        response = self.complete(prompt, system=system, model=model, **kwargs)
        content = response.content.strip()

        # Extract JSON from markdown code block if present
        if content.startswith("```"):
            lines = content.split("\n")
            # Remove first and last lines (code block markers)
            json_lines = []
            in_block = False
            for line in lines:
                if line.startswith("```") and not in_block:
                    in_block = True
                    continue
                if line.startswith("```") and in_block:
                    break
                if in_block:
                    json_lines.append(line)
            content = "\n".join(json_lines)

        try:
            return json.loads(content)
        except json.JSONDecodeError as e:
            raise LLMClientError(f"Invalid JSON response: {e}") from e

    @property
    def is_using_fallback(self) -> bool:
        """Check if currently using fallback provider."""
        return self._using_fallback


def get_llm_client(
    model: str | None = None,
    endpoint: str | None = None,
    api_key: str | None = None,
    **kwargs: Any,
) -> LLMClient:
    """
    Factory function to create an LLM client.

    Args:
        model: Model name or alias
        endpoint: LiteLLM endpoint URL
        api_key: API key
        **kwargs: Additional LLMClient parameters

    Returns:
        Configured LLMClient instance

    Example:
        >>> client = get_llm_client(model="docs-validator")
        >>> response = client.complete("Check this documentation")
    """
    return LLMClient(model=model, endpoint=endpoint, api_key=api_key, **kwargs)


# === CLI Interface ===
def main() -> int:
    """CLI entry point for testing the client."""
    import argparse

    parser = argparse.ArgumentParser(description="Test LLM client")
    parser.add_argument("prompt", nargs="?", default="Say hello in one word")
    parser.add_argument("--model", "-m", help="Model to use")
    parser.add_argument("--system", "-s", help="System prompt")
    parser.add_argument("--json", "-j", action="store_true", help="Request JSON output")
    parser.add_argument("--stream", action="store_true", help="Enable streaming")
    args = parser.parse_args()

    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
    )

    try:
        client = get_llm_client(model=args.model)

        if args.json:
            result = client.analyze_json(args.prompt, system=args.system)
            print(json.dumps(result, indent=2))
        elif args.stream:
            for chunk in client.chat([{"role": "user", "content": args.prompt}], stream=True):
                print(chunk, end="", flush=True)
            print()
        else:
            response = client.complete(args.prompt, system=args.system)
            print(f"Model: {response.model}")
            print(f"Usage: {response.usage}")
            print(f"Response: {response.content}")

        if client.is_using_fallback:
            print("\n[Note: Used GitHub Models fallback]")

        return 0

    except LLMClientError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
