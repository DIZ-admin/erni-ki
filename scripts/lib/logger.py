#!/usr/bin/env python3
"""
ERNI-KI Structured Logging Library

Provides centralized structured logging with JSON and colored output support.

Usage:
    from scripts.lib.logger import get_logger
    logger = get_logger(__name__)
    logger.info("Message", extra={"key": "value"})
"""

import json
import logging
import sys
from datetime import datetime
from pathlib import Path


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

        # Format timestamp
        timestamp = datetime.utcnow().isoformat() + "Z"

        # Build colored output
        level = f"{color}{record.levelname}{reset}"
        message = record.getMessage()

        return f"[{timestamp}] [{level}] {record.name} - {message}"


class JSONFormatter(logging.Formatter):
    """Format logs as JSON for machine parsing."""

    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON."""
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        # Add extra fields if present
        if hasattr(record, "extra") and isinstance(record.extra, dict):
            log_data.update(record.extra)

        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_data, ensure_ascii=False, default=str)


class DynamicStderrHandler(logging.StreamHandler):
    """StreamHandler that honors runtime replacements of sys.stderr."""

    def __init__(self) -> None:
        super().__init__(stream=None)

    def emit(self, record: logging.LogRecord) -> None:  # pragma: no cover - thin shim
        self.setStream(sys.stderr)
        super().emit(record)


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

    # Console handler (stderr) that respects runtime redirection in tests
    console_handler = DynamicStderrHandler()
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
    Attach a JSON-formatted file handler to the given logger, creating parent directories as needed.

    Parameters:
        logger (logging.Logger): Logger to receive the file handler.
        file_path (str | Path): Path to the log file to write.

    Notes:
        Sets the file handler's level to the logger's current level.
        If directory creation or handler setup fails, an error is
        logged on the provided logger; the function does not raise
        the exception.
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
