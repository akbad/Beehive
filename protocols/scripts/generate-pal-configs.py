#!/usr/bin/env python3
"""
Generate PAL per-CLI config files.

This script reads:
  - settings.yaml (paths and CLI launch commands)
  - directives.yml (user-accessible model/role settings)
to generate one JSON config file per CLI supported by both Bureau and PAL's clink 
(i.e. claude.json, codex.json, gemini.json).

Roles are auto-discovered from the agents/role-prompts/ directory.

Usage:
    python generate-pal-configs.py [--dry-run] [--verbose]

Options:
    --dry-run   Print what would be generated without writing files
    --verbose   Print detailed output during generation
"""

from __future__ import annotations

import argparse
import json
import sys
import yaml
from pathlib import Path
from typing import Any

from lib.pollen.config_loader import get_config


def get_bureau_root() -> Path:
    """Find the project root (by checking for pyproject.toml)."""
    current = Path(__file__).resolve()
    for parent in [current] + list(current.parents):
        if (parent / "pyproject.toml").exists():
            return parent
    raise RuntimeError("Could not find project root (no pyproject.toml found)")


def discover_roles(role_prompts_dir: Path) -> list[str]:
    """
    Discover role names from .md files in the role prompts source directory in Bureau.

    Args:
        role_prompts_dir: Directory containing role prompt files (e.g., agents/role-prompts/)

    Returns:
        Sorted list of role names (simply basenames of role prompt files)
    """
    if not role_prompts_dir.exists():
        raise FileNotFoundError(f"Role source directory not found: {role_prompts_dir}")

    roles = []
    for file in role_prompts_dir.glob("*.md"):
        # use role prompt file's basename as the role's name
        roles.append(file.stem)

    return sorted(roles)


def build_roles_path_map(
    base_setting: str | list[str],
    extra_setting: str | list[str],
    all_role_names: list[str],
    pal_prompts_dir: str,
) -> dict[str, dict[str, str]]:
    """
    Build roles config dict from base and extra role settings.

    Args:
        base_setting:     Baseline roles ("all", "none", or list of role names)
        extra_setting:    CLI-specific extra roles ("all", "none", or list of role names)
        all_role_names:   Complete list of available roles (from auto-discovery)
        pal_prompts_dir:  Prefix for prompt_path (e.g., "systemprompts/bees")

    Returns:
        Roles configuration dictionary mapping role name -> {"prompt_path": ...}
    """
    def expand(setting: str | list[str]) -> set[str]:
        if setting == "all":
            return set(all_role_names)
        elif isinstance(setting, list):
            return set(r for r in setting if r in all_role_names)
        return set()  # includes when setting is "none"

    final = expand(base_setting) | expand(extra_setting)
    return {name: {"prompt_path": f"{pal_prompts_dir}/{name}.md"} for name in sorted(final)}


def generate_arg_list(template: list[str], substitutions: dict[str, str]) -> list[str]:
    """
    Substitute placeholders in argument template (to then be provided as explicit arguments for
    the CLI launch command when launched via clink).

    Args:
        template:       List of argument strings with {placeholder} markers
        substitutions:  Dictionary of placeholder -> value mappings

    Returns:
        List with placeholders replaced
    """
    result = []
    for arg in template:
        for key, value in substitutions.items():
            arg = arg.replace(f"{{{key}}}", value)
        result.append(arg)
    return result


def generate_pal_cli_config_dict(
    cli_name: str,
    cli_settings: dict[str, Any],
    roles_path_map: dict[str, dict[str, str]],
    arg_vals: dict[str, str],
) -> dict[str, Any]:
    """
    Generate a PAL configuration dictionary for a specific coding CLI, 
    ready to be dumped as JSON to constitute a PAL-compatible CLI-specific config file.

    Args:
        cli_name:      CLI name (e.g. "codex")
        cli_settings:  Per-CLI settings (from settings.yaml)
        roles_path_map:  Roles configuration (role name -> dict with single prompt_path entry)
        arg_vals:      Values for placeholders for arguments to CLI launch commands (e.g., model, effort)

    Returns:
        Complete configuration dictionary for this CLI
    """
    # Build additional_args with placeholder substitutions
    args_template = cli_settings.get("additional_args", [])
    additional_args = generate_arg_list(args_template, arg_vals)

    return {
        "name": cli_name,
        "command": cli_settings["command"],
        "additional_args": additional_args,
        "env": cli_settings.get("env", {}),
        "roles": roles_path_map,
    }


