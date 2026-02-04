"""
Utilities for resolving and expanding placeholders in configuration strings
using values from:
- env vars
- a config dictionary 
"""

from __future__ import annotations

import os
import re
from typing import Any, Mapping

# regex used to extract names of value placeholders (formatted to be within `${...}`)
# note `[^}+]` (match all non `}` chars) is used in the capturing group over `.*` since there may
#   be multiple value placeholders in a config string; `.*` would match up to the last `}` in the line,
#   capturing the entire substring starting from the beginning of first placeholder to the end of the last,
#   including everything in between
_PLACEHOLDER_REGEX = re.compile(r"\$\{([^}]+)\}")

# retrieve value stored in config dict (i.e. as formed by merging YML configs)
def _get_config_value(config: Mapping[str, Any], path_to_key: str) -> str | None:
    parts = path_to_key.split(".")

    # safely traverse config tree towards key's location
    current: Any = config
    for part in parts:
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return None if current is None else str(current)


def expand_placeholders(
    value: str, config: Mapping[str, Any], env: Mapping[str, str] | None = None
) -> str:
    """
    Expands `${...}` placeholders in a string using environment variables and config values.

    Args:
        value:   The string containing placeholders to expand.
        config:  Mapping used to resolve placeholders (via dot-notation) if they are not found 
                 in the environment.
        env:     A mapping of environment variables to check first. 
                 If None, defaults to os.environ.

    Returns:
        The string with all resolvable placeholders replaced by their actual values.
    """
    if env is None:
        env = os.environ

    def repl(match: re.Match[str]) -> str:
        key = match.group(1)
        if key in env:
            return env[key]
        cfg_val = _get_config_value(config, key)
        return cfg_val if cfg_val is not None else match.group(0)

    expanded = value
    seen = {expanded}
    while True:
        # config validation is responsible for catching recursive placeholders (or cycles thereof) 
        #   that would cause infinite looping here (e.g. `val="...${val}..."`)
        expanded = _PLACEHOLDER_REGEX.sub(repl, expanded)
        if expanded in seen:
            break
        seen.add(expanded)
    return expanded
