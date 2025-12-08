"""
macOS dev override: skip LiteLLM prisma migrations/generate to avoid DB/engine
issues on local runs. The real implementation is replaced with a no-op.
"""

from litellm._logging import verbose_proxy_logger


def main():
    verbose_proxy_logger.info("mac override: prisma migration skipped")


if __name__ == "__main__":
    main()
