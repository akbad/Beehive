"""
Shared pytest fixtures for cleanup handler tests.

- Fixtures are reusable setup/teardown providers for tests, returning 
  ready-to-use objs (e.g. temp files, mock configs).
- Pytest:
    - builds and injects fixtures into tests (who request them via args)  
    - handles cleanup
"""

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pytest


# =============================================================================
# DATETIME FIXTURES - Fixed dates for deterministic testing
# =============================================================================

@pytest.fixture
def cutoff_datetime() -> datetime:
    """
    Fixed UTC cutoff datetime for consistent boundary testing.

    All tests use this as the reference point:
    - Items created BEFORE this are stale and should be moved to trash
    - Items created AT or AFTER this are valid and should be preserved

    Resolves to January 15, 2024, 12:00:00 UTC
    """
    return datetime(2024, 1, 15, 12, 0, 0, tzinfo=timezone.utc)


@pytest.fixture
def stale_datetime() -> datetime:
    """Date earlier than cutoff (i.e. items with this date should be considered stale).
    
    Resolves to January 1, 2024, 00:00:00 UTC
    """
    return datetime(2024, 1, 1, 0, 0, 0, tzinfo=timezone.utc)


@pytest.fixture
def valid_datetime() -> datetime:
    """Date later than cutoff (i.e. items with this date should be considered valid).
    
    Resolves to February 1, 2024, 00:00:00 UTC
    """
    return datetime(2024, 2, 1, 0, 0, 0, tzinfo=timezone.utc)


@pytest.fixture
def boundary_datetime(cutoff_datetime: datetime) -> datetime:
    """Exact boundary datetime (should NOT be expired: stale items should have dates strictly less than the cutoff)."""
    return cutoff_datetime


# =============================================================================
# CONFIG FIXTURES
# =============================================================================

@pytest.fixture
def mock_config() -> dict[str, Any]:
    """Base configuration structure matching queen.yml."""
    return {
        "agents": ["claude", "gemini"],
        "retention_period_for": {
            "claude_mem": "30d",
            "serena": "90d",
            "qdrant": "180d",
            "memory_mcp": "365d",
        },
        "cleanup": {
            "min_interval": "24h",
        },
        "trash": {
            "grace_period": "30d",
        },
        "path_to": {
            "workspace": "~/code",
        },
    }


# =============================================================================
# SQLITE FIXTURES (claude_mem handler)
# =============================================================================

@pytest.fixture
def sqlite_db(tmp_path: Path) -> Path:
    """Create temporary SQLite database consisting of 2 tables matching claude-mem's schema."""
    db_path = tmp_path / "claude-mem.db"
    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Create tables matching claude-mem schema
    # Note created_at is expected to be an ISO 8601 timestamp string
    cursor.execute("""
        CREATE TABLE session_summaries (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            summary TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE observations (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            content TEXT
        )
    """)

    conn.commit()
    conn.close()
    return db_path


@pytest.fixture
def sqlite_db_with_data(
    sqlite_db: Path,
    stale_datetime: datetime,
    valid_datetime: datetime,
) -> Path:
    """
    Receives a SQLite database initialized by sqlite_db() to match claude-mem's schema
    and pre-populates it with test data.
    """
    conn = sqlite3.connect(str(sqlite_db))
    cursor = conn.cursor()

    # Format with Z suffix to match claude-mem's ISO 8601 format for the created_at
    #   timestamp string (created in JS via toISOString())
    stale_ts = stale_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
    valid_ts = valid_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

    # Add stale session summary record
    cursor.execute(
        "INSERT INTO session_summaries (id, created_at, summary) VALUES (?, ?, ?)",
        ("session_stale", stale_ts, "Stale session summary")
    )

    # Add valid session summary record
    cursor.execute(
        "INSERT INTO session_summaries (id, created_at, summary) VALUES (?, ?, ?)",
        ("session_valid", valid_ts, "Valid session summary")
    )

    # Add stale observation record
    cursor.execute(
        "INSERT INTO observations (id, created_at, content) VALUES (?, ?, ?)",
        ("obs_stale", stale_ts, "Stale observation")
    )

    # Add valid observation record
    cursor.execute(
        "INSERT INTO observations (id, created_at, content) VALUES (?, ?, ?)",
        ("obs_valid", valid_ts, "Valid observation")
    )

    conn.commit()
    conn.close()
    return sqlite_db


