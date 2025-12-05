"""
Tests for validating configuration files.

This module tests the integrity and validity of configuration files
added or modified in the diff, including YAML, TOML, and example configs.
"""

import json
from pathlib import Path

import pytest
import yaml


class TestLycheeConfig:
    """Tests for .lychee.toml configuration."""

    def test_lychee_toml_exists(self):
        """Test that .lychee.toml exists."""
        config_path = Path(".lychee.toml")
        assert config_path.exists(), ".lychee.toml should exist"

    def test_lychee_toml_valid_toml(self):
        """Test that .lychee.toml is valid TOML."""
        try:
            import tomli
        except ImportError:
            pytest.skip("tomli not installed")

        config_path = Path(".lychee.toml")
        with open(config_path, "rb") as f:
            config = tomli.load(f)

        assert "general" in config
        assert config["general"]["offline"] is True
        assert config["general"]["max_concurrency"] == 4

    def test_lychee_config_has_required_fields(self):
        """Test that lychee config has all required fields."""
        try:
            import tomli
        except ImportError:
            pytest.skip("tomli not installed")

        config_path = Path(".lychee.toml")
        with open(config_path, "rb") as f:
            config = tomli.load(f)

        required_fields = ["offline", "max_concurrency", "include_verbatim", "exclude_path"]
        for field in required_fields:
            assert field in config["general"], f"Missing required field: {field}"


class TestRuntimeConfig:
    """Tests for runtime configuration (.nvmrc removed, Bun required)."""

    def test_package_json_defines_bun_engine(self):
        """package.json must declare bun engine since Bun is primary runtime."""
        package_json_path = Path("package.json")
        assert package_json_path.exists(), "package.json should exist"

        with package_json_path.open() as f:
            package_data = json.load(f)

        engines = package_data.get("engines", {})
        assert "bun" in engines, "engines.bun must be defined"
        assert engines["bun"].startswith(">="), "engines.bun should be a semver range (>=x.y.z)"

    def test_package_manager_is_bun(self):
        """packageManager field should pin bun version."""
        package_json_path = Path("package.json")
        with package_json_path.open() as f:
            package_data = json.load(f)

        package_manager = package_data.get("packageManager", "")
        assert package_manager.startswith("bun@"), "packageManager should be bun@<version>"


class TestMypyConfig:
    """Tests for mypy.ini configuration."""

    def test_mypy_ini_exists(self):
        """Test that mypy.ini exists."""
        config_path = Path("mypy.ini")
        assert config_path.exists(), "mypy.ini should exist"

    def test_mypy_ini_valid_format(self):
        """Test that mypy.ini is valid INI format."""
        import configparser

        config = configparser.ConfigParser()
        config_path = Path("mypy.ini")

        try:
            config.read(config_path)
            assert "mypy" in config.sections()
        except Exception as e:
            pytest.fail(f"mypy.ini is not valid INI format: {e}")

    def test_mypy_ini_has_required_settings(self):
        """Test that mypy.ini has required settings."""
        import configparser

        config = configparser.ConfigParser()
        config.read("mypy.ini")

        mypy_section = config["mypy"]
        required_settings = [
            "python_version",
            "warn_return_any",
            "warn_unused_configs",
        ]

        for setting in required_settings:
            assert setting in mypy_section, f"Missing required mypy setting: {setting}"


class TestMakefile:
    """Tests for Makefile."""

    def test_makefile_exists(self):
        """Test that Makefile exists."""
        makefile_path = Path("Makefile")
        assert makefile_path.exists(), "Makefile should exist"

    def test_makefile_has_help_target(self):
        """Test that Makefile has a help target."""
        makefile_path = Path("Makefile")
        content = makefile_path.read_text()

        assert "help:" in content, "Makefile should have a help target"
        assert (
            ".DEFAULT_GOAL := help" in content or "default:" in content
        ), "Makefile should have a default goal"

    def test_makefile_has_essential_targets(self):
        """Test that Makefile has essential targets."""
        makefile_path = Path("Makefile")
        content = makefile_path.read_text()

        essential_targets = [
            "install",
            "test",
            "lint",
            "clean",
            "docker-build",
            "docker-up",
            "docker-down",
        ]

        for target in essential_targets:
            assert f"{target}:" in content, f"Makefile should have {target} target"

    def test_makefile_targets_have_descriptions(self):
        """Test that Makefile targets have ## descriptions for help."""
        makefile_path = Path("Makefile")
        content = makefile_path.read_text()

        # Count targets with ## descriptions
        described_targets = [line for line in content.split("\n") if ":" in line and "##" in line]

        assert len(described_targets) > 10, "Makefile should have descriptions (##) for help system"


