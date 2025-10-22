#!/usr/bin/env python3
"""
Helper script to update Codex config.toml with auto-approval settings.

Usage:
    python3 add-codex-auto-approvals.py <config_file_path>
"""

import sys
from pathlib import Path


def update_codex_config(config_path: str) -> None:
    """
    Update Codex config.toml with auto-approval settings.

    Args:
        config_path: Path to the config.toml file
    """
    config_file = Path(config_path).expanduser()

    # Create parent directory if it doesn't exist
    config_file.parent.mkdir(parents=True, exist_ok=True)

    # Read existing config or start fresh
    if config_file.exists():
        with open(config_file, 'r') as f:
            content = f.read()
    else:
        content = ""

    lines = content.split('\n') if content else []

    # Track what we need to add/update
    has_approval_policy = False
    has_sandbox_mode = False
    has_sandbox_section = False
    has_network_access = False
    in_sandbox_section = False

    new_lines = []
    i = 0

    while i < len(lines):
        line = lines[i].strip()

        # Check for existing settings
        if line.startswith('approval_policy'):
            has_approval_policy = True
            new_lines.append('approval_policy = "never"')
        elif line.startswith('sandbox_mode'):
            has_sandbox_mode = True
            new_lines.append('sandbox_mode = "workspace-write"')
        elif line.startswith('[sandbox_workspace_write]'):
            has_sandbox_section = True
            in_sandbox_section = True
            new_lines.append(line)
        elif in_sandbox_section:
            if line.startswith('['):
                # Entering a new section
                in_sandbox_section = False
                if not has_network_access:
                    new_lines.append('network_access = true')
                    has_network_access = True
                new_lines.append(lines[i])
            elif line.startswith('network_access'):
                has_network_access = True
                new_lines.append('network_access = true')
            else:
                new_lines.append(lines[i])
        else:
            new_lines.append(lines[i])

        i += 1

    # Add missing settings
    if not has_approval_policy:
        new_lines.insert(0, 'approval_policy = "never"')
        print("Added 'approval_policy = \"never\"'")
    else:
        print("Updated 'approval_policy' to 'never'")

    if not has_sandbox_mode:
        new_lines.insert(1 if has_approval_policy else 0, 'sandbox_mode = "workspace-write"')
        print("Added 'sandbox_mode = \"workspace-write\"'")
    else:
        print("Updated 'sandbox_mode' to 'workspace-write'")

    if not has_sandbox_section:
        new_lines.append('')
        new_lines.append('[sandbox_workspace_write]')
        new_lines.append('network_access = true')
        print("Added '[sandbox_workspace_write]' section with 'network_access = true'")
    elif not has_network_access:
        print("Added 'network_access = true' to [sandbox_workspace_write]")
    else:
        print("'network_access' already set to true")

    # Write updated config
    with open(config_file, 'w') as f:
        f.write('\n'.join(new_lines))
        if not new_lines[-1].strip():  # Don't double newline
            pass
        else:
            f.write('\n')

    print(f"Successfully updated {config_file}")


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 add-codex-auto-approvals.py <config_file_path>")
        sys.exit(1)

    config_path = sys.argv[1]
    update_codex_config(config_path)
