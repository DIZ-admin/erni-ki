#!/usr/bin/env python3
"""Tests for scripts/lib/logger.py"""

import logging
import sys
from io import StringIO
from pathlib import Path

import pytest

# Add scripts to path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))

from lib.logger import ColoredFormatter, JSONFormatter, get_logger, log_to_file


def test_get_logger_default():
    """Test default logger creation."""
    logger = get_logger("test_logger")

    assert logger.name == "test_logger"
    assert logger.level == logging.INFO
    assert len(logger.handlers) > 0


def test_get_logger_custom_level():
    """Test logger with custom level."""
    logger = get_logger("test_debug", level="DEBUG")

    assert logger.level == logging.DEBUG


def test_get_logger_json_format():
    """Test logger with JSON format."""
    logger = get_logger("test_json", json_output=True)

    # Check that handler has JSON formatter
    assert any(isinstance(h.formatter, JSONFormatter) for h in logger.handlers)


def test_get_logger_colored_format():
    """Test logger with colored format."""
    logger = get_logger("test_colored", json_output=False)

    # Check that handler has colored formatter
    assert any(isinstance(h.formatter, ColoredFormatter) for h in logger.handlers)


def test_json_formatter():
    """Test JSON formatter output."""
    formatter = JSONFormatter()
    record = logging.LogRecord(
        name="test",
        level=logging.INFO,
        pathname="test.py",
        lineno=10,
        msg="Test message",
        args=(),
        exc_info=None,
    )

    output = formatter.format(record)

    # Should be valid JSON
    import json

    data = json.loads(output)

    assert data["level"] == "INFO"
    assert data["message"] == "Test message"
    assert "timestamp" in data


def test_colored_formatter():
    """Test colored formatter output."""
    formatter = ColoredFormatter()
    record = logging.LogRecord(
        name="test",
        level=logging.ERROR,
        pathname="test.py",
        lineno=10,
        msg="Error message",
        args=(),
        exc_info=None,
    )

    output = formatter.format(record)

    # Should contain ANSI codes
    assert "\033[" in output
    assert "ERROR" in output
    assert "Error message" in output


def test_log_to_file(tmp_path):
    """Test logging to file."""
    log_file = tmp_path / "test.log"
    logger = get_logger("test_file_logger")

    log_to_file(logger, log_file)

    # Write some logs
    logger.info("Test info message")
    logger.error("Test error message")

    # Verify file exists and contains logs
    assert log_file.exists()
    content = log_file.read_text()

    assert "Test info message" in content
    assert "Test error message" in content


def test_logger_no_duplicate_handlers():
    """Test that calling get_logger twice doesn't add duplicate handlers."""
    logger1 = get_logger("test_duplicate")
    handler_count1 = len(logger1.handlers)

    logger2 = get_logger("test_duplicate")
    handler_count2 = len(logger2.handlers)

    assert handler_count1 == handler_count2
    assert logger1 is logger2  # Same instance


def test_logger_exception_logging():
    """Test exception logging."""
    logger = get_logger("test_exception", json_output=True)

    # Capture stderr
    old_stderr = sys.stderr
    sys.stderr = StringIO()

    try:
        raise ValueError("Test exception")
    except ValueError:
        logger.exception("An error occurred")

    output = sys.stderr.getvalue()
    sys.stderr = old_stderr

    # Should contain exception info
    assert "exception" in output.lower()
    assert "ValueError" in output


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