class TestAlertmanagerConfig:
    """Tests for alertmanager configuration example."""

    def test_alertmanager_example_exists(self):
        """Test that alertmanager.yml.example exists."""
        config_path = Path("conf/alertmanager/alertmanager.yml.example")
        assert config_path.exists(), "alertmanager.yml.example should exist"

    def test_alertmanager_example_valid_yaml(self):
        """Test that alertmanager.yml.example is valid YAML."""
        config_path = Path("conf/alertmanager/alertmanager.yml.example")

        with open(config_path) as f:
            config = yaml.safe_load(f)

        assert config is not None
        assert "route" in config
        assert "receivers" in config

    def test_alertmanager_config_structure(self):
        """Test that alertmanager config has correct structure."""
        config_path = Path("conf/alertmanager/alertmanager.yml.example")

        with open(config_path) as f:
            config = yaml.safe_load(f)

        # Check route configuration
        assert "receiver" in config["route"]
        assert "group_by" in config["route"]
        assert isinstance(config["route"]["group_by"], list)

        # Check receivers
        assert isinstance(config["receivers"], list)
        assert len(config["receivers"]) > 0

        # Check first receiver
        first_receiver = config["receivers"][0]
        assert "name" in first_receiver


class TestLokiConfig:
    """Tests for Loki configuration example."""

    def test_loki_example_exists(self):
        """Test that loki-config.example.yaml exists."""
        config_path = Path("conf/loki/loki-config.example.yaml")
        assert config_path.exists(), "loki-config.example.yaml should exist"

    def test_loki_example_valid_yaml(self):
        """Test that loki-config.example.yaml is valid YAML."""
        config_path = Path("conf/loki/loki-config.example.yaml")

        with open(config_path) as f:
            config = yaml.safe_load(f)

        assert config is not None
        assert "auth_enabled" in config
        assert "server" in config
        assert "ingester" in config

    def test_loki_config_has_required_sections(self):
        """Test that Loki config has all required sections."""
        config_path = Path("conf/loki/loki-config.example.yaml")

        with open(config_path) as f:
            config = yaml.safe_load(f)

        required_sections = [
            "auth_enabled",
            "server",
            "ingester",
            "limits_config",
            "schema_config",
            "storage_config",
        ]

        for section in required_sections:
            assert section in config, f"Missing required Loki config section: {section}"


class TestRedisConfig:
    """Tests for Redis configuration example."""

    def test_redis_example_exists(self):
        """Test that redis.conf.example exists."""
        config_path = Path("conf/redis/redis.conf.example")
        assert config_path.exists(), "redis.conf.example should exist"

    def test_redis_example_basic_structure(self):
        """Test that redis.conf.example has basic structure."""
        config_path = Path("conf/redis/redis.conf.example")
        content = config_path.read_text()

        # Check for essential Redis directives
        essential_directives = [
            "protected-mode",
            "port",
            "bind",
            "databases",
            "requirepass",
        ]

        for directive in essential_directives:
            assert directive in content, f"Redis config should contain {directive}"

    def test_redis_config_has_security_settings(self):
        """Test that Redis config has security settings."""
        config_path = Path("conf/redis/redis.conf.example")
        content = config_path.read_text()

        assert "protected-mode yes" in content
        assert "requirepass" in content
        assert "CHANGEME" in content or "password" in content.lower()


