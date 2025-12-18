"""Beehive configuration loader providing type-safe access to all Beehive settings.

1. Merges configuration from YAML files with the following precedence hierarchy
   (later sources override earlier ones):  

   a. comb.yml:  Fixed system config (cloud endpoints, disabled tools)
   b. queen.yml: Team defaults (agents, retention, paths)
   c. local.yml: Local overrides (gitignored)
   d. env vars:  Highest-priority overrides

2. Loads configuration

"""
import os
import re
from datetime import timedelta
from functools import lru_cache
from pathlib import Path
from typing import Any, TypedDict

import yaml


# TypedDict schemas corresponding to nested YAML config sections
class RetentionPeriodForConfig(TypedDict):
    claude_mem: str
    serena: str
    qdrant: str
    memory_mcp: str


class TrashConfig(TypedDict):
    grace_period: str


class CleanupConfig(TypedDict):
    min_interval: str


class StartupTimeoutForConfig(TypedDict):
    mcp_servers: int
    docker_daemon: int


class PortForConfig(TypedDict):
    qdrant_db: int
    zen_mcp: int
    qdrant_mcp: int
    sourcegraph_mcp: int
    semgrep_mcp: int
    serena_mcp: int


class StorageForConfig(TypedDict, total=False):
    qdrant: str
    memory_mcp: str
    claude_mem: str


class PathToConfig(TypedDict, total=False):
    workspace: str
    serena_projects: str
    fs_mcp_whitelist: str
    mcp_clones: str
    storage_for: StorageForConfig


class QdrantConfig(TypedDict, total=False):
    collection: str
    embedding_provider: str


class EndpointForConfig(TypedDict):
    sourcegraph: str
    context7: str
    tavily: str


class Config(TypedDict, total=False):
    agents: list[str]
    retention_period_for: RetentionPeriodForConfig
    trash: TrashConfig
    cleanup: CleanupConfig
    startup_timeout_for: StartupTimeoutForConfig
    port_for: PortForConfig
    path_to: PathToConfig
    qdrant: QdrantConfig
    endpoint_for: EndpointForConfig


