#!/usr/bin/env python3
"""
Helper script to update Claude Code settings.json with MCP auto-approval configuration.

Usage:
    python3 add-claude-auto-approvals.py <settings_file_path>

This script:
1. Creates the settings file if it doesn't exist
2. Merges in the MCP auto-approval permissions
3. Preserves existing settings
"""

import sys
from config_utils import load_json_config, save_json_config


def update_claude_settings(settings_path: str) -> None:
    """
    Update Claude settings.json with MCP auto-approval configuration.

    Args:
        settings_path: Path to the settings.json file
    """
    # Load existing settings or start with empty dict
    settings = load_json_config(settings_path, default={})

    # Ensure permissions structure exists
    if 'permissions' not in settings:
        settings['permissions'] = {}

    if 'allow' not in settings['permissions']:
        settings['permissions']['allow'] = []

    # Add MCP wildcard if not already present
    mcp_pattern = "mcp__*"
    if mcp_pattern not in settings['permissions']['allow']:
        settings['permissions']['allow'].append(mcp_pattern)
        print(f"Added '{mcp_pattern}' to permissions.allow")
    else:
        print(f"'{mcp_pattern}' already in permissions.allow")

    # Add enableAllProjectMcpServers if not already set
    if 'enableAllProjectMcpServers' not in settings:
        settings['enableAllProjectMcpServers'] = True
        print("Added 'enableAllProjectMcpServers': true")
    else:
        print(f"'enableAllProjectMcpServers' already set to: {settings['enableAllProjectMcpServers']}")

    # Write updated settings
    save_json_config(settings_path, settings)
    print(f"Successfully updated {settings_path}")


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 update_claude_settings.py <settings_file_path>")
        sys.exit(1)

    settings_path = sys.argv[1]
    update_claude_settings(settings_path)
