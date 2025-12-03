"""Load config related to Beehive cleanup"""
import json
import re
from datetime import timedelta
from pathlib import Path
from typing import TypedDict

BEEHIVE_DIR = Path.home() / ".beehive"
CONFIG_PATH = BEEHIVE_DIR / "config.json"
STATE_PATH = BEEHIVE_DIR / "state.json"
TRASH_DIR = BEEHIVE_DIR / "trash"


# stores how long memories are retained for in each memory backend
class RetentionConfig(TypedDict):
    claude_mem: str
    serena: str
    qdrant: str
    memory_mcp: str


# stores grace period before trashed items are deleted permanently
class TrashConfig(TypedDict):
    grace_period: str


# stores interval of time to wait in between memory cleanup runs
class CleanupConfig(TypedDict):
    min_interval: str


class Config(TypedDict):
    retention: RetentionConfig
    trash: TrashConfig
    cleanup: CleanupConfig


# default values for per-MCP memory retention intervals
DEFAULT_CONFIG: Config = {
    "retention": {
        "claude_mem": "30d",
        "serena": "90d",
        "qdrant": "180d",
        "memory_mcp": "365d",
    },
    "trash": {
        "grace_period": "30d",
    },
    "cleanup": {
        "min_interval": "24h",
    },
}


def parse_duration(duration_str: str) -> timedelta:
    """Parse duration string like '30d', '2w', '3m', '1y', '24h' to timedelta."""
    if duration_str.lower() == "never":
        return timedelta.max

    match = re.match(r"^(\d+)([hdwmy])$", duration_str.lower())
    if not match:
        raise ValueError(f"Invalid duration format: {duration_str}. Use format like '24h', '30d', '2w', '3m', '1y'")

    value = int(match.group(1))
    unit = match.group(2)

    if unit == "h":
        return timedelta(hours=value)
    elif unit == "d":
        return timedelta(days=value)
    elif unit == "w":
        return timedelta(weeks=value)
    elif unit == "m":
        return timedelta(days=value * 30)  # Approximate month
    elif unit == "y":
        return timedelta(days=value * 365)  # Approximate year

    raise ValueError(f"Unknown duration unit: {unit}")


def load_config() -> Config:
    """Load config from ~/.beehive/config.json; fall back to defaults in DEFAULT_CONFIG where needed."""
    if not CONFIG_PATH.exists():
        return DEFAULT_CONFIG.copy()

    try:
        with open(CONFIG_PATH) as f:
            user_config = json.load(f)
    except (json.JSONDecodeError, IOError):
        return DEFAULT_CONFIG.copy()

    # merge user config with defaults
    config = DEFAULT_CONFIG.copy()

    if "retention" in user_config:
        config["retention"] = {**DEFAULT_CONFIG["retention"], **user_config["retention"]}  # type: ignore[typeddict-item]

    if "trash" in user_config:
        config["trash"] = {**DEFAULT_CONFIG["trash"], **user_config["trash"]}  # type: ignore[typeddict-item]

    if "cleanup" in user_config:
        config["cleanup"] = {**DEFAULT_CONFIG["cleanup"], **user_config["cleanup"]}  # type: ignore[typeddict-item]

    return config


def get_retention(config: Config, storage_name: str) -> str:
    """Get retention period for a chosen memory backend."""
    # normalize memory backend's name (e.g. claude-mem -> claude_mem)
    key = storage_name.replace("-", "_")
    
    return config["retention"][key]