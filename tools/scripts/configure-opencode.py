#!/usr/bin/env -S uv run
"""
Merge OpenCode config: fill missing keys from generated template into user config,
preserving existing user overrides.
"""

import argparse
import sys
from pathlib import Path

from lib.pollen import json_config_utils as cu


def merge_missing(base: dict, add: dict) -> dict:
    for k, v in add.items():
        if k not in base or base[k] is None:
            base[k] = v
        elif isinstance(base[k], dict) and isinstance(v, dict):
            merge_missing(base[k], v)
    return base


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True, help="Path to user OpenCode config (will be created/updated)")
    parser.add_argument("--generated", required=True, help="Path to generated OpenCode template")
    args = parser.parse_args()

    target_path = Path(args.target).expanduser()
    generated_path = Path(args.generated).expanduser()

    if not generated_path.exists():
        print(f"Generated config not found: {generated_path}", file=sys.stderr)
        return 1

    generated_cfg = cu.load_json_config(str(generated_path), default={}, create_backup=False)
    target_cfg = cu.load_json_config(str(target_path), default={}, create_backup=True)

    merged = merge_missing(target_cfg, generated_cfg)
    cu.save_json_config(str(target_path), merged, indent=2)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
