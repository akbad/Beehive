"""State management for Beehive cleanup."""
import json
from datetime import datetime, timezone, timedelta
from typing import TypedDict

from ..config_loader import get_wax_dir, get_state_path


class State(TypedDict, total=False):
    last_cleanup_run: str
    last_trash_empty: str


WAX_DIR = get_wax_dir()
STATE_PATH = get_state_path()


def load_state() -> State:
    """Load state from .wax/state.json."""
    if not STATE_PATH.exists():
        return {}

    try:
        with open(STATE_PATH) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}


def save_state(updates: State) -> None:
    """Update state file with latest values."""
    WAX_DIR.mkdir(parents=True, exist_ok=True)

    current = load_state()
    current.update(updates)

    with open(STATE_PATH, "w") as f:
        json.dump(current, f, indent=2)


def did_recently_run(state: State, N: int = 24) -> bool:
    """Check if cleanup ran within the last N hours."""
    last_run = state.get("last_cleanup_run")
    if not last_run:
        return False

    try:
        last_run_as_dt = datetime.fromisoformat(last_run)
        cutoff = datetime.now(last_run_as_dt.tzinfo) - timedelta(hours=N)
        return last_run_as_dt > cutoff
    except (ValueError, TypeError):
        # in case last_run is not a ISO datetime, or a string at all
        return False


def now_as_iso() -> str:
    """Return current time in ISO format."""
    return datetime.now(timezone.utc).isoformat()
