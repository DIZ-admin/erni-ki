#!/usr/bin/env python3
"""
LEGACY: deprecated, use update_status_snippet_v2.py instead.
Compatibility wrapper that delegates to update_status_snippet_v2.

Keeps existing hook entrypoints stable while using the refactored logic
that handles frontmatter and locale injection.
"""

from __future__ import annotations

from update_status_snippet_v2 import main

if __name__ == "__main__":
    main()
