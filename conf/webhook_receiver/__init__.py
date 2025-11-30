"""
Typed wrapper for webhook receiver module.

The runtime implementation lives in ``conf/webhook-receiver/webhook-receiver.py``.
We load it dynamically so that both the Docker image (which expects the dashed
filename) and the test suite (which imports ``conf.webhook_receiver``) work
consistently. This also allows mypy to treat the package as typed via
``py.typed``.
"""

import sys
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType

_BASE_DIR = Path(__file__).resolve().parent.parent
_RECEIVER_PATH = _BASE_DIR / "webhook-receiver" / "webhook-receiver.py"
_HANDLER_PATH = _BASE_DIR / "webhook-receiver" / "webhook_handler.py"


def _load_module(name: str, path: Path) -> ModuleType:
    if name in sys.modules:
        return sys.modules[name]
    """Load a module from a given path and register it under the package."""
    spec = spec_from_file_location(f"conf.webhook_receiver.{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook receiver implementation from {path}")
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    # Ensure direct imports like `import webhook_receiver` use the same module
    sys.modules.setdefault(name.replace("-", "_"), module)
    sys.modules.setdefault(f"conf.webhook_receiver.{name}", module)
    return module


# Load both the webhook receiver and handler implementations (dashed filenames)
_receiver_impl = _load_module("webhook_receiver", _RECEIVER_PATH)
_handler_impl = _load_module("webhook_handler", _HANDLER_PATH)

# Expose as attributes for tests and consumers
webhook_receiver = _receiver_impl
webhook_handler = _handler_impl

__all__ = [
    "webhook_receiver",
    "webhook_handler",
]


def __getattr__(name: str):
    if name == "webhook_receiver":
        # Raise RuntimeError for invalid/missing secrets on access
        _receiver_impl._validate_secrets()
        import sys

        sys.modules.setdefault("conf.webhook_receiver.webhook_receiver", _receiver_impl)
        return _receiver_impl
    if name == "webhook_handler":
        import sys

        sys.modules.setdefault("conf.webhook_receiver.webhook_handler", _handler_impl)
        return _handler_impl
    raise AttributeError(name)
