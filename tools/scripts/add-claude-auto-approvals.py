#!/usr/bin/env -S uv run
"""
Helper script to update Claude Code settings.json with tool auto-approval configuration
(only if the user specifies the appropriate flag in the calling script).

Usage:
    uv run add-claude-auto-approvals.py <settings_file_path> <server_name_1> <server_name_2> ...

This script:
1. Creates the settings file if it doesn't exist
2. Adds explicit mcp__<server_name> permissions for each provided server
3. Preserves existing settings
"""

import sys

from lib.pollen.json_config_utils import load_json_config, save_json_config


# Built-in Claude Code tools to auto-approve (non-destructive tools only)
BUILTIN_TOOLS_AUTO_APPROVE = [
    "WebFetch",       # Fetch web content
    "WebSearch",      # Search the web
    "Task",           # Launch specialized agents
    "TodoWrite",      # Task tracking
    "AskUserQuestion", # Ask questions during execution
    "ExitPlanMode",   # Exit plan mode
    "BashOutput",     # Read background shell output
    "KillShell",      # Kill background shells
    "Grep",           # Search file contents (read-only)
    "Glob",           # File pattern matching (read-only)
    "Skill",          # User-defined skills
    "SlashCommand",   # User-defined slash commands
    "mcp__plugin_claude-mem_claude-mem-search__*",  # Claude-Mem search tools wildcard
]


def update_claude_settings(settings_path: str, mcp_servers: list[str]) -> None:
    """
    Update Claude settings.json with MCP auto-approval configuration.

    Args:
        settings_path: Path to the settings.json file
        mcp_servers: List of MCP server names to auto-approve
    """
    # Load existing settings or start with empty dict
    settings = load_json_config(settings_path, default={})

    # Ensure permissions structure exists
    if 'permissions' not in settings:
        settings['permissions'] = {}

    if 'allow' not in settings['permissions']:
        settings['permissions']['allow'] = []

    # Add explicit mcp__<server_name> permissions for each server
    added_count = 0
    for server in mcp_servers:
        mcp_permission = f"mcp__{server}"
        if mcp_permission not in settings['permissions']['allow']:
            settings['permissions']['allow'].append(mcp_permission)
            print(f"Added '{mcp_permission}' to permissions.allow")
            added_count += 1
        else:
            print(f"'{mcp_permission}' already in permissions.allow")

    # Add explicit auto-approvals for non-destructive built-in tools
    for perm in BUILTIN_TOOLS_AUTO_APPROVE:
        if perm not in settings['permissions']['allow']:
            settings['permissions']['allow'].append(perm)

    if added_count > 0:
        print(f"Added {added_count} new MCP permission(s)")
    else:
        print("All MCP permissions already present")

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
    if len(sys.argv) < 2:
        print("Usage: uv run add-claude-auto-approvals.py <settings_file_path> [server_name_1] [server_name_2] ...")
        sys.exit(1)

    settings_path = sys.argv[1]
    mcp_servers = sys.argv[2:] if len(sys.argv) > 2 else []
    update_claude_settings(settings_path, mcp_servers)
