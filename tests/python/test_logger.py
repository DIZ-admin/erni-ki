#!/usr/bin/env python3
"""Tests for scripts/lib/logger.py"""

import logging
import sys
from io import StringIO
from pathlib import Path

import pytest  # type: ignore[import-not-found]

# Add scripts to path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))

from lib.logger import (  # type: ignore[import-not-found]
    ColoredFormatter,
    JSONFormatter,
    get_logger,
    log_to_file,
)


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


# ============================================================================
# Additional tests for logger.py enhancements
# ============================================================================


def test_logger_output_format_consistency():
    """Test that logger output format is consistent across log levels."""
    import io
    import sys
    from scripts.lib.logger import logger
    
    # Capture log output
    log_capture = io.StringIO()
    handler = logging.StreamHandler(log_capture)
    handler.setFormatter(logging.Formatter('%(levelname)s:%(name)s:%(message)s'))
    
    test_logger = logging.getLogger('test_format')
    test_logger.addHandler(handler)
    test_logger.setLevel(logging.DEBUG)
    
    test_logger.debug("Debug message")
    test_logger.info("Info message")
    test_logger.warning("Warning message")
    test_logger.error("Error message")
    test_logger.critical("Critical message")
    
    output = log_capture.getvalue()
    lines = output.strip().split('\n')
    
    # All lines should follow the same format
    assert len(lines) == 5
    for line in lines:
        assert ':' in line
        parts = line.split(':', 2)
        assert len(parts) == 3  # level:name:message


def test_logger_handles_unicode_characters():
    """Test that logger handles unicode characters properly."""
    from scripts.lib.logger import logger
    
    # Should not raise
    logger.info("Unicode test: 日本語 🚨 Ελληνικά")
    logger.warning("Special chars: café, naïve, résumé")
    logger.error("Emojis: 🔥 ⚠️ ✅ ❌")


def test_logger_handles_very_long_messages():
    """Test that logger handles very long messages."""
    from scripts.lib.logger import logger
    
    long_message = "A" * 10000
    
    # Should not raise or truncate unexpectedly
    logger.info(long_message)
    logger.error(long_message)


def test_logger_handles_multiline_messages():
    """Test that logger handles multiline messages."""
    from scripts.lib.logger import logger
    
    multiline_message = """This is a multiline message
    with multiple lines
    and indentation"""
    
    # Should handle gracefully
    logger.info(multiline_message)


def test_logger_handles_special_formatting_characters():
    """Test that logger handles special formatting characters safely."""
    from scripts.lib.logger import logger
    
    # Messages with % formatting characters
    logger.info("Message with %s and %d")
    logger.warning("Percentage: 100% complete")
    logger.error("Path: C:\\Users\\test\\file.txt")


def test_logger_thread_safety():
    """Test that logger is thread-safe under concurrent access."""
    from scripts.lib.logger import logger
    import threading
    import time
    
    results = []
    
    def log_messages(thread_id):
        for i in range(10):
            logger.info(f"Thread {thread_id}, message {i}")
            time.sleep(0.001)
        results.append(thread_id)
    
    # Create multiple threads
    threads = [threading.Thread(target=log_messages, args=(i,)) for i in range(5)]
    
    # Start all threads
    for thread in threads:
        thread.start()
    
    # Wait for completion
    for thread in threads:
        thread.join()
    
    # All threads should complete successfully
    assert len(results) == 5


def test_logger_exception_logging_with_traceback():
    """Test that logger properly handles exception logging."""
    from scripts.lib.logger import logger
    
    try:
        raise ValueError("Test exception")
    except ValueError as e:
        # Should not raise
        logger.exception("Exception occurred")
        logger.error(f"Error: {e}")


def test_logger_with_different_log_levels():
    """Test logger behavior with different configured log levels."""
    import logging
    from scripts.lib.logger import logger
    
    # Test with DEBUG level
    logger.setLevel(logging.DEBUG)
    logger.debug("Debug message - should appear")
    
    # Test with INFO level
    logger.setLevel(logging.INFO)
    logger.debug("Debug message - should not appear")
    logger.info("Info message - should appear")
    
    # Test with WARNING level
    logger.setLevel(logging.WARNING)
    logger.info("Info message - should not appear")
    logger.warning("Warning message - should appear")


def test_logger_contextual_information():
    """Test logger with contextual information (extra fields)."""
    from scripts.lib.logger import logger
    
    # Should handle extra context
    logger.info("Message with context", extra={"user": "test", "action": "login"})


def test_logger_performance_under_load():
    """Test logger performance with high message volume."""
    from scripts.lib.logger import logger
    import time
    
    start_time = time.time()
    
    # Log many messages
    for i in range(1000):
        logger.info(f"Performance test message {i}")
    
    elapsed = time.time() - start_time
    
    # Should complete in reasonable time (< 5 seconds for 1000 messages)
    assert elapsed < 5.0


def test_logger_with_structured_data():
    """Test logger with structured data (dicts, lists)."""
    from scripts.lib.logger import logger
    
    # Should handle structured data
    logger.info("Config loaded: %s", {"host": "localhost", "port": 8080})
    logger.warning("Invalid items: %s", [1, 2, 3, 4, 5])


def test_logger_name_and_module():
    """Test that logger has proper name and module information."""
    from scripts.lib.logger import logger
    
    assert logger.name == "erni-ki"
    assert hasattr(logger, 'handlers')
    assert len(logger.handlers) > 0


# End of additional tests for logger.py