class TestEntrypointScripts:
    """Tests for new entrypoint scripts."""

    @pytest.mark.parametrize(
        "script_name",
        [
            "litellm.sh",
            "openwebui.sh",
            "searxng.sh",
        ],
    )
    def test_entrypoint_script_exists(self, script_name):
        """Test that entrypoint scripts exist."""
        script_path = Path(f"scripts/entrypoints/{script_name}")
        assert script_path.exists(), f"{script_name} should exist"

    @pytest.mark.parametrize(
        "script_name",
        [
            "litellm.sh",
            "openwebui.sh",
            "searxng.sh",
        ],
    )
    def test_entrypoint_script_has_shebang(self, script_name):
        """Test that entrypoint scripts have proper shebang."""
        script_path = Path(f"scripts/entrypoints/{script_name}")
        content = script_path.read_text()

        first_line = content.split("\n")[0]
        assert first_line.startswith("#!"), f"{script_name} should have shebang"
        assert "bash" in first_line or "sh" in first_line

    @pytest.mark.parametrize(
        "script_name",
        [
            "litellm.sh",
            "openwebui.sh",
            "searxng.sh",
        ],
    )
    def test_entrypoint_script_has_error_handling(self, script_name):
        """Test that entrypoint scripts have error handling."""
        script_path = Path(f"scripts/entrypoints/{script_name}")
        content = script_path.read_text()

        # Should have set -e or equivalent
        assert (
            "set -e" in content or "set -euo pipefail" in content
        ), f"{script_name} should have error handling (set -e)"


class TestEnvValidatorScript:
    """Tests for env-validator.sh script."""

    def test_env_validator_exists(self):
        """Test that env-validator.sh exists."""
        script_path = Path("scripts/functions/env-validator.sh")
        assert script_path.exists(), "env-validator.sh should exist"

    def test_env_validator_has_shebang(self):
        """Test that env-validator.sh has proper shebang."""
        script_path = Path("scripts/functions/env-validator.sh")
        content = script_path.read_text()

        first_line = content.split("\n")[0]
        assert first_line.startswith("#!"), "env-validator.sh should have shebang"

    def test_env_validator_has_functions(self):
        """Test that env-validator.sh defines validation functions."""
        script_path = Path("scripts/functions/env-validator.sh")
        content = script_path.read_text()

        # Should define functions for validation
        assert "function" in content or "()" in content, "env-validator.sh should define functions"


class TestSecretsBaseline:
    """Tests for .secrets.baseline."""

    def test_secrets_baseline_exists(self):
        """Test that .secrets.baseline exists."""
        baseline_path = Path(".secrets.baseline")
        assert baseline_path.exists(), ".secrets.baseline should exist"

    def test_secrets_baseline_valid_json(self):
        """Test that .secrets.baseline is valid JSON."""
        baseline_path = Path(".secrets.baseline")

        with open(baseline_path) as f:
            baseline = json.load(f)

        assert "results" in baseline
        assert "generated_at" in baseline

    def test_secrets_baseline_updated(self):
        """Test that .secrets.baseline has recent generated_at timestamp."""
        baseline_path = Path(".secrets.baseline")

        with open(baseline_path) as f:
            baseline = json.load(f)

        generated_at = baseline["generated_at"]
        assert (
            "2025" in generated_at or "2024" in generated_at
        ), ".secrets.baseline should have recent timestamp"


class TestDocumentationMetadata:
    """Tests for documentation metadata in markdown files."""

    def test_new_docs_have_metadata(self):
        """Test that new documentation files have proper metadata."""
        new_docs = [
            "docs/operations/core/ci-cd-overview.md",
            "docs/operations/upgrade-guide.md",
            "docs/quality/code-standards.md",
            "docs/troubleshooting/faq.md",
        ]

        for doc_path_str in new_docs:
            doc_path = Path(doc_path_str)
            if not doc_path.exists():
                continue

            content = doc_path.read_text()
            lines = content.split("\n")

            # Check for front matter
            if lines[0].strip() == "---":
                assert "---" in lines[1:10], f"{doc_path_str} should have closing front matter"

                # Check for required fields
                front_matter = "\n".join(lines[1:10])
                assert "language:" in front_matter
                assert "doc_version:" in front_matter or "last_updated:" in front_matter


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
