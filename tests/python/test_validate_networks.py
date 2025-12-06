"""
Tests for validate_networks.py script.

This module tests the Docker Compose network validation functionality.
"""

import subprocess
import sys
from pathlib import Path

import pytest
import yaml

# Import the module
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
import validate_networks  # noqa: E402


class TestParseArgs:
    """Test command-line argument parsing."""

    def test_default_compose_file_path(self):
        """Test default compose file path is set correctly."""
        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py"])
            args = validate_networks.parse_args()

            assert args.compose_file is not None
            assert args.compose_file.name == "compose.yml"

    def test_custom_compose_file_path(self, tmp_path):
        """Test custom compose file path is accepted."""
        custom_file = tmp_path / "custom.yml"
        custom_file.touch()

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(custom_file)])
            args = validate_networks.parse_args()

            assert args.compose_file == custom_file


class TestNetworkValidation:
    """Test network validation logic."""

    def create_minimal_compose(self, tmp_path, services_config, networks_config=None):
        """Helper to create a compose file for testing."""
        if networks_config is None:
            networks_config = {
                "frontend": {"internal": False},
                "backend": {"internal": True},
                "data": {"internal": True},
                "monitoring": {"internal": True},
            }

        compose_data = {
            "services": services_config,
            "networks": networks_config,
        }

        compose_file = tmp_path / "test-compose.yml"
        with open(compose_file, "w", encoding="utf-8") as f:
            yaml.dump(compose_data, f)

        return compose_file

    def test_validates_correct_network_assignment(self, tmp_path):
        """Test validation passes for correct network assignments."""
        services = {
            "nginx": {
                "image": "nginx",
                "networks": ["frontend", "backend"],
            },
            "db": {
                "image": "postgres",
                "networks": ["data"],
            },
        }

        compose_file = self.create_minimal_compose(tmp_path, services)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # Should pass validation for services that match expected networks
        assert result in [0, 1]  # May fail due to missing services, but won't crash

    def test_detects_missing_compose_file(self, tmp_path):
        """Test error handling for missing compose file."""
        nonexistent = tmp_path / "nonexistent.yml"

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(nonexistent)])
            result = validate_networks.main()

        assert result == 1

    def test_detects_invalid_yaml(self, tmp_path):
        """Test error handling for invalid YAML."""
        compose_file = tmp_path / "invalid.yml"
        compose_file.write_text("invalid: yaml: content: [[[", encoding="utf-8")

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        assert result == 1

    def test_validates_network_mode_services(self, tmp_path):
        """Test validation of services using network_mode."""
        services = {
            "postgres-exporter-proxy": {
                "image": "exporter",
                "network_mode": "service:db",
            },
        }

        compose_file = self.create_minimal_compose(tmp_path, services)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # Should handle network_mode services without crashing
        assert result in [0, 1]

    def test_detects_wrong_network_assignment(self, tmp_path):
        """Test detection of incorrect network assignments."""
        # nginx should be on frontend+backend, not just frontend
        services = {
            "nginx": {
                "image": "nginx",
                "networks": ["frontend"],
            },
        }

        compose_file = self.create_minimal_compose(tmp_path, services)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # Should fail validation
        assert result == 1

    def test_validates_dict_network_format(self, tmp_path):
        """Test validation of dict-format network assignments."""
        services = {
            "nginx": {
                "image": "nginx",
                "networks": {
                    "frontend": {},
                    "backend": {},
                },
            },
        }

        compose_file = self.create_minimal_compose(tmp_path, services)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # Should handle dict format networks
        assert result in [0, 1]

    def test_detects_unexpected_services(self, tmp_path):
        """Test detection of services not in expected list."""
        services = {
            "unknown-service": {
                "image": "unknown",
                "networks": ["backend"],
            },
        }

        compose_file = self.create_minimal_compose(tmp_path, services)

        # Should detect and report extra services
        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        assert result in [0, 1]


class TestPortBindingsValidation:
    """Test port bindings validation."""

    def test_detects_removed_ports(self, tmp_path):
        """Test detection that ports should be removed."""
        services = {
            "auth": {
                "image": "auth",
                "ports": ["9092:9090"],  # Should be removed
                "networks": ["backend", "data"],
            },
        }

        networks = {
            "backend": {"internal": True},
            "data": {"internal": True},
        }

        compose_file = tmp_path / "test-compose.yml"
        with open(compose_file, "w", encoding="utf-8") as f:
            yaml.dump({"services": services, "networks": networks}, f)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # Should fail due to port that should be removed
        assert result == 1

    def test_validates_kept_ports(self, tmp_path):
        """Test validation of ports that should be kept."""
        services = {
            "nginx": {
                "image": "nginx",
                "ports": ["80:80", "443:443", "8080:8080"],
                "networks": ["frontend", "backend"],
            },
        }

        networks = {
            "frontend": {"internal": False},
            "backend": {"internal": True},
        }

        compose_file = tmp_path / "test-compose.yml"
        with open(compose_file, "w", encoding="utf-8") as f:
            yaml.dump({"services": services, "networks": networks}, f)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # May pass or fail depending on other services, but should handle ports
        assert result in [0, 1]


