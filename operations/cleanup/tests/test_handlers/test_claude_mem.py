"""Tests for ClaudeMemHandler (SQLite cleanup)."""
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from operations.cleanup.handlers.claude_mem import ClaudeMemHandler


class TestClaudeMemGetExpiredItems:
    """Tests for ClaudeMemHandler.get_stale_items()."""

    def test_z_suffix_format_matches_db(
        self,
        apply_mock_patches,
        with_sqlite_data: Path,
        cutoff_datetime: datetime,
    ):
        """Cutoff string uses Z suffix format."""
        handler = ClaudeMemHandler()
        stale_ids = [item["data"]["id"] for item in handler.get_stale_items(cutoff_datetime)]
        
        assert "session_stale" in stale_ids
        assert "obs_stale" in stale_ids

        assert "session_valid" not in stale_ids
        assert "obs_valid" not in stale_ids

    def test_millisecond_truncation(
        self,
        apply_mock_patches,
        sqlite_db: Path,
    ):
        """
        Microseconds in the cutoff datetime object are truncated to milliseconds in 
        ClaudeMemHandler to match the granularity of the timestamps stored by claude-mem in SQLite.
        """

        # insert item with millisecond-granular timestamp
        conn = sqlite3.connect(str(sqlite_db))
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO session_summaries (id, created_at, summary) VALUES (?, ?, ?)",
            ("test_session", "2024-01-15T12:00:00.123Z", "Test summary")
        )
        conn.commit()
        conn.close()

        handler = ClaudeMemHandler()

        # using staleness cutoff set to exact same time: item should NOT be expired (comparison uses <)
        cutoff = datetime(2024, 1, 15, 12, 0, 0, 123000, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)
        assert len(items) == 0
        
        # using staleness cutoff set to 999 µs later: item should NOT be expired 
        #   (i.e. since 123,999 µs should get truncated to 123ms) 
        cutoff = datetime(2024, 1, 15, 12, 0, 0, 123999, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)
        assert len(items) == 0

        # set cutoff to 1 ms later: item should be expired
        cutoff_later = datetime(2024, 1, 15, 12, 0, 0, 124000, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff_later)
        assert len(items) == 1

    def test_exact_boundary_not_deleted(
        self,
        apply_mock_patches,
        sqlite_db: Path,
    ):
        """Items EXACTLY matching the cutoff time should NOT be deleted."""
        
        # insert item at exact boundary time
        conn = sqlite3.connect(str(sqlite_db))
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO session_summaries (id, created_at, summary) VALUES (?, ?, ?)",
            ("boundary_session", "2024-01-15T12:00:00.000Z", "Boundary summary")
        )
        conn.commit()
        conn.close()

        handler = ClaudeMemHandler()
        cutoff = datetime(2024, 1, 15, 12, 0, 0, tzinfo=timezone.utc)

        stale_ids = [item["data"]["id"] for item in handler.get_stale_items(cutoff)]
        assert "boundary_session" not in stale_ids

    def test_empty_db_returns_empty_list(
        self,
        apply_mock_patches,
        sqlite_db: Path,
        cutoff_datetime: datetime,
    ):
        """Empty database returns empty list."""
        handler = ClaudeMemHandler()
        items = handler.get_stale_items(cutoff_datetime)
        assert items == []

    def test_missing_db_returns_empty_list(
        self,
        tmp_path: Path,
        cutoff_datetime: datetime,
        monkeypatch,
    ):
        """Non-existent database returns empty list."""
        
        # use custom monkeypatch to retrieve non-existent DB path from config
        monkeypatch.setattr(
            "operations.cleanup.handlers.claude_mem.get_storage",
            lambda _: tmp_path / "nonexistent.db"
        )

        handler = ClaudeMemHandler()
        stale_items = handler.get_stale_items(cutoff_datetime)
        assert stale_items == []


class TestClaudeMemDeleteItems:
    """Tests for ClaudeMemHandler.delete_items_from_storage()."""

    def test_delete_removes_items_from_db(
        self,
        apply_mock_patches,
        with_sqlite_data: Path,
        cutoff_datetime: datetime,
    ):
        """Deleted items are removed from database."""
        handler = ClaudeMemHandler()
        stale_items = handler.get_stale_items(cutoff_datetime)
        deleted = handler.delete_items_from_storage(stale_items)

        # rows with ids "session_stale" & "obs_stale" should have been deleted

        # ensure returned deletion count was correct
        assert deleted == 2

        # ensure the rows mentioned above were actually the ones deleted
        conn = sqlite3.connect(str(with_sqlite_data))
        cursor = conn.cursor()

        cursor.execute("SELECT id FROM session_summaries")
        remaining_sessions = [row[0] for row in cursor.fetchall()]

        cursor.execute("SELECT id FROM observations")
        remaining_obs = [row[0] for row in cursor.fetchall()]

        conn.close()

        assert "session_stale" not in remaining_sessions
        assert "session_valid" in remaining_sessions
        assert "obs_stale" not in remaining_obs
        assert "obs_valid" in remaining_obs

    def test_delete_empty_list_returns_zero(
        self,
        apply_mock_patches,
        sqlite_db: Path,
    ):
        """Deleting empty list returns 0."""
        handler = ClaudeMemHandler()
        deleted = handler.delete_items_from_storage([])
        assert deleted == 0


class TestClaudeMemWipe:
    """Tests for ClaudeMemHandler.wipe()."""

    def test_wipe_clears_all_data(
        self,
        apply_mock_patches,
        with_sqlite_data: Path,
    ):
        """Wipe removes all data from all tables."""
        handler = ClaudeMemHandler()
        result = handler.wipe(backup=True)

        # 2 sessions & 2 observations should have been wiped
        assert result["wiped"] == 4

        # verify tables are indeed empty
        conn = sqlite3.connect(str(with_sqlite_data))
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM session_summaries")
        assert cursor.fetchone()[0] == 0
        cursor.execute("SELECT COUNT(*) FROM observations")
        assert cursor.fetchone()[0] == 0
        conn.close()

    def test_wipe_missing_db(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Wipe on missing database returns appropriate message."""
        
        # use custom monkeypatch to retrieve non-existent DB path from config
        monkeypatch.setattr(
            "operations.cleanup.handlers.claude_mem.get_storage",
            lambda _: tmp_path / "nonexistent.db"
        )

        handler = ClaudeMemHandler()
        result = handler.wipe()

        assert result["wiped"] == 0
        assert "database does not exist" in result["message"]