def find_repo_root(start_path: Path | None = None) -> Path:
    """Find the repository root by looking for queen.yml or .git directory.

    Args:
        start_path: Starting directory for search. Defaults to cwd.

    Returns:
        Path to repository root.

    Raises:
        FileNotFoundError: If no repo root found.
    """
    if start_path is None:
        start_path = Path.cwd()

    current = start_path.resolve()

    while current != current.parent:
        if (current / "queen.yml").exists() or (current / ".git").exists():
            return current
        current = current.parent

    # Check root directory
    if (current / "queen.yml").exists() or (current / ".git").exists():
        return current

    raise FileNotFoundError(
        f"Could not find repository root (queen.yml or .git) starting from {start_path}"
    )


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Deep merge two dicts, with the `override` dict taking precedence.

    Args:
        base: Base dictionary.
        override: Dictionary with override values.

    Returns:
        Merged dictionary.
    """
    result = base.copy()

    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value

    return result


def expand_path(path_str: str) -> Path:
    """Expand ~ and environment variables in path string."""
    expanded = os.path.expandvars(os.path.expanduser(path_str))
    return Path(expanded)


def _load_yaml_file(path: Path) -> dict[str, Any]:
    """Load YAML file if it exists, otherwise return empty dict."""
    if path.exists():
        with open(path) as f:
            return yaml.safe_load(f) or {}
    return {}


@lru_cache(maxsize=1)  # cache most recent returned config (clear using clear_config_cache())
def get_config() -> Config:
    """Load and merge configs, following this resolution order:

    1. comb.yml (base defaults, required)
    2. queen.yml (team config, if exists)
    3. local.yml (local overrides, if exists)
    4. Environment variables (highest priority)
    
    For testing: 
    1. monkeypatch find_repo_root() to return the temp testing directory path
    2. call clear_config_cache() to clear cache
    3. call get_config() to do a fresh config read, retrieving the test-oriented config

        monkeypatch.setattr("lib.pollen.config_loader.find_repo_root", lambda: tmp_path)
        clear_config_cache()
        config = get_config()

    Settings specified at paths LATER in the list OVERRIDE IDENTICAL SETTINGS at paths EARLIER in the list.
    > e.g. `mcp.auto_approve: yes` in local.yml overrides `mcp.auto_approve: no` in queen.yml

    Returns:
        Merged configuration dictionary.

    Raises:
        FileNotFoundError: If repo root cannot be found.
    """
    repo_root = find_repo_root()

    config: dict[str, Any] = {}

    # Load configs in precedence order (later overrides earlier)
    for filename in ["comb.yml", "queen.yml", "local.yml"]:
        config = deep_merge(config, _load_yaml_file(repo_root / filename))

    # Apply environment variable overrides for path_to
    path_to = config.get("path_to", {})
    path_env_overrides = {
        "serena_projects": "BEEHIVE_WORKSPACE",
    }

    for path_key, env_var in path_env_overrides.items():
        if env_val := os.environ.get(env_var):
            path_to[path_key] = env_val

    # Apply environment variable overrides for path_to.storage_for
    storage_for = path_to.get("storage_for", {})
    storage_env_overrides = {
        "memory_mcp": "MEMORY_MCP_STORAGE_PATH",
        "claude_mem": "CLAUDE_MEM_STORAGE_PATH",
        "qdrant": "QDRANT_STORAGE_PATH",
    }

    for storage_key, env_var in storage_env_overrides.items():
        if env_val := os.environ.get(env_var):
            storage_for[storage_key] = env_val

    # Derive paths from workspace if not explicitly set
    if workspace := path_to.get("workspace"):
        # Only set these if not already configured
        if "serena_projects" not in path_to:
            path_to["serena_projects"] = workspace
        if "fs_mcp_whitelist" not in path_to:
            path_to["fs_mcp_whitelist"] = workspace
        if "mcp_clones" not in path_to:
            path_to["mcp_clones"] = f"{workspace}/mcp-servers"

    # Derive qdrant_url if not provided: use port_for.qdrant_db
    if "qdrant_url" not in path_to:
        ports_cfg = config.get("port_for", {})
        port = ports_cfg.get("qdrant_db", 8780)
        path_to["qdrant_url"] = f"http://127.0.0.1:{port}"

    path_to["storage_for"] = storage_for
    config["path_to"] = path_to

    # Merge Qdrant section defaults if missing
    qdrant_cfg = config.get("qdrant", {})
    if "collection" not in qdrant_cfg:
        qdrant_cfg["collection"] = "coding-memory"
    if "embedding_provider" not in qdrant_cfg:
        qdrant_cfg["embedding_provider"] = "fastembed"
    config["qdrant"] = qdrant_cfg

    return config  # type: ignore[return-value]


def clear_config_cache() -> None:
    """Clear the cached config (for testing)."""
    get_config.cache_clear()


# Convenience accessors
def get_enabled_agents() -> list[str]:
    """Get list of enabled agent names."""
    config = get_config()
    return config.get("agents", [])


def is_agent_enabled(agent_name: str) -> bool:
    """Check if a specific agent is enabled.

    Args:
        agent_name: Agent name (claude, gemini, codex, opencode).

    Returns:
        True if agent is in enabled list.
    """
    return agent_name.lower() in [a.lower() for a in get_enabled_agents()]


def get_retention(storage_name: str) -> str:
    """Get retention period for a storage backend.

    Args:
        storage_name: Storage name (e.g., "claude-mem", "qdrant").

    Returns:
        Retention period string (e.g., "30d").
    """
    config = get_config()
    # Normalize: claude-mem -> claude_mem
    key = storage_name.replace("-", "_")
    return config.get("retention_period_for", {}).get(key, "30d")


def get_trash_grace_period() -> str:
    """Get trash grace period."""
    config = get_config()
    return config.get("trash", {}).get("grace_period", "30d")


def get_cleanup_interval() -> str:
    """Get minimum cleanup interval."""
    config = get_config()
    return config.get("cleanup", {}).get("min_interval", "24h")


def get_path(path_name: str) -> Path:
    """Get a configured file path, expanded.

    Args:
        path_name: Path key (serena_projects, fs_mcp_whitelist, mcp_clones).

    Returns:
        Expanded Path object.
    """
    config = get_config()
    path_str = config.get("path_to", {}).get(path_name, "")
    return expand_path(path_str) if path_str else Path()


def get_storage(storage_name: str) -> Path:
    """Get a configured storage path, expanded.

    Args:
        storage_name: Storage key (qdrant, memory_mcp, claude_mem).

    Returns:
        Expanded Path object.
    """
    config = get_config()
    path_str = config.get("path_to", {}).get("storage_for", {}).get(storage_name, "")
    return expand_path(path_str) if path_str else Path()


# Path constants (computed from config)
def get_repo_root() -> Path:
    """Get repository root path."""
    try:
        return find_repo_root()
    except FileNotFoundError:
        return Path.cwd()


def get_wax_dir() -> Path:
    """Get .wax directory path (in repo root).

    The wax stores operational state and trash - like
    storage cells in a beehive.
    """
    return get_repo_root() / ".wax"


def get_state_path() -> Path:
    """Get state.json path."""
    return get_wax_dir() / "state.json"


def get_trash_dir() -> Path:
    """Get trash directory path."""
    return get_wax_dir() / "trash"


def get_qdrant_url() -> str:
    """Get Qdrant server URL."""
    config = get_config()
    return config.get("path_to", {}).get("qdrant_url", "http://127.0.0.1:8780")


def get_qdrant_collection() -> str:
    """Get Qdrant collection name."""
    config = get_config()
    return config.get("qdrant", {}).get("collection", "coding-memory")


# Duration parsing (moved from cleanup/config.py)
def parse_duration(duration_str: str) -> timedelta:
    """Parse duration string like '30d', '2w', '3m', '1y', '24h' to timedelta.

    Args:
        duration_str: Duration string (e.g., "30d", "24h", "always").

    Returns:
        timedelta object.

    Raises:
        ValueError: If format is invalid.
    """
    if duration_str.lower() == "always":
        return timedelta.max

    match = re.match(r"^(\d+)([hdwmy])$", duration_str.lower())
    if not match:
        raise ValueError(
            f"Invalid duration format: {duration_str}. "
            "Use format like '24h', '30d', '2w', '3m', '1y'"
        )

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