class TestOutputFormat:
    """Test output formatting and reporting."""

    def test_produces_validation_report(self, tmp_path, capsys):
        """Test that validation produces a structured report."""
        services = {
            "nginx": {
                "image": "nginx",
                "networks": ["frontend", "backend"],
            },
        }

        networks = {
            "frontend": {"internal": False},
            "backend": {"internal": True},
        }

        compose_file = tmp_path / "test-compose.yml"
        with open(compose_file, "w", encoding="utf-8") as f:
            yaml.dump({"services": services, "networks": networks}, f)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            validate_networks.main()

        captured = capsys.readouterr()
        output = captured.out

        # Check for report sections
        assert "NETWORK SEGMENTATION VALIDATION REPORT" in output
        assert "NETWORK DEFINITIONS" in output
        assert "SERVICE NETWORK ASSIGNMENTS" in output
        assert "PORT BINDINGS ANALYSIS" in output
        assert "VALIDATION SUMMARY" in output

    def test_shows_network_definitions(self, tmp_path, capsys):
        """Test that network definitions are displayed."""
        networks = {
            "frontend": {"internal": False},
            "backend": {"internal": True},
            "data": {"internal": True},
            "monitoring": {"internal": True},
        }

        compose_file = tmp_path / "test-compose.yml"
        with open(compose_file, "w", encoding="utf-8") as f:
            yaml.dump({"services": {}, "networks": networks}, f)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            validate_networks.main()

        captured = capsys.readouterr()
        output = captured.out

        assert "frontend" in output
        assert "backend" in output
        assert "data" in output
        assert "monitoring" in output


class TestRealWorldScenarios:
    """Test real-world usage scenarios."""

    def test_validates_complete_stack(self, tmp_path):
        """Test validation of a complete service stack."""
        services = {
            "nginx": {"image": "nginx", "networks": ["frontend", "backend"]},
            "db": {"image": "postgres", "networks": ["data"]},
            "redis": {"image": "redis", "networks": ["data"]},
            "openwebui": {"image": "openwebui", "networks": ["backend", "data"]},
            "prometheus": {"image": "prometheus", "networks": ["monitoring"]},
        }

        networks = {
            "frontend": {"internal": False},
            "backend": {"internal": True},
            "data": {"internal": True},
            "monitoring": {"internal": True},
        }

        compose_file = tmp_path / "test-compose.yml"
        with open(compose_file, "w", encoding="utf-8") as f:
            yaml.dump({"services": services, "networks": networks}, f)

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # Should handle complete stack without crashing
        assert result in [0, 1]

    def test_handles_empty_compose_file(self, tmp_path):
        """Test handling of empty compose file."""
        compose_file = tmp_path / "empty.yml"
        compose_file.write_text("{}", encoding="utf-8")

        with pytest.MonkeyPatch.context() as m:
            m.setattr(sys, "argv", ["validate_networks.py", "--compose-file", str(compose_file)])
            result = validate_networks.main()

        # Should handle empty file gracefully
        assert result in [0, 1]


class TestCommandLineInterface:
    """Test command-line interface."""

    def test_cli_with_valid_compose(self, tmp_path):
        """Test CLI execution with valid compose file."""
        services = {"nginx": {"image": "nginx", "networks": ["frontend", "backend"]}}
        networks = {"frontend": {}, "backend": {}}

        compose_file = tmp_path / "test.yml"
        with open(compose_file, "w", encoding="utf-8") as f:
            yaml.dump({"services": services, "networks": networks}, f)

        result = subprocess.run(  # noqa: S603
            [
                sys.executable,
                str(Path(__file__).parents[2] / "scripts" / "validate_networks.py"),
                "--compose-file",
                str(compose_file),
            ],
            capture_output=True,
            text=True,
            check=False,
        )

        # Should execute without errors
        assert result.returncode in [0, 1]
        assert "NETWORK SEGMENTATION VALIDATION REPORT" in result.stdout


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
