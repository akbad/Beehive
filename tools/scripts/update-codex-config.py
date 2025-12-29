#!/usr/bin/env -S uv run
"""
Helper script to update Codex config.toml with auto-approval settings and
sandbox writable roots.

Usage:
    uv run update-codex-config.py <config_file_path> [--auto-approve]
        [--ensure-writable-root <path> ...]
"""

from __future__ import annotations

import argparse
import tomllib
from pathlib import Path


def parse_writable_roots(line: str) -> list[str]:
    snippet = f"[sandbox_workspace_write]\n{line}\n"
    try:
        parsed = tomllib.loads(snippet)
    except tomllib.TOMLDecodeError:
        return []

    roots = parsed.get("sandbox_workspace_write", {}).get("writable_roots")
    if isinstance(roots, list):
        return [str(item) for item in roots]
    return []


def finalize_sandbox_section(
    new_lines: list[str],
    writable_roots: list[str],
    auto_approve: bool,
    has_writable_roots: bool,
    has_network_access: bool,
) -> tuple[bool, bool]:
    if writable_roots and not has_writable_roots:
        new_lines.append(format_writable_roots(writable_roots))
        has_writable_roots = True
        print("Added 'writable_roots' to [sandbox_workspace_write]")
    if auto_approve and not has_network_access:
        new_lines.append("network_access = true")
        has_network_access = True
        print("Added 'network_access = true' to [sandbox_workspace_write]")

    return has_writable_roots, has_network_access


def format_writable_roots(roots: list[str]) -> str:
    formatted = ", ".join(f'"{root}"' for root in roots)
    return f"writable_roots = [{formatted}]"


def merge_roots(existing: list[str], additions: list[str]) -> list[str]:
    merged = list(existing)
    for root in additions:
        if root not in merged:
            merged.append(root)
    return merged


def update_codex_config(config_path: str, auto_approve: bool, writable_roots: list[str]) -> None:
    config_file = Path(config_path).expanduser()

    # Create parent directory if it doesn't exist
    config_file.parent.mkdir(parents=True, exist_ok=True)

    # Read existing config or start fresh
    content = config_file.read_text() if config_file.exists() else ""
    lines = content.split("\n") if content else []

    # Track what we need to add/update
    has_approval_policy = False
    has_sandbox_mode = False
    has_sandbox_section = False
    has_network_access = False
    has_writable_roots = False
    in_sandbox_section = False

    new_lines: list[str] = []

    for line in lines:
        stripped = line.strip()
        header = stripped.split("#", 1)[0].strip()

        # Check for existing settings
        if stripped.startswith("approval_policy"):
            has_approval_policy = True
            if auto_approve:
                new_lines.append('approval_policy = "never"')
                print("Updated 'approval_policy' to 'never'")
            else:
                new_lines.append(line)
            continue

        if stripped.startswith("sandbox_mode"):
            has_sandbox_mode = True
            if auto_approve:
                new_lines.append('sandbox_mode = "workspace-write"')
                print("Updated 'sandbox_mode' to 'workspace-write'")
            else:
                new_lines.append(line)
            continue

        if header == "[sandbox_workspace_write]":
            has_sandbox_section = True
            in_sandbox_section = True
            new_lines.append(line)
            continue

        if in_sandbox_section:
            if header.startswith("["):
                has_writable_roots, has_network_access = finalize_sandbox_section(
                    new_lines,
                    writable_roots,
                    auto_approve,
                    has_writable_roots,
                    has_network_access,
                )
                in_sandbox_section = False
                new_lines.append(line)
                continue

            if stripped.startswith("network_access"):
                has_network_access = True
                if auto_approve:
                    new_lines.append("network_access = true")
                else:
                    new_lines.append(line)
                continue

            if stripped.startswith("writable_roots"):
                has_writable_roots = True
                if writable_roots:
                    existing = parse_writable_roots(line)
                    merged = merge_roots(existing, writable_roots)
                    new_lines.append(format_writable_roots(merged))
                    if merged != existing:
                        print("Updated 'writable_roots' in [sandbox_workspace_write]")
                else:
                    new_lines.append(line)
                continue

            new_lines.append(line)
            continue

        new_lines.append(line)

    if in_sandbox_section:
        has_writable_roots, has_network_access = finalize_sandbox_section(
            new_lines,
            writable_roots,
            auto_approve,
            has_writable_roots,
            has_network_access,
        )

    # Add missing auto-approval settings if requested
    if auto_approve:
        insert_index = 0
        if not has_approval_policy:
            new_lines.insert(insert_index, 'approval_policy = "never"')
            print("Added 'approval_policy = \"never\"'")
            insert_index += 1
        if not has_sandbox_mode:
            new_lines.insert(insert_index, 'sandbox_mode = "workspace-write"')
            print("Added 'sandbox_mode = \"workspace-write\"'")

    if writable_roots and not has_sandbox_section:
        new_lines.append("")
        new_lines.append("[sandbox_workspace_write]")
        new_lines.append(format_writable_roots(writable_roots))
        print("Added '[sandbox_workspace_write]' section with 'writable_roots'")
        if auto_approve:
            new_lines.append("network_access = true")
            print("Added 'network_access = true' to [sandbox_workspace_write]")

    # Write updated config
    with open(config_file, "w") as f:
        f.write("\n".join(new_lines).rstrip() + "\n")

    print(f"Successfully updated {config_file}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Update Codex config.toml with auto-approval settings and sandbox writable roots."
        )
    )
    parser.add_argument("config_path", help="Path to the config.toml file")
    parser.add_argument("--auto-approve", action="store_true")
    parser.add_argument("--ensure-writable-root", action="append", default=[])
    args = parser.parse_args()

    update_codex_config(
        args.config_path,
        auto_approve=args.auto_approve,
        writable_roots=args.ensure_writable_root,
    )


if __name__ == "__main__":
    main()
