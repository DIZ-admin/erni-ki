#!/usr/bin/env python3
"""
ERNI-KI Structured Logging Library

Provides centralized structured logging with JSON and colored output support,
including correlation ID tracking for distributed tracing.

Usage:
    from scripts.lib.logger import get_logger, set_correlation_id

    # Basic usage
    logger = get_logger(__name__)
    logger.info("Message", extra={"key": "value"})

    # With correlation ID (for request tracing)
    with logging_context(correlation_id="abc-123", request_id="req-456"):
        logger.info("Processing request")

    # Or manually
    set_correlation_id("abc-123")
    logger.info("This log will include correlation_id")
"""

import functools
import json
import logging
import os
import sys
import uuid
from collections.abc import Callable
from contextlib import contextmanager
from contextvars import ContextVar
from datetime import datetime
from pathlib import Path
from typing import Any, TypeVar

# ============================================================================
# Context Variables for Distributed Tracing
# ============================================================================

# Correlation ID: Tracks a request across multiple services
correlation_id_var: ContextVar[str] = ContextVar("correlation_id", default="")

# Request ID: Unique identifier for a specific request
request_id_var: ContextVar[str] = ContextVar("request_id", default="")

# Additional context that can be added to all logs (None default to avoid mutable default)
extra_context_var: ContextVar[dict[str, Any] | None] = ContextVar("extra_context", default=None)

# Get hostname once at module load
_HOSTNAME = os.getenv("HOSTNAME", os.getenv("HOST", "unknown"))


# ============================================================================
# Context Management Functions
# ============================================================================


def get_correlation_id() -> str:
    """Get current correlation ID, generating one if not set."""
    cid = correlation_id_var.get()
    if not cid:
        cid = str(uuid.uuid4())[:8]  # Short UUID for readability
        correlation_id_var.set(cid)
    return cid


def set_correlation_id(correlation_id: str) -> None:
    """Set correlation ID for current context."""
    correlation_id_var.set(correlation_id)


def get_request_id() -> str:
    """Get current request ID."""
    return request_id_var.get()


def set_request_id(request_id: str) -> None:
    """Set request ID for current context."""
    request_id_var.set(request_id)


def set_extra_context(ctx: dict[str, Any]) -> None:
    """Set additional context to include in all logs."""
    extra_context_var.set(ctx)


def clear_context() -> None:
    """Clear all context variables."""
    correlation_id_var.set("")
    request_id_var.set("")
    extra_context_var.set(None)


@contextmanager
def logging_context(
    correlation_id: str | None = None,
    request_id: str | None = None,
    **extra: Any,
):
    """
    Context manager for setting logging context.

    Usage:
        with logging_context(correlation_id="abc", user_id="123"):
            logger.info("This log includes correlation_id and user_id")
    """
    # Save current state
    old_correlation_id = correlation_id_var.get()
    old_request_id = request_id_var.get()
    old_extra = extra_context_var.get()

    try:
        # Set new context
        if correlation_id:
            correlation_id_var.set(correlation_id)
        elif not old_correlation_id:
            # Generate new correlation ID if none exists
            correlation_id_var.set(str(uuid.uuid4())[:8])

        if request_id:
            request_id_var.set(request_id)

        if extra:
            new_extra = {**(old_extra or {}), **extra}
            extra_context_var.set(new_extra)

        yield
    finally:
        # Restore previous state
        correlation_id_var.set(old_correlation_id)
        request_id_var.set(old_request_id)
        extra_context_var.set(old_extra)


# Type variable for decorator
F = TypeVar("F", bound=Callable[..., Any])


def with_logging_context(**ctx_kwargs: Any) -> Callable[[F], F]:
    """
    Decorator for adding logging context to a function.

    Usage:
        @with_logging_context(correlation_id="task-123", task="process_data")
        def process_data():
            logger.info("Processing...")  # Includes correlation_id and task
    """

    def decorator(func: F) -> F:
        @functools.wraps(func)
        def sync_wrapper(*args: Any, **kwargs: Any) -> Any:
            with logging_context(**ctx_kwargs):
                return func(*args, **kwargs)

        @functools.wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
            with logging_context(**ctx_kwargs):
                return await func(*args, **kwargs)

        # Return appropriate wrapper based on function type
        if asyncio_iscoroutinefunction(func):
            return async_wrapper  # type: ignore
        return sync_wrapper  # type: ignore

    return decorator


