import sys
from pathlib import Path

# Ensure repository root is on sys.path for module resolution (e.g., webhook_receiver shim)
ROOT = Path(__file__).resolve().parents[2]
root_str = str(ROOT)
if root_str not in sys.path:
    sys.path.insert(0, root_str)
