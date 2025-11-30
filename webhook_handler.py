#!/usr/bin/env python3
"""
Shim to expose the webhook handler implementation under a stable module name.

The real code lives in conf/webhook-receiver/webhook_handler.py; this file lets
tests and patches import `webhook_handler` directly without modifying PYTHONPATH.
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType

SOURCE_PATH = Path(__file__).parent / "conf" / "webhook-receiver" / "webhook_handler.py"

spec = importlib.util.spec_from_file_location("webhook_handler_impl", SOURCE_PATH)
if spec is None or spec.loader is None:
    raise ImportError(f"Unable to load webhook_handler from {SOURCE_PATH}")

_module = importlib.util.module_from_spec(spec)
assert isinstance(_module, ModuleType)
spec.loader.exec_module(_module)

# Expose the real implementation under the webhook_handler name for patching
sys.modules["webhook_handler"] = _module

# Re-export public attributes
globals().update(
    {name: getattr(_module, name) for name in dir(_module) if not name.startswith("_")}
)
__all__ = [name for name in globals() if not name.startswith("_")]