# =============================================================================
# JSONL FIXTURES (memory_mcp handler)
# =============================================================================

@pytest.fixture
def jsonl_file(tmp_path: Path) -> Path:
    """Create empty JSONL file."""
    file_path = tmp_path / "memory.jsonl"
    file_path.touch()
    return file_path


def _to_iso_z(dt: datetime) -> str:
    """Convert datetime to ISO format with Z suffix (UTC)."""
    # Ensure UTC, format without offset, append Z
    return dt.strftime("%Y-%m-%dT%H:%M:%S.000Z")


@pytest.fixture
def jsonl_file_with_data(
    tmp_path: Path,
    stale_datetime: datetime,
    valid_datetime: datetime,
) -> Path:
    """JSONL file pre-populated with test entities for collision testing.

    Uses 8 entities to test ID/name collision prevention:
    - stale_id_and_name: same value as name (stale) and id (stale)
    - valid_id_and_name: same value as name (valid) and id (valid)
    - stale_id_but_valid_name: same value as name (valid) and id (stale)
    - valid_id_but_stale_name: same value as name (stale) and id (valid)

    Plus one entity without timestamp for skip testing.
    """
    file_path = tmp_path / "memory.jsonl"

    entities = [
        # Both stale with same value: both should be deleted
        {"name": "stale_id_and_name", "created_at": _to_iso_z(stale_datetime)},
        {"id": "stale_id_and_name", "created_at": _to_iso_z(stale_datetime)},

        # Both valid with same value: both should be kept
        {"name": "valid_id_and_name", "created_at": _to_iso_z(valid_datetime)},
        {"id": "valid_id_and_name", "created_at": _to_iso_z(valid_datetime)},

        # Name valid, ID stale with same value: name kept, ID deleted
        {"name": "stale_id_but_valid_name", "created_at": _to_iso_z(valid_datetime)},
        {"id": "stale_id_but_valid_name", "created_at": _to_iso_z(stale_datetime)},

        # Name stale, ID valid with same value: name deleted, ID kept
        {"name": "valid_id_but_stale_name", "created_at": _to_iso_z(stale_datetime)},
        {"id": "valid_id_but_stale_name", "created_at": _to_iso_z(valid_datetime)},

        # Entity without timestamp (should be skipped)
        {"name": "no_timestamp_entity"},
    ]

    with open(file_path, "w") as f:
        for entity in entities:
            f.write(json.dumps(entity) + "\n")

    return file_path


# =============================================================================
# SERENA FIXTURES (filesystem)
# =============================================================================

@pytest.fixture
def serena_projects(tmp_path: Path) -> Path:
    """Realistic Serena project structure including symlink edge case.

    Creates:
    - 2 regular projects with .serena/memories/ (2 memory files each)
    - 1 symlinked project pointing to external directory

    The external directory is at tmp_path / "external" for tests that need
    to verify it wasn't touched.
    """
    projects_dir = tmp_path / "projects"

    # Create two regular projects with .serena/memories/
    for i in range(2):
        project_dir = projects_dir / f"project_{i}"
        memories_dir = project_dir / ".serena" / "memories"
        memories_dir.mkdir(parents=True, exist_ok=True)

        # Create memory files
        for j in range(2):
            memory_file = memories_dir / f"memory_{j}.md"
            memory_file.write_text(f"# Memory {j}\n\nProject {i} memory content.")

    # Create external directory (outside projects_dir) with memories
    external_dir = tmp_path / "external"
    external_memories = external_dir / ".serena" / "memories"
    external_memories.mkdir(parents=True)
    (external_memories / "external_memory.md").write_text("External memory")

    # Create symlink inside projects_dir pointing to external
    symlinked_project = projects_dir / "symlinked_project"
    symlinked_project.symlink_to(external_dir)

    return projects_dir


