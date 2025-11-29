"""
Typed wrapper for webhook receiver module.

The runtime implementation lives in ``conf/webhook-receiver/webhook-receiver.py``.
We load it dynamically so that both the Docker image (which expects the dashed
filename) and the test suite (which imports ``conf.webhook_receiver``) work
consistently. This also allows mypy to treat the package as typed via
``py.typed``.
"""

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType

_IMPL_PATH = Path(__file__).resolve().parent.parent / "webhook-receiver" / "webhook-receiver.py"


def _load_impl() -> ModuleType:
    spec = spec_from_file_location("conf.webhook_receiver._impl", _IMPL_PATH)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load webhook receiver implementation from {_IMPL_PATH}")
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_impl = _load_impl()

# Re-export public API for tests and consumers.
__all__ = [
    "app",
    "handle_critical_alert",
    "handle_gpu_alert",
    "process_alert",
    "run_recovery_script",
    "save_alert_to_file",
    "LOG_DIR",
    "RECOVERY_DIR",
]

globals().update({name: getattr(_impl, name) for name in __all__})
