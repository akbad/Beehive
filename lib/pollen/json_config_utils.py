#!/usr/bin/env -S uv run
"""
Shared utility functions for managing configuration files.

This module provides common operations for loading, saving, and
managing JSON configuration files with proper error handling.
"""

import json
import os
from pathlib import Path
from typing import Optional


def ensure_parent_dir(file_path: Path) -> None:
    """
    Ensure the parent directory of a file exists.

    Args:
        file_path: Path object for the target file
    """
    file_path.parent.mkdir(parents=True, exist_ok=True)


def load_json_config(
    path: str,
    default: Optional[dict] = None,
    create_backup: bool = True
) -> dict:
    """
    Load a JSON configuration file with error handling.

    Args:
        path: Path to the JSON file (supports ~ expansion)
        default: Default dict to return if file doesn't exist (defaults to {})
        create_backup: Whether to create a backup if JSON is invalid

    Returns:
        Loaded configuration dictionary

    Raises:
        SystemExit: If JSON is invalid and create_backup is False
    """
    if default is None:
        default = {}

    config_path = Path(path).expanduser()

    if not config_path.exists():
        return default.copy()

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError as exc:
        if create_backup:
            backup_path = config_path.with_suffix('.json.backup')
            config_path.rename(backup_path)
            print(f"Warning: {config_path} contains invalid JSON.")
            print(f"Created backup at {backup_path} and starting fresh.")
            return default.copy()
        else:
            raise SystemExit(f"Failed to parse {path}: {exc}") from exc


def save_json_config(path: str, config: dict, indent: int = 2) -> None:
    """
    Save a configuration dictionary to a JSON file.

    Args:
        path: Path to the JSON file (supports ~ expansion)
        config: Configuration dictionary to save
        indent: JSON indentation level (default: 2)
    """
    config_path = Path(path).expanduser()
    ensure_parent_dir(config_path)

    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=indent)
        f.write('\n')  # Add trailing newline


def expand_vars(value: str) -> str:
    """
    Expand environment variables in a string.

    Args:
        value: String that may contain environment variables

    Returns:
        String with environment variables expanded
    """
    return os.path.expandvars(value)
