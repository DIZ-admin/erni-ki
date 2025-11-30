# mypy: ignore-errors
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

SOURCE_PATH: Path = Path(__file__).parent / "conf" / "webhook-receiver" / "webhook_handler.py"

spec: importlib.machinery.ModuleSpec | None = importlib.util.spec_from_file_location(
    "webhook_handler_impl", SOURCE_PATH
)
if spec is None or spec.loader is None:
    raise ImportError(f"Unable to load webhook_handler from {SOURCE_PATH}")

_module: ModuleType = importlib.util.module_from_spec(spec)
if not isinstance(_module, ModuleType):
    raise ImportError(f"Module loaded from {SOURCE_PATH} is not a valid ModuleType")

try:
    spec.loader.exec_module(_module)
except Exception as e:  # pragma: no cover - defensive guard
    raise ImportError(f"Failed to execute module from {SOURCE_PATH}: {e}") from e

# Expose the real implementation under the webhook_handler name for patching
sys.modules["webhook_handler"] = _module

_exported_names = [name for name in dir(_module) if not name.startswith("_")]

# Re-export public attributes
globals().update({name: getattr(_module, name) for name in _exported_names})
__all__: list[str] = _exported_names
