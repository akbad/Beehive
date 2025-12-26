"""Tests for trash management (soft-delete with grace period)."""
import json
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path


from operations.cleanup.trash import (
    empty_expired_trash,
    empty_all_trash,
    generate_trash_filename,
    get_trash_dir,
    move_to_trash,
    write_manifest,
)


class TestGetTrashDir:
    """Tests for get_trash_dir()."""

    def test_creates_directory_if_missing(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Creates trash directory if it doesn't exist."""
        trash_base = tmp_path / ".wax" / "trash"
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        result = get_trash_dir("claude_mem")

        assert result.exists()
        assert result.name == "claude_mem"
        assert result.parent == trash_base

    def test_returns_existing_directory(
        self,
        trash_dir: Path,
        monkeypatch,
    ):
        """Returns existing directory without error."""
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_dir
        )

        backend_dir = trash_dir / "qdrant"
        backend_dir.mkdir()

        result = get_trash_dir("qdrant")
        assert result == backend_dir


class TestGenerateTrashFilename:
    """Tests for generate_trash_filename()."""

    def test_format_with_timestamp(self):
        """Generates timestamped filename with item count."""
        filename = generate_trash_filename(42)

        # format: YYYY-MM-DDTHH-MM-SS_42-items.json
        assert "_42-items.json" in filename
        assert filename.startswith("20")  # year starts with 20xx

    def test_custom_extension(self):
        """Supports custom file extension."""
        filename = generate_trash_filename(10, extension="jsonl")
        assert filename.endswith("_10-items.jsonl")


class TestWriteManifest:
    """Tests for write_manifest()."""

    def test_creates_new_manifest(
        self,
        tmp_path: Path,
    ):
        """Creates new manifest file if none exists."""
        trash_path = tmp_path / "backend"
        trash_path.mkdir()

        write_manifest(
            trash_path=trash_path,
            storage_name="claude_mem",
            item_count=5,
            retention="30d",
            grace_period="7d",
            files=[Path("/fake/file1.db"), Path("/fake/file2.db")],
        )

        # verify manifest was created with expected structure
        manifest_path = trash_path / ".manifest.json"
        assert manifest_path.exists()

        with open(manifest_path) as f:
            data = json.load(f)

        assert isinstance(data, list)
        assert len(data) == 1
        assert data[0]["source"] == "claude_mem"
        assert data[0]["item_count"] == 5
        assert data[0]["original_retention"] == "30d"
        assert "auto_purge_after" in data[0]
        assert len(data[0]["files"]) == 2

    def test_appends_to_existing_manifest(
        self,
        tmp_path: Path,
    ):
        """Appends to existing manifest rather than overwriting."""
        trash_path = tmp_path / "backend"
        trash_path.mkdir()

        # add first entry
        write_manifest(trash_path, "claude_mem", 3, "30d")

        # add second entry
        write_manifest(trash_path, "qdrant", 10, "90d")

        manifest_path = trash_path / ".manifest.json"
        with open(manifest_path) as f:
            data = json.load(f)

        assert len(data) == 2
        assert data[0]["source"] == "claude_mem"
        assert data[1]["source"] == "qdrant"

    def test_converts_legacy_single_object(
        self,
        tmp_path: Path,
    ):
        """Converts legacy single-object manifest to list format."""
        trash_path = tmp_path / "backend"
        trash_path.mkdir()

        # write legacy format (single object, not list)
        manifest_path = trash_path / ".manifest.json"
        legacy = {
            "trashed_at": "2024-01-01T00:00:00+00:00",
            "source": "legacy",
            "item_count": 1,
            "files": [],
        }
        with open(manifest_path, "w") as f:
            json.dump(legacy, f)

        # append new entry
        write_manifest(trash_path, "new_backend", 5, "30d")

        with open(manifest_path) as f:
            data = json.load(f)

        assert isinstance(data, list)
        assert len(data) == 2
        assert data[0]["source"] == "legacy"
        assert data[1]["source"] == "new_backend"

    def test_handles_corrupt_manifest(
        self,
        tmp_path: Path,
    ):
        """Handles corrupt manifest gracefully by starting fresh."""
        trash_path = tmp_path / "backend"
        trash_path.mkdir()

        # write corrupt JSON
        manifest_path = trash_path / ".manifest.json"
        manifest_path.write_text("not valid json {{{")

        # starts fresh without raising
        write_manifest(trash_path, "backend", 1, "30d")

        with open(manifest_path) as f:
            data = json.load(f)

        assert len(data) == 1
        assert data[0]["source"] == "backend"


