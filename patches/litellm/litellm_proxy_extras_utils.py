"""
macOS dev override: bypass litellm-proxy-extras Prisma migrations/db push.
"""

from __future__ import annotations


class ProxyExtrasDBManager:  # minimal shim
    @staticmethod
    def setup_database(use_migrate: bool = False) -> bool:
        # No-op for local dev; treat as success.
        return True
