#!/usr/bin/env python3

import sys
from typing import Any

from config_utils import load_json_config, save_json_config, expand_vars


def build_entry(transport: str, payload: list[str]) -> dict:
    """
    Build an MCP server entry based on transport type.

    Args:
        transport: Either 'http' or 'stdio'
        payload: Transport-specific configuration arguments

    Returns:
        Dictionary containing server configuration

    Raises:
        SystemExit: If transport is invalid or required arguments are missing
    """
    if transport == "http":
        if not payload:
            raise SystemExit("HTTP transport requires a URL argument")
        url, *headers = payload
        entry: dict[str, Any] = {"httpUrl": expand_vars(url)}
        header_map: dict[str, str] = {}
        for header in headers:
            if ":" not in header:
                continue
            key, value = header.split(":", 1)
            header_map[key] = expand_vars(value)
        if header_map:
            entry["headers"] = header_map
        return entry

    if transport == "stdio":
        if not payload:
            raise SystemExit("stdio transport requires a command argument")
        command, *args = payload
        return {"command": command, "args": args}

    raise SystemExit(f"Unsupported transport: {transport}")


def main() -> None:
    """Main entry point for the script."""
    if len(sys.argv) < 4:
        raise SystemExit(
            "Usage: add-to-gemini-settings.py <transport> <server> <config_path> [payload...]"
        )

    transport, server_name, config_path, *payload = sys.argv[1:]

    # Load existing config with default mcpServers structure
    config = load_json_config(config_path, default={"mcpServers": {}}, create_backup=False)
    config.setdefault("mcpServers", {})
    config["mcpServers"][server_name] = build_entry(transport, payload)

    # Save updated config
    save_json_config(config_path, config)


if __name__ == "__main__":
    main()
