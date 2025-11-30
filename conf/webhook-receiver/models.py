"""
Pydantic models for webhook alert validation.
"""

from typing import Any

from pydantic import BaseModel, field_validator


class AlertLabels(BaseModel):
    """Alert labels with validation."""

    alertname: str
    severity: str | None = None
    service: str | None = None
    category: str | None = None
    gpu_id: str | None = None
    component: str | None = None

    @field_validator("alertname", mode="before")
    @classmethod
    def validate_alertname(cls, v: str) -> str:
        """Validate alert name length and content."""
        if not v:
            raise ValueError("alertname cannot be empty")
        if "\x00" in v:
            raise ValueError("alertname cannot contain null bytes")
        if len(v) > 256:
            raise ValueError("alertname cannot exceed 256 characters")
        return v.strip()

    @field_validator("severity", mode="before")
    @classmethod
    def validate_severity(cls, v: str | None) -> str | None:
        """Validate severity is one of allowed values."""
        if v is None:
            return v
        allowed = {"critical", "warning", "info", "debug"}
        v_lower = str(v).lower().strip()
        if v_lower not in allowed:
            raise ValueError(f"severity must be one of {allowed}, got {v_lower}")
        return v_lower

    @field_validator("service", mode="before")
    @classmethod
    def validate_service(cls, v: str | None) -> str | None:
        """Validate service name."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 128:
            raise ValueError("service cannot exceed 128 characters")
        if not v.replace("-", "").replace("_", "").isalnum():
            raise ValueError(
                "service must contain only alphanumeric characters, hyphens, or underscores"
            )
        return v

    @field_validator("category", mode="before")
    @classmethod
    def validate_category(cls, v: str | None) -> str | None:
        """Validate alert category."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 128:
            raise ValueError("category cannot exceed 128 characters")
        return v

    @field_validator("gpu_id", mode="before")
    @classmethod
    def validate_gpu_id(cls, v: str | None) -> str | None:
        """Validate GPU ID format."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 32:
            raise ValueError("gpu_id cannot exceed 32 characters")
        if not v.replace("-", "").isalnum():
            raise ValueError("gpu_id must be alphanumeric with optional hyphens")
        return v

    @field_validator("component", mode="before")
    @classmethod
    def validate_component(cls, v: str | None) -> str | None:
        """Validate component name."""
        if v is None:
            return v
        v = str(v).strip()
        if len(v) > 128:
            raise ValueError("component cannot exceed 128 characters")
        return v


class Alert(BaseModel):
    """Single alert with labels and annotations."""

    labels: AlertLabels
    annotations: dict[str, Any] = {}
    status: str


class AlertPayload(BaseModel):
    """Webhook payload containing alerts."""

    alerts: list[Alert]
    groupLabels: dict[str, Any] = {}
