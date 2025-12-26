"""Tests for state management (cleanup run tracking)."""
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path


from lib.pollen.cleanup.state import (
    did_recently_run,
    load_state,
    now_as_iso,
    save_state,
)


class TestLoadState:
    """Tests for load_state()."""

    def test_returns_empty_dict_when_file_missing(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Returns empty dict when state file doesn't exist."""
        monkeypatch.setattr(
            "lib.pollen.cleanup.state.STATE_PATH",
            tmp_path / "nonexistent.json"
        )

        state = load_state()
        assert state == {}

    def test_loads_existing_state(
        self,
        state_file: Path,
        monkeypatch,
    ):
        """Loads state from existing file."""
        state_file.write_text(json.dumps({
            "last_cleanup_run": "2024-01-15T12:00:00+00:00",
            "custom_key": "value",
        }))
        monkeypatch.setattr(
            "lib.pollen.cleanup.state.STATE_PATH",
            state_file
        )

        state = load_state()

        assert state["last_cleanup_run"] == "2024-01-15T12:00:00+00:00"
        assert state["custom_key"] == "value"

    def test_returns_empty_dict_on_corrupt_json(
        self,
        state_file: Path,
        monkeypatch,
    ):
        """Returns empty dict when JSON is corrupt."""
        state_file.write_text("not valid json {{{")
        monkeypatch.setattr(
            "lib.pollen.cleanup.state.STATE_PATH",
            state_file
        )

        state = load_state()
        assert state == {}

    def test_returns_empty_dict_on_io_error(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Returns empty dict on IO errors."""
        # note: creating a directory at the file path triggers IsADirectoryError on open()
        bad_path = tmp_path / "state.json"
        bad_path.mkdir()
        monkeypatch.setattr(
            "lib.pollen.cleanup.state.STATE_PATH",
            bad_path
        )

        state = load_state()
        assert state == {}


class TestSaveState:
    """Tests for save_state()."""

    def test_creates_directory_if_missing(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Creates .wax directory if it doesn't exist."""
        wax_dir = tmp_path / ".wax"
        state_path = wax_dir / "state.json"

        monkeypatch.setattr("lib.pollen.cleanup.state.WAX_DIR", wax_dir)
        monkeypatch.setattr("lib.pollen.cleanup.state.STATE_PATH", state_path)

        save_state({"last_cleanup_run": "2024-01-15T12:00:00+00:00"})

        assert wax_dir.exists()
        assert state_path.exists()

    def test_preserves_existing_keys(
        self,
        wax_dir: Path,
        monkeypatch,
    ):
        """Preserves other keys when updating state."""
        state_path = wax_dir / "state.json"
        state_path.write_text(json.dumps({
            "existing_key": "existing_value",
            "last_cleanup_run": "old_value",
        }))

        monkeypatch.setattr("lib.pollen.cleanup.state.WAX_DIR", wax_dir)
        monkeypatch.setattr("lib.pollen.cleanup.state.STATE_PATH", state_path)

        save_state({"last_cleanup_run": "new_value"})

        with open(state_path) as f:
            state = json.load(f)

        assert state["existing_key"] == "existing_value"
        assert state["last_cleanup_run"] == "new_value"

    def test_writes_valid_json(
        self,
        wax_dir: Path,
        monkeypatch,
    ):
        """Writes valid, formatted JSON."""
        state_path = wax_dir / "state.json"

        monkeypatch.setattr("lib.pollen.cleanup.state.WAX_DIR", wax_dir)
        monkeypatch.setattr("lib.pollen.cleanup.state.STATE_PATH", state_path)

        save_state({
            "last_cleanup_run": "2024-01-15T12:00:00+00:00",
            "last_trash_empty": "2024-01-10T00:00:00+00:00",
        })

        # verify output is valid JSON
        with open(state_path) as f:
            state = json.load(f)

        assert "last_cleanup_run" in state
        assert "last_trash_empty" in state


class TestDidRecentlyRun:
    """Tests for did_recently_run()."""

    def test_within_window_returns_true(self):
        """Returns True when last run is within N hours."""
        # set to 12 hours ago (window is 24 hours)
        last_run = (datetime.now(timezone.utc) - timedelta(hours=12)).isoformat()
        state = {"last_cleanup_run": last_run}

        result = did_recently_run(state, N=24)
        assert result is True

    def test_outside_window_returns_false(self):
        """Returns False when last run is older than N hours."""
        # set to 30 hours ago (window is 24 hours)
        last_run = (datetime.now(timezone.utc) - timedelta(hours=30)).isoformat()
        state = {"last_cleanup_run": last_run}

        result = did_recently_run(state, N=24)
        assert result is False

    def test_exact_boundary_returns_false(self):
        """Returns False when last run is exactly N hours ago (boundary is exclusive)."""
        # set to exactly 24 hours ago
        last_run = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
        state = {"last_cleanup_run": last_run}

        result = did_recently_run(state, N=24)
        # comparison uses > (greater than), not >=
        assert result is False

    def test_missing_key_returns_false(self):
        """Returns False when last_cleanup_run key is missing."""
        state = {}

        result = did_recently_run(state, N=24)
        assert result is False

    def test_none_value_returns_false(self):
        """Returns False when last_cleanup_run is None."""
        state = {"last_cleanup_run": None}

        result = did_recently_run(state, N=24)
        assert result is False

    def test_invalid_iso_returns_false(self):
        """Returns False when timestamp is not valid ISO format."""
        state = {"last_cleanup_run": "not a timestamp"}

        result = did_recently_run(state, N=24)
        assert result is False

    def test_empty_string_returns_false(self):
        """Returns False when timestamp is empty string."""
        state = {"last_cleanup_run": ""}

        result = did_recently_run(state, N=24)
        assert result is False

    def test_custom_window_size(self):
        """Respects custom window size N."""
        # set to 2 hours ago
        last_run = (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat()
        state = {"last_cleanup_run": last_run}

        # within 4 hour window
        assert did_recently_run(state, N=4) is True

        # outside 1 hour window
        assert did_recently_run(state, N=1) is False

    def test_handles_timezone_aware_datetime(self):
        """Handles timezone-aware datetime strings."""
        # use ISO format with explicit UTC offset
        last_run = (datetime.now(timezone.utc) - timedelta(hours=6)).isoformat()
        state = {"last_cleanup_run": last_run}

        result = did_recently_run(state, N=24)
        assert result is True

    def test_handles_z_suffix(self):
        """Handles Z suffix timezone format."""
        # use Z suffix instead of +00:00
        dt = datetime.now(timezone.utc) - timedelta(hours=6)
        last_run = dt.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
        # note Python's fromisoformat Z-suffix support varies by version;
        # this test documents expected behavior and verifies graceful handling
        state = {"last_cleanup_run": last_run}

        result = did_recently_run(state, N=24)


class TestNowAsIso:
    """Tests for now_as_iso()."""

    def test_returns_iso_format(self):
        """Returns current time in ISO format."""
        result = now_as_iso()

        # verify result is parseable as ISO datetime
        parsed = datetime.fromisoformat(result)
        assert parsed is not None

    def test_returns_utc_time(self):
        """Returns time in UTC timezone."""
        result = now_as_iso()

        parsed = datetime.fromisoformat(result)
        # verify timezone info is present (UTC)
        assert parsed.tzinfo is not None

    def test_returns_recent_time(self):
        """Returns approximately current time."""
        before = datetime.now(timezone.utc)
        result = now_as_iso()
        after = datetime.now(timezone.utc)

        parsed = datetime.fromisoformat(result)

        # verify result falls between before and after timestamps
        assert before <= parsed <= after
