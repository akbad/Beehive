"""Config validator for Beehive cleanup module.

Validates that all required configuration fields are present before
cleanup operations run. This prevents silent failures from missing keys.
"""
import sys
from typing import Any, Mapping


class ConfigurationError(Exception):
    """Raised when configuration is invalid."""
    pass


# Required schema for cleanup operations
REQUIRED_SCHEMA: dict[str, Any] = {
    "agents": list,            # At least one agent enabled
    "retention_period_for": {
        "claude_mem": str,     # Duration string (e.g., "30d")
        "serena": str,
        "qdrant": str,
        "memory_mcp": str,
    },
    "cleanup": {
        "min_interval": str,   # Duration string
    },
    "trash": {
        "grace_period": str,   # Duration string
    },
    "path_to": {
        "workspace": str,      # Base workspace path string
    },
    "startup_timeout_for": {
        "mcp_servers": int,    # Seconds to wait for MCP servers
        "docker_daemon": int,  # Seconds to wait for Docker daemon
    },
    "port_for": {
        "qdrant_db": int,
        "qdrant_mcp": int,
        "sourcegraph_mcp": int,
        "semgrep_mcp": int,
        "serena_mcp": int,
    },
}


def _validate_node(config: Mapping[str, Any], schema: dict, path: str = "") -> list[str]:
    """Recursively validate config against schema.

    Args:
        config: Configuration dict to validate.
        schema: Schema dict defining required structure.
        path: Current path for error messages.

    Returns:
        List of error messages (empty if valid).
    """
    errors = []

    for key, expected_type in schema.items():
        current_path = f"{path}.{key}" if path else key

        if key not in config:
            errors.append(f"Missing required key: {current_path}")
            continue

        value = config[key]

        if isinstance(expected_type, dict):
            # Nested structure - recurse
            if not isinstance(value, dict):
                errors.append(
                    f"Expected dict for '{current_path}', got {type(value).__name__}"
                )
            else:
                errors.extend(_validate_node(value, expected_type, current_path))
        elif expected_type is list:
            # Check it's a list
            if not isinstance(value, list):
                errors.append(
                    f"Expected list for '{current_path}', got {type(value).__name__}"
                )
            elif len(value) == 0:
                errors.append(f"'{current_path}' cannot be empty")
        elif expected_type is str:
            # Check it's a string (or can be stringified)
            if value is None:
                errors.append(f"'{current_path}' cannot be None")
            elif not isinstance(value, (str, int, float)):
                errors.append(
                    f"Expected string-like for '{current_path}', got {type(value).__name__}"
                )
        elif expected_type is int:
            if not isinstance(value, int):
                errors.append(
                    f"Expected int for '{current_path}', got {type(value).__name__}"
                )

    return errors


def validate_config(config: Mapping[str, Any]) -> list[str]:
    """Validate config dict against required schema.

    Args:
        config: Configuration dictionary to validate.

    Returns:
        List of error messages (empty list = valid).
    """
    if not isinstance(config, dict):
        return ["Configuration must be a dictionary"]

    return _validate_node(config, REQUIRED_SCHEMA)


def validate_and_raise(config: Mapping[str, Any]) -> None:
    """Validate config and raise ConfigurationError if invalid.

    Args:
        config: Configuration dictionary to validate.

    Raises:
        ConfigurationError: If configuration is invalid.
    """
    errors = validate_config(config)
    if errors:
        error_msg = "Configuration validation failed:\n  - " + "\n  - ".join(errors)
        raise ConfigurationError(error_msg)


def validate_duration_format(duration: str) -> str | None:
    """Validate a duration string format.

    Args:
        duration: Duration string to validate.

    Returns:
        Error message if invalid, None if valid.
    """
    import re

    if duration.lower() == "always":
        return None

    if not re.match(r"^\d+[hdwmy]$", duration.lower()):
        return f"Invalid duration format: '{duration}'. Use format like '24h', '30d', '2w', '3m', '1y', or 'always'"

    return None


def _check_durations(section: Mapping[str, Any], section_name: str, *keys: str) -> list[str]:
    """Check duration format for specified keys in a config section.

    Args:
        section: Config section dictionary.
        section_name: Name of section for error messages.
        *keys: Keys to check within the section.

    Returns:
        List of error messages for invalid durations.
    """
    errors = []
    for key in keys:
        if key in section:
            if err := validate_duration_format(str(section[key])):
                errors.append(f"{section_name}.{key}: {err}")
    return errors


def validate_durations(config: Mapping[str, Any]) -> list[str]:
    """Validate all duration strings in config have correct format.

    Args:
        config: Configuration dictionary.

    Returns:
        List of error messages for invalid durations.
    """
    errors = []

    errors.extend(_check_durations(
        config.get("retention_period_for", {}), "retention_period_for",
        "claude_mem", "serena", "qdrant", "memory_mcp"
    ))
    errors.extend(_check_durations(
        config.get("cleanup", {}), "cleanup",
        "min_interval"
    ))
    errors.extend(_check_durations(
        config.get("trash", {}), "trash",
        "grace_period"
    ))

    return errors


def full_validate(config: Mapping[str, Any]) -> list[str]:
    """Perform full validation including structure and format checks.

    Args:
        config: Configuration dictionary.

    Returns:
        List of all error messages.
    """
    errors = validate_config(config)

    # Only check duration formats if structure is valid
    if not errors:
        errors.extend(validate_durations(config))

    return errors


def main() -> int:
    """CLI entry point for config validation.

    Returns:
        0 if valid, 1 if invalid.
    """
    from .config_loader import get_config

    try:
        config = get_config()
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    errors = full_validate(config)

    if errors:
        print("Configuration validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("Configuration is valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