class TestMoveToTrash:
    """Tests for move_to_trash()."""

    def test_moves_file_to_trash(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """File is moved (not copied) to trash directory."""
        trash_base = tmp_path / ".wax" / "trash"
        trash_base.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create source file
        source = tmp_path / "source" / "file.db"
        source.parent.mkdir()
        source.write_text("content")

        result = move_to_trash(source, "claude_mem")

        assert not source.exists()  # original moved
        assert result.exists()  # new location exists
        assert result.read_text() == "content"

    def test_moves_with_project_name(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Creates project subdirectory for Serena memories."""
        trash_base = tmp_path / ".wax" / "trash"
        trash_base.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create source file
        source = tmp_path / "memories" / "memory.md"
        source.parent.mkdir()
        source.write_text("# Memory")

        result = move_to_trash(source, "serena", project_name="my_project")

        assert result.parent.name == "my_project"
        assert result.name == "memory.md"


class TestEmptyExpiredTrash:
    """Tests for empty_expired_trash()."""

    def test_deletes_expired_items(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Files older than grace period are deleted."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create old file
        old_file = storage_dir / "old.json"
        old_file.write_text("{}")

        # create manifest with old entry
        old_time = (datetime.now(timezone.utc) - timedelta(days=60)).isoformat()
        manifest = [{
            "trashed_at": old_time,
            "source": "backend",
            "item_count": 1,
            "files": [str(old_file)],
        }]
        (storage_dir / ".manifest.json").write_text(json.dumps(manifest))

        removed = empty_expired_trash("30d")

        assert removed == 1
        assert not old_file.exists()

    def test_preserves_non_expired_items(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Files newer than grace period are preserved."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create new file
        new_file = storage_dir / "new.json"
        new_file.write_text("{}")

        # create manifest with recent entry
        recent_time = (datetime.now(timezone.utc) - timedelta(days=5)).isoformat()
        manifest = [{
            "trashed_at": recent_time,
            "source": "backend",
            "item_count": 1,
            "files": [str(new_file)],
        }]
        (storage_dir / ".manifest.json").write_text(json.dumps(manifest))

        removed = empty_expired_trash("30d")

        assert removed == 0
        assert new_file.exists()

    def test_handles_missing_trash_dir(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Returns 0 when trash directory doesn't exist."""
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            tmp_path / "nonexistent"
        )

        removed = empty_expired_trash("30d")
        assert removed == 0

    def test_skips_corrupt_manifest(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Skips storage directories with corrupt manifests."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # write corrupt manifest
        (storage_dir / ".manifest.json").write_text("not json")
        (storage_dir / "file.json").write_text("{}")

        removed = empty_expired_trash("30d")

        # skips this directory without crashing
        assert removed == 0

    # note: TOCTOU = Time-Of-Check-To-Time-Of-Use race condition
    def test_toctou_file_not_found(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Regression test: handles FileNotFoundError (Issue TOCTOU race)."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create manifest referencing non-existent file
        old_time = (datetime.now(timezone.utc) - timedelta(days=60)).isoformat()
        manifest = [{
            "trashed_at": old_time,
            "source": "backend",
            "item_count": 1,
            "files": [str(storage_dir / "already_deleted.json")],
        }]
        (storage_dir / ".manifest.json").write_text(json.dumps(manifest))

        # continues without raising
        removed = empty_expired_trash("30d")
        assert removed == 0

    def test_mtime_fallback_when_no_files_list(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Falls back to mtime comparison when files list is empty."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create file with old mtime
        old_file = storage_dir / "old.json"
        old_file.write_text("{}")
        old_timestamp = (datetime.now(timezone.utc) - timedelta(days=60)).timestamp()
        # note: os.utime takes (atime, mtime) tuple; we set both to same value
        os.utime(old_file, (old_timestamp, old_timestamp))

        # create manifest with empty files list (triggers mtime fallback)
        old_time = (datetime.now(timezone.utc) - timedelta(days=60)).isoformat()
        manifest = [{
            "trashed_at": old_time,
            "source": "backend",
            "item_count": 1,
            "files": [],
        }]
        (storage_dir / ".manifest.json").write_text(json.dumps(manifest))

        removed = empty_expired_trash("30d")

        assert removed == 1
        assert not old_file.exists()

    def test_removes_empty_storage_dir(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Removes storage directory when all entries are purged."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create old file
        old_file = storage_dir / "old.json"
        old_file.write_text("{}")

        # create manifest with single old entry
        old_time = (datetime.now(timezone.utc) - timedelta(days=60)).isoformat()
        manifest = [{
            "trashed_at": old_time,
            "source": "backend",
            "item_count": 1,
            "files": [str(old_file)],
        }]
        (storage_dir / ".manifest.json").write_text(json.dumps(manifest))

        empty_expired_trash("30d")

        # entire storage directory should be removed
        assert not storage_dir.exists()

    def test_preserves_storage_dir_with_remaining_entries(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Preserves storage directory when some entries remain."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create files
        old_file = storage_dir / "old.json"
        old_file.write_text("{}")
        new_file = storage_dir / "new.json"
        new_file.write_text("{}")

        # create manifest with mixed entries
        old_time = (datetime.now(timezone.utc) - timedelta(days=60)).isoformat()
        new_time = (datetime.now(timezone.utc) - timedelta(days=5)).isoformat()
        manifest = [
            {
                "trashed_at": old_time,
                "source": "backend",
                "item_count": 1,
                "files": [str(old_file)],
            },
            {
                "trashed_at": new_time,
                "source": "backend",
                "item_count": 1,
                "files": [str(new_file)],
            },
        ]
        (storage_dir / ".manifest.json").write_text(json.dumps(manifest))

        empty_expired_trash("30d")

        # storage directory should remain with new file
        assert storage_dir.exists()
        assert new_file.exists()
        assert not old_file.exists()

        # manifest should be updated
        with open(storage_dir / ".manifest.json") as f:
            remaining = json.load(f)
        assert len(remaining) == 1

    def test_handles_legacy_single_object_manifest(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Handles legacy single-object manifest format."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        old_file = storage_dir / "old.json"
        old_file.write_text("{}")

        # legacy single object (not list)
        old_time = (datetime.now(timezone.utc) - timedelta(days=60)).isoformat()
        manifest = {
            "trashed_at": old_time,
            "source": "backend",
            "item_count": 1,
            "files": [str(old_file)],
        }
        (storage_dir / ".manifest.json").write_text(json.dumps(manifest))

        removed = empty_expired_trash("30d")

        assert removed == 1


class TestEmptyAllTrash:
    """Tests for empty_all_trash()."""

    def test_empties_all_items(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Deletes all trash items regardless of age."""
        trash_base = tmp_path / ".wax" / "trash"
        storage_dir = trash_base / "backend"
        storage_dir.mkdir(parents=True)
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_base
        )

        # create multiple files
        (storage_dir / "file1.json").write_text("{}")
        (storage_dir / "file2.json").write_text("{}")
        (storage_dir / ".manifest.json").write_text("[]")

        result = empty_all_trash()

        assert result["emptied"] == 2  # excludes .manifest.json
        assert not storage_dir.exists()

    def test_handles_missing_trash_dir(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Returns appropriate message when trash doesn't exist."""
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            tmp_path / "nonexistent"
        )

        result = empty_all_trash()

        assert result["emptied"] == 0
        assert "does not exist" in result["message"]
