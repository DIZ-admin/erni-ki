"""
# mypy: ignore-errors
Shim module to load the dashed implementation ``conf/webhook-receiver/webhook_handler.py``.
"""

import sys
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

_BASE = Path(__file__).resolve().parent.parent / "webhook-receiver" / "webhook_handler.py"
_SPEC = spec_from_file_location("webhook_handler", _BASE)
if _SPEC and _SPEC.loader:
    _MODULE = module_from_spec(_SPEC)
    sys.modules.setdefault("webhook_handler", _MODULE)
    _SPEC.loader.exec_module(_MODULE)
    globals().update(_MODULE.__dict__)
else:  # pragma: no cover - safety fallback
    raise ImportError(f"Cannot load webhook_handler implementation from {_BASE}")