def asyncio_iscoroutinefunction(func: Callable[..., Any]) -> bool:
    """Check if function is async, handling both regular and wrapped functions."""
    import asyncio

    return asyncio.iscoroutinefunction(func)


# ============================================================================
# Formatters
# ============================================================================


class ColoredFormatter(logging.Formatter):
    """Format logs with ANSI colors for terminal output."""

    COLORS = {
        "DEBUG": "\033[0;36m",  # Cyan
        "INFO": "\033[0;34m",  # Blue
        "WARNING": "\033[1;33m",  # Yellow
        "ERROR": "\033[0;31m",  # Red
        "CRITICAL": "\033[0;41m",  # Red background
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        """Format log record with colors."""
        color = self.COLORS.get(record.levelname, "")
        reset = self.RESET if color else ""

        # Format timestamp (using timezone-aware UTC)
        timestamp = datetime.now(tz=__import__("datetime").timezone.utc).isoformat()

        # Build colored output
        level = f"{color}{record.levelname}{reset}"
        message = record.getMessage()

        # Add correlation ID if present
        cid = correlation_id_var.get()
        cid_str = f" [{cid}]" if cid else ""

        return f"[{timestamp}]{cid_str} [{level}] {record.name} - {message}"


class JSONFormatter(logging.Formatter):
    """Format logs as JSON for machine parsing with full context."""

    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON with correlation context."""
        # Base log data (using timezone-aware UTC)
        log_data: dict[str, Any] = {
            "timestamp": datetime.now(tz=__import__("datetime").timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "hostname": _HOSTNAME,
        }

        # Add correlation context
        cid = correlation_id_var.get()
        if cid:
            log_data["correlation_id"] = cid

        rid = request_id_var.get()
        if rid:
            log_data["request_id"] = rid

        # Add extra context from ContextVar
        extra_ctx = extra_context_var.get()
        if extra_ctx:
            log_data.update(extra_ctx)

        # Add extra fields from record if present
        extra = getattr(record, "extra", None)
        if isinstance(extra, dict):
            log_data.update(extra)

        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_data, ensure_ascii=False, default=str)


# ============================================================================
# Logger Factory
# ============================================================================


def get_logger(
    name: str,
    level: str | int | None = None,
    json_output: bool = False,
) -> logging.Logger:
    """
    Create and configure a logger with a single console handler.

    Parameters:
        name (str): Logger name (typically __name__).
        level (str | int | None): Logging level as a string (e.g.,
            "DEBUG") or an int; defaults to INFO when None or
            unrecognized.
        json_output (bool): If True, format console output as JSON;
            otherwise use colored terminal formatting.

    Returns:
        logging.Logger: Configured logger instance with a single stdout handler.
    """
    # Convert string level to logging level
    if level is None:
        log_level = logging.INFO
    elif isinstance(level, str):
        log_level = getattr(logging, level.upper(), logging.INFO)
    else:
        log_level = level

    logger = logging.getLogger(name)
    logger.setLevel(log_level)

    # Remove existing handlers to avoid duplicates
    logger.handlers = []

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(log_level)

    if json_output:
        console_formatter: logging.Formatter = JSONFormatter()
    else:
        console_formatter = ColoredFormatter()

    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    return logger


def log_to_file(logger: logging.Logger, file_path: str | Path) -> None:
    """
    Attach a JSON-formatted file handler to the given logger.

    Parameters:
        logger (logging.Logger): Logger to receive the file handler.
        file_path (str | Path): Path to the log file to write.

    Notes:
        Sets the file handler's level to the logger's current level.
        If directory creation or handler setup fails, an error is
        logged on the provided logger.
    """
    file_path_obj = Path(file_path)

    try:
        # Create parent directories if needed
        file_path_obj.parent.mkdir(parents=True, exist_ok=True)

        file_handler = logging.FileHandler(str(file_path_obj))
        file_handler.setLevel(logger.level)
        file_formatter = JSONFormatter()
        file_handler.setFormatter(file_formatter)
        logger.addHandler(file_handler)
    except OSError as e:
        logger.error("Failed to setup file logging at %s: %s", file_path_obj, e)


# ============================================================================
# Default Logger Instance
# ============================================================================

# Default logger instance for direct imports
logger = get_logger("erni-ki")
