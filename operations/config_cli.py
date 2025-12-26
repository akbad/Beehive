#!/usr/bin/env -S uv run
"""CLI tool for shell scripts to read Beehive configuration.

1. Merges configs using the order: charter.yml → directives.yml → local.yml → env)
2. Reads from merged config

Usage:
    get-config agents                           # Output: claude gemini codex opencode
    get-config retention_period_for.qdrant      # Output: 180d
    get-config path_to.qdrant_url                # Output: http://127.0.0.1:8780
    get-config --check agent claude    # Exit 0 if enabled, 1 if not
    get-config --list agents           # List all enabled agents
"""
import sys
from typing import Any, Mapping

from .config_loader import get_config, is_agent_enabled, get_enabled_agents


def get_nested_value(data: Mapping[str, Any], key_path: str) -> Any:
    """Get a nested value from a dict using dot notation.

    Args:
        data: Dictionary to traverse.
        key_path: Dot-separated path (e.g., "retention_period_for.qdrant").

    Returns:
        The value at the path, or None if not found.
    """
    keys = key_path.split(".")
    current = data

    for key in keys:
        if isinstance(current, dict) and key in current:
            current = current[key]
        else:
            return None

    return current


def format_value(value: Any) -> str:
    """Format a value for shell output.

    Lists are space-separated, other values are converted to strings.
    """
    if isinstance(value, list):
        return " ".join(str(v) for v in value)
    elif isinstance(value, bool):
        return "true" if value else "false"
    elif value is None:
        return ""
    else:
        return str(value)


def main() -> int:
    """Main entrypoint for get-config CLI."""
    args = sys.argv[1:]

    if not args:
        print("Usage: get-config <key.path> | --check agent <name> | --list agents", file=sys.stderr)
        return 1

    if args[0] == "--check":
        # check if requested setting is enabled in the config 
        # (only supports checking if an agent is enabled for now)
        if len(args) < 3:
            print("Usage: get-config --check agent <name>", file=sys.stderr)
            return 1

        check_type = args[1]
        check_value = args[2]

        if check_type == "agent":
            # recall callers are bash scripts, so return 0 as true
            return 0 if is_agent_enabled(check_value) else 1
        else:
            print(f"Unknown check type: {check_type}", file=sys.stderr)
            return 1

    if args[0] == "--list":
        # show all enabled settings for a specific key in the config
        # (only supports checking list of enabled agents for now)
        if len(args) < 2:
            print("Usage: get-config --list agents", file=sys.stderr)
            return 1

        list_type = args[1]

        if list_type == "agents":
            print(" ".join(get_enabled_agents()))
            return 0
        else:
            print(f"Unknown list type: {list_type}", file=sys.stderr)
            return 1

    # get config value using key path
    key_path = args[0]
    config = get_config()
    value = get_nested_value(config, key_path)

    if value is None:
        print(f"Key not found: {key_path}", file=sys.stderr)
        return 1

    print(format_value(value))
    return 0


if __name__ == "__main__":
    sys.exit(main())