def get_cli_arg_vals(cli_name: str, cli_config: dict[str, Any]) -> dict[str, str]:
    """
    Get values (from root-level, user-oriented YAML configs) to swap with placeholders in argument templates
    to create list of args to pass when launching a CLI via clink.

    Args:
        cli_name: CLI name (claude, codex, gemini)
        cli_config: The pal.<cli_name> config from directives.yml

    Returns:
        Dictionary of placeholder -> value substitutions
    """
    if cli_name == "claude":
        return {"model": cli_config.get("model", "sonnet")}
    elif cli_name == "codex":
        return {
            "model": cli_config.get("model", "gpt-5.2-codex"),
            "effort": cli_config.get("effort", "medium"),
        }
    else:
        # gemini and others
        return {}


def generate_pal_cli_config_files(
    pal_settings: dict[str, Any],
    bureau_root: Path,
    dry_run: bool = False,
    verbose: bool = False,
) -> list[Path]:
    """
    Generate PAL per-coding-CLI config files.

    Args:
        pal_settings:   Parsed settings.yaml configuration
        bureau_root:   Bureau root directory
        dry_run:        If True, don't write files
        verbose:        If True, print detailed output

    Returns:
        List of generated file paths
    """
    # Extract config values from settings.yaml
    cli_settings = pal_settings["cli"]
    pal_role_prompts_dir = pal_settings["role_prompt_dir_in"]["pal"]
    bureau_role_prompts_dir = bureau_root / pal_settings["role_prompt_dir_in"]["bureau"]
    bureau_root_level_configs = get_config()

    # NOTE: pal_root_level_config is distinct from pal_settings
    #   - pal_settings stores PAL-related settings values that rarely change
    #   - pal_config stores PAL-related configs from Bureau's root-level YAML configs
    #   (meant for user-oriented configurable values, like choice of model and reasoning effort)
    #
    # Handle both:
    #   - key non-existence
    #   - existence w/o a value (which would result in .get() returning `None` instead of `{}`)
    pal_root_level_config = bureau_root_level_configs.get("pal", {}) or {}
    base_roles_config = pal_root_level_config.get("base-roles", "all")

    # Auto-discover available Bureau role prompt files
    role_names = discover_roles(bureau_role_prompts_dir)
    if verbose:
        print(f"Discovered {len(role_names)} roles from {bureau_role_prompts_dir}")

    output_dir = bureau_root / "protocols" / "pal" / "generated"
    output_dir.mkdir(parents=True, exist_ok=True)
    generated_files = []

    for cli_name, cli_settings_dict in cli_settings.items():
        # Get per-CLI config from pal.<cli_name>, handling both:
        # - key non-existence
        # - existence w/o a value (which would result in .get() returning `None` instead of `{}`)
        cli_config = pal_root_level_config.get(cli_name, {}) or {}

        extra_roles_config = cli_config.get("extra-roles", "none")

        # Build mapping from role names to {"prompt_path": <path>}
        roles_path_map = build_roles_path_map(base_roles_config, extra_roles_config, role_names, pal_role_prompts_dir)

        # Get arg placeholder values from per-CLI config (model, effort, etc.)
        arg_vals = get_cli_arg_vals(cli_name, cli_config)

        # Generate this CLI's PAL config file
        config_dict = generate_pal_cli_config_dict(
            cli_name,
            cli_settings_dict,
            roles_path_map,
            arg_vals,
        )

        filename = f"{cli_name}.json"
        output_path = output_dir / filename

        if verbose or dry_run:
            print(f"{'Would generate' if dry_run else 'Generating'}: {output_path.name}")
            if verbose:
                print(f"  - additional_args: {config_dict['additional_args']}")
                print(f"  - roles: {len(config_dict['roles'])} roles")

        if not dry_run:
            with open(output_path, "w") as f:
                json.dump(config_dict, f, indent=4)
                f.write("\n")  # trailing newline

        generated_files.append(output_path)

    return generated_files


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate PAL per-CLI config files from settings.yaml"
    )
    parser.add_argument(
        "--dry-run",
        "-d",
        action="store_true",
        help="Print what would be generated (without writing files)",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Print detailed output",
    )
    args = parser.parse_args()

    try:
        bureau_root = get_bureau_root()
        pal_settings_path = bureau_root / "protocols" / "pal" / "settings.yaml"

        if not pal_settings_path.exists():
            print(f"Error: settings.yaml not found at {pal_settings_path}", file=sys.stderr)
            return 1

        with open(pal_settings_path) as f:
            pal_settings = yaml.safe_load(f)

        generated = generate_pal_cli_config_files(
            pal_settings=pal_settings,
            bureau_root=bureau_root,
            dry_run=args.dry_run,
            verbose=args.verbose,
        )

        if args.dry_run:
            print(f"Would generate {len(generated)} configuration files")
        else:
            print(f"Generated {len(generated)} configuration files")

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