# =============================================================================
# QDRANT FIXTURES (HTTP API mocking)
# =============================================================================

@pytest.fixture
def _qdrant_base_url() -> str:
    """Base URL for Qdrant API."""
    return "http://127.0.0.1:8780"


@pytest.fixture
def _qdrant_collection() -> str:
    """Qdrant collection name."""
    return "coding-memory"


# =============================================================================
# TRASH/STATE FIXTURES
# =============================================================================

@pytest.fixture
def wax_dir(tmp_path: Path) -> Path:
    """Create temporary .wax directory for state and trash."""
    wax = tmp_path / ".wax"
    wax.mkdir()
    return wax


@pytest.fixture
def trash_dir(wax_dir: Path) -> Path:
    """Create trash subdirectory."""
    trash = wax_dir / "trash"
    trash.mkdir()
    return trash


@pytest.fixture
def state_file(wax_dir: Path) -> Path:
    """Path to state.json (may or may not exist)."""
    return wax_dir / "state.json"


# =============================================================================
# SETTINGS MOCK FIXTURE
# =============================================================================

@pytest.fixture
def mock_settings(
    tmp_path: Path,
    sqlite_db: Path,
    jsonl_file: Path,
    serena_projects: Path,
    wax_dir: Path,
    _qdrant_base_url: str,
    _qdrant_collection: str,
    mock_config: dict,
    monkeypatch, 
):
    """Monkeypatch all settings functions to use test paths.

    Note monkeypatching is distinct from stubbing: it allows runtime
    replacement of *any* attribute in *any* module.

    Args:
    - monkeypatch: pytest's built-in patching tool
    - all others: other fixtures, injected as deps

    Note patches are made at the import location (where it's used, i.e.
    the importing module) and *not* at the source (i.e. the module 
    originally defining the imported function). 
    
    This is because Python's import system makes a separate, local 
    reference to the original function when a module imports it.
    
    Patching at the source would leave the reference in the 
    point of use, i.e. the importing module (where we want the 
    patch to actually take effect), pointing to the original 
    function and not the patched version meant for testing.

    Patches made:
    - get_path() to return test paths
    - get_qdrant_url() to return test URL
    - get_qdrant_collection() to return test collection
    - get_config() to return mock_config
    - get_wax_dir() to return test wax dir
    - get_trash_dir() to return test trash dir
    - get_state_path() to return test state path
    """

    # define replacement functions
    def mock_get_path(path_name: str) -> Path:
        paths = {
            "serena_projects": serena_projects,
        }
        return paths.get(path_name, tmp_path / path_name)

    def mock_get_storage(storage_name: str) -> Path:
        storages = {
            "claude_mem": sqlite_db,
            "memory_mcp": jsonl_file,
        }
        return storages.get(storage_name, tmp_path / storage_name)

    # patch handlers' function imports 
    #   (and *not* the source's definitions)
    monkeypatch.setattr(
        "lib.pollen.cleanup.handlers.claude_mem.get_storage",
        mock_get_storage
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.handlers.memory_mcp.get_storage",
        mock_get_storage
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.handlers.serena.get_path",
        mock_get_path
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.handlers.qdrant.get_qdrant_url",
        lambda: _qdrant_base_url
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.handlers.qdrant.get_qdrant_collection",
        lambda: _qdrant_collection
    )

    # patch state module
    monkeypatch.setattr(
        "lib.pollen.cleanup.state.get_wax_dir",
        lambda: wax_dir
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.state.get_state_path",
        lambda: wax_dir / "state.json"
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.state.WAX_DIR",
        wax_dir
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.state.STATE_PATH",
        wax_dir / "state.json"
    )

    # Patch trash module
    trash_dir = wax_dir / "trash"
    monkeypatch.setattr(
        "lib.pollen.cleanup.trash.get_base_trash_dir",
        lambda: trash_dir
    )
    monkeypatch.setattr(
        "lib.pollen.cleanup.trash.BASE_TRASH_DIR",
        trash_dir
    )

    return mock_config
